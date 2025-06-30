package models

import "time"

type User struct {
	ID                 string    `json:"id" gorm:"primaryKey;type:text"`
	Login              string    `json:"login" gorm:"unique"`
	PasswordHash       string    `json:"password_hash"`
	TelegramAuth       bool      `json:"telegram_auth"`
	RedditAuth         bool      `json:"reddit_auth"`
	VKAuth             bool      `json:"vk_auth"`
	RedditAccessToken  string    `json:"reddit_access_token"`
	RedditRefreshToken string    `json:"reddit_refresh_token"`
	VKAccessToken      string    `json:"vk_access_token"`
	TelegramSession    string    `json:"telegram_session"`
	Role               string    `json:"role" gorm:"default:'User'"`
	IsBanned           bool      `json:"is_banned" gorm:"default:false"`
	SuspiciousAttempts int       `json:"suspicious_attempts" gorm:"default:0"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}

type ForbiddenWord struct {
	Word      string    `json:"word" gorm:"primaryKey;type:text"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type SuspiciousUser struct {
	ID        string    `json:"id" gorm:"primaryKey;type:text"`
	UserID    string    `json:"user_id"`
	Reason    string    `json:"reason"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
