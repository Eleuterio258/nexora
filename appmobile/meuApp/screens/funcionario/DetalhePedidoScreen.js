import React from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { Button } from '../../src/components';

const typeIcons = {
  'Ferias anuais': 'palm-tree',
  'Férias anuais': 'palm-tree',
  Dispensa: 'calendar-remove-outline',
  'Licenca pessoal': 'account-heart-outline',
  'Licença pessoal': 'account-heart-outline',
};

const statusToneMap = {
  Pendente: {
    bg: theme.colors.infoDim,
    border: theme.colors.blueBorder,
    text: theme.colors.accent,
  },
  Aprovado: {
    bg: theme.colors.successLight || theme.colors.infoDim,
    border: theme.colors.success,
    text: theme.colors.success,
  },
  'Em revisao': {
    bg: theme.colors.surface2,
    border: theme.colors.border2,
    text: theme.colors.text,
  },
  'Em revisão': {
    bg: theme.colors.surface2,
    border: theme.colors.border2,
    text: theme.colors.text,
  },
};

export default function DetalhePedidoScreen({ navigation, route }) {
  const request = route?.params?.request || {};
  const type = request.type || 'Pedido';
  const status = request.status || 'Pendente';
  const statusTone = statusToneMap[status] || statusToneMap.Pendente;
  const typeIcon = typeIcons[type] || 'file-document-outline';

  const requestInfo = [
    { label: 'Periodo', value: request.period || '--' },
    { label: 'Estado', value: status },
    { label: 'Dias', value: request.daysLabel || request.detail || '--' },
    { label: 'Submetido em', value: request.submittedAt || 'Hoje, 08:16' },
  ];

  const timeline = request.timeline || [
    { title: 'Pedido submetido', meta: 'Aguardando analise do gestor' },
    { title: 'Validacao da equipa', meta: 'Cobertura interna ainda por confirmar' },
    { title: 'Resposta final', meta: 'Sera atualizada apos decisao' },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={20} color={theme.colors.text} />
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>Detalhe do pedido</Text>
          <Text style={styles.headerSub}>Ferias, dispensa ou licenca pessoal</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.heroCard}>
          <View style={styles.heroIcon}>
            <MaterialCommunityIcons name={typeIcon} size={22} color={theme.colors.accent} />
          </View>
          <View style={styles.heroContent}>
            <Text style={styles.heroType}>{type}</Text>
            <Text style={styles.heroMeta}>{request.employeeName || 'Seu pedido registado'}</Text>
          </View>
          <View style={[styles.statusBadge, { backgroundColor: statusTone.bg, borderColor: statusTone.border }]}>
            <Text style={[styles.statusBadgeText, { color: statusTone.text }]}>{status}</Text>
          </View>
        </View>

        <View style={styles.sectionCard}>
          <Text style={styles.sectionTitle}>Resumo</Text>
          {requestInfo.map((item) => (
            <View key={item.label} style={styles.infoRow}>
              <Text style={styles.infoLabel}>{item.label}</Text>
              <Text style={styles.infoValue}>{item.value}</Text>
            </View>
          ))}
        </View>

        <View style={styles.sectionCard}>
          <Text style={styles.sectionTitle}>Justificacao</Text>
          <Text style={styles.paragraphText}>
            {request.reason || request.detail || 'Pedido submetido para aprovacao do gestor.'}
          </Text>
        </View>

        <View style={styles.sectionCard}>
          <Text style={styles.sectionTitle}>Documento de suporte</Text>
          <View style={styles.fileRow}>
            <View style={styles.fileIcon}>
              <MaterialCommunityIcons name="paperclip" size={18} color={theme.colors.accent} />
            </View>
            <View style={styles.fileInfo}>
              <Text style={styles.fileName}>{request.attachmentName || 'Sem arquivo anexado'}</Text>
              <Text style={styles.fileMeta}>
                {request.attachmentName ? 'Anexo enviado com o pedido' : 'Nenhum documento associado'}
              </Text>
            </View>
          </View>
        </View>

        <View style={styles.sectionCard}>
          <Text style={styles.sectionTitle}>Andamento</Text>
          {timeline.map((item, index) => (
            <View key={`${item.title}-${index}`} style={styles.timelineRow}>
              <View style={styles.timelineDot} />
              <View style={styles.timelineContent}>
                <Text style={styles.timelineTitle}>{item.title}</Text>
                <Text style={styles.timelineMeta}>{item.meta}</Text>
              </View>
            </View>
          ))}
        </View>

        <Button label="Editar pedido" onPress={() => navigation.navigate('SolicitarFeriasForm', { requestType: type, reason: request.reason })} />
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
  heroCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
  },
  heroIcon: {
    width: 46,
    height: 46,
    borderRadius: 14,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroContent: {
    flex: 1,
  },
  heroType: {
    fontSize: 15,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  heroMeta: {
    marginTop: 4,
    fontSize: 12,
    color: theme.colors.muted,
  },
  statusBadge: {
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  statusBadgeText: {
    fontSize: 11,
    fontWeight: theme.fontWeight.semibold,
  },
  sectionCard: {
    backgroundColor: theme.colors.surface,
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
    marginBottom: 12,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 12,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  infoLabel: {
    fontSize: 12,
    color: theme.colors.muted,
  },
  infoValue: {
    flex: 1,
    textAlign: 'right',
    fontSize: 13,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  paragraphText: {
    fontSize: 13,
    lineHeight: 20,
    color: theme.colors.text,
  },
  fileRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  fileIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  fileInfo: {
    flex: 1,
  },
  fileName: {
    fontSize: 14,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  fileMeta: {
    marginTop: 3,
    fontSize: 12,
    color: theme.colors.muted,
  },
  timelineRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    marginBottom: 12,
  },
  timelineDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: theme.colors.accent,
    marginTop: 5,
  },
  timelineContent: {
    flex: 1,
  },
  timelineTitle: {
    fontSize: 13,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  timelineMeta: {
    marginTop: 2,
    fontSize: 12,
    lineHeight: 18,
    color: theme.colors.muted,
  },
});
