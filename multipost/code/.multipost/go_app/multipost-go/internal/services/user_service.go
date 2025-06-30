package services

import (
	"github.com/dgrijalva/jwt-go"
	"gorm.io/gorm"
	"multipost-go/internal/models"
	"time"
)

type UserService struct {
	db *gorm.DB
}

func NewUserService(db *gorm.DB) *UserService {
	return &UserService{db: db}
}

func (s *UserService) CreateUser(user models.User) (string, error) {
	if err := s.db.Create(&user).Error; err != nil {
		return "", err
	}

	token, err := s.GenerateToken(user.ID)
	if err != nil {
		return "", err
	}

	return token, nil
}

func (s *UserService) GetUserByLogin(login string) (*models.User, error) {
	var user models.User
	if err := s.db.Where("login = ?", login).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (s *UserService) UpdateSocialAuth(userID, platform string, auth bool) error {
	var user models.User
	if err := s.db.Where("id = ?", userID).First(&user).Error; err != nil {
		return err
	}

	if platform == "telegram" {
		user.TelegramAuth = auth
	} else if platform == "reddit" {
		user.RedditAuth = auth
	}

	return s.db.Save(&user).Error
}

func (s *UserService) UpdateRedditAuth(userID string, auth bool, accessToken string) error {
	var user models.User
	if err := s.db.Where("id = ?", userID).First(&user).Error; err != nil {
		return err
	}

	user.RedditAuth = auth
	user.RedditAccessToken = accessToken
	return s.db.Save(&user).Error
}

func (s *UserService) GenerateToken(userID string) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	})

	return token.SignedString([]byte("your_jwt_secret"))
}
