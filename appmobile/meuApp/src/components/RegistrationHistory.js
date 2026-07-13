import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../theme';

export function RegistrationHistory({ title = 'Histórico de registo', items = [] }) {
  return (
    <View style={styles.wrapper}>
      <Text style={styles.title}>{title}</Text>
      {items.map((item, index) => (
        <View key={`${item.day}-${item.time}-${index}`} style={styles.item}>
          <View style={[styles.iconWrap, item.success ? styles.iconWrapSuccess : styles.iconWrapPending]}>
            <MaterialCommunityIcons
              name={item.success ? 'check-circle-outline' : 'clock-outline'}
              size={16}
              color={item.success ? theme.colors.success : theme.colors.warning}
            />
          </View>
          <View style={styles.info}>
            <Text style={styles.itemTitle}>{item.title}</Text>
            <Text style={styles.itemMeta}>{item.day} · {item.time} · {item.method}</Text>
          </View>
          <Text style={[styles.status, item.success ? styles.statusSuccess : styles.statusPending]}>
            {item.success ? 'Confirmado' : 'Pendente'}
          </Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    width: '100%',
    marginTop: 18,
  },
  title: {
    fontSize: 12,
    color: theme.colors.muted,
    marginBottom: 10,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 12,
    marginBottom: 8,
  },
  iconWrap: {
    width: 36,
    height: 36,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconWrapSuccess: {
    backgroundColor: theme.colors.successDim,
  },
  iconWrapPending: {
    backgroundColor: theme.colors.warningDim,
  },
  info: {
    flex: 1,
  },
  itemTitle: {
    fontSize: 13,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  itemMeta: {
    marginTop: 2,
    fontSize: 11,
    color: theme.colors.muted,
  },
  status: {
    fontSize: 11,
    fontWeight: theme.fontWeight.semibold,
  },
  statusSuccess: {
    color: theme.colors.success,
  },
  statusPending: {
    color: theme.colors.warning,
  },
});

export default RegistrationHistory;
