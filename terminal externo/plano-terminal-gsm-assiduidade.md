# Plano de construção — Terminal GSM Dedicado (Controlo de Assiduidade)

> Plano de execução para transformar o conceito descrito em [terminal-gsm-assiduidade-satelite.md](terminal-gsm-assiduidade-satelite.md) num dispositivo real. Cobre hardware, firmware, backend, testes e caminho até produção.

## 0. Aviso honesto antes de começar

Isto **não é um projecto de software puro** como o resto do Nexora — é um produto de hardware com firmware embarcado e comunicação por rádio. Isso muda o tipo de risco:

- **Certificação regulatória**: rádios GSM/4G e, principalmente, satélite (Iridium/Inmarsat) normalmente precisam de homologação/type-approval junto da entidade reguladora de telecomunicações do país onde o aparelho vai operar (em Moçambique, o INCM). Vender ou operar um terminal com rádio não homologado é um risco legal, não só técnico.
- **Custo do canal satélite**: Iridium Certus/Inmarsat BGAN cobram por dados e por assinatura de linha; mesmo um evento de ponto pequeno tem custo por transmissão. Isto define se o satélite é viável como fallback raro ou inviável em uso diário.
- **Ciclo de hardware é lento**: escolher módulo → protótipo em breadboard → PCB → gabinete IP54 → certificação. Semanas/meses por iteração, não commits.
- **Nenhum destes três pontos bloqueia começar** — mas devem ser decisões conscientes, não assumidas. Ver secção 6 (Decisões a tomar cedo).

## 1. Fases

### Fase 1 — Validação de conceito em bancada (sem satélite, sem gabinete)

Objectivo: provar que ESP32 + GSM + RFID + assinatura HMAC + envio para a API Assiduidade funciona de ponta a ponta, com peças de desenvolvimento soltas (dev boards), sem preocupação estética ou de robustez.

Entregáveis:
- ESP32 dev board + módulo SIM7600 (ou similar) em breadboard, a enviar um evento de teste
- Leitor RFID/NFC a ler um cartão e produzir um `funcionario_id` de teste
- Firmware mínimo que assina o evento com HMAC-SHA256 (mesmo algoritmo do `devicehmac` do backend) e faz `POST` para um endpoint de teste
- Endpoint no backend a aceitar e verificar esse pedido (ver Fase 3)

Critério de saída: um cartão lido no protótipo aparece como evento de assiduidade real no Nexora ERP, de ponta a ponta, via GSM.

### Fase 2 — Firmware funcional (offline-first)

Objectivo: cobrir os requisitos funcionais descritos no documento de conceito.

Entregáveis:
- Fila de eventos offline em Flash (estrutura simples, com limite e política de descarte/alerta quando cheia)
- Sincronização automática quando a rede volta, com re-tentativa e backoff
- Ecrã LCD com estados (hora, última marcação, sinal GSM, bateria)
- Teclado + PIN como método de identificação alternativo ao RFID
- Gestão de bateria (medição de nível, aviso de bateria fraca)

Critério de saída: o dispositivo pode ficar 24h sem rede, acumular eventos, e sincronizar tudo correctamente ao reconectar, sem duplicar nem perder registos.

### Fase 3 — Integração backend

Objectivo: o Nexora ERP passa a saber emitir e verificar credenciais para este tipo de device, e a aceitar os seus eventos como assiduidade real.

Entregáveis:
- Registo do device em `hardware.devices` com `access_key_id`/`secret_access_key_hash`, tipo `terminal-gsm-satelite` (ou equivalente) e `permissions` limitadas a escrita de eventos de assiduidade
- Endpoint de emissão de credenciais (gestor cria o terminal no ERP, recebe o segredo uma única vez — mesmo padrão de `RNF-ID-02` do modelo de identidade)
- Wiring do `devicehmac.Verify` no handler que recebe os eventos deste device (hoje o pacote existe mas não está ligado a nenhum handler)
- Resolução do evento para `funcionario_id`, reaproveitando `recursos-humanos/service/funcionario.Service` (mesmo caminho já usado por outros dispositivos do módulo `hardware`)
- Activar `hmac_ativo=true` só para devices deste tipo

Critério de saída: um terminal real autentica, envia um evento assinado, e o evento aparece correctamente atribuído ao funcionário certo, com `tenant_id` isolado.

### Fase 4 — Gabinete e robustez física

Objectivo: sair da bancada para algo que aguenta obra/campo.

Entregáveis:
- Gabinete IP54 (comprar de catálogo ou desenhar/imprimir em 3D para protótipo)
- Antena GSM externa fixada, bateria com autonomia real testada (não só datasheet)
- Teste de temperatura (-10°C a 60°C) e de queda/vibração básico

Critério de saída: dispositivo sobrevive a um dia de uso em condições reais de obra/campo sem falhar.

### Fase 5 — Piloto com satélite (opcional, condicional à decisão de custo)

Objectivo: só depois de Fases 1-4 provadas com GSM, adicionar o módulo satélite como fallback.

Entregáveis:
- Módulo L-band integrado, com lógica de "só usar satélite se GSM falhar N vezes seguidas"
- Validação de custo real por evento enviado via satélite
- Teste em local sem cobertura móvel

Critério de saída: decisão informada — o satélite compensa o custo para o(s) cliente(s)-alvo, ou fica como opção premium/sob encomenda.

### Fase 6 — Piloto de campo e produção

Objectivo: 1-3 unidades num cliente real, por 2-4 semanas, antes de qualquer produção em série.

Entregáveis:
- Relatório de fiabilidade (registos perdidos, falhas de bateria, falhas de sincronização)
- Ajustes finais de firmware/hardware a partir do piloto
- Se fizer sentido comercialmente: homologação regulatória, escolha de fabricante/PCB em série, custo unitário final

## 2. Ordem recomendada

```text
Fase 1 (bancada) → Fase 3 (backend) em paralelo
        │
        ▼
Fase 2 (firmware offline-first)
        │
        ▼
Fase 4 (gabinete/robustez)
        │
        ▼
Fase 5 (satélite, opcional) → Fase 6 (piloto/produção)
```

A Fase 3 (backend) pode arrancar em paralelo com a Fase 1, porque não depende de hardware físico — só precisa de um cliente HTTP de teste a simular o dispositivo.

## 3. O que já existe e pode ser reaproveitado

- **Assinatura HMAC-SHA256**: `backend/internal/pkg/devicehmac/` — algoritmo pronto, só falta ligar a um handler e implementar o equivalente em firmware (ver [terminal-gsm-assiduidade-satelite.md](terminal-gsm-assiduidade-satelite.md), secção 9)
- **Schema de credenciais de device**: `hardware.devices` já tem `access_key_id`, `secret_access_key_hash`, `permissions`, `hmac_ativo`, `auth_version` (migration `20260808190000_hardware_device_hmac.up.sql`)
- **Resolução pessoa/funcionário**: `recursos-humanos/service/funcionario.Service`, já usado por outros dispositivos de assiduidade
- **Sistema flexível de assiduidade**: pipeline de eventos já em produção (`eventos_assiduidade`), pronto a receber mais uma fonte de eventos

## 4. O que não existe e precisa de ser criado de raiz

- Firmware do zero (nenhum código de dispositivo embarcado existe hoje no repositório)
- Endpoint específico de emissão/rotação de credenciais para este tipo de device (o padrão existe para outros, mas não está implementado para este)
- Handler HTTP que liga `devicehmac.Verify` a um evento de assiduidade (o pacote está pronto mas órfão — não é chamado em lado nenhum ainda)
- Selecção real de fornecedor de módulo GSM, leitor RFID, ecrã, gabinete e (se avançar) módulo satélite
- Qualquer relação comercial com provedor satelital (Iridium/Inmarsat não vendem directo a utilizador final; passa por revendedor)

## 5. Riscos principais

| Risco | Impacto | Mitigação |
|---|---|---|
| Homologação regulatória do rádio | Pode impedir venda/uso legal | Confirmar cedo junto do INCM se módulos GSM/satélite já homologados (muitos módulos comerciais já vêm com certificação de fábrica reaproveitável) |
| Custo do satélite inviabilizar o caso de uso | Fase 5 vira feature "de catálogo" nunca usada | Validar custo real por evento antes de investir em integração |
| Autonomia de bateria real ficar abaixo do datasheet | Terminal falha em campo sem aviso | Testar autonomia real na Fase 4, não confiar só na especificação |
| Sincronização offline perder/duplicar eventos | Corrompe dados de assiduidade, afecta salário | Desenhar idempotência (ex.: UUID por evento gerado no dispositivo) desde a Fase 2 |
| Ninguém no projecto tem experiência prévia de hardware/firmware embarcado | Ciclos de tentativa-erro mais longos que software puro | Aceitar timeline mais longa; considerar consultoria/parceiro de hardware para Fases 4-6 |

## 6. Decisões a tomar cedo

Antes de comprar qualquer peça:

1. **Satélite é essencial no MVP ou é fase 2 do produto?** Isto muda drasticamente o custo e complexidade do protótipo inicial.
2. **Volume-alvo**: protótipo único para um cliente, ou intenção de produzir em série? Muda a escolha entre dev boards (rápido, caro por unidade) e PCB customizado (lento no início, barato em série).
3. **Quem vai escrever o firmware?** ESP-IDF/C é uma competência distinta do stack actual (Go/Python/Kotlin/PHP) — decidir se é internamente aprendido, contratado, ou terceirizado.
4. **Nome/tipo do device no schema**: como este terminal vai ser distinguido de outros dispositivos `hardware` existentes (leitores faciais, QR) — precisa de um `device_type` ou equivalente antes da Fase 3.

## 7. Próximo passo imediato

Sugestão concreta para arrancar já, sem esperar por peças físicas: implementar a Fase 3 (backend) primeiro, porque é 100% software e usa infra já existente — dá para testar com um script/cliente HTTP a simular o terminal antes de qualquer hardware chegar. Depois, comprar as peças da Fase 1 (ESP32 dev board + módulo SIM7600 + leitor RFID) em paralelo.
