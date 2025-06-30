package main

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"multipost-go/config"
	"multipost-go/internal/db"
	"multipost-go/internal/handlers"
	"multipost-go/internal/middlewares"
	"multipost-go/internal/services"
)

func main() {
	cfg := config.LoadConfig()
	database := db.InitDB(cfg)

	authService := services.NewAuthService(database, cfg.JWTSecret)
	adminService := services.NewAdminService(database)
	postService := services.NewPostService(database, adminService)
	publishService := services.NewPublishService(database, cfg)
	templateService := services.NewTemplateService(database)

	authHandler := handlers.NewAuthHandler(authService, cfg)
	adminHandler := handlers.NewAdminHandler(adminService)
	postHandler := handlers.NewPostHandler(postService, publishService)
	templateHandler := handlers.NewTemplateHandler(templateService)
	linkHandler := handlers.NewLinkHandler(database)

	go publishService.StartScheduledPosting()

	app := fiber.New()

	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
	}))

	// Открытые маршруты
	app.Post("/register", authHandler.Register)
	app.Post("/login", authHandler.Login)
	app.Get("/auth/reddit", authHandler.RedditAuth)
	app.Get("/auth/reddit/callback", authHandler.RedditCallback)
	app.Get("/auth/vk/callback", authHandler.VKCallback)
	app.Post("/auth/vk/exchange", authHandler.VKExchange)

	// Защищенные маршруты
	api := app.Group("/api", middlewares.AuthMiddleware())
	api.Put("/auth/:platform", authHandler.UpdateSocialAuth)
	api.Post("/posts", postHandler.CreatePost)
	api.Get("/posts", postHandler.GetPosts)
	api.Post("/posts/:id/publish", postHandler.PublishPost)
	api.Delete("/posts/:id", postHandler.DeletePost)
	api.Post("/templates", templateHandler.CreateTemplate)
	api.Get("/templates", templateHandler.GetTemplates)
	api.Put("/templates/:id", templateHandler.UpdateTemplate)
	api.Delete("/templates/:id", templateHandler.DeleteTemplate)
	api.Post("/links", linkHandler.CreateLinks)
	api.Get("/links", linkHandler.GetLinks)
	api.Post("/get_user", middlewares.AuthMiddleware(), authHandler.GetUserByLogin)
	api.Get("/vk/groups", authHandler.GetVKGroups)
	api.Get("/user/:id", middlewares.AuthMiddleware(), authHandler.GetUser)
	// Новые маршруты для FastAPI
	api.Post("/check_forbidden_words", adminHandler.CheckForbiddenWords)
	api.Post("/report_forbidden_words_attempt", adminHandler.ReportForbiddenWordsAttempt)

	// Маршруты для администраторов
	admin := api.Group("/admin", middlewares.AdminMiddleware(database))
	admin.Get("/users", adminHandler.GetAllUsers)
	admin.Put("/users/:id/role", adminHandler.UpdateUserRole)
	admin.Post("/forbidden-words", adminHandler.AddForbiddenWord)
	admin.Get("/forbidden-words", adminHandler.GetForbiddenWords)
	admin.Delete("/forbidden-words/:word", adminHandler.DeleteForbiddenWord)
	admin.Put("/users/:id/ban", adminHandler.BanUser)
	admin.Get("/suspicious-users", adminHandler.GetSuspiciousUsers)

	app.Listen(":" + cfg.Port)
}
