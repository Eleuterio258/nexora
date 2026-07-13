import React, { useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  StatusBar,
  ScrollView,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';

export default function ForgotPasswordScreen({ navigation }) {
  const [identifier, setIdentifier] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleRecover = async () => {
    if (!identifier.trim()) {
      Alert.alert('Campo obrigatorio', 'Informe o email ou utilizador associado a conta.');
      return;
    }

    setIsSubmitting(true);

    try {
      await new Promise((resolve) => setTimeout(resolve, 800));
      Alert.alert(
        'Pedido registado',
        'Se a conta existir, recebera instrucoes de recuperacao no canal configurado.',
        [
          {
            text: 'Voltar ao login',
            onPress: () => navigation.goBack(),
          },
        ]
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.sidebarStart} />

      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.heroSection}>
          <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
            <MaterialCommunityIcons name="arrow-left" size={18} color="#FFFFFF" />
            <Text style={styles.backButtonText}>Voltar</Text>
          </TouchableOpacity>

          <View style={styles.heroBadge}>
            <Text style={styles.heroBadgeText}>RECUPERACAO DE ACESSO</Text>
          </View>

          <Text style={styles.heroTitle}>Esqueceu a senha?</Text>
          <Text style={styles.heroSubtitle}>
            Informe o email ou utilizador para iniciar a recuperacao do acesso.
          </Text>
        </View>

        <View style={styles.formShell}>
          <View style={styles.infoCard}>
            <MaterialCommunityIcons
              name="shield-lock-outline"
              size={20}
              color={theme.colors.sidebarAccent}
            />
            <Text style={styles.infoCardText}>
              Enviaremos instrucoes para o canal associado a sua conta, quando disponivel.
            </Text>
          </View>

          <View style={styles.inputBlock}>
            <Text style={styles.inputLabel}>Email ou utilizador</Text>
            <View style={styles.inputContainer}>
              <MaterialCommunityIcons
                name="account-circle-outline"
                size={18}
                color={theme.colors.muted}
                style={styles.inputIcon}
              />
              <TextInput
                style={styles.input}
                placeholder="exemplo@empresa.com"
                placeholderTextColor={theme.colors.muted}
                value={identifier}
                onChangeText={setIdentifier}
                autoCapitalize="none"
                keyboardType="email-address"
              />
            </View>
          </View>

          <TouchableOpacity
            style={[styles.buttonPrimary, isSubmitting && styles.buttonPrimaryDisabled]}
            onPress={handleRecover}
            disabled={isSubmitting}
          >
            <Text style={styles.buttonPrimaryText}>
              {isSubmitting ? 'A processar...' : 'Recuperar senha'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.secondaryAction} onPress={() => navigation.goBack()}>
            <Text style={styles.secondaryActionText}>Lembrei da senha</Text>
          </TouchableOpacity>
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
  scrollContent: {
    flexGrow: 1,
  },
  heroSection: {
    paddingHorizontal: 24,
    paddingTop: 24,
    paddingBottom: 28,
    backgroundColor: theme.colors.sidebarStart,
  },
  backButton: {
    alignSelf: 'flex-start',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 18,
  },
  backButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: theme.fontWeight.medium,
  },
  heroBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.18)',
    marginBottom: 18,
  },
  heroBadgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: theme.fontWeight.semibold,
    letterSpacing: 1,
  },
  heroTitle: {
    color: '#FFFFFF',
    fontSize: 28,
    lineHeight: 34,
    fontWeight: theme.fontWeight.bold,
    marginBottom: 10,
  },
  heroSubtitle: {
    color: 'rgba(255,255,255,0.78)',
    fontSize: 14,
    lineHeight: 21,
  },
  formShell: {
    flex: 1,
    marginTop: -12,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    backgroundColor: theme.colors.surface,
    paddingHorizontal: 24,
    paddingTop: 24,
    paddingBottom: 28,
  },
  infoCard: {
    flexDirection: 'row',
    gap: 12,
    padding: 14,
    borderRadius: 16,
    backgroundColor: theme.colors.blueDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
    marginBottom: 22,
  },
  infoCardText: {
    flex: 1,
    color: theme.colors.text,
    fontSize: 13,
    lineHeight: 19,
  },
  inputBlock: {
    marginBottom: 16,
  },
  inputLabel: {
    fontSize: 13,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
    marginBottom: 8,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface2,
    borderRadius: 12,
    paddingHorizontal: 14,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  inputIcon: {
    marginRight: 10,
  },
  input: {
    flex: 1,
    paddingVertical: 14,
    fontSize: 14,
    color: theme.colors.text,
  },
  buttonPrimary: {
    marginTop: 8,
    backgroundColor: theme.colors.sidebarAccent,
    borderRadius: 14,
    paddingVertical: 15,
    alignItems: 'center',
    shadowColor: theme.colors.sidebarAccent,
    shadowOpacity: 0.22,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 8 },
    elevation: 4,
  },
  buttonPrimaryDisabled: {
    opacity: 0.7,
  },
  buttonPrimaryText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
  },
  secondaryAction: {
    marginTop: 16,
    alignItems: 'center',
  },
  secondaryActionText: {
    color: theme.colors.sidebarAccent,
    fontSize: 13,
    fontWeight: theme.fontWeight.medium,
  },
});
