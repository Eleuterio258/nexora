import React from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';

function getBadgeConfig(kind) {
  if (kind === 'birthday') {
    return {
      title: 'Detalhe do aniversario',
      icon: 'cake-variant-outline',
      accent: theme.colors.amber,
      bg: theme.colors.amberDim,
      border: theme.colors.amberBorder,
      badge: 'Aniversario',
    };
  }

  return {
    title: 'Detalhe do evento',
    icon: 'calendar-month-outline',
    accent: theme.colors.blue,
    bg: theme.colors.infoDim,
    border: theme.colors.blueBorder,
    badge: 'Evento',
  };
}

export default function DetalheAgendaItemScreen({ navigation, route }) {
  const kind = route?.params?.kind || 'event';
  const title = route?.params?.title || 'Item da agenda';
  const subtitle = route?.params?.subtitle || 'Sem detalhe';
  const time = route?.params?.time || 'Sem horario';
  const dateLabel = route?.params?.dateLabel || '';
  const details = route?.params?.details || [];
  const badgeConfig = getBadgeConfig(kind);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={20} color={theme.colors.text} />
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>{badgeConfig.title}</Text>
          <Text style={styles.headerSub}>{title}</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.heroCard}>
          <View style={[styles.heroIcon, { backgroundColor: badgeConfig.bg, borderColor: badgeConfig.border }]}>
            <MaterialCommunityIcons name={badgeConfig.icon} size={20} color={badgeConfig.accent} />
          </View>
          <View style={styles.heroInfo}>
            <Text style={styles.heroTitle}>{title}</Text>
            <Text style={styles.heroMeta}>{subtitle}</Text>
            <Text style={[styles.heroBadge, { color: badgeConfig.accent, backgroundColor: badgeConfig.bg, borderColor: badgeConfig.border }]}>
              {badgeConfig.badge}
            </Text>
          </View>
        </View>

        <Text style={styles.sectionTitle}>Informacao</Text>
        <View style={styles.infoCard}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Data</Text>
            <Text style={styles.infoValue}>{dateLabel || '-'}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Horario</Text>
            <Text style={styles.infoValue}>{time}</Text>
          </View>
          <View style={styles.infoRowLast}>
            <Text style={styles.infoLabel}>Contexto</Text>
            <Text style={styles.infoValue}>{subtitle}</Text>
          </View>
        </View>

        {details.length > 0 && (
          <>
            <Text style={styles.sectionTitle}>Detalhes</Text>
            <View style={styles.infoCard}>
              {details.map((item, index) => (
                <View key={`${index}-${item.label}`} style={index === details.length - 1 ? styles.infoRowLast : styles.infoRow}>
                  <Text style={styles.infoLabel}>{item.label}</Text>
                  <Text style={styles.infoValue}>{item.value}</Text>
                </View>
              ))}
            </View>
          </>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.surface,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 14,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  headerInfo: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  headerSub: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
  body: {
    padding: 16,
    paddingBottom: 24,
  },
  heroCard: {
    flexDirection: 'row',
    gap: 12,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
  },
  heroIcon: {
    width: 44,
    height: 44,
    borderRadius: 14,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroInfo: {
    flex: 1,
  },
  heroTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  heroMeta: {
    marginTop: 4,
    fontSize: 12,
    color: theme.colors.muted,
  },
  heroBadge: {
    marginTop: 6,
    alignSelf: 'flex-start',
    fontSize: 11,
    fontWeight: theme.fontWeight.semibold,
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  sectionTitle: {
    fontSize: 12,
    color: theme.colors.muted,
    marginBottom: 10,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  infoCard: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 14,
    marginBottom: 14,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  infoRowLast: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
    paddingVertical: 8,
  },
  infoLabel: {
    fontSize: 12,
    color: theme.colors.muted,
  },
  infoValue: {
    flex: 1,
    textAlign: 'right',
    fontSize: 12,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
});
