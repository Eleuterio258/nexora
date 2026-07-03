# Guia de Prompts para Geração de Mockups — E258Tech App Completo

Guia completo para gerar mockups de **todas as telas** do sistema escolar mobile E258Tech, organizados por fluxo de utilizador. Baseado em **Material Design 3**, identidade **Emerald Green**, layout sem bordas e tipografia **Plus Jakarta Sans**.

---

## Sistema de Design — Tokens Globais

> **Bloco base** — inclua sempre no início de qualquer prompt para garantir consistência:
> `"E258Tech brand identity, Material Design 3, borderless layout, Plus Jakarta Sans typography, primary color Emerald Green #10B981, containers #F0FDF4 mint background, 28dp rounded corners no borders, white main background #FFFFFF, dark text #111827, secondary text #6B7280, 9:16 aspect ratio, ultra high resolution, pixel-perfect UI"`

| Token | Hex | Uso |
|---|---|---|
| Primária | `#10B981` | Botões, ícones ativos, destaques |
| Mint 50 | `#F0FDF4` | Fundo de containers/cards |
| Mint 200 | `#D1FAE5` | Pill de seleção ativo |
| Emerald 700 | `#047857` | Texto sobre fundo mint |
| Texto Dark | `#111827` | Títulos e texto primário |
| Texto Gray | `#6B7280` | Subtítulos e labels |
| Superfície | `#FFFFFF` | Fundo da tela |
| Erro | `#EF4444` | Estados de erro |
| Aviso | `#F59E0B` | Alertas e urgência |
| Sucesso | `#10B981` | Confirmações |

---

# FLUXO 1 — AUTENTICAÇÃO

## 1.1 Tela de Splash / Abertura

> **Prompt:**
> "High-fidelity mobile app UI mockup, splash screen, E258Tech brand. 9:16 aspect ratio. Full screen emerald gradient background from #10B981 top to #047857 bottom. Center: Nexora School logo icon — stylized bold letter "N" in white with rounded corners and long flat shadow inside, right stem has a negative-space cutout of the Mozambique country map silhouette, small white rounded squares (digital pixels) floating above the top-right corner. Logo size 96dp, clean vector style. Below logo: 'E258Tech' wordmark in white 28sp bold, letter-spacing 2dp. Below wordmark: 'Sistema Escolar Digital' in white 14sp regular with 40% opacity. Bottom area: thin white linear progress bar 200dp wide, 2dp height, partially filled, showing loading. Very bottom: 'Versão 2.1.0' in white 11sp with 30% opacity. No status bar. Centered composition, clean minimal design, premium mobile app feel, ultra high resolution."

---

## 1.2 Tela de Onboarding — Slide 1 de 3

> **Prompt:**
> "High-fidelity mobile app UI mockup, onboarding screen slide 1 of 3, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top 50%: large flat illustration of a student with books and a smartphone, emerald green tones, minimal vector art style on mint background (#F0FDF4), 28dp corners, no border. Page dot indicators below illustration: 3 dots, first dot filled emerald elongated pill, other two small gray circles. Bottom section: 'Acompanhe as suas Notas' in 26sp bold dark #111827 centered. Below: 'Veja o seu desempenho em todas as disciplinas em tempo real.' in 15sp gray #6B7280 centered, 2-line max. Skip button top-right 'Saltar' in emerald text style. Primary button at bottom full-width 56dp 28dp radius emerald fill 'Próximo'. Plus Jakarta Sans, ultra high resolution."

---

## 1.3 Tela de Onboarding — Slide 2 de 3

> **Prompt:**
> "High-fidelity mobile app UI mockup, onboarding screen slide 2 of 3, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top 50%: large flat illustration of a weekly calendar/timetable with color-coded class blocks in emerald, blue and amber, vector art on mint background #F0FDF4, 28dp corners. Page dots: 3 dots, second dot filled emerald pill, others small gray. Title: 'O Seu Horário Sempre à Mão' 26sp bold dark centered. Body: 'Consulte as aulas do dia, semana, e receba lembretes automáticos.' 15sp gray centered. Skip button top-right. Primary button 'Próximo' emerald full-width 56dp. Plus Jakarta Sans, ultra high resolution."

---

## 1.4 Tela de Onboarding — Slide 3 de 3

> **Prompt:**
> "High-fidelity mobile app UI mockup, onboarding screen slide 3 of 3, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top 50%: flat illustration of notification bell with communication bubbles, emerald tones, on mint background. Page dots: 3 dots, third dot filled emerald pill. Title: 'Fique Sempre Informado' 26sp bold dark centered. Body: 'Receba comunicados, tarefas e avisos da escola diretamente no seu telemóvel.' 15sp gray centered. Two buttons at bottom: secondary outlined button 'Entrar' full-width 56dp emerald border, then below primary button 'Criar Conta' full-width 56dp emerald fill. Plus Jakarta Sans, ultra high resolution."

---

## 1.5 Tela de Login

> **Prompt:**
> "High-fidelity mobile app UI mockup, login screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top 25%: subtle mint radial gradient #F0FDF4 fading to white. Centered Nexora School logo icon 64dp emerald green — stylized bold letter "N" with rounded corners and long flat shadow, right stem with negative-space cutout of Mozambique map silhouette, small emerald rounded squares floating above top-right like digital pixels. 'E258Tech' 24sp bold emerald below, 'Sistema Escolar Digital' 13sp gray below that. Section title 'Bem-vindo de volta' 22sp bold dark #111827, subtitle 'Insira as suas credenciais para continuar' 14sp gray #6B7280. Two MD3 Outlined TextField inputs, 56dp height, 12dp radius, emerald border on focus: first field label 'Número de Estudante' with person Material Symbol prefix icon in gray; second field label 'Senha' with lock icon prefix, eye toggle suffix. 'Esqueceu a senha?' emerald text button right-aligned below password. Primary button full-width 56dp 28dp radius emerald fill #10B981 white text 'Entrar' 16sp semibold. Divider 'ou' with lines. Secondary button outlined 'Entrar como Encarregado' 56dp full-width emerald border. Very bottom: 'Problemas? Contacte a Secretaria' 12sp gray centered. Plus Jakarta Sans, ultra high resolution."

---

## 1.6 Tela de Recuperar Senha

> **Prompt:**
> "High-fidelity mobile app UI mockup, forgot password screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow left. Center illustration: flat envelope with lock icon, emerald tones, on mint container #F0FDF4 28dp radius no border. Title 'Recuperar Acesso' 22sp bold dark. Body text: 'Introduza o número de estudante. Enviaremos um código de verificação para o email registado.' 15sp gray centered, 3-line max. MD3 Outlined TextField 'Número de Estudante' 56dp emerald border. Primary button full-width 56dp 28dp radius emerald fill 'Enviar Código'. Below button: 'Voltar ao Login' text link emerald centered. Plus Jakarta Sans, ultra high resolution."

---

## 1.7 Tela de Verificação por Código OTP

> **Prompt:**
> "High-fidelity mobile app UI mockup, OTP code verification screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow. Center: shield with checkmark illustration, emerald tones, mint container. Title 'Verificar Identidade' 22sp bold dark. Body: 'Código enviado para l***@gmail.com' 14sp gray. Four large OTP input boxes in a row, each 64dp wide 64dp tall, 12dp radius, MD3 Outlined style — first 3 boxes filled with digits in 28sp bold dark, last box empty with emerald focused border and cursor. Below inputs: 'Não recebeu o código? Reenviar em 0:45' 13sp gray with countdown. Primary button full-width 56dp 28dp radius emerald fill 'Confirmar'. Plus Jakarta Sans, ultra high resolution."

---

## 1.8 Tela de PIN de Acesso Rápido

> **Prompt:**
> "High-fidelity mobile app UI mockup, PIN setup screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow. Avatar circle 72dp with user photo placeholder, emerald ring border. Name 'Lucas Machava' 18sp bold, '10ª Classe' 13sp gray. Title 'Criar PIN de Acesso Rápido' 20sp bold dark centered. Subtitle 'Use 4 dígitos para entrar mais rapidamente' 14sp gray centered. 4 PIN dot indicators in a row, 20dp circles: 2 filled emerald, 2 outlined gray. Large numeric keypad below: 3x4 grid of circular buttons 72dp, digits 1-9 then backspace, 0; digit buttons have mint background #F0FDF4 no border 36dp font dark, backspace icon in gray. Skip link 'Configurar Depois' emerald text centered below keypad. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 2 — PORTAL DO ALUNO

## 2.1 Dashboard Principal

> **Prompt:**
> "High-fidelity mobile app UI mockup, student home dashboard, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Status bar dark icons top. Top row: 'Olá, Lucas!' 26sp bold dark #111827 left, avatar circle 44dp right with emerald ring. Date subtitle 'Segunda-feira, 23 de Junho' 13sp gray left. Horizontal scroll row of 3 quick-stat mini cards (no border, 28dp radius, #F0FDF4): card 1 — emerald graduation icon, 'Média Geral' label, '15.7' bold emerald value; card 2 — bell icon, 'Notificações' label, '3' bold value; card 3 — warning icon amber, 'Tarefas Atrasadas' label, '1' bold amber value. Section label 'Hoje no Horário' 16sp semibold dark. Two class cards (no border 28dp radius white shadow elevation 1): each card — left colored circle with subject initial, subject name 16sp bold, teacher 13sp gray, time pill chip 'Agora · 07h30–08h30' filled emerald or upcoming 'Próxima · 09h00'. Floating notification badge emerald on bell. Section 'Comunicados Recentes': 1 card no border 28dp shadow, message preview 2 lines, date. MD3 Navigation Bar bottom: Home (active emerald pill), Notas, Horário, Mais. Plus Jakarta Sans, ultra high resolution."

---

## 2.2 Tela de Notificações

> **Prompt:**
> "High-fidelity mobile app UI mockup, notifications screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Notificações' 20sp bold, 'Marcar todas lidas' emerald text button right. Filter chips row: 'Todas' (active filled emerald), 'Notas', 'Horário', 'Comunicados', 'Tarefas' — outlined gray inactive. Section label 'Não Lidas · 3' 13sp gray semibold. Unread notification cards (no border 28dp radius white shadow elevation 1): left vertical 4dp emerald accent bar, icon circle 44dp emerald fill (bell/book/calendar symbol white), title 14sp bold dark, description 13sp gray 2 lines, timestamp '5 min atrás' 11sp gray right. Cards: 'Nova Nota em Matemática — Prof. Silva lançou nota: 17 valores', 'Reunião de Pais — Sexta-feira 27 Jun às 14h00 — Confirme presença', 'Tarefa Entregue — Física enviada com sucesso'. Section divider 'Anteriores' 12sp gray. Read notifications: same layout, no accent bar, background #F9FAFB. Swipe action hint: left swipe reveals red delete. MD3 Navigation Bar. Plus Jakarta Sans, ultra high resolution."

---

## 2.3 Tela de Pesquisa Global

> **Prompt:**
> "High-fidelity mobile app UI mockup, global search screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, MD3 Search Bar full-width (no border, 12dp radius, #F0FDF4 background) with search icon left, 'Pesquisar disciplinas, professores...' placeholder 14sp gray, microphone icon right, cursor blinking. Chip row 'Sugestões': 'Matemática', 'Prof. Silva', 'Horário de Sexta' — outlined emerald chips. Section 'Resultados Recentes' 13sp gray. Result list items (no border, divider lines only): each row — category icon emerald left, title 14sp bold, subtitle 12sp gray, arrow right gray. Example results: book icon 'Matemática' / 'Disciplina · 10ª Classe A', person icon 'Prof. António Silva' / 'Docente · Matemática e Física', calendar icon 'Física · Quarta 08h00' / 'Próxima aula'. Empty state when typing: large search illustration mint container centered, 'Sem resultados para X' 16sp bold, 'Tente outro termo' 13sp gray. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 3 — NOTAS E DESEMPENHO

## 3.1 Lista de Notas por Trimestre

> **Prompt:**
> "High-fidelity mobile app UI mockup, grades list screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Minhas Notas' 20sp bold. Trimester tab selector: 3 MD3 tabs '1º Trim', '2º Trim', '3º Trim', active tab emerald underline indicator 3dp. Summary hero card: no border 28dp radius #F0FDF4 background — left side circular chart ring 80dp diameter in emerald showing 78% fill, center of ring '15.7' 28sp bold emerald, below '/ 20' 14sp gray; right side: 3 mini stats stacked — 'Aprovado' chip emerald, 'Melhor: Biologia 18', 'A melhorar: Química 13'. Subject list below: cards no border 28dp radius white shadow elevation 1. Each subject card: left 48dp circle with subject abbreviation bold white on emerald/blue/amber background, subject name 15sp bold, teacher 12sp gray; right side: grade 22sp bold dark, small horizontal progress bar emerald below grade, percentage 11sp gray. Cards: Matemática 17, Física 14, Biologia 18, História 16, Química 13, Português 15, Ed.Física 19. MD3 Navigation Bar 'Notas' active emerald pill. Plus Jakarta Sans, ultra high resolution."

---

## 3.2 Detalhe da Disciplina — Aba Notas

> **Prompt:**
> "High-fidelity mobile app UI mockup, subject detail with grades tab, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top app bar: back arrow, 'Matemática' 20sp bold center, share icon right, no elevation. Hero section: no border 28dp radius #F0FDF4 card — left emerald circle 72dp with math sigma symbol white; right: 'Matemática' 18sp bold, 'Prof. António Silva' 13sp gray, '2 aulas/semana' 12sp gray, chip 'Amanhã · 08h00' filled emerald small. MD3 Tab row: 'Notas' (active underline emerald), 'Conteúdo', 'Tarefas', 'Assiduidade' — scrollable tabs. Tab Notas content: trimester breakdown 3 mini cards in a row (no border 16dp radius mint): '1º T: 16', '2º T: 17', '3º T: —' with status chip 'Em curso'. Grade history label 'Histórico de Avaliações'. Grade rows (divider separated, no cards): date 12sp gray left, category chip (Teste/Ficha/Oral/TPC) colored center, notes icon right-of-chip, grade value 18sp bold dark right with small emerald dot if above 10, red dot if below. Rows: '15 Mar · Teste 1 · 16', '28 Mar · Ficha · 17', '10 Apr · Teste 2 · 18'. FAB emerald '+' bottom-right rounded. Plus Jakarta Sans, ultra high resolution."

---

## 3.3 Detalhe da Disciplina — Aba Conteúdo

> **Prompt:**
> "High-fidelity mobile app UI mockup, subject content/curriculum tab, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top app bar: back arrow, 'Matemática' 20sp bold, tabs. MD3 Tab row: 'Notas', 'Conteúdo' (active underline emerald), 'Tarefas', 'Assiduidade'. Search bar within tab: #F0FDF4 no border 12dp radius 'Pesquisar conteúdo...' with search icon. Progress card: no border 28dp radius #F0FDF4 — 'Progresso do Programa' 14sp bold, horizontal thick progress bar emerald 65% width, '65% concluído · 18 de 28 tópicos' 12sp gray. Curriculum unit list (accordion style): Unit header row — folder icon emerald, 'Unidade 1: Álgebra' 14sp bold, '6/6 tópicos' chip mint filled emerald text right, expand arrow. Expanded unit shows tópico rows with indent: check circle emerald filled if completed, text 13sp dark, 'Visto em 10 Mar' 11sp gray right. Unit 2 collapsed. Unit 3 collapsed with '2/4 tópicos' chip in amber. Plus Jakarta Sans, ultra high resolution."

---

## 3.4 Boletim Escolar

> **Prompt:**
> "High-fidelity mobile app UI mockup, school report card screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Boletim Escolar' 20sp bold, download icon right (emerald). Header card: no border 28dp radius #F0FDF4 — student avatar circle 56dp, 'Lucas Machava' 18sp bold, 'Nº 12345 · 10ª Classe A' 13sp gray, 'Ano Lectivo 2026' 12sp emerald semibold. MD3 Tab row: '1º Trimestre', '2º Trimestre', '3º Trimestre', 'Final'. Boletim table card: no border 28dp radius white shadow elevation 2. Table header row: 'Disciplina' left, 'MF' center (Médias por ficha columns), 'MT' right — all 12sp bold dark. Table rows alternating white/#FAFAFA: subject name 13sp dark left, grade values 13sp center, mean 14sp bold right colored emerald if ≥10, red if <10. Rows: Matemática, Física, Biologia, etc. Footer row: 'Média Geral' bold left, '15.7' 16sp bold emerald right. Stamp area: 'APROVADO' in emerald bold outlined box bottom-right. 'Baixar PDF' full-width outlined button emerald. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 4 — HORÁRIO

## 4.1 Grade Horária Semanal

> **Prompt:**
> "High-fidelity mobile app UI mockup, weekly schedule screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Horário Semanal' 20sp bold, calendar icon right. Week navigator: left arrow, 'Semana de 23–27 Jun 2026' 14sp bold center, right arrow. Day selector strip: horizontal row of 5 pill buttons Mon-Fri labels + day number — 'Seg 23' active filled emerald #10B981 white text 28dp radius, others gray outlined. Current time indicator: thin emerald horizontal line across schedule grid with filled emerald dot left and 'Agora 08h15' label. Schedule grid: left column 48dp showing time labels 07h00/08h00... in 11sp gray; main area shows class blocks — Matemática block 60min height #D1FAE5 mint fill emerald left border 4dp, subject name 13sp bold emerald, teacher initials 11sp gray, room '12dp'; Física block blue tint #DBEAFE; Português block amber tint #FEF3C7; blocks have 12dp radius. Break slot 'Intervalo' lighter gray pattern. Empty slot dashed outline gray. MD3 Navigation Bar 'Horário' active. Plus Jakarta Sans, ultra high resolution."

---

## 4.2 Calendário Mensal de Eventos

> **Prompt:**
> "High-fidelity mobile app UI mockup, school calendar screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Calendário' 20sp bold. Month navigator: left arrow, 'Junho 2026' 18sp bold center, right arrow. Month grid calendar: 7-column (Sun–Sat) header 12sp gray, day number cells — today (23) has emerald filled circle 36dp white number; days with events show small colored dot beneath number (emerald for test, amber for event, red for deadline); selected day highlighted mint #D1FAE5. Event list below calendar for selected day 'Seg, 23 Jun': section label 14sp semibold gray. Event cards no border 28dp radius shadow: left colored category bar 4dp (emerald=test, amber=event, red=deadline), event title 14sp bold, time '08h00 – 09h00' 13sp gray, category chip small. Events: 'Teste de Matemática · 08h00', 'Entrega de Ficha de Física · 11h00'. Add event FAB emerald bottom-right. MD3 Navigation Bar. Plus Jakarta Sans, ultra high resolution."

---

## 4.3 Detalhe da Aula

> **Prompt:**
> "High-fidelity mobile app UI mockup, class detail screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Detalhe da Aula' 20sp bold, no elevation. Hero card: no border 28dp radius #F0FDF4 — large subject icon circle 80dp emerald, 'Matemática' 22sp bold dark, 'Prof. António Silva' 15sp gray, 'Sala 12 · Bloco B' 13sp gray, time range '08h00 – 09h30' 14sp bold emerald, duration chip '90 min' filled mint. Status row: 'Aula de Hoje' chip filled emerald if current, 'Próxima Aula' outlined if upcoming. Section 'Conteúdo Previsto': filled card no border #F0FDF4 28dp — 'Trigonometria — Seno e Cosseno' 14sp bold, 'Referência: Livro pág. 142–156' 13sp gray, 'Levar calculadora científica' 13sp amber with warning icon. Section 'Recursos': document chip 'Ficha de Exercícios.pdf' with download icon emerald, image chip 'Diagrama_Trig.png'. Action buttons row: 'Ver Notas' outlined emerald, 'Ver Faltas' outlined gray. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 5 — TAREFAS E TRABALHOS

## 5.1 Lista de Tarefas

> **Prompt:**
> "High-fidelity mobile app UI mockup, tasks and homework screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Tarefas' 20sp bold, filter icon right. Filter chips: 'Todas', 'Pendentes' (active emerald fill), 'Concluídas', 'Em Atraso'. Progress summary card: no border 28dp radius #F0FDF4 — horizontal layout: left circular progress ring 64dp emerald showing 37%, '3/8' 18sp bold center of ring; right: 'concluídas esta semana' 13sp gray, thin progress bar emerald below. Section 'Em Atraso · 1' label with red dot. Overdue task card: no border 28dp radius white shadow, left 4dp red accent bar, subject dot red, title 'Ficha de Física — Capítulo 5' 14sp bold dark, subject 'Física' 12sp gray, 'Entrega: 20 Jun' 12sp red bold with clock icon, 'Em Atraso' red chip right. Section 'Pendentes · 4'. Task cards no border 28dp shadow: checkbox outlined left, subject dot emerald, task title 14sp bold, subject 12sp gray, due date 12sp amber if <3 days, gray if future. Completed tasks: checkbox filled emerald, title strikethrough gray muted. FAB emerald '+' bottom-right. MD3 Navigation Bar. Plus Jakarta Sans, ultra high resolution."

---

## 5.2 Detalhe da Tarefa

> **Prompt:**
> "High-fidelity mobile app UI mockup, task detail screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Detalhe da Tarefa' 20sp bold. Status chip top-right: 'Pendente' amber outlined or 'Concluída' emerald filled. Title card: no border 28dp radius #F0FDF4 — task title 'Ficha de Exercícios — Álgebra' 20sp bold dark, subject row: book icon emerald, 'Matemática · Prof. Silva' 14sp gray, due date row: calendar icon, 'Entregar até 25 Jun · 23h59' 14sp bold — amber if urgent, red if late. Divider. Section 'Descrição': body text 14sp gray 'Resolver os exercícios 1 a 15 das páginas 78–80. Mostrar o desenvolvimento completo das resoluções.'. Section 'Recursos Anexados': file chip 'Ficha_Algebra.pdf' with download icon emerald, tappable. Section 'Submissão': large dashed upload zone card 28dp radius — upload icon gray, 'Toque para adicionar ficheiro' 14sp gray, 'PDF, DOC, imagem · Máx. 10MB' 12sp gray. Uploaded file row: file icon, 'Resolucao_Lucas.pdf · 2.1 MB', remove X icon. Primary button 'Submeter Tarefa' full-width 56dp 28dp radius emerald fill. Plus Jakarta Sans, ultra high resolution."

---

## 5.3 Confirmação de Entrega

> **Prompt:**
> "High-fidelity mobile app UI mockup, task submission success screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Center composition vertically centered. Large success animation frame: circular mint background #F0FDF4 120dp, animated check icon emerald 64dp inside (static frame showing filled checkmark). 'Tarefa Entregue!' 26sp bold dark #111827 below, centered. 'A sua ficha foi enviada com sucesso.' 15sp gray centered. Summary card: no border 28dp radius #F0FDF4 — rows with icon + label + value: book icon 'Disciplina' 'Matemática', calendar icon 'Enviada em' '23 Jun · 14h32', file icon 'Ficheiro' 'Resolucao_Lucas.pdf', clock icon 'Prazo' '25 Jun · 23h59' in emerald. Two buttons: 'Ver Minhas Tarefas' primary emerald full-width 56dp; 'Ir para o Início' secondary outlined emerald full-width 56dp below. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 6 — ASSIDUIDADE

## 6.1 Registo de Presenças

> **Prompt:**
> "High-fidelity mobile app UI mockup, attendance screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Assiduidade' 20sp bold. Subject filter dropdown chip: 'Todas as Disciplinas' with expand arrow, emerald text. Summary row: 3 equal mini stat cards no border 28dp radius mint — 'Presenças' '72' emerald bold; 'Faltas' '8' red bold; 'Taxa' '90%' emerald bold. Month heatmap card: no border 28dp radius white shadow — month label 'Junho 2026', 7-column day grid: each cell 36dp circle — green fill for presente, red fill for falta, amber for falta justificada, gray for no class, white for future. Legend row: colored circles + labels small 11sp. Section 'Registo Detalhado': list rows (divider separated): date left 13sp gray, subject center 13sp bold dark, status chip right — 'Presente' filled mint emerald text, 'Falta' filled red-50 red text, 'Justificada' filled amber-50 amber text. MD3 Navigation Bar. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 7 — COMUNICAÇÃO

## 7.1 Caixa de Mensagens / Comunicados

> **Prompt:**
> "High-fidelity mobile app UI mockup, school messages inbox, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Mensagens' 20sp bold, compose icon top-right emerald. Filter chips: 'Recebidas' (active emerald), 'Enviadas', 'Arquivadas'. Search bar #F0FDF4 no border 12dp radius 'Pesquisar mensagens...'. Message list (MD3 style list tiles, divider separated): each item — avatar circle 44dp with sender initials on colored background; sender name 14sp bold dark, subject line 13sp semibold dark if unread / gray if read, preview snippet 13sp gray 1 line; timestamp 11sp gray top-right; unread badge: emerald dot 8dp top-right of avatar. Unread item has white background bold text; read item has #FAFAFA background. Messages: 'Prof. Silva · Resultado do Teste · Parabéns Lucas! A tua nota...' unread; 'Secretaria · Documentos Prontos · O seu certificado está...' unread; 'Direcção · Reunião de Pais · Convite para reunião...' read. Swipe actions: left swipe = archive gray, right swipe = mark read emerald. FAB compose emerald bottom-right. Plus Jakarta Sans, ultra high resolution."

---

## 7.2 Conversa / Thread de Mensagem

> **Prompt:**
> "High-fidelity mobile app UI mockup, message thread screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top app bar: back arrow, avatar circle 40dp, 'Prof. António Silva' 16sp bold, 'Matemática' 12sp gray, video call icon and phone icon right. Message bubbles in chat style: received messages left — rounded bubble 28dp radius except top-left 4dp, background #F0FDF4 mint, text 14sp dark, timestamp 11sp gray below left; sent messages right — rounded bubble except top-right 4dp, background #10B981 emerald, text white 14sp, timestamp 11sp white-70 below right. Thread: received 'Olá Lucas, queria avisar que os resultados do teste já estão disponíveis no sistema.' → sent 'Obrigado Professor! Já vi, fiquei contente com a nota.' → received 'Continua assim! Para a próxima semana teremos uma ficha sobre trigonometria. Prepara-te bem.' Attachment area: received message with file chip #DBEAFE 'Ficha_Trigonometria.pdf' download icon. Bottom input bar: #F0FDF4 no border 28dp radius input field 'Escreva uma mensagem...' 14sp gray, attach icon left, send button emerald circle right. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 8 — PAGAMENTOS E PROPINAS

## 8.1 Estado das Propinas

> **Prompt:**
> "High-fidelity mobile app UI mockup, school fees payment screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Propinas' 20sp bold, receipt icon right emerald. Balance hero card: no border 28dp radius #F0FDF4 — 'Situação Atual' 14sp gray, 'Em Dia' 28sp bold emerald with checkmark circle icon, below: 'Próximo pagamento: Julho 2026' 13sp gray, 'Valor: 1.500,00 MT' 16sp bold dark. Payment status list — month rows no border 28dp radius white shadow: month name 15sp bold left, amount 14sp bold right, status chip — 'Pago' filled mint emerald text, 'Pendente' outlined amber, 'Em Atraso' filled red-50 red text. Months: Jun ✓ Pago, Mai ✓ Pago, Abr ✓ Pago, Mar ✓ Pago, Fev — Pendente amber. Section 'Pagamento Pendente': highlighted card amber tint no border 28dp — 'Fevereiro 2026 · 1.500,00 MT', 'Vence em 3 dias' amber bold, 'Pagar Agora' emerald button inside card. Primary button 'Ver Histórico Completo' outlined emerald full-width. Plus Jakarta Sans, ultra high resolution."

---

## 8.2 Histórico de Pagamentos

> **Prompt:**
> "High-fidelity mobile app UI mockup, payment history screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Histórico de Pagamentos' 20sp bold, filter icon. Year selector: '2026' active emerald chip, '2025' outlined. Summary card: no border 28dp radius #F0FDF4 — 'Total Pago em 2026' 13sp gray, '9.000,00 MT' 32sp bold dark, '6 de 10 meses pagos' 13sp gray, horizontal progress bar emerald 60%. Payment list grouped by month: month section header 14sp semibold gray 'Junho 2026'. Transaction row: receipt icon circle 44dp mint fill emerald icon, 'Propina — Junho' 14sp bold, 'Pago via M-Pesa' 12sp gray, date '05 Jun 2026' 11sp gray left; amount '1.500,00 MT' 14sp bold dark right, emerald checkmark icon. Each month shows one row. Download receipt: each row has download icon right gray tappable. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 9 — DOCUMENTOS

## 9.1 Centro de Documentos

> **Prompt:**
> "High-fidelity mobile app UI mockup, documents center screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Documentos' 20sp bold, search icon right. Horizontal scroll categories chips row: 'Todos' (active emerald fill), 'Certificados', 'Boletins', 'Declarações', 'Formulários'. Section 'Disponíveis para Download' 14sp semibold gray. Document cards no border 28dp radius white shadow elevation 1: left 56dp square file icon container #F0FDF4 with PDF/DOC icon in emerald; right: document name 14sp bold dark, type chip 'PDF' small mint, date 'Emitido: 15 Jun 2026' 12sp gray; download button 'Baixar' small outlined emerald right. Cards: 'Boletim 1º Trimestre 2026', 'Declaração de Matrícula', 'Certificado de Frequência'. Section 'Solicitar Documento': text 'Precisa de outro documento?' 14sp gray, 'Fazer Pedido' outlined button emerald. Section 'Pedidos em Andamento': status card — document name, 'Em processamento' chip amber, 'Prazo: 3 dias úteis' 12sp gray. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 10 — PERFIL

## 10.1 Perfil do Aluno

> **Prompt:**
> "High-fidelity mobile app UI mockup, student profile screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Perfil' 20sp bold, settings icon top-right. Profile hero: avatar circle 96dp emerald ring border 3dp, camera badge small circle bottom-right gray, 'Lucas Machava' 22sp bold dark, '10ª Classe · Turma A' 14sp gray, 'Nº 12345' 12sp gray, 'Editar Perfil' small outlined emerald chip. Achievement row: 3 equal mini cards no border 28dp radius mint — '90%' Assiduidade label, '15.7' Média label, '4' Medalhas label — each with small icon above value, emerald/amber icons. Section 'Informações Pessoais': list card no border 28dp radius white shadow — rows with icon + label + value: person icon 'BI' '123456789A', cake icon 'Nascimento' '15 Jan 2010', phone icon 'Contacto' '+258 84 000 0000', mail icon 'Email' 'l***@gmail.com', shield icon 'Encarregado' 'Maria Machava'. Section 'Configurações': toggle rows — 'Notificações Push' emerald switch ON, 'Emails de Aviso' switch OFF; nav rows — 'Idioma' 'Português', 'Sobre o App', 'Política de Privacidade'. 'Terminar Sessão' red text button centered bottom. MD3 Navigation Bar Perfil active. Plus Jakarta Sans, ultra high resolution."

---

## 10.2 Editar Perfil

> **Prompt:**
> "High-fidelity mobile app UI mockup, edit profile screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Editar Perfil' 20sp bold, 'Guardar' emerald text button right. Avatar section: avatar circle 96dp, emerald ring, 'Alterar Foto' emerald text link below. Form section: MD3 Filled TextField style (no border, 12dp radius, #F0FDF4 background, emerald underline focus): fields — 'Nome Completo' (read-only grayed), 'Número de Estudante' (read-only), 'Email' value editable, 'Telefone' value editable, 'Endereço' value editable. Section 'Segurança': 'Alterar Senha' nav row — lock icon, text, arrow right; 'Alterar PIN' nav row — keypad icon, text, arrow right. Section 'Notificações': toggle rows with sub-label — 'Novas Notas' emerald switch on, sub '14sp gray Receber alerta quando nota for lançada'; 'Lembretes de Aulas' switch on; 'Comunicados da Escola' switch on; 'Mensagens' switch on. Primary button 'Guardar Alterações' full-width 56dp emerald fill fixed bottom above nav. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 11 — PORTAL DO PROFESSOR

## 11.1 Dashboard do Professor

> **Prompt:**
> "High-fidelity mobile app UI mockup, teacher dashboard screen, E258Tech school app TEACHER mode. 9:16 aspect ratio, white background, borderless MD3. Status bar dark. Top: 'Olá, Prof. Silva!' 24sp bold dark, 'António Silva · Matemática e Física' 13sp gray, avatar circle 44dp right emerald ring. Quick stats row horizontal scroll: cards no border 28dp radius mint — '6' Turmas, '142' Alunos, '3' Tarefas Pendentes, '12' Notas por Lançar — each with icon and label. Section 'Aulas de Hoje' 16sp semibold. Class cards (2) no border 28dp radius white shadow: left time column emerald '08h00–09h30', center — 'Matemática · 10ª A' bold, 'Sala 12' gray, '28 alunos' gray, right action chip 'Marcar Presenças' small emerald outlined. Section 'Pendências': list item 'Notas do Teste 2 — Física 11ª B' with amber dot, 'Entregar até amanhã' 12sp amber. Bottom nav: Home (active), Turmas, Notas, Mensagens. Plus Jakarta Sans, ultra high resolution."

---

## 11.2 Lançar Notas — Seleção de Turma

> **Prompt:**
> "High-fidelity mobile app UI mockup, teacher grade entry - class selection, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Lançar Notas' 20sp bold. Step indicator: 3 steps — '1 Turma' (filled emerald circle '1'), '2 Avaliação', '3 Notas' — connected by lines, inactive steps gray. Section 'Selecione a Turma': class cards grid 2 columns — each card no border 28dp radius #F0FDF4 shadow: class name '10ª Classe A' 18sp bold emerald, subject 'Matemática' 14sp gray, '28 alunos' 12sp gray, arrow right icon. Cards: 10ª A Matemática, 10ª B Matemática, 11ª A Física, 11ª B Física. Selected card shows emerald border 2dp and checkmark top-right. Primary button 'Próximo' full-width 56dp emerald fill, disabled gray until selection. Plus Jakarta Sans, ultra high resolution."

---

## 11.3 Lançar Notas — Lista de Alunos

> **Prompt:**
> "High-fidelity mobile app UI mockup, teacher grade entry for students list, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Notas · 10ª A · Matemática' 18sp bold. Context chip row: 'Teste 2 · Trimestre 1' chip mint, 'Nota máx: 20' chip gray, 'Lançadas: 18/28' chip emerald. Search bar #F0FDF4 no border 'Pesquisar aluno...'. Students list — each row card (no border 28dp radius white shadow): left avatar circle 40dp with initials colored background, student name 14sp bold dark, student number 12sp gray; right side: MD3 Outlined TextField compact 64dp wide 44dp tall 8dp radius — number input value '17' emerald text if entered, placeholder '—' gray if empty, emerald underline. Quick-fill buttons: 'Preencher em Massa' text button top-right emerald. Status: rows with value entered show small emerald check right of input; pending show amber dot. Sticky bottom bar: 'Guardar Rascunho' outlined gray left, 'Publicar Notas' filled emerald right — both 48dp. Plus Jakarta Sans, ultra high resolution."

---

## 11.4 Marcar Presenças

> **Prompt:**
> "High-fidelity mobile app UI mockup, teacher attendance marking screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Marcar Presenças' 20sp bold. Context card: no border 28dp radius #F0FDF4 — 'Matemática · 10ª Classe A' 16sp bold, 'Seg 23 Jun · 08h00–09h30' 13sp gray, 'Sala 12' 12sp gray. Status summary chips row: 'Presentes: 24' emerald chip, 'Faltas: 3' red chip, 'Pendentes: 1' gray chip. Bulk action row: 'Marcar Todos Presentes' emerald text button left, 'Repor' gray text button right. Students list — each row (divider separated): avatar circle 40dp initials, student name 14sp bold dark, number 12sp gray; right: 3-button segmented control 100dp — 'P' (Presente) selected green, 'F' (Falta) red, 'J' (Justificada) amber — active button filled colored, inactive outlined gray. Buttons 36dp height each. Row with 'F' selected shows red tint on card background. Sticky bottom: 'Guardar Presenças' full-width 56dp emerald fill. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 12 — PORTAL DO ENCARREGADO

## 12.1 Dashboard do Encarregado

> **Prompt:**
> "High-fidelity mobile app UI mockup, parent/guardian dashboard, E258Tech school app PARENT mode. 9:16 aspect ratio, white background, borderless MD3. Top: 'Olá, Sra. Maria!' 24sp bold dark, 'Encarregada de Educação' 13sp gray, avatar right. Child selector card: no border 28dp radius #F0FDF4 — 'A acompanhar:' 12sp gray, horizontal scroll of child chips: 'Lucas · 10ª A' filled emerald, 'Ana · 8ª B' outlined gray. Stats row for selected child: cards mint no border — 'Média: 15.7' emerald, 'Faltas: 8' amber, 'Propinas: Em Dia' emerald. Section 'Últimas Notas de Lucas': 3 subject rows — subject name, grade value, date, color indicator. Section 'Avisos Escolares': notification cards with school icon, message preview, date. Section 'Próxima Reunião': highlighted card amber tint — 'Reunião de Pais · Sex 27 Jun · 14h00', 'Confirmar Presença' button emerald inside card. Bottom nav: Home, Notas, Mensagens, Perfil — parent role. Plus Jakarta Sans, ultra high resolution."

---

# ESTADOS ESPECIAIS

## E.1 Estado Vazio (Empty State)

> **Prompt:**
> "High-fidelity mobile app UI mockup, empty state screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Vertically centered composition. Large flat illustration in center: simple line art of open book or magnifying glass, emerald and mint tones, on mint circle background 140dp. Below: 'Ainda sem Tarefas' 22sp bold dark #111827 centered. Subtitle: 'As suas tarefas e trabalhos de casa aparecerão aqui quando forem atribuídos.' 15sp gray #6B7280 centered 3-line max. Optional CTA button 'Explorar Horário' outlined emerald 56dp 28dp radius centered. Rest of screen is clean white space. Same MD3 Navigation Bar at bottom. Plus Jakarta Sans, ultra high resolution, calming and clear empty state design."

---

## E.2 Estado de Carregamento (Loading State)

> **Prompt:**
> "High-fidelity mobile app UI mockup, skeleton loading state screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Header area: gray placeholder rectangle 200dp wide 28dp tall 14dp radius for title (shimmer effect). Below: horizontal row of 3 skeleton stat cards 28dp radius gray animated. Section label skeleton 100dp wide 14dp tall. Three skeleton list cards 28dp radius — each card: left circle 44dp gray, right side 2 stacked rectangles gray 14dp and 10dp radius. Skeleton elements use animated gradient from #F3F4F6 to #E5E7EB to #F3F4F6 (shimmer). All content placeholders are neutral grays, no text visible. MD3 Navigation Bar visible normally at bottom. Clean loading skeleton, no spinners. Plus Jakarta Sans, ultra high resolution."

---

## E.3 Estado de Erro de Ligação

> **Prompt:**
> "High-fidelity mobile app UI mockup, network error screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top app bar visible with back arrow. Vertically centered composition. Large flat illustration: wifi symbol with X mark, or broken cable, emerald and gray tones, on mint circle 140dp. 'Sem Ligação à Internet' 22sp bold dark centered. Subtitle: 'Verifique a sua ligação de dados ou WiFi e tente novamente.' 15sp gray centered 2-line max. Error code: 'ERR_NETWORK_UNAVAILABLE' 11sp gray monospace centered. Primary button 'Tentar Novamente' full-width 56dp 28dp radius emerald fill centered. Secondary text button 'Trabalhar Offline' emerald text below — smaller, gray background data shown. MD3 Navigation Bar bottom. Plus Jakarta Sans, ultra high resolution."

---

## E.4 Erro de Formulário / Validação

> **Prompt:**
> "High-fidelity mobile app UI mockup, form validation error state, E258Tech school login screen with errors, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Login form layout. Error snackbar at top: red background #EF4444, white text 'Credenciais inválidas. Verifique e tente novamente.' 14sp, white X close icon right — 56dp height 8dp radius. Input field 'Número de Estudante': MD3 Outlined TextField in ERROR state — red border 2dp, label 'Número de Estudante' in red above field, field value '9999' in dark text, error helper text below 'Número de estudante não encontrado' 12sp red with error icon left. Input field 'Senha': red border, helper text 'Senha incorreta. X tentativas restantes: 2' 12sp red. 'Esqueceu a senha?' link emerald. Primary button 'Entrar' still visible but disabled gray. Same overall layout as login. Plus Jakarta Sans, ultra high resolution."

---

## E.5 Ecrã de Sucesso / Confirmação

> **Prompt:**
> "High-fidelity mobile app UI mockup, success confirmation screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Full-screen celebration layout. Top 40%: mint gradient #F0FDF4 to white. Large animated success checkmark: outer circle 120dp mint stroke, inner circle 96dp emerald fill, white checkmark icon 48dp bold centered. Confetti illustration: small colored dots and stars scattered around the checkmark in emerald, amber and blue tones. Title: 'Concluído com Sucesso!' 26sp bold dark #111827 centered. Subtitle: 'A sua nota foi lançada e os alunos foram notificados.' 15sp gray centered 2-line max. Summary card: no border 28dp radius #F0FDF4 — rows: 'Disciplina · Matemática 10ª A', 'Avaliação · Teste 2', 'Notas publicadas · 28 alunos', 'Data · 23 Jun · 14h32'. Two buttons: 'Lançar Mais Notas' outlined emerald full-width, 'Ir ao Dashboard' filled emerald full-width. Plus Jakarta Sans, ultra high resolution."

---

## 2.4 Menu "Mais" — Acesso Rápido Expandido

> **Prompt:**
> "High-fidelity mobile app UI mockup, bottom sheet 'More' menu, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Main screen is dimmed 50% dark overlay. Bottom sheet rises from bottom — white 28dp top radius only, drag handle 40dp wide 4dp tall gray centered top. Sheet title 'Mais Opções' 16sp semibold dark. 2-column icon grid of menu items: each item is a rounded square 80dp #F0FDF4 no border, centered icon 28dp emerald, label below 12sp dark. Items: 'Assiduidade' calendar-check icon, 'Pagamentos' credit-card icon, 'Documentos' file icon, 'Comunicados' megaphone icon, 'Ranking' trophy icon, 'Medalhas' medal icon, 'Ajuda' help-circle icon, 'Configurações' settings icon. Tapping outside sheet dismisses. MD3 Navigation Bar still visible at bottom below sheet. Plus Jakarta Sans, ultra high resolution."

---

## 2.5 Medalhas e Conquistas

> **Prompt:**
> "High-fidelity mobile app UI mockup, achievements and badges screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Medalhas e Conquistas' 20sp bold. Hero card: no border 28dp radius #F0FDF4 — trophy icon 48dp emerald, 'Lucas tem 4 Medalhas' 18sp bold dark, XP bar label 'Nível 7 · 740/1000 XP' 13sp gray, thick emerald horizontal progress bar 74%. Filter chips: 'Todas' (active emerald), 'Conquistadas', 'Bloqueadas'. Medals grid 3 columns: each medal item — circle 72dp: earned medals show colored icon (emerald/gold/amber) filled circle, locked medals show gray circle with lock icon; medal name below 12sp dark bold if earned, gray if locked; XP value '50 XP' 11sp emerald below name. Earned: 'Primeiro Acesso' emerald, 'Nota Máxima' gold star, 'Sem Faltas' amber, '10 Dias Seguidos' emerald. Locked (grayed): 'Média 18+', 'Turma Top 3', 'Livro Completo'. Plus Jakarta Sans, ultra high resolution."

---

## 2.6 Ranking da Turma

> **Prompt:**
> "High-fidelity mobile app UI mockup, class ranking screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Ranking · 10ª Classe A' 20sp bold. Period chips: 'Este Trimestre' (active emerald), 'Geral'. Podium section top 3: center position 1 — avatar circle 64dp emerald ring, name '2 lines bold', '18.2' emerald bold below; left position 2 — avatar 52dp smaller, elevated platform, name, '17.8'; right position 3 — avatar 48dp, name, '17.1'. Platform shapes: 1st tallest emerald, 2nd silver gray, 3rd amber. Below podium: ranking list from position 4 onwards — each row: position number 16sp bold emerald left 32dp, avatar circle 40dp, name 14sp bold, class average 14sp bold right, small trend arrow up/down colored. Highlighted row for current user 'Lucas · #7 · 15.7' with mint #D1FAE5 background. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 3 — NOTAS (ADICIONAL)

## 3.5 Gráfico de Evolução de Notas

> **Prompt:**
> "High-fidelity mobile app UI mockup, grade evolution chart screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Evolução de Notas' 20sp bold, filter icon right. Period chips: 'Trimestre 1' (active emerald), 'Trimestre 2', 'Ano'. Subject filter dropdown: 'Todas as Disciplinas' chip emerald with expand arrow. Main chart card: no border 28dp radius white shadow elevation 2 — line chart 280dp height: X-axis shows evaluation dates (Teste 1/Ficha/Teste 2), Y-axis shows grades 0-20; emerald smooth line connecting grade points with filled circles at each point 8dp; hover point shows tooltip 'Teste 2 · 17 valores · 28 Mar' in dark card above point; grid lines light gray dashed horizontal. Below chart: summary cards row 3 equal mint cards — 'Melhor Nota' '18' emerald, 'Média' '15.7' dark, 'Tendência' '↑ +1.3' emerald with up arrow. Subject comparison: horizontal bars for each subject showing average grade, emerald fill, subject label left 13sp, grade value right 13sp bold. Plus Jakarta Sans, ultra high resolution."

---

## 3.6 Detalhe da Avaliação Individual

> **Prompt:**
> "High-fidelity mobile app UI mockup, individual assessment detail screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Teste 2 — Matemática' 18sp bold. Status hero card: no border 28dp radius #F0FDF4 — grade value '17' 56sp bold emerald center, '/ 20 valores' 16sp gray below, 'Aprovado' chip emerald below that, 'Acima da média da turma' 13sp gray. Stats row: 3 equal mint cards — 'Posição' '4º' dark bold, 'Média Turma' '13.8' gray, 'Mais Alta' '19' emerald. Section 'Detalhes da Avaliação': info rows (divider separated, no card): calendar icon 'Data' '15 de Março de 2026', tag icon 'Tipo' 'Teste Escrito', book icon 'Matéria' 'Trigonometria – Cap. 8', percent icon 'Peso' '40% da média trimestral'. Section 'Comentário do Professor': text card #F0FDF4 no border 28dp radius — quote icon emerald top-left, italic text 14sp gray 'Excelente resolução! Continue a praticar os exercícios de geometria.', teacher name 12sp bold emerald right. Download chip 'Ver Ficha Corrigida · PDF' emerald outlined. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 4 — HORÁRIO (ADICIONAL)

## 4.4 Vista Diária do Horário

> **Prompt:**
> "High-fidelity mobile app UI mockup, daily schedule list view, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: 'Hoje — Segunda, 23 Jun' 18sp bold, view toggle icons (grid/list) top-right. Date strip: horizontal 5-day row pills Mon–Fri, 'Seg' active emerald. Below: vertical timeline list of today's classes. Each class item: left time column 48dp — start time 13sp bold dark, end time 11sp gray; center card (no border 20dp radius shadow): left 4dp colored bar (emerald=Matemática, blue=Física, amber=Português), subject name 15sp bold, teacher 12sp gray, room 'Sala 12' 11sp gray with door icon, right status chip: 'Agora' filled emerald if current class, 'Concluída' filled gray if past, 'Em breve' outlined amber if next. Break slots: dashed card 'Intervalo · 10min' amber text centered. Free period: dotted card 'Hora Livre' gray. Bottom 'Próxima Aula daqui a 45 min — Física' banner strip emerald at bottom above nav bar. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 6 — ASSIDUIDADE (ADICIONAL)

## 6.2 Justificar Falta

> **Prompt:**
> "High-fidelity mobile app UI mockup, justify absence form screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Justificar Falta' 20sp bold. Context card: no border 28dp radius #F0FDF4 — 'Falta em Matemática' 16sp bold dark, 'Segunda-feira, 20 Jun · 08h00–09h30' 13sp gray, 'Prof. António Silva' 12sp gray. Form section: MD3 Filled TextField style — 'Motivo da Falta' dropdown field (select: Doença / Consulta Médica / Assunto Familiar / Outro), text area 'Descrição (opcional)' 120dp tall #F0FDF4 no border 12dp radius. Section 'Documento Comprovativo': dashed upload zone 28dp radius — document icon gray, 'Adicionar comprovativo (opcional)' 14sp gray, 'PDF, imagem · Máx. 5MB' 12sp gray; if uploaded shows file row with remove option. Section 'Período': date range row 'De: 20 Jun' and 'Até: 20 Jun' with calendar chips emerald tappable. Primary button 'Submeter Justificação' full-width 56dp emerald. Note text 'A justificação será analisada pela secretaria em 1-2 dias úteis.' 12sp gray centered. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 7 — COMUNICAÇÃO (ADICIONAL)

## 7.3 Nova Mensagem — Compose

> **Prompt:**
> "High-fidelity mobile app UI mockup, compose new message screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: X close icon left, 'Nova Mensagem' 20sp bold center, 'Enviar' emerald text button right (grayed until form filled). To field: MD3 Filled TextField 'Para:' — inside shows recipient chip 'Prof. António Silva' filled emerald with X remove, cursor blinking after chip; below field: horizontal scroll suggestion chips of recent contacts: 'Prof. Silva', 'Secretaria', 'Direcção'. Subject field: 'Assunto:' filled text field placeholder 'Escreva o assunto...'. Divider line. Main compose area: large text input no border 'Escreva a sua mensagem...' 15sp gray, minimum 200dp height, cursor top-left. Bottom toolbar: attach icon, image icon, emerald send FAB right. Attachment added row: file icon, 'Documento.pdf · 1.2 MB', X remove. Keyboard visible bottom half simulated. Plus Jakarta Sans, ultra high resolution."

---

## 7.4 Detalhe de Comunicado Oficial

> **Prompt:**
> "High-fidelity mobile app UI mockup, official school announcement detail, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, share icon right. Header card: no border 28dp radius #F0FDF4 — category chip 'Aviso Oficial' filled emerald top-left; megaphone icon circle 56dp emerald; title 'Reunião Geral de Pais e Encarregados' 20sp bold dark; sender row: Nexora School logo icon 32dp emerald green circle — stylized bold letter "N" with rounded corners, long flat shadow, right stem negative-space cutout of Mozambique map silhouette, small emerald pixels floating above top-right. 'Direcção da Escola · E258Tech' 13sp bold, date '20 Jun 2026 · 14h32' 11sp gray. Priority badge: 'URGENTE' filled red chip if urgent. Body text section: 14sp gray 1.5 line-height, full announcement text — 'Convocam-se todos os encarregados de educação para a Reunião Geral do 2º Trimestre a realizar-se na Sexta-feira, dia 27 de Junho de 2026, pelas 14h00, no Auditório da escola...'. Section 'Detalhes': info rows — calendar 'Data' '27 Jun · 14h00', map-pin 'Local' 'Auditório Principal', users 'Destinatários' 'Todos os Encarregados'. Action buttons: 'Confirmar Presença' filled emerald, 'Adicionar ao Calendário' outlined emerald. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 8 — PAGAMENTOS (ADICIONAL)

## 8.3 Processo de Pagamento — M-Pesa

> **Prompt:**
> "High-fidelity mobile app UI mockup, M-Pesa payment process screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Pagar Propina' 20sp bold. Step indicator: 3 steps — '1 Valor' (filled emerald), '2 Confirmação', '3 Conclusão' — with connecting lines. Payment summary card: no border 28dp radius #F0FDF4 — 'Propina — Fevereiro 2026' 16sp bold dark, 'Valor a pagar' 13sp gray, '1.500,00 MT' 32sp bold dark. Payment method section: 'Método de Pagamento' 14sp semibold. Method cards (selectable, one selected): M-Pesa card — emerald border selected, M-Pesa logo icon left, 'M-Pesa' 14sp bold, '+258 84 000 0000' 12sp gray, checkmark emerald right; e-Mola card — outlined gray unselected, e-Mola icon, 'e-Mola' 14sp, '+258 86 000 0000' 12sp gray. M-Pesa phone field: 'Número M-Pesa' MD3 outlined field prefilled '+258 84 000 0000' emerald. Note: 'Receberá um PIN de confirmação no seu telemóvel M-Pesa.' 12sp gray italic. Primary button 'Confirmar Pagamento · 1.500 MT' full-width 56dp 28dp radius emerald. Plus Jakarta Sans, ultra high resolution."

---

## 8.4 Recibo de Pagamento

> **Prompt:**
> "High-fidelity mobile app UI mockup, payment receipt screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: X close, 'Recibo de Pagamento' 20sp bold, share icon right. Top area mint gradient #F0FDF4 to white 30% height. Center: checkmark circle 80dp emerald fill, white checkmark 40dp. 'Pagamento Confirmado' 24sp bold dark. Amount '1.500,00 MT' 32sp bold emerald. Receipt card: no border 28dp radius white shadow elevation 2 — dashed top edge zig-zag style (receipt tear effect), rows with label left gray and value right bold dark: 'Referência' 'TXN-2026-06234', 'Data' '23 Jun 2026 · 14h48', 'Método' 'M-Pesa', 'Número' '+258 84 000 0000', 'Propina' 'Fevereiro 2026', 'Escola' 'E258Tech Escola', 'Estado' 'PAGO' bold emerald. Dashed bottom edge. Two buttons: 'Baixar Recibo PDF' outlined emerald full-width 56dp; 'Ir ao Início' filled emerald full-width 56dp. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 9 — DOCUMENTOS (ADICIONAL)

## 9.2 Formulário de Pedido de Documento

> **Prompt:**
> "High-fidelity mobile app UI mockup, document request form screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Solicitar Documento' 20sp bold. Document type selector: 3 selectable cards in vertical list (no border 28dp radius shadow): each card has icon circle 48dp mint+emerald, document name 15sp bold, description 13sp gray, 'Prazo: 3 dias úteis' 12sp gray; selected card has emerald border 2dp and checkmark top-right. Cards: 'Declaração de Matrícula' / document icon, 'Certidão de Frequência' / certificate icon, 'Histórico Escolar' / list icon. Below: 'Propósito do Pedido' dropdown MD3 outlined — options: Emprego, Bolsa, Outro. 'Observações' text area optional. Processing fee note: info card mint #F0FDF4 — info icon emerald, 'Este documento é gratuito. Prazo de emissão: 3 dias úteis.' 13sp dark. Primary button 'Submeter Pedido' full-width 56dp emerald. Plus Jakarta Sans, ultra high resolution."

---

## 9.3 Visualizador de PDF

> **Prompt:**
> "High-fidelity mobile app UI mockup, in-app PDF viewer screen, E258Tech school app. 9:16 aspect ratio, dark/white split design, borderless MD3. Top app bar: dark gray #1F2937 background — back arrow white, 'Boletim 1º Trimestre.pdf' 16sp bold white, share icon white, download icon white. PDF content area: white background, rendered PDF page with school header containing the Nexora School logo icon — stylized bold letter "N" in emerald green with rounded corners, long flat shadow, right stem negative-space cutout of Mozambique map silhouette, small emerald pixels floating above — alongside 'E258Tech Escola' wordmark, student name, grade table — realistic document appearance, crisp text. Bottom toolbar: dark gray — left: page indicator '1 / 3' white 13sp; center: zoom out icon white, zoom percentage '100%' white, zoom in icon white; right: fullscreen icon white. Top of PDF shows school letterhead. Page shows as scrollable with shadow edge. Pinch zoom indication. Search-in-doc icon in toolbar. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 10 — PERFIL (ADICIONAL)

## 10.3 Configurações — Menu Principal

> **Prompt:**
> "High-fidelity mobile app UI mockup, settings main menu screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Configurações' 20sp bold. User summary card: no border 28dp radius #F0FDF4 — avatar 56dp emerald ring, 'Lucas Machava' 16sp bold, '10ª Classe A · Nº 12345' 13sp gray, 'Ver Perfil →' emerald text link. Settings sections as grouped list cards (no border 28dp radius shadow): Section 'Conta' — rows with icon + label + arrow: person 'Informações Pessoais', lock 'Segurança e Senha', fingerprint 'Biometria e PIN', bell 'Notificações'. Section 'Aparência' — paint 'Tema' value 'Claro', globe 'Idioma' value 'Português', text-size 'Tamanho do Texto', accessibility 'Acessibilidade'. Section 'Privacidade' — shield 'Política de Privacidade', eye 'Gerir Dados', trash 'Eliminar Conta'. Section 'Suporte' — help 'Ajuda e FAQ', message-circle 'Contactar Suporte', star 'Avaliar App'. Version '2.1.0' centered gray 12sp bottom. Plus Jakarta Sans, ultra high resolution."

---

## 10.4 Alterar Senha

> **Prompt:**
> "High-fidelity mobile app UI mockup, change password screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Alterar Senha' 20sp bold. Security illustration: flat shield with lock icon, emerald tones, mint container 100dp centered top. Info text: 'A sua nova senha deve ter pelo menos 8 caracteres, incluir letras e números.' 14sp gray centered. Form fields: MD3 Outlined TextField 56dp 12dp radius emerald focus border: 'Senha Atual' with lock icon, eye toggle; 'Nova Senha' with lock icon, eye toggle; 'Confirmar Nova Senha' with lock icon, eye toggle. Password strength indicator below 'Nova Senha' field: horizontal bar — 4 segments: red (Fraca), orange, amber, emerald (Forte) — first 2 filled amber showing 'Média' strength label 12sp amber right. Requirements checklist: small rows with check/x icons — '✓ 8+ caracteres' emerald, '✓ Letras e números' emerald, '✗ Símbolo especial' gray. Primary button 'Atualizar Senha' full-width 56dp emerald fill. Plus Jakarta Sans, ultra high resolution."

---

## 10.5 Biometria e PIN

> **Prompt:**
> "High-fidelity mobile app UI mockup, biometric and PIN security screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Biometria e PIN' 20sp bold. Biometrics card: no border 28dp radius white shadow — fingerprint icon 48dp emerald center, 'Impressão Digital' 16sp bold dark, 'Entre sem digitar a senha' 13sp gray, large MD3 Switch toggle emerald ON to the right of row. Below: Face ID row similarly — face-scan icon, 'Face ID / Reconhecimento Facial' 15sp bold, switch emerald. Section 'PIN de Acesso Rápido': card no border 28dp radius shadow — keypad icon emerald, 'PIN Ativo · 4 dígitos' 15sp bold, 'Alterado há 30 dias' 12sp gray; 'Alterar PIN' text link emerald right. Section 'Sessão': timeout setting row 'Bloquear após' value 'Inatividade de 5 min' with chevron; 'Pedir confirmação em pagamentos' toggle ON emerald. Info banner #F0FDF4 mint — shield icon, 'A biometria é processada localmente e nunca enviada a servidores.' 12sp dark. Plus Jakarta Sans, ultra high resolution."

---

## 10.6 Idioma e Acessibilidade

> **Prompt:**
> "High-fidelity mobile app UI mockup, language and accessibility settings, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Idioma e Acessibilidade' 20sp bold. Section 'Idioma': language selection list in card no border 28dp radius shadow — each row: flag emoji, language name 14sp bold dark, region 13sp gray; selected language 'Português (Moçambique)' has emerald radio button filled right. Other options: 'English (UK)' gray radio, 'Português (Portugal)' gray. Section 'Tamanho do Texto': slider card — sample text preview 'Texto de Exemplo' showing live size change; MD3 slider with emerald thumb and track from A-small left to A-large right, current value at 'Médio'. Section 'Acessibilidade': toggle rows — 'Contraste Elevado' switch OFF, 'Reduzir Animações' switch OFF, 'Texto em Negrito' switch ON emerald, 'Leitor de Ecrã' switch OFF. Apply button 'Aplicar Alterações' full-width 56dp emerald bottom. Plus Jakarta Sans, ultra high resolution."

---

## 10.7 Sobre o App

> **Prompt:**
> "High-fidelity mobile app UI mockup, about app screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Sobre' 20sp bold. Center hero: Nexora School logo icon 80dp emerald green — stylized bold letter "N" with rounded corners and long flat shadow, right stem with negative-space cutout of Mozambique country silhouette, small emerald rounded squares floating above top-right like pixels. 'E258Tech' 28sp bold dark, 'Sistema Escolar Digital' 15sp gray, version badge chip 'v 2.1.0 · Build 210' filled mint emerald text. Divider. Info list card no border 28dp radius shadow: rows — code icon 'Versão' '2.1.0', calendar icon 'Última Atualização' '23 Jun 2026', globe icon 'Website' 'e258tech.co.mz' emerald link, mail icon 'Email' 'suporte@e258tech.co.mz' emerald link. Section 'Legal': nav rows — 'Termos de Uso', 'Política de Privacidade', 'Licenças de Software'. Section 'Equipa': card #F0FDF4 no border — 'Desenvolvido por E258Tech' 14sp bold center, '🇲🇿 Feito em Moçambique' 13sp gray center, small flag illustration. 'Avaliar o App' FAB-style chip emerald centered bottom with star icon. Plus Jakarta Sans, ultra high resolution."

---

## 10.8 Ajuda — Perguntas Frequentes

> **Prompt:**
> "High-fidelity mobile app UI mockup, help FAQ screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Ajuda e Suporte' 20sp bold. Search bar: #F0FDF4 no border 12dp radius 'Pesquisar na ajuda...' with search icon. Quick contact strip: 2 chips — 'Chat em Direto' emerald filled with message icon, 'Enviar Email' outlined emerald. Section 'Perguntas Frequentes' 14sp semibold gray. FAQ accordion list (no border 28dp radius shadow card wrapping all): each FAQ item — question text 14sp bold dark left, expand/collapse chevron right; expanded item shows answer text 13sp gray 1.5 line-height below with separator. FAQs: 'Como recuperar a minha senha?' (expanded, showing answer), 'Onde vejo o meu número de estudante?', 'Como justificar uma falta?', 'Posso pagar propinas pelo app?', 'Como descarregar o boletim?'. Section 'Contactar Suporte': card #F0FDF4 — phone icon, 'Linha de Apoio: +258 21 000 000' 14sp bold, 'Seg–Sex · 08h00–16h00' 12sp gray. Plus Jakarta Sans, ultra high resolution."

---

## 10.9 Reportar Problema / Feedback

> **Prompt:**
> "High-fidelity mobile app UI mockup, report problem / feedback screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Reportar Problema' 20sp bold. Problem type selector: label '1. Tipo de Problema' 14sp semibold. 4 selectable chips in 2-row grid: 'Erro Técnico' outlined, 'Nota Incorreta' outlined, 'Sugestão' outlined, 'Outro' outlined — one selected shows filled emerald. Severity field: '2. Gravidade' — 3 outlined chips: 'Urgente' red, 'Normal' amber, 'Baixo' gray — one selected. Text area: '3. Descrição' label, large MD3 Filled text area #F0FDF4 no border 12dp radius 'Descreva o problema em detalhe...' 120dp tall, character count '0 / 500' bottom-right gray. Screenshot option: dashed zone 28dp — camera icon, 'Adicionar captura de ecrã (opcional)' 13sp gray; if added shows thumbnail preview with X. System info row auto-included: info icon, 'Versão 2.1.0 · Android 14 · 10ª A' 12sp gray. Primary button 'Enviar Relatório' full-width 56dp emerald. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 11 — PORTAL DO PROFESSOR (ADICIONAL)

## 11.5 Lista de Turmas do Professor

> **Prompt:**
> "High-fidelity mobile app UI mockup, teacher classes list screen, E258Tech school app TEACHER mode. 9:16 aspect ratio, white background, borderless MD3. Top: 'Minhas Turmas' 20sp bold. Search bar #F0FDF4 'Pesquisar turmas...'. Filter chips: 'Todas' (active emerald), 'Manhã', 'Tarde'. Turma cards (no border 28dp radius white shadow): header colored band 60dp tall with class name '10ª Classe A' 20sp bold white, subject 'Matemática' 14sp white on emerald gradient; below band: stats row — person icon '28 alunos', check icon '90% Assiduidade', star icon 'Média: 13.8'; action row: 'Ver Alunos' chip outlined, 'Lançar Notas' chip emerald filled, 'Marcar Presenças' chip outlined. Cards: 10ª A Matemática (emerald), 10ª B Matemática (teal), 11ª A Física (blue), 11ª B Física (indigo), 12ª A Matemática (purple). FAB '+ Nova Turma' emerald bottom-right. Bottom nav: Home, Turmas (active emerald pill), Notas, Mensagens. Plus Jakarta Sans, ultra high resolution."

---

## 11.6 Detalhe da Turma

> **Prompt:**
> "High-fidelity mobile app UI mockup, teacher class detail screen, E258Tech school app TEACHER mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, '10ª Classe A — Matemática' 18sp bold, 3-dot menu right. Hero stats: 3 equal mint cards no border — '28' Alunos icon-person, '13.8' Média icon-star, '90%' Assiduidade icon-check. MD3 Tabs: 'Alunos' (active underline emerald), 'Notas', 'Tarefas', 'Comunicados'. Tab Alunos content: search bar 'Pesquisar aluno...', student list rows (divider separated): avatar circle 40dp initials colored, student name 14sp bold, number 12sp gray, average '15.7' 14sp bold right colored emerald/red; row tappable → detail. Sort options: 'Ordenar por' chip — Nome / Nota / Assiduidade. Bulk action bar appears on long-press: send message, assign task, export. Section filter 'Em Risco · 3' red label with alert students highlighted. Plus Jakarta Sans, ultra high resolution."

---

## 11.7 Ficha do Aluno — Vista do Professor

> **Prompt:**
> "High-fidelity mobile app UI mockup, student file view from teacher perspective, E258Tech school app TEACHER mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Lucas Machava' 20sp bold. Student card: avatar 72dp emerald ring, '10ª Classe A · Nº 12345' 13sp gray, 'Turma de Matemática' chip emerald. Performance row: 3 mini mint cards — 'Média em Mat.' '15.7' emerald bold, 'Assiduidade' '90%' emerald, 'Tarefas' '7/8' dark. MD3 Tabs: 'Notas' (active), 'Presenças', 'Tarefas'. Tab Notas: grade rows for this subject only — date, assessment type chip, grade value, trend arrow; mini line chart of student's grade evolution. Alert banner amber if student at risk: 'Nota abaixo de 10 no Teste 2 — considere apoio adicional.' amber container. Action buttons: 'Enviar Mensagem' outlined, 'Adicionar Nota' filled emerald, 'Ver Histórico Completo' text emerald. Plus Jakarta Sans, ultra high resolution."

---

## 11.8 Criar Tarefa / Trabalho de Casa

> **Prompt:**
> "High-fidelity mobile app UI mockup, create homework assignment screen, E258Tech school app TEACHER mode. 9:16 aspect ratio, white background, borderless MD3. Top: X close, 'Nova Tarefa' 20sp bold center, 'Publicar' emerald text button right. Form: MD3 Filled TextField #F0FDF4 12dp radius: 'Título da Tarefa' field, 'Descrição e Instruções' text area 100dp tall, 'Disciplina' dropdown showing 'Matemática', 'Turma(s)' multi-select chips 'Turma 10ª A' emerald chip + '+ Adicionar'. Due date row: calendar icon left, 'Data de Entrega' label, '25 Jun 2026' value + time '23h59' — tappable opens date picker. Max grade row: '0-20 valores' input 12sp. Category chips: 'Tipo' — 'TPC' selected emerald, 'Ficha', 'Projeto', 'Oral' outlined. Resources section: 'Anexar Recursos' label, row of add-buttons: camera icon chip, file icon chip, link icon chip; attached file preview row if added. Preview toggle 'Ver como Aluno' text button emerald. Plus Jakarta Sans, ultra high resolution."

---

## 11.9 Criar Comunicado para Turma

> **Prompt:**
> "High-fidelity mobile app UI mockup, create class announcement screen, E258Tech school app TEACHER mode. 9:16 aspect ratio, white background, borderless MD3. Top: X close, 'Novo Comunicado' 20sp bold center, 'Enviar' emerald text button right. Audience section: 'Enviar para:' label. Recipient type chips 2 rows: '10ª Classe A' selected emerald filled, '10ª Classe B' outlined, '11ª Classe A' outlined, 'Todos os Alunos' outlined, 'Todos os Encarregados' outlined — multiple selectable. Priority toggle row: 'Marcar como Urgente' label, switch emerald toggle. Category dropdown: 'Categoria' — Informativo / Aviso / Evento / Lembrete. Title field: 'Título' MD3 Filled 56dp. Body text area: 'Mensagem' large text area 150dp #F0FDF4 no border. Scheduled send row: clock icon, 'Enviar Agora' radio selected, 'Agendar Envio' radio with date picker if selected. Attachments row: paperclip icon, 'Anexar ficheiro' text link emerald. Preview count: 'Será enviado para 56 destinatários' 13sp gray centered. Plus Jakarta Sans, ultra high resolution."

---

## 11.10 Relatório da Turma

> **Prompt:**
> "High-fidelity mobile app UI mockup, class report screen, E258Tech school app TEACHER mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Relatório · 10ª A' 20sp bold, download icon emerald right. Period selector chips: '1º Trimestre' (active emerald), '2º Trimestre', 'Ano'. Overview cards row: 3 mint no border — 'Aprovados' '24 / 28' emerald bold, 'Reprovados' '4' red bold, 'Média' '13.8' dark bold. Bar chart card: no border 28dp radius shadow — grade distribution chart: X-axis 0-5, 6-9, 10-13, 14-17, 18-20 ranges, Y-axis number of students, bars in emerald filled, hoverable. Below chart: 'Distribuição de Notas' 14sp semibold. Performance table: rows per student (scrollable) — rank position, name, grade, assiduidade %, tasks completed, status chip. At-risk students section: amber tint card — 'Alunos em Risco · 4' 14sp bold amber, student list mini rows. Export: 'Exportar Excel' outlined chip, 'Gerar PDF' outlined chip. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 12 — PORTAL DO ENCARREGADO (ADICIONAL)

## 12.2 Notas do Filho — Vista do Encarregado

> **Prompt:**
> "High-fidelity mobile app UI mockup, parent view of child's grades, E258Tech school app PARENT mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Notas de Lucas' 20sp bold. Child switcher chips: 'Lucas · 10ª A' active emerald, 'Ana · 8ª B' outlined. Trimester tab selector: '1º Trim' (active emerald underline), '2º Trim', '3º Trim'. Summary hero: mint card no border 28dp — ring chart emerald 78%, '15.7' 28sp bold emerald center, 'Média Geral' 12sp gray below, 'Aprovado' chip emerald, 'Evolução: ↑ +0.8 vs último trimestre' 13sp emerald. Subject cards (no border 28dp shadow): subject name 15sp bold, teacher 12sp gray, grade 22sp bold right colored, small progress bar. Alert row if grade below 10: 'Atenção: Química com 9 valores' amber card with warning icon — 'Agende uma reunião com o professor' action link emerald. Plus Jakarta Sans, ultra high resolution."

---

## 12.3 Assiduidade do Filho — Vista do Encarregado

> **Prompt:**
> "High-fidelity mobile app UI mockup, parent view of child's attendance, E258Tech school app PARENT mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Assiduidade de Lucas' 20sp bold. Child switcher chips. Summary: 3 mint cards — 'Presenças' '72' emerald, 'Faltas' '8' red, 'Taxa' '90%' emerald. Calendar heatmap card: no border 28dp radius shadow — same as student view. Section 'Faltas Não Justificadas': alert card red tint — '2 faltas por justificar' 14sp bold red, list of dates + subject. Action button inside card 'Justificar Falta' outlined red. Section 'Histórico': filter 'Todas / Justificadas / Por Justificar' chips. List rows: date, subject, status chip. Section 'Aviso de Limite': if close to limit — amber banner 'Lucas está a 2 faltas do limite trimestral. Máximo: 10 faltas.' Plus Jakarta Sans, ultra high resolution."

---

## 12.4 Solicitar Reunião com Professor

> **Prompt:**
> "High-fidelity mobile app UI mockup, parent request meeting with teacher screen, E258Tech school app PARENT mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Solicitar Reunião' 20sp bold. Teacher selection: 'Com quem pretende reunir?' label. Teacher cards (selectable, no border 28dp radius shadow): each card — avatar 48dp initials colored, teacher name 15sp bold, subject 13sp gray, 'Disponível para reunião' emerald chip or 'Indisponível esta semana' gray chip. Selected card: emerald border. Date preference: 'Preferência de Data' MD3 date picker card — calendar mini view, selectable available dates highlighted emerald. Time slot picker: horizontal chips of available times '09h00', '10h00', '14h00', '15h30' — selected chip filled emerald. Meeting type: 'Presencial' / 'Videochamada' segmented button. Topic field: 'Motivo' dropdown — Desempenho / Comportamento / Notas / Assiduidade / Outro. Notes text area optional. Primary button 'Enviar Pedido de Reunião' full-width 56dp emerald. Plus Jakarta Sans, ultra high resolution."

---

## 12.5 Autorização de Saída Antecipada

> **Prompt:**
> "High-fidelity mobile app UI mockup, early exit authorization screen, E258Tech school app PARENT mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Autorização de Saída' 20sp bold. Info card: #F0FDF4 no border 28dp — info icon emerald, 'As autorizações de saída devem ser submetidas até 1 hora antes da aula. Sujeitas a aprovação da direcção.' 13sp dark. Child selector: 'Aluno' — 'Lucas Machava · 10ª A' filled chip. Date and time: 'Data' chip calendar tappable, 'Hora de Saída' chip time picker '10h30'. Reason: 'Motivo' dropdown — Consulta Médica / Assunto Familiar / Visita / Emergência / Outro. Description: text field 'Descrição' optional. Guardian confirmation: 'Encarregado' row — 'Maria Machava' +258... with checkmark. Document optional: dashed upload zone small. Authorization status history below divider: past requests in list — date, status chip 'Aprovada' emerald / 'Pendente' amber / 'Rejeitada' red. Primary button 'Submeter Autorização' full-width 56dp emerald. Plus Jakarta Sans, ultra high resolution."

---

## 12.6 Pagamento de Propinas — Vista do Encarregado

> **Prompt:**
> "High-fidelity mobile app UI mockup, parent fees payment overview screen, E258Tech school app PARENT mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Propinas' 20sp bold. Child tabs: 'Lucas' (active emerald underline), 'Ana'. Balance card: no border 28dp radius #F0FDF4 — 'Situação de Lucas' 14sp gray, large status — 'Em Dia' 24sp bold emerald with checkmark, or 'Pendente' 24sp bold amber; 'Valor: 1.500,00 MT/mês' 14sp dark; 'Próximo: Julho 2026' 13sp gray. Payment alert card (if pending): amber tint no border 28dp — warning icon, 'Propina de Fevereiro em Atraso' 14sp bold amber, '1.500,00 MT — Vence em 3 dias' 13sp dark, 'Pagar Agora' button filled amber inside card. Month list: same as student view with month/status/amount/download receipt. Total summary footer: 'Total Pago 2026: 9.000 MT · 6 meses' 13sp gray centered. Plus Jakarta Sans, ultra high resolution."

---

# FLUXO 13 — PORTAL DO ADMINISTRADOR

## 13.1 Dashboard do Administrador

> **Prompt:**
> "High-fidelity mobile app UI mockup, school administrator dashboard, E258Tech school app ADMIN mode. 9:16 aspect ratio, white background, borderless MD3. Top: Nexora School logo icon 32dp emerald green left — stylized bold letter "N" with rounded corners, long flat shadow, right stem negative-space cutout of Mozambique map silhouette, small emerald pixels floating above top-right. 'Painel Administrativo' 18sp bold center, notifications bell right with badge. Admin greeting: 'E258Tech Escola · Ano 2026' 14sp gray. KPI grid 2x2: 4 cards no border 28dp radius white shadow — '847' Alunos Matriculados icon-users; '42' Professores icon-person; '94%' Assiduidade Global icon-check; '78%' Propinas Pagas icon-credit-card — each with small trend arrow and period label '+ 3 vs mês anterior'. Section 'Alertas do Sistema' 14sp semibold. Alert cards: amber tint no border — '12 alunos com propinas em atraso', 'Notas do 2º Trimestre pendentes: 3 turmas', '5 pedidos de documentos aguardam aprovação'. Quick actions row: 'Matrículas', 'Relatórios', 'Comunicados', 'Configurações' — 4 outlined chips emerald. Bottom nav: Dashboard (active), Alunos, Professores, Relatórios. Plus Jakarta Sans, ultra high resolution."

---

## 13.2 Gestão de Alunos — Lista

> **Prompt:**
> "High-fidelity mobile app UI mockup, student management list screen, E258Tech school app ADMIN mode. 9:16 aspect ratio, white background, borderless MD3. Top: 'Gestão de Alunos' 20sp bold, filter icon + export icon right. Stats strip: '847 Alunos · 32 Turmas · 94% Assiduidade' 12sp gray centered. Search bar full-width #F0FDF4 'Pesquisar por nome, BI, número...'. Filter row chips: 'Todos', '10ª Classe', '11ª Classe', '12ª Classe', 'Em Risco' red chip. Bulk action bar (appears on multi-select): 'Selecionar Todos', 'Enviar Comunicado', 'Exportar'. Student list rows (no border 28dp radius shadow card per row): avatar circle 40dp initials, student name 14sp bold, class '10ª A' chip mint, number '12345' 12sp gray; right: status chip 'Activo' emerald filled, 'Em Risco' amber, 'Inactivo' gray; arrow right. FAB '+' emerald 'Novo Aluno' bottom-right. Swipe right: quick actions — edit blue, deactivate amber, view green. Plus Jakarta Sans, ultra high resolution."

---

## 13.3 Ficha Completa do Aluno — Admin

> **Prompt:**
> "High-fidelity mobile app UI mockup, complete student record admin view, E258Tech school app ADMIN mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Ficha do Aluno' 20sp bold, edit icon + 3-dot menu right. Photo card: avatar 80dp emerald ring, 'Lucas Machava' 20sp bold dark, 'Nº 12345 · 10ª Classe A' 14sp gray, status chip 'Activo' emerald. Admin action chips row: 'Editar', 'Transferir', 'Suspender', 'Histórico'. MD3 Tabs scrollable: 'Pessoal', 'Académico', 'Financeiro', 'Documentos'. Tab Pessoal: info list card no border shadow — BI, data de nascimento, género, naturalidade, telefone, email, endereço. Encarregado sub-section: name, BI, relationship, phone, email. Tab Académico: enrollment date, class history, grade averages per year, attendance percentage, disciplinary records. Tab Financeiro: payment status, outstanding balance, payment history list. Tab Documentos: uploaded documents list with download. Plus Jakarta Sans, ultra high resolution."

---

## 13.4 Processo de Matrícula

> **Prompt:**
> "High-fidelity mobile app UI mockup, student enrollment process screen, E258Tech school app ADMIN mode. 9:16 aspect ratio, white background, borderless MD3. Top: back arrow, 'Nova Matrícula' 20sp bold. Step progress: 4 steps — '1 Dados Pessoais' (active filled emerald), '2 Encarregado', '3 Documentos', '4 Confirmação' — connected line, inactive gray. Step 1 form: photo upload row — avatar placeholder 80dp dashed circle, 'Adicionar Foto' emerald text link below. MD3 Filled TextField fields: 'Nome Completo', 'Número de BI', 'Data de Nascimento' date picker, 'Género' dropdown M/F, 'Naturalidade', 'Telefone', 'Email (opcional)'. Class assignment: 'Classe' dropdown '10ª Classe', 'Turma' dropdown 'Turma A'. Auto-generated: 'Número de Estudante gerado: 12348' info chip emerald. Primary button 'Próximo Passo' full-width 56dp emerald. Save draft: 'Guardar Rascunho' outlined gray. Progress dots bottom. Plus Jakarta Sans, ultra high resolution."

---

## 13.5 Gestão de Professores

> **Prompt:**
> "High-fidelity mobile app UI mockup, teacher management screen, E258Tech school app ADMIN mode. 9:16 aspect ratio, white background, borderless MD3. Top: 'Professores' 20sp bold, filter + export icons. Stats: '42 Professores · 18 Disciplinas' 12sp gray. Search bar 'Pesquisar por nome, disciplina...'. Filter chips: 'Todos', 'Matemática', 'Ciências', 'Humanas', 'Artes'. Teacher list rows (no border 28dp radius shadow): avatar 48dp initials emerald/blue/amber, teacher name 15sp bold, subjects chips row 'Matemática' 'Física' small mint chips, class count '4 turmas' 12sp gray; right: status chip 'Activo' emerald, arrow. Tap row opens teacher detail with their classes, assigned subjects, contact info. FAB '+' emerald 'Adicionar Professor' bottom-right. Workload indicator: small progress bar on each row showing 'carga horária' percentage — green if normal, amber if high, red if overloaded. Plus Jakarta Sans, ultra high resolution."

---

## 13.6 Relatórios e Estatísticas Escolares

> **Prompt:**
> "High-fidelity mobile app UI mockup, school statistics and reports screen, E258Tech school app ADMIN mode. 9:16 aspect ratio, white background, borderless MD3. Top: 'Relatórios' 20sp bold, download icon emerald right. Period filter: '1º Trimestre 2026' chip with dropdown expand arrow emerald. Report category tabs: 'Desempenho', 'Assiduidade' (active underline emerald), 'Financeiro', 'Documentos'. Tab Assiduidade: donut chart card 160dp — emerald slice 90% Presente, red 7% Falta, amber 3% Justificada; legend below with percentages and colored dots. Bar chart below: X-axis months Jan-Jun, Y-axis percentage, emerald bars — 'Assiduidade por Mês'. Class comparison table: header 'Turma / Taxa / Alunos', rows for each class with mini horizontal bar. At-risk section: '23 alunos com assiduidade abaixo de 75%' red alert card. Export options: 'Excel' chip, 'PDF' chip, 'Enviar por Email' chip — all outlined. Plus Jakarta Sans, ultra high resolution."

---

# ESTADOS ESPECIAIS (ADICIONAIS)

## E.6 Modo Offline

> **Prompt:**
> "High-fidelity mobile app UI mockup, offline mode screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Persistent banner at very top (below status bar): amber background #FEF3C7, wifi-off icon amber left, 'Sem ligação — A trabalhar offline' 13sp amber bold, 'Reconectar' text button amber bold right. Below banner: normal dashboard content but with subtle differences — cards show cached data, refresh icons grayed out, action buttons disabled with gray tint. Center overlay on action button: tooltip 'Disponível quando online'. Offline capabilities indicator: bottom sheet or info card showing 'Disponível Offline: Horário, Notas (só leitura), Perfil' with check icons emerald; 'Indisponível: Mensagens, Tarefas, Pagamentos' with X icons gray. Sync indicator: 'Última sincronização: 23 Jun · 09h15' 11sp gray with sync icon. Plus Jakarta Sans, ultra high resolution."

---

## E.7 Atualização Disponível

> **Prompt:**
> "High-fidelity mobile app UI mockup, app update available screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Full-screen modal overlay (not bottom sheet): centered card no border 28dp radius white shadow elevation 4 with dark dim behind. Card contents: Nexora School logo icon 56dp emerald green top center — stylized bold letter "N" with rounded corners and long flat shadow, right stem negative-space cutout of Mozambique country silhouette, small emerald rounded squares floating above top-right like digital pixels. 'Nova Versão Disponível' 22sp bold dark. 'v 2.2.0' chip emerald filled large. What's new section: 'Novidades nesta versão' 14sp semibold; bullet list 14sp gray — '• Melhorias na tela de notas', '• Suporte a pagamentos e-Mola', '• Correções de estabilidade', '• Desempenho melhorado'. File size: '28 MB · Tempo estimado: 2 min' 12sp gray. Two buttons: 'Atualizar Agora' full-width 56dp emerald fill; 'Mais Tarde' full-width 56dp outlined gray below. Forced update variant: hide 'Mais Tarde' button, show 'Esta versão é obrigatória' 12sp red below update button. Plus Jakarta Sans, ultra high resolution."

---

## E.8 Solicitação de Permissão

> **Prompt:**
> "High-fidelity mobile app UI mockup, permission request screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Center composition. Large permission illustration: flat icon of bell/camera/location, emerald tones, on mint circle 120dp. Permission type title: 'Permitir Notificações' or 'Acesso à Câmara' — 22sp bold dark centered. Explanation body: 'Para receber alertas de novas notas, comunicados da escola e lembretes de aulas, é necessário ativar as notificações.' 15sp gray centered, 3-line max. Benefit bullets (optional): 3 rows with emerald check icons — 'Notas lançadas em tempo real', 'Comunicados urgentes', 'Lembretes de aulas'. Two buttons: 'Permitir' full-width 56dp 28dp radius emerald fill — primary; 'Agora Não' outlined gray full-width below. Very bottom: 'Pode alterar nas Configurações do telemóvel a qualquer momento.' 11sp gray centered. Plus Jakarta Sans, ultra high resolution."

---

## E.9 Sessão Expirada / Timeout

> **Prompt:**
> "High-fidelity mobile app UI mockup, session expired / timeout screen, E258Tech school app. 9:16 aspect ratio, white background, borderless MD3. Background is blurred dimmed screenshot of last app screen. Center modal card: no border 28dp radius white shadow elevation 4. Lock icon circle 80dp mint fill, lock icon emerald 40dp. 'Sessão Expirada' 22sp bold dark centered. 'A sua sessão foi encerrada por inatividade. Faça login novamente para continuar.' 14sp gray centered. Two buttons: 'Entrar com PIN' full-width 56dp emerald fill — shows PIN keypad below if tapped; 'Entrar com Senha' outlined emerald full-width below — navigates to login. 'Terminar Sessão' red text link centered below buttons. Security note: 'Por segurança, encerramos sessões inativas.' 11sp gray centered. Plus Jakarta Sans, ultra high resolution."

---



> Use este bloco como **prefixo** em qualquer prompt personalizado para garantir consistência máxima:
>
> `"High-fidelity mobile app UI mockup, E258Tech school app, Material Design 3, Plus Jakarta Sans typography, primary color Emerald Green #10B981, white background #FFFFFF, containers mint #F0FDF4, no borders on any element, 28dp rounded corners throughout, text dark #111827, secondary text gray #6B7280, MD3 Navigation Bar at bottom, 9:16 aspect ratio, pixel-perfect, ultra high resolution, Dribbble quality UI design."`

---

## Modificadores de Estilo

| Objetivo | Acrescentar ao Prompt |
|---|---|
| Telemóvel real | `shown inside Samsung Galaxy S24 mockup frame` |
| Dark Mode | `dark background #0F172A, containers #1E293B, text white` |
| Tablet | `4:3 aspect ratio, side navigation drawer` |
| Fotorrealista | `photorealistic UI render, Dribbble quality shot` |
| Anotações UX | `with UX annotations and red callout arrows labeling components` |
| Comparação | `split screen showing before and after states side by side` |
| App Store | `framed in App Store screenshot style, gradient background behind device` |
| Múltiplas telas | `flat lay of 4 screens arranged in a 2x2 grid, white background, soft shadows` |
