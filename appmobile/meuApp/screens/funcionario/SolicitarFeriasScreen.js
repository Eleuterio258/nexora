import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  ActivityIndicator,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { Button, FuncionarioBottomNav } from '../../src/components';
import { fetchAuthJson } from '../modules/moduleApi';
import { loadStoredAccess } from '../../src/access';

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
  return d.toLocaleDateString('pt-PT', { day: '2-digit', month: 'short', year: 'numeric' });
}

function diffDays(start, end) {
  if (!start || !end) return 0;
  const a = new Date(start);
  const b = new Date(end);
  return Math.max(1, Math.round((b - a) / 86400000) + 1);
}

const TYPE_OPTIONS = ['Todos', ...Object.values(TYPE_LABELS)];

export default function SolicitarFeriasScreen({ navigation }) {
  const [leaves, setLeaves]           = useState([]);
  const [loading, setLoading]         = useState(true);
  const [error, setError]             = useState(null);
  const [employeeId, setEmployeeId]   = useState(null);
  const [selectedType, setSelectedType] = useState('Todos');
  const [isTypeOpen, setIsTypeOpen]   = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { user } = await loadStoredAccess();
      const empId = user?.employee_id;
      setEmployeeId(empId);

      const path = empId ? `/hr/employees/${empId}/leaves` : '/hr/leaves';
      const data = await fetchAuthJson(path);
      const list = Array.isArray(data) ? data : (data?.items || []);
      setLeaves(list);
    } catch (err) {
      setError(err.message || 'Erro ao carregar pedidos');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const filteredLeaves = useMemo(() => {
    if (selectedType === 'Todos') return leaves;
    const key = Object.entries(TYPE_LABELS).find(([, v]) => v === selectedType)?.[0];
    return key ? leaves.filter((l) => l.type === key) : leaves;
  }, [leaves, selectedType]);

  function buildRequestForDetail(leave) {
    const days = diffDays(leave.start_date, leave.end_date);
    return {
      type: TYPE_LABELS[leave.type] || leave.type,
      period: `${formatDate(leave.start_date)} - ${formatDate(leave.end_date)}`,
      status: STATUS_LABELS[leave.status] || leave.status,
      detail: `${days} dia${days !== 1 ? 's' : ''} solicitado${days !== 1 ? 's' : ''}`,
      daysLabel: `${days} dia${days !== 1 ? 's' : ''}`,
      submittedAt: formatDate(leave.created_at),
      reason: leave.notes || '',
      attachmentName: '',
      timeline: [],
    };
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>Meus Pedidos</Text>
          <Text style={styles.headerSub}>Lista dos seus pedidos de ferias, dispensa e licenca pessoal</Text>
        </View>
        <TouchableOpacity
          style={styles.headerAction}
          onPress={() => navigation.navigate('SolicitarFeriasForm')}
          activeOpacity={0.85}
        >
          <MaterialCommunityIcons name="plus" size={18} color="#FFFFFF" />
          <Text style={styles.headerActionText}>Novo</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.balanceCard}>
          <View style={styles.balanceIcon}>
            <MaterialCommunityIcons name="clipboard-text-outline" size={20} color={theme.colors.accent} />
          </View>
          <View style={styles.balanceInfo}>
            <Text style={styles.balanceLabel}>Resumo</Text>
            {loading ? (
              <ActivityIndicator size="small" color={theme.colors.accent} style={{ marginTop: 4 }} />
            ) : (
              <>
                <Text style={styles.balanceValue}>{leaves.length} pedido{leaves.length !== 1 ? 's' : ''} registado{leaves.length !== 1 ? 's' : ''}</Text>
                <Text style={styles.balanceMeta}>Toque num pedido para abrir o detalhe completo</Text>
              </>
            )}
          </View>
        </View>

        <Text style={styles.filterLabel}>Tipo</Text>
        <View style={styles.dropdownWrap}>
          <TouchableOpacity
            style={styles.dropdownTrigger}
            onPress={() => setIsTypeOpen((open) => !open)}
            activeOpacity={0.9}
          >
            <Text style={styles.dropdownTriggerText}>{selectedType}</Text>
            <MaterialCommunityIcons
              name={isTypeOpen ? 'chevron-up' : 'chevron-down'}
              size={20}
              color={theme.colors.muted}
            />
          </TouchableOpacity>

          {isTypeOpen ? (
            <View style={styles.dropdownMenu}>
              {TYPE_OPTIONS.map((option) => {
                const isSelected = option === selectedType;
                return (
                  <TouchableOpacity
                    key={option}
                    style={[styles.dropdownItem, isSelected && styles.dropdownItemActive]}
                    onPress={() => { setSelectedType(option); setIsTypeOpen(false); }}
                    activeOpacity={0.9}
                  >
                    <Text style={[styles.dropdownItemText, isSelected && styles.dropdownItemTextActive]}>
                      {option}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          ) : null}
        </View>

        <Button label="Ir para formulario de pedido" onPress={() => navigation.navigate('SolicitarFeriasForm')} />

        {error ? (
          <View style={styles.errorWrap}>
            <Text style={styles.errorText}>{error}</Text>
            <TouchableOpacity onPress={load} style={styles.retryBtn}>
              <Text style={styles.retryText}>Tentar novamente</Text>
            </TouchableOpacity>
          </View>
        ) : loading ? (
          <ActivityIndicator size="large" color={theme.colors.accent} style={{ marginTop: 24 }} />
        ) : (
          <View style={styles.listSection}>
            {filteredLeaves.length === 0 ? (
              <Text style={styles.emptyText}>Nenhum pedido encontrado.</Text>
            ) : (
              filteredLeaves.map((leave, index) => {
                const days = diffDays(leave.start_date, leave.end_date);
                const typeLabel   = TYPE_LABELS[leave.type] || leave.type;
                const statusLabel = STATUS_LABELS[leave.status] || leave.status;
                return (
                  <TouchableOpacity
                    key={leave.id || index}
                    style={styles.requestCard}
                    activeOpacity={0.9}
                    onPress={() => navigation.navigate('DetalhePedido', { request: buildRequestForDetail(leave) })}
                  >
                    <View style={styles.requestHead}>
                      <Text style={styles.requestType}>{typeLabel}</Text>
                      <Text style={styles.requestStatus}>{statusLabel}</Text>
                    </View>
                    <Text style={styles.requestMeta}>
                      {formatDate(leave.start_date)} — {formatDate(leave.end_date)}
                    </Text>
                    <Text style={styles.requestDetail}>
                      {days} dia{days !== 1 ? 's' : ''} solicitado{days !== 1 ? 's' : ''}
                    </Text>
                    <View style={styles.requestFooter}>
                      <Text style={styles.requestHint}>Ver detalhe do pedido</Text>
                      <MaterialCommunityIcons name="chevron-right" size={18} color={theme.colors.muted} />
                    </View>
                  </TouchableOpacity>
                );
              })
            )}
          </View>
        )}
      </ScrollView>

      <FuncionarioBottomNav navigation={navigation} activeKey="ferias" />
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
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 14,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  headerInfo: {
    flex: 1,
  },
  headerAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: theme.colors.accent,
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  headerActionText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: theme.fontWeight.semibold,
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
  balanceCard: {
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
  balanceIcon: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  balanceInfo: {
    flex: 1,
  },
  balanceLabel: {
    fontSize: 11,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  balanceValue: {
    fontSize: 18,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginTop: 3,
  },
  balanceMeta: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
  filterLabel: {
    fontSize: 12,
    color: theme.colors.muted,
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  dropdownWrap: {
    marginBottom: 14,
  },
  dropdownTrigger: {
    minHeight: 48,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 14,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  dropdownTriggerText: {
    fontSize: 14,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  dropdownMenu: {
    marginTop: 8,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    overflow: 'hidden',
  },
  dropdownItem: {
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  dropdownItemActive: {
    backgroundColor: theme.colors.infoDim,
  },
  dropdownItemText: {
    fontSize: 14,
    color: theme.colors.text,
  },
  dropdownItemTextActive: {
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.semibold,
  },
  listSection: {
    marginTop: 12,
  },
  errorWrap: {
    marginTop: 24,
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
    borderRadius: 999,
  },
  retryText: {
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.semibold,
  },
  emptyText: {
    marginTop: 24,
    textAlign: 'center',
    color: theme.colors.muted,
    fontSize: theme.fontSize.md,
  },
  requestCard: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
  },
  requestHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10,
    marginBottom: 4,
  },
  requestType: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  requestStatus: {
    fontSize: 12,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.accent,
  },
  requestMeta: {
    fontSize: 12,
    color: theme.colors.muted,
    marginTop: 2,
  },
  requestDetail: {
    fontSize: 12,
    color: theme.colors.text,
    marginTop: 8,
  },
  requestFooter: {
    marginTop: 12,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  requestHint: {
    fontSize: 12,
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.medium,
  },
});
