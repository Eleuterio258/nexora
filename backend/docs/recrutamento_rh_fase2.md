# Fase 2 — Documentos e Contactos de Emergência

**Objetivo:** Copiar documentos da candidatura para o processo do funcionário e registar contactos de emergência.

## Ficheiros alterados

- `internal/modules/recrutamento/handlers/contratar.go`

## Funcionalidades

1. **Cópia de CV** (`cv_ficheiro`) para `rh.documentos_funcionario` como `cv`.
2. **Cópia da carta de motivação** (`carta_ficheiro`) como `carta_motivacao`.
3. **Cópia do exame médico de admissão** (quando fornecido) como `exame_medico_admissao`.
4. **Contactos de emergência** inseridos em `rh.contactos_emergencia`.

## Validações

- Ficheiros são lidos do storage abstrato (`internal/storage`) e guardados no path `uploads/tenant-{id}/rh/documentos/{tipo}/`.
- O tipo MIME é inferido da extensão (`.pdf` → `application/pdf`).
- Contactos sem nome ou telefone são ignorados silenciosamente.
