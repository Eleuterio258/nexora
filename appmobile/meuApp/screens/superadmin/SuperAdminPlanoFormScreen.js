import React, { useEffect, useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, ScrollView,
  StyleSheet, SafeAreaView, StatusBar, ActivityIndicator,
  Switch, Alert,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { theme } from '../../src/theme';
import { SISTEMA_BASE_URL } from '../../src/config';

function Field({ label, required, children }) {
  return (
    <View style={styles.fieldWrap}>
      <Text style={styles.label}>{label}{required ? <Text style={styles.req}> *</Text> : null}</Text>
      {children}
    </View>
  );
}

export default function SuperAdminPlanoFormScreen({ route, navigation }) {
  const plano = route.params?.plano || null;
  const isEdit = !!plano;

  const [name, setName] = useState(plano?.name || '');
  const [code, setCode] = useState(plano?.code || '');
  const [description, setDescription] = useState(plano?.description || '');
  const [monthlyPrice, setMonthlyPrice] = useState(plano?.monthly_price != null ? String(plano.monthly_price) : '');
  const [annualPrice, setAnnualPrice] = useState(plano?.annual_price != null ? String(plano.annual_price) : '');
  const [maxUsers, setMaxUsers] = useState(plano?.max_users != null ? String(plano.max_users) : '');
  const [maxStorageGb, setMaxStorageGb] = useState(plano?.max_storage_gb != null ? String(plano.max_storage_gb) : '');
  const [isPublic, setIsPublic] = useState(plano?.is_public ?? true);
  const [isActive, setIsActive] = useState(plano?.is_active ?? true);
  const [saving, setSaving] = useState(false);

  const save = async () => {
    if (!name.trim()) { Alert.alert('Erro', 'O nome do plano e obrigatorio.'); return; }
    if (!code.trim()) { Alert.alert('Erro', 'O codigo do plano e obrigatorio.'); return; }

    setSaving(true);
    try {
      const token = await AsyncStorage.getItem('auth.token');
      const body = {
        name: name.trim(),
        code: code.trim().toUpperCase(),
        description: description.trim() || undefined,
        monthly_price: monthlyPrice ? Number(monthlyPrice) : undefined,
        annual_price: annualPrice ? Number(annualPrice) : undefined,
        max_users: maxUsers ? Number(maxUsers) : undefined,
        max_storage_gb: maxStorageGb ? Number(maxStorageGb) : undefined,
        is_public: isPublic,
        is_active: isActive,
      };

      const url = isEdit
        ? `${SISTEMA_BASE_URL}/planos/${plano.id}`
        : `${SISTEMA_BASE_URL}/planos`;
      const method = isEdit ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(body),
      });

      if (res.ok) {
        navigation.goBack();
      } else {
        const e = await res.json().catch(() => ({}));
        Alert.alert('Erro', e?.message || `Erro ${res.status} ao ${isEdit ? 'actualizar' : 'criar'} plano.`);
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
        <Text style={styles.headerTitle}>{isEdit ? 'Editar Plano' : 'Novo Plano'}</Text>
        <View style={{ width: 36 }} />
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.body} showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Identificacao</Text>

          <Field label="Nome" required>
            <TextInput
              style={styles.input}
              value={name}
              onChangeText={setName}
              placeholder="Ex: Basico, Pro, Enterprise"
              placeholderTextColor={theme.colors.muted}
            />
          </Field>

          <Field label="Codigo" required>
            <TextInput
              style={styles.input}
              value={code}
              onChangeText={(t) => setCode(t.toUpperCase())}
              placeholder="Ex: BASIC, PRO, ENT"
              placeholderTextColor={theme.colors.muted}
              autoCapitalize="characters"
              maxLength={20}
            />
          </Field>

          <Field label="Descricao">
            <TextInput
              style={[styles.input, styles.textarea]}
              value={description}
              onChangeText={setDescription}
              placeholder="Descricao resumida do plano..."
              placeholderTextColor={theme.colors.muted}
              multiline
              numberOfLines={3}
              textAlignVertical="top"
            />
          </Field>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Preco</Text>

          <View style={styles.row}>
            <View style={{ flex: 1 }}>
              <Field label="Mensal (MZN)">
                <TextInput
                  style={styles.input}
                  value={monthlyPrice}
                  onChangeText={setMonthlyPrice}
                  placeholder="0"
                  placeholderTextColor={theme.colors.muted}
                  keyboardType="numeric"
                />
              </Field>
            </View>
            <View style={{ width: 12 }} />
            <View style={{ flex: 1 }}>
              <Field label="Anual (MZN)">
                <TextInput
                  style={styles.input}
                  value={annualPrice}
                  onChangeText={setAnnualPrice}
                  placeholder="0"
                  placeholderTextColor={theme.colors.muted}
                  keyboardType="numeric"
                />
              </Field>
            </View>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Limites</Text>

          <View style={styles.row}>
            <View style={{ flex: 1 }}>
              <Field label="Max. Utilizadores">
                <TextInput
                  style={styles.input}
                  value={maxUsers}
                  onChangeText={setMaxUsers}
                  placeholder="Ilimitado"
                  placeholderTextColor={theme.colors.muted}
                  keyboardType="numeric"
                />
              </Field>
            </View>
            <View style={{ width: 12 }} />
            <View style={{ flex: 1 }}>
              <Field label="Armazenamento (GB)">
                <TextInput
                  style={styles.input}
                  value={maxStorageGb}
                  onChangeText={setMaxStorageGb}
                  placeholder="Ilimitado"
                  placeholderTextColor={theme.colors.muted}
                  keyboardType="numeric"
                />
              </Field>
            </View>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Configuracoes</Text>

          <View style={styles.toggleRow}>
            <View style={styles.toggleInfo}>
              <Text style={styles.toggleLabel}>Plano publico</Text>
              <Text style={styles.toggleSub}>Visivel para clientes no portal</Text>
            </View>
            <Switch
              value={isPublic}
              onValueChange={setIsPublic}
              trackColor={{ false: theme.colors.border2, true: theme.colors.sidebarAccent }}
              thumbColor="#fff"
            />
          </View>

          <View style={[styles.toggleRow, { borderBottomWidth: 0 }]}>
            <View style={styles.toggleInfo}>
              <Text style={styles.toggleLabel}>Plano activo</Text>
              <Text style={styles.toggleSub}>Disponivel para atribuicao a tenants</Text>
            </View>
            <Switch
              value={isActive}
              onValueChange={setIsActive}
              trackColor={{ false: theme.colors.border2, true: theme.colors.green }}
              thumbColor="#fff"
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
              <MaterialCommunityIcons name={isEdit ? 'content-save-outline' : 'plus'} size={18} color="#fff" />
              <Text style={styles.saveBtnText}>{isEdit ? 'Guardar alteracoes' : 'Criar plano'}</Text>
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
  headerTitle: { fontSize: 16, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },

  scroll: { flex: 1 },
  body: { padding: 16, paddingBottom: 40, gap: 16 },

  section: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16, borderWidth: 1, borderColor: theme.colors.border,
    padding: 16, gap: 0,
  },
  sectionTitle: {
    fontSize: 13, fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text, marginBottom: 14,
  },

  fieldWrap: { marginBottom: 14 },
  label: { fontSize: 12, color: theme.colors.muted, fontWeight: theme.fontWeight.medium, marginBottom: 6 },
  req: { color: theme.colors.red },
  input: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1, borderColor: theme.colors.border,
    borderRadius: 12, paddingHorizontal: 14, paddingVertical: 12,
    fontSize: 14, color: theme.colors.text,
  },
  textarea: { minHeight: 72, paddingTop: 12 },

  row: { flexDirection: 'row' },

  toggleRow: {
    flexDirection: 'row', alignItems: 'center',
    paddingVertical: 14,
    borderBottomWidth: 1, borderBottomColor: theme.colors.border,
  },
  toggleInfo: { flex: 1 },
  toggleLabel: { fontSize: 14, fontWeight: theme.fontWeight.medium, color: theme.colors.text },
  toggleSub: { fontSize: 11, color: theme.colors.muted, marginTop: 2 },

  saveBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8,
    backgroundColor: theme.colors.sidebarAccent,
    borderRadius: 14, paddingVertical: 16,
  },
  saveBtnText: { fontSize: 15, fontWeight: theme.fontWeight.semibold, color: '#fff' },
});
