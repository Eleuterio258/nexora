package handlers

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) ObterAvatar(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "userId")
	var url string
	err := h.db.QueryRow(r.Context(), `SELECT ficheiro_url FROM user_avatar WHERE user_id = $1`, userID).Scan(&url)
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

	os.MkdirAll(h.cfg.AvatarDir, 0755)
	filename := fmt.Sprintf("user_%s_%d%s", userID, time.Now().UnixMilli(), ext)
	dest := filepath.Join(h.cfg.AvatarDir, filename)

	out, err := os.Create(dest)
	if err != nil {
		jsonErr(w, "Erro ao guardar ficheiro", http.StatusInternalServerError)
		return
	}
	defer out.Close()

	size, err := io.Copy(out, file)
	if err != nil {
		jsonErr(w, "Erro ao guardar ficheiro", http.StatusInternalServerError)
		return
	}

	url := "/avatars/" + filename
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO user_avatar (user_id, ficheiro_url, mime_type, tamanho_bytes)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id) DO UPDATE SET
		  ficheiro_url = $2, mime_type = $3, tamanho_bytes = $4`,
		userID, url, mime, size)
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
	err := h.db.QueryRow(r.Context(), `DELETE FROM user_avatar WHERE user_id = $1 RETURNING ficheiro_url`, userID).Scan(&url)
	if err != nil {
		jsonErr(w, "Avatar não encontrado", http.StatusNotFound)
		return
	}
	// Remover ficheiro do disco (ignorar erro se já não existir)
	if strings.HasPrefix(url, "/avatars/") {
		os.Remove(filepath.Join(h.cfg.AvatarDir, filepath.Base(url)))
	}
	w.WriteHeader(http.StatusNoContent)
}
