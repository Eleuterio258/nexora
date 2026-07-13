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

export default function ModuleCustomersScreen() {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [customers, setCustomers] = useState([]);

  const loadCustomers = async (isRefresh = false) => {
    try {
      if (isRefresh) setRefreshing(true);
      else setLoading(true);
      setError('');

      const data = await fetchAuthJson('/clientes?apenas_ativos=true');
      setCustomers(Array.isArray(data) ? data : []);
    } catch (err) {
      setError(err?.message || 'Nao foi possivel carregar os clientes.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadCustomers();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />
      <AppHeader title="Clientes" subtitle={`${customers.length} cliente${customers.length !== 1 ? 's' : ''} ativos`} />

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.body}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => loadCustomers(true)} tintColor={theme.colors.blue} />}
      >
        <SectionLabel>Carteira ativa</SectionLabel>

        {error ? (
          <View style={styles.errorCard}>
            <MaterialCommunityIcons name="alert-circle-outline" size={18} color={theme.colors.error} />
            <Text style={styles.errorText}>{error}</Text>
          </View>
        ) : null}

        {loading ? <Text style={styles.helperText}>A carregar clientes...</Text> : null}
        {!loading && customers.length === 0 ? <Text style={styles.helperText}>Nenhum cliente ativo encontrado.</Text> : null}

        {customers.map((customer) => (
          <View key={`${customer.id}`} style={styles.customerCard}>
            <View style={styles.headerRow}>
              <View style={styles.nameWrap}>
                <Text style={styles.customerName}>{customer.name}</Text>
                <Text style={styles.customerMeta}>
                  {[customer.city, customer.province].filter(Boolean).join(', ') || customer.country || 'Sem localizacao'}
                </Text>
              </View>
              <View style={styles.statusBadge}>
                <Text style={styles.statusText}>{customer.is_active ? 'Ativo' : 'Inativo'}</Text>
              </View>
            </View>

            <View style={styles.infoGrid}>
              <InfoItem icon="account-tie-outline" label="Contacto" value={customer.contact_person || 'Sem contacto'} />
              <InfoItem icon="phone-outline" label="Telefone" value={customer.phone || 'Sem telefone'} />
              <InfoItem icon="email-outline" label="Email" value={customer.email || 'Sem email'} />
              <InfoItem icon="identifier" label="NIF" value={customer.tax_id || 'Sem NIF'} />
            </View>

            <View style={styles.balanceRow}>
              <BalanceBox label="Limite de credito" value={formatCurrency(customer.credit_limit)} />
              <BalanceBox label="Saldo corrente" value={formatCurrency(customer.current_account_balance)} tone="warning" />
            </View>
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

function InfoItem({ icon, label, value }) {
  return (
    <View style={styles.infoItem}>
      <MaterialCommunityIcons name={icon} size={15} color={theme.colors.muted} />
      <View style={styles.infoTextWrap}>
        <Text style={styles.infoLabel}>{label}</Text>
        <Text style={styles.infoValue} numberOfLines={1}>{value}</Text>
      </View>
    </View>
  );
}

function BalanceBox({ label, value, tone = 'default' }) {
  const valueColor = tone === 'warning' ? theme.colors.amber : theme.colors.blue;
  const backgroundColor = tone === 'warning' ? theme.colors.amberDim : theme.colors.blueDim;

  return (
    <View style={[styles.balanceBox, { backgroundColor }]}>
      <Text style={styles.balanceLabel}>{label}</Text>
      <Text style={[styles.balanceValue, { color: valueColor }]}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.bg },
  scroll: { flex: 1 },
  body: { padding: 16, paddingBottom: 32 },
  helperText: { color: theme.colors.muted, fontSize: 12, marginBottom: 12 },
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
  customerCard: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 10,
    marginBottom: 14,
  },
  nameWrap: { flex: 1 },
  customerName: { fontSize: 15, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  customerMeta: { marginTop: 4, fontSize: 12, color: theme.colors.muted },
  statusBadge: {
    backgroundColor: theme.colors.greenDim,
    borderWidth: 1,
    borderColor: theme.colors.greenBorder,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  statusText: { fontSize: 11, color: theme.colors.green, fontWeight: theme.fontWeight.medium },
  infoGrid: { gap: 10, marginBottom: 14 },
  infoItem: { flexDirection: 'row', gap: 10, alignItems: 'center' },
  infoTextWrap: { flex: 1 },
  infoLabel: { fontSize: 11, color: theme.colors.muted },
  infoValue: { marginTop: 1, fontSize: 13, color: theme.colors.text },
  balanceRow: { flexDirection: 'row', gap: 10 },
  balanceBox: {
    flex: 1,
    borderRadius: 14,
    padding: 12,
  },
  balanceLabel: { fontSize: 11, color: theme.colors.muted, marginBottom: 4 },
  balanceValue: { fontSize: 14, fontWeight: theme.fontWeight.semibold },
});
