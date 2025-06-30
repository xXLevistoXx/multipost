package services

import (
	"fmt"
	"github.com/google/uuid"
	"gorm.io/gorm"
	"multipost-go/internal/models"
	"strings"
	"time"
)

type PostService struct {
	db           *gorm.DB
	adminService *AdminService
}

func NewPostService(db *gorm.DB, adminService *AdminService) *PostService {
	return &PostService{db: db, adminService: adminService}
}

type CreatePostRequest struct {
	Title       string      `json:"title" form:"title"`
	Description string      `json:"description" form:"description"`
	Images      []ImageFile `json:"-" form:"images"`
	SocialIDs   []string    `json:"social_ids" form:"social_ids"`
	ScheduledAt *time.Time  `json:"scheduled_at" form:"scheduled_at"`
}

type ImageFile struct {
	Data []byte
	Name string
}

func (s *PostService) CreatePost(userID string, req CreatePostRequest) (*models.Post, error) {
	// Проверка, забанен ли пользователь
	var user models.User
	if err := s.db.Where("id = ?", userID).First(&user).Error; err != nil {
		return nil, fmt.Errorf("пользователь не найден: %v", err)
	}
	if user.IsBanned {
		return nil, fmt.Errorf("пользователь заблокирован")
	}

	// Проверка запрещенных слов
	forbiddenWords := s.adminService.CheckForbiddenWords(req.Title + " " + req.Description)
	if len(forbiddenWords) > 0 {
		// Увеличиваем счетчик подозрительных попыток
		if err := s.adminService.IncrementSuspiciousAttempts(userID, forbiddenWords); err != nil {
			return nil, fmt.Errorf("не удалось увеличить счетчик подозрительных попыток: %v", err)
		}
		return nil, fmt.Errorf("пост содержит запрещенные слова: %s", strings.Join(forbiddenWords, ", "))
	}

	var links []models.Link

	fmt.Printf("Received SocialIDs: %v for user %s\n", req.SocialIDs, userID)
	if err := s.db.Where("user_id = ? AND social_id IN ?", userID, req.SocialIDs).Find(&links).Error; err != nil {
		fmt.Printf("Error querying links: %v\n", err)
		return nil, fmt.Errorf("ошибка при запросе ссылок: %v", err)
	}
	fmt.Printf("Found links: %v\n", links)

	for _, socialID := range req.SocialIDs {
		found := false
		for _, link := range links {
			if link.SocialID == socialID {
				found = true
				break
			}
		}
		if !found && strings.HasPrefix(socialID, "@") {
			fmt.Printf("Creating new link for socialID: %s\n", socialID)
			newLink := models.Link{
				ID:        uuid.New().String(),
				UserID:    userID,
				SocialID:  socialID,
				Platform:  "telegram",
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			}
			if err := s.db.Create(&newLink).Error; err != nil {
				fmt.Printf("Error creating new link: %v\n", err)
				return nil, fmt.Errorf("ошибка при создании новой ссылки: %v", err)
			}
			links = append(links, newLink)
		}
	}

	if len(links) == 0 {
		fmt.Printf("No valid social IDs provided for user %s\n", userID)
		return nil, fmt.Errorf("не предоставлены действительные идентификаторы социальных сетей")
	}

	now := time.Now()
	post := models.Post{
		ID:          uuid.New().String(),
		Title:       req.Title,
		Description: req.Description,
		Socials:     links,
		ScheduledAt: req.ScheduledAt,
		Published:   req.ScheduledAt == nil || req.ScheduledAt.Before(time.Now()),
		UserID:      userID,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	var images []models.Image
	for _, img := range req.Images {
		images = append(images, models.Image{
			Data:      img.Data,
			PostID:    post.ID,
			CreatedAt: now,
			UpdatedAt: now,
		})
	}

	if err := s.db.Create(&post).Error; err != nil {
		fmt.Printf("Error creating post: %v\n", err)
		return nil, fmt.Errorf("ошибка при создании поста: %v", err)
	}
	fmt.Printf("Post created: %+v\n", post)

	if len(images) > 0 {
		if err := s.db.Create(&images).Error; err != nil {
			fmt.Printf("Error creating images: %v\n", err)
			return nil, fmt.Errorf("ошибка при создании изображений: %v", err)
		}
	}

	if err := s.db.Preload("Images").Preload("Socials").First(&post, "id = ?", post.ID).Error; err != nil {
		fmt.Printf("Error preloading post: %v\n", err)
		return nil, fmt.Errorf("ошибка при загрузке данных поста: %v", err)
	}

	return &post, nil
}

func (s *PostService) GetPosts(userID string) ([]models.Post, error) {
	var posts []models.Post
	if err := s.db.Preload("Images").Preload("Socials").
		Where("user_id = ?", userID).
		Find(&posts).Error; err != nil {
		fmt.Printf("Error getting posts: %v\n", err)
		return nil, fmt.Errorf("ошибка при получении постов: %v", err)
	}
	fmt.Printf("Posts retrieved for user %s: %+v\n", userID, posts)
	return posts, nil
}

func (s *PostService) GetPost(postID, userID string) (*models.Post, error) {
	var post models.Post
	if err := s.db.Preload("Images").Preload("Socials").
		Where("id = ? AND user_id = ?", postID, userID).
		First(&post).Error; err != nil {
		fmt.Printf("Error getting post %s: %v\n", postID, err)
		return nil, fmt.Errorf("ошибка при получении поста %s: %v", postID, err)
	}
	return &post, nil
}

func (s *PostService) PublishPost(postID, userID string) error {
	var post models.Post
	if err := s.db.Where("id = ? AND user_id = ?", postID, userID).First(&post).Error; err != nil {
		fmt.Printf("Error finding post %s: %v\n", postID, err)
		return fmt.Errorf("ошибка при поиске поста %s: %v", postID, err)
	}

	// Проверка, забанен ли пользователь
	var user models.User
	if err := s.db.Where("id = ?", userID).First(&user).Error; err != nil {
		return fmt.Errorf("пользователь не найден: %v", err)
	}
	if user.IsBanned {
		return fmt.Errorf("пользователь заблокирован")
	}

	// Проверка запрещенных слов
	forbiddenWords := s.adminService.CheckForbiddenWords(post.Title + " " + post.Description)
	if len(forbiddenWords) > 0 {
		if err := s.adminService.IncrementSuspiciousAttempts(userID, forbiddenWords); err != nil {
			return fmt.Errorf("не удалось увеличить счетчик подозрительных попыток: %v", err)
		}
		return fmt.Errorf("пост содержит запрещенные слова: %s", strings.Join(forbiddenWords, ", "))
	}

	post.Published = true
	post.ScheduledAt = nil
	post.UpdatedAt = time.Now()
	if err := s.db.Save(&post).Error; err != nil {
		fmt.Printf("Error updating post %s: %v\n", postID, err)
		return fmt.Errorf("ошибка при обновлении поста %s: %v", postID, err)
	}

	return nil
}

func (s *PostService) DeletePost(userID, postID string) error {
	var post models.Post
	if err := s.db.Where("id = ? AND user_id = ?", postID, userID).First(&post).Error; err != nil {
		fmt.Printf("Ошибка в нахождении поста %s: %v\n", postID, err)
		return fmt.Errorf("ошибка при поиске поста %s: %v", postID, err)
	}

	if err := s.db.Delete(&post).Error; err != nil {
		fmt.Printf("Ошибка удаления поста %s: %v\n", postID, err)
		return fmt.Errorf("ошибка при удалении поста %s: %v", postID, err)
	}
	fmt.Printf("Пост удален: %s for user %s\n", postID, userID)
	return nil
}

func (s *PostService) GetScheduledPosts() ([]models.Post, error) {
	var posts []models.Post
	if err := s.db.Preload("Images").Preload("Socials").
		Where("published = ? AND scheduled_at IS NOT NULL AND scheduled_at <= ?", false, time.Now()).
		Find(&posts).Error; err != nil {
		fmt.Printf("Ошибка в получении отложенных постов: %v\n", err)
		return nil, fmt.Errorf("ошибка при получении отложенных постов: %v", err)
	}
	return posts, nil
}
