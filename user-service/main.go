package main

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

type User struct {
	Id      int
	Name    string
	Email   string
	Balance int
}

type CreateUserRequest struct {
	Name  string `json:"name" binding:"required"`
	Email string `json:"email" binding:"required"`
}

type PayValueRequest struct {
	UserId int `json:"user_id"`
	Value  int `json:"value" binding:"required"`
}

type DepositValueRequest struct {
	UserId int `json:"user_id"`
	Value  int `json:"value" binding:"required"`
}

var users []User
var currentUserId int = 1

func main() {
	router := gin.Default()
	router.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "pong",
		})
	})
	router.POST("/user", createUser)
	router.GET("/user/:userId", getUser)
	router.POST("/user/pay", payValue)
	router.POST("/user/deposit", depositValue)
	router.GET("/health", health)
	router.Run("0.0.0.0:3001")
}

func createUser(c *gin.Context) {
	var createUserRequest CreateUserRequest
	if err := c.ShouldBindJSON(&createUserRequest); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	user := User{
		Id:      len(users),
		Name:    createUserRequest.Name,
		Email:   createUserRequest.Email,
		Balance: 0,
	}
	users = append(users, user)
	c.JSON(200, gin.H{"id": len(users) - 1})
}

func getUser(c *gin.Context) {
	userId, _ := strconv.Atoi(c.Param("userId"))
	for _, user := range users {
		if user.Id == userId {
			c.JSON(200, gin.H{
				"id":      user.Id,
				"name":    user.Name,
				"email":   user.Email,
				"balance": user.Balance,
			})
			return
		}
	}
	c.String(404, "user not found")
}

func payValue(c *gin.Context) {
	var payValueRequest PayValueRequest
	if err := c.ShouldBindJSON(&payValueRequest); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	for index, user := range users {
		if user.Id == payValueRequest.UserId {
			users[index] = User{Id: user.Id, Name: user.Name, Email: user.Email, Balance: user.Balance - payValueRequest.Value}
			c.String(200, "payment done")
			return
		}
	}
	c.String(404, "user not found")
}

func depositValue(c *gin.Context) {
	var depositValueRequest DepositValueRequest
	if err := c.ShouldBindJSON(&depositValueRequest); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	for index, user := range users {
		if user.Id == depositValueRequest.UserId {
			users[index] = User{Id: user.Id, Name: user.Name, Email: user.Email, Balance: user.Balance + depositValueRequest.Value}
			c.String(200, "deposit done")
			return
		}
	}
	c.String(404, "user not found")
}

func health(c *gin.Context) {
	c.JSON(200, gin.H{
		"status": "ok",
	})
}
