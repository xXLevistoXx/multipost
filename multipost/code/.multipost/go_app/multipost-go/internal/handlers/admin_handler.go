package handlers

import (
	"github.com/gofiber/fiber/v2"
	"log"
	"multipost-go/internal/services"
	"net/url" // Добавляем для декодирования URL
)

type AdminHandler struct {
	adminService *services.AdminService
}

func NewAdminHandler(adminService *services.AdminService) *AdminHandler {
	return &AdminHandler{adminService: adminService}
}

func (h *AdminHandler) GetAllUsers(c *fiber.Ctx) error {
	users, err := h.adminService.GetAllUsers()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"users": users})
}

func (h *AdminHandler) UpdateUserRole(c *fiber.Ctx) error {
	userID := c.Params("id")
	var req struct {
		Role string `json:"role"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	if err := h.adminService.UpdateUserRole(userID, req.Role); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"status": "success"})
}

func (h *AdminHandler) AddForbiddenWord(c *fiber.Ctx) error {
	var req struct {
		Word string `json:"word"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	if err := h.adminService.AddForbiddenWord(req.Word); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"status": "success"})
}

func (h *AdminHandler) GetForbiddenWords(c *fiber.Ctx) error {
	words, err := h.adminService.GetForbiddenWords()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	var wordList []string
	for _, w := range words {
		wordList = append(wordList, w.Word)
	}
	return c.JSON(wordList)
}

func (h *AdminHandler) DeleteForbiddenWord(c *fiber.Ctx) error {
	word := c.Params("word")
	// Декодируем параметр из URL
	decodedWord, err := url.PathUnescape(word)
	if err != nil {
		log.Printf("Error decoding word parameter: %v", err)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Некорректный параметр слова"})
	}
	log.Printf("Attempting to delete forbidden word: %s (decoded: %s)", word, decodedWord)
	result := h.adminService.DeleteForbiddenWord(decodedWord)
	if result.Error != nil {
		log.Printf("Error deleting forbidden word: %v", result.Error)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": result.Error.Error()})
	}
	if result.RowsAffected == 0 {
		log.Printf("No rows affected, word '%s' not found", decodedWord)
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Слово не найдено"})
	}
	log.Printf("Successfully deleted forbidden word: %s", decodedWord)
	return c.JSON(fiber.Map{"status": "success"})
}

func (h *AdminHandler) BanUser(c *fiber.Ctx) error {
	userID := c.Params("id")
	var req struct {
		Ban bool `json:"ban"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	if err := h.adminService.BanUser(userID, req.Ban); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	var message string
	if req.Ban {
		message = "Пользователь заблокирован"
	} else {
		message = "Пользователь разблокирован"
	}
	return c.JSON(fiber.Map{"status": "success", "message": message})
}

func (h *AdminHandler) GetSuspiciousUsers(c *fiber.Ctx) error {
	users, err := h.adminService.GetSuspiciousUsers()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"suspicious_users": users})
}

func (h *AdminHandler) CheckForbiddenWords(c *fiber.Ctx) error {
	var req struct {
		Text string `json:"text"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	forbiddenWords := h.adminService.CheckForbiddenWords(req.Text)
	response := fiber.Map{"forbidden_words": forbiddenWords}
	log.Printf("CheckForbiddenWords response: %v", response)
	return c.JSON(response)
}

func (h *AdminHandler) ReportForbiddenWordsAttempt(c *fiber.Ctx) error {
	var req struct {
		AccountID      string   `json:"account_id"`
		ForbiddenWords []string `json:"forbidden_words"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	if err := h.adminService.IncrementSuspiciousAttempts(req.AccountID, req.ForbiddenWords); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"status": "success"})
}
