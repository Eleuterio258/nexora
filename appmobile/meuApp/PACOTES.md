# Pacotes Instalados

## 📦 Dependências de Produção

### Core React & React Native
| Pacote | Versão | Descrição |
|--------|--------|-----------|
| `react` | 19.1.0 | Biblioteca principal do React |
| `react-native` | 0.81.5 | Framework principal do app |
| `expo` | ~54.0.33 | SDK do Expo |

### Navegação
| Pacote | Versão | Descrição |
|--------|--------|-----------|
| `@react-navigation/native` | ^7.2.2 | Navegação principal |
| `@react-navigation/native-stack` | ^7.14.10 | Stack Navigator |
| `react-native-screens` | ^4.24.0 | Otimização de telas |
| `react-native-safe-area-context` | ^5.7.0 | Áreas seguras |

### APIs do Expo
| Pacote | Versão | Descrição |
|--------|--------|-----------|
| `expo-camera` | ~17.0.10 | Câmera para biometria facial e QR |
| `expo-location` | ~19.0.8 | GPS para validação de presença |
| `expo-image-picker` | ~17.0.10 | Seleção de imagens |
| `expo-font` | ~14.0.11 | Fontes customizadas |
| `expo-haptics` | ~15.0.8 | Feedback tátil |
| `expo-status-bar` | ~3.0.9 | Barra de status |

### Armazenamento
| Pacote | Versão | Descrição |
|--------|--------|-----------|
| `@react-native-async-storage/async-storage` | 2.2.0 | Armazenamento local (tokens, prefs) |

## 🛠️ Dependências de Desenvolvimento

| Pacote | Versão | Descrição |
|--------|--------|-----------|
| `eslint` | ^10.2.0 | Linter para qualidade do código |
| `prettier` | ^3.8.1 | Formatador de código |

## 📋 Scripts Disponíveis

```bash
# Iniciar servidor de desenvolvimento
npm start

# Abrir no Android
npm run android

# Abrir no iOS
npm run ios

# Abrir no navegador (web)
npm run web

# Limpar cache e reiniciar
npm run clear

# Verificar erros de lint
npm run lint

# Formatar código
npm run format
```

## 🎯 Uso das APIs

### Câmera (expo-camera)
Usada para:
- Biometria facial
- Leitura de QR Code
- Selfie + GPS

### Localização (expo-location)
Usada para:
- Validação de perímetro GPS
- Selfie + GPS

### AsyncStorage
Usado para:
- Armazenar token JWT
- Preferências do usuário
- Cache offline

### Haptics
Usado para:
- Feedback tátil ao registrar presença
- Feedback em botões importantes

## 📊 Total de Pacotes

- **Produção**: 14 pacotes
- **Desenvolvimento**: 2 pacotes
- **Total**: 16 pacotes

---

**Última atualização**: Abril 2026  
**SDK Expo**: 54.0.33
