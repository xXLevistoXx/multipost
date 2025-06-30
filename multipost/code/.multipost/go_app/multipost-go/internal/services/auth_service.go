package services

import (
	"errors"
	"fmt"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
	"multipost-go/internal/models"
	"time"
)

type AuthService struct {
	Db        *gorm.DB
	jwtSecret string
}

func NewAuthService(db *gorm.DB, jwtSecret string) *AuthService {
	return &AuthService{
		Db:        db,
		jwtSecret: jwtSecret,
	}
}

type RegisterRequest struct {
	Login    string `json:"login"`
	Password string `json:"password"`
}

type LoginRequest struct {
	Login    string `json:"login"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Token string      `json:"token"`
	User  models.User `json:"user"`
}

func (s *AuthService) Register(req RegisterRequest) (*AuthResponse, error) {
	if req.Login == "" {
		return nil, fmt.Errorf("Логин не может быть пустым")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	user := models.User{
		ID:           uuid.New().String(),
		Login:        req.Login,
		PasswordHash: string(hashedPassword),
		TelegramAuth: false,
		RedditAuth:   false,
		VKAuth:       false,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	if err := s.Db.Create(&user).Error; err != nil {
		return nil, err
	}

	token, err := s.GenerateToken(user.ID)
	if err != nil {
		return nil, err
	}

	return &AuthResponse{Token: token, User: user}, nil
}

func (s *AuthService) Login(req LoginRequest) (*AuthResponse, error) {
	var user models.User
	if err := s.Db.Where("login = ?", req.Login).First(&user).Error; err != nil {
		return nil, errors.New("user not found")
	}

	if user.IsBanned {
		return nil, errors.New("Пользователь заллокирован и не сможет войти в систему")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, errors.New("Неверный пароль")
	}

	token, err := s.GenerateToken(user.ID)
	if err != nil {
		return nil, err
	}

	return &AuthResponse{Token: token, User: user}, nil
}

func (s *AuthService) GenerateToken(userID string) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	})

	tokenString, err := token.SignedString([]byte(s.jwtSecret))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

func (s *AuthService) UpdateTelegramAuth(userID string, session string, auth bool) error {
	return s.Db.Model(&models.User{}).
		Where("id = ?", userID).
		Updates(map[string]interface{}{
			"telegram_auth":    auth,
			"telegram_session": session,
			"updated_at":       time.Now(),
		}).Error
}

func (s *AuthService) UpdateSocialAuth(userID, platform string, auth bool) error {
	var user models.User
	if err := s.Db.Where("id = ?", userID).First(&user).Error; err != nil {
		return err
	}

	if platform == "telegram" {
		user.TelegramAuth = auth
	} else if platform == "reddit" {
		user.RedditAuth = auth
	} else {
		return fmt.Errorf("Неверная соцсеть: %s", platform)
	}

	user.UpdatedAt = time.Now()
	return s.Db.Save(&user).Error
}

func (s *AuthService) UpdateRedditAuth(userID, accessToken, refreshToken string, auth bool) error {
	return s.Db.Model(&models.User{}).
		Where("id = ?", userID).
		Updates(map[string]interface{}{
			"reddit_auth":          auth,
			"reddit_access_token":  accessToken,
			"reddit_refresh_token": refreshToken,
			"updated_at":           time.Now(),
		}).Error
}

func (s *AuthService) UpdateVKAuth(userID, accessToken string, auth bool) error {
	return s.Db.Model(&models.User{}).
		Where("id = ?", userID).
		Updates(map[string]interface{}{
			"vk_access_token": accessToken,
			"vk_auth":         auth,
			"updated_at":      time.Now(),
		}).Error
}

func (s *AuthService) SaveLinks(links []models.Link) error {
	now := time.Now()
	for i := range links {
		links[i].ID = uuid.New().String()
		links[i].CreatedAt = now
		links[i].UpdatedAt = now
	}
	return s.Db.Create(&links).Error
}

func (s *AuthService) GetUser(userID string) (*models.User, error) {
	var user models.User
	if err := s.Db.Where("id = ?", userID).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (s *AuthService) GetUserByLogin(login string) (*models.User, error) {
	var user models.User
	if err := s.Db.Where("login = ?", login).First(&user).Error; err != nil {
		return nil, errors.New("пользователь не найден")
	}
	return &user, nil
}
