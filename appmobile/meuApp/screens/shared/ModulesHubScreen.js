import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  StatusBar,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { AppHeader, FuncionarioBottomNav } from '../../src/components';
import { MODULE_CATALOG, MODULE_GROUPS, loadStoredAccess } from '../../src/access';

function getModulesByKeys(keys, enabledKeys) {
  return keys
    .map((k) => MODULE_CATALOG.find((m) => m.key === k))
    .filter((m) => m && enabledKeys.includes(m.key));
}

export default function ModulesHubScreen({ navigation }) {
  const [enabledKeys, setEnabledKeys] = useState([]);

  useEffect(() => {
    let mounted = true;
    loadStoredAccess()
      .then(({ modules }) => {
        if (mounted) setEnabledKeys(Array.isArray(modules) ? modules : []);
      })
      .catch(() => { if (mounted) setEnabledKeys([]); });
    return () => { mounted = false; };
  }, []);

  const visibleGroups = MODULE_GROUPS
    .map((group) => ({
      ...group,
      items: getModulesByKeys(group.modules, enabledKeys),
    }))
    .filter((group) => group.items.length > 0);

  const totalEnabled = enabledKeys.length;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader
        title="Modulos"
        subtitle={`${totalEnabled} modulo${totalEnabled !== 1 ? 's' : ''} disponivel${totalEnabled !== 1 ? 'is' : ''}`}
      />

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.body}
        showsVerticalScrollIndicator={false}
      >
        {visibleGroups.length === 0 ? (
          <View style={styles.emptyState}>
            <MaterialCommunityIcons name="view-grid-outline" size={36} color={theme.colors.muted} />
            <Text style={styles.emptyTitle}>Sem modulos ativos</Text>
            <Text style={styles.emptyText}>
              Este utilizador ainda nao tem modulos atribuidos no backend.
            </Text>
          </View>
        ) : (
          visibleGroups.map((group) => (
            <View key={group.key} style={styles.section}>
              <View style={styles.sectionHeader}>
                <View style={[styles.sectionIconWrap, { backgroundColor: group.dimColor }]}>
                  <MaterialCommunityIcons name={group.icon} size={14} color={group.color} />
                </View>
                <Text style={styles.sectionLabel}>{group.label}</Text>
                <Text style={styles.sectionCount}>{group.items.length}</Text>
              </View>

              <View style={styles.grid}>
                {group.items.map((item) => (
                  <TouchableOpacity
                    key={item.key}
                    style={styles.card}
                    activeOpacity={0.88}
                    onPress={() => navigation.navigate(item.route)}
                  >
                    <View style={[styles.cardIcon, { backgroundColor: group.dimColor }]}>
                      <MaterialCommunityIcons name={item.icon} size={20} color={group.color} />
                    </View>
                    <Text style={styles.cardTitle} numberOfLines={1}>{item.title}</Text>
                    <Text style={styles.cardDesc} numberOfLines={2}>{item.description}</Text>
                    <View style={styles.cardFooter}>
                      <MaterialCommunityIcons name="arrow-right" size={14} color={group.color} />
                    </View>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          ))
        )}
      </ScrollView>

      <FuncionarioBottomNav navigation={navigation} activeKey="modules" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg,
  },
  scroll: {
    flex: 1,
  },
  body: {
    padding: 16,
    paddingBottom: 96,
    gap: 24,
  },

  emptyState: {
    alignItems: 'center',
    paddingTop: 48,
    gap: 10,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  emptyText: {
    fontSize: 13,
    color: theme.colors.muted,
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 24,
  },

  section: {
    gap: 10,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  sectionIconWrap: {
    width: 24,
    height: 24,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sectionLabel: {
    flex: 1,
    fontSize: 13,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    letterSpacing: 0.1,
  },
  sectionCount: {
    fontSize: 11,
    color: theme.colors.muted,
    fontWeight: theme.fontWeight.medium,
  },

  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  card: {
    width: '48%',
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 14,
  },
  cardIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 10,
  },
  cardTitle: {
    fontSize: 13,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  cardDesc: {
    marginTop: 3,
    fontSize: 11,
    lineHeight: 16,
    color: theme.colors.muted,
  },
  cardFooter: {
    marginTop: 10,
    alignItems: 'flex-end',
  },
});
