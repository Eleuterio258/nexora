import React, { useCallback, useState } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity,
  StyleSheet, SafeAreaView, StatusBar, ActivityIndicator,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { theme } from '../../src/theme';
import { SISTEMA_BASE_URL } from '../../src/config';

function InfoRow({ icon, label, value }) {
  if (!value) return null;
  return (
    <View style={styles.infoRow}>
      <MaterialCommunityIcons name={icon} size={15} color={theme.colors.muted} />
      <View style={styles.infoText}>
        <Text style={styles.infoLabel}>{label}</Text>
        <Text style={styles.infoValue}>{value}</Text>
      </View>
    </View>
  );
}

export default function SuperAdminTenantDetailScreen({ route, navigation }) {
  const { tenant } = route.params;
  const [plan, setPlan] = useState(null);
  const [loadingPlan, setLoadingPlan] = useState(true);

  const loadPlan = useCallback(async () => {
    setLoadingPlan(true);
    try {
      const token = await AsyncStorage.getItem('auth.token');
      const res = await fetch(`${SISTEMA_BASE_URL}/tenants/${tenant.id}/plano`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) { const data = await res.json(); setPlan(data); }
      else { setPlan(null); }
    } catch (_) { setPlan(null); }
    finally { setLoadingPlan(false); }
  }, [tenant.id]);

  useFocusEffect(useCallback(() => { loadPlan(); }, [loadPlan]));

  const formatDate = (d) => d ? new Date(d).toLocaleDateString('pt-PT') : '—';

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={22} color={theme.colors.text} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Detalhe do Tenant</Text>
        <View style={{ width: 36 }} />
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.heroCard}>
          <View style={styles.heroAvatar}>
            <Text style={styles.heroAvatarText}>{(tenant.name || '?')[0].toUpperCase()}</Text>
          </View>
          <Text style={styles.heroName}>{tenant.name}</Text>
          {tenant.trade_name ? <Text style={styles.heroTrade}>{tenant.trade_name}</Text> : null}
          <View style={[styles.heroBadge, { backgroundColor: tenant.deleted_at ? theme.colors.redDim : theme.colors.greenDim, borderColor: tenant.deleted_at ? theme.colors.redBorder : theme.colors.greenBorder }]}>
            <View style={[styles.heroBadgeDot, { backgroundColor: tenant.deleted_at ? theme.colors.red : theme.colors.green }]} />
            <Text style={[styles.heroBadgeText, { color: tenant.deleted_at ? theme.colors.red : theme.colors.green }]}>{tenant.deleted_at ? 'Inativo' : 'Activo'}</Text>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Informacoes</Text>
          <InfoRow icon="email-outline"    label="Email"    value={tenant.email} />
          <InfoRow icon="phone-outline"    label="Telefone" value={tenant.phone} />
          <InfoRow icon="map-marker-outline" label="Cidade"  value={tenant.city} />
          <InfoRow icon="earth"            label="Pais"     value={tenant.country} />
          <InfoRow icon="identifier"       label="NIF"      value={tenant.tax_id} />
          <InfoRow icon="calendar-outline" label="Criado em" value={formatDate(tenant.created_at)} />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Plano actual</Text>
          {loadingPlan ? (
            <ActivityIndicator size="small" color={theme.colors.accent} style={{ marginVertical: 16 }} />
          ) : plan ? (
            <View style={styles.planCard}>
              <View style={styles.planHeader}>
                <View style={styles.planIconWrap}>
                  <MaterialCommunityIcons name="layers-outline" size={20} color={theme.colors.blue} />
                </View>
                <View style={styles.planInfo}>
                  <Text style={styles.planName}>{plan.plan?.name || `Plano #${plan.plan_id}`}</Text>
                  <Text style={styles.planCode}>{plan.plan?.code || '—'}</Text>
                </View>
                <View style={[styles.planStatus, plan.is_active
                  ? { backgroundColor: theme.colors.greenDim, borderColor: theme.colors.greenBorder }
                  : { backgroundColor: theme.colors.redDim, borderColor: theme.colors.redBorder }
                ]}>
                  <Text style={[styles.planStatusText, { color: plan.is_active ? theme.colors.green : theme.colors.red }]}>
                    {plan.is_active ? 'Ativo' : 'Inativo'}
                  </Text>
                </View>
              </View>

              <View style={styles.planMeta}>
                <View style={styles.planMetaItem}>
                  <Text style={styles.planMetaLabel}>Inicio</Text>
                  <Text style={styles.planMetaValue}>{formatDate(plan.started_at)}</Text>
                </View>
                <View style={styles.planMetaItem}>
                  <Text style={styles.planMetaLabel}>Expira</Text>
                  <Text style={styles.planMetaValue}>{plan.expires_at ? formatDate(plan.expires_at) : 'Sem prazo'}</Text>
                </View>
                <View style={styles.planMetaItem}>
                  <Text style={styles.planMetaLabel}>Max Users</Text>
                  <Text style={styles.planMetaValue}>{plan.plan?.max_users ?? '—'}</Text>
                </View>
              </View>

              <TouchableOpacity
                style={styles.changePlanBtn}
                onPress={() => navigation.navigate('SuperAdminTenantPlano', { tenant, currentPlan: plan })}
                activeOpacity={0.85}
              >
                <MaterialCommunityIcons name="swap-horizontal" size={15} color={theme.colors.sidebarAccent} />
                <Text style={styles.changePlanText}>Alterar plano</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <View style={styles.noPlan}>
              <MaterialCommunityIcons name="layers-off-outline" size={24} color={theme.colors.muted} />
              <Text style={styles.noPlanText}>Sem plano atribuido</Text>
              <TouchableOpacity
                style={styles.assignPlanBtn}
                onPress={() => navigation.navigate('SuperAdminTenantPlano', { tenant, currentPlan: null })}
                activeOpacity={0.85}
              >
                <MaterialCommunityIcons name="plus" size={15} color="#fff" />
                <Text style={styles.assignPlanText}>Atribuir plano</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.bg },
  header: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: 12, paddingVertical: 14,
    borderBottomWidth: 1, borderBottomColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
  },
  backBtn: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center' },
  headerTitle: { fontSize: 16, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },

  scroll: { flex: 1 },
  body: { padding: 16, paddingBottom: 40, gap: 16 },

  heroCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16, borderWidth: 1, borderColor: theme.colors.border,
    padding: 20, alignItems: 'center', gap: 8,
  },
  heroAvatar: {
    width: 64, height: 64, borderRadius: 18,
    backgroundColor: theme.colors.sidebarStart,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: 4,
  },
  heroAvatarText: { color: '#fff', fontSize: 26, fontWeight: theme.fontWeight.bold },
  heroName: { fontSize: 20, fontWeight: theme.fontWeight.bold, color: theme.colors.text },
  heroTrade: { fontSize: 13, color: theme.colors.muted },
  heroBadge: {
    flexDirection: 'row', alignItems: 'center', gap: 5,
    paddingHorizontal: 10, paddingVertical: 5,
    borderRadius: 999, borderWidth: 1, marginTop: 4,
  },
  heroBadgeDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: theme.colors.green },
  heroBadgeText: { fontSize: 11, fontWeight: theme.fontWeight.semibold },

  section: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16, borderWidth: 1, borderColor: theme.colors.border,
    padding: 16, gap: 12,
  },
  sectionTitle: {
    fontSize: 13, fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text, marginBottom: 4,
  },

  infoRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  infoText: { flex: 1 },
  infoLabel: { fontSize: 11, color: theme.colors.muted },
  infoValue: { fontSize: 13, color: theme.colors.text, fontWeight: theme.fontWeight.medium, marginTop: 1 },

  planCard: {
    backgroundColor: theme.colors.surface2,
    borderRadius: 14, borderWidth: 1, borderColor: theme.colors.border,
    padding: 14, gap: 14,
  },
  planHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  planIconWrap: {
    width: 40, height: 40, borderRadius: 12,
    backgroundColor: theme.colors.blueDim,
    alignItems: 'center', justifyContent: 'center',
  },
  planInfo: { flex: 1 },
  planName: { fontSize: 14, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  planCode: { fontSize: 11, color: theme.colors.muted, marginTop: 2 },
  planStatus: {
    paddingHorizontal: 8, paddingVertical: 4,
    borderRadius: 999, borderWidth: 1,
  },
  planStatusText: { fontSize: 11, fontWeight: theme.fontWeight.semibold },
  planMeta: { flexDirection: 'row', gap: 0 },
  planMetaItem: { flex: 1, alignItems: 'center' },
  planMetaLabel: { fontSize: 11, color: theme.colors.muted },
  planMetaValue: { fontSize: 13, fontWeight: theme.fontWeight.semibold, color: theme.colors.text, marginTop: 2 },

  noPlan: {
    alignItems: 'center', padding: 20, gap: 10,
    backgroundColor: theme.colors.surface2,
    borderRadius: 14, borderWidth: 1, borderColor: theme.colors.border,
  },
  noPlanText: { fontSize: 13, color: theme.colors.muted },

  changePlanBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 6,
    paddingVertical: 10,
    borderRadius: 10, borderWidth: 1,
    borderColor: theme.colors.sidebarAccent + '40',
    backgroundColor: theme.colors.sidebarAccent + '0C',
  },
  changePlanText: { fontSize: 13, fontWeight: theme.fontWeight.medium, color: theme.colors.sidebarAccent },

  assignPlanBtn: {
    flexDirection: 'row', alignItems: 'center', gap: 6,
    backgroundColor: theme.colors.sidebarAccent,
    paddingHorizontal: 16, paddingVertical: 9,
    borderRadius: theme.borderRadius.full,
  },
  assignPlanText: { fontSize: 13, fontWeight: theme.fontWeight.semibold, color: '#fff' },
});
