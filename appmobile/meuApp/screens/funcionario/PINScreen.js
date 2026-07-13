import React, { useEffect, useRef, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import {
  ScrollView,
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  StatusBar,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { theme } from '../../src/theme';
import { RegistrationHistory } from '../../src/components';
import { API_BASE_URL } from '../../src/config';

export default function PINScreen({ navigation }) {
  const [pin, setPin] = useState('');
  const [secondsLeft, setSecondsLeft] = useState(30);
  const [validationState, setValidationState] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const authRef = useRef({ token: null, userId: null, employeeCode: null });

  useEffect(() => {
    AsyncStorage.multiGet(['auth.token', 'auth.user']).then((pairs) => {
      const token = pairs[0][1] || '';
      const user  = JSON.parse(pairs[1][1] || '{}');
      authRef.current = {
        token,
        userId: user?.id || null,
        employeeCode: user?.username || null,
      };
    });

    const interval = setInterval(() => {
      setSecondsLeft((current) => (current <= 1 ? 30 : current - 1));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const handlePinPress = (digit) => {
    if (pin.length < 6) {
      setPin((p) => `${p}${digit}`);
      if (validationState) setValidationState('');
    }
  };

  const handleBackspace = () => {
    setPin((p) => p.slice(0, -1));
    if (validationState) setValidationState('');
  };

  const handleConfirm = async () => {
    if (pin.length < 4) return;
    setIsSubmitting(true);
    try {
      const { employeeCode, token, userId } = authRef.current;

      // Verificar PIN via backend
      const res = await fetch(`${API_BASE_URL}/auth/login/pin`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ employee_code: employeeCode, pin }),
      });

      if (!res.ok) {
        setValidationState('PIN invalido. Tente novamente.');
        setPin('');
        return;
      }

      setValidationState('PIN validado com sucesso.');

      // Registar ponto
      await fetch(`${API_BASE_URL}/clock/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          user_id: userId,
          event_type: 'ENTRY',
          source: 'MOBILE_APP',
          recorded_at: new Date().toISOString(),
          idempotency_key: `pin-${userId}-${Date.now()}`,
        }),
      });

      navigation.navigate('Success', { method: 'pin', occurred_at: new Date().toISOString() });
    } catch (_) {
      setValidationState('Erro de ligacao. Tente novamente.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const totpCode = '483 291';
  const pinDots = Array.from({ length: 6 }, (_, index) => (index < pin.length ? '●' : '○')).join(' ');
  const otpProgressWidth = `${(secondsLeft / 30) * 100}%`;
  const isPinValid = validationState === 'PIN validado com sucesso.';

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <Text style={styles.headerTitle}>PIN / TOTP</Text>
        <Text style={styles.headerSub}>Codigo alternativo de acesso e confirmacao</Text>
      </View>

      <ScrollView style={styles.content} contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.heroCard}>
          <Text style={styles.heroEyebrow}>Autenticacao segura</Text>
          <Text style={styles.heroTitle}>Use o codigo temporario ou PIN</Text>
          <Text style={styles.heroText}>
            Ideal para quando a leitura facial, QR ou NFC nao estiver disponivel.
          </Text>

          <View style={styles.totpContainer}>
            <Text style={styles.totpLabel}>Codigo TOTP</Text>
            <Text style={styles.totpCode}>{totpCode}</Text>
            <View style={styles.totpBar}>
              <View style={[styles.totpFill, { width: otpProgressWidth }]} />
            </View>
            <Text style={styles.totpExpiry}>Expira em {secondsLeft}s</Text>
          </View>
        </View>

        <Text style={styles.orText}>Ou introduza o PIN de 4 digitos</Text>

        <View style={styles.pinDisplay}>
          <Text style={styles.pinDots}>{pinDots}</Text>
          <Text style={styles.pinHint}>PIN introduzido manualmente</Text>
        </View>

        {validationState ? (
          <View style={[styles.feedbackCard, isPinValid ? styles.feedbackSuccess : styles.feedbackError]}>
            <Text style={[styles.feedbackText, isPinValid ? styles.feedbackSuccessText : styles.feedbackErrorText]}>
              {validationState}
            </Text>
          </View>
        ) : null}

        <View style={styles.pinGrid}>
          {['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'backspace'].map((digit, index) => (
            <TouchableOpacity
              key={index}
              style={[styles.pinKey, digit === '' && styles.pinKeyEmpty]}
              onPress={() => {
                if (digit === 'backspace') {
                  handleBackspace();
                } else if (digit !== '') {
                  handlePinPress(digit);
                }
              }}
              disabled={digit === ''}
              activeOpacity={0.9}
            >
              {digit === 'backspace' ? (
                <MaterialCommunityIcons name="backspace-outline" size={18} color={theme.colors.text} />
              ) : (
                <Text style={styles.pinKeyText}>{digit}</Text>
              )}
            </TouchableOpacity>
          ))}
        </View>

        <TouchableOpacity
          style={[styles.confirmButton, (pin.length < 4 || isSubmitting) && styles.confirmButtonDisabled]}
          activeOpacity={0.9}
          disabled={pin.length < 4 || isSubmitting}
          onPress={handleConfirm}
        >
          <Text style={styles.confirmButtonText}>{isSubmitting ? 'A verificar…' : 'Confirmar registo'}</Text>
        </TouchableOpacity>

        <RegistrationHistory items={registrationHistory} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.surface,
  },
  content: {
    flex: 1,
    backgroundColor: theme.colors.surface,
  },
  header: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  headerSub: {
    fontSize: 12,
    color: theme.colors.muted,
    marginTop: 2,
  },
  body: {
    flexGrow: 1,
    padding: 16,
    paddingBottom: 32,
    alignItems: 'center',
  },
  heroCard: {
    width: '100%',
    backgroundColor: theme.colors.surface2,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 18,
    marginBottom: 16,
  },
  heroEyebrow: {
    fontSize: 11,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  heroTitle: {
    marginTop: 4,
    fontSize: 18,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  heroText: {
    marginTop: 6,
    fontSize: 12,
    color: theme.colors.muted,
    lineHeight: 18,
  },
  totpContainer: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: theme.colors.border,
    marginTop: 16,
    width: '100%',
  },
  totpLabel: {
    fontSize: 11,
    color: theme.colors.muted,
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  totpCode: {
    fontSize: 28,
    fontWeight: theme.fontWeight.semibold,
    letterSpacing: 8,
    color: theme.colors.text,
    fontFamily: 'monospace',
    marginBottom: 8,
  },
  totpBar: {
    width: '100%',
    height: 5,
    backgroundColor: theme.colors.border,
    borderRadius: 999,
    overflow: 'hidden',
    marginBottom: 6,
  },
  totpFill: {
    height: '100%',
    backgroundColor: theme.colors.green,
    borderRadius: 999,
  },
  totpExpiry: {
    fontSize: 11,
    color: theme.colors.muted,
  },
  orText: {
    fontSize: 12,
    color: theme.colors.muted,
    marginBottom: 12,
    textAlign: 'center',
  },
  pinDisplay: {
    width: '100%',
    backgroundColor: theme.colors.surface2,
    borderRadius: 16,
    paddingVertical: 16,
    paddingHorizontal: 24,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: theme.colors.border,
    alignItems: 'center',
  },
  pinDots: {
    fontSize: 22,
    letterSpacing: 8,
    color: theme.colors.text,
  },
  pinHint: {
    marginTop: 6,
    fontSize: 11,
    color: theme.colors.muted,
  },
  feedbackCard: {
    width: '100%',
    borderRadius: 14,
    borderWidth: 1,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 16,
  },
  feedbackSuccess: {
    backgroundColor: theme.colors.greenDim,
    borderColor: theme.colors.greenBorder,
  },
  feedbackError: {
    backgroundColor: theme.colors.redDim,
    borderColor: theme.colors.redBorder,
  },
  feedbackText: {
    fontSize: 12,
    fontWeight: theme.fontWeight.medium,
  },
  feedbackSuccessText: {
    color: theme.colors.green,
  },
  feedbackErrorText: {
    color: theme.colors.red,
  },
  pinGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    width: '100%',
    maxWidth: 260,
    gap: 8,
  },
  pinKey: {
    flex: 1,
    minWidth: 68,
    backgroundColor: theme.colors.surface2,
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  pinKeyEmpty: {
    backgroundColor: 'transparent',
    borderWidth: 0,
  },
  pinKeyText: {
    fontSize: 16,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  confirmButton: {
    width: '100%',
    backgroundColor: theme.colors.accent,
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 16,
    marginBottom: 20,
  },
  confirmButtonDisabled: {
    opacity: 0.45,
  },
  confirmButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
  },
});
