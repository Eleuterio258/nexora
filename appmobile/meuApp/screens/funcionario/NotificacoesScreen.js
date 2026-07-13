import React, { useMemo, useState } from 'react';
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

const notifications = [
  {
    title: 'Pedido aprovado',
    message: 'O gestor aprovou as ferias de 12 Jun a 22 Jun.',
    time: 'Agora',
    tone: 'success',
    category: 'Pedidos',
    icon: 'check-circle-outline',
    action: 'Ver pedido',
  },
  {
    title: 'Nova mensagem do gestor',
    message: 'Verifica a cobertura da equipa para o turno de amanha.',
    time: '12 min',
    tone: 'info',
    category: 'Chat',
    icon: 'message-outline',
    action: 'Abrir conversa',
  },
  {
    title: 'Justificacao em revisao',
    message: 'A sua justificacao de atraso de ontem esta em analise.',
    time: '1 h',
    tone: 'warning',
    category: 'Assiduidade',
    icon: 'clock-alert-outline',
    action: 'Ver justificacao',
  },
  {
    title: 'Grupo Financeira',
    message: 'Foi partilhado um novo comunicado no grupo.',
    time: 'Ontem',
    tone: 'default',
    category: 'Chat',
    icon: 'account-group-outline',
    action: 'Abrir grupo',
  },
];

const filters = ['Todas', 'Pedidos', 'Chat', 'Assiduidade'];

function getToneStyles(tone) {
  if (tone === 'success') {
    return { bg: theme.colors.greenDim, border: theme.colors.greenBorder, color: theme.colors.green };
  }
  if (tone === 'warning') {
    return { bg: theme.colors.amberDim, border: theme.colors.amberBorder, color: theme.colors.amber };
  }
  if (tone === 'info') {
    return { bg: theme.colors.infoDim, border: theme.colors.blueBorder, color: theme.colors.blue };
  }
  return { bg: theme.colors.surface2, border: theme.colors.border, color: theme.colors.text };
}

export default function NotificacoesScreen({ navigation }) {
  const [activeFilter, setActiveFilter] = useState('Todas');

  const filteredNotifications = useMemo(() => {
    if (activeFilter === 'Todas') {
      return notifications;
    }

    return notifications.filter((item) => item.category === activeFilter);
  }, [activeFilter]);

  const summary = useMemo(() => ({
    unread: notifications.length,
    requests: notifications.filter((item) => item.category === 'Pedidos').length,
    chat: notifications.filter((item) => item.category === 'Chat').length,
  }), []);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={20} color={theme.colors.text} />
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>Notificacoes</Text>
          <Text style={styles.headerSub}>Alertas, aprovacoes e mensagens recentes</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.summaryCard}>
          <View style={styles.summaryHead}>
            <View style={styles.summaryIcon}>
              <MaterialCommunityIcons name="bell-badge-outline" size={20} color={theme.colors.accent} />
            </View>
            <View style={styles.summaryInfo}>
              <Text style={styles.summaryLabel}>Central de alertas</Text>
              <Text style={styles.summaryTitle}>{summary.unread} itens recentes</Text>
              <Text style={styles.summaryMeta}>Pedidos, mensagens e actualizacoes operacionais concentrados num so lugar.</Text>
            </View>
          </View>

          <View style={styles.metricRow}>
            <View style={styles.metricCard}>
              <Text style={styles.metricValue}>{summary.requests}</Text>
              <Text style={styles.metricLabel}>Pedidos</Text>
            </View>
            <View style={styles.metricCard}>
              <Text style={styles.metricValue}>{summary.chat}</Text>
              <Text style={styles.metricLabel}>Chat</Text>
            </View>
            <View style={styles.metricCard}>
              <Text style={[styles.metricValue, { color: theme.colors.amber }]}>{summary.unread}</Text>
              <Text style={styles.metricLabel}>Novas</Text>
            </View>
          </View>
        </View>

        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          style={styles.filterScroller}
          contentContainerStyle={styles.filterRow}
        >
          {filters.map((filter) => {
            const isActive = activeFilter === filter;
            return (
              <TouchableOpacity
                key={filter}
                style={[styles.filterChip, isActive && styles.filterChipActive]}
                onPress={() => setActiveFilter(filter)}
                activeOpacity={0.9}
              >
                <Text style={[styles.filterChipText, isActive && styles.filterChipTextActive]}>{filter}</Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>

        {filteredNotifications.map((item, index) => {
          const tone = getToneStyles(item.tone);

          return (
            <View
              key={`${item.title}-${index}`}
              style={[styles.notificationCard, { backgroundColor: tone.bg, borderColor: tone.border }]}
            >
              <View style={[styles.notificationIcon, { backgroundColor: theme.colors.surface }]}>
                <MaterialCommunityIcons name={item.icon} size={18} color={tone.color} />
              </View>

              <View style={styles.notificationInfo}>
                <View style={styles.notificationHead}>
                  <Text style={styles.notificationTitle}>{item.title}</Text>
                  <Text style={styles.notificationTime}>{item.time}</Text>
                </View>

                <View style={styles.categoryBadge}>
                  <Text style={styles.categoryBadgeText}>{item.category}</Text>
                </View>

                <Text style={styles.notificationMessage}>{item.message}</Text>

                <TouchableOpacity style={styles.notificationAction} activeOpacity={0.9}>
                  <Text style={styles.notificationActionText}>{item.action}</Text>
                  <MaterialCommunityIcons name="chevron-right" size={18} color={theme.colors.accent} />
                </TouchableOpacity>
              </View>
            </View>
          );
        })}
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
  summaryCard: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 16,
    marginBottom: 14,
  },
  summaryHead: {
    flexDirection: 'row',
    gap: 12,
  },
  summaryIcon: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  summaryInfo: {
    flex: 1,
  },
  summaryLabel: {
    fontSize: 11,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  summaryTitle: {
    marginTop: 3,
    fontSize: 18,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  summaryMeta: {
    marginTop: 4,
    fontSize: 12,
    color: theme.colors.muted,
    lineHeight: 18,
  },
  metricRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 14,
  },
  metricCard: {
    flex: 1,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    paddingVertical: 12,
    paddingHorizontal: 12,
  },
  metricValue: {
    fontSize: 20,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
  },
  metricLabel: {
    marginTop: 3,
    fontSize: 12,
    color: theme.colors.muted,
  },
  filterScroller: {
    marginBottom: 14,
  },
  filterRow: {
    flexDirection: 'row',
    gap: 8,
  },
  filterChip: {
    paddingHorizontal: 14,
    paddingVertical: 9,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  filterChipActive: {
    backgroundColor: theme.colors.infoDim,
    borderColor: theme.colors.blueBorder,
  },
  filterChipText: {
    fontSize: 12,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.muted,
  },
  filterChipTextActive: {
    color: theme.colors.accent,
  },
  notificationCard: {
    flexDirection: 'row',
    gap: 12,
    borderWidth: 1,
    borderRadius: 16,
    padding: 14,
    marginBottom: 10,
  },
  notificationIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  notificationInfo: {
    flex: 1,
  },
  notificationHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10,
    marginBottom: 4,
  },
  notificationTitle: {
    flex: 1,
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  notificationTime: {
    fontSize: 11,
    color: theme.colors.muted,
  },
  categoryBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    marginBottom: 8,
  },
  categoryBadgeText: {
    fontSize: 10,
    color: theme.colors.muted,
    fontWeight: theme.fontWeight.semibold,
    textTransform: 'uppercase',
  },
  notificationMessage: {
    fontSize: 12,
    color: theme.colors.text,
    lineHeight: 18,
  },
  notificationAction: {
    marginTop: 10,
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    gap: 4,
  },
  notificationActionText: {
    fontSize: 12,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.accent,
  },
});
