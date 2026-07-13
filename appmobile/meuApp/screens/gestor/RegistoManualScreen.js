import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  StatusBar,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { AppHeader, Button, SectionLabel, GestorBottomNav } from '../../src/components';

export default function RegistoManualScreen({ navigation }) {
  const [tipo, setTipo] = useState('entrada');
  const [dataHora] = useState('04/04/2026 · 08:00');
  const [motivo, setMotivo] = useState('Falha no leitor NFC.');

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader title="Registo Manual" subtitle="Lancamento de presenca por excecao" />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.body}>
          <SectionLabel>Funcionario</SectionLabel>
          <TouchableOpacity style={styles.selectBox} activeOpacity={0.85}>
            <View style={styles.selectLeft}>
              <MaterialCommunityIcons
                name="account-outline"
                size={20}
                color={theme.colors.blue}
              />
              <Text style={styles.selectText}>Joao Tembe</Text>
            </View>
            <MaterialCommunityIcons
              name="chevron-down"
              size={20}
              color={theme.colors.muted}
            />
          </TouchableOpacity>

          <SectionLabel>Tipo</SectionLabel>
          <View style={styles.tipoRow}>
            {['entrada', 'saida'].map((item) => {
              const active = tipo === item;
              return (
                <TouchableOpacity
                  key={item}
                  style={[styles.tipoButton, active && styles.tipoButtonActive]}
                  onPress={() => setTipo(item)}
                  activeOpacity={0.85}
                >
                  <Text style={[styles.tipoButtonText, active && styles.tipoButtonTextActive]}>
                    {item === 'entrada' ? 'Entrada' : 'Saida'}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>

          <SectionLabel>Data e hora</SectionLabel>
          <TouchableOpacity style={styles.selectBox} activeOpacity={0.85}>
            <View style={styles.selectLeft}>
              <MaterialCommunityIcons
                name="calendar-clock-outline"
                size={20}
                color={theme.colors.amber}
              />
              <Text style={styles.selectText}>{dataHora}</Text>
            </View>
          </TouchableOpacity>

          <SectionLabel>Motivo</SectionLabel>
          <TextInput
            style={styles.textArea}
            value={motivo}
            onChangeText={setMotivo}
            multiline
            numberOfLines={4}
            placeholder="Descreva o motivo do registo manual"
            placeholderTextColor={theme.colors.muted}
          />

          <Button label="Confirmar registo" onPress={() => {}} />
        </View>
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="ocorrencias" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg,
  },
  content: {
    flex: 1,
  },
  body: {
    padding: 16,
    gap: 2,
  },
  selectBox: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    paddingHorizontal: 14,
    paddingVertical: 13,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  selectLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  selectText: {
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  tipoRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 4,
  },
  tipoButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  tipoButtonActive: {
    backgroundColor: theme.colors.blueDim,
    borderColor: theme.colors.blueBorder,
  },
  tipoButtonText: {
    fontSize: theme.fontSize.md,
    color: theme.colors.muted,
    fontWeight: theme.fontWeight.medium,
  },
  tipoButtonTextActive: {
    color: theme.colors.blue,
  },
  textArea: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: theme.colors.border,
    minHeight: 96,
    textAlignVertical: 'top',
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
    marginBottom: 16,
  },
});
