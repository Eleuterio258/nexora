import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { theme } from '../theme';

/**
 * Badge Premium Reutilizável
 * @param {string} label - Texto do badge
 * @param {string} variant - Variação: success, error, warning, info, default
 * @param {object} style - Estilos adicionais
 */
export function Badge({ label, variant = 'default', style }) {
  const variants = {
    success: {
      backgroundColor: theme.colors.successDim,
      color: '#065F46',
      borderColor: theme.colors.successBorder,
    },
    error: {
      backgroundColor: theme.colors.errorDim,
      color: '#991B1B',
      borderColor: theme.colors.errorBorder,
    },
    warning: {
      backgroundColor: theme.colors.warningDim,
      color: '#92400E',
      borderColor: theme.colors.warningBorder,
    },
    info: {
      backgroundColor: theme.colors.infoDim,
      color: '#1E40AF',
      borderColor: theme.colors.infoBorder,
    },
    default: {
      backgroundColor: theme.colors.surface2,
      color: theme.colors.muted,
      borderColor: theme.colors.border,
    },
  };
  
  const variantStyle = variants[variant] || variants.default;
  
  return (
    <View style={[styles.badge, { backgroundColor: variantStyle.backgroundColor, borderColor: variantStyle.borderColor }, style]}>
      <Text style={[styles.badgeText, { color: variantStyle.color }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
  },
  badgeText: {
    fontSize: theme.fontSize.xs,
    fontWeight: theme.fontWeight.semibold,
  },
});

export default Badge;
