import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  TouchableOpacity,
  StatusBar,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { AppHeader, SectionLabel, GestorBottomNav } from '../../src/components';

const alerts = [
  {
    title: 'Rosto nao identificado',
    status: 'Alerta',
    statusColor: theme.colors.red,
    statusBg: theme.colors.redDim,
    borderColor: theme.colors.redBorder,
    sub: 'Camera entrada principal · 08:54',
    icon: 'face-recognition',
  },
  {
    title: 'QR invalido',
    status: 'Aviso',
    statusColor: theme.colors.amber,
    statusBg: theme.colors.amberDim,
    borderColor: theme.colors.amberBorder,
    sub: 'Joao Tembe · 08:42',
    icon: 'qrcode-scan',
  },
  {
    title: 'Fora do perimetro GPS',
    status: 'Aviso',
    statusColor: theme.colors.amber,
    statusBg: theme.colors.amberDim,
    borderColor: theme.colors.amberBorder,
    sub: 'Selfie rejeitada · Fatima Bila',
    icon: 'map-marker-alert-outline',
  },
  {
    title: 'Sync pendente ERP',
    status: 'Info',
    statusColor: theme.colors.blue,
    statusBg: theme.colors.blueDim,
    borderColor: theme.colors.blueBorder,
    sub: '2 eventos · tentativa 3/5',
    icon: 'sync-alert',
  },
];

export default function AlertasScreen({ navigation }) {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader title="Ocorrencias" subtitle="3 pendentes" />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.body}>
          <SectionLabel>Fila de alertas</SectionLabel>

          {alerts.map((alert) => (
            <TouchableOpacity
              key={alert.title}
              style={[styles.alertCard, { borderColor: alert.borderColor }]}
              activeOpacity={0.85}
              onPress={() => navigation.navigate('Ocorrencias')}
            >
              <View style={[styles.alertIconShell, { backgroundColor: alert.statusBg }]}>
                <MaterialCommunityIcons
                  name={alert.icon}
                  size={20}
                  color={alert.statusColor}
                />
              </View>
              <View style={styles.alertInfo}>
                <View style={styles.alertHeader}>
                  <Text style={styles.alertTitle}>{alert.title}</Text>
                  <View style={[styles.badge, { backgroundColor: alert.statusBg }]}>
                    <Text style={[styles.badgeText, { color: alert.statusColor }]}>
                      {alert.status}
                    </Text>
                  </View>
                </View>
                <Text style={styles.alertSub}>{alert.sub}</Text>
              </View>
            </TouchableOpacity>
          ))}
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
  },
  alertCard: {
    flexDirection: 'row',
    gap: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderRadius: theme.borderRadius.lg,
    padding: 12,
    marginBottom: 10,
  },
  alertIconShell: {
    width: 42,
    height: 42,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  alertInfo: {
    flex: 1,
  },
  alertHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 8,
    alignItems: 'flex-start',
  },
  alertTitle: {
    flex: 1,
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
  },
  badgeText: {
    fontSize: theme.fontSize.xs,
    fontWeight: theme.fontWeight.semibold,
    textTransform: 'uppercase',
  },
  alertSub: {
    marginTop: 4,
    fontSize: theme.fontSize.base,
    color: theme.colors.muted,
  },
});
