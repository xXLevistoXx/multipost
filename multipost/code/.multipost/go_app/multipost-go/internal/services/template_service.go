package services

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
	"multipost-go/internal/models"
	"time"
)

type TemplateService struct {
	db *gorm.DB
}

func NewTemplateService(db *gorm.DB) *TemplateService {
	return &TemplateService{db: db}
}

type CreateTemplateRequest struct {
	Name        string `json:"name"`
	Title       string `json:"title"`
	Description string `json:"description"`
}

func (s *TemplateService) CreateTemplate(userID string, req CreateTemplateRequest) (*models.Template, error) {
	template := models.Template{
		ID:          uuid.New().String(),
		Name:        req.Name,
		Title:       req.Title,
		Description: req.Description,
		UserID:      userID,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := s.db.Create(&template).Error; err != nil {
		return nil, err
	}

	return &template, nil
}

func (s *TemplateService) GetTemplates(userID string) ([]models.Template, error) {
	var templates []models.Template
	if err := s.db.Where("user_id = ?", userID).Find(&templates).Error; err != nil {
		return nil, err
	}
	return templates, nil
}

func (s *TemplateService) UpdateTemplate(userID, templateID string, req CreateTemplateRequest) (*models.Template, error) {
	var template models.Template
	if err := s.db.Where("id = ? AND user_id = ?", templateID, userID).First(&template).Error; err != nil {
		return nil, err
	}

	template.Name = req.Name
	template.Title = req.Title
	template.Description = req.Description
	template.UpdatedAt = time.Now()

	if err := s.db.Save(&template).Error; err != nil {
		return nil, err
	}

	return &template, nil
}

func (s *TemplateService) DeleteTemplate(userID, templateID string) error {
	var template models.Template
	if err := s.db.Where("id = ? AND user_id = ?", templateID, userID).First(&template).Error; err != nil {
		return err
	}

	if err := s.db.Delete(&template).Error; err != nil {
		return err
	}
	return nil
}
