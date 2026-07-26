# Configuração de Publicação na Play Store

Arquivo central para gerenciar as configurações de build e publicação do app **Nexora Recrutamento**.

---

## 1. Versão do App

Arquivo: [`android/app/build.gradle.kts`](android/app/build.gradle.kts)

Localize o bloco `defaultConfig`:

```kotlin
versionCode = 2
versionName = "1.0.1"
```

| Parte | Significado | Regra |
|---|---|---|
| `"1.0.1"` | `versionName` | Versão visível ao usuário. Use semântica: `MAJOR.MINOR.PATCH`. |
| `2` | `versionCode` | Número inteiro obrigatório e **sempre crescente** na Play Store. |

### Exemplos de atualização
- Correção de bug: `versionCode = 2` / `versionName = "1.0.1"` → `versionCode = 3` / `versionName = "1.0.2"`
- Nova funcionalidade: → `versionCode = 3` / `versionName = "1.1.0"`
- Grande release: → `versionCode = 3` / `versionName = "2.0.0"`

> ⚠️ **Atenção:** a Play Store rejeita se o `versionCode` não for maior que o anterior.

---

## 2. Versões do Android (SDK)

Arquivo: [`android/app/build.gradle.kts`](android/app/build.gradle.kts)

Localize o bloco `defaultConfig`:

```kotlin
defaultConfig {
    applicationId = "tech.e258tech.nexora_recrutamento"
    minSdk = 24
    targetSdk = 35
    versionCode = 2
    versionName = "1.0.1"
}
```

### Opção recomendada: deixar o Flutter decidir
```kotlin
minSdk = flutter.minSdkVersion
targetSdk = flutter.targetSdkVersion
```

### Opção fixa (se precisar forçar)
```kotlin
minSdk = 24       // Android 7.0 (API 24)
targetSdk = 34    // Android 14 (API 34)
```

> 💡 Regra da Play Store: o `targetSdkVersion` deve atender ao requisito mínimo exigido pelo Google. Manter o Flutter atualizado (`flutter upgrade`) garante isso automaticamente.

---

## 3. Nome e ID do App

| Configuração | Valor atual | Arquivo |
|---|---|---|
| Nome visível | `Nexora Rec` | [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) (`android:label`) |
| Application ID | `tech.e258tech.nexora_recrutamento` | [`android/app/build.gradle.kts`](android/app/build.gradle.kts) (`applicationId`) |

> ⚠️ **NUNCA mude o `applicationId` depois de publicado**, senão a Play Store tratará como um app novo.

---

## 4. Keystore de Assinatura

Arquivos:
- Keystore: [`android/app/keystore/nexora_recrutamento.keystore`](android/app/keystore/nexora_recrutamento.keystore)
- Configuração: [`android/app/keystore/keystore.properties`](android/app/keystore/keystore.properties)

```properties
storePassword=0OfRZ5fjgyKEojOj
keyPassword=0OfRZ5fjgyKEojOj
keyAlias=nexora_key
storeFile=keystore/nexora_recrutamento.keystore
```

> 🔐 **BACKUP OBRIGATÓRIO:** guarde o arquivo `.keystore` e a senha em local seguro. Sem eles, você não conseguirá atualizar o app na Play Store.

---

## 5. Gerar o Pacote para a Play Store

Após alterar a versão, execute:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

O arquivo gerado estará em:

```
build/app/outputs/bundle/release/app-release.aab
```

Faça o upload deste arquivo `.aab` no **Google Play Console**.

---

## 6. Checklist antes de publicar

- [ ] Versão atualizada no `android/app/build.gradle.kts` (`versionCode` e `versionName`)
- [ ] `flutter build appbundle --release` executado sem erros
- [ ] Arquivo `app-release.aab` gerado
- [ ] Ícones e splash screen atualizados (se houver mudança visual)
- [ ] Testes realizados em modo release
- [ ] Keystore e senhas em local seguro

---

## 7. Comandos úteis

```bash
# Ver versão atual
flutter --version

# Ver dependências desatualizadas
flutter pub outdated

# Limpar cache
flutter clean

# Build de release
flutter build appbundle --release
```
