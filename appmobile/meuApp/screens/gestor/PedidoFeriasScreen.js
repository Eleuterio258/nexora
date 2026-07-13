import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { AppHeader, SectionLabel, GestorBottomNav } from '../../src/components';
import { fetchAuthJson } from '../modules/moduleApi';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { API_BASE_URL } from '../../src/config';

const TYPE_LABELS = {
  annual_leave:   'Ferias anuais',
  sick_leave:     'Licenca medica',
  personal_leave: 'Licenca pessoal',
  dispensation:   'Dispensa',
};

const STATUS_LABELS = {
  pending:  'Pendente',
  approved: 'Aprovado',
  rejected: 'Rejeitado',
};

function formatDate(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleDateString('pt-PT', { day: '2-digit', month: 'short' });
}

function diffDays(start, end) {
  if (!start || !end) return 0;
  const a = new Date(start);
  const b = new Date(end);
  return Math.max(1, Math.round((b - a) / 86400000) + 1);
}

async function authPatch(path, body) {
  const token = await AsyncStorage.getItem('auth.token');
  const res = await fetch(`${API_BASE_URL}${path}`, {
    method: 'PUT',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  let payload = null;
  try { payload = await res.json(); } catch (_) {}
  if (!res.ok) {
    throw new Error(payload?.error || `Erro HTTP ${res.status}`);
  }
  return payload?.data || payload;
}

async function authPost(path, body = {}) {
  const token = await AsyncStorage.getItem('auth.token');
  const res = await fetch(`${API_BASE_URL}${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  let payload = null;
  try { payload = await res.json(); } catch (_) {}
  if (!res.ok) {
    throw new Error(payload?.error || `Erro HTTP ${res.status}`);
  }
  return payload?.data || payload;
}

export default function PedidoFeriasScreen({ navigation }) {
  const [leaves, setLeaves]     = useState([]);
  const [loading, setLoading]   = useState(true);
  const [error, setError]       = useState(null);
  const [acting, setActing]     = useState(null); // id being approved/rejected
  const [activeTab, setActiveTab] = useState('Pendentes');

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fetchAuthJson('/hr/leaves');
      const list = Array.isArray(data) ? data : (data?.items || []);
      setLeaves(list);
    } catch (err) {
      setError(err.message || 'Erro ao carregar pedidos');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const pendingCount = leaves.filter(
    (l) => l.status === 'pending',
  ).length;

  const filteredLeaves = leaves.filter((l) => {
    if (activeTab === 'Pendentes') return l.status === 'pending';
    if (activeTab === 'Aprovados') return l.status === 'approved';
    return true;
  });

  async function handleApprove(leave) {
    setActing(leave.id);
    try {
      await authPost(`/hr/leaves/${leave.id}/aprovar`);
      setLeaves((prev) => prev.map((l) => l.id === leave.id ? { ...l, status: 'approved' } : l));
    } catch (err) {
      Alert.alert('Erro', err.message || 'Nao foi possivel aprovar o pedido.');
    } finally {
      setActing(null);
    }
  }

  async function handleReject(leave) {
    Alert.alert(
      'Rejeitar pedido',
      `Tem a certeza que pretende rejeitar o pedido de ${leave.employee_name || 'funcionario'}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Rejeitar',
          style: 'destructive',
          onPress: async () => {
            setActing(leave.id);
            try {
              await authPatch(`/hr/leaves/${leave.id}`, {
                type: leave.type,
                start_date: leave.start_date,
                end_date: leave.end_date,
                status: 'rejected',
              });
              setLeaves((prev) => prev.map((l) => l.id === leave.id ? { ...l, status: 'rejected' } : l));
            } catch (err) {
              Alert.alert('Erro', err.message || 'Nao foi possivel rejeitar o pedido.');
            } finally {
              setActing(null);
            }
          },
        },
      ],
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader title="Pedidos de Ferias" subtitle="Pedidos recebidos dos funcionarios" />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.body}>
          <View style={styles.summaryCard}>
            <View style={styles.summaryIcon}>
              <MaterialCommunityIcons name="palm-tree" size={20} color={theme.colors.accent} />
            </View>
            <View style={styles.summaryInfo}>
              <Text style={styles.summaryEyebrow}>Caixa de entrada</Text>
              {loading ? (
                <ActivityIndicator size="small" color={theme.colors.accent} style={{ marginTop: 4 }} />
              ) : (
                <>
                  <Text style={styles.summaryValue}>{pendingCount} por validar</Text>
                  <Text style={styles.summaryMeta}>O funcionario submete e o gestor aprova ou rejeita</Text>
                </>
              )}
            </View>
          </View>

          <SectionLabel>Caixa de entrada</SectionLabel>

          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.typeRow}
            style={styles.typeScroller}
          >
            {['Pendentes', 'Aprovados', 'Todos'].map((tab) => {
              const isActive = tab === activeTab;
              return (
                <TouchableOpacity
                  key={tab}
                  style={[styles.typeChip, isActive && styles.typeChipActive]}
                  onPress={() => setActiveTab(tab)}
                  activeOpacity={0.9}
                >
                  <Text style={[styles.typeChipText, isActive && styles.typeChipTextActive]}>{tab}</Text>
                </TouchableOpacity>
              );
            })}
          </ScrollView>

          {error ? (
            <View style={styles.errorWrap}>
              <Text style={styles.errorText}>{error}</Text>
              <TouchableOpacity onPress={load} style={styles.retryBtn}>
                <Text style={styles.retryText}>Tentar novamente</Text>
              </TouchableOpacity>
            </View>
          ) : loading ? (
            <ActivityIndicator size="large" color={theme.colors.accent} style={{ marginTop: 32 }} />
          ) : (
            <>
              <View style={styles.daysCard}>
                <Text style={styles.daysLabel}>Resumo operacional</Text>
                <Text style={styles.daysValue}>{filteredLeaves.length} pedido{filteredLeaves.length !== 1 ? 's' : ''} visivel{filteredLeaves.length !== 1 ? 'eis' : ''}</Text>
              </View>

              <View style={styles.divider} />

              <SectionLabel>Pedidos recebidos</SectionLabel>

              {filteredLeaves.length === 0 ? (
                <Text style={styles.emptyText}>Nenhum pedido nesta categoria.</Text>
              ) : (
                filteredLeaves.map((leave) => {
                  const days       = diffDays(leave.start_date, leave.end_date);
                  const typeLabel   = TYPE_LABELS[leave.type] || leave.type;
                  const statusLabel = STATUS_LABELS[leave.status] || leave.status;
                  const isProcessing = acting === leave.id;

                  return (
                    <View key={leave.id} style={styles.requestCard}>
                      <View style={styles.requestHead}>
                        <Text style={styles.requestName}>{leave.employee_name || `ID ${leave.employee_id}`}</Text>
                        <Text style={styles.requestStatus}>{statusLabel}</Text>
                      </View>
                      <Text style={styles.requestMeta}>{typeLabel}</Text>
                      <Text style={styles.requestMeta}>
                        {formatDate(leave.start_date)} — {formatDate(leave.end_date)}
                      </Text>
                      <Text style={styles.requestMeta}>{days} dia{days !== 1 ? 's' : ''} solicitado{days !== 1 ? 's' : ''}</Text>
                      {leave.notes ? <Text style={styles.requestNote}>{leave.notes}</Text> : null}

                      {leave.status === 'pending' ? (
                        <View style={styles.requestActions}>
                          <TouchableOpacity
                            style={[styles.actionBtn, styles.approveBtn, isProcessing && styles.btnDisabled]}
                            onPress={() => !isProcessing && handleApprove(leave)}
                            activeOpacity={0.85}
                          >
                            {isProcessing ? (
                              <ActivityIndicator size="small" color="#fff" />
                            ) : (
                              <Text style={styles.approveBtnText}>Aprovar</Text>
                            )}
                          </TouchableOpacity>
                          <TouchableOpacity
                            style={[styles.actionBtn, styles.rejectBtn, isProcessing && styles.btnDisabled]}
                            onPress={() => !isProcessing && handleReject(leave)}
                            activeOpacity={0.85}
                          >
                            <Text style={styles.rejectBtnText}>Rejeitar</Text>
                          </TouchableOpacity>
                        </View>
                      ) : null}
                    </View>
                  );
                })
              )}
            </>
          )}
        </View>
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="mais" />
    </SafeAreaView>
  );
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
  },
  summaryCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: theme.borderRadius.lg,
    padding: 16,
    marginBottom: 16,
  },
  summaryIcon: {
    width: 42,
    height: 42,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  summaryInfo: {
    flex: 1,
  },
  summaryEyebrow: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.2,
  },
  summaryValue: {
    fontSize: theme.fontSize.xl,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginTop: 2,
  },
  summaryMeta: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 2,
  },
  typeScroller: {
    marginBottom: 14,
  },
  typeRow: {
    flexDirection: 'row',
    gap: 10,
    paddingRight: 6,
  },
  typeChip: {
    minHeight: 40,
    paddingHorizontal: 16,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    backgroundColor: theme.colors.surface,
    justifyContent: 'center',
  },
  typeChipActive: {
    backgroundColor: theme.colors.infoDim,
    borderColor: theme.colors.blueBorder,
  },
  typeChipText: {
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  typeChipTextActive: {
    color: theme.colors.accent,
  },
  daysCard: {
    backgroundColor: theme.colors.surface2,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 14,
    marginBottom: 14,
  },
  daysLabel: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
  },
  daysValue: {
    fontSize: theme.fontSize.xl,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginTop: 4,
  },
  divider: {
    height: 1,
    backgroundColor: theme.colors.border,
    marginVertical: 18,
  },
  requestCard: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: theme.borderRadius.lg,
    padding: 14,
    marginBottom: 10,
  },
  requestHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10,
    marginBottom: 4,
  },
  requestName: {
    flex: 1,
    fontSize: theme.fontSize.lg,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  requestStatus: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.accent,
  },
  requestMeta: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 2,
  },
  requestNote: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.text,
    marginTop: 8,
    lineHeight: 18,
  },
  requestActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 12,
  },
  actionBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: theme.borderRadius.base,
    alignItems: 'center',
    justifyContent: 'center',
  },
  approveBtn: {
    backgroundColor: theme.colors.success,
  },
  approveBtnText: {
    color: '#fff',
    fontWeight: theme.fontWeight.semibold,
    fontSize: theme.fontSize.md,
  },
  rejectBtn: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.redBorder,
  },
  rejectBtnText: {
    color: theme.colors.error,
    fontWeight: theme.fontWeight.semibold,
    fontSize: theme.fontSize.md,
  },
  btnDisabled: {
    opacity: 0.5,
  },
  errorWrap: {
    marginTop: 32,
    alignItems: 'center',
  },
  errorText: {
    color: theme.colors.error,
    fontSize: theme.fontSize.md,
    marginBottom: 12,
    textAlign: 'center',
  },
  retryBtn: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    backgroundColor: theme.colors.infoDim,
    borderRadius: theme.borderRadius.full,
  },
  retryText: {
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.semibold,
  },
  emptyText: {
    marginTop: 16,
    textAlign: 'center',
    color: theme.colors.muted,
    fontSize: theme.fontSize.md,
  },
});
