import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../theme';
import { GESTOR_NAV_ITEMS, filterNavItems, loadStoredAccess } from '../access';

export function GestorBottomNav({ navigation, activeKey }) {
  const [items, setItems] = useState(GESTOR_NAV_ITEMS);

  useEffect(() => {
    let mounted = true;

    loadStoredAccess()
      .then(({ modules }) => {
        if (mounted) {
          setItems(filterNavItems(GESTOR_NAV_ITEMS, modules));
        }
      })
      .catch(() => {
        if (mounted) {
          setItems(GESTOR_NAV_ITEMS);
        }
      });

    return () => {
      mounted = false;
    };
  }, []);

  return (
    <View style={styles.wrapper}>
      <View style={styles.container}>
        {items.map((item) => {
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
                  color={isActive ? theme.colors.blue : theme.colors.muted}
                />
              </View>
              <Text style={[styles.label, isActive && styles.labelActive]}>
                {item.label}
              </Text>
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
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 20,
    paddingHorizontal: 8,
    paddingVertical: 8,
  },
  item: {
    flex: 1,
    alignItems: 'center',
    gap: 4,
  },
  iconShell: {
    width: 36,
    height: 36,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'transparent',
  },
  iconShellActive: {
    backgroundColor: theme.colors.blueDim,
  },
  label: {
    fontSize: theme.fontSize.xs,
    color: theme.colors.muted,
    fontWeight: theme.fontWeight.medium,
  },
  labelActive: {
    color: theme.colors.blue,
  },
});

export default GestorBottomNav;
