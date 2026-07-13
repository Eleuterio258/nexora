import React, { useCallback, useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Switch,
  SafeAreaView,
  StatusBar,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { theme } from '../../src/theme';
import { AppHeader, GestorBottomNav } from '../../src/components';
import { MODULE_CATALOG, MODULE_GROUPS } from '../../src/access';

const ALL_KEYS = MODULE_CATALOG.map((m) => m.key);

export default function ModulosGestaoScreen({ navigation }) {
  const [enabled, setEnabled] = useState(new Set(ALL_KEYS));
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem('auth.modules').then((raw) => {
      if (raw) {
        try {
          const arr = JSON.parse(raw);
          if (Array.isArray(arr) && arr.length > 0) setEnabled(new Set(arr));
        } catch (_) {}
      }
    });
  }, []);

  const toggle = useCallback((key) => {
    setEnabled((prev) => {
      const next = new Set(prev);
      next.has(key) ? next.delete(key) : next.add(key);
      return next;
    });
    setSaved(false);
  }, []);

  const toggleGroup = useCallback((groupModules) => {
    setEnabled((prev) => {
      const next = new Set(prev);
      const allOn = groupModules.every((k) => next.has(k));
      groupModules.forEach((k) => (allOn ? next.delete(k) : next.add(k)));
      return next;
    });
    setSaved(false);
  }, []);

  const save = useCallback(async () => {
    setSaving(true);
    await AsyncStorage.setItem('auth.modules', JSON.stringify([...enabled]));
    setSaving(false);
    setSaved(true);
  }, [enabled]);

  const enabledCount = enabled.size;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader
        title="Gestao de Modulos"
        subtitle={`${enabledCount} de ${ALL_KEYS.length} modulos activos`}
        rightContent={
          <TouchableOpacity
            style={[styles.saveBtn, saved && styles.saveBtnDone]}
            onPress={save}
            disabled={saving || saved}
            activeOpacity={0.85}
          >
            <MaterialCommunityIcons
              name={saved ? 'check' : 'content-save-outline'}
              size={15}
              color={saved ? theme.colors.green : '#fff'}
            />
            <Text style={[styles.saveBtnText, saved && styles.saveBtnTextDone]}>
              {saving ? 'A guardar...' : saved ? 'Guardado' : 'Guardar'}
            </Text>
          </TouchableOpacity>
        }
      />

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.body}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.infoCard}>
          <MaterialCommunityIcons name="information-outline" size={16} color={theme.colors.accent} />
          <Text style={styles.infoText}>
            Estes modulos sao atribuidos localmente. Quando o backend enviar a lista de modulos no login, essa configuracao e substituida automaticamente.
          </Text>
        </View>

        {MODULE_GROUPS.map((group) => {
          const groupKeys = group.modules.filter((k) => ALL_KEYS.includes(k));
          const activeInGroup = groupKeys.filter((k) => enabled.has(k)).length;
          const allOn = activeInGroup === groupKeys.length;

          return (
            <View key={group.key} style={styles.section}>
              <TouchableOpacity
                style={styles.sectionHeader}
                onPress={() => toggleGroup(groupKeys)}
                activeOpacity={0.85}
              >
                <View style={[styles.sectionIcon, { backgroundColor: group.dimColor }]}>
                  <MaterialCommunityIcons name={group.icon} size={14} color={group.color} />
                </View>
                <Text style={styles.sectionLabel}>{group.label}</Text>
                <Text style={[styles.sectionCount, { color: group.color }]}>
                  {activeInGroup}/{groupKeys.length}
                </Text>
                <MaterialCommunityIcons
                  name={allOn ? 'toggle-switch' : 'toggle-switch-off-outline'}
                  size={22}
                  color={allOn ? group.color : theme.colors.muted}
                />
              </TouchableOpacity>

              <View style={styles.moduleList}>
                {groupKeys.map((key) => {
                  const mod = MODULE_CATALOG.find((m) => m.key === key);
                  if (!mod) return null;
                  const isOn = enabled.has(key);
                  return (
                    <View key={key} style={styles.moduleRow}>
                      <View style={[styles.moduleIcon, { backgroundColor: group.dimColor }]}>
                        <MaterialCommunityIcons name={mod.icon} size={16} color={group.color} />
                      </View>
                      <View style={styles.moduleInfo}>
                        <Text style={styles.moduleTitle}>{mod.title}</Text>
                        <Text style={styles.moduleDesc}>{mod.description}</Text>
                      </View>
                      <Switch
                        value={isOn}
                        onValueChange={() => toggle(key)}
                        trackColor={{ false: theme.colors.border2, true: group.dimColor }}
                        thumbColor={isOn ? group.color : theme.colors.muted}
                      />
                    </View>
                  );
                })}
              </View>
            </View>
          );
        })}
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="modulos" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.bg },
  scroll: { flex: 1 },
  body: { padding: 16, paddingBottom: 96, gap: 20 },

  saveBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.sidebarAccent,
  },
  saveBtnDone: {
    backgroundColor: theme.colors.greenDim,
    borderWidth: 1,
    borderColor: theme.colors.greenBorder,
  },
  saveBtnText: { fontSize: 12, fontWeight: theme.fontWeight.semibold, color: '#fff' },
  saveBtnTextDone: { color: theme.colors.green },

  infoCard: {
    flexDirection: 'row',
    gap: 10,
    alignItems: 'flex-start',
    backgroundColor: theme.colors.infoDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
    borderRadius: 14,
    padding: 14,
  },
  infoText: {
    flex: 1,
    fontSize: 12,
    lineHeight: 18,
    color: theme.colors.text,
  },

  section: { gap: 8 },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 4,
  },
  sectionIcon: {
    width: 26,
    height: 26,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sectionLabel: {
    flex: 1,
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  sectionCount: {
    fontSize: 12,
    fontWeight: theme.fontWeight.medium,
  },

  moduleList: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    overflow: 'hidden',
  },
  moduleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  moduleIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  moduleInfo: { flex: 1 },
  moduleTitle: {
    fontSize: 13,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  moduleDesc: {
    fontSize: 11,
    color: theme.colors.muted,
    marginTop: 2,
  },
});
