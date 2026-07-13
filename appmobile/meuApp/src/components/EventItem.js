import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { theme } from '../theme';
import { Badge } from './Badge';

/**
 * Item de evento Premium para listas
 * @param {string} name - Nome da pessoa
 * @param {string} meta - Metadados (hora, método, etc)
 * @param {string} status - Status: ok, late, absent, exit
 * @param {function} onPress - Função ao clicar (opcional)
 * @param {object} style - Estilos adicionais
 */
export function EventItem({ name, meta, status, onPress, style }) {
  const statusConfig = {
    ok: { dotColor: theme.colors.success, badgeVariant: 'success', label: 'OK' },
    late: { dotColor: theme.colors.warning, badgeVariant: 'warning', label: 'Tarde' },
    absent: { dotColor: theme.colors.error, badgeVariant: 'error', label: 'Ausente' },
    exit: { dotColor: theme.colors.info, badgeVariant: 'info', label: 'Saída' },
  };
  
  const config = statusConfig[status] || statusConfig.ok;
  
  const content = (
    <View style={[styles.eventItem, style]}>
      <View style={[styles.eventDot, { backgroundColor: config.dotColor }]} />
      <View style={styles.eventInfo}>
        <Text style={styles.eventName}>{name}</Text>
        <Text style={styles.eventMeta}>{meta}</Text>
      </View>
      <Badge label={config.label} variant={config.badgeVariant} />
    </View>
  );
  
  if (onPress) {
    return (
      <TouchableOpacity style={styles.touchable} onPress={onPress} activeOpacity={0.7}>
        {content}
      </TouchableOpacity>
    );
  }
  
  return content;
}

const styles = StyleSheet.create({
  touchable: {
  },
  eventItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
    paddingVertical: theme.spacing.base,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  eventDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  eventInfo: {
    flex: 1,
  },
  eventName: {
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  eventMeta: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 2,
  },
});

export default EventItem;
