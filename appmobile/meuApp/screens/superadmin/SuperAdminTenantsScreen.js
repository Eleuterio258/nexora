import React, { useCallback, useEffect, useState } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity, TextInput,
  StyleSheet, SafeAreaView, StatusBar, ActivityIndicator,
  Modal, Alert,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { theme } from '../../src/theme';
import { SISTEMA_BASE_URL } from '../../src/config';
import { SuperAdminNav } from './SuperAdminNav';

function TenantModal({ visible, onClose, onSaved, token }) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [country, setCountry] = useState('MZ');
  const [saving, setSaving] = useState(false);

  const reset = () => { setName(''); setEmail(''); setPhone(''); setCountry('MZ'); };

  const save = async () => {
    if (!name.trim()) { Alert.alert('Erro', 'O nome e obrigatorio.'); return; }
    setSaving(true);
    try {
      const body = { name: name.trim(), email: email || undefined, phone: phone || undefined, country };
      const res = await fetch(`${SISTEMA_BASE_URL}/tenants`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(body),
      });
      if (res.ok) { reset(); onSaved(); onClose(); }
      else { const e = await res.json(); Alert.alert('Erro', e?.message || 'Erro ao criar tenant.'); }
    } catch (_) { Alert.alert('Erro', 'Sem ligacao ao servidor.'); }
    finally { setSaving(false); }
  };

  return (
    <Modal visible={visible} transparent animationType="slide" statusBarTranslucent onRequestClose={onClose}>
      <View style={m.overlay}>
        <ScrollView
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
          contentContainerStyle={{ flexGrow: 1, justifyContent: 'flex-end' }}
        >
          <View style={m.sheet}>
            <View style={m.handle} />
            <Text style={m.title}>Novo Tenant</Text>

            <Text style={m.label}>Nome *</Text>
            <TextInput style={m.input} value={name} onChangeText={setName} placeholder="Nome da empresa" placeholderTextColor={theme.colors.muted} />

            <Text style={m.label}>Email</Text>
            <TextInput style={m.input} value={email} onChangeText={setEmail} placeholder="email@empresa.com" placeholderTextColor={theme.colors.muted} keyboardType="email-address" autoCapitalize="none" />

            <Text style={m.label}>Telefone</Text>
            <TextInput style={m.input} value={phone} onChangeText={setPhone} placeholder="+258 ..." placeholderTextColor={theme.colors.muted} keyboardType="phone-pad" />

            <Text style={m.label}>Pais</Text>
            <TextInput style={m.input} value={country} onChangeText={setCountry} placeholder="MZ" placeholderTextColor={theme.colors.muted} autoCapitalize="characters" maxLength={3} />

            <View style={m.actions}>
              <TouchableOpacity style={m.btnCancel} onPress={onClose} activeOpacity={0.85}>
                <Text style={m.btnCancelText}>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[m.btnSave, saving && { opacity: 0.7 }]} onPress={save} disabled={saving} activeOpacity={0.85}>
                <Text style={m.btnSaveText}>{saving ? 'A criar...' : 'Criar'}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </ScrollView>
      </View>
    </Modal>
  );
}

export default function SuperAdminTenantsScreen({ route, navigation }) {
  const [tenants, setTenants] = useState([]);
  const [filtered, setFiltered] = useState([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [token, setToken] = useState('');
  const [showCreate, setShowCreate] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const t = await AsyncStorage.getItem('auth.token');
      setToken(t || '');
      const res = await fetch(`${SISTEMA_BASE_URL}/tenants`, {
        headers: { Authorization: `Bearer ${t}` },
      });
      if (res.ok) {
        const data = await res.json();
        const lista = Array.isArray(data) ? data : (data?.data || []);
        setTenants(lista);
        setFiltered(lista);
      }
    } catch (_) {}
    finally { setLoading(false); }
  }, []);

  useFocusEffect(useCallback(() => { load(); }, [load]));

  useFocusEffect(
    useCallback(() => {
      if (route.params?.openCreate) {
        setShowCreate(true);
      }
    }, [route.params?.openCreate])
  );

  useEffect(() => {
    const q = search.toLowerCase();
    setFiltered(q ? tenants.filter((t) =>
      t.name?.toLowerCase().includes(q) || t.email?.toLowerCase().includes(q)
    ) : tenants);
  }, [search, tenants]);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>Tenants</Text>
          <Text style={styles.headerSub}>{tenants.length} empresa{tenants.length !== 1 ? 's' : ''} registada{tenants.length !== 1 ? 's' : ''}</Text>
        </View>
        <TouchableOpacity style={styles.addBtn} onPress={() => setShowCreate(true)} activeOpacity={0.85}>
          <MaterialCommunityIcons name="plus" size={18} color="#fff" />
          <Text style={styles.addBtnText}>Novo</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.searchWrap}>
        <MaterialCommunityIcons name="magnify" size={18} color={theme.colors.muted} />
        <TextInput
          style={styles.searchInput}
          value={search}
          onChangeText={setSearch}
          placeholder="Pesquisar tenant..."
          placeholderTextColor={theme.colors.muted}
        />
        {search ? (
          <TouchableOpacity onPress={() => setSearch('')}>
            <MaterialCommunityIcons name="close-circle" size={16} color={theme.colors.muted} />
          </TouchableOpacity>
        ) : null}
      </View>

      {loading ? (
        <ActivityIndicator size="large" color={theme.colors.accent} style={{ marginTop: 40 }} />
      ) : (
        <ScrollView style={styles.scroll} contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
          {filtered.length === 0 ? (
            <View style={styles.emptyState}>
              <MaterialCommunityIcons name="office-building-outline" size={36} color={theme.colors.muted} />
              <Text style={styles.emptyText}>{search ? 'Sem resultados' : 'Sem tenants'}</Text>
            </View>
          ) : (
            filtered.map((t) => (
              <TouchableOpacity
                key={t.id}
                style={styles.card}
                onPress={() => navigation.navigate('SuperAdminTenantDetail', { tenant: t })}
                activeOpacity={0.88}
              >
                <View style={styles.cardAvatar}>
                  <Text style={styles.cardAvatarText}>{(t.name || '?')[0].toUpperCase()}</Text>
                </View>
                <View style={styles.cardInfo}>
                  <Text style={styles.cardName}>{t.name}</Text>
                  <Text style={styles.cardMeta}>
                    {[t.email, t.phone, t.country].filter(Boolean).join(' · ') || '—'}
                  </Text>
                </View>
                <MaterialCommunityIcons name="chevron-right" size={18} color={theme.colors.muted} />
              </TouchableOpacity>
            ))
          )}
        </ScrollView>
      )}

      <TenantModal
        visible={showCreate}
        onClose={() => setShowCreate(false)}
        onSaved={load}
        token={token}
      />

      <SuperAdminNav navigation={navigation} activeKey="tenants" />
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

  searchWrap: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    marginHorizontal: 16, marginVertical: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: 1, borderColor: theme.colors.border,
    borderRadius: 12, paddingHorizontal: 12, paddingVertical: 10,
  },
  searchInput: { flex: 1, fontSize: 14, color: theme.colors.text },

  scroll: { flex: 1 },
  body: { paddingHorizontal: 16, paddingBottom: 96, gap: 8 },

  card: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    backgroundColor: theme.colors.surface,
    borderRadius: 14, borderWidth: 1, borderColor: theme.colors.border,
    padding: 14,
  },
  cardAvatar: {
    width: 42, height: 42, borderRadius: 12,
    backgroundColor: theme.colors.sidebarStart,
    alignItems: 'center', justifyContent: 'center',
  },
  cardAvatarText: { color: '#fff', fontSize: 16, fontWeight: theme.fontWeight.bold },
  cardInfo: { flex: 1 },
  cardName: { fontSize: 14, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  cardMeta: { fontSize: 12, color: theme.colors.muted, marginTop: 2 },

  emptyState: { alignItems: 'center', paddingTop: 48, gap: 10 },
  emptyText: { fontSize: 14, color: theme.colors.muted },
});

const m = StyleSheet.create({
  overlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.4)', justifyContent: 'flex-end' },
  sheet: {
    backgroundColor: theme.colors.surface,
    borderTopLeftRadius: 24, borderTopRightRadius: 24,
    padding: 24, paddingBottom: 36,
  },
  handle: {
    width: 40, height: 4, borderRadius: 2,
    backgroundColor: theme.colors.border2,
    alignSelf: 'center', marginBottom: 20,
  },
  title: { fontSize: 18, fontWeight: theme.fontWeight.bold, color: theme.colors.text, marginBottom: 20 },
  label: { fontSize: 12, color: theme.colors.muted, fontWeight: theme.fontWeight.medium, marginBottom: 6 },
  input: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1, borderColor: theme.colors.border,
    borderRadius: 12, paddingHorizontal: 14, paddingVertical: 12,
    fontSize: 14, color: theme.colors.text, marginBottom: 14,
  },
  actions: { flexDirection: 'row', gap: 10, marginTop: 6 },
  btnCancel: {
    flex: 1, paddingVertical: 14, borderRadius: 12,
    borderWidth: 1, borderColor: theme.colors.border,
    alignItems: 'center',
  },
  btnCancelText: { fontSize: 14, color: theme.colors.muted, fontWeight: theme.fontWeight.medium },
  btnSave: {
    flex: 1, paddingVertical: 14, borderRadius: 12,
    backgroundColor: theme.colors.sidebarAccent, alignItems: 'center',
  },
  btnSaveText: { fontSize: 14, color: '#fff', fontWeight: theme.fontWeight.semibold },
});
