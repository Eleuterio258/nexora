package handlers

import (
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/storage"
)

func (h *Handler) ObterAvatar(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	var url string
	err := h.db.QueryRow(r.Context(), `SELECT ficheiro_url FROM utilizadores.user_avatar WHERE user_id = $1`, userID).Scan(&url)
	if err != nil {
		jsonErr(w, "Avatar não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]string{"url": url}, http.StatusOK)
}

func (h *Handler) UploadAvatar(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}

	maxBytes := h.cfg.AvatarMaxMB * 1024 * 1024
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes+1024)
	if err := r.ParseMultipartForm(maxBytes); err != nil {
		jsonErr(w, fmt.Sprintf("Ficheiro demasiado grande (máximo %dMB)", h.cfg.AvatarMaxMB), http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("avatar")
	if err != nil {
		jsonErr(w, "Campo 'avatar' em falta", http.StatusBadRequest)
		return
	}
	defer file.Close()

	mime := header.Header.Get("Content-Type")
	if mime != "image/jpeg" && mime != "image/png" {
		jsonErr(w, "Formato não suportado. Use JPEG ou PNG", http.StatusBadRequest)
		return
	}

	ext := ".jpg"
	if strings.Contains(mime, "png") {
		ext = ".png"
	}

	filename := fmt.Sprintf("user_%s_%d%s", userID, time.Now().UnixMilli(), ext)
	key := storage.JoinPath("avatars", fmt.Sprintf("user-%s", userID), filename)

	data := make([]byte, header.Size)
	if _, err := io.ReadFull(file, data); err != nil {
		jsonErr(w, "Erro ao ler ficheiro", http.StatusInternalServerError)
		return
	}

	url, err := h.storage.Put(r.Context(), key, data, mime)
	if err != nil {
		jsonErr(w, "Erro ao guardar ficheiro", http.StatusInternalServerError)
		return
	}

	_, err = h.db.Exec(r.Context(), `
		INSERT INTO utilizadores.user_avatar (user_id, ficheiro_url, mime_type, tamanho_bytes)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id) DO UPDATE SET
		  ficheiro_url = $2, mime_type = $3, tamanho_bytes = $4`,
		userID, url, mime, header.Size)
	if err != nil {
		jsonErr(w, "Erro ao guardar avatar", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]string{"url": url}, http.StatusOK)
}

func (h *Handler) RemoverAvatar(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	caller := mw.GetUser(r)
	if itoa(caller.ID) != userID {
		jsonErr(w, "Sem permissão", http.StatusForbidden)
		return
	}
	var url string
	err := h.db.QueryRow(r.Context(), `DELETE FROM utilizadores.user_avatar WHERE user_id = $1 RETURNING ficheiro_url`, userID).Scan(&url)
	if err != nil {
		jsonErr(w, "Avatar não encontrado", http.StatusNotFound)
		return
	}
	// Remover ficheiro do storage
	key := storage.JoinPath("avatars", fmt.Sprintf("user-%s", userID), filepath.Base(url))
	_ = h.storage.Delete(r.Context(), key)
	w.WriteHeader(http.StatusNoContent)
}
