package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"golang.org/x/oauth2"
	"gorm.io/gorm"
	"io"
	"math/rand"
	"multipost-go/config"
	"multipost-go/internal/models"
	"multipost-go/internal/services"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

type AuthHandler struct {
	authService *services.AuthService
	vkService   *services.VKService
	cfg         *config.Config
	oauthConfig *oauth2.Config
}

func NewAuthHandler(authService *services.AuthService, cfg *config.Config) *AuthHandler {
	oauthConfig := &oauth2.Config{
		ClientID:     cfg.RedditClientID,
		ClientSecret: cfg.RedditClientSecret,
		RedirectURL:  cfg.RedditRedirectURI,
		Scopes:       []string{"identity", "submit", "mysubreddits"},
		Endpoint: oauth2.Endpoint{
			AuthURL:  "https://www.reddit.com/api/v1/authorize",
			TokenURL: "https://www.reddit.com/api/v1/access_token",
		},
	}
	vkService := services.NewVKService(cfg.VKClientID, "5.199")
	InitVkAuth(cfg)
	return &AuthHandler{
		authService: authService,
		vkService:   vkService,
		cfg:         cfg,
		oauthConfig: oauthConfig,
	}
}

func InitVkAuth(cfg *config.Config) {
	os.Setenv("VKGROUPACCESSTOKEN", cfg.VKGroupAccessToken)
	os.Setenv("VKAPIVERSION", "5.199")
	os.Setenv("VKCLIENTID", cfg.VKClientID)
	os.Setenv("VKCLIENTSECRET", cfg.VKClientSecret)
	os.Setenv("VKREDIRECTURI", cfg.VKRedirectURI)
	os.Setenv("VKTOKENURL", "https://oauth.vk.com/access_token")
}

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var req services.RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	resp, err := h.authService.Register(req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(resp)
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req services.LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	resp, err := h.authService.Login(req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(resp)
}

func (h *AuthHandler) UpdateSocialAuth(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	platform := c.Params("platform")
	fmt.Printf("Received request: platform=%s, userID=%s\n", platform, userID)

	var req struct {
		Auth    bool   `json:"auth"`
		Session string `json:"session"`
	}
	if err := c.BodyParser(&req); err != nil {
		fmt.Printf("UpdateSocialAuth: failed to parse request body: %v\n", err)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	fmt.Printf("UpdateSocialAuth: platform=%s, userID=%s, auth=%v, session=%s\n", platform, userID, req.Auth, req.Session[:50]+"...")

	if platform == "telegram" {
		if req.Session == "" && req.Auth {
			fmt.Println("UpdateSocialAuth: telegram session is empty")
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Телеграм сессия не может быть пустой, когда авторизован"})
		}
		if err := h.authService.UpdateTelegramAuth(userID, req.Session, req.Auth); err != nil {
			fmt.Printf("UpdateSocialAuth: failed to update telegram auth: %v\n", err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	} else {
		if err := h.authService.UpdateSocialAuth(userID, platform, req.Auth); err != nil {
			fmt.Printf("UpdateSocialAuth: failed to update %s auth: %v\n", platform, err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}

	return c.JSON(fiber.Map{"status": "success"})
}

func (h *AuthHandler) RedditAuth(c *fiber.Ctx) error {
	accountID := c.Query("accountID")
	if accountID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Пропущен accountID"})
	}

	state := fmt.Sprintf("reddit|%s", accountID)

	authURL := h.oauthConfig.Endpoint.AuthURL
	values := url.Values{}
	values.Set("client_id", h.oauthConfig.ClientID)
	values.Set("response_type", "code")
	values.Set("state", state)
	values.Set("redirect_uri", h.oauthConfig.RedirectURL)
	values.Set("duration", "permanent")
	values.Set("scope", strings.Join(h.oauthConfig.Scopes, " "))

	finalURL := fmt.Sprintf("%s?%s", authURL, values.Encode())
	fmt.Printf("Redirecting to Reddit auth URL: %s\n", finalURL)
	return c.Redirect(finalURL)
}

func (h *AuthHandler) RedditCallback(c *fiber.Ctx) error {
	code := c.Query("code")
	state := c.Query("state")
	fmt.Printf("RedditCallback: code=%s, state=%s\n", code, state)
	if code == "" || state == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "пропущен код или состояние"})
	}

	parts := strings.Split(state, "|")
	if len(parts) != 2 || parts[0] != "reddit" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "неправильный формат состояния"})
	}
	userID := parts[1]
	fmt.Printf("RedditCallback: userID=%s\n", userID)

	data := url.Values{}
	data.Set("grant_type", "authorization_code")
	data.Set("code", code)
	data.Set("redirect_uri", h.oauthConfig.RedirectURL)

	req, err := http.NewRequest("POST", "https://www.reddit.com/api/v1/access_token", strings.NewReader(data.Encode()))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "не удалось создать токен запроса"})
	}

	req.SetBasicAuth(h.oauthConfig.ClientID, h.oauthConfig.ClientSecret)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("User-Agent", "android:com.example.multipost:1.0 (by /u/Huge-Ad4304)")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("RedditCallback: failed to exchange code for token: %v\n", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "ошибка обмена кода на токен"})
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		fmt.Printf("RedditCallback: failed to get token, status: %s, body: %s\n", resp.Status, string(body))
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to get token, status: " + resp.Status,
			"body":  string(body),
		})
	}

	var tokenResp struct {
		AccessToken  string `json:"access_token"`
		TokenType    string `json:"token_type"`
		ExpiresIn    int    `json:"expires_in"`
		RefreshToken string `json:"refresh_token"`
		Scope        string `json:"scope"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&tokenResp); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "не удалось спарсить токен"})
	}
	fmt.Printf("RedditCallback: tokenResp=%+v\n", tokenResp)

	userReq, err := http.NewRequest("GET", "https://oauth.reddit.com/api/v1/me", nil)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to create user request"})
	}
	userReq.Header.Set("Authorization", "Bearer "+tokenResp.AccessToken)
	userReq.Header.Set("User-Agent", "android:com.example.multipost:1.0 (by /u/Huge-Ad4304)")

	userResp, err := client.Do(userReq)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to get user info"})
	}
	defer userResp.Body.Close()

	if userResp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(userResp.Body)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to get user info, status: " + userResp.Status,
			"body":  string(body),
		})
	}

	var userInfo struct {
		Name string `json:"name"`
	}
	if err := json.NewDecoder(userResp.Body).Decode(&userInfo); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to parse user info"})
	}

	subsReq, err := http.NewRequest("GET", "https://oauth.reddit.com/subreddits/mine/moderator", nil)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to create subreddits request"})
	}
	subsReq.Header.Set("Authorization", "Bearer "+tokenResp.AccessToken)
	subsReq.Header.Set("User-Agent", "android:com.example.multipost:1.0 (by /u/Huge-Ad4304)")

	subsResp, err := client.Do(subsReq)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to get subreddits"})
	}
	defer subsResp.Body.Close()

	if subsResp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(subsResp.Body)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed to get subreddits, status: " + subsResp.Status,
			"body":  string(body),
		})
	}

	var subsData struct {
		Data struct {
			Children []struct {
				Data struct {
					DisplayName   string `json:"display_name"`
					URL           string `json:"url"`
					IconImg       string `json:"icon_img"`
					CommunityIcon string `json:"community_icon"`
					HeaderImg     string `json:"header_img"`
				} `json:"data"`
			} `json:"children"`
		} `data`
	}
	if err := json.NewDecoder(subsResp.Body).Decode(&subsData); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "не удалось спарсить субреддиты"})
	}

	if err := h.authService.UpdateRedditAuth(userID, tokenResp.AccessToken, tokenResp.RefreshToken, true); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "не удалось обновить пользователя"})
	}

	var links []models.Link
	now := time.Now()
	for _, child := range subsData.Data.Children {
		avatar := child.Data.IconImg
		if avatar == "" {
			avatar = child.Data.CommunityIcon
		}
		if avatar == "" {
			avatar = child.Data.HeaderImg
		}
		if avatar == "" {
			avatar = "https://www.redditstatic.com/avatars/defaults/v2/avatar_default_4.png"
		}
		if strings.Contains(avatar, "?") {
			avatar = strings.Split(avatar, "?")[0]
		}

		link := models.Link{
			ID:           uuid.New().String(),
			UserID:       userID,
			SocialID:     child.Data.DisplayName,
			Platform:     "reddit",
			AccessToken:  tokenResp.AccessToken,
			Avatar:       avatar,
			CreatedAt:    now,
			UpdatedAt:    now,
			MainUsername: child.Data.DisplayName,
		}
		links = append(links, link)
	}

	if err := h.authService.SaveLinks(links); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "не удалось сохранить каналы"})
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"links":  links,
	})
}

type ExchangeRequest struct {
	Code         string `json:"code" binding:"required"`
	DeviceID     string `json:"device_id" binding:"required"`
	CodeVerifier string `json:"code_verifier" binding:"required"`
	AccountID    string `json:"accountID" binding:"required"`
}

func (h *AuthHandler) VKExchange(c *fiber.Ctx) error {
	var req ExchangeRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный формат запроса"})
	}

	fmt.Printf("Received code at: %s, code=%s, device_id=%s, code_verifier=%s\n", time.Now().Format(time.RFC3339), req.Code, req.DeviceID, req.CodeVerifier)

	payload := fmt.Sprintf(
		"grant_type=authorization_code&code=%s&device_id=%s&client_id=%s&client_secret=%s&redirect_uri=%s&code_verifier=%s",
		req.Code, req.DeviceID, os.Getenv("VKCLIENTID"), os.Getenv("VKCLIENTSECRET"), os.Getenv("VKREDIRECTURI"), req.CodeVerifier,
	)
	fmt.Printf("Sending VK token exchange request: %s\n", payload)

	request, err := http.NewRequest("POST", os.Getenv("VKTOKENURL"), strings.NewReader(payload))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Не удалось создать запрос"})
	}

	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{}
	fmt.Printf("Sending request at: %s\n", time.Now().Format(time.RFC3339))
	resp, err := client.Do(request)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": fmt.Sprintf("Не удалось отправить запрос к VK: %v", err)})
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Не удалось прочитать ответ"})
	}

	fmt.Printf("VK token exchange response: status=%d, body=%s\n", resp.StatusCode, string(body))

	if resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(fiber.Map{"vk_error": string(body)})
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Не удалось распарсить ответ VK"})
	}

	accessToken, ok := result["access_token"].(string)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Не удалось извлечь access_token"})
	}

	userIDFloat, ok := result["user_id"].(float64)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Не удалось извлечь user_id"})
	}
	userID := fmt.Sprintf("%.0f", userIDFloat)

	links, err := h.vkService.GetUserGroups(userID, accessToken)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": fmt.Sprintf("Не удалось получить группы: %v", err)})
	}

	if err := h.authService.SaveLinks(links); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": fmt.Sprintf("Не удалось сохранить ссылки: %v", err)})
	}

	if err := h.authService.UpdateVKAuth(req.AccountID, accessToken, true); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": fmt.Sprintf("Не удалось обновить авторизацию VK: %v", err)})
	}

	return c.JSON(fiber.Map{
		"message":      "ok",
		"access_token": accessToken,
		"links":        links,
	})
}

func (h *AuthHandler) VKCallback(c *fiber.Ctx) error {
	code := c.Query("code")
	state := c.Query("state")
	accountID := c.Query("accountID")

	if code == "" || state == "" || accountID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "missing code, state or accountID"})
	}

	// Проверка state для безопасности (здесь можно добавить логику сравнения с сохраненным state)
	payload := map[string]string{
		"code":          code,
		"device_id":     uuid.New().String(),
		"code_verifier": _generateCodeVerifier(),
		"accountID":     accountID,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to marshal payload"})
	}

	resp, err := http.Post("http://localhost/auth/vk/exchange", "application/json", bytes.NewBuffer(body))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": fmt.Sprintf("failed to exchange code: %v", err)})
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to decode response"})
	}

	return c.JSON(result)
}

func (h *AuthHandler) GetVKGroups(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	if userID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "missing user_id"})
	}

	var user models.User
	if err := h.authService.Db.Where("id = ?", userID).First(&user).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "user not found"})
	}

	if user.VKAccessToken == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "user not authenticated with VK"})
	}

	links, err := h.vkService.GetUserGroups(userID, user.VKAccessToken)
	if err != nil {
		// Если ошибка с пользовательским токеном, попробуем VKGROUPACCESSTOKEN
		accessToken := os.Getenv("VKGROUPACCESSTOKEN")
		if accessToken == "" {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "VK group access token is not set"})
		}
		links, err = h.vkService.GetGroupsWithGroupToken(accessToken)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"links":  links,
	})
}

func (h *AuthHandler) GetUser(c *fiber.Ctx) error {
	requestedID := c.Params("id")
	fmt.Printf("GetUser: requestedID=%s, userID from token=%v\n", requestedID, c.Locals("user_id"))

	// Проверка: совпадает ли ID из токена с запрашиваемым ID (для безопасности)
	if c.Locals("user_id") != nil && requestedID != c.Locals("user_id").(string) {
		fmt.Println("GetUser: Forbidden - requested ID does not match token user_id")
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Недостаточно прав для доступа к данным другого пользователя"})
	}

	user, err := h.authService.GetUser(requestedID)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			fmt.Printf("GetUser: user not found with ID %s\n", requestedID)
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Пользователь не найден"})
		}
		fmt.Printf("GetUser: failed to query user with ID %s: %v\n", requestedID, err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Внутренняя ошибка сервера"})
	}
	return c.JSON(user)
}

func (h *AuthHandler) GetUserByLogin(c *fiber.Ctx) error {
	var req struct {
		Login string `json:"login"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Неверный запрос"})
	}

	user, err := h.authService.GetUserByLogin(req.Login)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Пользователь не найден"})
	}

	token, err := h.authService.GenerateToken(user.ID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Не удалось сгенерировать токен"})
	}

	return c.JSON(fiber.Map{
		"user":  user,
		"token": token,
	})
}

// Вспомогательная функция для генерации code_verifier
func _generateCodeVerifier() string {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
	result := make([]byte, 64)
	for i := range result {
		result[i] = chars[rand.Intn(len(chars))]
	}
	return string(result)
}
