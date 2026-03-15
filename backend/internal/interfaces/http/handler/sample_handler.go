package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	appsample "github.com/toheart/go-react-openspec-starter/backend/internal/application/sample"
	"github.com/toheart/go-react-openspec-starter/backend/internal/interfaces/http/response"
)

type SampleHandler struct {
	service *appsample.Service
}

func NewSampleHandler(service *appsample.Service) *SampleHandler {
	return &SampleHandler{service: service}
}

func (h *SampleHandler) RegisterRoutes(router *gin.RouterGroup) {
	router.GET("/samples", h.List)
}

func (h *SampleHandler) List(c *gin.Context) {
	items, err := h.service.List(c.Request.Context())
	if err != nil {
		response.Error(c, http.StatusInternalServerError, 500001, "failed to list sample items")
		return
	}

	response.Success(c, items)
}
