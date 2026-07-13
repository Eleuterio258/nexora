import React, { useCallback, useEffect, useState } from 'react';
import {
  View,
  Text,
  TextInput,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  StatusBar,
  ActivityIndicator,
} from 'react-native';
import { theme } from '../../src/theme';
import { AppHeader, Badge, GestorBottomNav } from '../../src/components';
import { fetchAuthJson } from '../modules/moduleApi';

function getInitials(name) {
  if (!name) return '?';
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

// Map attendance status to display values
function getAvatarStyle(status) {
  const map = {
    present: { backgroundColor: theme.colors.greenDim, color: theme.colors.green, borderColor: theme.colors.greenBorder },
    absent:  { backgroundColor: theme.colors.redDim,   color: theme.colors.red,   borderColor: theme.colors.redBorder   },
    late:    { backgroundColor: theme.colors.amberDim, color: theme.colors.amber, borderColor: theme.colors.amberBorder },
    leave:   { backgroundColor: theme.colors.blueDim,  color: theme.colors.blue,  borderColor: theme.colors.blueBorder  },
  };
  return map[status] || map.absent;
}

function getBadgeVariant(status) {
  const map = { present: 'success', absent: 'danger', late: 'warning', leave: 'info' };
  return map[status] || 'default';
}

function getBadgeLabel(status) {
  const map = { present: 'Presente', absent: 'Ausente', late: 'Atrasado', leave: 'De licenca' };
  return map[status] || status;
}

function buildFilterLabel(key, counts) {
  const labels = {
    all:     `Todos (${counts.all})`,
    present: `Presentes (${counts.present})`,
    absent:  `Ausentes (${counts.absent})`,
    late:    `Atrasados (${counts.late})`,
  };
  return labels[key];
}

export default function EquipaScreenGestor({ navigation }) {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading]     = useState(true);
  const [error, setError]         = useState(null);
  const [search, setSearch]       = useState('');
  const [activeFilter, setActiveFilter] = useState('all');

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fetchAuthJson('/hr/employees?active=true&limit=200');
      const list = Array.isArray(data) ? data : (data?.items || []);
      setEmployees(list);
    } catch (err) {
      setError(err.message || 'Erro ao carregar equipa');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  // Derive status from attendance field if present; fall back to 'present' for active employees
  function getStatus(emp) {
    return emp.attendance_status || 'present';
  }

  const counts = employees.reduce(
    (acc, emp) => {
      const s = getStatus(emp);
      acc.all++;
      if (s === 'present') acc.present++;
      else if (s === 'absent') acc.absent++;
      else if (s === 'late') acc.late++;
      return acc;
    },
    { all: 0, present: 0, absent: 0, late: 0 },
  );

  const filterKeys = ['all', 'present', 'absent', 'late'];

  const filtered = employees.filter((emp) => {
    const matchSearch = !search || emp.full_name.toLowerCase().includes(search.toLowerCase()) ||
      (emp.employee_code || '').toLowerCase().includes(search.toLowerCase());
    const status = getStatus(emp);
    const matchFilter = activeFilter === 'all' || status === activeFilter;
    return matchSearch && matchFilter;
  });

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader
        title="Equipa"
        subtitle={`${counts.all} funcionário${counts.all !== 1 ? 's' : ''}`}
      />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.body}>
          <TextInput
            style={styles.searchInput}
            placeholder="Pesquisar por nome ou código…"
            placeholderTextColor={theme.colors.muted}
            value={search}
            onChangeText={setSearch}
          />

          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.filterRow}
            style={styles.filterScroller}
          >
            {filterKeys.map((key) => {
              const label = buildFilterLabel(key, counts);
              const isActive = activeFilter === key;
              return (
                <TouchableOpacity
                  key={key}
                  style={[styles.filterChip, isActive && styles.filterChipActive]}
                  onPress={() => setActiveFilter(key)}
                  activeOpacity={0.9}
                >
                  {isActive ? <View style={styles.filterChipIndicator} /> : null}
                  <Text style={[styles.filterChipText, isActive && styles.filterChipTextActive]}>
                    {label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </ScrollView>

          <TouchableOpacity
            style={styles.leaveShortcut}
            onPress={() => navigation.navigate('PedidoFerias')}
            activeOpacity={0.9}
          >
            <View>
              <Text style={styles.leaveShortcutLabel}>Pedidos recebidos</Text>
              <Text style={styles.leaveShortcutTitle}>Validar pedidos de férias</Text>
            </View>
            <Text style={styles.leaveShortcutAction}>Ver</Text>
          </TouchableOpacity>

          {loading ? (
            <ActivityIndicator size="large" color={theme.colors.accent} style={{ marginTop: 32 }} />
          ) : error ? (
            <View style={styles.errorWrap}>
              <Text style={styles.errorText}>{error}</Text>
              <TouchableOpacity onPress={load} style={styles.retryBtn}>
                <Text style={styles.retryText}>Tentar novamente</Text>
              </TouchableOpacity>
            </View>
          ) : filtered.length === 0 ? (
            <Text style={styles.emptyText}>Nenhum funcionário encontrado.</Text>
          ) : (
            filtered.map((emp) => {
              const status     = getStatus(emp);
              const avatarStyle = getAvatarStyle(status);
              return (
                <TouchableOpacity
                  key={emp.id}
                  style={styles.personItem}
                  onPress={() => navigation.navigate('DetalheFuncionario', {
                    id: emp.id,
                    name: emp.full_name,
                    initials: getInitials(emp.full_name),
                    dept: emp.position || '—',
                    status,
                  })}
                >
                  <View style={[styles.avatar, avatarStyle]}>
                    <Text style={[styles.avatarText, { color: avatarStyle.color }]}>
                      {getInitials(emp.full_name)}
                    </Text>
                  </View>
                  <View style={styles.personInfo}>
                    <Text style={styles.personName}>{emp.full_name}</Text>
                    <Text style={styles.personMeta}>
                      {emp.position || '—'}
                      {emp.employee_code ? ` · ${emp.employee_code}` : ''}
                    </Text>
                  </View>
                  <Badge label={getBadgeLabel(status)} variant={getBadgeVariant(status)} />
                </TouchableOpacity>
              );
            })
          )}
        </View>
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="equipa" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg,
  },
  content: {
    flex: 1,
  },
  body: {
    padding: 16,
  },
  searchInput: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: theme.borderRadius.base,
    paddingHorizontal: 13,
    paddingVertical: 10,
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
    marginBottom: 12,
  },
  filterScroller: {
    marginBottom: 16,
    marginHorizontal: -2,
  },
  filterRow: {
    flexDirection: 'row',
    gap: 10,
    paddingHorizontal: 2,
  },
  filterChip: {
    minHeight: 40,
    paddingHorizontal: 16,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    backgroundColor: theme.colors.surface,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  filterChipActive: {
    backgroundColor: theme.colors.infoDim,
    borderColor: theme.colors.blueBorder,
  },
  filterChipIndicator: {
    width: 8,
    height: 8,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.accent,
    marginRight: 8,
  },
  filterChipText: {
    fontSize: 13,
    lineHeight: 18,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  filterChipTextActive: {
    color: theme.colors.accent,
  },
  leaveShortcut: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: theme.borderRadius.lg,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  leaveShortcutLabel: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginBottom: 2,
  },
  leaveShortcutTitle: {
    fontSize: theme.fontSize.lg,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  leaveShortcutAction: {
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.accent,
  },
  personItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  avatar: {
    width: 34,
    height: 34,
    borderRadius: theme.borderRadius.full,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
  },
  avatarText: {
    fontSize: theme.fontSize.base,
    fontWeight: theme.fontWeight.semibold,
  },
  personInfo: {
    flex: 1,
  },
  personName: {
    fontSize: theme.fontSize.lg,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  personMeta: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 1,
  },
  errorWrap: {
    marginTop: 32,
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
    borderRadius: theme.borderRadius.full,
  },
  retryText: {
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.semibold,
  },
  emptyText: {
    marginTop: 32,
    textAlign: 'center',
    color: theme.colors.muted,
    fontSize: theme.fontSize.md,
  },
});
