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

const PLAN_COLORS = ['#2563EB', '#059669', '#D97706', '#7C3AED', '#0891B2'];

export default function SuperAdminPlanosScreen({ route, navigation }) {
  useFocusEffect(
    useCallback(() => {
      if (route.params?.openCreate) {
        navigation.navigate('SuperAdminPlanoForm', { plano: null });
      }
    }, [route.params?.openCreate, navigation])
  );
  const [planos, setPlanos] = useState([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const token = await AsyncStorage.getItem('auth.token');
      const res = await fetch(`${SISTEMA_BASE_URL}/planos`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        setPlanos(Array.isArray(data) ? data : (data?.data || []));
      }
    } catch (_) {}
    finally { setLoading(false); }
  }, []);

  useFocusEffect(useCallback(() => { load(); }, [load]));

  const fmt = (v) => v != null ? `${Number(v).toLocaleString('pt-PT')} MZN` : '—';

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>Planos</Text>
          <Text style={styles.headerSub}>{planos.length} plano{planos.length !== 1 ? 's' : ''} disponivel{planos.length !== 1 ? 'is' : ''}</Text>
        </View>
        <TouchableOpacity
          style={styles.addBtn}
          onPress={() => navigation.navigate('SuperAdminPlanoForm', { plano: null })}
          activeOpacity={0.85}
        >
          <MaterialCommunityIcons name="plus" size={18} color="#fff" />
          <Text style={styles.addBtnText}>Novo</Text>
        </TouchableOpacity>
      </View>

      {loading ? (
        <ActivityIndicator size="large" color={theme.colors.accent} style={{ marginTop: 40 }} />
      ) : (
        <ScrollView style={styles.scroll} contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
          {planos.length === 0 ? (
            <View style={styles.emptyState}>
              <MaterialCommunityIcons name="layers-outline" size={36} color={theme.colors.muted} />
              <Text style={styles.emptyText}>Sem planos configurados</Text>
            </View>
          ) : (
            planos.map((p, idx) => {
              const color = PLAN_COLORS[idx % PLAN_COLORS.length];
              const dimColor = color + '18';
              return (
                <TouchableOpacity
                  key={p.id}
                  style={[styles.card, { borderTopColor: color, borderTopWidth: 3 }]}
                  onPress={() => navigation.navigate('SuperAdminPlanoForm', { plano: p })}
                  activeOpacity={0.88}
                >
                  <View style={styles.cardHeader}>
                    <View style={[styles.cardIcon, { backgroundColor: dimColor }]}>
                      <MaterialCommunityIcons name="layers-outline" size={18} color={color} />
                    </View>
                    <View style={styles.cardMeta}>
                      <Text style={styles.cardName}>{p.name}</Text>
                      <Text style={[styles.cardCode, { color }]}>{p.code}</Text>
                    </View>
                    <View style={[styles.badge,
                      p.is_active
                        ? { backgroundColor: theme.colors.greenDim, borderColor: theme.colors.greenBorder }
                        : { backgroundColor: theme.colors.redDim, borderColor: theme.colors.redBorder }
                    ]}>
                      <Text style={[styles.badgeText, { color: p.is_active ? theme.colors.green : theme.colors.red }]}>
                        {p.is_active ? 'Ativo' : 'Inativo'}
                      </Text>
                    </View>
                  </View>

                  {p.description ? (
                    <Text style={styles.cardDesc}>{p.description}</Text>
                  ) : null}

                  <View style={styles.priceRow}>
                    <View style={styles.priceItem}>
                      <Text style={styles.priceLabel}>Mensal</Text>
                      <Text style={[styles.priceValue, { color }]}>{fmt(p.monthly_price)}</Text>
                    </View>
                    <View style={styles.priceDivider} />
                    <View style={styles.priceItem}>
                      <Text style={styles.priceLabel}>Anual</Text>
                      <Text style={[styles.priceValue, { color }]}>{fmt(p.annual_price)}</Text>
                    </View>
                  </View>

                  <View style={styles.limitsRow}>
                    <View style={styles.limitChip}>
                      <MaterialCommunityIcons name="account-multiple-outline" size={13} color={theme.colors.muted} />
                      <Text style={styles.limitText}>{p.max_users ?? '∞'} utilizadores</Text>
                    </View>
                    <View style={styles.limitChip}>
                      <MaterialCommunityIcons name="database-outline" size={13} color={theme.colors.muted} />
                      <Text style={styles.limitText}>{p.max_storage_gb ?? '∞'} GB</Text>
                    </View>
                    {p.is_public ? (
                      <View style={styles.limitChip}>
                        <MaterialCommunityIcons name="earth" size={13} color={theme.colors.muted} />
                        <Text style={styles.limitText}>Publico</Text>
                      </View>
                    ) : null}
                  </View>
                </TouchableOpacity>
              );
            })
          )}
        </ScrollView>
      )}

      <SuperAdminNav navigation={navigation} activeKey="planos" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.bg },
  header: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: 16, paddingTop: 14, paddingBottom: 12,
    borderBottomWidth: 1, borderBottomColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
  },
  headerTitle: { fontSize: 18, fontWeight: theme.fontWeight.bold, color: theme.colors.text },
  headerSub: { fontSize: 12, color: theme.colors.muted, marginTop: 2 },
  addBtn: {
    flexDirection: 'row', alignItems: 'center', gap: 5,
    backgroundColor: theme.colors.sidebarAccent,
    paddingHorizontal: 14, paddingVertical: 9,
    borderRadius: theme.borderRadius.full,
  },
  addBtnText: { color: '#fff', fontSize: 13, fontWeight: theme.fontWeight.semibold },

  scroll: { flex: 1 },
  body: { padding: 16, paddingBottom: 96, gap: 12 },

  card: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16, borderWidth: 1, borderColor: theme.colors.border,
    padding: 16, gap: 12, overflow: 'hidden',
  },
  cardHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  cardIcon: { width: 38, height: 38, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  cardMeta: { flex: 1 },
  cardName: { fontSize: 15, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  cardCode: { fontSize: 11, fontWeight: theme.fontWeight.medium, marginTop: 2 },
  cardDesc: { fontSize: 12, color: theme.colors.muted, lineHeight: 18 },

  badge: { paddingHorizontal: 8, paddingVertical: 4, borderRadius: 999, borderWidth: 1 },
  badgeText: { fontSize: 11, fontWeight: theme.fontWeight.semibold },

  priceRow: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: theme.colors.surface2,
    borderRadius: 12, borderWidth: 1, borderColor: theme.colors.border,
    overflow: 'hidden',
  },
  priceItem: { flex: 1, alignItems: 'center', paddingVertical: 10 },
  priceLabel: { fontSize: 11, color: theme.colors.muted },
  priceValue: { fontSize: 14, fontWeight: theme.fontWeight.bold, marginTop: 2 },
  priceDivider: { width: 1, height: '70%', backgroundColor: theme.colors.border },

  limitsRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  limitChip: {
    flexDirection: 'row', alignItems: 'center', gap: 4,
    backgroundColor: theme.colors.surface2,
    borderRadius: 999, borderWidth: 1, borderColor: theme.colors.border,
    paddingHorizontal: 10, paddingVertical: 5,
  },
  limitText: { fontSize: 11, color: theme.colors.muted },

  emptyState: { alignItems: 'center', paddingTop: 48, gap: 10 },
  emptyText: { fontSize: 14, color: theme.colors.muted },
});
