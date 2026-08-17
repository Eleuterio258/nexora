# Terminal GSM Dedicado — Controlo de Assiduidade (com comunicação via satélite)

> Conceito de hardware próprio para marcação de ponto, descrito a partir do infográfico de produto Nexora.
> Estado: proposta/mockup de produto, ainda sem implementação de backend/firmware associada neste repositório.

## 1. Visão geral

Dispositivo físico dedicado para controlo de assiduidade, pensado para locais sem rede fixa ou Wi-Fi — obras, fábricas, armazéns, campo, áreas remotas — onde a marcação de ponto precisa de continuar a funcionar mesmo sem cobertura móvel. A promessa central do produto é **"registos sempre garantidos, mesmo em áreas sem cobertura móvel"**, através de um canal de comunicação via satélite usado como reserva do GSM/4G.

## 2. Identificação do funcionário

- PIN
- Cartão RFID/NFC
- Impressão digital (opcional)

## 3. Funcionalidades

- Registo de entrada, saída, pausa e retorno
- Sincronização automática com o servidor
- GPS opcional, para localização do registo
- Comunicação via satélite opcional
- Funciona offline, com armazenamento local dos registos

## 4. Comunicação

- **Principal:** GSM 850/900/1800/1900 MHz + 2G/4G, via módulo SIM7600G / SIM7600G-H
- **Reserva (opcional):** satélite L-band — Iridium Certus ou Inmarsat BGAN, através de um provedor satelital externo até à Internet e ao Nexora Cloud
- Antena GSM/satélite e slot Micro SIM dedicados no dispositivo

## 5. Especificações técnicas de hardware

| Componente | Especificação |
| --- | --- |
| CPU | ESP32-WROOM-32 |
| Ecrã | LCD 2.4" colorido |
| Teclado | físico, 16 teclas |
| Leitor | RFID/NFC 13.56 MHz |
| Memória | Flash 4MB (opcional 32MB) — até 50.000 registos offline |
| Bateria | 3.7V 4000mAh — até 8h de uso |
| Dimensões | 120 × 60 × 22 mm |
| Protecção | IP54 (resistente a poeira e água) |
| Temperatura de operação | -10°C a 60°C |
| GPS (opcional) | módulo NEO-6M |
| Carregamento/configuração | USB Type-C |

### 5.1 Placa principal (PCB) — V1.0

Existe já um desenho de placa concreto (não só o conceito de produto), que precisa a especificação da secção 5 e introduz decisões de engenharia reais:

#### Dimensões e construção

- 95.0 × 120.0 mm, PCB de 1.6 mm, **5 camadas**: TOP (componentes) / GND PLANE / INNER 1 (sinais) / INNER 2 (sinais) / BOTTOM (solda)
- 4 furos de fixação nos cantos

#### Especificações confirmadas na placa

- CPU: ESP32-WROOM-32
- Comunicação: 4G (SIM7600G) / 2G
- Display: LCD TFT 2.4" (interface SPI)
- Identificação: RFID/NFC 13.56 MHz
- Sensor opcional: impressão digital (ligado por GPIO/SPI)
- Memória: Flash 8MB on-board (SPI) + **Micro SD removível até 32GB** — mais explícito que o "Flash 4MB (opcional 32MB)" genérico da secção 5; a placa real separa flash on-board de armazenamento removível
- Bateria: 3.7V / 4000mAh
- Alimentação: 5V via USB-C
- Periféricos de feedback: buzzer e LED de status
- **Comunicação com o servidor: HTTPS/MQTT** — ver nota na secção 9.4 sobre a implicação disto na assinatura HMAC

#### Esquema de ligação (barramentos)

```text
                    ┌──────────────┐
   TECLADO ────────►│              │
   RFID/NFC ────────►              │
   SENSOR DIGITAL ──►   ESP32      │
   LCD TFT 2.4" ◄───►   WROOM-32   │
   BUZZER/LED ◄──────│              │
                    └───┬──┬───┬───┘
                UART│    │SPI│SPI
                    ▼    ▼   ▼
              SIM7600G  MICRO SD  FLASH 8MB
              (4G/2G)
                    ▲
                UART│
                  GPS (opcional)

   BATERIA 3.7V → REGULADOR 5V/3.3V → alimenta o resto da placa
```

#### Conectores/headers expostos

Relevantes para quem for desenhar o gabinete e o firmware:

- `LCD TFT`: 3V3, GND, SCL, SDA, RST, DC, CS, BL
- `UART`: RX, TX, GND, 3V3 (debug/programação)
- Conectores dedicados: SIM (Micro SIM), antena GPS, antena GSM (`ANT`), USB Type-C, bateria, sensor digital, teclado, RFID/NFC

#### BOM (componentes principais)

| Componente | Qtd. |
| --- | --- |
| ESP32-WROOM-32 | 1 |
| SIM7600G (4G) | 1 |
| GPS Module (opcional) | 1 |
| LCD TFT 2.4" | 1 |
| RFID/NFC RC522 | 1 |
| Sensor Digital (opcional, impressão digital) | 1 |
| Micro SD Socket | 1 |
| Buzzer 3V | 1 |
| Regulador 5V | 1 |
| Regulador 3.3V | 1 |
| Bateria 3.7V / 4000mAh | 1 |
| Conectores/Diversos | — |

Nota: o leitor RFID/NFC concreto é o **RC522**, um módulo SPI comum e barato — bom para orçamento e disponibilidade, mas vale confirmar se o alcance/robustez do RC522 é suficiente para uso em campo antes de fechar o BOM definitivo.

## 6. Arquitectura do sistema

```text
Terminal GSM Dedicado
   │  2G/4G  ou  satélite (L-band) → provedor satelital → Internet
   ▼
API Assiduidade
   - autenticação do terminal
   - receção de registos
   - sincronização
   - armazenamento seguro
   ▼
Nexora ERP
   - Funcionários
   - Horários
   - Assiduidade
   - Relatórios
   - Folha salarial
```

## 7. Público-alvo

Empresas, obras, fábricas, armazéns, escritórios, escolas, campo e áreas remotas.

## 8. Relação com o que já existe no Nexora

Este conceito é um **dispositivo de assiduidade** na acepção da secção 2.4 de [modelo-usuario-funcionario-terminal.md](../docs/modelo-usuario-funcionario-terminal.md): não é um terminal POS (`pos.pos_terminals`) nem um funcionário (`rh.funcionarios`) — é hardware que autentica chamadas de serviço e informa qual funcionário marcou o ponto, resolvendo sempre para `funcionario_id`.

Já existe infraestrutura reaproveitável para este tipo de dispositivo:

- o módulo `hardware` (Go), que autentica dispositivos por `api_key_hash`/`api_key_prefix` e resolve a pessoa via `funcionario_id`, `employee_no` ou `user_id`, reutilizando o serviço canónico `recursos-humanos/service/funcionario.Service`;
- o gateway/serviço FaceClock (Python), que já distingue dispositivo de pessoa na autenticação (`DevicePublicKey.device_id` vs. `erp_funcionario_id`/`erp_user_id`);
- o sistema flexível de assiduidade (Fases A–F, já completo), que migrou 741 presenças reais para `eventos_assiduidade`.

Para este terminal GSM/satélite específico, ficam por definir (fora do âmbito deste documento, que é apenas descritivo):

1. protocolo de sincronização entre firmware ESP32 e a API Assiduidade (formato dos eventos, resolução de conflitos de registos offline);
2. modelo de custo/uso do canal satélite (Iridium Certus/Inmarsat BGAN são serviços pagos por dados, tipicamente caros face a GSM);
3. onde este dispositivo se encaixa nas tabelas existentes de `hardware` (novo tipo de dispositivo vs. reaproveitar o mesmo modelo dos leitores faciais/QR).

## 9. Autenticação do dispositivo — HMAC-SHA256

A autenticação deste terminal junto da API Assiduidade **não precisa de ser desenhada de raiz**: já existe no backend um protocolo de assinatura HMAC-SHA256 para dispositivos físicos, implementado em `backend/internal/pkg/devicehmac/` e com suporte de schema em `hardware.devices` (migration `20260808190000_hardware_device_hmac.up.sql`). O terminal GSM deve reaproveitar exactamente este mecanismo, não inventar um novo.

### 9.1 Credenciais do device

Cada terminal é uma linha em `hardware.devices` com:

- `access_key_id` — identificador público do device (prefixo `nxd_`), gravado no firmware na activação;
- `secret_access_key_hash` — SHA-256 do segredo HMAC, guardado só como hash no servidor; o segredo em claro só existe no dispositivo e no momento da emissão;
- `permissions` — lista JSON de permissões RBAC do device (ex.: `["assiduidade:ponto:write"]`) — o terminal só pode gravar eventos de assiduidade, nada mais;
- `hmac_ativo` — se `true`, HMAC é obrigatório; enquanto `false`, permite migração gradual a partir de X-API-Key simples (modo híbrido já previsto no schema, não é algo a criar de novo para este produto);
- `auth_version` — versão do protocolo, hoje `NEXORA-HMAC-SHA256-V1`.

### 9.2 Assinatura de cada pedido

Cada chamada HTTP do terminal para a API (ex.: `POST /api/hardware/events/generic` com o evento de ponto) transporta seis headers gerados por `devicehmac.Signer.SignBytes`:

| Header | Conteúdo |
| --- | --- |
| `X-Device-Access-Key` | `access_key_id` do terminal |
| `X-Device-Timestamp` | Unix timestamp do pedido |
| `X-Device-Nonce` | UUID único por pedido (anti-replay) |
| `X-Device-Content-SHA256` | SHA-256 hex do corpo do pedido |
| `X-Device-Signature` | HMAC-SHA256(secret, canonical_string) |
| `X-Device-Auth-Version` | `NEXORA-HMAC-SHA256-V1` |

A `canonical_string` assinada é:

```text
MÉTODO
/caminho/absoluto
query_string_canónica_ordenada
timestamp
nonce
sha256_hex(body)
```

separados por `\n`. O body é serializado em JSON com chaves ordenadas (`SerializeBody`/`marshalSorted`), garantindo que o mesmo payload produz sempre a mesma assinatura em ambos os lados.

No servidor, `devicehmac.Verify` recalcula o hash do corpo e a assinatura a partir do segredo associado ao `access_key_id`, comparando com `hmac.Equal` (comparação em tempo constante, evita timing attacks). Um pedido só é aceite se:

1. `auth_version` for suportada;
2. o hash do corpo coincidir com `X-Device-Content-SHA256`;
3. a assinatura recalculada coincidir com `X-Device-Signature`.

### 9.3 Porque serve bem para este terminal

- **Funciona offline-first:** a assinatura é calculada localmente no ESP32 a partir do segredo gravado no dispositivo — não depende de handshake prévio nem de token que expire, o que é essencial para um aparelho que armazena até 50.000 registos offline e sincroniza mais tarde, possivelmente via satélite com latência alta;
- **Nonce + timestamp** protegem contra reenvio de eventos capturados, relevante num canal satélite mais exposto/caro do que GSM;
- **Privilégio mínimo:** o campo `permissions` restringe o terminal a escrever eventos de assiduidade, nunca a agir como utilizador humano ou terminal POS — coerente com a distinção "dispositivo de assiduidade" da secção 2.4 de [modelo-usuario-funcionario-terminal.md](../docs/modelo-usuario-funcionario-terminal.md);
- **Reaproveitamento real:** nenhuma tabela, endpoint de emissão de credenciais ou código de verificação precisa de ser criado — o trabalho deste produto é apenas firmware (implementar o signer em C/ESP-IDF seguindo o mesmo algoritmo) e activar `hmac_ativo=true` para os devices deste tipo.

### 9.4 Atenção: a placa V1.0 prevê HTTPS **e** MQTT

A especificação da placa (secção 5.1) lista "comunicação com o servidor via HTTPS/MQTT" — ou seja, deixa em aberto usar um broker MQTT, não só pedidos HTTP directos. Isto tem impacto directo no esquema de assinatura:

- o `devicehmac` actual assina uma `canonical_string` construída a partir de **método HTTP, caminho e query string** (secção 9.2) — conceitos que não existem em MQTT, onde a unidade é um tópico (`topic`) e um payload publicado;
- se o terminal publicar eventos por MQTT, a assinatura tem de ser recalculada sobre outra canonical string (ex.: `topic + timestamp + nonce + sha256(payload)`), e o `devicehmac.Verify` do lado do servidor precisa de um caminho equivalente para validar mensagens recebidas do broker, não só pedidos HTTP;
- misturar os dois transportes sem decidir isto cedo arrisca ter dois protocolos de assinatura divergentes para o mesmo tipo de device.

Recomendação: para o MVP (Fase 1-3 do [plano-terminal-gsm-assiduidade.md](plano-terminal-gsm-assiduidade.md)), usar **apenas HTTPS** com o `devicehmac` tal como já existe — é o caminho zero-trabalho-extra no backend. Avaliar MQTT mais tarde, só se houver um motivo concreto (ex.: reduzir overhead de conexão em redes GSM instáveis), e nesse caso tratar como uma extensão do protocolo HMAC, não como transporte alternativo "grátis".
