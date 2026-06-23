# Requisitos — Modulo Utilizadores

## Requisitos Funcionais

### RF01 — Perfil de Utilizador
O sistema deve permitir ao utilizador gerir o seu perfil: primeiro nome, ultimo nome, nome de exibicao, data de nascimento, genero e bio.

### RF02 — Preferencias Pessoais
O sistema deve armazenar preferencias personalizaveis por utilizador (chave/valor), como tema, idioma, moeda preferida e formato de data.

### RF03 — Configuracoes Pessoais
O sistema deve armazenar configuracoes por utilizador (chave/valor) separadas das preferencias de UI.

### RF04 — Notificacoes
O sistema deve entregar notificacoes ao utilizador com titulo, mensagem e tipo, e permitir marcar como lida.

### RF05 — Gestao de Dispositivos
O sistema deve registar os dispositivos de acesso do utilizador, permitindo marcar dispositivos como confiaveis.

### RF06 — Registo de Actividade
O sistema deve registar as actividades do utilizador por modulo (ex: acedeu a faturacao, editou cliente X).

### RF07 — Tokens de Utilizador
O sistema deve gerir tokens adicionais por utilizador: refresh, verificacao de email, MFA e integracao.

### RF08 — Logs de Seguranca Pessoais
O sistema deve registar eventos de seguranca por utilizador (ex: alteracao de password, novo dispositivo) com severidade.

### RF09 — Avatar
O sistema deve permitir ao utilizador carregar e gerir a sua foto de perfil.

### RF10 — Idioma e Timezone
O perfil deve armazenar o idioma e timezone preferidos, usados para formatar datas e textos no sistema.

---

## Requisitos Nao Funcionais

### RNF01 — Privacidade
Os dados de perfil sao privados ao utilizador. Outros utilizadores nao devem aceder ao perfil completo de terceiros.

### RNF02 — Tamanho de Avatar
O avatar deve ser validado no upload: tamanho maximo de 2MB, formatos aceites: JPEG e PNG.

### RNF03 — Notificacoes em Tempo Real
O sistema deve suportar entrega de notificacoes em tempo real via WebSocket ou Server-Sent Events.

### RNF04 — Retencao de Actividade
Os registos de actividade do utilizador devem ser retidos por no minimo 90 dias.

### RNF05 — Desempenho
A consulta de perfil e preferencias deve responder em menos de 200ms.
