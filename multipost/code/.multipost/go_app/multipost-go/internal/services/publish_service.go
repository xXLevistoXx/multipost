package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"multipost-go/config"
	"multipost-go/internal/models"
	"net/http"
	"net/url"
	"strings"
	"time"

	"gorm.io/gorm"
)

type PublishService struct {
	db     *gorm.DB
	cfg    *config.Config
	client *http.Client
}

func NewPublishService(db *gorm.DB, cfg *config.Config) *PublishService {
	return &PublishService{
		db:     db,
		cfg:    cfg,
		client: &http.Client{},
	}
}

func (s *PublishService) StartScheduledPosting() {
	ticker := time.NewTicker(1 * time.Minute)
	for {
		select {
		case <-ticker.C:
			posts, err := s.getScheduledPosts()
			if err != nil {
				fmt.Printf("Error fetching scheduled posts: %v\n", err)
				continue
			}

			for _, post := range posts {
				if err := s.PublishPost(&post); err != nil {
					fmt.Printf("Error publishing post %s: %v\n", post.ID, err)
					continue
				}

				// Обновляем статус поста
				post.Published = true
				post.ScheduledAt = nil
				if err := s.db.Save(&post).Error; err != nil {
					fmt.Printf("Error updating post %s: %v\n", post.ID, err)
				}
			}
		}
	}
}

func (s *PublishService) getScheduledPosts() ([]models.Post, error) {
	var posts []models.Post
	if err := s.db.Preload("Images").Preload("Socials").
		Where("published = ? AND scheduled_at IS NOT NULL AND scheduled_at <= ?", false, time.Now()).
		Find(&posts).Error; err != nil {
		return nil, err
	}
	return posts, nil
}

func (s *PublishService) PublishPost(post *models.Post) error {
	// Находим пользователя, чтобы получить токены
	var user models.User
	if err := s.db.Where("id = ?", post.UserID).First(&user).Error; err != nil {
		return fmt.Errorf("failed to find user: %v", err)
	}

	for _, link := range post.Socials {
		if link.Platform == "telegram" {
			// Пропускаем Telegram, так как публикация идет через FastAPI
			continue
		}
		switch link.Platform {
		case "vk":
			if err := s.publishToVK(post, link, user); err != nil {
				fmt.Printf("Failed to publish to VK group %s: %v\n", link.SocialID, err)
				continue
			}
		case "reddit":
			if err := s.publishToReddit(post, link, user); err != nil {
				fmt.Printf("Failed to publish to Reddit subreddit %s: %v\n", link.SocialID, err)
				continue
			}
		}
	}

	// Обновляем статус поста
	post.Published = true
	post.ScheduledAt = nil
	if err := s.db.Save(post).Error; err != nil {
		return fmt.Errorf("failed to update post: %v", err)
	}

	return nil
}

func (s *PublishService) publishToVK(post *models.Post, link models.Link, user models.User) error {
	// Используем сохранённый VK access token
	accessToken := user.VKAccessToken
	if accessToken == "" {
		return fmt.Errorf("VK access token not provided")
	}

	// Получаем upload server для загрузки фотографий
	uploadURL, err := s.getVKUploadServer(link.SocialID, accessToken)
	if err != nil {
		return fmt.Errorf("failed to get VK upload server: %v", err)
	}

	// Загружаем фотографии
	photoIDs, err := s.uploadPhotosToVK(uploadURL, post.Images, link, accessToken)
	if err != nil {
		return fmt.Errorf("failed to upload photos to VK: %v", err)
	}

	// Формируем сообщение
	message := fmt.Sprintf("%s\n\n%s", post.Title, post.Description)

	// Публикуем пост
	data := url.Values{}
	data.Set("owner_id", fmt.Sprintf("-%s", link.SocialID)) // Отрицательный ID для сообщества
	data.Set("message", message)
	data.Set("attachments", strings.Join(photoIDs, ","))
	data.Set("access_token", accessToken)
	data.Set("v", "5.199")

	if post.ScheduledAt != nil && post.ScheduledAt.After(time.Now()) {
		data.Set("publish_date", fmt.Sprintf("%d", post.ScheduledAt.Unix()))
	}

	resp, err := s.client.PostForm("https://api.vk.com/method/wall.post", data)
	if err != nil {
		return fmt.Errorf("failed to post to VK: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read VK response: %v", err)
	}

	var vkResp struct {
		Response struct {
			PostID int `json:"post_id"`
		} `json:"response"`
		Error struct {
			ErrorMsg string `json:"error_msg"`
		} `json:"error"`
	}
	if err := json.Unmarshal(body, &vkResp); err != nil {
		return fmt.Errorf("failed to decode VK response: %v", err)
	}

	if vkResp.Error.ErrorMsg != "" {
		return fmt.Errorf("VK API error: %s", vkResp.Error.ErrorMsg)
	}

	return nil
}

func (s *PublishService) getVKUploadServer(groupID, accessToken string) (string, error) {
	data := url.Values{}
	data.Set("group_id", groupID)
	data.Set("access_token", accessToken)
	data.Set("v", "5.199")

	resp, err := s.client.PostForm("https://api.vk.com/method/photos.getWallUploadServer", data)
	if err != nil {
		return "", fmt.Errorf("failed to get upload server: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %v", err)
	}

	var uploadResp struct {
		Response struct {
			UploadURL string `json:"upload_url"`
		} `json:"response"`
		Error struct {
			ErrorMsg string `json:"error_msg"`
		} `json:"error"`
	}
	if err := json.Unmarshal(body, &uploadResp); err != nil {
		return "", fmt.Errorf("failed to decode response: %v", err)
	}

	if uploadResp.Error.ErrorMsg != "" {
		return "", fmt.Errorf("VK API error: %s", uploadResp.Error.ErrorMsg)
	}

	return uploadResp.Response.UploadURL, nil
}

func (s *PublishService) uploadPhotosToVK(uploadURL string, images []models.Image, link models.Link, accessToken string) ([]string, error) {
	var photoIDs []string

	for i, image := range images {
		// Создаем multipart форму
		var b bytes.Buffer
		w := multipart.NewWriter(&b)
		fw, err := w.CreateFormFile("file", fmt.Sprintf("photo_%d.jpg", i))
		if err != nil {
			return nil, fmt.Errorf("failed to create form file: %v", err)
		}
		if _, err := io.Copy(fw, bytes.NewReader(image.Data)); err != nil {
			return nil, fmt.Errorf("failed to copy image to form: %v", err)
		}
		w.Close()

		// Загружаем фото
		req, err := http.NewRequest("POST", uploadURL, &b)
		if err != nil {
			return nil, fmt.Errorf("failed to create upload request: %v", err)
		}
		req.Header.Set("Content-Type", w.FormDataContentType())

		uploadResp, err := s.client.Do(req)
		if err != nil {
			return nil, fmt.Errorf("failed to upload photo: %v", err)
		}
		defer uploadResp.Body.Close()

		body, err := io.ReadAll(uploadResp.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to read upload response: %v", err)
		}

		var uploadResult struct {
			Server int    `json:"server"`
			Photo  string `json:"photo"`
			Hash   string `json:"hash"`
		}
		if err := json.Unmarshal(body, &uploadResult); err != nil {
			return nil, fmt.Errorf("failed to decode upload response: %v", err)
		}

		// Сохраняем фото
		data := url.Values{}
		data.Set("group_id", link.SocialID)
		data.Set("server", fmt.Sprintf("%d", uploadResult.Server))
		data.Set("photo", uploadResult.Photo)
		data.Set("hash", uploadResult.Hash)
		data.Set("access_token", accessToken)
		data.Set("v", "5.199")

		saveResp, err := s.client.PostForm("https://api.vk.com/method/photos.saveWallPhoto", data)
		if err != nil {
			return nil, fmt.Errorf("failed to save photo: %v", err)
		}
		defer saveResp.Body.Close()

		saveBody, err := io.ReadAll(saveResp.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to read save response: %v", err)
		}

		var saveResult struct {
			Response []struct {
				ID      int `json:"id"`
				OwnerID int `json:"owner_id"`
			} `json:"response"`
			Error struct {
				ErrorMsg string `json:"error_msg"`
			} `json:"error"`
		}
		if err := json.Unmarshal(saveBody, &saveResult); err != nil {
			return nil, fmt.Errorf("failed to decode save response: %v", err)
		}

		if saveResult.Error.ErrorMsg != "" {
			return nil, fmt.Errorf("VK API error: %s", saveResult.Error.ErrorMsg)
		}

		if len(saveResult.Response) > 0 {
			photoID := fmt.Sprintf("photo%d_%d", saveResult.Response[0].OwnerID, saveResult.Response[0].ID)
			photoIDs = append(photoIDs, photoID)
		}
	}

	return photoIDs, nil
}

func (s *PublishService) publishToReddit(post *models.Post, link models.Link, user models.User) error {
	// Используем Reddit access token пользователя
	accessToken := user.RedditAccessToken
	if accessToken == "" {
		return fmt.Errorf("Reddit access token not provided")
	}

	// Формируем текстовый пост
	data := url.Values{}
	data.Set("sr", link.SocialID)
	data.Set("title", post.Title)
	data.Set("text", post.Description)
	data.Set("kind", "self")

	req, err := http.NewRequest("POST", "https://oauth.reddit.com/api/submit", strings.NewReader(data.Encode()))
	if err != nil {
		return fmt.Errorf("failed to create Reddit post request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("User-Agent", "multipost/1.0 by Huge-AD4304")

	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to post to Reddit: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read Reddit response: %v", err)
	}

	var redditResp struct {
		Success bool `json:"success"`
		Errors  []struct {
			Error string `json:"error"`
		} `json:"errors"`
	}
	if err := json.Unmarshal(body, &redditResp); err != nil {
		return fmt.Errorf("failed to decode Reddit response: %v", err)
	}

	if !redditResp.Success {
		return fmt.Errorf("Reddit API error: %v", redditResp.Errors)
	}

	// Reddit не поддерживает загрузку нескольких изображений в одном посте через API.
	// Также Reddit API не позволяет напрямую загружать изображения, нужно сначала загрузить их на сторонний хостинг
	// Здесь мы пропустим загрузку изображений, так как Reddit требует URL
	// В реальном приложении вам нужно будет загрузить изображения на сторонний сервис (например, Imgur) и получить URL
	for _, image := range post.Images {
		fmt.Printf("Reddit does not support direct image uploads. Image data length: %d bytes\n", len(image.Data))
		// Реализация загрузки на Imgur и получения URL может быть добавлена здесь
	}

	return nil
}
