import React, { useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { Button } from '../../src/components';

const meetingTypes = ['Presencial', 'Online', 'Híbrida'];
const availableParticipants = ['Gestor Financeira', 'Helena Cossa', 'Pedro Sitoe', 'Sofia Cumbe', 'João Tembe'];

export default function CriarReuniaoScreen({ navigation }) {
  const [title, setTitle] = useState('Reunião de alinhamento');
  const [type, setType] = useState(meetingTypes[0]);
  const [time, setTime] = useState('10:00');
  const [date, setDate] = useState('2026-04-20');
  const [location, setLocation] = useState('Sala 2');
  const [participants, setParticipants] = useState(['Gestor Financeira', 'Helena Cossa', 'Pedro Sitoe']);
  const [participantSearch, setParticipantSearch] = useState('');
  const [participantsOpen, setParticipantsOpen] = useState(false);
  const [agenda, setAgenda] = useState('1. Alinhamento inicial\n2. Revisão de tarefas\n3. Próximos passos');

  const filteredParticipants = availableParticipants.filter((person) =>
    person.toLowerCase().includes(participantSearch.toLowerCase())
  );

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={20} color={theme.colors.text} />
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>Criar Reunião</Text>
          <Text style={styles.headerSub}>Defina horário, participantes e agenda</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.heroCard}>
          <View style={styles.heroIcon}>
            <MaterialCommunityIcons name="calendar-clock-outline" size={20} color={theme.colors.accent} />
          </View>
          <View style={styles.heroInfo}>
            <Text style={styles.heroTitle}>Nova reunião</Text>
            <Text style={styles.heroMeta}>Crie uma reunião com participantes, horário e agenda definidos.</Text>
          </View>
        </View>

        <Text style={styles.label}>Título</Text>
        <TextInput
          style={styles.input}
          value={title}
          onChangeText={setTitle}
          placeholder="Título da reunião"
          placeholderTextColor={theme.colors.muted}
        />

        <Text style={styles.label}>Tipo</Text>
        <View style={styles.typeRow}>
          {meetingTypes.map((item) => {
            const isActive = item === type;
            return (
              <TouchableOpacity
                key={item}
                style={[styles.typeChip, isActive && styles.typeChipActive]}
                onPress={() => setType(item)}
                activeOpacity={0.9}
              >
                <Text style={[styles.typeChipText, isActive && styles.typeChipTextActive]}>{item}</Text>
              </TouchableOpacity>
            );
          })}
        </View>

        <View style={styles.row}>
          <View style={styles.field}>
            <Text style={styles.label}>Data</Text>
            <TextInput
              style={styles.input}
              value={date}
              onChangeText={setDate}
              placeholder="AAAA-MM-DD"
              placeholderTextColor={theme.colors.muted}
            />
          </View>
          <View style={styles.field}>
            <Text style={styles.label}>Hora</Text>
            <TextInput
              style={styles.input}
              value={time}
              onChangeText={setTime}
              placeholder="10:00"
              placeholderTextColor={theme.colors.muted}
            />
          </View>
        </View>

        <Text style={styles.label}>Local / Link</Text>
        <TextInput
          style={styles.input}
          value={location}
          onChangeText={setLocation}
          placeholder="Sala ou link da reunião"
          placeholderTextColor={theme.colors.muted}
        />

        <Text style={styles.label}>Participantes</Text>
        <TouchableOpacity
          style={styles.dropdownTrigger}
          onPress={() => setParticipantsOpen((open) => !open)}
          activeOpacity={0.9}
        >
          <Text style={styles.dropdownTriggerText}>
            {participants.length ? `${participants.length} participante(s) selecionado(s)` : 'Selecionar participantes'}
          </Text>
          <MaterialCommunityIcons
            name={participantsOpen ? 'chevron-up' : 'chevron-down'}
            size={20}
            color={theme.colors.muted}
          />
        </TouchableOpacity>

        {participantsOpen ? (
          <View style={styles.dropdownPanel}>
            <TextInput
              style={styles.searchInput}
              value={participantSearch}
              onChangeText={setParticipantSearch}
              placeholder="Pesquisar participante"
              placeholderTextColor={theme.colors.muted}
            />
            <ScrollView style={styles.dropdownList} nestedScrollEnabled>
              {filteredParticipants.map((person) => {
                const isSelected = participants.includes(person);

                return (
                  <TouchableOpacity
                    key={person}
                    style={styles.dropdownOption}
                    onPress={() => setParticipants((current) => (
                      current.includes(person)
                        ? current.filter((item) => item !== person)
                        : [...current, person]
                    ))}
                    activeOpacity={0.9}
                  >
                    <Text style={[styles.dropdownOptionText, isSelected && styles.dropdownOptionTextActive]}>
                      {person}
                    </Text>
                    {isSelected ? (
                      <MaterialCommunityIcons name="check" size={18} color={theme.colors.accent} />
                    ) : null}
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </View>
        ) : null}

        <View style={styles.selectedParticipantsWrap}>
          {participants.map((person) => (
            <View key={person} style={styles.selectedParticipantChip}>
              <Text style={styles.selectedParticipantText}>{person}</Text>
            </View>
          ))}
        </View>

        <Text style={styles.label}>Agenda</Text>
        <TextInput
          style={[styles.input, styles.textAreaLarge]}
          value={agenda}
          onChangeText={setAgenda}
          placeholder="Pontos da reunião"
          placeholderTextColor={theme.colors.muted}
          multiline
          textAlignVertical="top"
        />

        <Button label="Criar reunião" onPress={() => {}} />
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
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 20,
    padding: 16,
    marginBottom: 18,
  },
  heroIcon: {
    width: 46,
    height: 46,
    borderRadius: 16,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroInfo: {
    flex: 1,
  },
  heroTitle: {
    fontSize: 15,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  heroMeta: {
    marginTop: 3,
    fontSize: 12,
    color: theme.colors.muted,
    lineHeight: 18,
  },
  label: {
    fontSize: 11,
    color: theme.colors.muted,
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 0.6,
    marginLeft: 4,
  },
  input: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 14,
    color: theme.colors.text,
    marginBottom: 14,
  },
  row: {
    flexDirection: 'row',
    gap: 12,
  },
  field: {
    flex: 1,
  },
  typeRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 14,
  },
  typeChip: {
    paddingHorizontal: 16,
    paddingVertical: 11,
    borderRadius: 999,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
  },
  typeChipActive: {
    backgroundColor: theme.colors.infoDim,
    borderColor: theme.colors.blueBorder,
  },
  typeChipText: {
    fontSize: 13,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  typeChipTextActive: {
    color: theme.colors.accent,
  },
  dropdownTrigger: {
    minHeight: 52,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 16,
    paddingHorizontal: 16,
    marginBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  dropdownTriggerText: {
    fontSize: 14,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  dropdownPanel: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 18,
    padding: 12,
    marginBottom: 10,
  },
  searchInput: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 14,
    color: theme.colors.text,
    marginBottom: 10,
  },
  dropdownList: {
    maxHeight: 180,
  },
  dropdownOption: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 10,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  dropdownOptionText: {
    flex: 1,
    fontSize: 14,
    color: theme.colors.text,
  },
  dropdownOptionTextActive: {
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.semibold,
  },
  selectedParticipantsWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    marginBottom: 14,
  },
  selectedParticipantChip: {
    paddingHorizontal: 14,
    paddingVertical: 9,
    borderRadius: 999,
    backgroundColor: theme.colors.infoDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
  },
  selectedParticipantText: {
    fontSize: 13,
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.medium,
  },
  textAreaLarge: {
    minHeight: 120,
  },
});
