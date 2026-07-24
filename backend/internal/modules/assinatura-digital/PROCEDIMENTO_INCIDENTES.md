# Procedimento de incidentes — módulo `assinatura-digital`

Para operação de rotina (deploy, configuração, monitorização), ver
[MANUAL_OPERACIONAL.md](./MANUAL_OPERACIONAL.md). Este documento cobre o que
fazer quando algo corre mal de forma grave o suficiente para exigir uma
resposta a incidente, não tarefas do dia-a-dia.

**Nota**: este procedimento é uma proposta técnica inicial, escrita a partir
do que o código faz hoje — não foi validado por uma equipa de segurança
dedicada nem aprovado formalmente. Tratar como ponto de partida, não como
política final.

## Princípio geral

As evidências (`assinatura_digital.logs`, `versoes_assinadas`,
`validacoes`) são append-only por trigger de base de dados (Fase 1) — nada
neste procedimento deve envolver `UPDATE`/`DELETE` directo nessas tabelas.
Qualquer investigação regista-se como uma **nova** linha (log, validação),
nunca como alteração do que já lá está.

## 1. Suspeita de comprometimento da chave privada de assinatura

**Sintomas**: acesso não autorizado detectado a `SIGNATURE_DEV_KEY_PATH` (ou
ao cofre de chaves de um provider real), ou um provider real reporta uma
assinatura que este sistema não gerou.

**Resposta**:

1. Rodar a chave imediatamente: apagar/mover o ficheiro em
   `SIGNATURE_DEV_KEY_PATH` (ou revogar a credencial no provider real) e
   reiniciar o servidor — gera/obtém uma chave nova (ver Manual Operacional
   secção 5);
2. Identificar todas as versões assinadas com o certificado comprometido:
   ```sql
   SELECT id, documento_id, tenant_id, created_at
   FROM assinatura_digital.versoes_assinadas
   WHERE certificado_fingerprint = '<fingerprint comprometido>';
   ```
3. Para cada versão afectada, registar uma validação `invalido` (o mesmo
   padrão já implementado para `certificate.revoked` no webhook — ver
   `processarCertificadoRevogadoTx`, `handlers/webhooks.go`) — nunca apagar
   ou alterar a versão original;
4. Notificar os tenants cujos documentos foram afectados;
5. Se o provider for real (não `dev`/`intic-stub`): reportar à CA
   (SCDM/INTIC) para revogação formal do certificado.

## 2. Suspeita de comprometimento do segredo do webhook

**Sintomas**: eventos de webhook com HMAC válido mas conteúdo inesperado;
segredo (`SIGNATURE_WEBHOOK_SECRET_<PROVIDER>`) exposto em logs, repositório
ou canal inseguro.

**Resposta**:

1. Rodar o segredo imediatamente no ambiente e (se o provider suportar) no
   lado do provider;
2. Enquanto o segredo antigo não for invalidado no provider, considerar
   desativar temporariamente o webhook (`SIGNATURE_WEBHOOK_ENABLED=false`)
   — a aplicação já nega tudo com esta flag, sem precisar de mais nada;
3. Auditar `assinatura_digital.webhook_events` por eventos suspeitos no
   período em que o segredo esteve exposto:
   ```sql
   SELECT id, provider, event_id, event_type, created_at
   FROM assinatura_digital.webhook_events
   WHERE created_at BETWEEN '<início da exposição>' AND '<agora>'
   ORDER BY created_at;
   ```
4. Para qualquer evento suspeito já processado, seguir o mesmo padrão do
   cenário 1 (registar validação `invalido` para as versões afectadas).

## 3. Força bruta ao código OTP

**Sintomas**: pico de respostas `401`/`429` em `POST
/convites/{token}/otp/validar` vindo do mesmo IP ou token.

**Resposta**:

1. O limite de 5 tentativas por código já bloqueia automaticamente (`429`,
   ver `ValidarOTP` — corrigido na Fase 2 para ser atómico sob concorrência,
   com testes em `otp_test.go`); confirmar que o limite está de facto a
   aplicar-se olhando para `otp_tentativas` do convite em causa;
2. Se o padrão sugerir um ataque distribuído (muitos convites/tokens
   diferentes, não só um): considerar rate limit adicional a nível de
   proxy/CDN por IP, já que a aplicação só limita por convite;
3. Não existe hoje bloqueio de IP a nível da aplicação — é uma lacuna
   conhecida, não um mecanismo que falhou.

## 4. Suspeita de adulteração de um documento assinado

**Sintomas**: um documento reportado como assinado, mas o conteúdo
apresentado a alguém não bate com o que foi assinado.

**Resposta**:

1. Correr `GET /documentos/{id}/validacao` (ou `POST .../revalidar` para
   deixar registo) — se o hash não bater ou a assinatura criptográfica
   falhar, o resultado será `invalido`, nunca `valido` (ver README secção
   6.7 e testes `pki.TestVerificarPAdES_ConteudoAlterado`);
2. Servir sempre a versão a partir do `storage_key` registado em
   `versoes_assinadas`/`documentos`, nunca a partir de uma cópia externa —
   `BaixarDocumento` já verifica o hash antes de servir;
3. Se a alteração for confirmada: tratar como uma falha de integridade do
   storage subjacente (não da aplicação, que recusa `Delete` sobre
   evidências — ver `storage.ErrEvidenceDeleteForbidden`) — investigar
   acesso directo ao disco/bucket por fora da aplicação.

## 5. Base de dados ou storage indisponível a meio de uma assinatura

**Comportamento já garantido pelo desenho (Fase 2)**: `marcarAssinado`
corre numa única transação — uma falha a meio (BD ou storage) reverte tudo;
o signatário nunca fica `assinado` sem uma versão PAdES correspondente. Não
há "reparação" manual necessária nesse caso — o pedido simplesmente falha e
pode ser repetido pelo utilizador.

**Se a base de dados ficar indisponível durante uma janela prolongada**:
seguir o procedimento geral de recuperação de desastre do Nexora ERP (fora
do âmbito deste módulo especificamente) — este módulo não tem requisitos de
recuperação diferentes do resto do backend, excepto que as evidências
(`logs`, `versoes_assinadas`, `validacoes`) são append-only e não podem ser
"corrigidas" após restauro, só complementadas com novas entradas.

## 6. Revogação de certificado por um provider real (quando existir)

Já implementado tecnicamente desde a Fase 3: o evento `certificate.revoked`
do webhook localiza todas as versões assinadas com o `certificado_fingerprint`
indicado e regista uma validação `invalido` para cada uma — ver
`processarCertificadoRevogadoTx`. O que falta é puramente o lado humano:

1. Confirmar com o provider a razão e o âmbito da revogação;
2. Identificar os tenants/documentos afectados (consulta na secção 1 acima);
3. Notificar os afectados e definir se algum processo de negócio precisa de
   ser refeito (nova assinatura, revalidação contratual, etc.) — decisão de
   negócio, não técnica.

## Depois de qualquer incidente

- Registar o incidente (o quê, quando, âmbito, resposta) fora deste
  repositório, no sistema de gestão de incidentes da organização;
- Rever se este documento precisa de ser actualizado com o que se aprendeu;
- Se o incidente revelar uma lacuna de código (não apenas operacional),
  tratar como qualquer outro bug — não faz sentido "documentar como
  aceitável" uma falha que devia ser corrigida.
