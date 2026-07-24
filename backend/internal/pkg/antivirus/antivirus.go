// Package antivirus fornece uma interface simples para verificação de ficheiros
// com motores antivírus externos (ClamAV) ou noop para desenvolvimento/testes.
package antivirus

import (
	"fmt"
	"io"
	"net"
	"time"
)

// Resultado indica o resultado de uma verificação.
type Resultado struct {
	Limpo   bool
	Infectado bool
	Motivo  string
}

// Verificador é a interface comum a todos os motores antivírus.
type Verificador interface {
	Verificar(nome string, data []byte) (Resultado, error)
}

// Config contém as configurações do motor antivírus.
type Config struct {
	Provider string // "noop" ou "clamav"
	ClamAVNetwork string // "tcp" ou "unix"
	ClamAVAddress string // "localhost:3310" ou caminho do socket
}

// New cria um verificador consoante a configuração.
func New(cfg Config) Verificador {
	switch cfg.Provider {
	case "clamav":
		return &clamav{
			network: cfg.ClamAVNetwork,
			address: cfg.ClamAVAddress,
			timeout: 30 * time.Second,
		}
	default:
		return &noop{}
	}
}

// noop não deteta nada; apenas regista/loga.
type noop struct{}

func (n *noop) Verificar(nome string, data []byte) (Resultado, error) {
	return Resultado{Limpo: true}, nil
}

// clamav implementa a verificação via protocolo clamd.
// Suporta TCP e socket Unix.
type clamav struct {
	network string
	address string
	timeout time.Duration
}

func (c *clamav) Verificar(nome string, data []byte) (Resultado, error) {
	if c.network == "" {
		c.network = "tcp"
	}
	if c.address == "" {
		c.address = "localhost:3310"
	}

	conn, err := net.DialTimeout(c.network, c.address, c.timeout)
	if err != nil {
		return Resultado{}, fmt.Errorf("ligar ao ClamAV: %w", err)
	}
	defer conn.Close()

	// Envia o comando INSTREAM.
	if _, err := conn.Write([]byte("zINSTREAM\x00")); err != nil {
		return Resultado{}, fmt.Errorf("enviar comando: %w", err)
	}

	// Protocolo clamd: chunks de 4 bytes big-endian tamanho + dados.
	const maxChunk = 1024
	for len(data) > 0 {
		n := maxChunk
		if len(data) < n {
			n = len(data)
		}
		chunk := data[:n]
		header := []byte{byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)}
		if _, err := conn.Write(header); err != nil {
			return Resultado{}, fmt.Errorf("enviar chunk header: %w", err)
		}
		if _, err := conn.Write(chunk); err != nil {
			return Resultado{}, fmt.Errorf("enviar chunk: %w", err)
		}
		data = data[n:]
	}
	// Termina com tamanho zero.
	if _, err := conn.Write([]byte{0, 0, 0, 0}); err != nil {
		return Resultado{}, fmt.Errorf("terminar stream: %w", err)
	}

	// Lê resposta.
	buf, err := io.ReadAll(conn)
	if err != nil {
		return Resultado{}, fmt.Errorf("ler resposta: %w", err)
	}
	resp := string(buf)

	if resp == "" {
		return Resultado{}, fmt.Errorf("resposta vazia do ClamAV")
	}

	if resp == "stream: OK\x00" {
		return Resultado{Limpo: true}, nil
	}

	return Resultado{Infectado: true, Motivo: resp}, nil
}
