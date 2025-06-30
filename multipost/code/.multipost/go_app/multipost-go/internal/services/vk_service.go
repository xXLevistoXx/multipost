package services

import (
	"encoding/json"
	"fmt"
	"io"
	"multipost-go/internal/models"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/google/uuid"
	"time"
)

type VKService struct {
	ClientID   string
	ApiVersion string
}

func NewVKService(clientID, apiVersion string) *VKService {
	return &VKService{
		ClientID:   clientID,
		ApiVersion: apiVersion,
	}
}

type VKUser struct {
	UserID    string `json:"user_id"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Phone     string `json:"phone"`
	Avatar    string `json:"avatar"`
	Email     string `json:"email"`
}

type VKUserResponse struct {
	User  VKUser `json:"user"`
	Error struct {
		ErrorMsg string `json:"error_msg"`
	} `json:"error"`
}

type VKGroupItem struct {
	ID         int    `json:"id"`
	Name       string `json:"name"`
	ScreenName string `json:"screen_name"`
	IsClosed   int    `json:"is_closed"`
	Type       string `json:"type"`
	Photo50    string `json:"photo_50"`
	Photo100   string `json:"photo_100"`
	Photo200   string `json:"photo_200"`
}

type VKGroupResponse struct {
	Count int           `json:"count"`
	Items []VKGroupItem `json:"items"`
}

type VKRootResponse struct {
	Response VKGroupResponse `json:"response"`
	Error    struct {
		ErrorMsg string `json:"error_msg"`
	} `json:"error"`
}

type VKTokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	IDToken      string `json:"id_token"`
	ExpiresIn    int    `json:"expires_in"`
	UserID       string `json:"user_id"`
	Email        string `json:"email"`
	Phone        string `json:"phone"`
	Error        struct {
		ErrorMsg string `json:"error_msg"`
	} `json:"error"`
}

func (s *VKService) ExchangeCode(code, deviceID, codeVerifier, redirectURI string) (VKTokenResponse, error) {
	data := url.Values{}
	data.Set("grant_type", "authorization_code")
	data.Set("code", code)
	data.Set("device_id", deviceID)
	data.Set("client_id", s.ClientID)
	data.Set("client_secret", os.Getenv("VKCLIENTSECRET")) // Добавляем client_secret
	data.Set("redirect_uri", redirectURI)
	data.Set("code_verifier", codeVerifier)

	client := &http.Client{}
	req, err := http.NewRequest("POST", os.Getenv("VKTOKENURL"), strings.NewReader(data.Encode()))
	if err != nil {
		return VKTokenResponse{}, fmt.Errorf("failed to create request: %v", err)
	}
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	resp, err := client.Do(req)
	if err != nil {
		return VKTokenResponse{}, fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return VKTokenResponse{}, fmt.Errorf("failed to read response: %v", err)
	}

	var tokenResp VKTokenResponse
	if err := json.Unmarshal(body, &tokenResp); err != nil {
		return VKTokenResponse{}, fmt.Errorf("failed to decode response: %v, body: %s", err, string(body))
	}

	if tokenResp.Error.ErrorMsg != "" {
		return VKTokenResponse{}, fmt.Errorf("VK API error: %s", tokenResp.Error.ErrorMsg)
	}

	return tokenResp, nil
}

func (s *VKService) GetUserInfo(accessToken string) (VKUser, error) {
	data := url.Values{}
	data.Set("client_id", s.ClientID)
	data.Set("access_token", accessToken)
	data.Set("v", s.ApiVersion)

	client := &http.Client{}
	url := "https://id.vk.com/oauth2/user_info"
	req, err := http.NewRequest(http.MethodPost, url, strings.NewReader(data.Encode()))
	if err != nil {
		return VKUser{}, fmt.Errorf("failed to create request: %v", err)
	}
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	resp, err := client.Do(req)
	if err != nil {
		return VKUser{}, fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return VKUser{}, fmt.Errorf("failed to read response: %v", err)
	}

	var userResp VKUserResponse
	if err := json.Unmarshal(body, &userResp); err != nil {
		return VKUser{}, fmt.Errorf("failed to decode response: %v", err)
	}

	if userResp.Error.ErrorMsg != "" {
		return VKUser{}, fmt.Errorf("VK API error: %s", userResp.Error.ErrorMsg)
	}

	return userResp.User, nil
}

func (s *VKService) GetUserGroups(userID, accessToken string) ([]models.Link, error) {
	data := url.Values{}
	data.Set("access_token", accessToken)
	data.Set("user_id", userID)
	data.Set("extended", "1")
	data.Set("filter", "admin")
	data.Set("v", s.ApiVersion)

	url := fmt.Sprintf("%s?%s", "https://api.vk.com/method/groups.get", data.Encode())
	resp, err := http.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %v", err)
	}

	var groups VKRootResponse
	if err := json.Unmarshal(body, &groups); err != nil {
		return nil, fmt.Errorf("failed to decode response: %v", err)
	}

	if groups.Error.ErrorMsg != "" {
		return nil, fmt.Errorf("VK API error: %s", groups.Error.ErrorMsg)
	}

	var links []models.Link
	now := time.Now()
	for _, item := range groups.Response.Items {
		avatar := item.Photo200
		if avatar == "" {
			avatar = item.Photo100
		}
		if avatar == "" {
			avatar = item.Photo50
		}
		if avatar == "" {
			avatar = "https://vk.com/images/community_50.png"
		}
		link := models.Link{
			ID:           uuid.New().String(),
			UserID:       userID,
			SocialID:     fmt.Sprintf("%d", item.ID),
			Platform:     "vk",
			AccessToken:  accessToken,
			Title:        item.Name,
			MainUsername: item.ScreenName,
			Avatar:       avatar,
			CreatedAt:    now,
			UpdatedAt:    now,
		}
		links = append(links, link)
	}

	return links, nil
}

func (s *VKService) GetGroupsWithGroupToken(accessToken string) ([]models.Link, error) {
	data := url.Values{}
	data.Set("access_token", accessToken)
	data.Set("extended", "1")
	data.Set("filter", "admin")
	data.Set("v", s.ApiVersion)

	url := fmt.Sprintf("%s?%s", "https://api.vk.com/method/groups.get", data.Encode())
	resp, err := http.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %v", err)
	}

	var groups VKRootResponse
	if err := json.Unmarshal(body, &groups); err != nil {
		return nil, fmt.Errorf("failed to decode response: %v", err)
	}

	if groups.Error.ErrorMsg != "" {
		return nil, fmt.Errorf("VK API error: %s", groups.Error.ErrorMsg)
	}

	var links []models.Link
	now := time.Now()
	for _, item := range groups.Response.Items {
		avatar := item.Photo200
		if avatar == "" {
			avatar = item.Photo100
		}
		if avatar == "" {
			avatar = item.Photo50
		}
		if avatar == "" {
			avatar = "https://vk.com/images/community_50.png"
		}
		link := models.Link{
			ID:           uuid.New().String(),
			SocialID:     fmt.Sprintf("%d", item.ID),
			Platform:     "vk",
			AccessToken:  accessToken,
			Title:        item.Name,
			MainUsername: item.ScreenName,
			Avatar:       avatar,
			CreatedAt:    now,
			UpdatedAt:    now,
		}
		links = append(links, link)
	}

	return links, nil
}
