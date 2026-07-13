import React, { useCallback, useEffect, useState } from 'react';
import {
  View, Text, TouchableOpacity, ScrollView,
  StyleSheet, SafeAreaView, StatusBar, ActivityIndicator,
  TextInput, Alert,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { theme } from '../../src/theme';
import { SISTEMA_BASE_URL } from '../../src/config';

const PLAN_COLORS = ['#2563EB', '#059669', '#D97706', '#7C3AED', '#0891B2'];

export default function SuperAdminTenantPlanoScreen({ route, navigation }) {
  const { tenant, currentPlan } = route.params;

  const [planos, setPlanos] = useState([]);
  const [selectedId, setSelectedId] = useState(currentPlan?.plan_id || null);
  const [startsAt, setStartsAt] = useState(
    currentPlan?.started_at ? currentPlan.started_at.substring(0, 10) : new Date().toISOString().substring(0, 10)
  );
  const [expiresAt, setExpiresAt] = useState(
    currentPlan?.expires_at ? currentPlan.expires_at.substring(0, 10) : ''
  );
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const token = await AsyncStorage.getItem('auth.token');
      const res = await fetch(`${SISTEMA_BASE_URL}/planos`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        const lista = Array.isArray(data) ? data : (data?.data || []);
        setPlanos(lista.filter((p) => p.is_active));
      }
    } catch (_) {}
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const save = async () => {
    if (!selectedId) { Alert.alert('Erro', 'Seleccione um plano.'); return; }
    if (!startsAt) { Alert.alert('Erro', 'A data de inicio e obrigatoria.'); return; }

    setSaving(true);
    try {
      const token = await AsyncStorage.getItem('auth.token');
      const body = {
        plan_id: selectedId,
        started_at: startsAt,
        expires_at: expiresAt || null,
        is_active: true,
      };

      const isExisting = !!currentPlan;
      const url = `${SISTEMA_BASE_URL}/tenants/${tenant.id}/plano`;
      const method = isExisting ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(body),
      });

      if (res.ok) {
        navigation.goBack();
      } else {
        const e = await res.json().catch(() => ({}));
        Alert.alert('Erro', e?.message || `Erro ${res.status} ao atribuir plano.`);
      }
    } catch (_) {
      Alert.alert('Erro', 'Sem ligacao ao servidor.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={22} color={theme.colors.text} />
        </TouchableOpacity>
        <View style={styles.headerCenter}>
          <Text style={styles.headerTitle}>{currentPlan ? 'Alterar Plano' : 'Atribuir Plano'}</Text>
          <Text style={styles.headerSub}>{tenant.name}</Text>
        </View>
        <View style={{ width: 36 }} />
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Seleccionar plano</Text>
          {loading ? (
            <ActivityIndicator size="small" color={theme.colors.accent} style={{ marginVertical: 20 }} />
          ) : planos.length === 0 ? (
            <View style={styles.empty}>
              <MaterialCommunityIcons name="layers-off-outline" size={28} color={theme.colors.muted} />
              <Text style={styles.emptyText}>Sem planos activos disponiveis</Text>
            </View>
          ) : (
            planos.map((p, idx) => {
              const color = PLAN_COLORS[idx % PLAN_COLORS.length];
              const selected = selectedId === p.id;
              return (
                <TouchableOpacity
                  key={p.id}
                  style={[styles.planRow, selected && { borderColor: color, backgroundColor: color + '0A' }]}
                  onPress={() => setSelectedId(p.id)}
                  activeOpacity={0.85}
                >
                  <View style={[styles.planIcon, { backgroundColor: color + '18' }]}>
                    <MaterialCommunityIcons name="layers-outline" size={18} color={color} />
                  </View>
                  <View style={styles.planInfo}>
                    <Text style={styles.planName}>{p.name}</Text>
                    <Text style={[styles.planCode, { color }]}>{p.code}</Text>
                  </View>
                  <View style={[styles.radio, selected && { borderColor: color, backgroundColor: color }]}>
                    {selected ? <View style={styles.radioDot} /> : null}
                  </View>
                </TouchableOpacity>
              );
            })
          )}
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Periodo</Text>

          <View style={styles.fieldWrap}>
            <Text style={styles.label}>Data de inicio <Text style={styles.req}>*</Text></Text>
            <TextInput
              style={styles.input}
              value={startsAt}
              onChangeText={setStartsAt}
              placeholder="AAAA-MM-DD"
              placeholderTextColor={theme.colors.muted}
              keyboardType="numbers-and-punctuation"
              maxLength={10}
            />
          </View>

          <View style={[styles.fieldWrap, { marginBottom: 0 }]}>
            <Text style={styles.label}>Data de expiracao <Text style={styles.opt}>(opcional)</Text></Text>
            <TextInput
              style={styles.input}
              value={expiresAt}
              onChangeText={setExpiresAt}
              placeholder="AAAA-MM-DD  —  deixar vazio = sem prazo"
              placeholderTextColor={theme.colors.muted}
              keyboardType="numbers-and-punctuation"
              maxLength={10}
            />
          </View>
        </View>

        <TouchableOpacity
          style={[styles.saveBtn, saving && { opacity: 0.7 }]}
          onPress={save}
          disabled={saving}
          activeOpacity={0.85}
        >
          {saving ? (
            <ActivityIndicator size="small" color="#fff" />
          ) : (
            <>
              <MaterialCommunityIcons name="check" size={18} color="#fff" />
              <Text style={styles.saveBtnText}>{currentPlan ? 'Actualizar plano' : 'Atribuir plano'}</Text>
            </>
          )}
        </TouchableOpacity>

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
  headerCenter: { flex: 1, alignItems: 'center' },
  headerTitle: { fontSize: 16, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  headerSub: { fontSize: 11, color: theme.colors.muted, marginTop: 1 },

  scroll: { flex: 1 },
  body: { padding: 16, paddingBottom: 40, gap: 16 },

  section: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16, borderWidth: 1, borderColor: theme.colors.border,
    padding: 16, gap: 10,
  },
  sectionTitle: {
    fontSize: 13, fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text, marginBottom: 4,
  },

  planRow: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    borderRadius: 14, borderWidth: 1.5, borderColor: theme.colors.border,
    padding: 14,
  },
  planIcon: { width: 38, height: 38, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  planInfo: { flex: 1 },
  planName: { fontSize: 14, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  planCode: { fontSize: 11, fontWeight: theme.fontWeight.medium, marginTop: 2 },
  radio: {
    width: 20, height: 20, borderRadius: 10,
    borderWidth: 2, borderColor: theme.colors.border2,
    alignItems: 'center', justifyContent: 'center',
  },
  radioDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: '#fff' },

  fieldWrap: { marginBottom: 14 },
  label: { fontSize: 12, color: theme.colors.muted, fontWeight: theme.fontWeight.medium, marginBottom: 6 },
  req: { color: theme.colors.red },
  opt: { fontWeight: '400', color: theme.colors.muted },
  input: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1, borderColor: theme.colors.border,
    borderRadius: 12, paddingHorizontal: 14, paddingVertical: 12,
    fontSize: 14, color: theme.colors.text,
  },

  empty: { alignItems: 'center', paddingVertical: 24, gap: 8 },
  emptyText: { fontSize: 13, color: theme.colors.muted },

  saveBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8,
    backgroundColor: theme.colors.sidebarAccent,
    borderRadius: 14, paddingVertical: 16,
  },
  saveBtnText: { fontSize: 15, fontWeight: theme.fontWeight.semibold, color: '#fff' },
});
