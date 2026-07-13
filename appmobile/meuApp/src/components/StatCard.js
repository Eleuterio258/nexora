import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { theme } from '../theme';

/**
 * Card de estatística Premium
 * @param {string|number} value - Valor principal
 * @param {string} label - Rótulo abaixo do valor
 * @param {string} color - Cor do valor (success, error, warning, info, text)
 * @param {function} onPress - Função ao clicar (opcional)
 * @param {object} style - Estilos adicionais
 */
export function StatCard({ value, label, color = 'text', onPress, style }) {
  const variants = {
    green: {
      valueColor: theme.colors.green,
      labelColor: theme.colors.green,
      backgroundColor: theme.colors.surface,
      borderColor: theme.colors.border,
    },
    red: {
      valueColor: theme.colors.red,
      labelColor: theme.colors.red,
      backgroundColor: theme.colors.surface,
      borderColor: theme.colors.border,
    },
    amber: {
      valueColor: theme.colors.amber,
      labelColor: theme.colors.amber,
      backgroundColor: theme.colors.surface,
      borderColor: theme.colors.border,
    },
    blue: {
      valueColor: theme.colors.blue,
      labelColor: theme.colors.blue,
      backgroundColor: theme.colors.surface,
      borderColor: theme.colors.border,
    },
    text: {
      valueColor: theme.colors.text,
      labelColor: theme.colors.muted,
      backgroundColor: theme.colors.surface,
      borderColor: theme.colors.border,
    },
  };

  const variant = variants[color] || variants.text;

  const cardStyles = [
    styles.statCard,
    {
      backgroundColor: variant.backgroundColor,
      borderColor: variant.borderColor,
    },
    style,
  ];

  return (
    <TouchableOpacity
      style={cardStyles}
      onPress={onPress}
      activeOpacity={onPress ? 0.7 : 1}
      disabled={!onPress}
    >
      <Text style={[styles.statValue, { color: variant.valueColor }]}>{value}</Text>
      <Text style={[styles.statLabel, { color: variant.labelColor }]}>{label}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  statCard: {
    flex: 1,
    minWidth: '45%',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    paddingVertical: theme.spacing.lg,
    paddingHorizontal: theme.spacing.xl,
    borderWidth: 0.5,
    borderColor: theme.colors.border,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  statValue: {
    fontSize: theme.fontSize['3xl'],
    fontWeight: theme.fontWeight.bold,
    letterSpacing: -1,
  },
  statLabel: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 4,
    fontWeight: theme.fontWeight.medium,
  },
});

export default StatCard;
