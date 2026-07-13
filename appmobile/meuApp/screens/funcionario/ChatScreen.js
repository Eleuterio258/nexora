import React, { useMemo, useState } from 'react';
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
import { FuncionarioBottomNav } from '../../src/components';

const conversations = [
  { name: 'Helena Cossa', type: 'Privado', lastMessage: 'Confirma a troca do turno?', time: '09:42', unread: 2, icon: 'account-outline', role: 'Financeira' },
  { name: 'Gestor Financeira', type: 'Privado', lastMessage: 'Recebi a tua justificação.', time: '08:15', unread: 0, icon: 'briefcase-account-outline', role: 'Gestor direto' },
  { name: 'Grupo Financeira', type: 'Grupo', lastMessage: 'Reunião antecipada para as 14h.', time: 'Ontem', unread: 5, icon: 'account-group-outline', members: 14 },
  { name: 'Turno da Manhã', type: 'Grupo', lastMessage: 'Checklist partilhada no grupo.', time: 'Ontem', unread: 0, icon: 'clipboard-list-outline', members: 9 },
];

export default function ChatScreen({ navigation }) {
  const [activeTab, setActiveTab] = useState('Todos');
  const [search, setSearch] = useState('');

  const filteredConversations = useMemo(() => {
    return conversations.filter((conversation) => {
      const matchesTab = activeTab === 'Todos' || conversation.type === activeTab;
      const matchesSearch = !search || conversation.name.toLowerCase().includes(search.toLowerCase());
      return matchesTab && matchesSearch;
    });
  }, [activeTab, search]);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>Chat</Text>
          <Text style={styles.headerSub}>Conversas privadas e grupos</Text>
        </View>
        <TouchableOpacity style={styles.newChatButton} activeOpacity={0.85}>
          <MaterialCommunityIcons name="pencil-outline" size={18} color={theme.colors.accent} />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <TextInput
          style={styles.searchInput}
          value={search}
          onChangeText={setSearch}
          placeholder="Pesquisar conversa"
          placeholderTextColor={theme.colors.muted}
        />

        <View style={styles.tabRow}>
          {['Todos', 'Privado', 'Grupo'].map((tab) => {
            const isActive = tab === activeTab;

            return (
              <TouchableOpacity
                key={tab}
                style={[styles.tabChip, isActive && styles.tabChipActive]}
                onPress={() => setActiveTab(tab)}
                activeOpacity={0.9}
              >
                <Text style={[styles.tabChipText, isActive && styles.tabChipTextActive]}>{tab}</Text>
              </TouchableOpacity>
            );
          })}
        </View>

        {filteredConversations.map((conversation) => (
          <TouchableOpacity
            key={conversation.name}
            style={styles.chatCard}
            activeOpacity={0.9}
            onPress={() => navigation.navigate(
              conversation.type === 'Privado' ? 'ChatPrivado' : 'ChatGrupo',
              conversation.type === 'Privado'
                ? { name: conversation.name, role: conversation.role }
                : { name: conversation.name, members: conversation.members }
            )}
          >
            <View style={styles.chatAvatar}>
              <MaterialCommunityIcons name={conversation.icon} size={18} color={theme.colors.accent} />
            </View>
            <View style={styles.chatInfo}>
              <View style={styles.chatHead}>
                <Text style={styles.chatName}>{conversation.name}</Text>
                <Text style={styles.chatTime}>{conversation.time}</Text>
              </View>
              <Text style={styles.chatType}>{conversation.type}</Text>
              <Text style={styles.chatMessage}>{conversation.lastMessage}</Text>
            </View>
            {conversation.unread ? (
              <View style={styles.chatBadge}>
                <Text style={styles.chatBadgeText}>{conversation.unread}</Text>
              </View>
            ) : null}
          </TouchableOpacity>
        ))}
      </ScrollView>

      <FuncionarioBottomNav navigation={navigation} activeKey="chat" />
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
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 14,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  headerInfo: {
    flex: 1,
  },
  newChatButton: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: theme.colors.infoDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
    alignItems: 'center',
    justifyContent: 'center',
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
  searchInput: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 14,
    color: theme.colors.text,
    marginBottom: 12,
  },
  tabRow: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 12,
  },
  tabChip: {
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 999,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border2,
  },
  tabChipActive: {
    backgroundColor: theme.colors.infoDim,
    borderColor: theme.colors.blueBorder,
  },
  tabChipText: {
    fontSize: 13,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  tabChipTextActive: {
    color: theme.colors.accent,
  },
  chatCard: {
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
  chatAvatar: {
    width: 42,
    height: 42,
    borderRadius: 14,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  chatInfo: {
    flex: 1,
  },
  chatHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 10,
  },
  chatName: {
    flex: 1,
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  chatTime: {
    fontSize: 11,
    color: theme.colors.muted,
  },
  chatType: {
    marginTop: 2,
    fontSize: 11,
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.medium,
  },
  chatMessage: {
    marginTop: 4,
    fontSize: 12,
    color: theme.colors.muted,
  },
  chatBadge: {
    minWidth: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: theme.colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 6,
  },
  chatBadgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: theme.fontWeight.semibold,
  },
});
