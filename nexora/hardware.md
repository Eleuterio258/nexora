# Hardware — Prompts de Design para PCB, Montagem e Caixa 3D

Documento de referência com prompts prontos para usar em ferramentas de IA de design de PCB, geradores de imagem e modelação 3D. Inclui todas as especificações técnicas do sistema para que qualquer ferramenta produza resultados precisos.

---

## Índice

1. [Especificações técnicas de referência](#1-especificações-técnicas-de-referência)
2. [Prompts para design de esquemático](#2-prompts-para-design-de-esquemático)
3. [Prompts para layout de PCB](#3-prompts-para-layout-de-pcb)
4. [Prompts para design da caixa 3D](#4-prompts-para-design-da-caixa-3d)
5. [Prompts para geração de imagem (visualização)](#5-prompts-para-geração-de-imagem-visualização)
6. [Prompts para OpenSCAD (código 3D paramétrico)](#6-prompts-para-openscad-código-3d-paramétrico)
7. [Prompts para Fusion 360 / FreeCAD](#7-prompts-para-fusion-360--freecad)
8. [Prompts para KiCad com IA](#8-prompts-para-kicad-com-ia)
9. [Lista de ficheiros a gerar](#9-lista-de-ficheiros-a-gerar)

---

## 1. Especificações técnicas de referência

Usar estas especificações em todos os prompts como contexto.

### Componentes e dimensões físicas

| Componente | Dimensões (mm) | Montagem | Observação |
| ----------- | -------------- | -------- | ---------- |
| ESP32 DevKit v1 38 pinos | 55 × 28 × 12 | Through-hole | Pitch 2,54 mm |
| TFT ILI9341 2,8" | 75 × 49 × 5 | Header 14 pinos | Ecrã visível 45 × 35 mm |
| MFRC522 RFID | 60 × 40 × 5 | Header 8 pinos | Antena integrada |
| R307 Biometria | 56 × 20 × 20 | Conector JST 4 pinos | Montar na frente da caixa |
| NEO-6M GPS | 35 × 35 × 8 | Header 4 pinos | Antena cerâmica ou SMA |
| SIM800L | 40 × 40 × 3 | Header 12 pinos | Antena SMA externa |
| Keypad 4×3 membrana | 96 × 69 × 0,5 | Cabo plano 7 pinos | Colar na caixa |
| SIM800L antena | — | SMA fêmea | Coaxial para exterior caixa |
| 18650 × 6 (pack) | 80 × 70 × 40 | Holder soldado | 2S3P ou 6P |
| XL6009 Boost | 43 × 21 × 14 | Header 4 pinos | Pré-ajustado para 5 V |
| LM2596 Buck | 43 × 21 × 14 | Header 4 pinos | Pré-ajustado para 4 V |
| TP5100 Carregador | 26 × 15 × 5 | SMD / módulo | Carrega até 2 A |
| LED 5 mm verde | ⌀5 | Through-hole | Com resistor 220 Ω |
| LED 5 mm vermelho | ⌀5 | Through-hole | Com resistor 220 Ω |
| Buzzer activo 5 V | ⌀12 × 9 | Through-hole | — |
| Capacitor 1000 µF | ⌀12 × 25 | Through-hole | Junto ao SIM800L |
| Conector USB-C carga | 9 × 3,5 | SMD | Para recarregar bateria |

### Conexões entre módulos

```txt
ESP32 GPIO 18,23,19 (SPI) → TFT CS=15, DC=2, RST=4
                           → RFID SS=5, RST=22
ESP32 GPIO 16,17 (UART2)  → Biometria R307 RX/TX
ESP32 GPIO 34    (UART1)  → GPS NEO-6M TX
ESP32 GPIO 26,27 (UART0)  → SIM800L TX/RX
ESP32 GPIO 32,33,25,14    → Keypad linhas
ESP32 GPIO 12,13,21       → Keypad colunas
ESP32 GPIO 0              → LED verde (via 220Ω)
ESP32 GPIO 36 (ADC)       → Divisor tensão bateria (R=100kΩ+100kΩ)
ESP32 GPIO 38             → Transistor NPN → GPS VCC (on/off)
ESP32 GPIO 37             → Transistor NPN → Biometria VCC (on/off)
ESP32 GPIO 39             → Transistor NPN → Buzzer
Bateria 18650             → BMS → XL6009 (5 V) → ESP32 VIN, TFT, RFID, GPS
                                → LM2596 (4 V) → SIM800L VCC
                          → TP5100 ← USB-C entrada
```

### Dimensões da caixa

```txt
Interior útil:    200 × 140 × 70 mm
Parede:           3 mm (PETG) ou 4 mm (PLA)
Exterior total:   206 × 146 × 76 mm
Montagem na parede: 2 furos ⌀5 mm a 180 mm de distância (horizontal)
Material:         PETG (resistência ao calor) ou ABS
Cor:              Preto ou cinzento escuro
Acabamento:       Mate
```

### Face frontal da caixa

```txt
┌──────────────────────────────────────────┐
│  ┌────────────────────┐  ●  ●            │
│  │                    │  V  E            │  V = LED verde
│  │   TFT 2.8"         │                  │  E = LED vermelho
│  │   75×49 mm         │  ┌───────────┐   │
│  │                    │  │ 1 │ 2 │ 3 │   │
│  └────────────────────┘  │ 4 │ 5 │ 6 │   │
│                           │ 7 │ 8 │ 9 │   │
│  ┌──────────────────┐    │ * │ 0 │ # │   │
│  │ RFID (antena)    │    └───────────┘   │
│  │ área livre metal │                    │
│  └──────────────────┘  [BIOMETRIA]       │
│                           ⌀21 mm          │
│  ○ Buzzer ⌀5             encaixe lateral │
└──────────────────────────────────────────┘
```

### Face posterior / lateral

```txt
Lateral esquerda:  SMA antena GSM, SMA antena GPS (ou janela transparente)
Lateral direita:   USB-C (carga), interruptor ON/OFF
Inferior:          2 grelhas de ventilação 20×5 mm
Posterior:         2 furos ⌀5 mm para parafusos de parede (centro a centro 180 mm)
```

---

## 2. Prompts para design de esquemático

### Prompt para ChatGPT / Claude / Gemini — gerar netlist KiCad

```
Gera um netlist KiCad (.net) para um sistema de controlo de assiduidade com ESP32.
Inclui os seguintes componentes e conexões:

MICROCONTROLADOR:
- U1: ESP32-WROOM-32 (ou ESP32 DevKit equivalente)

DISPLAY:
- U2: ILI9341 TFT 2.8" SPI
  SCK  → GPIO18
  MOSI → GPIO23
  MISO → GPIO19
  CS   → GPIO15
  DC   → GPIO2
  RST  → GPIO4
  VCC  → 3.3V
  GND  → GND

RFID:
- U3: MFRC522
  SCK  → GPIO18 (partilhado com TFT)
  MOSI → GPIO23 (partilhado)
  MISO → GPIO19 (partilhado)
  SS   → GPIO5
  RST  → GPIO22
  VCC  → 3.3V
  GND  → GND

BIOMETRIA:
- U4: R307 (conector JST-4P)
  TX   → GPIO16
  RX   → GPIO17
  VCC  → Q1 coletor (controlo de energia)
  GND  → GND
- Q1: NPN 2N2222 ou BC547, base=GPIO37, emissor=GND, coletor=VCC_Biometria

GPS:
- U5: NEO-6M (conector 4 pinos)
  TX   → GPIO34
  VCC  → Q2 coletor
  GND  → GND
- Q2: NPN 2N2222, base=GPIO38, emissor=GND, coletor=VCC_GPS

GSM:
- U6: SIM800L (conector 12 pinos)
  TX   → GPIO26
  RX   → GPIO27
  VCC  → 4.0V (saída LM2596)
  GND  → GND
- C3: 1000µF/10V em paralelo com VCC do SIM800L

KEYPAD:
- J1: Conector 7 pinos flat para keypad 4×3
  Linhas:  GPIO32, GPIO33, GPIO25, GPIO14
  Colunas: GPIO12, GPIO13, GPIO21

ALIMENTAÇÃO:
- BAT1: Pack 18650 6 células com BMS (conector XT60)
- U7: XL6009 Boost 3.7V→5V (conector 4 pinos, enable, input, output, GND)
- U8: LM2596 Buck 5V→4V (idem)
- U9: TP5100 carregador LiPo (conector USB-C + bateria)
- J2: Conector USB-C para carga
- SW1: Interruptor ON/OFF entre BMS e XL6009

FEEDBACK:
- LED1: Verde, GPIO0, resistor R1=220Ω
- LED2: Vermelho, GPIO36 (via buffer 74HC1G125), resistor R2=220Ω
- BZ1: Buzzer activo 5V, via Q3 NPN (base=GPIO39, resistor R3=1kΩ)

MONITORIZAÇÃO DE BATERIA:
- R4: 100kΩ entre BAT+ e GPIO36
- R5: 100kΩ entre GPIO36 e GND
(divisor de tensão para medir tensão da bateria)

DESACOPLAMENTO:
- C1: 100nF junto ao VCC do ESP32
- C2: 100nF junto ao VCC do RFID
- C4: 100nF junto ao VCC do GPS

Produz o netlist em formato KiCad (.net), com referências únicas para cada componente e todas as nets nomeadas correctamente (VCC_5V, VCC_3V3, VCC_4V, GND, etc.).
```

---

### Prompt para gerar esquemático em EasyEDA / LCSC

```
Cria um projecto EasyEDA para um terminal de controlo de assiduidade ESP32.
Usa componentes disponíveis na biblioteca LCSC.

Requisitos do esquemático:
1. Separar em 4 folhas: (A) Microcontrolador e periféricos SPI, (B) UARTs e keypad, (C) Alimentação e bateria, (D) Feedback e monitorização

Folha A — ESP32 + SPI:
- ESP32-WROOM-32 com todos os pinos etiquetados
- ILI9341 via header 14 pinos (SPI VSPI: SCK=18, MOSI=23, MISO=19, CS=15, DC=2, RST=4)
- MFRC522 via header 8 pinos (SPI partilhado, CS=5, RST=22)
- Desacoplamento: 100nF em cada VCC

Folha B — UARTs + Keypad:
- R307 biometria via conector JST-PH 4 pinos (GPIO16=TX, GPIO17=RX)
- Transistor NPN 2N2222 para corte de energia da biometria (GPIO37)
- NEO-6M GPS via header 4 pinos (GPIO34=RX)
- Transistor NPN para corte de energia do GPS (GPIO38)
- SIM800L via header 12 pinos (GPIO26=TX, GPIO27=RX)
- Capacitor 1000µF/10V junto ao SIM800L
- Keypad 4×3 via conector FFC/FPC 7 pinos

Folha C — Alimentação:
- Pack 18650 (símbolo bateria genérica) com conector XT60
- BMS 6S paralelo (símbolo como bloco funcional)
- XL6009 Boost converter (entrada 3.7-4.2V, saída 5V/2A)
- LM2596 Buck converter (entrada 5V, saída 4.0V/1A)
- TP5100 módulo carregador LiPo 2A
- Conector USB-C com linhas VBUS e GND
- Interruptor SPST para ON/OFF
- Fusível 3A na linha principal

Folha D — Feedback e monitorização:
- LED verde com resistor 220Ω (GPIO0)
- LED vermelho com buffer 74HC1G125 e resistor 220Ω (GPIO36)
- Buzzer activo 5V com transistor NPN e resistor 1kΩ base (GPIO39)
- Divisor resistivo 100kΩ+100kΩ para ADC bateria (GPIO36)

Indica LCSC part numbers para cada componente quando disponível.
```

---

## 3. Prompts para layout de PCB

### Prompt principal para layout (KiCad / EasyEDA / Altium)

```
Faz o layout de uma PCB de 2 camadas para um terminal de controlo de assiduidade.

ESPECIFICAÇÕES DA PCB:
- Dimensões: 180 × 120 mm
- Camadas: 2 (Top Copper + Bottom Copper)
- Espessura: 1,6 mm FR4
- Cor do solder mask: Preto
- Silkscreen: Branco
- Acabamento: HASL lead-free
- Fabricante alvo: JLCPCB ou PCBWay

REGRAS DE DESIGN:
- Largura mínima de trilha: 0,25 mm (sinal), 1,0 mm (alimentação 3,3V/5V), 2,0 mm (alimentação bateria)
- Espaçamento mínimo: 0,2 mm
- Via mínima: ⌀0,6 mm drill, ⌀1,2 mm pad
- Plano de GND na camada Bottom
- Plano de VCC_5V na camada Top (parcial, onde possível)

POSICIONAMENTO DOS COMPONENTES (obrigatório):
- ESP32 DevKit: centro superior da placa, orientação vertical
- TFT ILI9341: canto superior esquerdo, ecrã para cima (virado para o exterior da caixa)
- MFRC522: canto inferior esquerdo, antena longe do SIM800L
- Keypad conector: borda direita, vertical
- R307 conector: borda inferior esquerda
- GPS NEO-6M: canto superior direito (longe do SIM800L)
- SIM800L: canto inferior direito (zona de RF isolada)
- XL6009 + LM2596: centro inferior
- TP5100 + USB-C: borda esquerda, centro
- Bateria: conector XT60 na borda inferior centro
- LEDs: borda superior, visíveis pela frente da caixa
- Buzzer: canto superior direito

ZONAS DE RF (regras especiais):
- SIM800L: keepout de 10 mm em volta da antena SMA
- RFID MFRC522: keepout de 5 mm em volta da antena integrada — sem planos de cobre nesta área
- GPS NEO-6M: distância mínima de 30 mm do SIM800L

TRILHAS CRÍTICAS:
- SPI (SCK/MOSI/MISO): trilhas paralelas, comprimento igualado (±0,5 mm), máx 50 mm
- UART GPS (GPIO34): linha simples, afastada do SIM800L
- Alimentação SIM800L: trilha 2 mm mínimo, directo do LM2596 com capacitor 1000µF o mais perto possível do VCC SIM800L
- Divisor de tensão ADC: resistores SMD 0402 o mais perto possível do GPIO36

FUROS DE MONTAGEM:
- 4 × M3 nos cantos (3,2 mm drill, copper clearance 5 mm)
- Compatível com caixa 200×140×70 mm

Gera o ficheiro .kicad_pcb ou exporta o Gerber completo (GTL, GBL, GTS, GBS, GTO, GBO, DRL).
```

---

### Prompt para revisão DRC (Design Rule Check)

```
Faz a revisão DRC do seguinte layout de PCB para um sistema ESP32 de assiduidade.
Verifica especificamente:

1. ZONAS DE RF:
   - O plano de cobre está afastado pelo menos 5 mm da antena do MFRC522?
   - O GPS e o SIM800L têm pelo menos 30 mm de separação?
   - A antena SMA do SIM800L tem keepout de 10 mm?

2. ALIMENTAÇÃO:
   - As trilhas de bateria (corrente até 3 A) têm pelo menos 2 mm de largura?
   - O capacitor 1000µF está a menos de 5 mm do VCC do SIM800L?
   - Há plano de GND contínuo na camada Bottom?

3. SPI:
   - As trilhas SCK/MOSI/MISO têm comprimento igualado (±0,5 mm)?
   - Estão paralelas e com espaçamento mínimo de 0,2 mm?

4. COMPONENTES MECÂNICOS:
   - Os 4 furos M3 de montagem estão dentro da PCB?
   - Os conectores de borda (USB-C, XT60, SMA) estão correctamente posicionados?

5. FABRICABILIDADE:
   - Todas as vias têm drill ≥ 0,6 mm?
   - Nenhuma trilha passa por baixo dos componentes de RF?

Lista todos os erros encontrados e propõe correcções.
```

---

## 4. Prompts para design da caixa 3D

### Prompt principal para impressão FDM (PLA/PETG)

```
Desenha uma caixa para impressão 3D FDM para um terminal de controlo de assiduidade com ESP32.

DIMENSÕES INTERNAS:
- Largura: 200 mm
- Altura: 140 mm
- Profundidade: 70 mm
- Espessura de parede: 3,5 mm (PETG) ou 4 mm (PLA)

MATERIAL E IMPRESSÃO:
- Material: PETG (preferido — resistência ao calor até 80°C, mais robusto que PLA)
- Alternativa: ABS (para ambientes quentes)
- Altura de camada: 0,2 mm
- Infill: 40% (paredes e tampa) — gyroid
- Perímetros: 4
- Suportes: apenas onde necessário (mínimos)
- Sem suportes na face frontal

DESIGN GERAL:
- Tampa frontal removível com 4 parafusos M3 embutidos (inserts de latão ⌀4,5 mm)
- Encaixe tipo "caixa + tampa" (box + lid) com rebaixo de 5 mm
- Cantos externos com raio de 8 mm (aspecto profissional)
- Superfície frontal texturada (padrão fino) para reduzir marcas de dedos
- Furos de montagem na traseira: 2 × M5, a 180 mm de distância (horizontal), com placa de encosto

FACE FRONTAL (tampa) — recortes obrigatórios:
┌─────────────────────────────────────────────────┐
│                                                 │
│  ┌──────────────────────┐  ●verde  ●vermelho     │
│  │ Recorte TFT          │  ⌀5      ⌀5            │
│  │ 76 × 50 mm           │                        │
│  │ (borda chanfrada 1mm)│  ┌─────────────────┐   │
│  └──────────────────────┘  │ Keypad membrana │   │
│                             │ 96 × 69 mm      │   │
│  ┌──────────────────────┐  │ recorte exacto  │   │
│  │ Janela RFID          │  │ +cola lateral   │   │
│  │ 62 × 42 mm           │  └─────────────────┘   │
│  │ Material ABS transp. │                        │
│  │ (sem metal na área)  │  ⌀21 mm encaixe        │
│  └──────────────────────┘  biometria R307         │
│                                                   │
│          ○ Buzzer ⌀6 mm (grelha de furos 3×3)    │
└─────────────────────────────────────────────────┘

LATERAIS E TRASEIRA — recortes e elementos:
- Lateral esquerda:
  * Conector SMA antena GSM: ⌀8 mm, centro a 20 mm da base
  * Conector SMA antena GPS: ⌀8 mm, centro a 40 mm da base
  * Ou janela transparente ABS 40×30 mm para antena GPS interna

- Lateral direita:
  * Conector USB-C: recorte 10 × 4 mm com chanfro, centro a 15 mm da base
  * Interruptor ON/OFF: recorte 20 × 10 mm, centro a 40 mm da base

- Base inferior:
  * 2 grelhas de ventilação: 20 × 5 mm cada, espaçadas 60 mm
  * Pés de borracha: 4 saliências ⌀8 × 2 mm nos cantos (para grelhas de ventilação)

- Traseira:
  * 2 furos M5 com contra-furo ⌀9 × 3 mm (cabeça parafuso embutida)
  * Placa de encosto rectangular 50 × 30 × 3 mm (impressa separado)
  * Distância entre furos: 180 mm horizontal

INTERIOR — elementos internos:
- Standoffs M3 × 5 mm de altura: 4 × nos cantos para fixar PCB 180×120 mm
- Suporte para pack 18650: caixilho 82 × 72 × 42 mm, com molas de contacto
- Suporte para XL6009 + LM2596: prateleira 50 × 25 mm com pinos de retenção
- Calha de passagem de cabos: 15 × 10 mm ao longo da lateral esquerda
- Separador de RF: parede interna de 40 mm de altura entre RFID e SIM800L

MÓDULO BIOMETRIA — encaixe frontal:
- Encaixe circular ⌀21 mm com profundidade de 20 mm
- Rebaixo para sensor: ⌀19 mm × 3 mm (área de leitura)
- Retaining ring com 2 parafusos M2
- Posição: canto inferior direito da face frontal

QUALIDADE DE IMPRESSÃO ESPERADA:
- Superfície externa Lisa (não necessita lixar)
- Furos de rosca M3: usar inserts de calor (heatset inserts) ⌀4,5 mm × 4 mm
- Furos SMA: imprimir com 0,1 mm menor que o nominal, depois alargar com broca
- Tampa frontal: imprimir em posição horizontal (face frontal para baixo, sem suportes)
- Corpo: imprimir de pé (parede posterior na mesa)

Exporta os ficheiros STL separados:
1. corpo_principal.stl
2. tampa_frontal.stl
3. placa_montagem_parede.stl
4. encaixe_biometria.stl
5. suporte_bateria.stl
```

---

### Prompt para FreeCAD (script Python)

```python
# Cola este script no FreeCAD Python console para gerar a caixa base

import FreeCAD, Part, Draft

doc = FreeCAD.newDocument("Caixa_Assiduidade")

# ── Corpo principal ──────────────────────────────────────────────
corpo_ext = Part.makeBox(206, 76, 146)  # L × P × H exteriores

# Escavar interior
interior = Part.makeBox(199, 69, 140)  # paredes 3.5mm
interior.Placement.Base = FreeCAD.Vector(3.5, 3.5, 3.5)

corpo = corpo_ext.cut(interior)

# ── Recorte TFT 76×50mm na face frontal ──────────────────────────
tft_cut = Part.makeBox(76, 10, 50)
tft_cut.Placement.Base = FreeCAD.Vector(10, 0, 70)
corpo = corpo.cut(tft_cut)

# ── Recorte Keypad 96×69mm ───────────────────────────────────────
kp_cut = Part.makeBox(96, 10, 69)
kp_cut.Placement.Base = FreeCAD.Vector(100, 0, 50)
corpo = corpo.cut(kp_cut)

# ── Furos LED 5mm (×2) ───────────────────────────────────────────
led1 = Part.makeCylinder(2.5, 10)
led1.Placement.Base = FreeCAD.Vector(100, 0, 130)
led2 = Part.makeCylinder(2.5, 10)
led2.Placement.Base = FreeCAD.Vector(115, 0, 130)
corpo = corpo.cut(led1).cut(led2)

# ── Furos SMA laterais ────────────────────────────────────────────
sma1 = Part.makeCylinder(4, 10)
sma1.Placement.Base = FreeCAD.Vector(0, 20, 20)
sma1.Placement.Rotation = FreeCAD.Rotation(FreeCAD.Vector(0,1,0), 90)
sma2 = Part.makeCylinder(4, 10)
sma2.Placement.Base = FreeCAD.Vector(0, 20, 40)
sma2.Placement.Rotation = FreeCAD.Rotation(FreeCAD.Vector(0,1,0), 90)
corpo = corpo.cut(sma1).cut(sma2)

# ── Furos montagem parede (M5) ────────────────────────────────────
fw1 = Part.makeCylinder(2.5, 10)
fw1.Placement.Base = FreeCAD.Vector(13, 69, 73)
fw2 = Part.makeCylinder(2.5, 10)
fw2.Placement.Base = FreeCAD.Vector(193, 69, 73)
corpo = corpo.cut(fw1).cut(fw2)

# ── Adicionar ao documento ────────────────────────────────────────
Part.show(corpo)
doc.recompute()
```

---

## 5. Prompts para geração de imagem (visualização)

### Midjourney / DALL-E 3 / Stable Diffusion — Renderização realista

```
Photorealistic product render of a modern industrial IoT attendance terminal device,
wall-mounted, matte black ABS enclosure, dimensions approximately 20cm × 15cm × 7cm.

Front panel features:
- 2.8 inch color TFT LCD display showing employee name, time and green check icon
- 4x3 numeric membrane keypad on the right side
- Fingerprint sensor circular cutout (21mm diameter) bottom right with blue LED ring
- Two small indicator LEDs (green and red) top right
- Transparent RFID reader window bottom left with subtle scan animation effect
- Subtle buzzer grille (3x3 holes pattern) bottom center
- Company logo "NEXORA" embossed on top

Left side: two SMA antenna connectors (GPS and GSM)
Right side: USB-C charging port, black toggle switch

Clean industrial design, professional quality, similar to HID access control readers,
studio lighting, white background, 4K resolution, product photography style

--ar 4:3 --style raw --v 6
```

---

### Prompt — vista explodida (exploded view)

```
Technical exploded view illustration of an ESP32 IoT attendance terminal,
clean engineering diagram style, white background, labeled components.

Show separated layers from front to back:
1. Front panel (matte black) with cutouts for display, keypad, fingerprint, RFID window
2. 2.8" ILI9341 TFT display module
3. Main PCB (green, 180×120mm) with ESP32, RFID MFRC522, GPS NEO-6M modules
4. Battery holder with 6x 18650 cells
5. Back enclosure with wall mounting holes

Isometric view, technical illustration style, component labels in Portuguese,
arrows showing assembly order, clean vector-like render

--ar 16:9 --style raw --v 6
```

---

### Prompt — esquema de pinagem visual

```
Clean technical diagram showing ESP32 DevKit board pinout connections to:
- ILI9341 TFT display (SPI bus, 6 wires)
- MFRC522 RFID module (SPI bus shared, 4 wires)
- R307 fingerprint sensor (UART, 4 wires)
- NEO-6M GPS module (UART, 2 wires)
- SIM800L GSM module (UART, 2 wires + power)
- 4x3 Keypad (7 wires)

Style: clean circuit diagram, color-coded wires (red=VCC, black=GND, yellow=data),
labeled GPIO numbers, white background, professional technical documentation style,
similar to Arduino tutorial diagrams from Instructables or Adafruit

--ar 16:9 --style raw --v 6
```

---

## 6. Prompts para OpenSCAD (código 3D paramétrico)

Colar directamente no OpenSCAD para gerar e exportar STL.

### corpo_principal.scad

```scad
// ── Parâmetros globais ─────────────────────────────────────────
$fn = 60;  // resolução de cilindros

// Dimensões exteriores
W = 206;   // largura
D = 76;    // profundidade
H = 146;   // altura
T = 3.5;   // espessura de parede

// Raio dos cantos
R = 8;

module rounded_box(w, d, h, r) {
    hull() {
        for (x = [r, w-r], y = [r, d-r])
            translate([x, y, 0]) cylinder(h=h, r=r);
    }
}

module corpo() {
    difference() {
        // Exterior arredondado
        rounded_box(W, D, H, R);

        // Interior escavado (excepto base)
        translate([T, T, T])
            rounded_box(W-2*T, D-2*T, H, R-T);

        // ── Face frontal (y=0): recortes ──────────────────────

        // TFT 76×50mm — canto superior esquerdo
        translate([10, -1, H-10-50])
            cube([76, T+2, 50]);

        // Keypad 96×69mm — centro direito
        translate([W-10-96, -1, H-10-69-30])
            cube([96, T+2, 69]);

        // Janela RFID 62×42mm — inferior esquerdo
        translate([10, -1, 15])
            cube([62, T+2, 42]);

        // Encaixe biometria ⌀21mm — inferior direito
        translate([W-40, -1, 30])
            rotate([-90, 0, 0])
                cylinder(h=T+2, r=10.5);

        // Grelha buzzer 3×3 furos ⌀4mm
        for (xi=[0:2], yi=[0:2])
            translate([W/2 - 12 + xi*12, -1, 8 + yi*12])
                rotate([-90, 0, 0])
                    cylinder(h=T+2, r=2);

        // LEDs ⌀5mm
        translate([W-30, -1, H-15])
            rotate([-90,0,0]) cylinder(h=T+2, r=2.5);
        translate([W-15, -1, H-15])
            rotate([-90,0,0]) cylinder(h=T+2, r=2.5);

        // ── Lateral esquerda (x=0): SMA ──────────────────────
        translate([-1, D/2-5, 20])
            rotate([0, 90, 0]) cylinder(h=T+2, r=4);
        translate([-1, D/2-5, 40])
            rotate([0, 90, 0]) cylinder(h=T+2, r=4);

        // ── Lateral direita (x=W): USB-C + interruptor ───────
        translate([W-T-1, D/2-5, 15])
            cube([T+2, 10, 4]);    // USB-C 10×4mm
        translate([W-T-1, D/2-5, 35])
            cube([T+2, 20, 10]);   // interruptor

        // ── Base: grelhas ventilação ──────────────────────────
        translate([W/2-30, 20, -1])
            cube([20, 5, T+2]);
        translate([W/2+10, 20, -1])
            cube([20, 5, T+2]);

        // ── Traseira: furos montagem M5 ───────────────────────
        translate([13, D-T-1, H/2])
            rotate([90,0,0]) cylinder(h=T+2, r=2.5);
        translate([W-13, D-T-1, H/2])
            rotate([90,0,0]) cylinder(h=T+2, r=2.5);
    }

    // ── Standoffs internos para PCB ───────────────────────────
    for (pos = [[T+2, T+2, T], [T+2, T+2+115, T],
                [T+2+175, T+2, T], [T+2+175, T+2+115, T]])
        translate(pos)
            difference() {
                cylinder(h=8, r=4);
                cylinder(h=8, r=1.5);  // rosca M3
            }
}

corpo();
```

### suporte_bateria.scad

```scad
// Suporte para 6× 18650 (configuração 2×3)
$fn = 40;

CEL_D = 18.5;  // diâmetro 18650 + folga
CEL_L = 65.5;  // comprimento 18650 + folga
ROWS  = 2;
COLS  = 3;
T     = 2;

module cell_slot() {
    cylinder(h=CEL_L, r=CEL_D/2);
}

module holder() {
    difference() {
        // Corpo sólido
        cube([COLS*CEL_D + 2*T + (COLS-1)*1,
              ROWS*CEL_D + 2*T + (ROWS-1)*1,
              CEL_L + 2*T]);

        // Furos para células
        for (c=[0:COLS-1], r=[0:ROWS-1])
            translate([T + c*(CEL_D+1) + CEL_D/2,
                       T + r*(CEL_D+1) + CEL_D/2,
                       T])
                cell_slot();

        // Janela de acesso às molas (base)
        translate([T, T, 0])
            cube([COLS*CEL_D + (COLS-1)*1,
                  ROWS*CEL_D + (ROWS-1)*1,
                  T+1]);
    }
}

holder();
```

---

## 7. Prompts para Fusion 360 / FreeCAD

### Prompt para Fusion 360 (AI generative / script)

```
Design a professional wall-mounted enclosure in Autodesk Fusion 360 for an
ESP32-based attendance terminal.

BODY SPECIFICATIONS:
- External dimensions: 206mm W × 76mm D × 146mm H
- Wall thickness: 3.5mm
- Corner radius: 8mm (all external corners)
- Material simulation: Matte black ABS plastic
- Split design: main body + front panel lid (4x M3 screws)
- Lid overlap: 5mm rebate around perimeter

FRONT PANEL CUTOUTS (create as parameters):
- TFT_W=76, TFT_H=50, TFT_X=10, TFT_Y=86 (from bottom)
- KEYPAD_W=96, KEYPAD_H=69, KEYPAD_X=100, KEYPAD_Y=47
- RFID_W=62, RFID_H=42, RFID_X=10, RFID_Y=15
- FINGER_D=21 (circle), FINGER_X=166, FINGER_Y=30 (center)
- LED1_D=5, LED1_X=176, LED1_Y=131 (center)
- LED2_D=5, LED2_X=191, LED2_Y=131 (center)
- BUZZER: 3x3 grid of D=4mm holes, centered at X=103, Y=12

SIDE CUTOUTS:
- Left: 2x SMA holes D=8mm at Y=D/2, Z=20 and Z=40
- Right: USB-C slot 10×4mm at Z=15; Toggle 20×10mm at Z=35

REAR FEATURES:
- 2x M5 mounting holes, center-to-center 180mm horizontal
- Countersink M5 (head diameter 9mm, depth 3mm)
- Integrated wall bracket with keyhole slots

INTERIOR FEATURES:
- 4x M3 boss (OD=8mm, H=8mm) for PCB 180×120mm
- Battery cradle recess 82×72×42mm
- Cable routing channel 15×10mm along left wall
- RF separator wall (H=40mm) between RFID and GSM zones

Generate timeline-based parametric model with all dimensions as named parameters.
Export: STEP file + STL for each body part separately.
```

---

## 8. Prompts para KiCad com IA

### Prompt para gerar footprints customizados

```
Gera os seguintes footprints KiCad (.kicad_mod) para o projecto de assiduidade ESP32:

1. FOOTPRINT: ESP32_DevKit_38pin
   - 2 filas de 19 pinos
   - Pitch: 2,54 mm
   - Distância entre filas: 25,4 mm (10 pinos)
   - Pad size: 1,7 × 1,7 mm
   - Drill: 1,0 mm
   - Courtyard: 56 × 28 mm
   - Silk: rectângulo com label ESP32

2. FOOTPRINT: SIM800L_Module
   - 2 filas de 6 pinos
   - Pitch: 2,0 mm
   - Distância entre filas: 35 mm
   - Pad size: 1,5 × 1,5 mm
   - Drill: 0,9 mm
   - Courtyard: 42 × 42 mm
   - Keepout: copper pour na área da antena (30 × 42 mm, lado direito)

3. FOOTPRINT: JST_PH_4pin (para biometria R307)
   - 4 pinos em linha
   - Pitch: 2,0 mm
   - Pad size: 1,8 × 2,5 mm (SMD)
   - Courtyard: 10 × 5 mm

4. FOOTPRINT: XT60_Connector (para bateria)
   - 2 pinos
   - Pitch: 7,5 mm
   - Pad size: 3,5 × 3,5 mm
   - Drill: 2,0 mm
   - Silk: marcação + e −
   - Courtyard: 20 × 15 mm

Formata cada footprint como ficheiro .kicad_mod válido para KiCad 7 ou superior.
```

---

### Prompt para gerar BOM (Bill of Materials)

```
Gera uma BOM completa em CSV para o sistema de assiduidade ESP32 com as colunas:
Referência, Valor, Footprint, Quantidade, Fabricante, Part Number, Fornecedor, Preço_USD_unit, Preço_MZN_unit, Subtotal_MZN

Inclui estes componentes:
- U1: ESP32-WROOM-32 (Espressif)
- U2: ILI9341 módulo TFT 2.8" SPI
- U3: MFRC522 módulo RFID
- U4: R307 sensor biométrico
- U5: NEO-6M módulo GPS
- U6: SIM800L módulo GSM
- U7: XL6009 módulo boost converter
- U8: LM2596 módulo buck converter
- U9: TP5100 módulo carregador LiPo
- BAT1: 18650 3500mAh × 6
- J1: Conector XT60 fêmea
- J2: Conector USB-C SMD
- J3: Conector JST-PH 4 pinos (biometria)
- J4-J5: Conector SMA fêmea PCB (GPS e GSM)
- C1-C4: Capacitor 100nF 0402
- C5: Capacitor 1000µF/10V (electrolítico)
- R1-R2: Resistor 220Ω 0402 (LEDs)
- R3: Resistor 1kΩ 0402 (buzzer)
- R4-R5: Resistor 100kΩ 0402 (divisor bateria)
- Q1-Q3: 2N2222 ou BC547 NPN (controlo de energia)
- LED1: LED 5mm verde
- LED2: LED 5mm vermelho
- BZ1: Buzzer activo 5V 12mm
- SW1: Interruptor SPST
- PCB: FR4 180×120mm 2 camadas (JLCPCB)
- Caixa: Impressão 3D PETG (custo estimado filamento)
- M3_inserts: Inserts de calor M3 × 8
- Parafusos M3 × 10: × 8

Câmbio referência: 1 USD = 64 MZN.
Adiciona linha de TOTAL no final.
```

---

## 9. Lista de ficheiros a gerar

```txt
nexora_assiduidade/
├── hardware/
│   ├── pcb/
│   │   ├── assiduidade_esp32.kicad_pro    ← projecto KiCad
│   │   ├── assiduidade_esp32.kicad_sch    ← esquemático
│   │   ├── assiduidade_esp32.kicad_pcb    ← layout PCB
│   │   ├── gerbers/
│   │   │   ├── assiduidade-F_Cu.gtl       ← camada top cobre
│   │   │   ├── assiduidade-B_Cu.gbl       ← camada bottom cobre
│   │   │   ├── assiduidade-F_Mask.gts     ← solder mask top
│   │   │   ├── assiduidade-B_Mask.gbs     ← solder mask bottom
│   │   │   ├── assiduidade-F_Silks.gto    ← silkscreen top
│   │   │   ├── assiduidade-B_Silks.gbo    ← silkscreen bottom
│   │   │   └── assiduidade-Edge_Cuts.gm1  ← contorno da placa
│   │   ├── drill/
│   │   │   └── assiduidade.drl            ← ficheiro de furos
│   │   └── bom/
│   │       └── bom_assiduidade.csv        ← lista de materiais
│   │
│   └── caixa_3d/
│       ├── corpo_principal.scad           ← OpenSCAD paramétrico
│       ├── corpo_principal.stl            ← exportado para impressão
│       ├── tampa_frontal.scad
│       ├── tampa_frontal.stl
│       ├── suporte_bateria.scad
│       ├── suporte_bateria.stl
│       ├── encaixe_biometria.scad
│       ├── encaixe_biometria.stl
│       └── placa_montagem_parede.stl
│
├── firmware/                              ← código ESP32
│   └── src/ ...
│
└── hardware.md                            ← este ficheiro
```

### Ferramentas recomendadas

| Tarefa | Ferramenta gratuita | Ferramenta paga |
| ------ | ------------------- | --------------- |
| Esquemático + PCB | KiCad 8, EasyEDA | Altium Designer |
| Fabricar PCB | JLCPCB, PCBWay | — |
| Modelação 3D | FreeCAD, OpenSCAD | Fusion 360 |
| Impressão 3D | Slicer: Bambu Studio, PrusaSlicer | — |
| Render fotorrealista | Blender (Cycles) | KeyShot |
| Geração de imagem IA | DALL-E 3, Stable Diffusion | Midjourney |
| IA para esquemático | ChatGPT + KiCad plugin | Altium AI |
