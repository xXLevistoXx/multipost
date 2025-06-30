package db

import (
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"log"
	"multipost-go/config"
	"multipost-go/internal/models"
	"time"

	"github.com/google/uuid"
)

func InitDB(cfg *config.Config) *gorm.DB {
	var db *gorm.DB
	var err error

	// Пытаемся подключиться к базе данных с повторными попытками
	for i := 0; i < 10; i++ {
		db, err = gorm.Open(postgres.Open(cfg.DatabaseURL), &gorm.Config{})
		if err == nil {
			break
		}
		log.Printf("Failed to connect to database: %v, retrying in 2 seconds...", err)
		time.Sleep(2 * time.Second)
	}

	if err != nil {
		log.Fatalf("Failed to connect to database after retries: %v", err)
	}

	// Автомиграция для создания и обновления таблиц
	err = db.AutoMigrate(
		&models.User{},
		&models.Link{},
		&models.Post{},
		&models.Image{},
		&models.Template{},
		&models.ForbiddenWord{},  // Новая таблица
		&models.SuspiciousUser{}, // Новая таблица
	)
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	// Проверка наличия администратора
	var adminCount int64
	db.Model(&models.User{}).Where("role = ?", "Admin").Count(&adminCount)
	if adminCount == 0 {
		log.Println("No admin found, creating default admin user...")
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
		if err != nil {
			log.Fatalf("Failed to hash admin password: %v", err)
		}
		now := time.Now()
		admin := models.User{
			ID:           uuid.New().String(),
			Login:        "admin",
			PasswordHash: string(hashedPassword),
			Role:         "Admin",
			CreatedAt:    now,
			UpdatedAt:    now,
		}
		if err := db.Create(&admin).Error; err != nil {
			log.Fatalf("Failed to create admin user: %v", err)
		}
		log.Println("Default admin created with login: admin, password: admin123")
	}

	log.Println("Database migration completed")
	return db
}
