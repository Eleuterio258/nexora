import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';

const NAV_ITEMS = [
  { key: 'dashboard', label: 'Inicio',   icon: 'view-dashboard-outline', route: 'SuperAdminDashboard' },
  { key: 'tenants',   label: 'Tenants',  icon: 'office-building-outline', route: 'SuperAdminTenants' },
  { key: 'planos',    label: 'Planos',   icon: 'layers-outline',          route: 'SuperAdminPlanos' },
];

export function SuperAdminNav({ navigation, activeKey }) {
  return (
    <View style={styles.wrapper}>
      <View style={styles.container}>
        {NAV_ITEMS.map((item) => {
          const isActive = item.key === activeKey;
          return (
            <TouchableOpacity
              key={item.key}
              style={styles.item}
              onPress={() => navigation.navigate(item.route)}
              activeOpacity={0.85}
            >
              <View style={[styles.iconShell, isActive && styles.iconShellActive]}>
                <MaterialCommunityIcons
                  name={item.icon}
                  size={20}
                  color={isActive ? '#fff' : theme.colors.muted}
                />
              </View>
              <Text style={[styles.label, isActive && styles.labelActive]}>{item.label}</Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    paddingHorizontal: 12,
    paddingBottom: 10,
    paddingTop: 8,
    backgroundColor: theme.colors.bg,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
  },
  container: {
    flexDirection: 'row',
    backgroundColor: theme.colors.sidebarStart,
    borderRadius: 20,
    paddingHorizontal: 8,
    paddingVertical: 8,
  },
  item: { flex: 1, alignItems: 'center', gap: 4 },
  iconShell: {
    width: 36, height: 36, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
  },
  iconShellActive: { backgroundColor: theme.colors.sidebarAccent },
  label: { fontSize: theme.fontSize.xs, color: 'rgba(255,255,255,0.45)', fontWeight: theme.fontWeight.medium },
  labelActive: { color: '#fff' },
});
