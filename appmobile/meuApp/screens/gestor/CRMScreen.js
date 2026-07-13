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
import AsyncStorage from '@react-native-async-storage/async-storage';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { API_BASE_URL } from '../../src/config';
import { AppHeader, SectionLabel, GestorBottomNav } from '../../src/components';

const stageIcon = {
  open: 'briefcase-outline',
  won: 'handshake-outline',
  lost: 'close-circle-outline',
};

const activityIcon = {
  call: 'phone-outline',
  meeting: 'calendar-account-outline',
  follow_up: 'timeline-clock-outline',
  proposal: 'file-document-outline',
};

export default function CRMScreen({ navigation }) {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [accounts, setAccounts] = useState([]);
  const [leads, setLeads] = useState([]);
  const [deals, setDeals] = useState([]);
  const [activities, setActivities] = useState([]);
  const [pipeline, setPipeline] = useState([]);

  const loadCRM = async (isRefresh = false) => {
    try {
      if (isRefresh) setRefreshing(true);
      else setLoading(true);
      setError('');

      const token = await AsyncStorage.getItem('auth.token');
      if (!token) {
        setError('Sessao expirada. Inicie sessao novamente.');
        return;
      }

      const headers = { Authorization: `Bearer ${token}` };
      const urls = [
        `${API_BASE_URL}/crm/accounts?apenas_ativos=true`,
        `${API_BASE_URL}/crm/leads`,
        `${API_BASE_URL}/crm/deals`,
        `${API_BASE_URL}/crm/activities?status=pending`,
        `${API_BASE_URL}/crm/reports/pipeline-summary`,
      ];

      const responses = await Promise.all(urls.map((url) => fetch(url, { headers })));
      const failed = responses.find((response) => !response.ok);
      if (failed) {
        setError(`Falha ao carregar CRM (${failed.status}).`);
        return;
      }

      const [accountsData, leadsData, dealsData, activitiesData, pipelineData] = await Promise.all(
        responses.map((response) => response.json()),
      );

      setAccounts(Array.isArray(accountsData) ? accountsData : []);
      setLeads(Array.isArray(leadsData) ? leadsData : []);
      setDeals(Array.isArray(dealsData) ? dealsData : []);
      setActivities(Array.isArray(activitiesData) ? activitiesData : []);
      setPipeline(Array.isArray(pipelineData) ? pipelineData : []);
    } catch (_) {
      setError('Nao foi possivel carregar os dados de CRM.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadCRM();
  }, []);

  const openModules = () => navigation.navigate('ModuleCRM');

  const totalPipelineValue = pipeline.reduce((sum, item) => sum + Number(item?.value_total || 0), 0);
  const wonDeals = deals.filter((deal) => deal?.status === 'won').length;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader title="CRM" subtitle="Contas, leads, pipeline e actividades comerciais" />

      <ScrollView
        style={styles.content}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => loadCRM(true)} tintColor={theme.colors.blue} />}
      >
        <View style={styles.body}>
          <SectionLabel>Resumo comercial</SectionLabel>
          <View style={styles.grid}>
            <MetricCard icon="office-building-outline" label="Contas activas" value={`${accounts.length}`} color={theme.colors.blue} />
            <MetricCard icon="account-search-outline" label="Leads" value={`${leads.length}`} color={theme.colors.amber} />
            <MetricCard icon="handshake-outline" label="Negocios ganhos" value={`${wonDeals}`} color={theme.colors.green} />
            <MetricCard icon="cash-multiple" label="Valor pipeline" value={formatCurrency(totalPipelineValue)} color={theme.colors.accent} compact />
          </View>

          {error ? (
            <View style={styles.errorCard}>
              <MaterialCommunityIcons name="alert-circle-outline" size={18} color={theme.colors.error} />
              <Text style={styles.errorText}>{error}</Text>
              <TouchableOpacity style={styles.retryButton} onPress={() => loadCRM()}>
                <Text style={styles.retryText}>Tentar novamente</Text>
              </TouchableOpacity>
            </View>
          ) : null}

          <View style={styles.actionsRow}>
            <TouchableOpacity style={styles.actionButton} onPress={() => loadCRM(true)} activeOpacity={0.85}>
              <MaterialCommunityIcons name="refresh" size={18} color={theme.colors.blue} />
              <Text style={styles.actionText}>Actualizar</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionButton} onPress={openModules} activeOpacity={0.85}>
              <MaterialCommunityIcons name="view-grid-outline" size={18} color={theme.colors.blue} />
              <Text style={styles.actionText}>Modulo</Text>
            </TouchableOpacity>
          </View>

          <SectionLabel>Pipeline</SectionLabel>
          {loading ? (
            <Text style={styles.helperText}>A carregar dados comerciais...</Text>
          ) : pipeline.length === 0 ? (
            <Text style={styles.helperText}>Sem etapas registadas no pipeline.</Text>
          ) : (
            pipeline.map((item) => (
              <View key={`${item.stage_id}`} style={styles.pipelineCard}>
                <View style={styles.pipelineHeader}>
                  <Text style={styles.pipelineTitle}>{item.name}</Text>
                  <Text style={styles.pipelineCount}>{item.num_deals} negocios</Text>
                </View>
                <Text style={styles.pipelineMeta}>Probabilidade {item.probability}%</Text>
                <Text style={styles.pipelineValue}>{formatCurrency(item.value_total)}</Text>
              </View>
            ))
          )}

          <SectionLabel>Contas prioritarias</SectionLabel>
          {accounts.slice(0, 4).map((account) => (
            <View key={`${account.id}`} style={styles.accountCard}>
              <View style={styles.accountHeader}>
                <Text style={styles.accountName}>{account.name}</Text>
                <View style={styles.badge}>
                  <Text style={styles.badgeText}>{account.country || 'N/A'}</Text>
                </View>
              </View>
              <Text style={styles.accountMeta}>{[account.city, account.province].filter(Boolean).join(', ') || 'Localizacao nao definida'}</Text>
              <Text style={styles.accountContact}>{account.phone || account.email || 'Sem contacto principal'}</Text>
            </View>
          ))}
          {!loading && accounts.length === 0 ? <Text style={styles.helperText}>Nenhuma conta activa encontrada.</Text> : null}

          <SectionLabel>Leads recentes</SectionLabel>
          {leads.slice(0, 4).map((lead) => (
            <View key={`${lead.id}`} style={styles.activityRow}>
              <View style={styles.activityIcon}>
                <MaterialCommunityIcons name="account-convert-outline" size={18} color={theme.colors.amber} />
              </View>
              <View style={styles.activityInfo}>
                <Text style={styles.activityTitle}>{lead.name}</Text>
                <Text style={styles.activityMeta}>{lead.source || 'Sem origem'} · score {lead.score || 0}%</Text>
              </View>
              <Text style={styles.statusText}>{lead.status}</Text>
            </View>
          ))}
          {!loading && leads.length === 0 ? <Text style={styles.helperText}>Nenhum lead registado.</Text> : null}

          <SectionLabel>Negocios em curso</SectionLabel>
          {deals.slice(0, 4).map((deal) => (
            <View key={`${deal.id}`} style={styles.activityRow}>
              <View style={styles.activityIcon}>
                <MaterialCommunityIcons name={stageIcon[deal.status] || 'briefcase-outline'} size={18} color={theme.colors.green} />
              </View>
              <View style={styles.activityInfo}>
                <Text style={styles.activityTitle}>{deal.name}</Text>
                <Text style={styles.activityMeta}>{formatCurrency(deal.value)} · etapa #{deal.stage_id}</Text>
              </View>
              <Text style={styles.statusText}>{deal.status}</Text>
            </View>
          ))}
          {!loading && deals.length === 0 ? <Text style={styles.helperText}>Nenhum negocio registado.</Text> : null}

          <SectionLabel>Actividades pendentes</SectionLabel>
          {activities.slice(0, 4).map((activity) => (
            <View key={`${activity.id}`} style={styles.activityRow}>
              <View style={styles.activityIcon}>
                <MaterialCommunityIcons name={activityIcon[activity.type] || 'timeline-text-outline'} size={18} color={theme.colors.blue} />
              </View>
              <View style={styles.activityInfo}>
                <Text style={styles.activityTitle}>{activity.description}</Text>
                <Text style={styles.activityMeta}>{formatDateTime(activity.date)}</Text>
              </View>
              <Text style={styles.statusText}>{activity.status}</Text>
            </View>
          ))}
          {!loading && activities.length === 0 ? <Text style={styles.helperText}>Sem actividades pendentes.</Text> : null}
        </View>
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="crm" />
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

function formatCurrency(value) {
  const amount = Number(value || 0);
  return `${amount.toLocaleString('pt-PT', { minimumFractionDigits: 0, maximumFractionDigits: 0 })} MZN`;
}

function formatDateTime(value) {
  if (!value) return 'Sem data';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'Sem data';
  return date.toLocaleString('pt-PT', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg,
  },
  content: {
    flex: 1,
  },
  body: {
    padding: 16,
    paddingBottom: 88,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    marginBottom: 18,
  },
  metricCard: {
    width: '48%',
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
  },
  metricIcon: {
    width: 36,
    height: 36,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  metricValue: {
    fontSize: 24,
    fontWeight: theme.fontWeight.bold,
  },
  metricValueCompact: {
    fontSize: 20,
  },
  metricLabel: {
    marginTop: 4,
    fontSize: 12,
    color: theme.colors.muted,
  },
  errorCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.error,
    borderRadius: 14,
    padding: 14,
    marginBottom: 18,
  },
  errorText: {
    flex: 1,
    color: theme.colors.text,
    fontSize: 12,
  },
  retryButton: {
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 10,
    backgroundColor: theme.colors.blueDim,
  },
  retryText: {
    color: theme.colors.blue,
    fontWeight: theme.fontWeight.semibold,
    fontSize: 12,
  },
  actionsRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 18,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 12,
    paddingVertical: 12,
  },
  actionText: {
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  helperText: {
    color: theme.colors.muted,
    fontSize: 12,
    marginBottom: 12,
  },
  pipelineCard: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
  },
  pipelineHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  pipelineTitle: {
    fontSize: 15,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  pipelineCount: {
    fontSize: 12,
    color: theme.colors.blue,
    fontWeight: theme.fontWeight.medium,
  },
  pipelineMeta: {
    marginTop: 6,
    fontSize: 12,
    color: theme.colors.muted,
  },
  pipelineValue: {
    marginTop: 4,
    fontSize: 16,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.semibold,
  },
  accountCard: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
  },
  accountHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 10,
  },
  accountName: {
    fontSize: 15,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
    backgroundColor: theme.colors.blueDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
  },
  badgeText: {
    fontSize: 11,
    color: theme.colors.blue,
    fontWeight: theme.fontWeight.medium,
  },
  accountMeta: {
    marginTop: 6,
    fontSize: 12,
    color: theme.colors.text,
  },
  accountContact: {
    marginTop: 2,
    fontSize: 11,
    color: theme.colors.muted,
  },
  activityRow: {
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
  activityIcon: {
    width: 38,
    height: 38,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.blueDim,
  },
  activityInfo: {
    flex: 1,
  },
  activityTitle: {
    fontSize: 14,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  activityMeta: {
    marginTop: 3,
    fontSize: 11,
    color: theme.colors.muted,
  },
  statusText: {
    color: theme.colors.muted,
    fontSize: 11,
    textTransform: 'capitalize',
  },
});
