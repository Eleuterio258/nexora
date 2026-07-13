import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  RefreshControl,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { AppHeader, SectionLabel } from '../../src/components';
import { fetchAuthJson, formatCurrency } from './moduleApi';

export default function ModuleReportsScreen() {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [salesSummary, setSalesSummary] = useState(null);
  const [topCustomers, setTopCustomers] = useState([]);
  const [pipeline, setPipeline] = useState([]);

  const loadReports = async (isRefresh = false) => {
    try {
      if (isRefresh) setRefreshing(true);
      else setLoading(true);
      setError('');

      const [summaryData, topCustomersData, pipelineData] = await Promise.all([
        fetchAuthJson('/reports/sales-summary'),
        fetchAuthJson('/reports/top-customers?limit=5'),
        fetchAuthJson('/crm/reports/pipeline-summary'),
      ]);

      setSalesSummary(summaryData || null);
      setTopCustomers(Array.isArray(topCustomersData) ? topCustomersData : []);
      setPipeline(Array.isArray(pipelineData) ? pipelineData : []);
    } catch (err) {
      setError(err?.message || 'Nao foi possivel carregar os relatorios.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadReports();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />
      <AppHeader title="Relatorios" subtitle="Indicadores comerciais e CRM" />

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.body}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => loadReports(true)} tintColor={theme.colors.blue} />}
      >
        {error ? (
          <View style={styles.errorCard}>
            <MaterialCommunityIcons name="alert-circle-outline" size={18} color={theme.colors.error} />
            <Text style={styles.errorText}>{error}</Text>
          </View>
        ) : null}

        <SectionLabel>Resumo de vendas</SectionLabel>
        {loading && !salesSummary ? <Text style={styles.helperText}>A carregar resumo...</Text> : null}
        {salesSummary ? (
          <View style={styles.metricsGrid}>
            <MetricCard icon="cash-register" label="Vendas" value={formatCurrency(salesSummary.total_vendas)} color={theme.colors.blue} />
            <MetricCard icon="clipboard-list-outline" label="Pedidos" value={`${salesSummary.total_pedidos || 0}`} color={theme.colors.green} />
            <MetricCard icon="receipt-text-outline" label="Faturas" value={`${salesSummary.total_faturas || 0}`} color={theme.colors.amber} />
            <MetricCard icon="account-multiple-outline" label="Clientes" value={`${salesSummary.total_clientes || 0}`} color={theme.colors.accent} />
          </View>
        ) : null}

        <SectionLabel>Top clientes</SectionLabel>
        {topCustomers.map((customer, index) => (
          <View key={`${customer.cliente_id}`} style={styles.rankCard}>
            <View style={styles.rankBadge}>
              <Text style={styles.rankBadgeText}>#{index + 1}</Text>
            </View>
            <View style={styles.rankInfo}>
              <Text style={styles.rankTitle}>{customer.cliente_nome}</Text>
              <Text style={styles.rankMeta}>{customer.total_faturas || 0} faturas</Text>
            </View>
            <Text style={styles.rankValue}>{formatCurrency(customer.total_receita)}</Text>
          </View>
        ))}
        {!loading && topCustomers.length === 0 ? <Text style={styles.helperText}>Sem clientes com receita registada.</Text> : null}

        <SectionLabel>Pipeline comercial</SectionLabel>
        {pipeline.map((stage) => (
          <View key={`${stage.stage_id}`} style={styles.pipelineCard}>
            <View style={styles.rowBetween}>
              <Text style={styles.pipelineTitle}>{stage.name}</Text>
              <Text style={styles.pipelineCount}>{stage.num_deals} negocios</Text>
            </View>
            <Text style={styles.pipelineMeta}>Probabilidade {stage.probability}%</Text>
            <Text style={styles.pipelineValue}>{formatCurrency(stage.value_total)}</Text>
          </View>
        ))}
        {!loading && pipeline.length === 0 ? <Text style={styles.helperText}>Sem pipeline disponivel.</Text> : null}
      </ScrollView>
    </SafeAreaView>
  );
}

function MetricCard({ icon, label, value, color }) {
  return (
    <View style={styles.metricCard}>
      <View style={[styles.metricIcon, { backgroundColor: `${color}22` }]}>
        <MaterialCommunityIcons name={icon} size={18} color={color} />
      </View>
      <Text style={[styles.metricValue, { color }]} numberOfLines={1}>{value}</Text>
      <Text style={styles.metricLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.bg },
  scroll: { flex: 1 },
  body: { padding: 16, paddingBottom: 32 },
  errorCard: {
    flexDirection: 'row',
    gap: 10,
    alignItems: 'center',
    backgroundColor: theme.colors.errorDim,
    borderWidth: 1,
    borderColor: theme.colors.errorBorder,
    borderRadius: 14,
    padding: 14,
    marginBottom: 14,
  },
  errorText: { flex: 1, fontSize: 12, color: theme.colors.text },
  helperText: { color: theme.colors.muted, fontSize: 12, marginBottom: 12 },
  metricsGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 18 },
  metricCard: {
    width: '48%',
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
  },
  metricIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  metricValue: { fontSize: 20, fontWeight: theme.fontWeight.bold },
  metricLabel: { marginTop: 4, fontSize: 12, color: theme.colors.muted },
  rankCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
  },
  rankBadge: {
    width: 34,
    height: 34,
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.blueDim,
  },
  rankBadgeText: { fontSize: 12, color: theme.colors.blue, fontWeight: theme.fontWeight.semibold },
  rankInfo: { flex: 1 },
  rankTitle: { fontSize: 14, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  rankMeta: { marginTop: 3, fontSize: 11, color: theme.colors.muted },
  rankValue: { fontSize: 13, color: theme.colors.text, fontWeight: theme.fontWeight.semibold },
  pipelineCard: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
  },
  rowBetween: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 12 },
  pipelineTitle: { fontSize: 14, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  pipelineCount: { fontSize: 11, color: theme.colors.blue, fontWeight: theme.fontWeight.medium },
  pipelineMeta: { marginTop: 4, fontSize: 12, color: theme.colors.muted },
  pipelineValue: { marginTop: 6, fontSize: 15, color: theme.colors.text, fontWeight: theme.fontWeight.semibold },
});
