package models

import (
	"time"
)

type Link struct {
	ID           string    `json:"id" gorm:"primaryKey;type:text"`
	UserID       string    `json:"user_id"`
	SocialID     string    `json:"social_id"`
	Platform     string    `json:"platform"`
	AccessToken  string    `json:"access_token"`
	Title        string    `json:"title"`
	MainUsername string    `json:"main_username"`
	Avatar       string    `json:"avatar"`                          // Добавляем поле для аватара
	IsCreator    bool      `json:"is_creator" gorm:"default:false"` // Новое поле со значением по умолчанию
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}
