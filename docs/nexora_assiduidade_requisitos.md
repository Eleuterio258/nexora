# Nexora Assiduidade — Requisitos de Sistema

## 1. Visão Geral

O **Nexora Assiduidade** é o subsistema de controlo de ponto, presenças e assiduidade do ERP Nexora. Tem como objectivo registar de forma fiável as entradas e saídas dos colaboradores, calcular horas trabalhadas, horas extra, faltas e atrasos, e integrar essa informação com o módulo de **Recursos Humanos** já existente no backend.

O sistema é composto por:
- **Terminal IoT de assiduidade** baseado em ESP32, com múltiplos modos de identificação.
- **Firmware embarcado** que comunica com a API do ERP.
- **Backend/API** do Nexora (módulo `rh.presencas` e extensões).
- **Interfaces de gestão** (portal web / desktop / mobile) para consulta, relatórios e parametrização.

---

## 2. Objectivos do Negócio

| ID | Objectivo |
|----|-----------|
| OB-01 | Substituir ou complementar o registo manual de ponto por um processo automático e auditável. |
| OB-02 | Garantir conformidade com a legislação laboral moçambicana (cartão de ponto, horas extra, descanso). |
| OB-03 | Reduzir erros e fraudes no registo de presenças. |
| OB-04 | Fornecer dados actualizados para processamento salarial e avaliação de desempenho. |
| OB-05 | Permitir o trabalho em locais sem rede eléctrica ou internet fixa (modo offline + GSM). |

---

## 3. Stakeholders

| Stakeholder | Interesse |
|-------------|-----------|
| Colaborador | Marcar entrada/saída de forma rápida e ver o seu saldo. |
| Gestor / Chefe de equipa | Aprovar correções, consultar equipa, detectar atrasos. |
| Departamento de RH | Parametrizar horários, gerar relatórios, exportar para folha. |
| Técnico de campo | Instalar e manter terminais, diagnosticar falhas. |
| Auditor / Contabilidade | Rastreabilidade dos registos e integridade dos dados. |

---

## 4. Requisitos Funcionais

### 4.1 Identificação do colaborador

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF-01 | O terminal deve permitir identificação por **biometria** (sensor R307). | Alta |
| RF-02 | O terminal deve permitir identificação por **cartão RFID/NFC** (MFRC522). | Alta |
| RF-03 | O terminal deve permitir identificação por **código numérico pessoal** via keypad 4×3. | Média |
| RF-04 | O sistema deve suportar múltiplos métodos combinados (p. ex. RFID + PIN). | Média |
| RF-05 | Cada colaborador deve ter uma ou mais credenciais registadas no perfil RH (`rh.funcionarios`). | Alta |
| RF-06 | O administrador deve poder inibir temporariamente uma credencial (cartão perdido, dedo lesionado). | Média |

### 4.2 Marcação de ponto

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF-10 | O terminal deve registar a data, hora, tipo (entrada/saída), localização GPS e identificador do terminal. | Alta |
| RF-11 | O sistema deve distinguir automaticamente entre **entrada** e **saída** com base no último registo do dia. | Alta |
| RF-12 | O colaborador deve poder forçar explicitamente uma marcação de entrada ou saída no terminal. | Média |
| RF-13 | Deve ser possível configurar um **intervalo mínimo entre marcações** para evitar duplicados. | Média |
| RF-14 | Cada marcação deve ser confirmada visualmente no ecrã e por sinal sonoro/LED. | Alta |
| RF-15 | O terminal deve funcionar em **modo offline**, armazenando localmente as marcações e sincronizando quando houver rede. | Alta |
| RF-16 | Em modo offline, o terminal deve validar credenciais contra uma cache local de colaboradores. | Alta |

### 4.3 Horários de trabalho

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF-20 | O sistema deve utilizar a tabela `rh.horarios_trabalho` para definir entrada, saída, intervalo e dias da semana. | Alta |
| RF-21 | Cada funcionário deve estar associado a um horário (`funcionarios.horario_id`). | Alta |
| RF-22 | O sistema deve suportar horários rotativos, turnos e escalas (futuro). | Baixa |
| RF-23 | Deve ser possível definir feriados e dias de excepção por tenant. | Média |

### 4.4 Cálculo e classificação

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF-30 | O sistema deve calcular as **horas trabalhadas** por dia com base na entrada e saída. | Alta |
| RF-31 | O sistema deve calcular **horas extra** (`rh.presencas.horas_extra`) quando o colaborador excede a carga diária. | Alta |
| RF-32 | O sistema deve detectar e registar **atrasos** (entrada após horário) e **saídas antecipadas**. | Alta |
| RF-33 | O sistema deve detectar e registar **faltas** (ausência de marcação em dia útil). | Alta |
| RF-34 | O sistema deve permitir classificar uma ausência como falta justificada (licença, dispensa, etc.). | Média |
| RF-35 | O sistema deve permitir correcções manuais por um utilizador com permissão adequada, com registo de auditoria. | Alta |

### 4.5 Sincronização e comunicação

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF-40 | O terminal deve sincronizar as marcações com a API do backend através de HTTPS/REST. | Alta |
| RF-41 | O terminal deve suportar conectividade **Wi-Fi**, **GSM (SIM800L)** e, preferencialmente, **Ethernet**. | Alta |
| RF-42 | A sincronização deve ser periódica e/ou despoletada por eventos (marcação, restabelecimento de rede). | Alta |
| RF-43 | O terminal deve receber do backend a lista actualizada de colaboradores e credenciais. | Alta |
| RF-44 | O backend deve rejeitar marcações duplicadas e garantir idempotência. | Alta |
| RF-45 | O terminal deve enviar heartbeat/status periódico (bateria, sinal, versão firmware). | Média |

### 4.6 Gestão e relatórios

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF-50 | O portal de gestão deve permitir consultar o registo diário de presenças por colaborador. | Alta |
| RF-51 | O portal deve apresentar relatórios de assiduidade (horas trabalhadas, extras, atrasos, faltas) por período. | Alta |
| RF-52 | O sistema deve permitir exportar relatórios em PDF e Excel/CSV. | Média |
| RF-53 | O sistema deve disponibilizar dashboard com indicadores (taxa de assiduidade, atrasos, faltas). | Média |
| RF-54 | O gestor deve poder aprovar/rejeitar pedidos de correcção de ponto. | Média |
| RF-55 | O sistema deve notificar o gestor e o RH sobre atrasos, faltas ou anomalias. | Média |

### 4.7 Integração com RH e folha de pagamento

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF-60 | As presenças registadas devem alimentar a tabela `rh.presencas`. | Alta |
| RF-61 | As horas extra devem ser disponibilizadas ao módulo de processamento salarial. | Alta |
| RF-62 | Faltas e atrasos devem ser considerados nos cálculos de remuneração e descontos. | Média |
| RF-63 | O sistema deve respeitar o multi-tenant: cada tenant vê apenas os seus colaboradores e terminais. | Alta |

---

## 5. Requisitos Não-Funcionais

### 5.1 Hardware do terminal

| ID | Requisito |
|----|-----------|
| RNF-01 | Microcontrolador ESP32-WROOM-32 (Wi-Fi + Bluetooth). |
| RNF-02 | Ecrã TFT 2.8" ILI9341 para interface com o colaborador. |
| RNF-03 | Leitor de cartões RFID MFRC522 (13,56 MHz). |
| RNF-04 | Sensor biométrico R307 para identificação por impressão digital. |
| RNF-05 | Módulo GPS NEO-6M para georreferenciação das marcações. |
| RNF-06 | Módulo GSM SIM800L para comunicação em locais sem Wi-Fi. |
| RNF-07 | Keypad 4×3 membrana para introdução de PIN/código. |
| RNF-08 | Alimentação por bateria 18650 com carregamento USB-C e autonomia mínima de 24 horas. |
| RNF-09 | LEDs de estado (verde/vermelho) e buzzer para feedback imediato. |
| RNF-10 | Caixa robusta para montagem em parede, dimensionada conforme `nexora/hardware.md`. |

### 5.2 Firmware

| ID | Requisito |
|----|-----------|
| RNF-20 | Desenvolvido em C/C++ para ESP32 (Arduino framework ou ESP-IDF). |
| RNF-21 | Suporte a OTA (atualização remota de firmware). |
| RNF-22 | Cache local de colaboradores e marcações (cartão SD ou SPIFFS/LittleFS). |
| RNF-23 | Relógio RTC com sincronização NTP/GPS para timestamp fiável. |
| RNF-24 | Criptografia das credenciais em repouso e em trânsito (TLS 1.2+). |
| RNF-25 | Logs locais para diagnóstico e envio remoto. |

### 5.3 Backend / API

| ID | Requisito |
|----|-----------|
| RNF-30 | API RESTful protegida por autenticação JWT/tokens. |
| RNF-31 | Validação de tenant em todos os endpoints. |
| RNF-32 | Rate-limiting nos endpoints de marcação para prevenir abuso. |
| RNF-33 | Auditoria de todas as operações de criação/alteração de presenças. |
| RNF-34 | Idempotência nas sincronizações do terminal. |
| RNF-35 | WebSocket ou push notifications para alertas em tempo real. |

### 5.4 Performance e disponibilidade

| ID | Requisito |
|----|-----------|
| RNF-40 | Tempo de resposta do terminal a uma marcação ≤ 2 segundos. |
| RNF-41 | Disponibilidade do backend ≥ 99,5%. |
| RNF-42 | Capacidade de armazenar no mínimo 10.000 marcações em modo offline. |
| RNF-43 | Sincronização automática assim que a conectividade for restabelecida. |

### 5.5 Segurança

| ID | Requisito |
|----|-----------|
| RNF-50 | As comunicações terminal-backend devem usar HTTPS/TLS. |
| RNF-51 | Os templates biométricos devem ser armazenados de forma irreversível (não deve ser possível reconstruir a imagem da impressão digital). |
| RNF-52 | Controlo de acesso baseado em papéis (RBAC) no portal de gestão. |
| RNF-53 | Protecção contra replay de marcações. |
| RNF-54 | Backup periódico dos registos de assiduidade. |

### 5.6 Usabilidade

| ID | Requisito |
|----|-----------|
| RNF-60 | Interface do terminal em Português (suporte futuro a Inglês). |
| RNF-61 | Mensagens claras de erro (credencial não reconhecida, sem rede, etc.). |
| RNF-62 | Portal de gestão responsivo e acessível. |

---

## 6. Modelo de Dados (resumo)

As entidades principais já existem ou serão estendidas no schema `rh`:

- `rh.funcionarios` — colaboradores com `horario_id` e `user_id`.
- `rh.horarios_trabalho` — definição dos horários.
- `rh.presencas` — registo diário de entrada, saída, horas extra e observações.
- `rh.cargos` — cargos/funções dos colaboradores.

### Extensões previstas

- `rh.credenciais_funcionario` (nova): ligação entre funcionário e credenciais biométricas/RFID/PIN.
- `rh.terminais_assiduidade` (nova): cadastro dos terminais IoT (identificador, localização, tenant, estado).
- `rh.marcacoes_ponto` (nova): registo bruto de cada marcação (entrada/saída, timestamp, terminal, GPS).
- `rh.correcoes_ponto` (nova): pedidos e aprovações de correcção com auditoria.
- `rh.feriados` (nova): feriados e dias de excepção por tenant.

---

## 7. Integrações

| Sistema | Tipo de integração | Dados trocados |
|---------|-------------------|----------------|
| Backend Nexora (Go) | REST API + WebSocket | Marcações, colaboradores, horários, relatórios. |
| Módulo RH | Base de dados partilhada | `funcionarios`, `horarios_trabalho`, `presencas`. |
| Processamento Salarial | Base de dados / API | Horas extra, faltas, atrasos. |
| Notificações Push (Firebase) | Push service | Alertas de atrasos, faltas, aprovações. |
| Recrutamento | Indirecta via RH | Candidatos contratados tornam-se funcionários. |

---

## 8. Casos de Uso Principais

### UC-01 — Marcar entrada no terminal
1. Colaborador aproxima cartão RFID ou coloca dedo no sensor.
2. Terminal identifica o colaborador.
3. Terminal regista data/hora/GPS/terminal.
4. Terminal mostra confirmação e acende LED verde.
5. Terminal sincroniza com backend quando possível.

### UC-02 — Consultar presenças no portal
1. Gestor acede ao portal de assiduidade.
2. Selecciona período e equipa.
3. Sistema apresenta lista de presenças, atrasos e faltas.
4. Gestor exporta relatório em Excel.

### UC-03 — Corrigir marcação
1. Colaborador submete pedido de correcção com justificação.
2. Gestor recebe notificação.
3. Gestor aprova ou rejeita o pedido.
4. Sistema actualiza `rh.presencas` e regista auditoria.

### UC-04 — Funcionamento offline
1. Terminal perde conectividade.
2. Terminal continua a aceitar marcações usando cache local.
3. Terminal armazena marcações na memória local.
4. Quando a rede volta, sincroniza automaticamente.

---

## 9. Permissões (RBAC)

| Permissão | Descrição |
|-------------|-----------|
| `assiduidade.marcar` | Permite marcar ponto no terminal (implícito aos colaboradores). |
| `assiduidade.visualizar` | Consultar presenças próprias ou da equipa. |
| `assiduidade.gerir` | Corrigir, aprovar e parametrizar horários. |
| `assiduidade.relatorios` | Gerar e exportar relatórios de assiduidade. |
| `assiduidade.terminais` | Gerir terminais IoT e firmware. |
| `assiduidade.admin` | Acesso total ao módulo. |

---

## 10. Roadmap Sugerido

| Fase | Entregável |
|------|------------|
| 1 | Especificação da API de marcações e extensão do schema `rh`. |
| 2 | Firmware base do terminal (biometria + RFID + Wi-Fi/GSM + cache offline). |
| 3 | Backend: endpoints de marcações, sincronização e cálculo de horas. |
| 4 | Portal web de gestão de assiduidade. |
| 5 | Integração com processamento salarial e relatórios avançados. |
| 6 | Suporte a múltiplos terminais, turnos e georreferenciação avançada. |

---

## 11. Glossário

| Termo | Significado |
|-------|-------------|
| **Assiduidade** | Conjunto de registos e cálculos relacionados com a presença do colaborador no trabalho. |
| **Marcação** | Registo de entrada ou saída de um colaborador. |
| **Terminal** | Dispositivo IoT ESP32 instalado no local de trabalho para marcação de ponto. |
| **Tenant** | Entidade/empresa isolada no sistema multi-empresa do Nexora. |
| **Template biométrico** | Representação digital irreversível da impressão digital usada para comparação. |

---

*Documento gerado a partir da análise do projecto Nexora (backend `rh`, hardware ESP32 e integração recrutamento→RH).*
