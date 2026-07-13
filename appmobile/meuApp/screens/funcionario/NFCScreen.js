import React from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  StatusBar,
} from 'react-native';
import { theme } from '../../src/theme';

export default function NFCScreen({ navigation }) {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <Text style={styles.headerTitle}>NFC / Cartao</Text>
        <Text style={styles.headerSub}>Aproxime o telemovel ou cartao do leitor</Text>
      </View>

      <View style={styles.body}>
        <View style={styles.heroCard}>
          <Text style={styles.heroEyebrow}>Leitura por proximidade</Text>
          <Text style={styles.heroTitle}>Aguardando aproximacao</Text>
          <Text style={styles.heroText}>
            Encoste o dispositivo ao leitor NFC para validar a entrada ou saida sem usar a camera.
          </Text>

          <View style={styles.nfcContainer}>
            <View style={[styles.wave, styles.wave1]} />
            <View style={[styles.wave, styles.wave2]} />
            <View style={[styles.wave, styles.wave3]} />
            <View style={[styles.wave, styles.wave4]} />
            <View style={styles.centerIcon}>
              <MaterialCommunityIcons name="nfc-variant" size={36} color={theme.colors.blue} />
            </View>
          </View>

          <View style={styles.statusPill}>
            <View style={styles.statusDot} />
            <Text style={styles.statusPillText}>NFC activo · aguarda leitura</Text>
          </View>
        </View>

        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>Como usar</Text>
          <Text style={styles.infoText}>1. Desbloqueie o telemovel ou aproxime o cartao.</Text>
          <Text style={styles.infoText}>2. Encoste ao leitor por 1 a 2 segundos.</Text>
          <Text style={styles.infoText}>3. Aguarde a confirmacao do registo.</Text>
        </View>

        <TouchableOpacity style={styles.buttonPrimary} onPress={() => navigation.navigate('Success', { method: 'nfc' })} activeOpacity={0.9}>
          <Text style={styles.buttonPrimaryText}>Simular leitura</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.buttonOutline} onPress={() => navigation.goBack()} activeOpacity={0.9}>
          <Text style={styles.buttonOutlineText}>Cancelar</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.surface,
  },
  header: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  headerSub: {
    fontSize: 12,
    color: theme.colors.muted,
    marginTop: 2,
  },
  body: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
  },
  heroCard: {
    backgroundColor: theme.colors.surface2,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 20,
    alignItems: 'center',
    marginBottom: 16,
  },
  heroEyebrow: {
    fontSize: 11,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  heroTitle: {
    fontSize: 20,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginTop: 6,
  },
  heroText: {
    marginTop: 8,
    fontSize: 12,
    color: theme.colors.muted,
    textAlign: 'center',
    lineHeight: 18,
  },
  nfcContainer: {
    width: 150,
    height: 150,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 18,
    marginBottom: 18,
  },
  wave: {
    position: 'absolute',
    borderWidth: 1.5,
    borderColor: theme.colors.blueBorder,
    borderRadius: 999,
  },
  wave1: {
    width: 40,
    height: 40,
    opacity: 0.25,
  },
  wave2: {
    width: 72,
    height: 72,
    opacity: 0.4,
  },
  wave3: {
    width: 108,
    height: 108,
    opacity: 0.6,
  },
  wave4: {
    width: 144,
    height: 144,
    opacity: 0.8,
  },
  centerIcon: {
    width: 58,
    height: 58,
    borderRadius: 18,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
    alignItems: 'center',
    justifyContent: 'center',
  },
  statusPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.infoDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: theme.colors.blue,
  },
  statusPillText: {
    fontSize: 12,
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.medium,
  },
  infoCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 16,
    marginBottom: 16,
  },
  infoTitle: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginBottom: 8,
  },
  infoText: {
    fontSize: 12,
    color: theme.colors.muted,
    lineHeight: 18,
    marginBottom: 4,
  },
  buttonPrimary: {
    backgroundColor: theme.colors.accent,
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
    marginBottom: 10,
  },
  buttonPrimaryText: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: '#FFFFFF',
  },
  buttonOutline: {
    paddingVertical: 14,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    alignItems: 'center',
  },
  buttonOutlineText: {
    fontSize: 14,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
});
