# Guia de Uniformização do Layout

## 📐 Estrutura de Tema e Componentes

O aplicativo Omnisys ERP foi uniformizado usando um sistema de tema e componentes compartilhados para garantir consistência visual em todas as telas.

### 📂 Estrutura de Arquivos

```
meuApp/
├── src/
│   ├── theme/
│   │   └── index.js              # Tema global (cores, espaçamentos, tipografia)
│   └── components/
│       ├── index.js              # Exportação de todos os componentes
│       ├── AppHeader.js          # Header padrão
│       ├── StatCard.js           # Card de estatística
│       ├── Badge.js              # Badge de status
│       ├── Button.js             # Botão reutilizável
│       ├── SectionLabel.js       # Label de seção
│       └── EventItem.js          # Item de evento
├── screens/                      # Todas as telas do app
└── App.js                        # Configuração da navegação
```

## 🎨 Tema Global

### Cores

Todas as cores são definidas em `src/theme/index.js`:

```javascript
import { theme } from '../src/theme';

// Uso em componentes:
backgroundColor: theme.colors.bg
color: theme.colors.green
borderColor: theme.colors.border
```

**Paleta de Cores:**

| Nome | Valor | Uso |
|------|-------|-----|
| `bg` | `#0f1117` | Background principal |
| `surface` | `#171b24` | Superfície primária |
| `surface2` | `#1e2330` | Superfície secundária |
| `border` | `rgba(255,255,255,0.07)` | Bordas sutis |
| `border2` | `rgba(255,255,255,0.12)` | Bordas mais visíveis |
| `text` | `#e8eaf0` | Texto principal |
| `muted` | `#6b7280` | Texto secundário |
| `green` | `#1fd898` | Sucesso/OK |
| `red` | `#ff5c6a` | Erro/Ausente |
| `amber` | `#f5a623` | Aviso/Atraso |
| `blue` | `#4e8ef7` | Info/Saída |
| `accent` | `#1fd898` | Cor de destaque |

### Espaçamentos

```javascript
theme.spacing.xs    // 4px
theme.spacing.sm    // 6px
theme.spacing.md    // 8px
theme.spacing.base  // 10px
theme.spacing.lg    // 12px
theme.spacing.xl    // 14px
theme.spacing['2xl'] // 16px
theme.spacing['3xl'] // 20px
```

### Border Radius

```javascript
theme.borderRadius.sm    // 6px
theme.borderRadius.base  // 10px
theme.borderRadius.lg    // 14px
theme.borderRadius.xl    // 20px
theme.borderRadius.full  // 9999 (círculo)
```

### Tipografia

```javascript
theme.fontSize.xs     // 9px
theme.fontSize.sm     // 10px
theme.fontSize.base   // 11px
theme.fontSize.md     // 12px
theme.fontSize.lg     // 13px
theme.fontSize.xl     // 16px
theme.fontSize['2xl'] // 20px
theme.fontSize['3xl'] // 26px

theme.fontWeight.normal   // '400'
theme.fontWeight.medium   // '500'
theme.fontWeight.semibold // '600'
```

## 🧩 Componentes Reutilizáveis

### 1. AppHeader

Header padrão para todas as telas.

```jsx
import { AppHeader } from '../src/components';

<AppHeader
  title="Dashboard"
  subtitle="Turno manhã · 08h–17h"
  rightContent={<View>...</View>}  // opcional
/>
```

### 2. StatCard

Card de estatística para grids.

```jsx
import { StatCard } from '../src/components';

<StatCard
  value="47"
  label="Presentes"
  color="green"  // green, red, amber, blue, text
  onPress={() => navigation.navigate('Equipa')}  // opcional
/>
```

### 3. Badge

Badge de status colorido.

```jsx
import { Badge } from '../src/components';

<Badge
  label="OK"
  variant="success"  // success, danger, warning, info, default
/>
```

### 4. Button

Botão primário ou outline.

```jsx
import { Button } from '../src/components';

<Button
  label="Confirmar registo"
  onPress={handleSubmit}
  variant="primary"  // primary, outline
/>
```

### 5. SectionLabel

Label para seções.

```jsx
import { SectionLabel } from '../src/components';

<SectionLabel>Eventos recentes</SectionLabel>
```

### 6. EventItem

Item de evento para listas.

```jsx
import { EventItem } from '../src/components';

<EventItem
  name="Carlos Nhaca"
  meta="09:38 · Entrada · Facial · 93%"
  status="ok"  // ok, late, absent, exit
  onPress={() => navigation.navigate('Detalhe')}
/>
```

## 📋 Como Atualizar Telas Existentes

### Antes (código duplicado):

```jsx
const styles = StyleSheet.create({
  header: {
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.07)',
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#e8eaf0',
  },
});
```

### Depois (usando tema):

```jsx
import { theme } from '../src/theme';
import { AppHeader } from '../src/components';

// No render:
<AppHeader title="Dashboard" subtitle="Turno manhã · 08h–17h" />

// Styles simplificados:
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg,
  },
});
```

## ✅ Checklist de Uniformização

### Para cada tela:

- [ ] Importar tema: `import { theme } from '../src/theme';`
- [ ] Usar `AppHeader` em vez de header customizado
- [ ] Usar `StatCard` para cards de estatísticas
- [ ] Usar `Badge` para status
- [ ] Usar `Button` para botões
- [ ] Usar `SectionLabel` para labels de seção
- [ ] Usar `EventItem` para listas de eventos
- [ ] Usar cores do tema: `theme.colors.*`
- [ ] Usar espaçamentos do tema: `theme.spacing.*`
- [ ] Usar border radius do tema: `theme.borderRadius.*`
- [ ] Usar tipografia do tema: `theme.fontSize.*`, `theme.fontWeight.*`

## 🎯 Benefícios da Uniformização

1. **Consistência Visual**: Todas as telas seguem o mesmo design system
2. **Manutenção Fácil**: Alterar o tema atualiza todas as telas automaticamente
3. **Código Limpo**: Menos duplicação de estilos
4. **Escalabilidade**: Fácil adicionar novas telas seguindo o padrão
5. **Performance**: Componentes otimizados e reutilizados

## 🚀 Próximos Passos

Para completar a uniformização:

1. **Atualizar telas restantes** do funcionário com o tema escuro
2. **Criar mais componentes** conforme necessário (Card, Input, etc)
3. **Adicionar Dark Mode toggle** para app do funcionário
4. **Documentar novos componentes** conforme forem criados

## 📝 Exemplo Completo

```jsx
import React from 'react';
import { View, Text, ScrollView, StyleSheet, SafeAreaView, StatusBar } from 'react-native';
import { theme } from '../src/theme';
import { AppHeader, StatCard, SectionLabel, EventItem, Button } from '../src/components';

export default function ExemploScreen({ navigation }) {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.bg} />
      
      <AppHeader title="Exemplo" subtitle="Descrição da tela" />

      <ScrollView style={styles.content}>
        <View style={styles.body}>
          <StatCard value="47" label="Presentes" color="green" />
          
          <SectionLabel>Lista de eventos</SectionLabel>
          
          <EventItem
            name="João Silva"
            meta="08:00 · Entrada · Facial"
            status="ok"
          />
          
          <Button label="Acção" onPress={() => {}} variant="primary" />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg,
  },
  content: {
    flex: 1,
  },
  body: {
    padding: theme.spacing['2xl'],
  },
});
```

## 🔗 Referências

- **Tema**: `src/theme/index.js`
- **Componentes**: `src/components/`
- **Protótipo**: `gestor_app.html`

---

**Versão**: 1.0  
**Última atualização**: Abril 2026
