//package config
//
//import (
//	"os"
//)

//type Config struct {
//	DatabaseURL        string
//	JWTSecret          string
//	Port               string
//	RedditClientID     string
//	RedditClientSecret string
//	RedditRedirectURI  string
//	VKClientID         string
//	VKClientSecret     string
//	VKGroupAccessToken string
//	VKRedirectURI      string
//}
//
//func LoadConfig() *Config {
//	return &Config{
//		DatabaseURL:        getEnv("DATABASE_URL", "postgres://multipost:multipost123@db:5432/multipost?sslmode=disable"),
//		JWTSecret:          getEnv("JWT_SECRET", "your-secret-key"),
//		Port:               getEnv("PORT", "8080"),
//		RedditClientID:     getEnv("REDDIT_CLIENT_ID", "rbPEXEM2hTaCd8Ea6yqVMA"),
//		RedditClientSecret: getEnv("REDDIT_CLIENT_SECRET", "_BCSC_QIbiaX6OfXQ0891ZSzTR2T4Q"),
//		RedditRedirectURI:  getEnv("REDDIT_REDIRECT_URI", "https://multipostingm.com/auth/reddit/callback"),
//		VKClientID:         getEnv("VK_CLIENT_ID", "53526931"),
//		VKClientSecret:     getEnv("VK_CLIENT_SECRET", "mG5pSuuvDx6sYA7WLRcn"),
//		VKGroupAccessToken: getEnv("VK_GROUP_ACCESS_TOKEN", "1df238f61df238f61df238f64b1ec2f96511df21df238f675eabff314a9886b3887999d"),
//		VKRedirectURI:      getEnv("VK_REDIRECT_URI", "https://multipostingm.com/auth/vk/callback"),
//	}
//}
//
//func getEnv(key, fallback string) string {
//	if value, exists := os.LookupEnv(key); exists {
//		return value
//	}
//	return fallback
//}
package config

import (
        "os"
)

type Config struct {
        DatabaseURL        string
        JWTSecret          string
        Port               string
        RedditClientID     string
        RedditClientSecret string
        RedditRedirectURI  string
        VKClientID         string
        VKClientSecret     string
        VKGroupAccessToken string
        VKRedirectURI      string
}

func LoadConfig() *Config {
        return &Config{
                DatabaseURL:        getEnv("DATABASE_URL", "postgres://multipost:multipost123@db:5432/multipost?sslmode=disable"),
                JWTSecret:          getEnv("JWT_SECRET", "your-secret-key"),
                Port:               getEnv("PORT", "8080"),
                RedditClientID:     getEnv("REDDIT_CLIENT_ID", "rbPEXEM2hTaCd8Ea6yqVMA"),
                RedditClientSecret: getEnv("REDDIT_CLIENT_SECRET", "_BCSC_QIbiaX6OfXQ0891ZSzTR2T4Q"),
                RedditRedirectURI:  getEnv("REDDIT_REDIRECT_URI", "https://multipostingm.ru/auth/reddit/callback"),
                VKClientID:         getEnv("VK_CLIENT_ID", "53526931"),
                VKClientSecret:     getEnv("VK_CLIENT_SECRET", "1df238f61df238f61df238f64b1ec2f96511df21df238f675eabff314a9886b3887999d"),
                VKGroupAccessToken: getEnv("VK_GROUP_ACCESS_TOKEN", "1df238f61df238f61df238f64b1ec2f96511df21df238f675eabff314a9886b3887999d"),
                VKRedirectURI:      getEnv("VK_REDIRECT_URI", "https://multipostingm.ru/auth/vk/callback"),
        }
}

func getEnv(key, fallback string) string {
        if value, exists := os.LookupEnv(key); exists {
                return value
        }
        return fallback
}
