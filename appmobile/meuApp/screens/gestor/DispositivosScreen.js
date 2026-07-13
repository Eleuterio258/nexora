import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  StatusBar,
  TouchableOpacity,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { AppHeader, Button, SectionLabel, GestorBottomNav } from '../../src/components';

const devices = [
  {
    id: 'cam-entrada',
    icon: 'camera-outline',
    name: 'Camera Entrada Principal',
    zone: 'Recepcao',
    type: 'Facial',
    lastPing: '09:39',
    health: '98%',
    status: 'online',
  },
  {
    id: 'nfc-hall-a',
    icon: 'nfc-variant',
    name: 'Leitor NFC Hall A',
    zone: 'Piso 1',
    type: 'NFC',
    lastPing: '09:40',
    health: '96%',
    status: 'online',
  },
  {
    id: 'kiosk-p2',
    icon: 'monitor-dashboard',
    name: 'Kiosk Piso 2',
    zone: 'Operacoes',
    type: 'Kiosk',
    lastPing: '08:53',
    health: 'Sem resposta',
    status: 'offline',
  },
  {
    id: 'cam-park',
    icon: 'camera-wireless-outline',
    name: 'Camera Parking',
    zone: 'Parque',
    type: 'Facial',
    lastPing: '09:38',
    health: '94%',
    status: 'online',
  },
  {
    id: 'bio-rh',
    icon: 'fingerprint',
    name: 'Leitor Biometrico RH',
    zone: 'RH',
    type: 'Biometrico',
    lastPing: '09:35',
    health: '91%',
    status: 'warning',
  },
];

const incidents = [
  { title: 'Kiosk Piso 2 sem sync', meta: '47 min sem resposta · ultima acao pendente', tone: 'danger' },
  { title: 'Biometrico RH com latencia', meta: '7 validacoes acima de 2s nas ultimas 2h', tone: 'warning' },
];

export default function DispositivosScreen({ navigation }) {
  const total = devices.length;
  const online = devices.filter((device) => device.status === 'online').length;
  const offline = devices.filter((device) => device.status === 'offline').length;
  const warning = devices.filter((device) => device.status === 'warning').length;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader
        title="Dispositivos"
        subtitle={`${total} registados · monitorizacao activa`}
        rightContent={
          <TouchableOpacity
            style={styles.headerAction}
            activeOpacity={0.9}
            onPress={() => navigation.navigate('Mais')}
          >
            <MaterialCommunityIcons name="cog-outline" size={16} color={theme.colors.accent} />
            <Text style={styles.headerActionText}>Config</Text>
          </TouchableOpacity>
        }
      />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.body}>
          <View style={styles.highlightCard}>
            <View style={styles.highlightRow}>
              <View>
                <Text style={styles.highlightEyebrow}>Estado da infraestrutura</Text>
                <Text style={styles.highlightTitle}>Sincronizacao dos leitores</Text>
              </View>
              <View style={styles.liveBadge}>
                <View style={styles.liveDot} />
                <Text style={styles.liveText}>live</Text>
              </View>
            </View>
            <Text style={styles.highlightText}>
              1 dispositivo precisa intervencao imediata e 1 esta com degradacao de resposta.
            </Text>
            <View style={styles.metricRow}>
              <View style={styles.metricCard}>
                <Text style={[styles.metricValue, { color: theme.colors.green }]}>{online}</Text>
                <Text style={styles.metricLabel}>Online</Text>
              </View>
              <View style={styles.metricCard}>
                <Text style={[styles.metricValue, { color: theme.colors.red }]}>{offline}</Text>
                <Text style={styles.metricLabel}>Offline</Text>
              </View>
              <View style={styles.metricCard}>
                <Text style={[styles.metricValue, { color: theme.colors.amber }]}>{warning}</Text>
                <Text style={styles.metricLabel}>Atencao</Text>
              </View>
            </View>
          </View>

          <SectionLabel>Incidentes</SectionLabel>
          {incidents.map((incident) => {
            const toneStyles = getIncidentToneStyles(incident.tone);
            return (
              <View key={incident.title} style={[styles.incidentCard, toneStyles.card]}>
                <View style={styles.incidentHead}>
                  <Text style={[styles.incidentTitle, toneStyles.title]}>{incident.title}</Text>
                  <Text style={[styles.incidentBadge, toneStyles.badge]}>{incident.tone === 'danger' ? 'Critico' : 'Monitorar'}</Text>
                </View>
                <Text style={styles.incidentMeta}>{incident.meta}</Text>
              </View>
            );
          })}

          <View style={styles.actionRow}>
            <Button label="Forcar sync" onPress={() => {}} variant="outline" style={styles.flexBtn} />
            <Button label="Registo manual" onPress={() => navigation.navigate('RegistoManual')} variant="primary" style={styles.flexBtn} />
          </View>

          <View style={styles.divider} />

          <SectionLabel>Lista de dispositivos</SectionLabel>
          {devices.map((device) => {
            const statusStyles = getStatusStyles(device.status);
            return (
              <TouchableOpacity key={device.id} style={styles.deviceCard} activeOpacity={0.92}>
                <View style={[styles.deviceIcon, statusStyles.iconWrap]}>
                  <MaterialCommunityIcons name={device.icon} size={20} color={statusStyles.iconColor} />
                </View>
                <View style={styles.deviceMain}>
                  <View style={styles.deviceHead}>
                    <Text style={styles.deviceName}>{device.name}</Text>
                    <View style={[styles.statusPill, statusStyles.pill]}>
                      <View style={[styles.statusDot, { backgroundColor: statusStyles.iconColor }]} />
                      <Text style={[styles.statusText, { color: statusStyles.iconColor }]}>
                        {device.status === 'online' ? 'Online' : device.status === 'offline' ? 'Offline' : 'Atencao'}
                      </Text>
                    </View>
                  </View>
                  <Text style={styles.deviceMeta}>
                    {device.type} · {device.zone}
                  </Text>
                  <View style={styles.deviceFoot}>
                    <Text style={styles.deviceSub}>Ultimo ping {device.lastPing}</Text>
                    <Text style={[styles.deviceSub, statusStyles.healthText]}>Saude {device.health}</Text>
                  </View>
                </View>
              </TouchableOpacity>
            );
          })}
        </View>
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="mais" />
    </SafeAreaView>
  );
}

function getStatusStyles(status) {
  if (status === 'offline') {
    return {
      iconWrap: { backgroundColor: theme.colors.redDim, borderColor: theme.colors.redBorder },
      iconColor: theme.colors.red,
      pill: { backgroundColor: theme.colors.redDim, borderColor: theme.colors.redBorder },
      healthText: { color: theme.colors.red },
    };
  }

  if (status === 'warning') {
    return {
      iconWrap: { backgroundColor: theme.colors.amberDim, borderColor: theme.colors.amberBorder },
      iconColor: theme.colors.amber,
      pill: { backgroundColor: theme.colors.amberDim, borderColor: theme.colors.amberBorder },
      healthText: { color: theme.colors.amber },
    };
  }

  return {
    iconWrap: { backgroundColor: theme.colors.blueDim, borderColor: theme.colors.blueBorder },
    iconColor: theme.colors.blue,
    pill: { backgroundColor: theme.colors.greenDim, borderColor: theme.colors.greenBorder },
    healthText: { color: theme.colors.green },
  };
}

function getIncidentToneStyles(tone) {
  if (tone === 'danger') {
    return {
      card: {
        backgroundColor: theme.colors.redDim,
        borderColor: theme.colors.redBorder,
      },
      title: {
        color: theme.colors.red,
      },
      badge: {
        color: theme.colors.red,
      },
    };
  }

  return {
    card: {
      backgroundColor: theme.colors.amberDim,
      borderColor: theme.colors.amberBorder,
    },
    title: {
      color: theme.colors.amber,
    },
    badge: {
      color: theme.colors.amber,
    },
  };
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
  headerAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
    backgroundColor: theme.colors.blueDim,
  },
  headerActionText: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.accent,
  },
  highlightCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 16,
  },
  highlightRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 12,
  },
  highlightEyebrow: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 4,
  },
  highlightTitle: {
    fontSize: theme.fontSize.xl,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  liveBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.greenDim,
    borderWidth: 1,
    borderColor: theme.colors.greenBorder,
  },
  liveDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: theme.colors.green,
  },
  liveText: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.green,
  },
  highlightText: {
    fontSize: theme.fontSize.md,
    color: theme.colors.muted,
    lineHeight: 20,
    marginTop: 10,
  },
  metricRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 14,
  },
  metricCard: {
    flex: 1,
    backgroundColor: theme.colors.surface2,
    borderRadius: theme.borderRadius.base,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: 12,
    paddingHorizontal: 12,
  },
  metricValue: {
    fontSize: theme.fontSize['3xl'],
    fontWeight: theme.fontWeight.semibold,
  },
  metricLabel: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 2,
  },
  incidentCard: {
    borderRadius: theme.borderRadius.base,
    borderWidth: 1,
    padding: 14,
    marginBottom: 10,
  },
  incidentHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  incidentTitle: {
    flex: 1,
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.semibold,
  },
  incidentBadge: {
    fontSize: theme.fontSize.xs,
    fontWeight: theme.fontWeight.semibold,
    textTransform: 'uppercase',
  },
  incidentMeta: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.text,
    marginTop: 4,
  },
  actionRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 6,
  },
  flexBtn: {
    flex: 1,
  },
  divider: {
    height: 1,
    backgroundColor: theme.colors.border,
    marginVertical: 16,
  },
  deviceCard: {
    flexDirection: 'row',
    gap: 12,
    padding: 14,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    marginBottom: 10,
  },
  deviceIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    borderWidth: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  deviceMain: {
    flex: 1,
  },
  deviceHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10,
  },
  deviceName: {
    flex: 1,
    fontSize: theme.fontSize.lg,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  statusPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  statusText: {
    fontSize: theme.fontSize.xs,
    fontWeight: theme.fontWeight.semibold,
  },
  deviceMeta: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 3,
  },
  deviceFoot: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
    marginTop: 10,
  },
  deviceSub: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
  },
});
