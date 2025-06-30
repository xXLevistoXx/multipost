package handlers

import (
	"github.com/gofiber/fiber/v2"
	"io"
	"log"
	"multipost-go/internal/services"
	"time"
)

type PostHandler struct {
	postService    *services.PostService
	publishService *services.PublishService
}

func NewPostHandler(postService *services.PostService, publishService *services.PublishService) *PostHandler {
	return &PostHandler{
		postService:    postService,
		publishService: publishService,
	}
}

func (h *PostHandler) CreatePost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	// Парсим multipart/form-data
	form, err := c.MultipartForm()
	if err != nil {
		log.Printf("Failed to parse multipart form: %v", err)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Failed to parse multipart form"})
	}

	// Извлекаем текстовые поля
	log.Printf("Form values: %+v", form.Value)
	title := form.Value["title"]
	if len(title) == 0 {
		log.Printf("Title is missing")
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Title is required"})
	}
	description := form.Value["description"]
	if len(description) == 0 {
		log.Printf("Description is missing")
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Description is required"})
	}
	socialIDs := form.Value["social_ids[]"]
	if len(socialIDs) == 0 {
		log.Printf("Social IDs are missing")
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "At least one social ID is required"})
	}
	var scheduledAt *time.Time
	if len(form.Value["scheduled_at"]) > 0 && form.Value["scheduled_at"][0] != "" {
		log.Printf("Received scheduled_at: %s", form.Value["scheduled_at"][0])
		parsedTime, err := time.Parse(time.RFC3339, form.Value["scheduled_at"][0])
		if err != nil {
			log.Printf("Failed to parse scheduled_at: %v", err)
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid scheduled_at format"})
		}
		scheduledAt = &parsedTime
	}

	// Извлекаем файлы изображений
	files := form.File["images"]
	var imageFiles []services.ImageFile
	for _, file := range files {
		openedFile, err := file.Open()
		if err != nil {
			log.Printf("Failed to open image file: %v", err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to open image file"})
		}
		defer openedFile.Close()

		data, err := io.ReadAll(openedFile)
		if err != nil {
			log.Printf("Failed to read image file: %v", err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to read image file"})
		}

		imageFiles = append(imageFiles, services.ImageFile{
			Data: data,
			Name: file.Filename,
		})
	}

	// Формируем запрос
	req := services.CreatePostRequest{
		Title:       title[0],
		Description: description[0],
		Images:      imageFiles,
		SocialIDs:   socialIDs,
		ScheduledAt: scheduledAt,
	}

	// Создаем пост
	log.Printf("Creating post for user %s with social_ids: %v, scheduled_at: %v", userID, socialIDs, scheduledAt)
	post, err := h.postService.CreatePost(userID, req)
	if err != nil {
		log.Printf("Failed to create post: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	// Если пост не отложенный, публикуем сразу
	if post.ScheduledAt == nil || post.ScheduledAt.Before(time.Now()) {
		if err := h.publishService.PublishPost(post); err != nil {
			log.Printf("Failed to publish post: %v", err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}

	return c.JSON(post)
}

func (h *PostHandler) GetPosts(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	posts, err := h.postService.GetPosts(userID)
	if err != nil {
		log.Printf("Failed to get posts: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(posts)
}

func (h *PostHandler) PublishPost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	postID := c.Params("id")

	post, err := h.postService.GetPost(postID, userID)
	if err != nil {
		log.Printf("Failed to get post: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	if err := h.publishService.PublishPost(post); err != nil {
		log.Printf("Failed to publish post: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"status": "success"})
}

func (h *PostHandler) DeletePost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	postID := c.Params("id")
	if err := h.postService.DeletePost(userID, postID); err != nil {
		log.Printf("Failed to delete post: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"status": "success"})
}