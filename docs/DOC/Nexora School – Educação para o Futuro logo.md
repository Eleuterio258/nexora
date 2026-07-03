# Prompts para Logo — Nexora School
**Ficheiro de referência:** `logo.svg` — Logo final aprovado  
**Marca:** Nexora School – Educação para o Futuro  
**Conceito central:** Letra "N" estilizada com recorte da silhueta de Moçambique e pixels digitais, simbolizando educação, tecnologia e identidade nacional.

---

## O que é o `logo.svg`

O ficheiro `logo.svg` contém o logotipo final da Nexora School. Não é texto — é um **símbolo/ícone puro** composto por:

1. **Letra "N" estilizada** em verde esmeralda, com cantos arredondados e efeito de sombra longa/3D no interior.
2. **Silhueta de Moçambique** recortada como espaço negativo (negative space) na parte direita vertical da letra "N".
3. **Pixels/quadrados flutuantes** em verde esmeralda, de tamanhos variados, saindo da parte superior direita da letra "N" próximo ao recorte do mapa — representando digitalização, tecnologia e inovação.
4. **Fundo transparente**.

### Paleta Real

| Elemento | Valor |
|---|---|
| Verde principal (N + pixels) | `#02AE8D` Emerald |
| Verde sombra/3D | `#047857` Emerald Dark |
| Recorte do mapa | transparente / branco (negative space) |
| Fundo | transparente ou `#FFFFFF` |

---

## PROMPT CURTO — Canva / Looka / Ideogram

```
Logo icon for "Nexora School". A bold stylized letter "N" in emerald green #02AE8D with rounded corners and a long flat shadow inside the letter. The right vertical stem of the N has a clean negative-space cutout of the Mozambique country map silhouette. Several small emerald green rounded squares (digital pixels) float above the top-right of the N, appearing to emerge from the map cutout. Transparent background. Flat vector, modern, tech-education brand, no text, no gradients, clean bezier paths.
```

---

## PROMPT MÉDIO — DALL·E 3 / Adobe Firefly / Recraft

```
Flat vector logo icon for "Nexora School – Educação para o Futuro". The symbol is a stylized uppercase letter "N" in solid emerald green #02AE8D. The N has rounded top and bottom corners and a long diagonal shadow effect inside the letter (flat 3D long shadow). On the right vertical stem of the N, create a negative-space cutout in the exact geographic silhouette shape of Mozambique — the map area should be transparent/white, not filled. Above the top-right corner of the N, add 7–9 floating rounded squares in the same emerald green #02AE8D, varying sizes (small to medium), arranged in a loose upward-right cluster like digital pixels dissolving. Transparent background. No text, no letters besides the N, no gradients, no outlines, no photorealism. Clean SVG-style vector, modern school + technology identity.
```

---

## PROMPT LONGO — Midjourney

```
flat vector logo icon for a school technology brand "Nexora School", stylized bold letter "N" as the main symbol, emerald green #02AE8D, rounded corners on all terminals, long flat shadow inside the N creating subtle 3D depth, on the right vertical stem of the N a clean negative-space cutout of the Mozambique country map silhouette, the map cutout is white/transparent, above the top-right of the N a cluster of 8 floating rounded squares in same emerald green #02AE8D like dissolving digital pixels, square sizes vary from 12px to 32px, pixels arranged in upward-right scatter, transparent background, no text, no tagline, no gradients, no glow, no outlines, no borders, clean geometric vector, app icon style, brand identity design --ar 1:1 --style raw --v 6.1
```

### Prompt Negativo — Midjourney `--no`

```
--no text, letters except N, words, typography, tagline, gradients, drop shadows, glow effects, 3D render, photorealism, photographic texture, outline stroke, multiple colors, rainbow, flag colors, vintage, ornate, complex patterns, decorative swirls, background fill
```

---

## PROMPT PARA CHATGPT / CLAUDE — GERAR CÓDIGO SVG IDÊNTICO

```
Generate clean SVG code for the Nexora School logo icon that matches EXACTLY the following description:

1. Canvas: viewBox="0 0 1024 1024", width="1024" height="1024", transparent background.
2. Main element: a stylized uppercase letter "N" in emerald green #02AE8D.
   - The N should be bold, with rounded outer corners.
   - Add a long flat shadow inside the N (use a darker emerald #047857 polygon) to create a subtle 3D effect.
3. Negative-space cutout: on the right vertical stem of the N, cut out the geographic silhouette of Mozambique. The cutout area must be transparent (no fill).
4. Pixels: above the top-right area of the N, add 7–9 floating rounded squares in #02AE8D, varying sizes (approx 30–80px), arranged in a scattered upward-right cluster like digital pixels dissolving.
5. No text, no tagline, no gradients, no filters.
6. Output only raw SVG code starting with <svg>.
```

---

## INSTRUÇÕES — Figma (Montagem Manual)

```
Passos para recriar o logo no Figma:

1. Criar frame 1024×1024px transparente.
2. Desenhar a letra "N":
   - Usar a fonte Plus Jakarta Sans ExtraBold, tamanho ~700pt, digitar "N".
   - Converter para vetor (Outline Stroke / Flatten).
   - Aplicar Fill sólido #02AE8D.
   - Arredondar cantos externos.
3. Adicionar sombra longa interna:
   - Duplicar a forma da N.
   - Criar polígono de sombra em #047857 dentro da letra, seguindo o ângulo da diagonal.
   - Usar máscara para limitar a sombra dentro da forma da N.
4. Recorte do mapa:
   - Importar a silhueta vetorial de Moçambique (mz-01.svg).
   - Posicionar sobre a haste direita da N.
   - Usar Subtract Selection para recortar a silhueta do N (negative space).
5. Pixels flutuantes:
   - Criar 7–9 quadrados com cantos arredondados (corner radius ~4px).
   - Preencher com #02AE8D.
   - Distribuir acima do canto superior direito do N, tamanhos variados.
6. Exportar como SVG (Include "id" attribute desligado se for uso final).
```

---

## INSTRUÇÕES — Adobe Illustrator

```
Passos no Adobe Illustrator para recriar o logo:

1. Criar artboard 1024×1024px.
2. Digitar "N" com Plus Jakarta Sans ExtraBold ~700pt.
3. Converter texto para outlines (Type → Create Outlines).
4. Preencher com #02AE8D, stroke None.
5. Arredondar cantos externos (Effect → Stylize → Round Corners, ~12px).
6. Criar sombra longa interna:
   - Duplicar a forma.
   - Desenhar polígono de sombra em #047857.
   - Usar Pathfinder → Intersect ou Clipping Mask para aplicar dentro do N.
7. Importar silhueta de Moçambique (mz-01.svg).
   - Escalar e posicionar sobre a haste direita do N.
   - Selecionar N + mapa → Pathfinder → Minus Front para criar o recorte.
8. Adicionar pixels:
   - Criar quadrados com cantos arredondados, variando tamanho 30–80px.
   - Preencher #02AE8D.
   - Posicionar cluster flutuante no topo direito.
9. Exportar: File → Export → Export As → SVG.
   - Preservar editing capabilities: OFF.
```

---

## VARIAÇÕES DO LOGO FINAL

### Ícone Principal — uso em app/perfil
```
Canvas 1024×1024px transparente
Elemento central: N com recorte de Moçambique + pixels
Ficheiro: logo.svg (atual)
```

### Versão em Fundo Branco
```
Mesmo símbolo sobre fundo #FFFFFF
Ficheiro: logo-white-bg.svg / logo-white-bg.png
```

### Versão em Fundo Escuro
```
Símbolo em #02AE8D sobre fundo #111827
O recorte do mapa fica na cor do fundo (#111827)
Ficheiro: logo-dark-bg.svg
```

### Versão Monocromática — impressão
```
Todo o símbolo em #111827 sobre branco
Ficheiro: logo-mono.svg
```

### Favicon / Ícone pequeno
```
Apenas a letra "N" com recorte do mapa, sem pixels (ou com 2–3 pixels)
Tamanhos: 16×16, 32×32, 48×48, 180×180
Ficheiro: favicon.ico / apple-touch-icon.png
```

---

## CHECKLIST TÉCNICA — logo.svg

### Antes de exportar
- [ ] Forma da letra "N" preenchida com `#02AE8D`
- [ ] Sombra longa interna em `#047857`
- [ ] Silhueta de Moçambique recortada como negative space
- [ ] Pixels flutuantes em `#02AE8D`, cantos arredondados
- [ ] Fundo transparente
- [ ] Sem texto, sem tagline no ícone principal

### Qualidade do ficheiro SVG
- [ ] `viewBox="0 0 1024 1024"`
- [ ] Sem `filter`, `feGaussianBlur`, ou efeitos bitmap
- [ ] Sem `linearGradient` ou `radialGradient`
- [ ] Todas as formas como paths limpos
- [ ] Testado em 16px (favicon), 64px (app bar), 512px (banner)

### Exportações finais
- [ ] `logo.svg` — ícone principal transparente
- [ ] `logo-white-bg.svg` / `.png` — fundo branco
- [ ] `logo-dark-bg.svg` — fundo escuro
- [ ] `logo-mono.svg` — monocromático
- [ ] `favicon.ico`
- [ ] `apple-touch-icon.png`
