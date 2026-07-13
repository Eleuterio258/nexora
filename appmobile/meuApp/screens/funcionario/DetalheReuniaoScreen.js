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
import { Button } from '../../src/components';

const defaultAgenda = [
  'Abertura e alinhamento do objetivo da reunião',
  'Revisão dos pontos pendentes da semana',
  'Definição de próximos passos e responsáveis',
];

const defaultParticipants = ['Gestor Financeira', 'Amélia Langa', 'Helena Cossa', 'Pedro Sitoe'];

export default function DetalheReuniaoScreen({ navigation, route }) {
  const title = route?.params?.title || 'Reunião';
  const time = route?.params?.time || '00:00';
  const meta = route?.params?.meta || 'Sem detalhe';
  const mode = route?.params?.mode || 'Presencial';
  const participants = route?.params?.participants || defaultParticipants;
  const agendaItems = route?.params?.agendaItems || defaultAgenda;

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={20} color={theme.colors.text} />
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>Detalhe da reunião</Text>
          <Text style={styles.headerSub}>{title}</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.heroCard}>
          <View style={styles.heroIcon}>
            <MaterialCommunityIcons name="video-outline" size={20} color={theme.colors.accent} />
          </View>
          <View style={styles.heroInfo}>
            <Text style={styles.heroTitle}>{title}</Text>
            <Text style={styles.heroMeta}>{time} · {meta}</Text>
            <Text style={styles.heroMode}>{mode}</Text>
          </View>
        </View>

        <Text style={styles.sectionTitle}>Informação</Text>
        <View style={styles.infoCard}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Horário</Text>
            <Text style={styles.infoValue}>{time}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Contexto</Text>
            <Text style={styles.infoValue}>{meta}</Text>
          </View>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Formato</Text>
            <Text style={styles.infoValue}>{mode}</Text>
          </View>
        </View>

        <Text style={styles.sectionTitle}>Participantes</Text>
        <View style={styles.infoCard}>
          {participants.map((person) => (
            <View key={person} style={styles.participantRow}>
              <View style={styles.participantDot} />
              <Text style={styles.participantText}>{person}</Text>
            </View>
          ))}
        </View>

        <Text style={styles.sectionTitle}>Agenda</Text>
        <View style={styles.infoCard}>
          {agendaItems.map((item, index) => (
            <View key={`${index}-${item}`} style={styles.participantRow}>
              <Text style={styles.agendaIndex}>{index + 1}.</Text>
              <Text style={styles.participantText}>{item}</Text>
            </View>
          ))}
        </View>

        <Button label="Entrar na reunião" onPress={() => {}} />
        <Button label="Abrir chat do grupo" onPress={() => navigation.navigate('ChatGrupo')} variant="outline" style={styles.secondaryButton} />
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
    backgroundColor: theme.colors.infoDim,
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
  heroMode: {
    marginTop: 6,
    alignSelf: 'flex-start',
    fontSize: 11,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.accent,
    backgroundColor: theme.colors.infoDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
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
  participantRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
    paddingVertical: 6,
  },
  participantDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: theme.colors.accent,
    marginTop: 5,
  },
  agendaIndex: {
    width: 18,
    fontSize: 12,
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.semibold,
  },
  participantText: {
    flex: 1,
    fontSize: 12,
    color: theme.colors.text,
    lineHeight: 18,
  },
  secondaryButton: {
    marginTop: 10,
  },
});
