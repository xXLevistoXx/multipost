package handlers

import (
	"github.com/gofiber/fiber/v2"
	"multipost-go/internal/services"
)

type TemplateHandler struct {
	templateService *services.TemplateService
}

func NewTemplateHandler(templateService *services.TemplateService) *TemplateHandler {
	return &TemplateHandler{templateService: templateService}
}

func (h *TemplateHandler) CreateTemplate(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	var req services.CreateTemplateRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	template, err := h.templateService.CreateTemplate(userID, req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(template)
}

func (h *TemplateHandler) GetTemplates(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	templates, err := h.templateService.GetTemplates(userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(templates)
}

func (h *TemplateHandler) UpdateTemplate(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	templateID := c.Params("id")
	var req services.CreateTemplateRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный зпрос"})
	}

	template, err := h.templateService.UpdateTemplate(userID, templateID, req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(template)
}

func (h *TemplateHandler) DeleteTemplate(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	templateID := c.Params("id")

	if err := h.templateService.DeleteTemplate(userID, templateID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"status": "success"})
}
