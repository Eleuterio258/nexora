import React from 'react';
import { Text, StyleSheet } from 'react-native';
import { theme } from '../theme';

/**
 * Label de seção Premium
 * @param {string} children - Texto da label
 * @param {object} style - Estilos adicionais
 */
export function SectionLabel({ children, style }) {
  return (
    <Text style={[styles.sectionLabel, style]}>{children}</Text>
  );
}

const styles = StyleSheet.create({
  sectionLabel: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.muted,
    letterSpacing: 0.8,
    textTransform: 'uppercase',
    marginBottom: theme.spacing.md,
    marginTop: theme.spacing.lg,
  },
});

export default SectionLabel;
