# Análise Técnica — Protocolo de Autenticação Nexora HMAC

> **Projeto:** FaceClock / assiduidade_system_backend  
> **Data:** 2026-08-04  
> **Escopo:** Especificação independente de linguagem para autenticação entre sistemas usando `NEXORA_ACCESS_KEY_ID` + `NEXORA_SECRET_ACCESS_KEY` com HMAC-SHA256.  
> **Clientes-alvo:** Python (SDK oficial), Go, Java, C#, ou qualquer linguagem capaz de computar SHA-256 e HMAC-SHA256.

---

## 1. Resumo Executivo

A autenticação Nexora baseia-se num **protocolo HMAC-SHA256** semelhante ao modelo de credenciais da AWS, mas próprio da Nexora. Cada requisição é assinada localmente pelo cliente usando uma chave secreta (`NEXORA_SECRET_ACCESS_KEY`) que **nunca transita pela rede**. O backend valida a assinatura comparando-a com uma assinatura reconstruída a partir da mesma mensagem canónica.

**Princípios fundamentais:**

- A chave secreta é conhecida apenas pelo cliente e pelo backend.
- Cada pedido inclui um timestamp e um nonce único para evitar replay.
- A assinatura cobre o método HTTP, o caminho, a query string, o timestamp, o nonce e o hash do body.
- O backend armazena a chave secreta cifrada em repouso.
- Clientes podem ser implementados em qualquer linguagem (Go, Java, C#, Python, etc.) desde que sigam o mesmo protocolo.

---

## 2. Especificação do Protocolo

### 2.1 Headers de autenticação

Todo pedido autenticado deve incluir os seguintes headers:

| Header | Descrição | Exemplo |
|---|---|---|
| `X-Nexora-Access-Key` | Identificador público da credencial | `nexora_ak_xxxxxxxxx` |
| `X-Nexora-Timestamp` | Timestamp UNIX em segundos (UTC) | `1785830400` |
| `X-Nexora-Nonce` | UUID v4 único por pedido | `7d3cb813-3e44-4c94-9ecf-9e1ca710cf11` |
| `X-Nexora-Content-SHA256` | Hash SHA-256 do body serializado | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `X-Nexora-Signature` | Assinatura HMAC-SHA256 da mensagem canónica | `a1b2c3d4...` |
| `X-Nexora-Auth-Version` | (Opcional, recomendado) Versão do protocolo | `NEXORA-HMAC-SHA256-V1` |

### 2.2 Mensagem canónica

```text
HTTP_METHOD
REQUEST_PATH
CANONICAL_QUERY_STRING
TIMESTAMP
NONCE
BODY_SHA256
```

Exemplo:

```text
POST
/api/biometric/verify

1785830400
7d3cb813-3e44-4c94-9ecf-9e1ca710cf11
HASH_SHA256_DO_BODY
```

**Regras de normalização:**

1. **`HTTP_METHOD`**: maiúsculas. Exemplos: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`.
2. **`REQUEST_PATH`**: caminho absoluto, sem query string, sem normalização de encoding. Exemplo: `/api/biometric/verify`.
3. **`CANONICAL_QUERY_STRING`**:
   - Codificar cada chave e valor com percent-encoding (RFC 3986).
   - Ordenar as chaves lexicograficamente.
   - Concatenar com `&` no formato `chave=valor`.
   - Se não houver query string, usar string vazia.
4. **`TIMESTAMP`**: string decimal do timestamp UNIX em segundos.
5. **`NONCE`**: UUID v4 em formato string canónico (com hífens), minúsculas.
6. **`BODY_SHA256`**: `hex(SHA256(body_bytes))`.
   - Para pedidos sem body, usar `SHA256(b"")`.
   - O body deve ser os bytes exatamente como enviados pela rede.

### 2.3 Serialização do body

Quando o body for JSON, deve ser serializado de forma **determinística**:

```python
json.dumps(
    payload,
    separators=(",", ":"),
    sort_keys=True,
).encode("utf-8")
```

Equivalente em outras linguagens:

- **Go:** `json.Marshal` já ordena mapas por chave, mas pode produzir espaços. Usar encoder customizado se necessário.
- **Java:** `ObjectMapper.configure(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS, true)` e remover espaços.
- **C#:** `JsonSerializer.Serialize(obj, new JsonSerializerOptions { PropertyNamingPolicy = null })` — cuidado com ordenação; pode ser necessário converter para `SortedDictionary` ou usar `Newtonsoft.Json` com `ContractResolver` ordenado.

> **Nota importante:** se o body não for JSON (ex.: multipart, bytes vazios), o `BODY_SHA256` é calculado diretamente sobre os bytes enviados, sem transformação JSON.

### 2.4 Cálculo da assinatura

```python
signature = hmac.new(
    secret_access_key.encode("utf-8"),
    canonical_request.encode("utf-8"),
    hashlib.sha256,
).hexdigest()
```

Equivalente em outras linguagens:

- **Go:** `hmac.New(sha256.New, []byte(secret))` → `Write(canonical)` → `hex.EncodeToString(Sum(nil))`.
- **Java:** `Mac.getInstance("HmacSHA256")` com `SecretKeySpec`.
- **C#:** `HMACSHA256.ComputeHash(Encoding.UTF8.GetBytes(canonical))` → `Convert.ToHexString(...).ToLowerInvariant()`.

### 2.5 Body vazio

Para pedidos `GET`, `DELETE` ou qualquer pedido sem body:

```text
BODY_SHA256 = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

Este é o SHA-256 de `b""`.

---

## 3. Geração e Gestão de Credenciais no Backend

### 3.1 Entidade `ApiCredential`

```text
ApiCredential
- id (UUID)
- access_key_id (string, único, prefixado com nexora_ak_)
- encrypted_secret_access_key (string)
- name (string, descritivo)
- tenant_id (string)
- permissions (JSON list)
- status (active | revoked)
- created_at (datetime)
- expires_at (datetime, opcional)
- last_used_at (datetime)
- revoked_at (datetime, opcional)
```

### 3.2 Geração segura

- `access_key_id`: prefixo fixo + 32 bytes aleatórios codificados em base64-urlsafe. Exemplo: `nexora_ak_aB3dEfGhIjKlMnOpQrStUvWxYz0123456789`.
- `secret_access_key`: 32-64 bytes aleatórios gerados por `secrets.token_urlsafe()` ou `crypto/rand`. Exemplo: `nexora_sk_...`.
- A chave secreta é apresentada **apenas uma vez** no momento da criação, durante a resposta da API.
- A chave secreta é cifrada em repouso usando uma chave mestra externa (`NEXORA_CREDENTIAL_ENCRYPTION_KEY`).

### 3.3 Cifragem em repouso

Recomenda-se usar `cryptography.fernet.Fernet` (Python) com uma chave de 32 bytes base64-urlsafe:

```python
from cryptography.fernet import Fernet
fernet = Fernet(NEXORA_CREDENTIAL_ENCRYPTION_KEY)
encrypted = fernet.encrypt(secret_access_key.encode("utf-8"))
decrypted = fernet.decrypt(encrypted).decode("utf-8")
```

A chave mestra **nunca** é guardada na base de dados; deve vir exclusivamente de variável de ambiente ou gestor de segredos.

### 3.4 Revogação e rotação

- **Revogação:** atualizar `status = revoked` e `revoked_at = now()`. Credenciais revogadas rejeitam imediatamente pedidos.
- **Rotação:** criar nova credencial para o mesmo tenant/terminal. A antiga permanece válida durante um período de sobreposição (ex.: 5 minutos) para evitar interrupção. Após esse período, a antiga é revogada automaticamente.

---

## 4. Validação no Backend (passo a passo)

A dependência FastAPI deve executar:

1. Verificar se todos os headers obrigatórios estão presentes. Se não, devolver **401**.
2. Verificar se o pedido é HTTPS quando `ENVIRONMENT=production`. Se não, devolver **401** ou **403**.
3. Procurar a credencial pelo `X-Nexora-Access-Key`.
4. Se não existir, devolver **401** (sem revelar que o access key é desconhecido).
5. Decifrar `encrypted_secret_access_key`.
6. Verificar `status == active`. Se revogada, devolver **401**.
7. Verificar `expires_at`. Se expirada, devolver **401**.
8. Calcular `BODY_SHA256` a partir do body recebido.
9. Comparar com `X-Nexora-Content-SHA256`. Se diferente, devolver **401**.
10. Verificar timestamp: `|now - timestamp| <= 300` segundos. Se fora, devolver **401**.
11. Verificar nonce no Redis: `SET NX nexora:nonce:<access_key>:<nonce> EX 300`. Se já existir, devolver **409** (ou **401**).
12. Reconstruir a mensagem canónica.
13. Calcular a assinatura esperada com HMAC-SHA256.
14. Comparar com `hmac.compare_digest()`.
15. Se falhar, devolver **401**.
16. Verificar permissões: a operação deve estar em `permissions`. Se não, devolver **403**.
17. Verificar `tenant_id` da credencial contra o recurso solicitado.
18. Atualizar `last_used_at` (sem logar segredos).
19. Permitir o acesso ao endpoint.

### 4.1 Mensagens de erro

Todas as falhas de autenticação devem devolver a mesma mensagem genérica:

```json
{"detail": "Credenciais de autenticação inválidas ou requisição não autorizada."}
```

Apenas a falta de permissão pode devolver **403** com mensagem genérica:

```json
{"detail": "Sem permissão para executar esta operação."}
```

---

## 5. Implementação em Clientes Externos

### 5.1 Python — SDK oficial (`nexora_sdk`)

```python
from nexora_sdk import NexoraClient

client = NexoraClient()

resultado = client.biometric.verify(
    user_id="usr_123",
    image_base64="BASE64_DA_IMAGEM",
)
```

O SDK resolve credenciais nesta ordem:

1. Parâmetros passados ao `NexoraClient`.
2. Variáveis de ambiente (`NEXORA_ACCESS_KEY_ID`, `NEXORA_SECRET_ACCESS_KEY`, `NEXORA_API_URL`).
3. Ficheiro de configuração Nexora (`~/.nexora/credentials` ou `.nexora/credentials`).

### 5.2 Go — exemplo mínimo

```go
package main

import (
    "crypto/hmac"
    "crypto/sha256"
    "encoding/hex"
    "encoding/json"
    "fmt"
    "net/http"
    "strings"
    "time"

    "github.com/google/uuid"
)

func signRequest(method, path, query, secret string, body []byte) map[string]string {
    bodyHash := sha256.Sum256(body)
    timestamp := fmt.Sprintf("%d", time.Now().Unix())
    nonce := uuid.New().String()

    canonical := fmt.Sprintf("%s\n%s\n%s\n%s\n%s\n%s",
        strings.ToUpper(method),
        path,
        query,
        timestamp,
        nonce,
        hex.EncodeToString(bodyHash[:]),
    )

    mac := hmac.New(sha256.New, []byte(secret))
    mac.Write([]byte(canonical))
    signature := hex.EncodeToString(mac.Sum(nil))

    return map[string]string{
        "X-Nexora-Access-Key":     "nexora_ak_xxxxxxxxx",
        "X-Nexora-Timestamp":      timestamp,
        "X-Nexora-Nonce":          nonce,
        "X-Nexora-Content-SHA256": hex.EncodeToString(bodyHash[:]),
        "X-Nexora-Signature":      signature,
        "X-Nexora-Auth-Version":   "NEXORA-HMAC-SHA256-V1",
        "Content-Type":            "application/json",
    }
}

func main() {
    payload := map[string]string{"user_id": "usr_123", "image_base64": "..."}
    body, _ := json.Marshal(payload) // Go ordena mapas por chave, mas cuidado com espaços

    headers := signRequest("POST", "/api/biometric/verify", "", "nexora_sk_xxxxxxxxx", body)

    req, _ := http.NewRequest("POST", "https://api.nexora.co.mz/api/biometric/verify", strings.NewReader(string(body)))
    for k, v := range headers {
        req.Header.Set(k, v)
    }

    client := &http.Client{}
    resp, _ := client.Do(req)
    fmt.Println(resp.Status)
}
```

> **Nota para Go:** `json.Marshal` ordena mapas, mas pode inserir espaços após `,` e `:`. Para garantir compatibilidade com o backend, o body deve ser serializado **sem espaços** ou o backend deve aceitar o hash do body exatamente como enviado. Recomenda-se que o backend **não recompute o JSON**, apenas compute `SHA256(body_bytes_recebidos)`.

### 5.3 Java — exemplo mínimo

```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.UUID;
import java.util.Base64;

public class NexoraSigner {
    public static String sha256Hex(byte[] input) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        return bytesToHex(digest.digest(input));
    }

    public static String hmacSha256Hex(String secret, String message) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        SecretKeySpec key = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
        mac.init(key);
        return bytesToHex(mac.doFinal(message.getBytes(StandardCharsets.UTF_8)));
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    public static void main(String[] args) throws Exception {
        String accessKey = "nexora_ak_xxxxxxxxx";
        String secret = "nexora_sk_xxxxxxxxx";
        String body = "{\"image_base64\":\"...\",\"user_id\":\"usr_123\"}";
        byte[] bodyBytes = body.getBytes(StandardCharsets.UTF_8);

        String bodyHash = sha256Hex(bodyBytes);
        String timestamp = String.valueOf(Instant.now().getEpochSecond());
        String nonce = UUID.randomUUID().toString();

        String canonical = String.join("\n",
            "POST",
            "/api/biometric/verify",
            "",
            timestamp,
            nonce,
            bodyHash
        );

        String signature = hmacSha256Hex(secret, canonical);

        System.out.println("X-Nexora-Access-Key: " + accessKey);
        System.out.println("X-Nexora-Timestamp: " + timestamp);
        System.out.println("X-Nexora-Nonce: " + nonce);
        System.out.println("X-Nexora-Content-SHA256: " + bodyHash);
        System.out.println("X-Nexora-Signature: " + signature);
    }
}
```

### 5.4 C# — exemplo mínimo

```csharp
using System;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

class NexoraSigner
{
    static string Sha256Hex(byte[] input)
    {
        using var sha = SHA256.Create();
        return Convert.ToHexString(sha.ComputeHash(input)).ToLowerInvariant();
    }

    static string HmacSha256Hex(string secret, string message)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        return Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(message))).ToLowerInvariant();
    }

    static void Main()
    {
        var accessKey = "nexora_ak_xxxxxxxxx";
        var secret = "nexora_sk_xxxxxxxxx";
        var body = JsonSerializer.Serialize(new { user_id = "usr_123", image_base64 = "..." });
        var bodyBytes = Encoding.UTF8.GetBytes(body);

        var bodyHash = Sha256Hex(bodyBytes);
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString();
        var nonce = Guid.NewGuid().ToString();

        var canonical = string.Join("\n",
            "POST",
            "/api/biometric/verify",
            "",
            timestamp,
            nonce,
            bodyHash
        );

        var signature = HmacSha256Hex(secret, canonical);

        Console.WriteLine($"X-Nexora-Access-Key: {accessKey}");
        Console.WriteLine($"X-Nexora-Timestamp: {timestamp}");
        Console.WriteLine($"X-Nexora-Nonce: {nonce}");
        Console.WriteLine($"X-Nexora-Content-SHA256: {bodyHash}");
        Console.WriteLine($"X-Nexora-Signature: {signature}");
    }
}
```

> **Nota para C#:** `JsonSerializer.Serialize` pode não ordenar propriedades por nome. Para garantir compatibilidade, usar `JsonSerializerOptions` com `PropertyNamingPolicy = null` e ordenar manualmente, ou usar `SortedDictionary<string, object>`.

---

## 6. Interoperabilidade entre Linguagens

Para garantir que um cliente Go, Java ou C# produza a mesma assinatura que o SDK Python, os seguintes pontos devem ser **estritamente alinhados**:

1. **Headers idênticos** — mesmo nome, mesmo casing.
2. **Mensagem canónica idêntica** — mesmo número de linhas, mesma ordem, sem espaços extras.
3. **Body idêntico** — o hash SHA-256 deve ser calculado sobre os **bytes exatos** enviados pelo cliente.
4. **Timestamp como string decimal** — sem milissegundos.
5. **Nonce como UUID v4 minúsculo** — com hífens.
6. **Canonical query string normalizada** — RFC 3986, chaves ordenadas.
7. **HMAC-SHA256 em hex minúsculo**.

**Recomendação:** o backend deve calcular o `BODY_SHA256` a partir do body bruto recebido, não reserializar JSON. Assim, pequenas diferenças de formatação JSON entre linguagens não quebram a assinatura, desde que o body enviado e o `X-Nexora-Content-SHA256` correspondam.

---

## 7. Endpoints Protegidos e Permissões

### 7.1 Rotas a proteger

| Método | Path | Permissão |
|---|---|---|
| `POST` | `/api/v1/biometric/enroll` | `biometric:enroll` |
| `POST` | `/api/v1/biometric/verify` | `biometric:verify` |
| `POST` | `/api/v1/fingerprint/enroll` | `fingerprint:enroll` |
| `POST` | `/api/v1/fingerprint/identify` | `fingerprint:identify` |
| `DELETE` | `/api/v1/fingerprint/enroll/{user_id}` | `fingerprint:delete` |
| `POST` | `/api/v1/liveness/challenge` | `liveness:challenge` |
| `POST` | `/api/v1/liveness/verify` | `liveness:verify` |
| `*` | `/api/v1/attendance/*` (futuro) | `attendance:*` |

### 7.2 Rotas públicas

| Método | Path |
|---|---|
| `GET` | `/health` |
| `GET` | `/ready` |
| `GET` | `/metrics` |

---

## 8. Segurança Obrigatória

- **HTTPS em produção:** rejeitar pedidos HTTP quando `ENVIRONMENT=production`.
- **Nunca enviar a secret:** a `NEXORA_SECRET_ACCESS_KEY` só é usada localmente para HMAC.
- **Não logar credenciais:** middleware e handlers não devem logar headers de autenticação, secrets, ou imagens base64.
- **Rate limiting:** por access key e por IP. O ERP pode apresentar um único IP; limitar por IP sozinho não protege contra abuso de uma credencial.
- **Tenant isolado:** cada credencial pertence a um tenant; aplicação de `apply_tenant` continua a filtrar recursos.
- **Credenciais por terminal:** atribuir uma credencial diferente a cada terminal físico.
- **Revogação imediata:** um terminal comprometido pode ser revogado sem afetar outros.
- **Comparação segura:** usar sempre `hmac.compare_digest()`.
- **Proteção replay:** Redis com TTL ≥ 300s para `access_key_id + nonce`.
- **Body vazio:** documentar `BODY_SHA256 = SHA256(b"")`.
- **Versionamento:** header `X-Nexora-Auth-Version: NEXORA-HMAC-SHA256-V1` para evolução futura do protocolo.

---

## 9. Testes Obrigatórios

1. Chamada com assinatura válida.
2. Access Key ID inexistente.
3. Assinatura inválida.
4. Body modificado depois da assinatura.
5. Timestamp expirado.
6. Nonce repetido.
7. Credencial revogada.
8. Credencial expirada.
9. Credencial de outro tenant.
10. Credencial sem permissão.
11. Query string alterada depois da assinatura.
12. Rotação de credenciais.
13. Concorrência envolvendo o mesmo nonce.
14. Garantia de que segredos não aparecem nos logs.
15. Compatibilidade entre a assinatura gerada pelo SDK e a validação do backend.
16. **(Adicional)** Compatibilidade cruzada: assinar em Go/Java/C# e validar no backend Python.

---

## 10. Questões em Aberto

1. O SDK será publicado no PyPI ou mantido apenas como pasta dentro do repositório?
2. O provisionamento de credenciais será feito por CLI, endpoint admin, ou sincronização automática com o ERP?
3. A autenticação Nexora **substitui** ou **coexiste** com `Authorization: Bearer` nos endpoints de integração?
4. Os endpoints `/api/attendance/*` serão criados no FaceClock ou existem apenas no ERP?
5. Qual chave de cifragem usar para as secrets em repouso? `Fernet` ou AES-256-GCM manual?
6. Redis será obrigatório em todos os ambientes ou apenas em produção (dev/testes usando `fakeredis`)?
7. Pretende-se fornecer SDKs oficiais também para Go, Java e C#, ou apenas documentação de protocolo?

---

## 11. Próximos Passos

1. Confirmar as decisões em aberto, especialmente o provisionamento de credenciais e a coexistência/substituição de auth.
2. Implementar a entidade `ApiCredential` e migração Alembic.
3. Refatorar `app/security/nexora_auth.py` para cumprir a especificação deste protocolo.
4. Implementar o SDK Python `nexora_sdk` como referência.
5. Criar exemplos mínimos de assinatura em Go, Java e C# para validação cruzada.
6. Proteger os endpoints de integração e executar todos os testes obrigatórios.

---

*Documento gerado para especificação independente de linguagem do protocolo de autenticação Nexora HMAC.*
