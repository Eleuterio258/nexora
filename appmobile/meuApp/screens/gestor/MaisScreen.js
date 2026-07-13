import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  StatusBar,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { clearStoredAccess } from '../../src/access';
import { AppHeader, Button, SectionLabel, GestorBottomNav } from '../../src/components';

const devices = [
  { icon: 'camera-outline', name: 'Camera Entrada Principal', meta: 'facial · ultimo ping 09:39', online: true },
  { icon: 'nfc-variant', name: 'Leitor NFC Hall A', meta: 'nfc · ultimo ping 09:40', online: true },
  { icon: 'monitor-dashboard', name: 'Kiosk Piso 2', meta: 'offline · sem resposta 52 min', online: false },
  { icon: 'camera-outline', name: 'Camera Parking', meta: 'facial · ultimo ping 09:38', online: true },
  { icon: 'fingerprint', name: 'Leitor Biometrico RH', meta: 'biometrico · ultimo ping 09:35', online: true },
];

const methods = [
  { name: 'Biometria facial', sub: 'Requer liveness detection', active: true },
  { name: 'NFC / RFID', sub: 'Cartao e telemovel (HCE)', active: true },
  { name: 'QR Code dinamico', sub: 'Requer localizacao GPS', active: true },
  { name: 'Selfie + GPS', sub: 'Validacao manual do gestor', active: false },
  { name: 'PIN / TOTP', sub: 'Codigo temporario', active: false },
];

export default function MaisScreen({ navigation }) {
  const [toggles, setToggles] = useState(methods.map((method) => method.active));

  const handleToggle = (index) => {
    const next = [...toggles];
    next[index] = !next[index];
    setToggles(next);
  };

  const handleLogout = async () => {
    await clearStoredAccess();
    navigation.reset({
      index: 0,
      routes: [{ name: 'Login' }],
    });
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader title="Dispositivos & Config" subtitle="Tenant activo" />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.body}>
          <SectionLabel>Dispositivos</SectionLabel>
          {devices.map((device) => (
            <View key={device.name} style={styles.deviceItem}>
              <View style={styles.deviceIcon}>
                <MaterialCommunityIcons
                  name={device.icon}
                  size={18}
                  color={device.online ? theme.colors.blue : theme.colors.muted}
                />
              </View>
              <View style={styles.deviceInfo}>
                <Text style={styles.deviceName}>{device.name}</Text>
                <Text style={[styles.deviceMeta, !device.online && styles.deviceMetaOffline]}>
                  {device.meta}
                </Text>
              </View>
              <View
                style={[
                  styles.statusDot,
                  { backgroundColor: device.online ? theme.colors.green : theme.colors.red },
                ]}
              />
            </View>
          ))}

          <Button
            label="Forcar sync de configuracao"
            onPress={() => {}}
            variant="outline"
            style={styles.btnOutline}
          />

          <View style={styles.divider} />

          <SectionLabel>Metodos activos - tenant</SectionLabel>
          <View style={styles.configList}>
            {methods.map((method, index) => (
              <View key={method.name} style={styles.configItem}>
                <View style={styles.configInfo}>
                  <Text style={styles.configName}>{method.name}</Text>
                  <Text style={styles.configSub}>{method.sub}</Text>
                </View>
                <TouchableOpacity
                  style={[styles.toggle, toggles[index] && styles.toggleOn]}
                  onPress={() => handleToggle(index)}
                  activeOpacity={0.85}
                >
                  <View style={[styles.toggleKnob, toggles[index] && styles.toggleKnobOn]} />
                </TouchableOpacity>
              </View>
            ))}
          </View>

          <View style={styles.divider} />

          <SectionLabel>Geofencing</SectionLabel>
          <Text style={styles.formLabel}>Raio de validacao (metros)</Text>
          <View style={styles.inputBox}>
            <Text style={styles.inputText}>75</Text>
          </View>

          <Button label="Guardar configuracao" onPress={() => {}} variant="primary" />

          <Button
            label="Sair"
            onPress={handleLogout}
            variant="outline"
            style={styles.logoutButton}
          />
        </View>
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="mais" />
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
  },
  deviceItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  deviceIcon: {
    width: 32,
    height: 32,
    borderRadius: 8,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    justifyContent: 'center',
    alignItems: 'center',
  },
  deviceInfo: {
    flex: 1,
  },
  deviceName: {
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  deviceMeta: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 1,
  },
  deviceMetaOffline: {
    color: theme.colors.red,
  },
  statusDot: {
    width: 7,
    height: 7,
    borderRadius: 3.5,
  },
  btnOutline: {
    marginTop: 12,
  },
  divider: {
    height: 1,
    backgroundColor: theme.colors.border,
    marginVertical: 14,
  },
  configList: {
    gap: 6,
  },
  configItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 12,
    paddingHorizontal: 14,
    backgroundColor: theme.colors.surface2,
    borderRadius: theme.borderRadius.base,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  configInfo: {
    flex: 1,
  },
  configName: {
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  configSub: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 1,
  },
  toggle: {
    width: 38,
    height: 22,
    borderRadius: theme.borderRadius.xl,
    backgroundColor: theme.colors.hint,
    justifyContent: 'center',
    paddingHorizontal: 3,
  },
  toggleOn: {
    backgroundColor: theme.colors.green,
  },
  toggleKnob: {
    width: 16,
    height: 16,
    borderRadius: theme.borderRadius.full,
    backgroundColor: '#fff',
  },
  toggleKnobOn: {
    transform: [{ translateX: 16 }],
  },
  formLabel: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.muted,
    letterSpacing: 0.06,
    textTransform: 'uppercase',
    marginBottom: 5,
  },
  inputBox: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: theme.borderRadius.base,
    paddingHorizontal: 13,
    paddingVertical: 10,
    marginBottom: 12,
  },
  inputText: {
    fontSize: theme.fontSize.lg,
    color: theme.colors.text,
  },
  logoutButton: {
    marginTop: 10,
    borderColor: theme.colors.redBorder,
    backgroundColor: theme.colors.redDim,
  },
});
