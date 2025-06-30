package models

import (
	"time"
)

type Post struct {
	ID          string     `json:"id" gorm:"primaryKey;type:text"`
	Title       string     `json:"title"`
	Description string     `json:"description"`
	Images      []Image    `json:"images"`
	Socials     []Link     `json:"socials" gorm:"many2many:post_links;foreignKey:ID;joinForeignKey:PostID;References:ID;joinReferences:LinkID;constraint:OnDelete:CASCADE"`
	ScheduledAt *time.Time `json:"scheduled_at"`
	Published   bool       `json:"published"`
	UserID      string     `json:"user_id"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
	Platform    string     `json:"platform"` // Новое поле (telegram, vk, reddit)
}
