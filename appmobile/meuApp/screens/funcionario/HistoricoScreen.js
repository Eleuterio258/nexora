import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  StatusBar,
  ActivityIndicator,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { theme } from '../../src/theme';
import { FuncionarioBottomNav } from '../../src/components';
import { API_BASE_URL } from '../../src/config';

const filters = ['Todos', 'Entrada', 'Saida'];

const statusConfig = {
  ok: {
    label: 'OK',
    color: theme.colors.green,
    bgColor: theme.colors.greenDim,
    borderColor: theme.colors.greenBorder,
    dotColor: theme.colors.green,
    icon: 'check-circle-outline',
  },
  late: {
    label: 'Tarde',
    color: theme.colors.amber,
    bgColor: theme.colors.amberDim,
    borderColor: theme.colors.amberBorder,
    dotColor: theme.colors.amber,
    icon: 'clock-alert-outline',
  },
  absence: {
    label: 'Falta',
    color: theme.colors.red,
    bgColor: theme.colors.redDim,
    borderColor: theme.colors.redBorder,
    dotColor: theme.colors.red,
    icon: 'alert-circle-outline',
  },
};

function formatRecord(record) {
  const dt = new Date(record.recorded_at);
  const time = dt.toLocaleTimeString('pt-PT', { hour: '2-digit', minute: '2-digit' });
  const date = dt.toLocaleDateString('pt-PT', { day: '2-digit', month: 'short', year: 'numeric' });
  const today = new Date();
  const isToday = dt.toDateString() === today.toDateString();
  const yesterday = new Date(today); yesterday.setDate(today.getDate() - 1);
  const isYesterday = dt.toDateString() === yesterday.toDateString();
  const day = isToday ? 'Hoje' : isYesterday ? 'Ontem' : date;
  const type = record.event_type === 'ENTRY' ? 'Entrada' : 'Saida';
  const method = record.source === 'MOBILE_APP' ? 'Mobile' : record.source || '';
  const confidence = record.confidence_score ? ` · score ${Math.round(record.confidence_score * 100)}%` : '';
  return { status: 'ok', day, date, time, type, method, detail: `${type} via ${method}${confidence}`, raw: record };
}

export default function HistoricoScreen({ navigation }) {
  const [activeFilter, setActiveFilter] = useState('Todos');
  const [historyData, setHistoryData] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadHistory = useCallback(async () => {
    setLoading(true);
    try {
      const token = await AsyncStorage.getItem('auth.token');
      const res = await fetch(`${API_BASE_URL}/hr/attendance?page_size=50`, {
        headers: { 'Authorization': `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        setHistoryData((data.items || []).map(formatRecord));
      }
    } catch (_) {}
    finally { setLoading(false); }
  }, []);

  useEffect(() => { loadHistory(); }, [loadHistory]);

  const filteredHistory = useMemo(() => {
    if (activeFilter === 'Todos') return historyData;
    return historyData.filter((item) => item.type === activeFilter);
  }, [activeFilter, historyData]);

  const stats = useMemo(() => ({
    total: historyData.length,
    entries: historyData.filter((item) => item.type === 'Entrada').length,
    exits: historyData.filter((item) => item.type === 'Saida').length,
  }), [historyData]);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>Historico</Text>
          <Text style={styles.headerSub}>Resumo dos ultimos registos de presenca</Text>
        </View>
        <TouchableOpacity
          style={styles.headerAction}
          onPress={() => navigation.navigate('Justificar')}
          activeOpacity={0.85}
        >
          <MaterialCommunityIcons name="text-box-check-outline" size={18} color={theme.colors.accent} />
          <Text style={styles.headerActionText}>Justificar</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.summaryCard}>
          <View style={styles.summaryHead}>
            <View style={styles.summaryIcon}>
              <MaterialCommunityIcons name="timeline-clock-outline" size={20} color={theme.colors.accent} />
            </View>
            <View style={styles.summaryInfo}>
              <Text style={styles.summaryLabel}>Desempenho recente</Text>
              <Text style={styles.summaryTitle}>Pontualidade em linha com o turno</Text>
              <Text style={styles.summaryMeta}>Os desvios mais recentes aparecem abaixo para consulta e justificacao.</Text>
            </View>
          </View>

          <View style={styles.statsRow}>
            <View style={styles.statCard}>
              <Text style={[styles.statValue, { color: theme.colors.green }]}>{stats.entries}</Text>
              <Text style={styles.statLabel}>Entradas</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{stats.exits}</Text>
              <Text style={styles.statLabel}>Saidas</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={[styles.statValue, { color: theme.colors.blue }]}>{stats.total}</Text>
              <Text style={styles.statLabel}>Total</Text>
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

        {loading && (
          <ActivityIndicator size="large" color={theme.colors.accent} style={{ marginTop: 32 }} />
        )}

        {!loading && filteredHistory.length === 0 && (
          <View style={styles.emptyState}>
            <MaterialCommunityIcons name="calendar-blank-outline" size={36} color={theme.colors.muted} />
            <Text style={styles.emptyText}>Sem registos encontrados.</Text>
          </View>
        )}

        {!loading && filteredHistory.map((item, index) => {
          const config = statusConfig[item.status] || statusConfig.ok;
          const canJustify = false;

          return (
            <View key={`${item.date}-${index}`} style={styles.timelineCard}>
              <View style={styles.timelineHead}>
                <View style={[styles.timelineIconWrap, { backgroundColor: config.bgColor, borderColor: config.borderColor }]}>
                  <MaterialCommunityIcons name={config.icon} size={18} color={config.color} />
                </View>

                <View style={styles.timelineInfo}>
                  <View style={styles.timelineTitleRow}>
                    <Text style={styles.timelineTitle}>{item.day} · {item.time}</Text>
                    <View style={[styles.badge, { backgroundColor: config.bgColor, borderColor: config.borderColor }]}>
                      <Text style={[styles.badgeText, { color: config.color }]}>{config.label}</Text>
                    </View>
                  </View>
                  <Text style={styles.timelineMeta}>
                    {item.type}{item.method ? ` · ${item.method}` : ''}
                  </Text>
                  <Text style={styles.timelineDetail}>{item.detail}</Text>
                </View>
              </View>

              {canJustify ? (
                <TouchableOpacity
                  style={styles.justifyButton}
                  onPress={() =>
                    navigation.navigate('Justificar', {
                      day: item.day,
                      time: item.time,
                      status: item.status,
                      reason:
                        item.status === 'absence'
                          ? `Justificacao de falta referente a ${item.date}.`
                          : `Justificacao de atraso referente a ${item.date}.`,
                    })
                  }
                  activeOpacity={0.9}
                >
                  <Text style={styles.justifyButtonText}>
                    {item.status === 'absence' ? 'Justificar falta' : 'Justificar atraso'}
                  </Text>
                  <MaterialCommunityIcons name="chevron-right" size={18} color={theme.colors.accent} />
                </TouchableOpacity>
              ) : null}
            </View>
          );
        })}
      </ScrollView>

      <FuncionarioBottomNav navigation={navigation} activeKey="history" />
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
    justifyContent: 'space-between',
    gap: 12,
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 14,
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
  headerAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.infoDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
  },
  headerActionText: {
    fontSize: 12,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.accent,
  },
  body: {
    padding: 16,
    paddingBottom: 24,
  },
  summaryCard: {
    backgroundColor: theme.colors.surface2,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: theme.colors.border,
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
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginTop: 3,
  },
  summaryMeta: {
    marginTop: 4,
    fontSize: 12,
    color: theme.colors.muted,
    lineHeight: 18,
  },
  statsRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 14,
  },
  statCard: {
    flex: 1,
    backgroundColor: theme.colors.surface,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: 12,
    paddingHorizontal: 12,
  },
  statValue: {
    fontSize: 20,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
  },
  statLabel: {
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
  timelineCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 14,
    marginBottom: 10,
  },
  timelineHead: {
    flexDirection: 'row',
    gap: 12,
  },
  timelineIconWrap: {
    width: 42,
    height: 42,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  timelineInfo: {
    flex: 1,
  },
  timelineTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 8,
    alignItems: 'flex-start',
  },
  timelineTitle: {
    flex: 1,
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  timelineMeta: {
    marginTop: 3,
    fontSize: 12,
    color: theme.colors.muted,
  },
  timelineDetail: {
    marginTop: 6,
    fontSize: 12,
    color: theme.colors.text,
    lineHeight: 18,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
  },
  badgeText: {
    fontSize: 10,
    fontWeight: theme.fontWeight.semibold,
    textTransform: 'uppercase',
  },
  justifyButton: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  justifyButtonText: {
    fontSize: 12,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.accent,
  },
  emptyState: {
    alignItems: 'center',
    paddingTop: 40,
    gap: 10,
  },
  emptyText: {
    fontSize: 14,
    color: theme.colors.muted,
  },
});
