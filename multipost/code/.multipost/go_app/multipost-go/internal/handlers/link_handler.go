package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"gorm.io/gorm"
	"log"
	"multipost-go/internal/models"
	"strings"
	"time"
)

type LinkHandler struct {
	db *gorm.DB
}

func NewLinkHandler(db *gorm.DB) *LinkHandler {
	return &LinkHandler{db: db}
}

func (h *LinkHandler) CreateLinks(c *fiber.Ctx) error {
	var req struct {
		UserID   string              `json:"user_id"`
		Platform string              `json:"platform"`
		Channels []map[string]string `json:"channels"`
	}

	if err := c.BodyParser(&req); err != nil {
		log.Printf("Failed to parse request: %v", err)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request"})
	}

	if req.UserID == "" {
		log.Printf("Missing user_id in request")
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Missing user_id"})
	}

	if req.Platform == "" {
		log.Printf("Missing platform in request")
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Missing platform"})
	}

	log.Printf("Received request: user_id=%s, platform=%s, channels=%v", req.UserID, req.Platform, req.Channels)

	for _, channel := range req.Channels {
		socialID := channel["social_id"]
		if socialID == "" {
			socialID = channel["title"]
		}
		if socialID == "" {
			log.Printf("Пропускаем каналы с пустыми названиеми: %v", channel)
			continue
		}
		// Нормализуем social_id для Telegram
		if !strings.HasPrefix(socialID, "@") && req.Platform == "telegram" {
			socialID = "@" + socialID
		}
		link := models.Link{
			ID:           uuid.New().String(),
			UserID:       req.UserID,
			SocialID:     socialID,
			Platform:     req.Platform,
			AccessToken:  "",
			Title:        channel["title"],
			MainUsername: socialID,
			CreatedAt:    time.Now(),
			UpdatedAt:    time.Now(),
		}
		// Проверяем, существует ли запись
		var existingLink models.Link
		if err := h.db.Where("social_id = ? AND user_id = ? AND platform = ?", socialID, req.UserID, req.Platform).First(&existingLink).Error; err == nil {
			log.Printf("Link already exists: social_id=%s, user_id=%s", socialID, req.UserID)
			continue
		}
		if err := h.db.Create(&link).Error; err != nil {
			log.Printf("Failed to save link: social_id=%s, error=%v", socialID, err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Не удалось сохранить ссыылку"})
		}
		log.Printf("Saved link: social_id=%s, user_id=%s, title=%s", socialID, req.UserID, link.Title)
	}

	return c.JSON(fiber.Map{"status": "success"})
}

func (h *LinkHandler) GetLinks(c *fiber.Ctx) error {
	userID := c.Query("user_id")
	platform := c.Query("platform")

	if userID == "" || platform == "" {
		log.Printf("Missing user_id or platform in query")
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Пропущен id пользователя или соцсеть"})
	}

	var links []models.Link
	query := h.db.Where("user_id = ? AND platform = ?", userID, platform)
	if err := query.Find(&links).Error; err != nil {
		log.Printf("Failed to fetch links: user_id=%s, platform=%s, error=%v", userID, platform, err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Не удалось загрузить каналы"})
	}

	log.Printf("Fetched %d links for user_id=%s, platform=%s", len(links), userID, platform)
	return c.JSON(fiber.Map{
		"status": "success",
		"links":  links,
	})
}
