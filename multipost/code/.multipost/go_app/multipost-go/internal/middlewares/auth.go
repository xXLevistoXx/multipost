package middlewares

import (
	"fmt"
	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
	"multipost-go/config"
	"multipost-go/internal/models"
	"strings"
)

func AuthMiddleware() fiber.Handler {
	cfg := config.LoadConfig()
	return func(c *fiber.Ctx) error {
		tokenString := c.Get("Authorization")
		if tokenString == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Упущен токен"})
		}

		fmt.Printf("Received Authorization header: %s\n", tokenString)
		tokenString = strings.TrimPrefix(tokenString, "Bearer ")
		if tokenString == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Неверный формат токена"})
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return []byte(cfg.JWTSecret), nil
		})
		if err != nil || !token.Valid {
			fmt.Printf("Token parsing error: %v\n", err)
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Неверный токен"})
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid token claims"})
		}

		userID, ok := claims["user_id"].(string)
		if !ok {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Неверный ID пользователя"})
		}

		c.Locals("user_id", userID)
		return c.Next()
	}
}

func AdminMiddleware(db *gorm.DB) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userID := c.Locals("user_id").(string)
		var user models.User
		if err := db.Where("id = ?", userID).First(&user).Error; err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "пользователь не найден"})
		}

		if user.Role != "Admin" {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Access denied: Admin role required"})
		}

		return c.Next()
	}
}
