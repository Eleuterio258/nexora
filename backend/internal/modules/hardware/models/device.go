package models

import "time"

// Device representa um dispositivo de hardware registado no ERP.
type Device struct {
	ID           int64
	TenantID     int64
	BranchID     *int64
	Nome         string
	SerialNumber *string
	Modelo       string
	Localizacao  *string
	Tipo         string
	Driver       string
	IPPermitido  *string
	APIKeyPrefix string
	Ativo        bool
	UltimoUsoEm  *time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
}
