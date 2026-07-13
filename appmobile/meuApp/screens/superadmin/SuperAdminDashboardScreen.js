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
import { SuperAdminNav } from './SuperAdminNav';

export default function SuperAdminDashboardScreen({ navigation }) {
  const [stats, setStats] = useState({ tenants: 0, planos: 0, ativos: 0 });
  const [recentTenants, setRecentTenants] = useState([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const token = await AsyncStorage.getItem('auth.token');
      const headers = { Authorization: `Bearer ${token}` };

      const [tenantsRes, planosRes] = await Promise.all([
        fetch(`${SISTEMA_BASE_URL}/tenants`, { headers }),
        fetch(`${SISTEMA_BASE_URL}/planos`, { headers }),
      ]);

      const tenants = tenantsRes.ok ? await tenantsRes.json() : [];
      const planos  = planosRes.ok  ? await planosRes.json()  : [];

      const lista       = Array.isArray(tenants) ? tenants : (tenants?.data || []);
      const listaPlanos = Array.isArray(planos)  ? planos  : (planos?.data  || []);

      setStats({
        tenants: lista.length,
        planos:  listaPlanos.length,
        ativos:  listaPlanos.filter((p) => p.is_active).length,
      });
      setRecentTenants(lista.slice(0, 5));
    } catch (_) {}
    finally { setLoading(false); }
  }, []);

  useFocusEffect(useCallback(() => { load(); }, [load]));

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.sidebarStart} />

      <View style={styles.hero}>
        <View style={styles.heroBadge}>
          <View style={styles.heroDot} />
          <Text style={styles.heroBadgeText}>SUPER ADMIN</Text>
        </View>
        <Text style={styles.heroTitle}>Painel do Sistema</Text>
        <Text style={styles.heroSub}>Gestao de tenants e planos da plataforma</Text>
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        {loading ? (
          <ActivityIndicator size="large" color={theme.colors.accent} style={{ marginTop: 32 }} />
        ) : (
          <>
            <View style={styles.statRow}>
              <TouchableOpacity
                style={styles.statCard}
                onPress={() => navigation.navigate('SuperAdminTenants')}
                activeOpacity={0.85}
              >
                <View style={[styles.statIcon, { backgroundColor: '#DBEAFE' }]}>
                  <MaterialCommunityIcons name="office-building-outline" size={20} color={theme.colors.blue} />
                </View>
                <Text style={styles.statValue}>{stats.tenants}</Text>
                <Text style={styles.statLabel}>Tenants</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.statCard}
                onPress={() => navigation.navigate('SuperAdminPlanos')}
                activeOpacity={0.85}
              >
                <View style={[styles.statIcon, { backgroundColor: '#D1FAE5' }]}>
                  <MaterialCommunityIcons name="layers-outline" size={20} color={theme.colors.green} />
                </View>
                <Text style={styles.statValue}>{stats.planos}</Text>
                <Text style={styles.statLabel}>Planos</Text>
              </TouchableOpacity>

              <View style={styles.statCard}>
                <View style={[styles.statIcon, { backgroundColor: '#FEF3C7' }]}>
                  <MaterialCommunityIcons name="check-decagram-outline" size={20} color={theme.colors.amber} />
                </View>
                <Text style={styles.statValue}>{stats.ativos}</Text>
                <Text style={styles.statLabel}>Ativos</Text>
              </View>
            </View>

            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>Tenants recentes</Text>
                <TouchableOpacity onPress={() => navigation.navigate('SuperAdminTenants')} activeOpacity={0.85}>
                  <Text style={styles.sectionAction}>Ver todos</Text>
                </TouchableOpacity>
              </View>

              {recentTenants.length === 0 ? (
                <View style={styles.emptyState}>
                  <MaterialCommunityIcons name="office-building-outline" size={28} color={theme.colors.muted} />
                  <Text style={styles.emptyText}>Sem tenants registados</Text>
                </View>
              ) : (
                recentTenants.map((t) => (
                  <TouchableOpacity
                    key={t.id}
                    style={styles.tenantRow}
                    onPress={() => navigation.navigate('SuperAdminTenantDetail', { tenant: t })}
                    activeOpacity={0.85}
                  >
                    <View style={styles.tenantAvatar}>
                      <Text style={styles.tenantAvatarText}>{(t.name || '?')[0].toUpperCase()}</Text>
                    </View>
                    <View style={styles.tenantInfo}>
                      <Text style={styles.tenantName}>{t.name}</Text>
                      <Text style={styles.tenantMeta}>{t.email || t.phone || t.country || '—'}</Text>
                    </View>
                    <MaterialCommunityIcons name="chevron-right" size={18} color={theme.colors.muted} />
                  </TouchableOpacity>
                ))
              )}
            </View>

            <View style={styles.quickSection}>
              <TouchableOpacity
                style={styles.quickCard}
                onPress={() => navigation.navigate('SuperAdminTenants', { openCreate: true })}
                activeOpacity={0.85}
              >
                <MaterialCommunityIcons name="plus-circle-outline" size={22} color={theme.colors.sidebarAccent} />
                <Text style={styles.quickLabel}>Novo Tenant</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.quickCard}
                onPress={() => navigation.navigate('SuperAdminPlanoForm', { plano: null })}
                activeOpacity={0.85}
              >
                <MaterialCommunityIcons name="plus-circle-outline" size={22} color={theme.colors.green} />
                <Text style={styles.quickLabel}>Novo Plano</Text>
              </TouchableOpacity>
            </View>
          </>
        )}
      </ScrollView>

      <SuperAdminNav navigation={navigation} activeKey="dashboard" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.bg },
  hero: {
    backgroundColor: theme.colors.sidebarStart,
    paddingHorizontal: 20, paddingTop: 20, paddingBottom: 24,
  },
  heroBadge: {
    flexDirection: 'row', alignItems: 'center', gap: 6,
    alignSelf: 'flex-start',
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderWidth: 1, borderColor: 'rgba(255,255,255,0.15)',
    borderRadius: 999, paddingHorizontal: 10, paddingVertical: 5, marginBottom: 14,
  },
  heroDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: '#10B981' },
  heroBadgeText: { color: '#fff', fontSize: 11, fontWeight: theme.fontWeight.semibold, letterSpacing: 0.8 },
  heroTitle: { color: '#fff', fontSize: 24, fontWeight: theme.fontWeight.bold, letterSpacing: -0.5 },
  heroSub: { color: 'rgba(255,255,255,0.6)', fontSize: 13, marginTop: 4 },

  scroll: { flex: 1 },
  body: { padding: 16, paddingBottom: 96, gap: 20 },

  statRow: { flexDirection: 'row', gap: 10 },
  statCard: {
    flex: 1, backgroundColor: theme.colors.surface,
    borderRadius: 16, borderWidth: 1, borderColor: theme.colors.border,
    padding: 14, alignItems: 'center', gap: 6,
  },
  statIcon: { width: 40, height: 40, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  statValue: { fontSize: 22, fontWeight: theme.fontWeight.bold, color: theme.colors.text },
  statLabel: { fontSize: 11, color: theme.colors.muted },

  section: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16, borderWidth: 1, borderColor: theme.colors.border,
    overflow: 'hidden',
  },
  sectionHeader: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: 16, paddingVertical: 12,
    borderBottomWidth: 1, borderBottomColor: theme.colors.border,
  },
  sectionTitle: { fontSize: 14, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  sectionAction: { fontSize: 12, color: theme.colors.sidebarAccent, fontWeight: theme.fontWeight.medium },

  tenantRow: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    paddingHorizontal: 16, paddingVertical: 13,
    borderBottomWidth: 1, borderBottomColor: theme.colors.border,
  },
  tenantAvatar: {
    width: 36, height: 36, borderRadius: 10,
    backgroundColor: theme.colors.sidebarStart,
    alignItems: 'center', justifyContent: 'center',
  },
  tenantAvatarText: { color: '#fff', fontSize: 14, fontWeight: theme.fontWeight.bold },
  tenantInfo: { flex: 1 },
  tenantName: { fontSize: 13, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  tenantMeta: { fontSize: 11, color: theme.colors.muted, marginTop: 2 },

  emptyState: { alignItems: 'center', padding: 24, gap: 8 },
  emptyText: { fontSize: 13, color: theme.colors.muted },

  quickSection: { flexDirection: 'row', gap: 10 },
  quickCard: {
    flex: 1, backgroundColor: theme.colors.surface,
    borderRadius: 14, borderWidth: 1, borderColor: theme.colors.border,
    paddingVertical: 16, alignItems: 'center', gap: 8,
  },
  quickLabel: { fontSize: 12, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
});
