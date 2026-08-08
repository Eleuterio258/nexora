# Arquitetura de Reconhecimento Facial

## 1. Diagrama de fluxo

```mermaid
flowchart LR
    A[Dispositivo de Captura<br/>Câmera / Webcam / Mobile] --> B{Captura Facial}
    B --> C{Validação de Qualidade}
    C -->|Face detectada, qualidade OK| D{Liveness Detection}
    C -->|Face ausente / baixa qualidade| B
    D -->|Vivo| E[Pré-processamento<br/>Alinhamento, normalização, crop]
    D -->|Ataque detectado| F[Rejeitar]
    E --> G[Modelo de Reconhecimento<br/>ArcFace / AdaFace / FaceNet]
    G --> H[Embedding Facial<br/>Vetor 128/512/1024D]
    H --> I[Encriptação<br/>AES-256 + TLS 1.3]
    I --> J[(Base de Dados<br/>Templates + Metadados)]
    J --> K[Motor de Similaridade<br/>FAISS / pgvector / Milvus]
    K --> L[Resultado<br/>Match / No-match / Score]

    style A fill:#e1f5fe
    style G fill:#fff3e0
    style I fill:#f3e5f5
    style J fill:#e8f5e9
    style F fill:#ffebee
    style L fill:#e8f5e9
```

---

## 2. Descrição das etapas

### 2.1 Captura facial
- **Entrada:** stream de vídeo ou imagem estática do dispositivo.
- **Requisitos:**
  - Resolução mínima recomendada: face detectável com ≥ 80×80 px após crop.
  - Pose frontal ou near-frontal; evitar oclusão excessiva.
  - Iluminação uniforme; evitar backlight forte.
- **Saída:** frame bruto para validação.
- **Recomendação:** não persistir frames brutos sem necessidade explícita de auditoria.

### 2.2 Validação de qualidade
- **Objetivo:** garantir que a imagem é adequada para reconhecimento.
- **Verificações:**
  - Detecção de face (RetinaFace, MTCNN, YuNet).
  - Número de faces igual a 1.
  - Olhos abertos e face alinhada.
  - Nitidez / exposição / contraste dentro de limites aceitáveis.
- **Ação em falha:** solicitar nova captura com mensagem clara ao usuário.

### 2.3 Liveness detection
- **Objetivo:** confirmar que o rosto pertence a uma pessoa viva.
- **Técnicas:**
  - **Passiva:** análise de textura, reflexos, profundidade, fluxo óptico.
  - **Ativa:** desafios de movimento (piscar, virar, sorrir).
- **Recomendação:** para cenários de alto risco, combinar passiva + ativa ou usar sensor de profundidade (ToF / LiDAR / câmera 3D).
- **Ação em falha:** bloquear e registrar tentativa.

### 2.4 Pré-processamento
- Alinhamento dos pontos fiduciais (landmarks).
- Crop padronizado (ex: 112×112 ou 224×224 conforme modelo).
- Normalização de intensidade e cor (RGB, subtract mean, divide std).

### 2.5 Modelo de reconhecimento
- **Opções recomendadas:**
  - **ArcFace / AdaFace:** estado da arte para precisão e robustez.
  - **MagFace:** útil quando se deseja estimar também a qualidade do template.
  - **MobileFaceNet:** para edge/mobile com baixa latência.
- **Critérios de escolha:**
  - Acurácia em benchmarks (LFW, IJB-C, MegaFace).
  - Latência e footprint de memória.
  - Avaliação de bias entre grupos demográficos.
- **Versionamento:** versionar o modelo e nunca misturar embeddings de modelos diferentes.

### 2.6 Embedding facial
- Vetor denso de 128, 512 ou 1024 dimensões.
- **Métricas de similaridade:**
  - Cosine similarity (mais comum).
  - Distância euclidiana normalizada.
- **Threshold típico:** calibrar no dataset próprio; valores de referência:
  - ArcFace/AdaFace: cosine similarity ≥ 0,55–0,65 para match.
- **Importante:** embeddings são dados biométricos sensíveis. Tratá-los como PII.

### 2.7 Encriptação
- **Em trânsito:** TLS 1.2 ou superior; autenticação mútua entre serviços críticos.
- **Em repouso:**
  - AES-256 para criptografia de campo ou volume de banco.
  - Chaves gerenciadas por HSM/KMS; nunca hardcoded.
  - Rotação periódica de chaves.
- **Observação:** como a comparação é aproximada, hashing com sal não funciona para templates. Criptografia reversível ou técnicas de template protection (cancelable biometrics) são as alternativas.

### 2.8 Base de dados
- **Armazenar:**
  - Embedding criptografado.
  - Metadados: timestamp, versão do modelo, score de qualidade, ID de usuário referenciado.
  - Opcional: imagem de referência reduzida e criptografada, apenas se necessário para auditoria.
- **Não armazenar:** frames brutos capturados do dia a dia (excluir após processamento).
- **Infraestrutura:**
  - Isolamento de rede.
  - Controle de acesso mínimo (RBAC).
  - Logs de auditoria para acesso e alterações.
- **Busca 1:N:** utilizar índice de vizinhos aproximados (ANN) como FAISS, Milvus ou pgvector para escalabilidade.

---

## 3. Riscos e mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Foto / replay / deepfake | Acesso não autorizado | Liveness passiva + ativa; desafios de movimento; sensores de profundidade |
| Embeddings vazados | Reidentificação / uso cruzado | Criptografia em repouso; acesso mínimo; chaves em KMS/HSM |
| Modelo desatualizado | Degradação de precisão | Versionamento e monitoramento contínuo de FAR/FRR |
| Mudança de modelo | Incompatibilidade de templates | Planejar re-enrolamento ao trocar modelo |
| Bias demográfico | Taxas de erro desiguais | Testar por grupo; ajustar thresholds por subpopulação se necessário |
| Escalada 1:N | Falsos positivos em massa | ANN + threshold calibrado; indexação eficiente |
| Canal interceptado | Injeção de imagem falsa | TLS mútuo; assinatura de payload; validação no servidor |

---

## 4. Checklist de implementação

- [ ] Definir base legal e consentimento do usuário (LGPD/GDPR).
- [ ] Escolher modelo de embedding e versioná-lo.
- [ ] Implementar detecção de face e validação de qualidade.
- [ ] Implementar liveness (passiva; ativa se cenário exigir).
- [ ] Criptografar embeddings em repouso e trânsito.
- [ ] Armazenar apenas dados mínimos e metadados técnicos.
- [ ] Configurar motor de busca por similaridade (1:N) ou comparação 1:1.
- [ ] Estabelecer thresholds calibrados no dataset próprio.
- [ ] Implementar logs de auditoria e controle de acesso.
- [ ] Criar fluxo de exclusão e portabilidade dos dados biométricos.
- [ ] Realizar testes de segurança (PAD — Presentation Attack Detection).

---

## 5. Considerações de compliance

- **LGPD / GDPR:** embeddings faciais são dados pessoais sensíveis. Exigem:
  - Consentimento explícito.
  - Finalidade clara e limitada.
  - Tempo de retenção definido.
  - Direito de acesso, correção, exclusão e portabilidade.
- **Anonimização:** embeddings não são totalmente anônimos. Reconstruções aproximadas são possíveis na literatura. Tratá-los como dados sensíveis.
- **Retenção de imagens:** manter imagens brutas apenas se justificado e com retenção curta; descartar após extração do template quando possível.

---

## 6. Métricas de avaliação

- **FAR (False Acceptance Rate):** taxa de aceitação de um não-usuário como usuário.
- **FRR (False Rejection Rate):** taxa de rejeição de um usuário legítimo.
- **EER (Equal Error Rate):** ponto onde FAR = FRR; útil para escolher threshold.
- **PAD metrics:** APCER (Attack Presentation Classification Error Rate) e BPCER (Bona Fide Presentation Classification Error Rate).

---

## 7. Referências de tecnologia

- **Detecção de face:** RetinaFace, MTCNN, YuNet, MediaPipe Face Detection.
- **Liveness:** FaceID-like challenge-response, passive liveness SDKs, depth sensors.
- **Modelos de embedding:** ArcFace, AdaFace, MagFace, FaceNet, MobileFaceNet.
- **Busca ANN:** FAISS, Milvus, Pinecone, pgvector, Weaviate.
- **Criptografia:** AES-256, TLS 1.3, AWS KMS / Azure Key Vault / HashiCorp Vault.

---

*Documento gerado para orientar a implementação segura e escalável do pipeline de reconhecimento facial.*
