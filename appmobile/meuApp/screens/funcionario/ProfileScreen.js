import React, { useEffect, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { theme } from '../../src/theme';
import { clearStoredAccess, loadStoredAccess } from '../../src/access';
import { FuncionarioBottomNav } from '../../src/components';
import { fetchAuthJson } from '../modules/moduleApi';

function getInitials(name) {
  if (!name) return '?';
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function buildProfileItems(user, employee) {
  const items = [
    { icon: 'badge-account-outline', label: 'Nome', value: user?.name || user?.nome || '—' },
  ];
  if (user?.job_position_name) {
    items.push({ icon: 'briefcase-outline', label: 'Cargo', value: user.job_position_name });
  }
  if (employee?.position) {
    items.push({ icon: 'office-building-outline', label: 'Funcao', value: employee.position });
  }
  if (employee?.email || user?.email) {
    items.push({ icon: 'email-outline', label: 'Email', value: employee?.email || user.email });
  }
  if (employee?.phone) {
    items.push({ icon: 'phone-outline', label: 'Telefone', value: employee.phone });
  }
  if (employee?.employee_code) {
    items.push({ icon: 'card-account-details-outline', label: 'Codigo', value: employee.employee_code });
  }
  return items;
}

export default function ProfileScreen({ navigation }) {
  const [user, setUser] = useState(null);
  const [employee, setEmployee] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const { user: storedUser } = await loadStoredAccess();
        setUser(storedUser);

        if (storedUser?.employee_id) {
          try {
            const emp = await fetchAuthJson(`/hr/employees/${storedUser.employee_id}`);
            setEmployee(emp);
          } catch (_) {}
        }
      } catch (_) {
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  const handleLogout = async () => {
    await clearStoredAccess();
    navigation.reset({ index: 0, routes: [{ name: 'Login' }] });
  };

  const displayName = user?.name || user?.nome || '—';
  const initials = getInitials(displayName);
  const profileItems = buildProfileItems(user, employee);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Perfil</Text>
        <Text style={styles.headerSub}>Dados do funcionário</Text>
      </View>

      {loading ? (
        <View style={styles.loadingWrap}>
          <ActivityIndicator size="large" color={theme.colors.accent} />
        </View>
      ) : (
        <ScrollView contentContainerStyle={styles.body}>
          <View style={styles.heroCard}>
            <View style={styles.avatar}>
              <Text style={styles.avatarText}>{initials}</Text>
            </View>
            <View style={styles.heroInfo}>
              <Text style={styles.heroName}>{displayName}</Text>
              <Text style={styles.heroMeta}>
                {user?.job_position_name || employee?.position || 'Funcionário'}
                {employee?.employee_code ? ` · ${employee.employee_code}` : ''}
              </Text>
            </View>
            <View style={styles.statusBadge}>
              <Text style={styles.statusBadgeText}>
                {user?.is_active !== false ? 'Activo' : 'Inactivo'}
              </Text>
            </View>
          </View>

          <Text style={styles.sectionTitle}>Informação pessoal</Text>
          {profileItems.map((item) => (
            <View key={item.label} style={styles.infoCard}>
              <View style={styles.infoIconWrap}>
                <MaterialCommunityIcons name={item.icon} size={20} color={theme.colors.blue} />
              </View>
              <View style={styles.infoText}>
                <Text style={styles.infoLabel}>{item.label}</Text>
                <Text style={styles.infoValue}>{item.value}</Text>
              </View>
            </View>
          ))}

          <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
            <MaterialCommunityIcons name="logout" size={18} color={theme.colors.error} />
            <Text style={styles.logoutButtonText}>Sair</Text>
          </TouchableOpacity>
        </ScrollView>
      )}

      <FuncionarioBottomNav navigation={navigation} activeKey="profile" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.surface,
  },
  header: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  headerSub: {
    fontSize: 12,
    color: theme.colors.muted,
    marginTop: 2,
  },
  loadingWrap: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  body: {
    padding: 16,
    paddingBottom: 24,
  },
  heroCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface2,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 16,
    marginBottom: 14,
  },
  avatar: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: theme.colors.blueDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontSize: 18,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.blue,
  },
  heroInfo: {
    flex: 1,
  },
  heroName: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  heroMeta: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: theme.colors.successDim,
  },
  statusBadgeText: {
    color: theme.colors.success,
    fontSize: 11,
    fontWeight: theme.fontWeight.semibold,
  },
  sectionTitle: {
    fontSize: 12,
    color: theme.colors.muted,
    marginBottom: 10,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  infoCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
    marginBottom: 8,
  },
  infoIconWrap: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: theme.colors.blueDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  infoText: {
    flex: 1,
  },
  infoLabel: {
    fontSize: 11,
    color: theme.colors.muted,
    marginBottom: 2,
  },
  infoValue: {
    fontSize: 14,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  logoutButton: {
    marginTop: 10,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: theme.colors.redBorder,
    backgroundColor: theme.colors.redDim,
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    gap: 8,
  },
  logoutButtonText: {
    color: theme.colors.error,
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
  },
});
