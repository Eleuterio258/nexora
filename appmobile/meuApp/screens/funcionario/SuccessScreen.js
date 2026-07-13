import React from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  StatusBar,
} from 'react-native';
import { theme } from '../../src/theme';

export default function SuccessScreen({ navigation, route }) {
  const {
    employee_name = 'Funcionario',
    employee_code = '',
    confidence = 0,
    record_type = 'entry',
    method = 'facial',
    occurred_at,
  } = route?.params ?? {};

  const timeStr = occurred_at
    ? new Date(occurred_at).toLocaleTimeString('pt-MZ', { hour: '2-digit', minute: '2-digit' })
    : new Date().toLocaleTimeString('pt-MZ', { hour: '2-digit', minute: '2-digit' });

  const recordLabel = record_type === 'entry' ? 'Entrada' : 'Saida';
  const methodLabels = { facial: 'Facial', nfc: 'NFC', qr: 'QR Code', pin: 'PIN', selfie: 'Selfie + GPS' };
  const methodLabel = methodLabels[method] ?? method;
  const pctLabel = confidence > 0 ? `${Math.round(confidence * 100)}%` : 'Confirmado';

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.body}>
        <View style={styles.heroCard}>
          <View style={styles.successIconWrap}>
            <MaterialCommunityIcons name="check-circle" size={72} color={theme.colors.success} />
          </View>

          <Text style={styles.successEyebrow}>Registo concluido</Text>
          <Text style={styles.successTitle}>Presenca registada com sucesso</Text>
          <Text style={styles.successSub}>
            {timeStr} · {recordLabel} · {methodLabel}
          </Text>

          <View style={styles.metricRow}>
            <View style={styles.metricCard}>
              <Text style={[styles.metricValue, { color: theme.colors.green }]}>{pctLabel}</Text>
              <Text style={styles.metricLabel}>Confianca</Text>
            </View>
            <View style={styles.metricCard}>
              <Text style={styles.metricValue}>{recordLabel}</Text>
              <Text style={styles.metricLabel}>Tipo</Text>
            </View>
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardLabel}>Funcionario</Text>
          <Text style={styles.cardTitle}>{employee_name}</Text>
          {employee_code ? <Text style={styles.cardSub}>Codigo: {employee_code}</Text> : null}
          <Text style={styles.cardMeta}>Metodo usado: {methodLabel}</Text>
        </View>

        <TouchableOpacity style={styles.buttonPrimary} onPress={() => navigation.navigate('HomeFunc')} activeOpacity={0.9}>
          <Text style={styles.buttonPrimaryText}>Voltar ao inicio</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.buttonOutline} onPress={() => navigation.navigate('Historico')} activeOpacity={0.9}>
          <Text style={styles.buttonOutlineText}>Ver historico</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.surface,
  },
  body: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
  },
  heroCard: {
    backgroundColor: theme.colors.surface2,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 22,
    alignItems: 'center',
    marginBottom: 16,
  },
  successIconWrap: {
    marginBottom: 16,
  },
  successEyebrow: {
    fontSize: 11,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  successTitle: {
    fontSize: 22,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginTop: 6,
    textAlign: 'center',
  },
  successSub: {
    fontSize: 13,
    color: theme.colors.muted,
    marginTop: 8,
    textAlign: 'center',
  },
  metricRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 18,
    width: '100%',
  },
  metricCard: {
    flex: 1,
    backgroundColor: theme.colors.surface,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: 12,
    paddingHorizontal: 12,
  },
  metricValue: {
    fontSize: 18,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
  },
  metricLabel: {
    marginTop: 3,
    fontSize: 12,
    color: theme.colors.muted,
  },
  card: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: theme.colors.border,
    marginBottom: 16,
  },
  cardLabel: {
    fontSize: 11,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginTop: 4,
  },
  cardSub: {
    fontSize: 12,
    color: theme.colors.muted,
    marginTop: 6,
  },
  cardMeta: {
    fontSize: 12,
    color: theme.colors.muted,
    marginTop: 2,
  },
  buttonPrimary: {
    backgroundColor: theme.colors.accent,
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
    marginBottom: 10,
  },
  buttonPrimaryText: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: '#FFFFFF',
  },
  buttonOutline: {
    paddingVertical: 14,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    alignItems: 'center',
  },
  buttonOutlineText: {
    fontSize: 14,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
});
