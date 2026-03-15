package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Envelope struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    any    `json:"data,omitempty"`
}

func Success(c *gin.Context, data any) {
	c.JSON(http.StatusOK, Envelope{
		Code:    0,
		Message: "success",
		Data:    data,
	})
}

func Error(c *gin.Context, statusCode, businessCode int, message string) {
	c.JSON(statusCode, Envelope{
		Code:    businessCode,
		Message: message,
	})
}
