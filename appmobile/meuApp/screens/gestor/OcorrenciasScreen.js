import React from 'react';
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
import { AppHeader, Button, SectionLabel, GestorBottomNav } from '../../src/components';

const criticalAlert = {
  title: 'Rosto nao identificado',
  sub: 'Camera Entrada Principal · 09:44:12 · validacao bloqueada',
  actions: ['Ver frame', 'Ignorar'],
};

const occurrences = [
  {
    title: 'QR invalido / expirado',
    sub: 'Joao Tembe · tentativa 08:42',
    severity: 'warning',
    label: 'Aviso',
    icon: 'qrcode-scan',
    actions: ['Ver frame', 'Arquivar'],
  },
  {
    title: 'GPS fora do perimetro',
    sub: 'Selfie rejeitada · Fatima Bila · 09:05',
    severity: 'warning',
    label: 'Aviso',
    icon: 'map-marker-alert-outline',
    actions: ['Ver localizacao', 'Arquivar'],
  },
  {
    title: 'Sync ERP pendente',
    sub: '2 eventos · tentativa 3/5 · proximo retry 09:55',
    severity: 'info',
    label: 'Info',
    icon: 'sync-alert',
    actions: ['Forcar retry'],
  },
  {
    title: 'Kiosk Piso 2 offline',
    sub: 'Sem resposta ha 52 min · ultimo ping 08:51',
    severity: 'danger',
    label: 'Critico',
    icon: 'monitor-off',
    actions: ['Ver dispositivos'],
  },
];

export default function OcorrenciasScreen({ navigation }) {
  const openCount = occurrences.length + 1;
  const criticalCount = occurrences.filter((item) => item.severity === 'danger').length + 1;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader
        title="Ocorrencias"
        subtitle={`${openCount} abertas · ${criticalCount} criticas`}
        rightContent={
          <TouchableOpacity
            style={styles.headerAction}
            activeOpacity={0.9}
            onPress={() => navigation.navigate('Dispositivos')}
          >
            <MaterialCommunityIcons name="router-wireless" size={16} color={theme.colors.accent} />
            <Text style={styles.headerActionText}>Infra</Text>
          </TouchableOpacity>
        }
      />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.body}>
          <View style={styles.alertBanner}>
            <View style={styles.alertHead}>
              <View style={styles.alertTitleWrap}>
                <Text style={styles.alertTitle}>{criticalAlert.title}</Text>
                <Text style={styles.alertSub}>{criticalAlert.sub}</Text>
              </View>
              <View style={styles.criticalBadge}>
                <Text style={styles.criticalBadgeText}>Critico</Text>
              </View>
            </View>

            <View style={styles.bannerActionRow}>
              <Button label={criticalAlert.actions[0]} onPress={() => {}} variant="primary" style={styles.flexBtn} />
              <Button label={criticalAlert.actions[1]} onPress={() => {}} variant="outline" style={styles.flexBtn} />
            </View>
          </View>

          <SectionLabel>Fila operacional</SectionLabel>
          {occurrences.map((occurrence) => {
            const tone = getSeverityStyles(occurrence.severity);

            return (
              <View key={occurrence.title} style={styles.occurrenceCard}>
                <View style={styles.occurrenceHead}>
                  <View style={[styles.occurrenceIconShell, tone.iconWrap]}>
                    <MaterialCommunityIcons
                      name={occurrence.icon}
                      size={20}
                      color={tone.iconColor}
                    />
                  </View>

                  <View style={styles.occurrenceInfo}>
                    <View style={styles.occurrenceHeaderRow}>
                      <Text style={styles.occurrenceTitle}>{occurrence.title}</Text>
                      <View style={[styles.statusBadge, tone.badge]}>
                        <Text style={[styles.statusBadgeText, { color: tone.iconColor }]}>
                          {occurrence.label}
                        </Text>
                      </View>
                    </View>
                    <Text style={styles.occurrenceSub}>{occurrence.sub}</Text>
                  </View>
                </View>

                <View style={styles.cardActions}>
                  {occurrence.actions.map((action) => (
                    <TouchableOpacity key={action} style={styles.cardActionBtn} activeOpacity={0.9}>
                      <Text style={styles.cardActionBtnText}>{action}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            );
          })}
        </View>
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="ocorrencias" />
    </SafeAreaView>
  );
}

function getSeverityStyles(severity) {
  if (severity === 'danger') {
    return {
      iconColor: theme.colors.red,
      iconWrap: { backgroundColor: theme.colors.redDim, borderColor: theme.colors.redBorder },
      badge: { backgroundColor: theme.colors.redDim, borderColor: theme.colors.redBorder },
    };
  }

  if (severity === 'warning') {
    return {
      iconColor: theme.colors.amber,
      iconWrap: { backgroundColor: theme.colors.amberDim, borderColor: theme.colors.amberBorder },
      badge: { backgroundColor: theme.colors.amberDim, borderColor: theme.colors.amberBorder },
    };
  }

  return {
    iconColor: theme.colors.blue,
    iconWrap: { backgroundColor: theme.colors.blueDim, borderColor: theme.colors.blueBorder },
    badge: { backgroundColor: theme.colors.blueDim, borderColor: theme.colors.blueBorder },
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
  alertBanner: {
    backgroundColor: theme.colors.redDim,
    borderWidth: 1,
    borderColor: theme.colors.redBorder,
    borderRadius: theme.borderRadius.lg,
    padding: 16,
    marginBottom: 14,
  },
  alertHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 12,
  },
  alertTitleWrap: {
    flex: 1,
  },
  alertTitle: {
    fontSize: theme.fontSize.lg,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.red,
  },
  alertSub: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.text,
    marginTop: 4,
    lineHeight: 18,
  },
  criticalBadge: {
    paddingHorizontal: 9,
    paddingVertical: 5,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.redDim,
    borderWidth: 1,
    borderColor: theme.colors.redBorder,
  },
  criticalBadgeText: {
    fontSize: theme.fontSize.xs,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.red,
    textTransform: 'uppercase',
  },
  bannerActionRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 14,
  },
  flexBtn: {
    flex: 1,
  },
  occurrenceCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 14,
    marginBottom: 10,
  },
  occurrenceHead: {
    flexDirection: 'row',
    gap: 12,
  },
  occurrenceIconShell: {
    width: 42,
    height: 42,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  occurrenceInfo: {
    flex: 1,
  },
  occurrenceHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 8,
    alignItems: 'flex-start',
  },
  occurrenceTitle: {
    flex: 1,
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
  },
  statusBadgeText: {
    fontSize: theme.fontSize.xs,
    fontWeight: theme.fontWeight.semibold,
    textTransform: 'uppercase',
  },
  occurrenceSub: {
    marginTop: 4,
    fontSize: theme.fontSize.base,
    color: theme.colors.muted,
  },
  cardActions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 12,
  },
  cardActionBtn: {
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    backgroundColor: theme.colors.surface2,
  },
  cardActionBtnText: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
});
