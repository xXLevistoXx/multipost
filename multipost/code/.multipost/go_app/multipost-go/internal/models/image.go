package models

import "time"

type Image struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Data      []byte    `json:"data"`
	PostID    string    `json:"post_id" gorm:"constraint:OnDelete:CASCADE"` // Добавляем CASCADE
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
