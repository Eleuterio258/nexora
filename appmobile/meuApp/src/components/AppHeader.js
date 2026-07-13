import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { theme } from '../theme';

/**
 * Header Premium do aplicativo Omnisys ERP
 * Design moderno com gradiente Azul/Roxo
 * @param {string} title - Título principal
 * @param {string} subtitle - Subtítulo (opcional)
 * @param {React.ReactNode} rightContent - Conteúdo do lado direito (opcional)
 * @param {object} style - Estilos adicionais
 */
export function AppHeader({ title, subtitle, rightContent, style }) {
  return (
    <View style={[styles.header, style]}>
      <View style={styles.headerLeft}>
        <Text style={styles.headerTitle}>{title}</Text>
        {subtitle && <Text style={styles.headerSub}>{subtitle}</Text>}
      </View>
      {rightContent && <View>{rightContent}</View>}
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    padding: theme.spacing['3xl'],
    paddingBottom: theme.spacing.xl,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    minHeight: 56,
  },
  headerLeft: {
    flex: 1,
  },
  headerTitle: {
    fontSize: theme.fontSize.xl,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
    letterSpacing: -0.5,
  },
  headerSub: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 2,
  },
});

export default AppHeader;
