import React, { useMemo, useState } from 'react';
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

const reportsByPeriod = {
  Diario: {
    label: '06 Abril 2026',
    summary: 'Resumo do turno da manha com ocorrencias e desvios do dia.',
    stats: [
      { label: 'Presentes', value: '47', color: theme.colors.green },
      { label: 'Taxa', value: '89%', color: theme.colors.text },
      { label: 'Atrasos', value: '2', color: theme.colors.amber },
      { label: 'Faltas', value: '3', color: theme.colors.red },
    ],
    trends: [
      { label: 'Entrada antes das 08h', value: '31', tone: 'success' },
      { label: 'Validacoes manuais', value: '4', tone: 'info' },
      { label: 'Pendencias de sync', value: '1', tone: 'warning' },
    ],
  },
  Semanal: {
    label: 'Semana 14 · 01-06 Abril',
    summary: 'Consolidado semanal para assiduidade, atrasos e performance dos dispositivos.',
    stats: [
      { label: 'Presencas', value: '281', color: theme.colors.green },
      { label: 'Media', value: '90%', color: theme.colors.text },
      { label: 'Atrasos', value: '11', color: theme.colors.amber },
      { label: 'Faltas', value: '7', color: theme.colors.red },
    ],
    trends: [
      { label: 'Melhor dia', value: 'Quarta · 94%', tone: 'success' },
      { label: 'Face ID dominante', value: '57%', tone: 'info' },
      { label: 'Alertas criticos', value: '2', tone: 'warning' },
    ],
  },
  Mensal: {
    label: 'Abril 2026',
    summary: 'Visao acumulada do mes para exportacao e apoio de payroll.',
    stats: [
      { label: 'Presencas', value: '1083', color: theme.colors.green },
      { label: 'Media', value: '91%', color: theme.colors.text },
      { label: 'Atrasos', value: '39', color: theme.colors.amber },
      { label: 'Faltas', value: '18', color: theme.colors.red },
    ],
    trends: [
      { label: 'Horas validadas', value: '8 442h', tone: 'success' },
      { label: 'NFC / Cartao', value: '29%', tone: 'info' },
      { label: 'Correcao manual', value: '13 registos', tone: 'warning' },
    ],
  },
};

const methods = [
  { name: 'Facial', count: 24, pct: 51, color: theme.colors.green },
  { name: 'NFC / Cartao', count: 14, pct: 30, color: theme.colors.blue },
  { name: 'QR Code', count: 8, pct: 17, color: theme.colors.amber },
  { name: 'Manual', count: 1, pct: 2, color: theme.colors.red },
];

const exportActions = [
  { icon: 'file-pdf-box', label: 'Exportar PDF', meta: 'Resumo visual para partilha' },
  { icon: 'microsoft-excel', label: 'Exportar Excel', meta: 'Base detalhada para analise' },
  { icon: 'email-fast-outline', label: 'Enviar por email', meta: 'Distribuir para RH e direccao' },
];

export default function RelatoriosScreenGestor({ navigation }) {
  const [period, setPeriod] = useState('Diario');

  const report = useMemo(() => reportsByPeriod[period], [period]);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />

      <AppHeader
        title="Relatorios"
        subtitle="Operacionais e exportacao"
        rightContent={
          <TouchableOpacity
            style={styles.headerAction}
            activeOpacity={0.9}
            onPress={() => navigation.navigate('DashboardGestor')}
          >
            <MaterialCommunityIcons name="chart-line" size={16} color={theme.colors.accent} />
            <Text style={styles.headerActionText}>Resumo</Text>
          </TouchableOpacity>
        }
      />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.body}>
          <View style={styles.periodRow}>
            {['Diario', 'Semanal', 'Mensal'].map((item) => {
              const isActive = period === item;
              return (
                <TouchableOpacity
                  key={item}
                  style={[styles.periodBtn, isActive && styles.periodBtnActive]}
                  onPress={() => setPeriod(item)}
                  activeOpacity={0.9}
                >
                  <Text style={[styles.periodBtnText, isActive && styles.periodBtnTextActive]}>
                    {item}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>

          <View style={styles.heroCard}>
            <View style={styles.heroHead}>
              <View>
                <Text style={styles.heroEyebrow}>{report.label}</Text>
                <Text style={styles.heroTitle}>Assiduidade consolidada</Text>
              </View>
              <View style={styles.heroBadge}>
                <MaterialCommunityIcons name="calendar-check-outline" size={14} color={theme.colors.blue} />
                <Text style={styles.heroBadgeText}>{period}</Text>
              </View>
            </View>
            <Text style={styles.heroText}>{report.summary}</Text>
            <View style={styles.reportStatGrid}>
              {report.stats.map((stat) => (
                <View key={stat.label} style={styles.statCard}>
                  <Text style={[styles.statValue, { color: stat.color }]}>{stat.value}</Text>
                  <Text style={styles.statLabel}>{stat.label}</Text>
                </View>
              ))}
            </View>
          </View>

          <SectionLabel>Indicadores chave</SectionLabel>
          <View style={styles.trendList}>
            {report.trends.map((trend) => {
              const toneStyle = getToneStyle(trend.tone);
              return (
                <View key={trend.label} style={styles.trendCard}>
                  <View style={[styles.trendIconWrap, toneStyle.iconWrap]}>
                    <MaterialCommunityIcons name={toneStyle.icon} size={16} color={toneStyle.iconColor} />
                  </View>
                  <View style={styles.trendMain}>
                    <Text style={styles.trendLabel}>{trend.label}</Text>
                    <Text style={[styles.trendValue, { color: toneStyle.iconColor }]}>{trend.value}</Text>
                  </View>
                </View>
              );
            })}
          </View>

          <View style={styles.divider} />

          <SectionLabel>Por metodo</SectionLabel>
          <View style={styles.methodList}>
            {methods.map((method) => (
              <View key={method.name} style={styles.methodRow}>
                <View style={[styles.methodDot, { backgroundColor: method.color }]} />
                <Text style={styles.methodName}>{method.name}</Text>
                <View style={styles.methodBarTrack}>
                  <View
                    style={[
                      styles.methodBarFill,
                      { width: `${method.pct}%`, backgroundColor: method.color },
                    ]}
                  />
                </View>
                <Text style={styles.methodCount}>{method.count}</Text>
              </View>
            ))}
          </View>

          <View style={styles.divider} />

          <SectionLabel>Exportar relatorio</SectionLabel>
          {exportActions.map((action) => (
            <TouchableOpacity key={action.label} style={styles.exportCard} activeOpacity={0.92}>
              <View style={styles.exportIcon}>
                <MaterialCommunityIcons name={action.icon} size={20} color={theme.colors.blue} />
              </View>
              <View style={styles.exportMain}>
                <Text style={styles.exportLabel}>{action.label}</Text>
                <Text style={styles.exportMeta}>{action.meta}</Text>
              </View>
              <MaterialCommunityIcons name="chevron-right" size={20} color={theme.colors.muted} />
            </TouchableOpacity>
          ))}

          <View style={styles.actionRow}>
            <Button
              label="Ver equipa"
              onPress={() => navigation.navigate('EquipaGestor')}
              variant="outline"
              style={styles.flexBtn}
            />
            <Button
              label="Ocorrencias"
              onPress={() => navigation.navigate('Ocorrencias')}
              variant="primary"
              style={styles.flexBtn}
            />
          </View>
        </View>
      </ScrollView>

      <GestorBottomNav navigation={navigation} activeKey="relatorios" />
    </SafeAreaView>
  );
}

function getToneStyle(tone) {
  if (tone === 'success') {
    return {
      icon: 'check-circle-outline',
      iconColor: theme.colors.green,
      iconWrap: { backgroundColor: theme.colors.greenDim, borderColor: theme.colors.greenBorder },
    };
  }

  if (tone === 'warning') {
    return {
      icon: 'alert-outline',
      iconColor: theme.colors.amber,
      iconWrap: { backgroundColor: theme.colors.amberDim, borderColor: theme.colors.amberBorder },
    };
  }

  return {
    icon: 'information-outline',
    iconColor: theme.colors.blue,
    iconWrap: { backgroundColor: theme.colors.blueDim, borderColor: theme.colors.blueBorder },
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
  periodRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 14,
  },
  periodBtn: {
    flex: 1,
    minHeight: 42,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    backgroundColor: theme.colors.surface,
    justifyContent: 'center',
    alignItems: 'center',
  },
  periodBtnActive: {
    backgroundColor: theme.colors.blueDim,
    borderColor: theme.colors.blueBorder,
  },
  periodBtnText: {
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.muted,
  },
  periodBtnTextActive: {
    color: theme.colors.accent,
  },
  heroCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 16,
  },
  heroHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 12,
  },
  heroEyebrow: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 4,
  },
  heroTitle: {
    fontSize: theme.fontSize.xl,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  heroBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
  },
  heroBadgeText: {
    fontSize: theme.fontSize.sm,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.blue,
  },
  heroText: {
    fontSize: theme.fontSize.md,
    color: theme.colors.muted,
    lineHeight: 20,
    marginTop: 10,
  },
  reportStatGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    marginTop: 16,
  },
  statCard: {
    flex: 1,
    minWidth: '47%',
    backgroundColor: theme.colors.surface2,
    borderRadius: theme.borderRadius.base,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: 12,
    paddingHorizontal: 14,
  },
  statValue: {
    fontSize: theme.fontSize['3xl'],
    fontWeight: theme.fontWeight.semibold,
    letterSpacing: -0.7,
  },
  statLabel: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 3,
  },
  trendList: {
    gap: 10,
  },
  trendCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.base,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 12,
  },
  trendIconWrap: {
    width: 38,
    height: 38,
    borderRadius: 12,
    borderWidth: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  trendMain: {
    flex: 1,
  },
  trendLabel: {
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  trendValue: {
    fontSize: theme.fontSize.sm,
    marginTop: 2,
  },
  divider: {
    height: 1,
    backgroundColor: theme.colors.border,
    marginVertical: 16,
  },
  methodList: {
    gap: 10,
  },
  methodRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  methodDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  methodName: {
    width: 112,
    fontSize: theme.fontSize.md,
    color: theme.colors.text,
  },
  methodBarTrack: {
    flex: 1,
    height: 6,
    backgroundColor: theme.colors.hint,
    borderRadius: theme.borderRadius.full,
    overflow: 'hidden',
  },
  methodBarFill: {
    height: '100%',
    borderRadius: theme.borderRadius.full,
  },
  methodCount: {
    minWidth: 26,
    textAlign: 'right',
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
  },
  exportCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 14,
    borderRadius: theme.borderRadius.base,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    marginBottom: 10,
  },
  exportIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: theme.colors.blueDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
    justifyContent: 'center',
    alignItems: 'center',
  },
  exportMain: {
    flex: 1,
  },
  exportLabel: {
    fontSize: theme.fontSize.md,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  exportMeta: {
    fontSize: theme.fontSize.sm,
    color: theme.colors.muted,
    marginTop: 2,
  },
  actionRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 6,
  },
  flexBtn: {
    flex: 1,
  },
});
