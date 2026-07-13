import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  RefreshControl,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { AppHeader, SectionLabel } from '../../src/components';
import { fetchAuthJson, formatCurrency } from './moduleApi';

export default function ModuleDashboardScreen({ navigation }) {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [customers, setCustomers] = useState([]);
  const [leads, setLeads] = useState([]);
  const [activities, setActivities] = useState([]);
  const [pipeline, setPipeline] = useState([]);

  const loadData = async (isRefresh = false) => {
    try {
      if (isRefresh) setRefreshing(true);
      else setLoading(true);
      setError('');

      const [customersData, leadsData, activitiesData, pipelineData] = await Promise.all([
        fetchAuthJson('/clientes?apenas_ativos=true'),
        fetchAuthJson('/crm/leads'),
        fetchAuthJson('/crm/activities?status=pending'),
        fetchAuthJson('/crm/reports/pipeline-summary'),
      ]);

      setCustomers(Array.isArray(customersData) ? customersData : []);
      setLeads(Array.isArray(leadsData) ? leadsData : []);
      setActivities(Array.isArray(activitiesData) ? activitiesData : []);
      setPipeline(Array.isArray(pipelineData) ? pipelineData : []);
    } catch (err) {
      setError(err?.message || 'Nao foi possivel carregar o dashboard.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const pipelineValue = pipeline.reduce((sum, stage) => sum + Number(stage?.value_total || 0), 0);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />
      <AppHeader
        title="Dashboard"
        subtitle="Resumo rapido dos modulos comerciais"
      />

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.body}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => loadData(true)} tintColor={theme.colors.blue} />}
      >
        <SectionLabel>Visao geral</SectionLabel>
        <View style={styles.metricsGrid}>
          <MetricCard icon="account-multiple-outline" label="Clientes" value={`${customers.length}`} color={theme.colors.blue} />
          <MetricCard icon="account-search-outline" label="Leads" value={`${leads.length}`} color={theme.colors.amber} />
          <MetricCard icon="timeline-clock-outline" label="Pendentes" value={`${activities.length}`} color={theme.colors.green} />
          <MetricCard icon="cash-multiple" label="Pipeline" value={formatCurrency(pipelineValue)} color={theme.colors.accent} compact />
        </View>

        {error ? (
          <View style={styles.errorCard}>
            <MaterialCommunityIcons name="alert-circle-outline" size={18} color={theme.colors.error} />
            <Text style={styles.errorText}>{error}</Text>
          </View>
        ) : null}

        <SectionLabel>Atalhos</SectionLabel>
        <View style={styles.shortcuts}>
          <ShortcutCard icon="account-tie-outline" title="CRM" subtitle="Contas, leads e pipeline" onPress={() => navigation.navigate('ModuleCRM')} />
          <ShortcutCard icon="account-multiple-outline" title="Clientes" subtitle="Carteira comercial" onPress={() => navigation.navigate('ModuleCustomers')} />
          <ShortcutCard icon="chart-box-outline" title="Relatorios" subtitle="Indicadores e top clientes" onPress={() => navigation.navigate('ModuleReports')} />
        </View>

        <SectionLabel>Pipeline atual</SectionLabel>
        {loading ? (
          <Text style={styles.helperText}>A carregar indicadores...</Text>
        ) : pipeline.length === 0 ? (
          <Text style={styles.helperText}>Sem etapas de pipeline registadas.</Text>
        ) : (
          pipeline.map((stage) => (
            <View key={`${stage.stage_id}`} style={styles.listCard}>
              <View style={styles.rowBetween}>
                <Text style={styles.cardTitle}>{stage.name}</Text>
                <Text style={styles.badgeText}>{stage.num_deals} negocios</Text>
              </View>
              <Text style={styles.cardMeta}>Probabilidade {stage.probability}%</Text>
              <Text style={styles.cardValue}>{formatCurrency(stage.value_total)}</Text>
            </View>
          ))
        )}

        <SectionLabel>Leads recentes</SectionLabel>
        {leads.slice(0, 4).map((lead) => (
          <View key={`${lead.id}`} style={styles.listRow}>
            <View style={styles.iconWrap}>
              <MaterialCommunityIcons name="account-convert-outline" size={18} color={theme.colors.amber} />
            </View>
            <View style={styles.listInfo}>
              <Text style={styles.cardTitle}>{lead.name}</Text>
              <Text style={styles.cardMeta}>{lead.source || 'Sem origem'} - score {lead.score || 0}%</Text>
            </View>
            <Text style={styles.statusText}>{lead.status}</Text>
          </View>
        ))}
        {!loading && leads.length === 0 ? <Text style={styles.helperText}>Nenhum lead encontrado.</Text> : null}
      </ScrollView>
    </SafeAreaView>
  );
}

function MetricCard({ icon, label, value, color, compact = false }) {
  return (
    <View style={styles.metricCard}>
      <View style={[styles.metricIcon, { backgroundColor: `${color}22` }]}>
        <MaterialCommunityIcons name={icon} size={18} color={color} />
      </View>
      <Text style={[styles.metricValue, compact && styles.metricValueCompact, { color }]} numberOfLines={1}>
        {value}
      </Text>
      <Text style={styles.metricLabel}>{label}</Text>
    </View>
  );
}

function ShortcutCard({ icon, title, subtitle, onPress }) {
  return (
    <TouchableOpacity style={styles.shortcutCard} activeOpacity={0.86} onPress={onPress}>
      <View style={styles.shortcutIcon}>
        <MaterialCommunityIcons name={icon} size={20} color={theme.colors.blue} />
      </View>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.cardMeta}>{subtitle}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.bg },
  scroll: { flex: 1 },
  body: { padding: 16, paddingBottom: 32 },
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
  metricValue: { fontSize: 22, fontWeight: theme.fontWeight.bold },
  metricValueCompact: { fontSize: 18 },
  metricLabel: { marginTop: 4, fontSize: 12, color: theme.colors.muted },
  shortcuts: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginBottom: 18 },
  shortcutCard: {
    width: '48%',
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
  },
  shortcutIcon: {
    width: 42,
    height: 42,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.blueDim,
    marginBottom: 10,
  },
  errorCard: {
    flexDirection: 'row',
    gap: 10,
    alignItems: 'center',
    backgroundColor: theme.colors.errorDim,
    borderWidth: 1,
    borderColor: theme.colors.errorBorder,
    borderRadius: 14,
    padding: 14,
    marginBottom: 18,
  },
  errorText: { flex: 1, fontSize: 12, color: theme.colors.text },
  helperText: { color: theme.colors.muted, fontSize: 12, marginBottom: 12 },
  listCard: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
  },
  rowBetween: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 12 },
  cardTitle: { fontSize: 14, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  cardMeta: { marginTop: 4, fontSize: 12, color: theme.colors.muted },
  cardValue: { marginTop: 6, fontSize: 16, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  badgeText: { fontSize: 11, color: theme.colors.blue, fontWeight: theme.fontWeight.medium },
  listRow: {
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
  iconWrap: {
    width: 38,
    height: 38,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.amberDim,
  },
  listInfo: { flex: 1 },
  statusText: { fontSize: 11, color: theme.colors.muted, textTransform: 'capitalize' },
});
