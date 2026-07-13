import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  TouchableOpacity,
} from 'react-native';

export default function DetalheFuncionarioScreen({ route, navigation }) {
  const { member } = route.params || {};

  const events = [
    { status: 'absence', text: 'Hoje · sem registo' },
    { status: 'ok', text: 'Ontem · Entrada 07:58 · NFC' },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.row}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{member?.initials || 'JT'}</Text>
          </View>
          <View style={styles.headerInfo}>
            <Text style={styles.headerTitle}>{member?.name || 'João Tembe'}</Text>
            <Text style={styles.headerSub}>RH · Turno 08h–17h</Text>
          </View>
          <View style={[styles.badge, styles.badgeRed]}>
            <Text style={styles.badgeTextRed}>Ausente</Text>
          </View>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body}>
        <Text style={styles.sectionTitle}>Esta semana</Text>

        <View style={styles.statsRow}>
          <View style={styles.stat}>
            <Text style={styles.statValue}>4</Text>
            <Text style={styles.statLabel}>Presenças</Text>
          </View>
          <View style={styles.stat}>
            <Text style={[styles.statValue, { color: '#E24B4A' }]}>1</Text>
            <Text style={styles.statLabel}>Faltas</Text>
          </View>
        </View>

        <Text style={styles.sectionTitle}>Eventos recentes</Text>

        {events.map((event, index) => {
          const dotColor =
            event.status === 'ok' ? '#1D9E75' : '#E24B4A';
          return (
            <View key={index} style={styles.eventItem}>
              <View style={[styles.dot, { backgroundColor: dotColor }]} />
              <Text style={styles.eventText}>{event.text}</Text>
            </View>
          );
        })}

        <TouchableOpacity style={styles.buttonAmber}>
          <Text style={styles.buttonAmberText}>Registar manualmente</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.buttonOutline}>
          <Text style={styles.buttonOutlineText}>Justificar falta</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  header: {
    padding: 16,
    borderBottomWidth: 0.5,
    borderBottomColor: '#E0E0E0',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#FCEBEB',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#A32D2D',
  },
  headerInfo: {
    marginLeft: 12,
    flex: 1,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: '500',
    color: '#1A1A1A',
  },
  headerSub: {
    fontSize: 12,
    color: '#8C8C8C',
    marginTop: 2,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
  },
  badgeRed: {
    backgroundColor: '#FCEBEB',
  },
  badgeTextRed: {
    fontSize: 10,
    fontWeight: '500',
    color: '#A32D2D',
  },
  body: {
    padding: 16,
  },
  sectionTitle: {
    fontSize: 11,
    color: '#8C8C8C',
    marginBottom: 8,
  },
  statsRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 16,
  },
  stat: {
    flex: 1,
    backgroundColor: '#F5F5F5',
    borderRadius: 8,
    padding: 10,
    borderWidth: 0.5,
    borderColor: '#E0E0E0',
  },
  statValue: {
    fontSize: 24,
    fontWeight: '500',
    color: '#1A1A1A',
  },
  statLabel: {
    fontSize: 10,
    color: '#8C8C8C',
    marginTop: 2,
  },
  eventItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 6,
    borderBottomWidth: 0.5,
    borderBottomColor: '#E0E0E0',
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginRight: 8,
  },
  eventText: {
    fontSize: 11,
    color: '#1A1A1A',
  },
  buttonAmber: {
    backgroundColor: '#BA7517',
    borderRadius: 8,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 16,
  },
  buttonAmberText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '500',
  },
  buttonOutline: {
    borderWidth: 0.5,
    borderColor: '#D0D0D0',
    borderRadius: 8,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonOutlineText: {
    color: '#4A4A4A',
    fontSize: 14,
  },
});
