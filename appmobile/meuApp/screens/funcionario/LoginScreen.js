import React, { useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Modal,
  StatusBar,
  ScrollView,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { API_BASE_URL } from '../../src/config';
import { MODULE_CATALOG, parseApiModules } from '../../src/access';

const QUICK_USERS = [
  { label: 'Admin',        username: 'admin',        password: 'admin123',       icon: 'shield-crown-outline',     color: '#6366f1' },
  { label: 'Super Admin',  username: 'super-admin',  password: 'superadmin123',  icon: 'shield-account-outline',   color: '#6366f1' },
  { label: 'Super Admin2', username: 'super_admin',  password: 'superadmin123',  icon: 'shield-star-outline',      color: '#6366f1' },
  { label: 'Gestor Geral', username: 'gestor',       password: 'superadmin123',  icon: 'briefcase-outline',        color: '#10b981' },
  { label: 'Funcionario',  username: 'funcionario',  password: 'superadmin123',  icon: 'account-outline',          color: '#3b82f6' },
  { label: 'Manager',      username: 'manager',      password: 'superadmin123',  icon: 'account-tie-outline',      color: '#10b981' },
  { label: 'User',         username: 'user',         password: 'superadmin123',  icon: 'account-circle-outline',   color: '#3b82f6' },
  { label: 'Vendas 1',     username: 'vendas1',      password: 'superadmin123',  icon: 'cart-outline',             color: '#f59e0b' },
  { label: 'Vendas 2',     username: 'vendas2',      password: 'superadmin123',  icon: 'cart-outline',             color: '#f59e0b' },
  { label: 'Caixa 1',      username: 'caixa1',       password: 'superadmin123',  icon: 'cash-register',            color: '#14b8a6' },
  { label: 'Caixa 2',      username: 'caixa2',       password: 'superadmin123',  icon: 'cash-register',            color: '#14b8a6' },
  { label: 'Estoque 1',    username: 'estoque1',     password: 'superadmin123',  icon: 'package-variant-closed',   color: '#8b5cf6' },
  { label: 'Estoque 2',    username: 'estoque2',     password: 'superadmin123',  icon: 'package-variant-closed',   color: '#8b5cf6' },
  { label: 'CRM 1',        username: 'crm1',         password: 'superadmin123',  icon: 'account-group-outline',    color: '#ec4899' },
  { label: 'CRM 2',        username: 'crm2',         password: 'superadmin123',  icon: 'account-group-outline',    color: '#ec4899' },
  { label: 'RH 1',         username: 'rh1',          password: 'superadmin123',  icon: 'human-male-board',         color: '#f97316' },
  { label: 'RH 2',         username: 'rh2',          password: 'superadmin123',  icon: 'human-male-board',         color: '#f97316' },
  { label: 'Folha',        username: 'folha1',       password: 'superadmin123',  icon: 'file-document-outline',    color: '#64748b' },
  { label: 'Entrega',      username: 'entrega1',     password: 'superadmin123',  icon: 'truck-delivery-outline',   color: '#06b6d4' },
  { label: 'Assinatura',   username: 'assinatura1',  password: 'superadmin123',  icon: 'draw-pen',                 color: '#a855f7' },
  { label: 'Relatorios',   username: 'relatorios1',  password: 'superadmin123',  icon: 'chart-bar',                color: '#84cc16' },
  { label: 'Operador 1',   username: 'operador1',    password: 'superadmin123',  icon: 'monitor-account',          color: '#94a3b8' },
  { label: 'Operador 2',   username: 'operador2',    password: 'superadmin123',  icon: 'monitor-account',          color: '#94a3b8' },
];

export default function LoginScreen({ navigation }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorModal, setErrorModal] = useState({ visible: false, title: '', message: '' });

  const showError = (title, message) => setErrorModal({ visible: true, title, message });
  const hideError = () => setErrorModal({ visible: false, title: '', message: '' });

  const isSuperAdmin = (rawRole) => {
    const r = `${rawRole || ''}`.toLowerCase().replace(/_/g, '-');
    return r === 'super-admin';
  };

  const extractEnvelopeData = (payload) => payload?.data || payload || {};

  const normalizeAuthPayload = (payload) => {
    const data = extractEnvelopeData(payload);
    const token = data?.token || data?.access_token || '';
    const rawUser = data?.user || {};

    const rawRole = rawUser?.role_name || rawUser?.role || '';
    const role = Array.isArray(rawRole) ? (rawRole[0] || '') : rawRole;

    const user = {
      id: rawUser?.id ?? null,
      username: rawUser?.username || rawUser?.employee_code || '',
      name: rawUser?.name || rawUser?.full_name || '',
      employee_id: rawUser?.employee_id ?? null,
      tenant_id: rawUser?.tenant_id ?? null,
      job_position_id: rawUser?.job_position_id ?? null,
      job_position_name: rawUser?.job_position_name || null,
      role,
      is_active: rawUser?.is_active ?? true,
    };

    // New API: modules = [{module, permissions}, ...]
    const { moduleKeys, permissions } = parseApiModules(data?.modules);
    const modules = moduleKeys.length > 0
      ? moduleKeys
      : isSuperAdmin(role) ? MODULE_CATALOG.map((m) => m.key) : [];

    return {
      token,
      refresh_token: data?.refresh_token || '',
      modules,
      permissions,
      user,
    };
  };

  const handleLogin = async () => {
    if (!username || !password) {
      showError('Campos obrigatorios', 'Preencha o utilizador e a senha para continuar.');
      return;
    }

    setIsSubmitting(true);

    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: username.trim(), password }),
      });

      let payload = null;
      try { payload = await response.json(); } catch (_) {}

      const authData = normalizeAuthPayload(payload);

      if (!response.ok || !authData.token) {
        const msg = payload?.message || payload?.error || `Erro HTTP ${response.status}`;
        showError('Falha no login', msg);
        return;
      }

      let modules = authData.modules;
      let permissions = authData.permissions;

      if (!isSuperAdmin(authData.user.role)) {
        try {
          const meRes = await fetch(`${API_BASE_URL}/me`, {
            headers: { 'Authorization': `Bearer ${authData.token}` },
          });
          if (meRes.ok) {
            const me = await meRes.json();
            const meData = extractEnvelopeData(me);
            if (meData?.modules) {
              const parsed = parseApiModules(meData.modules);
              if (parsed.moduleKeys.length > 0) {
                modules = parsed.moduleKeys;
                permissions = parsed.permissions;
              }
            }
            if (meData?.user) {
              authData.user = {
                ...authData.user,
                id: meData.user?.id ?? authData.user.id,
                username: meData.user?.username || authData.user.username,
                name: meData.user?.name || authData.user.name,
                employee_id: meData.user?.employee_id ?? authData.user.employee_id ?? null,
                tenant_id: meData.user?.tenant_id ?? authData.user.tenant_id ?? null,
                job_position_id: meData.user?.job_position_id ?? authData.user.job_position_id ?? null,
                job_position_name: meData.user?.job_position_name || authData.user.job_position_name || null,
                role: meData.user?.role_name || authData.user.role,
                is_active: meData.user?.is_active ?? authData.user.is_active,
              };
            }
          }
        } catch (_) {}
      }

      await AsyncStorage.multiSet([
        ['auth.token', authData.token],
        ['auth.refresh_token', authData.refresh_token],
        ['auth.user', JSON.stringify(authData.user)],
        ['auth.modules', JSON.stringify(modules)],
        ['auth.permissions', JSON.stringify(permissions)],
      ]);

      const isGestor = permissions.includes('admin.tenant');
      const dest = isSuperAdmin(authData.user.role)
        ? 'SuperAdminDashboard'
        : isGestor
          ? 'DashboardGestor'
          : 'HomeFunc';
      navigation.replace(dest);
    } catch (_) {
      showError('Sem ligacao', 'Nao foi possivel ligar ao servidor.\nVerifique a sua ligacao e tente novamente.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <Modal
        visible={errorModal.visible}
        transparent
        animationType="fade"
        onRequestClose={hideError}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <View style={styles.modalIconWrap}>
              <MaterialCommunityIcons name="alert-circle-outline" size={22} color={theme.colors.error} />
            </View>
            <Text style={styles.modalTitle}>{errorModal.title}</Text>
            <Text style={styles.modalMessage}>{errorModal.message}</Text>
            <View style={styles.modalDivider} />
            <View style={styles.modalActions}>
              <TouchableOpacity style={styles.modalBtn} onPress={hideError} activeOpacity={0.85}>
                <Text style={styles.modalBtnText}>Percebido</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
      <StatusBar barStyle="light-content" backgroundColor={theme.colors.sidebarStart} />

      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.heroSection}>
          <View style={styles.heroBadge}>
            <Text style={styles.heroBadgeText}>OMNISYS ERP</Text>
          </View>
          <Text style={styles.heroTitle}>Assiduidade inteligente para equipas modernas</Text>
          <Text style={styles.heroSubtitle}>
            O mesmo padrao visual do portal web, adaptado para mobile.
          </Text>
          <View style={styles.heroFeatures}>
            {[
              { icon: 'face-recognition', label: 'Facial' },
              { icon: 'map-marker-radius-outline', label: 'GPS' },
              { icon: 'nfc-variant', label: 'NFC' },
            ].map((f) => (
              <View key={f.label} style={styles.heroFeatureItem}>
                <MaterialCommunityIcons name={f.icon} size={16} color="#FFFFFF" />
                <Text style={styles.heroFeatureText}>{f.label}</Text>
              </View>
            ))}
          </View>
        </View>

        <View style={styles.formShell}>
          <View style={styles.formHeader}>
            <Text style={styles.formTitle}>Entrar</Text>
            <Text style={styles.formSubtitle}>Acesse a sua conta para continuar</Text>
          </View>

          <View style={styles.inputBlock}>
            <Text style={styles.inputLabel}>Utilizador</Text>
            <View style={styles.inputContainer}>
              <MaterialCommunityIcons name="account-outline" size={18} color={theme.colors.muted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="username"
                placeholderTextColor={theme.colors.muted}
                value={username}
                onChangeText={setUsername}
                autoCapitalize="none"
              />
            </View>
          </View>

          <View style={styles.inputBlock}>
            <Text style={styles.inputLabel}>Senha</Text>
            <View style={styles.inputContainer}>
              <MaterialCommunityIcons name="lock-outline" size={18} color={theme.colors.muted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Senha"
                placeholderTextColor={theme.colors.muted}
                value={password}
                onChangeText={setPassword}
                secureTextEntry={!showPassword}
              />
              <TouchableOpacity
                onPress={() => setShowPassword((current) => !current)}
                activeOpacity={0.7}
                style={styles.passwordToggle}
              >
                <MaterialCommunityIcons
                  name={showPassword ? 'eye-off-outline' : 'eye-outline'}
                  size={20}
                  color={theme.colors.muted}
                />
              </TouchableOpacity>
            </View>
          </View>

          <TouchableOpacity
            style={[styles.buttonPrimary, isSubmitting && styles.buttonPrimaryDisabled]}
            onPress={handleLogin}
            disabled={isSubmitting}
          >
            <Text style={styles.buttonPrimaryText}>{isSubmitting ? 'A autenticar...' : 'Entrar'}</Text>
          </TouchableOpacity>

          <View style={styles.divider}>
            <View style={styles.dividerLine} />
            <Text style={styles.dividerText}>acesso rapido</Text>
            <View style={styles.dividerLine} />
          </View>

          <View style={styles.quickGrid}>
            {QUICK_USERS.map((u) => (
              <TouchableOpacity
                key={u.username}
                style={styles.quickChip}
                onPress={() => { setUsername(u.username); setPassword(u.password); }}
                activeOpacity={0.75}
              >
                <View style={[styles.quickChipIcon, { backgroundColor: u.color + '1a' }]}>
                  <MaterialCommunityIcons name={u.icon} size={16} color={u.color} />
                </View>
                <View style={styles.quickChipInfo}>
                  <Text style={styles.quickChipLabel} numberOfLines={1}>{u.label}</Text>
                  <Text style={styles.quickChipUser} numberOfLines={1}>{u.username}</Text>
                </View>
              </TouchableOpacity>
            ))}
          </View>

          <TouchableOpacity
            style={styles.forgotPassword}
            onPress={() => navigation.navigate('ForgotPassword')}
          >
            <Text style={styles.forgotPasswordText}>Esqueceu a senha?</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.bg },
  scrollContent: { flexGrow: 1 },
  heroSection: {
    paddingHorizontal: 24,
    paddingTop: 24,
    paddingBottom: 28,
    backgroundColor: theme.colors.sidebarStart,
  },
  heroBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.18)',
    marginBottom: 18,
  },
  heroBadgeText: { color: '#FFFFFF', fontSize: 11, fontWeight: theme.fontWeight.semibold, letterSpacing: 1 },
  heroTitle: { color: '#FFFFFF', fontSize: 28, lineHeight: 34, fontWeight: theme.fontWeight.bold, marginBottom: 10 },
  heroSubtitle: { color: 'rgba(255,255,255,0.78)', fontSize: 14, lineHeight: 21, marginBottom: 20 },
  heroFeatures: { flexDirection: 'row', gap: 10 },
  heroFeatureItem: {
    flexDirection: 'row', alignItems: 'center', gap: 6,
    paddingHorizontal: 10, paddingVertical: 8, borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.08)', borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)',
  },
  heroFeatureText: { color: '#FFFFFF', fontSize: 12, fontWeight: theme.fontWeight.medium },
  formShell: {
    flex: 1, marginTop: -12, borderTopLeftRadius: 24, borderTopRightRadius: 24,
    backgroundColor: theme.colors.surface, paddingHorizontal: 24, paddingTop: 24, paddingBottom: 28,
  },
  formHeader: { marginBottom: 22 },
  formTitle: { fontSize: 24, color: theme.colors.text, fontWeight: theme.fontWeight.bold, marginBottom: 4 },
  formSubtitle: { fontSize: 14, color: theme.colors.muted },
  inputBlock: { marginBottom: 14 },
  inputLabel: { fontSize: 13, color: theme.colors.text, fontWeight: theme.fontWeight.medium, marginBottom: 8 },
  inputContainer: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: theme.colors.surface2, borderRadius: 12,
    paddingHorizontal: 14, borderWidth: 1, borderColor: theme.colors.border,
  },
  inputIcon: { marginRight: 10 },
  input: { flex: 1, paddingVertical: 14, fontSize: 14, color: theme.colors.text },
  passwordToggle: { marginLeft: 10, paddingVertical: 6 },
  buttonPrimary: {
    marginTop: 10, backgroundColor: theme.colors.sidebarAccent,
    borderRadius: 14, paddingVertical: 15, alignItems: 'center',
    shadowColor: theme.colors.sidebarAccent, shadowOpacity: 0.22,
    shadowRadius: 12, shadowOffset: { width: 0, height: 8 }, elevation: 4,
  },
  buttonPrimaryDisabled: { opacity: 0.7 },
  buttonPrimaryText: { color: '#FFFFFF', fontSize: 16, fontWeight: theme.fontWeight.semibold },
  divider: { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 22, marginBottom: 14 },
  dividerLine: { flex: 1, height: 1, backgroundColor: theme.colors.border },
  dividerText: { fontSize: 12, color: theme.colors.muted, textTransform: 'uppercase', letterSpacing: 0.8 },
  quickGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  quickChip: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    width: '48%', borderWidth: 1, borderColor: theme.colors.border,
    borderRadius: 12, padding: 10, backgroundColor: theme.colors.surface,
  },
  quickChipIcon: { width: 32, height: 32, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  quickChipInfo: { flex: 1 },
  quickChipLabel: { fontSize: 12, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  quickChipUser: { fontSize: 11, color: theme.colors.muted, marginTop: 1 },
  forgotPassword: { marginTop: 18, alignItems: 'center' },
  forgotPasswordText: { color: theme.colors.sidebarAccent, fontSize: 13, fontWeight: theme.fontWeight.medium },

  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15,23,42,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 24,
  },
  modalCard: {
    width: '100%',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius['2xl'],
    paddingTop: 28,
    paddingBottom: 20,
    paddingHorizontal: 24,
    elevation: 4,
    shadowColor: '#0F172A',
    shadowOpacity: 0.12,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 4 },
  },
  modalIconWrap: {
    width: 48,
    height: 48,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.errorDim,
    borderWidth: 1,
    borderColor: theme.colors.errorBorder,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  modalTitle: {
    fontSize: theme.fontSize['2xl'],
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginBottom: 8,
    letterSpacing: -0.3,
  },
  modalMessage: {
    fontSize: theme.fontSize.lg,
    color: theme.colors.muted,
    lineHeight: 22,
    marginBottom: 24,
  },
  modalDivider: {
    height: 1,
    backgroundColor: theme.colors.border,
    marginBottom: 16,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  modalBtn: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.sidebarAccent,
  },
  modalBtnText: {
    color: '#fff',
    fontSize: theme.fontSize.lg,
    fontWeight: theme.fontWeight.semibold,
  },
});
