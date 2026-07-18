# OmnisysERP Desktop - API REST Documentation

## Base URL
```
http://localhost:8081/api
```

## Authentication
Currently, the API is open and does not require authentication.

---

## Funcionarios (Employees) API

### 1. List All Employees
```http
GET /api/funcionarios
```

**Response:**
```json
[
  {
    "id": 1,
    "nome": "João",
    "apelido": "Silva",
    "email": "joao.silva@example.com",
    "telefone": "+244 923 456 789",
    "nif": "123456789",
    "cargo": "Desenvolvedor",
    "departamento": "TI",
    "dataAdmissao": "2024-01-15",
    "ativo": true,
    "foto": null,
    "observacoes": null,
    "dataCriacao": "2024-01-15T08:00:00",
    "dataAtualizacao": "2024-01-15T08:00:00"
  }
]
```

### 2. List Active Employees
```http
GET /api/funcionarios/ativos
```

### 3. Get Employee by ID
```http
GET /api/funcionarios/{id}
```

**Response:** Single employee object or 404

### 4. Search Employees
```http
GET /api/funcionarios/pesquisar?termo=joão
```

Searches by name, email, position, or department.

### 5. Create Employee
```http
POST /api/funcionarios
Content-Type: application/json

{
  "nome": "Maria",
  "apelido": "Santos",
  "email": "maria.santos@example.com",
  "telefone": "+244 912 345 678",
  "nif": "987654321",
  "cargo": "Analista",
  "departamento": "Financeiro",
  "dataAdmissao": "2024-04-01",
  "ativo": true,
  "observacoes": "Funcionária contratada recentemente"
}
```

### 6. Update Employee
```http
PUT /api/funcionarios/{id}
Content-Type: application/json

{
  "id": 1,
  "nome": "João",
  "apelido": "Silva Santos",
  "email": "joao.silva.santos@example.com",
  "cargo": "Senior Developer",
  "departamento": "TI",
  "dataAdmissao": "2024-01-15",
  "ativo": true
}
```

### 7. Delete Employee
```http
DELETE /api/funcionarios/{id}
```

**Response:** 204 No Content or 404

---

## Assiduidade (Attendance) API

### 1. List All Records
```http
GET /api/assiduidade
```

**Response:**
```json
[
  {
    "id": 1,
    "funcionario": {
      "id": 1,
      "nome": "João",
      "apelido": "Silva"
    },
    "dataHoraEntrada": "2024-04-14T08:00:00",
    "dataHoraSaida": "2024-04-14T17:00:00",
    "tipo": "PRESENCIAL",
    "observacao": null,
    "fotoEntrada": null,
    "fotoSaida": null
  }
]
```

### 2. Get Record by ID
```http
GET /api/assiduidade/{id}
```

### 3. List by Employee
```http
GET /api/assiduidade/funcionario/{funcionarioId}?inicio=2024-04-01&fim=2024-04-30
```

**Query Parameters:**
- `inicio` (optional): Start date (ISO format: YYYY-MM-DD)
- `fim` (optional): End date (ISO format: YYYY-MM-DD)

### 4. List Open Records (All)
```http
GET /api/assiduidade/registros-abertos
```

Returns all records without exit time (currently working).

### 5. Get Open Record by Employee
```http
GET /api/assiduidade/registros-abertos/funcionario/{funcionarioId}
```

Returns the current open record for an employee or 404.

### 6. Register Entry
```http
POST /api/assiduidade/entrada?funcionarioId=1&tipo=PRESENCIAL
```

**Query Parameters:**
- `funcionarioId` (required): Employee ID
- `tipo` (optional): Record type (PRESENCIAL, REMOTO, FERIAS, BAIXA_MEDICA, FORMACAO)

**Response:** Created attendance record

### 7. Register Exit
```http
POST /api/assiduidade/saida?funcionarioId=1
```

**Query Parameters:**
- `funcionarioId` (required): Employee ID

**Response:** Updated attendance record with exit time

### 8. Manual Registration
```http
POST /api/assiduidade/manual?funcionarioId=1&entrada=2024-04-14T08:00:00&saida=2024-04-14T17:00:00&tipo=PRESENCIAL&observacao=Registro manual
```

**Query Parameters:**
- `funcionarioId` (required): Employee ID
- `entrada` (required): Entry datetime (ISO format)
- `saida` (optional): Exit datetime (ISO format)
- `tipo` (optional): Record type (default: PRESENCIAL)
- `observacao` (optional): Observation note

### 9. Update Record
```http
PUT /api/assiduidade/{id}
Content-Type: application/json

{
  "id": 1,
  "funcionario": {
    "id": 1,
    "nome": "João",
    "apelido": "Silva"
  },
  "dataHoraEntrada": "2024-04-14T08:30:00",
  "dataHoraSaida": "2024-04-14T17:30:00",
  "tipo": "PRESENCIAL",
  "observacao": "Horário ajustado"
}
```

### 10. Delete Record
```http
DELETE /api/assiduidade/{id}
```

**Response:** 204 No Content or 404

---

## H2 Database Console

For development and debugging, access the H2 console:

**URL:** http://localhost:8081/h2-console

**Connection Settings:**
- **Saved Settings:** Generic H2 (Embedded)
- **JDBC URL:** `jdbc:h2:file:./data/omnisyserp`
- **User Name:** `omnisys`
- **Password:** `omnisys2026`

---

## Error Responses

### 400 Bad Request
```json
{
  "timestamp": "2024-04-14T10:30:00.000+00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Funcionario nao encontrado",
  "path": "/api/assiduidade/entrada"
}
```

### 404 Not Found
```json
{
  "timestamp": "2024-04-14T10:30:00.000+00:00",
  "status": 404,
  "error": "Not Found",
  "path": "/api/funcionarios/999"
}
```

### 500 Internal Server Error
```json
{
  "timestamp": "2024-04-14T10:30:00.000+00:00",
  "status": 500,
  "error": "Internal Server Error",
  "path": "/api/funcionarios"
}
```

---

## Record Types (TipoRegisto)

| Code | Label | Description |
|------|-------|-------------|
| `PRESENCIAL` | Presencial | In-person attendance |
| `REMOTO` | Remoto | Remote work |
| `FERIAS` | Férias | Vacation |
| `BAIXA_MEDICA` | Baixa Médica | Medical leave |
| `FORMACAO` | Formação | Training |

---

## Testing with cURL

### Create Employee
```bash
curl -X POST http://localhost:8081/api/funcionarios \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Test",
    "apelido": "User",
    "email": "test@example.com",
    "cargo": "Developer",
    "departamento": "TI",
    "dataAdmissao": "2024-04-14",
    "ativo": true
  }'
```

### Register Entry
```bash
curl -X POST "http://localhost:8081/api/assiduidade/entrada?funcionarioId=1&tipo=PRESENCIAL"
```

### Register Exit
```bash
curl -X POST "http://localhost:8081/api/assiduidade/saida?funcionarioId=1"
```

### List All Records
```bash
curl http://localhost:8081/api/assiduidade
```

---

## Notes

1. **Auto Server Mode**: The H2 database runs in auto server mode, allowing both the desktop app and H2 console to connect simultaneously.

2. **No Authentication**: Currently, the API has no authentication. For production use, implement Spring Security.

3. **CORS**: If accessing from a web frontend, configure CORS in Spring Boot.

4. **Database Location**: The database file is stored in `./data/omnisyserp` relative to the working directory.

5. **Server Port**: The API runs on port 8081 to avoid conflicts with other services.

---

## Integration with Backend System

This desktop API can sync with the main backend system (`D:\projecto\u-tech\2026\omnisyserp\controle`) via:

1. **Direct Database Access**: Both systems can share the same H2/PostgreSQL database.

2. **REST API Calls**: The desktop can call the backend's API or vice versa.

3. **File Export**: Export attendance data as CSV/JSON for import into the backend.

4. **Message Queue**: Use RabbitMQ/Kafka for real-time sync (future enhancement).

---

**Version**: 1.0.0  
**Last Updated**: April 14, 2026
