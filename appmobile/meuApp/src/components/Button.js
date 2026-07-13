import React from 'react';
import { TouchableOpacity, Text, StyleSheet } from 'react-native';
import { theme } from '../theme';

/**
 * Botão Premium Reutilizável
 * @param {string} label - Texto do botão
 * @param {function} onPress - Função ao clicar
 * @param {string} variant - Variação: primary, outline, destructive
 * @param {object} style - Estilos adicionais
 */
export function Button({ label, onPress, variant = 'primary', style, textStyle }) {
  const variantStyle = 
    variant === 'primary' ? styles.buttonPrimary :
    variant === 'destructive' ? styles.buttonDestructive :
    styles.buttonOutline;
  
  const textStyleVariant =
    variant === 'primary' ? styles.buttonTextPrimary :
    variant === 'destructive' ? styles.buttonTextDestructive :
    styles.buttonTextOutline;

  return (
    <TouchableOpacity
      style={[styles.button, variantStyle, style]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      <Text style={[styles.buttonText, textStyleVariant, textStyle]}>
        {label}
      </Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    borderRadius: theme.borderRadius.base,
    paddingVertical: theme.spacing.lg,
    paddingHorizontal: theme.spacing.xl,
    alignItems: 'center',
    width: '100%',
  },
  buttonPrimary: {
    backgroundColor: theme.colors.accent,
    shadowColor: theme.colors.accent,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 3,
  },
  buttonOutline: {
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    borderColor: theme.colors.border2,
  },
  buttonDestructive: {
    backgroundColor: theme.colors.destructive,
    shadowColor: theme.colors.destructive,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 3,
  },
  buttonText: {
    fontSize: theme.fontSize.lg,
    fontWeight: theme.fontWeight.semibold,
  },
  buttonTextPrimary: {
    color: '#FFFFFF',
  },
  buttonTextOutline: {
    color: theme.colors.text,
  },
  buttonTextDestructive: {
    color: '#FFFFFF',
  },
});

export default Button;
