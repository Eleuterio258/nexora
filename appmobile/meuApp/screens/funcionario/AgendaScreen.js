import React from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  FlatList,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';

function getToneStyles(tone) {
  if (tone === 'info') return { bg: theme.colors.infoDim, border: theme.colors.blueBorder, color: theme.colors.blue };
  if (tone === 'warning') return { bg: theme.colors.amberDim, border: theme.colors.amberBorder, color: theme.colors.amber };
  return { bg: theme.colors.surface2, border: theme.colors.border, color: theme.colors.text };
}

function generateDaysFrom(startDate, totalDays = 30) {
  const weekFormatter = new Intl.DateTimeFormat('pt-PT', { weekday: 'short' });
  const monthFormatter = new Intl.DateTimeFormat('pt-PT', { month: 'short' });
  const items = [];
  const current = new Date(startDate);
  const end = new Date(startDate);
  end.setDate(end.getDate() + totalDays - 1);

  while (current <= end) {
    items.push({
      key: current.toISOString().slice(0, 10),
      label: weekFormatter.format(current).replace('.', ''),
      date: String(current.getDate()).padStart(2, '0'),
      month: monthFormatter.format(current).replace('.', ''),
    });
    current.setDate(current.getDate() + 1);
  }

  return items;
}

function shiftDate(baseDate, amount) {
  const nextDate = new Date(baseDate);
  nextDate.setDate(nextDate.getDate() + amount);
  return nextDate;
}

function toDateKey(date) {
  return date.toISOString().slice(0, 10);
}

function formatMonthLabel(dateKey) {
  return new Intl.DateTimeFormat('pt-PT', {
    month: 'long',
    year: 'numeric',
  }).format(new Date(dateKey));
}

function formatSelectedDate(dateKey) {
  return new Intl.DateTimeFormat('pt-PT', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  }).format(new Date(dateKey));
}

function buildAgendaData() {
  const today = new Date();
  const tomorrow = shiftDate(today, 1);
  const inThreeDays = shiftDate(today, 3);
  const inSixDays = shiftDate(today, 6);
  const inTenDays = shiftDate(today, 10);

  return {
    events: [
      { dateKey: toDateKey(today), time: '09:00', title: 'Briefing Financeira', meta: 'Sala 2 · Com gestor', icon: 'briefcase-outline', tone: 'info' },
      { dateKey: toDateKey(today), time: '14:00', title: 'Reunião de equipa', meta: 'Grupo Financeira', icon: 'account-group-outline', tone: 'default' },
      { dateKey: toDateKey(tomorrow), time: '16:30', title: 'Entrega de relatório mensal', meta: 'Prazo interno', icon: 'file-document-outline', tone: 'warning' },
    ],
    meetings: [
      { dateKey: toDateKey(today), time: '11:00', title: '1:1 com gestor', meta: 'Revisão semanal de tarefas', icon: 'account-tie-voice-outline' },
      { dateKey: toDateKey(inThreeDays), time: '15:30', title: 'Reunião do projeto ERP', meta: 'Online · Equipa multidisciplinar', icon: 'video-outline' },
    ],
    birthdays: [
      { dateKey: toDateKey(today), name: 'Helena Cossa', dept: 'Financeira', when: 'Hoje', initials: 'HC' },
      { dateKey: toDateKey(inSixDays), name: 'Pedro Sitoe', dept: 'TI', when: '11 Abr', initials: 'PS' },
      { dateKey: toDateKey(inTenDays), name: 'Sofia Cumbe', dept: 'Logística', when: '15 Abr', initials: 'SC' },
    ],
  };
}

const DAY_BATCH_SIZE = 30;
const INITIAL_DAY_BATCHES = 3;
const DAY_ITEM_WIDTH = 76;

export default function AgendaScreen({ navigation }) {
  const todayKey = new Date().toISOString().slice(0, 10);
  const initialStartDate = React.useRef(shiftDate(new Date(), -DAY_BATCH_SIZE)).current;
  const [selectedDayKey, setSelectedDayKey] = React.useState(todayKey);
  const [days, setDays] = React.useState(() =>
    generateDaysFrom(initialStartDate, DAY_BATCH_SIZE * INITIAL_DAY_BATCHES)
  );
  const agendaData = React.useMemo(() => buildAgendaData(), []);
  const listRef = React.useRef(null);
  const scrollOffsetRef = React.useRef(0);
  const isPrependingRef = React.useRef(false);
  const isAppendingRef = React.useRef(false);

  const selectedEvents = React.useMemo(
    () => agendaData.events.filter((item) => item.dateKey === selectedDayKey),
    [agendaData.events, selectedDayKey]
  );
  const selectedMeetings = React.useMemo(
    () => agendaData.meetings.filter((item) => item.dateKey === selectedDayKey),
    [agendaData.meetings, selectedDayKey]
  );
  const selectedBirthdays = React.useMemo(
    () => agendaData.birthdays.filter((item) => item.dateKey === selectedDayKey),
    [agendaData.birthdays, selectedDayKey]
  );
  const summaryCount = selectedEvents.length + selectedMeetings.length + selectedBirthdays.length;

  const prependDays = () => {
    if (isPrependingRef.current || !days.length) return;

    isPrependingRef.current = true;
    const firstDay = new Date(days[0].key);
    const newStartDate = shiftDate(firstDay, -DAY_BATCH_SIZE);
    const newDays = generateDaysFrom(newStartDate, DAY_BATCH_SIZE);

    setDays((prevDays) => [...newDays, ...prevDays]);

    requestAnimationFrame(() => {
      listRef.current?.scrollToOffset({
        offset: scrollOffsetRef.current + (DAY_BATCH_SIZE * DAY_ITEM_WIDTH),
        animated: false,
      });
      isPrependingRef.current = false;
    });
  };

  const appendDays = () => {
    if (isAppendingRef.current || !days.length) return;

    isAppendingRef.current = true;
    const lastDay = new Date(days[days.length - 1].key);
    const newStartDate = shiftDate(lastDay, 1);
    const newDays = generateDaysFrom(newStartDate, DAY_BATCH_SIZE);

    setDays((prevDays) => [...prevDays, ...newDays]);

    requestAnimationFrame(() => {
      isAppendingRef.current = false;
    });
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={20} color={theme.colors.text} />
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>Agenda e Calendário</Text>
          <Text style={styles.headerSub}>Eventos da equipa e aniversários de colegas</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.monthCard}>
          <View>
            <Text style={styles.monthLabel}>{formatMonthLabel(selectedDayKey)}</Text>
            <Text style={styles.monthMeta}>
              {summaryCount > 0 ? `${summaryCount} itens para o dia selecionado` : 'Sem itens para o dia selecionado'}
            </Text>
          </View>
          <MaterialCommunityIcons name="calendar-month-outline" size={22} color={theme.colors.accent} />
        </View>

        <TouchableOpacity style={styles.createMeetingButton} onPress={() => navigation.navigate('CriarReuniao')} activeOpacity={0.9}>
          <MaterialCommunityIcons name="plus" size={18} color="#FFFFFF" />
          <Text style={styles.createMeetingButtonText}>Criar reunião</Text>
        </TouchableOpacity>

        <FlatList
          ref={listRef}
          horizontal
          data={days}
          keyExtractor={(day) => day.key}
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.daysRow}
          style={styles.daysScroller}
          initialNumToRender={10}
          maxToRenderPerBatch={12}
          windowSize={5}
          initialScrollIndex={DAY_BATCH_SIZE}
          getItemLayout={(_, index) => ({
            length: DAY_ITEM_WIDTH,
            offset: DAY_ITEM_WIDTH * index,
            index,
          })}
          onEndReached={appendDays}
          onEndReachedThreshold={0.4}
          onScroll={(event) => {
            const offsetX = event.nativeEvent.contentOffset.x;
            scrollOffsetRef.current = offsetX;

            if (offsetX < DAY_ITEM_WIDTH * 4) {
              prependDays();
            }
          }}
          scrollEventThrottle={16}
          renderItem={({ item: day }) => (
            <TouchableOpacity
              style={[styles.dayChip, day.key === selectedDayKey && styles.dayChipActive]}
              onPress={() => setSelectedDayKey(day.key)}
              activeOpacity={0.9}
            >
              <Text style={[styles.dayLabel, day.key === selectedDayKey && styles.dayLabelActive]}>{day.label}</Text>
              <Text style={[styles.dayDate, day.key === selectedDayKey && styles.dayDateActive]}>{day.date}</Text>
              <Text style={[styles.dayMonth, day.key === selectedDayKey && styles.dayMonthActive]}>{day.month}</Text>
            </TouchableOpacity>
          )}
        />

        <Text style={styles.sectionTitle}>Eventos do dia</Text>
        {selectedEvents.length === 0 && (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyText}>Nenhum evento para este dia.</Text>
          </View>
        )}
        {selectedEvents.map((event) => {
          const tone = getToneStyles(event.tone);
          return (
            <TouchableOpacity
              key={`${event.time}-${event.title}`}
              style={[styles.eventCard, { backgroundColor: tone.bg, borderColor: tone.border }]}
              activeOpacity={0.9}
              onPress={() => navigation.navigate('DetalheAgendaItem', {
                kind: 'event',
                title: event.title,
                subtitle: event.meta,
                time: event.time,
                dateLabel: formatSelectedDate(selectedDayKey),
                details: [
                  { label: 'Categoria', value: event.tone === 'warning' ? 'Prazo' : 'Agenda interna' },
                  { label: 'Canal', value: event.icon === 'briefcase-outline' ? 'Presencial' : 'Equipa' },
                ],
              })}
            >
              <View style={styles.eventTime}>
                <Text style={styles.eventTimeText}>{event.time}</Text>
              </View>
              <View style={[styles.eventIconWrap, { backgroundColor: theme.colors.surface }]}>
                <MaterialCommunityIcons name={event.icon} size={18} color={tone.color} />
              </View>
              <View style={styles.eventInfo}>
                <Text style={styles.eventTitle}>{event.title}</Text>
                <Text style={styles.eventMeta}>{event.meta}</Text>
              </View>
            </TouchableOpacity>
          );
        })}

        <Text style={styles.sectionTitle}>Reuniões</Text>
        {selectedMeetings.length === 0 && (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyText}>Nenhuma reunião agendada para este dia.</Text>
          </View>
        )}
        {selectedMeetings.map((meeting) => (
          <TouchableOpacity
            key={`${meeting.time}-${meeting.title}`}
            style={styles.meetingCard}
            activeOpacity={0.9}
            onPress={() => navigation.navigate('DetalheReuniao', {
              title: meeting.title,
              time: meeting.time,
              meta: meeting.meta,
              mode: meeting.title.includes('ERP') ? 'Online' : 'Presencial',
            })}
          >
            <View style={styles.meetingTime}>
              <Text style={styles.meetingTimeText}>{meeting.time}</Text>
            </View>
            <View style={styles.meetingIconWrap}>
              <MaterialCommunityIcons name={meeting.icon} size={18} color={theme.colors.accent} />
            </View>
            <View style={styles.meetingInfo}>
              <Text style={styles.meetingTitle}>{meeting.title}</Text>
              <Text style={styles.meetingMeta}>{meeting.meta}</Text>
            </View>
          </TouchableOpacity>
        ))}

        <Text style={styles.sectionTitle}>Aniversários dos colegas</Text>
        {selectedBirthdays.length === 0 && (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyText}>Nenhum aniversário neste dia.</Text>
          </View>
        )}
        {selectedBirthdays.map((person) => (
          <TouchableOpacity
            key={person.name}
            style={styles.birthdayCard}
            activeOpacity={0.9}
            onPress={() => navigation.navigate('DetalheAgendaItem', {
              kind: 'birthday',
              title: person.name,
              subtitle: `${person.dept} · ${person.when}`,
              time: 'Dia inteiro',
              dateLabel: formatSelectedDate(selectedDayKey),
              details: [
                { label: 'Departamento', value: person.dept },
                { label: 'Comemoracao', value: person.when },
              ],
            })}
          >
            <View style={styles.birthdayAvatar}>
              <Text style={styles.birthdayAvatarText}>{person.initials}</Text>
            </View>
            <View style={styles.birthdayInfo}>
              <Text style={styles.birthdayName}>{person.name}</Text>
              <Text style={styles.birthdayMeta}>{person.dept} · {person.when}</Text>
            </View>
            <View style={styles.birthdayAction}>
              <MaterialCommunityIcons name="cake-variant-outline" size={18} color={theme.colors.accent} />
            </View>
          </TouchableOpacity>
        ))}
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
  monthCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 16,
    marginBottom: 14,
  },
  monthLabel: {
    fontSize: 18,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    textTransform: 'capitalize',
  },
  monthMeta: {
    marginTop: 3,
    fontSize: 12,
    color: theme.colors.muted,
  },
  daysScroller: {
    marginBottom: 16,
  },
  createMeetingButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: theme.colors.accent,
    borderRadius: 14,
    paddingVertical: 12,
    marginBottom: 14,
  },
  createMeetingButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
  },
  daysRow: {
    flexDirection: 'row',
    gap: 8,
    paddingRight: 8,
  },
  dayChip: {
    width: 68,
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 8,
    paddingVertical: 8,
  },
  dayChipActive: {
    backgroundColor: theme.colors.infoDim,
    borderColor: theme.colors.blueBorder,
  },
  dayLabel: {
    fontSize: 11,
    color: theme.colors.muted,
  },
  dayLabelActive: {
    color: theme.colors.accent,
  },
  dayDate: {
    marginTop: 2,
    fontSize: 18,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
  },
  dayDateActive: {
    color: theme.colors.accent,
  },
  dayMonth: {
    marginTop: 1,
    fontSize: 10,
    color: theme.colors.muted,
  },
  dayMonthActive: {
    color: theme.colors.accent,
  },
  sectionTitle: {
    fontSize: 12,
    color: theme.colors.muted,
    marginBottom: 10,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  emptyCard: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 14,
    marginBottom: 10,
  },
  emptyText: {
    fontSize: 13,
    color: theme.colors.muted,
  },
  eventCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    borderWidth: 1,
    borderRadius: 16,
    padding: 14,
    marginBottom: 10,
  },
  eventTime: {
    width: 52,
  },
  eventTimeText: {
    fontSize: 13,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  eventIconWrap: {
    width: 38,
    height: 38,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  eventInfo: {
    flex: 1,
  },
  eventTitle: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  eventMeta: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
  meetingCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 14,
    marginBottom: 10,
  },
  meetingTime: {
    width: 52,
  },
  meetingTimeText: {
    fontSize: 13,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  meetingIconWrap: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  meetingInfo: {
    flex: 1,
  },
  meetingTitle: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  meetingMeta: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
  birthdayCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 14,
    marginBottom: 10,
  },
  birthdayAvatar: {
    width: 42,
    height: 42,
    borderRadius: 14,
    backgroundColor: theme.colors.amberDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  birthdayAvatarText: {
    fontSize: 13,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.amber,
  },
  birthdayInfo: {
    flex: 1,
  },
  birthdayName: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  birthdayMeta: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
  birthdayAction: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
