import React, { useMemo, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { Button } from '../../src/components';

export default function JustificarScreen({ navigation, route }) {
  const day = route?.params?.day || 'Hoje';
  const status = route?.params?.status || 'late';
  const time = route?.params?.time || '--:--';
  const presetReason = route?.params?.reason || '';

  const [attachmentName, setAttachmentName] = useState('');
  const [reason, setReason] = useState(presetReason);

  const isAbsence = status === 'absence';
  const title = isAbsence ? 'Justificar Falta' : 'Justificar Atraso';
  const badgeLabel = isAbsence ? 'Falta' : 'Atraso';
  const tone = isAbsence
    ? { bg: theme.colors.redDim, border: theme.colors.redBorder, color: theme.colors.red }
    : { bg: theme.colors.amberDim, border: theme.colors.amberBorder, color: theme.colors.amber };

  const checklist = useMemo(
    () => [
      'Explique o motivo com contexto suficiente para analise.',
      'Anexe comprovativo quando existir suporte documental.',
      'A resposta do gestor sera enviada na area de notificacoes.',
    ],
    []
  );

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={20} color={theme.colors.text} />
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>{title}</Text>
          <Text style={styles.headerSub}>Envie a justificacao para analise do gestor</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={[styles.occurrenceCard, { backgroundColor: tone.bg, borderColor: tone.border }]}>
          <View style={styles.occurrenceHead}>
            <View style={styles.occurrenceIcon}>
              <MaterialCommunityIcons
                name={isAbsence ? 'alert-circle-outline' : 'clock-alert-outline'}
                size={20}
                color={tone.color}
              />
            </View>
            <View style={styles.occurrenceInfo}>
              <Text style={styles.occurrenceTitle}>Ocorrencia registada</Text>
              <Text style={styles.occurrenceMeta}>{day} · {time}</Text>
            </View>
            <View style={[styles.occurrenceBadge, { backgroundColor: theme.colors.surface, borderColor: tone.border }]}>
              <Text style={[styles.occurrenceBadgeText, { color: tone.color }]}>{badgeLabel}</Text>
            </View>
          </View>
          <Text style={styles.occurrenceHint}>
            Anexe um comprovativo ou escreva o motivo com detalhe suficiente para validacao.
          </Text>
        </View>

        <View style={styles.checklistCard}>
          <Text style={styles.sectionTitle}>Antes de enviar</Text>
          {checklist.map((item) => (
            <View key={item} style={styles.checklistRow}>
              <MaterialCommunityIcons name="check-circle-outline" size={16} color={theme.colors.green} />
              <Text style={styles.checklistText}>{item}</Text>
            </View>
          ))}
        </View>

        <Text style={styles.formLabel}>Motivo da justificacao</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          value={reason}
          onChangeText={setReason}
          placeholder="Explique o motivo da falta ou atraso"
          placeholderTextColor={theme.colors.muted}
          multiline
          textAlignVertical="top"
        />

        <Text style={styles.formLabel}>Arquivo de suporte</Text>
        <TouchableOpacity
          style={styles.uploadButton}
          onPress={() => setAttachmentName('comprovativo.pdf')}
          activeOpacity={0.9}
        >
          <View style={styles.uploadIconWrap}>
            <MaterialCommunityIcons name="paperclip" size={18} color={theme.colors.accent} />
          </View>
          <View style={styles.uploadInfo}>
            <Text style={styles.uploadTitle}>Anexar comprovativo</Text>
            <Text style={styles.uploadMeta}>
              {attachmentName || 'Selecione um documento de suporte'}
            </Text>
          </View>
          <MaterialCommunityIcons name="upload" size={18} color={theme.colors.muted} />
        </TouchableOpacity>

        <Button label="Enviar justificacao" onPress={() => {}} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.surface,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 14,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  headerInfo: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  headerSub: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
  body: {
    padding: 16,
    paddingBottom: 24,
  },
  occurrenceCard: {
    borderWidth: 1,
    borderRadius: 16,
    padding: 16,
    marginBottom: 14,
  },
  occurrenceHead: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  occurrenceIcon: {
    width: 42,
    height: 42,
    borderRadius: 12,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
  },
  occurrenceInfo: {
    flex: 1,
  },
  occurrenceTitle: {
    fontSize: 15,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  occurrenceMeta: {
    marginTop: 4,
    fontSize: 12,
    color: theme.colors.muted,
  },
  occurrenceBadge: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
  },
  occurrenceBadgeText: {
    fontSize: 11,
    fontWeight: theme.fontWeight.semibold,
    textTransform: 'uppercase',
  },
  occurrenceHint: {
    marginTop: 12,
    fontSize: 12,
    color: theme.colors.text,
    lineHeight: 18,
  },
  checklistCard: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 16,
    marginBottom: 14,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginBottom: 10,
  },
  checklistRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
    marginBottom: 8,
  },
  checklistText: {
    flex: 1,
    fontSize: 12,
    color: theme.colors.text,
    lineHeight: 18,
  },
  formLabel: {
    fontSize: 12,
    color: theme.colors.muted,
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 14,
    color: theme.colors.text,
    marginBottom: 14,
  },
  textArea: {
    minHeight: 120,
  },
  uploadButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 14,
    padding: 14,
    marginBottom: 14,
  },
  uploadIconWrap: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  uploadInfo: {
    flex: 1,
  },
  uploadTitle: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  uploadMeta: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
});
