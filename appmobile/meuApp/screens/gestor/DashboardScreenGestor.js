import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  StatusBar,
} from 'react-native';
import { theme } from '../../src/theme';
import { AppHeader, SectionLabel, EventItem, GestorBottomNav } from '../../src/components';
import { hasModule, loadStoredAccess } from '../../src/access';

const methods = [
  { name: 'Facial', count: 24, pct: 51, color: theme.colors.green },
  { name: 'NFC / Cartão', count: 14, pct: 30, color: theme.colors.blue },
  { name: 'QR Code', count: 8, pct: 17, color: theme.colors.amber },
  { name: 'Manual', count: 1, pct: 2, color: theme.colors.red },
];

const events = [
  { name: 'Carlos Nhaca', meta: '09:38 · Entrada · Facial · 93%', status: 'ok', initials: 'CN' },
  { name: 'Fátima Bila', meta: '09:18 · Entrada · QR · 18 min tarde', status: 'late', initials: 'FB' },
  { name: 'João Tembe', meta: '— · Sem registo · alerta activo', status: 'absent', initials: 'JT' },
  { name: 'Amélia Langa', meta: '08:17 · Entrada · NFC', status: 'ok', initials: 'AL' },
  { name: 'Manuel Neves', meta: '12:30 · Saída · QR', status: 'exit', initials: 'MN' },
  { name: 'Sofia Cumbe', meta: '08:04 · Entrada · Facial · 97%', status: 'ok', initials: 'SC' },
];

export default function DashboardScreenGestor({ navigation }) {
  const presencePct = 89;
  const [modules, setModules] = useState([]);

  useEffect(() => {
    let mounted = true;

    loadStoredAccess()
      .then(({ modules: storedModules }) => {
        if (mounted) {
          setModules(storedModules);
        }
      })
      .catch(() => {
        if (mounted) {
          setModules([]);
        }
      });

    return () => {
      mounted = false;
    };
  }, []);

  const canAccessHR = hasModule(modules, 'hr');
  const canAccessReports = hasModule(modules, 'reports');
  const canAccessCRM = hasModule(modules, 'crm');

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader
        title="Dashboard"
        subtitle="Turno manhã · 08h–17h"
        rightContent={
          <View style={styles.wsBadge}>
            <View style={styles.wsDot} />
            <Text style={styles.wsText}>live</Text>
          </View>
        }
      />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Alert Banner */}
        {canAccessHR ? (
        <View style={styles.alertBanner}>
          <View style={styles.alertHeader}>
            <Text style={styles.alertTitle}>Rosto não identificado</Text>
            <View style={styles.severityBadge}>
              <Text style={styles.severityText}>Crítico</Text>
            </View>
          </View>
          <Text style={styles.alertSub}>Câmara Entrada Principal · 09:44:12</Text>
          <View style={styles.alertActions}>
            <TouchableOpacity
              style={styles.alertBtnPrimary}
              onPress={() => navigation.navigate('Ocorrencias')}
            >
              <Text style={styles.alertBtnPrimaryText}>Ver ocorrências</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.alertBtnSecondary}>
              <Text style={styles.alertBtnSecondaryText}>Ignorar</Text>
            </TouchableOpacity>
          </View>
        </View>
        ) : null}

        {canAccessHR ? (
        <View style={styles.statGrid}>
          <TouchableOpacity
            style={styles.statCard}
            activeOpacity={0.85}
            onPress={() => navigation.navigate('EquipaGestor')}
          >
            <Text style={[styles.statValue, { color: theme.colors.green }]}>47</Text>
            <Text style={styles.statLabel}>Presentes</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.statCard}
            activeOpacity={0.85}
            onPress={() => navigation.navigate('EquipaGestor')}
          >
            <Text style={[styles.statValue, { color: theme.colors.red }]}>3</Text>
            <Text style={styles.statLabel}>Ausentes</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.statCard}
            activeOpacity={0.85}
            onPress={() => navigation.navigate('EquipaGestor')}
          >
            <Text style={[styles.statValue, { color: theme.colors.amber }]}>2</Text>
            <Text style={styles.statLabel}>Atrasados</Text>
          </TouchableOpacity>
          <View style={styles.statCard}>
            <Text style={[styles.statValue, { color: theme.colors.blue }]}>5</Text>
            <Text style={styles.statLabel}>Sync pendente</Text>
          </View>
        </View>
        ) : null}

        {canAccessCRM ? (
          <TouchableOpacity
            style={styles.crmCard}
            activeOpacity={0.85}
            onPress={() => navigation.navigate('ModuleCRM')}
          >
            <View style={styles.crmIconWrap}>
              <Text style={styles.crmIconText}>CRM</Text>
            </View>
            <View style={styles.crmInfo}>
              <Text style={styles.crmTitle}>Modulo CRM</Text>
              <Text style={styles.crmSub}>Aceda a contas, leads e pipeline comercial no mobile.</Text>
            </View>
          </TouchableOpacity>
        ) : null}

        <TouchableOpacity
          style={styles.crmCard}
          activeOpacity={0.85}
          onPress={() => navigation.navigate('ModulesHub')}
        >
          <View style={styles.crmIconWrap}>
            <Text style={styles.crmIconText}>MOD</Text>
          </View>
          <View style={styles.crmInfo}>
            <Text style={styles.crmTitle}>Todos os modulos</Text>
            <Text style={styles.crmSub}>Navegue pelos 19 modulos oficiais conforme o acesso do utilizador.</Text>
          </View>
        </TouchableOpacity>

        <View style={styles.presenceBlock}>
          <View style={styles.presenceRow}>
            <Text style={styles.presenceLabel}>Taxa de presença · hoje</Text>
            <Text style={styles.presencePct}>{presencePct}%</Text>
          </View>
          <View style={styles.barTrack}>
            <View style={[styles.barFill, { width: `${presencePct}%` }]} />
          </View>
        </View>

        <View style={styles.divider} />

        {canAccessReports ? (
        <View style={styles.methodSection}>
          <SectionLabel style={styles.methodSectionLabel}>Por método</SectionLabel>
          <View style={styles.methodList}>
            {methods.map((method, index) => (
              <View key={index} style={styles.methodRow}>
                <View style={[styles.methodDot, { backgroundColor: method.color }]} />
                <Text style={styles.methodName}>{method.name}</Text>
                <View style={styles.methodBarTrack}>
                  <View style={[styles.methodBarFill, { width: `${method.pct}%`, backgroundColor: method.color }]} />
                </View>
                <Text style={styles.methodCount}>{method.count}</Text>
              </View>
            ))}
          </View>
        </View>
        ) : null}

        {canAccessHR ? <View style={styles.divider} /> : null}

        {canAccessHR ? (
        <View style={styles.eventsSection}>
          <SectionLabel style={styles.eventsSectionLabel}>Eventos recentes</SectionLabel>
          {events.map((event, index) => (
            <EventItem
              key={index}
              name={event.name}
              meta={event.meta}
              status={event.status}
              onPress={() => navigation.navigate('DetalheFuncionario', {
                name: event.name,
                initials: event.initials,
                dept: 'Financeira'
              })}
            />
          ))}
        </View>
        ) : (
        <View style={styles.emptyState}>
          <Text style={styles.emptyStateTitle}>Sem telas de gestao adicionais</Text>
          <Text style={styles.emptyStateText}>Os cards e atalhos desta area aparecem de acordo com os modulos atribuidos ao utilizador.</Text>
        </View>
        )}

        <View style={{ height: 80 }} />
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="dashboard" />
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
  wsBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderRadius: 20,
    backgroundColor: theme.colors.greenDim,
    borderWidth: 1,
    borderColor: theme.colors.greenBorder,
  },
  wsDot: {
    width: 5,
    height: 5,
    borderRadius: 2.5,
    backgroundColor: theme.colors.green,
  },
  wsText: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.green,
  },
  alertBanner: {
    backgroundColor: theme.colors.redDim,
    borderWidth: 1,
    borderColor: theme.colors.redBorder,
    borderRadius: theme.borderRadius.base,
    padding: 13,
    marginHorizontal: 16,
    marginBottom: 14,
  },
  alertHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  alertTitle: {
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.red,
  },
  alertSub: {
    fontSize: theme.fontSize.base,
    color: theme.colors.muted,
    marginBottom: 8,
  },
  alertActions: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  alertBtnPrimary: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: theme.colors.red,
  },
  alertBtnPrimaryText: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.medium,
    color: '#fff',
  },
  alertBtnSecondary: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
  },
  alertBtnSecondaryText: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.muted,
  },
  severityBadge: {
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: theme.colors.redDim,
    borderWidth: 1,
    borderColor: theme.colors.redBorder,
  },
  severityText: {
    fontSize: theme.fontSize.xs,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.red,
    letterSpacing: 0.05,
    textTransform: 'uppercase',
  },
  statGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.sm,
    paddingHorizontal: 16,
  },
  statCard: {
    flex: 1,
    minWidth: '45%',
    backgroundColor: theme.colors.surface2,
    borderRadius: 10,
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  crmCard: {
    marginHorizontal: 16,
    marginTop: 14,
    padding: 14,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
    backgroundColor: theme.colors.blueDim,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  crmIconWrap: {
    width: 46,
    height: 46,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.blue,
  },
  crmIconText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: theme.fontWeight.bold,
  },
  crmInfo: {
    flex: 1,
  },
  crmTitle: {
    fontSize: 15,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.semibold,
  },
  crmSub: {
    marginTop: 3,
    fontSize: 12,
    lineHeight: 18,
    color: theme.colors.muted,
  },
  statValue: {
    fontSize: 26,
    fontWeight: theme.fontWeight.semibold,
    letterSpacing: -1,
  },
  statLabel: {
    fontSize: theme.fontSize.xs,
    color: theme.colors.muted,
    marginTop: 2,
  },
  presenceBlock: {
    paddingHorizontal: 16,
    marginTop: 14,
  },
  presenceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'baseline',
    marginBottom: theme.spacing.sm,
  },
  presenceLabel: {
    fontSize: theme.fontSize.base,
    color: theme.colors.muted,
  },
  presencePct: {
    fontSize: theme.fontSize['2xl'],
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.green,
  },
  barTrack: {
    height: 4,
    backgroundColor: theme.colors.hint,
    borderRadius: 2,
  },
  barFill: {
    height: '100%',
    backgroundColor: theme.colors.green,
    borderRadius: 2,
  },
  divider: {
    height: 1,
    backgroundColor: theme.colors.border,
    marginVertical: 14,
  },
  methodSection: {
    paddingHorizontal: 16,
  },
  methodSectionLabel: {
    marginTop: 0,
  },
  eventsSection: {
    paddingHorizontal: 16,
  },
  eventsSectionLabel: {
    marginTop: 0,
  },
  methodList: {
  },
  methodRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
    marginBottom: theme.spacing.sm,
  },
  methodDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  methodName: {
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
    width: 100,
  },
  methodBarTrack: {
    flex: 2,
    height: 3,
    backgroundColor: theme.colors.hint,
    borderRadius: 2,
  },
  methodBarFill: {
    height: '100%',
    borderRadius: 2,
  },
  methodCount: {
    fontSize: theme.fontSize.base,
    color: theme.colors.muted,
    minWidth: 24,
    textAlign: 'right',
  },
  emptyState: {
    marginHorizontal: 16,
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.surface2,
  },
  emptyStateTitle: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  emptyStateText: {
    marginTop: 4,
    fontSize: 12,
    lineHeight: 18,
    color: theme.colors.muted,
  },
});
