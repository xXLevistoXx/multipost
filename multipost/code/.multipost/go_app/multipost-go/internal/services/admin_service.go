package services

import (
	"fmt"
	"github.com/google/uuid"
	"golang.org/x/text/cases" // Добавляем для корректной работы с Unicode
	"golang.org/x/text/language"
	"gorm.io/gorm"
	"multipost-go/internal/models"
	"strings"
	"time"
)

type AdminService struct {
	db *gorm.DB
}

func NewAdminService(db *gorm.DB) *AdminService {
	return &AdminService{db: db}
}

func (s *AdminService) GetAllUsers() ([]models.User, error) {
	var users []models.User
	if err := s.db.Find(&users).Error; err != nil {
		return nil, err
	}
	return users, nil
}

func (s *AdminService) UpdateUserRole(userID, newRole string) error {
	if newRole != "User" && newRole != "Admin" {
		return fmt.Errorf("Неверная роль: %s", newRole)
	}

	var user models.User
	if err := s.db.Where("id = ?", userID).First(&user).Error; err != nil {
		return err
	}

	if user.Role == "Admin" && newRole == "User" {
		var adminCount int64
		s.db.Model(&models.User{}).Where("role = ? AND id != ?", "Admin", userID).Count(&adminCount)
		if adminCount == 0 {
			return fmt.Errorf("Нельзя удалить последнего админа")
		}
	}

	user.Role = newRole
	user.UpdatedAt = time.Now()
	return s.db.Save(&user).Error
}

func (s *AdminService) AddForbiddenWord(word string) error {
	// Используем cases для корректной работы с Unicode
	caser := cases.Lower(language.Russian)
	word = caser.String(strings.TrimSpace(word))
	if word == "" {
		return fmt.Errorf("Слово не может быть пустым")
	}

	var existing models.ForbiddenWord
	if err := s.db.Where("word = ?", word).First(&existing).Error; err == nil {
		return fmt.Errorf("Слово уже существует")
	}

	forbiddenWord := models.ForbiddenWord{
		Word:      word,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	return s.db.Create(&forbiddenWord).Error
}

func (s *AdminService) GetForbiddenWords() ([]models.ForbiddenWord, error) {
	var words []models.ForbiddenWord
	if err := s.db.Find(&words).Error; err != nil {
		return nil, err
	}
	return words, nil
}

func (s *AdminService) DeleteForbiddenWord(word string) *gorm.DB {
	// Приводим слово к нижнему регистру с учетом Unicode
	caser := cases.Lower(language.Russian)
	return s.db.Where("word = ?", caser.String(word)).Delete(&models.ForbiddenWord{})
}

func (s *AdminService) BanUser(userID string, ban bool) error {
	var user models.User
	if err := s.db.Where("id = ?", userID).First(&user).Error; err != nil {
		return err
	}

	if user.Role == "Admin" {
		return fmt.Errorf("Нельзя забанить админа")
	}

	user.IsBanned = ban
	user.UpdatedAt = time.Now()
	return s.db.Save(&user).Error
}

func (s *AdminService) CheckForbiddenWords(text string) []string {
	var forbiddenWords []models.ForbiddenWord
	s.db.Find(&forbiddenWords)

	var foundWords []string
	caser := cases.Lower(language.Russian)
	lowerText := caser.String(text)
	for _, fw := range forbiddenWords {
		if strings.Contains(lowerText, fw.Word) {
			foundWords = append(foundWords, fw.Word)
		}
	}
	return foundWords
}

func (s *AdminService) IncrementSuspiciousAttempts(userID string, forbiddenWords []string) error {
	var user models.User
	if err := s.db.Where("id = ?", userID).First(&user).Error; err != nil {
		return err
	}

	user.SuspiciousAttempts++
	if user.SuspiciousAttempts >= 5 {
		suspicious := models.SuspiciousUser{
			ID:        uuid.New().String(),
			UserID:    userID,
			Reason:    "Вы используете запрещенные слова: " + strings.Join(forbiddenWords, ", "),
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}
		if err := s.db.Create(&suspicious).Error; err != nil {
			return err
		}
	}

	user.UpdatedAt = time.Now()
	return s.db.Save(&user).Error
}

func (s *AdminService) GetSuspiciousUsers() ([]models.SuspiciousUser, error) {
	var suspiciousUsers []models.SuspiciousUser
	if err := s.db.Find(&suspiciousUsers).Error; err != nil {
		return nil, err
	}
	return suspiciousUsers, nil
}
