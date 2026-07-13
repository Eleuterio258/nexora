import React, { useEffect, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  StatusBar,
} from 'react-native';
import { theme } from '../../src/theme';
import { FuncionarioBottomNav } from '../../src/components';
import { loadStoredAccess } from '../../src/access';

const methods = [
  { icon: 'face-recognition', title: 'Biometria Facial', sub: 'Registo com\nreconhecimento facial', screen: 'Face' },
  { icon: 'access-point', title: 'NFC / Cartão', sub: 'Aproxime seu cartão\nou dispositivo', screen: 'NFC' },
  { icon: 'qrcode-scan', title: 'QR Code', sub: 'Escaneie o código\npara registar', screen: 'QRCode' },
];

export default function HomeFuncScreen({ navigation }) {
  const [, setModules] = useState([]);

  useEffect(() => {
    let mounted = true;
    loadStoredAccess()
      .then(({ modules: storedModules }) => {
        if (mounted) setModules(storedModules);
      })
      .catch(() => {
        if (mounted) setModules([]);
      });
    return () => {
      mounted = false;
    };
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>AL</Text>
        </View>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>Amelia Langa</Text>
          <Text style={styles.headerSub}>Financeira · Turno 08h-17h</Text>
        </View>
        <TouchableOpacity
          style={styles.bellWrap}
          onPress={() => navigation.navigate('Notificacoes')}
          activeOpacity={0.85}
        >
          <MaterialCommunityIcons name="bell-outline" size={26} color={theme.colors.text} />
          <View style={styles.bellDot} />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.heroCard}>
          <View style={styles.heroTopRow}>
            <View style={styles.heroCheck}>
              <MaterialCommunityIcons name="check-bold" size={32} color={theme.colors.accent} />
            </View>
            <View style={styles.heroTitleWrap}>
              <Text style={styles.heroTitle}>Presença validada</Text>
              <View style={styles.heroBadge}>
                <View style={styles.heroBadgeDot} />
                <Text style={styles.heroBadgeText}>Activo</Text>
              </View>
            </View>
          </View>

          <View style={styles.heroStatsRow}>
            <View style={styles.heroStatItem}>
              <View style={styles.heroStatIcon}>
                <MaterialCommunityIcons name="clock-outline" size={18} color={theme.colors.accent} />
              </View>
              <Text style={styles.heroStatValue}>08:17</Text>
              <Text style={styles.heroStatLabel}>Entrada</Text>
            </View>
            <View style={styles.heroDivider} />
            <View style={styles.heroStatItem}>
              <View style={styles.heroStatIcon}>
                <MaterialCommunityIcons name="timer-sand" size={18} color={theme.colors.accent} />
              </View>
              <Text style={styles.heroStatValue}>17:00</Text>
              <Text style={styles.heroStatLabel}>Saída</Text>
            </View>
            <View style={styles.heroDivider} />
            <View style={styles.heroStatItem}>
              <View style={styles.heroStatIcon}>
                <MaterialCommunityIcons name="clipboard-text-outline" size={18} color={theme.colors.accent} />
              </View>
              <Text style={styles.heroStatValue}>1</Text>
              <Text style={styles.heroStatLabel}>Pendência</Text>
            </View>
          </View>
        </View>

        <View style={styles.quickRow}>
          <TouchableOpacity
            style={styles.quickCard}
            onPress={() => navigation.navigate('Notificacoes')}
            activeOpacity={0.9}
          >
            <View style={styles.quickIconWrap}>
              <MaterialCommunityIcons name="bell-outline" size={20} color={theme.colors.accent} />
            </View>
            <View style={styles.quickInfo}>
              <Text style={styles.quickTitle}>Notificações</Text>
              <Text style={styles.quickSub}>Veja suas notificações</Text>
            </View>
            <MaterialCommunityIcons name="chevron-right" size={20} color={theme.colors.muted} />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.quickCard}
            onPress={() => navigation.navigate('Chat')}
            activeOpacity={0.9}
          >
            <View style={styles.quickIconWrap}>
              <MaterialCommunityIcons name="message-text-outline" size={20} color={theme.colors.accent} />
            </View>
            <View style={styles.quickInfo}>
              <Text style={styles.quickTitle}>Chat</Text>
              <Text style={styles.quickSub}>Fale com sua equipe</Text>
            </View>
            <MaterialCommunityIcons name="chevron-right" size={20} color={theme.colors.muted} />
          </TouchableOpacity>
        </View>

        <Text style={styles.sectionTitle}>Método de registo</Text>
        <Text style={styles.sectionSub}>Escolha o método que deseja utilizar</Text>

        <View style={styles.methodsRow}>
          {methods.map((method) => (
            <TouchableOpacity
              key={method.title}
              style={styles.methodCard}
              onPress={() => navigation.navigate(method.screen)}
              activeOpacity={0.9}
            >
              <View style={styles.methodIconWrap}>
                <MaterialCommunityIcons name={method.icon} size={32} color={theme.colors.accent} />
              </View>
              <Text style={styles.methodTitle}>{method.title}</Text>
              <Text style={styles.methodSub}>{method.sub}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </ScrollView>

      <FuncionarioBottomNav navigation={navigation} activeKey="home" />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 14,
    backgroundColor: theme.colors.background,
  },
  avatar: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: theme.colors.accent,
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    fontSize: 18,
    fontWeight: theme.fontWeight.bold,
    color: '#FFFFFF',
  },
  headerInfo: {
    flex: 1,
    marginLeft: 12,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
  },
  headerSub: {
    fontSize: 13,
    color: theme.colors.muted,
    marginTop: 2,
  },
  bellWrap: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  bellDot: {
    position: 'absolute',
    top: 6,
    right: 6,
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: theme.colors.accent,
    borderWidth: 2,
    borderColor: theme.colors.background,
  },
  body: {
    padding: 16,
    paddingBottom: 24,
  },
  heroCard: {
    backgroundColor: theme.colors.accent,
    borderRadius: 20,
    padding: 20,
    marginBottom: 18,
  },
  heroTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  heroCheck: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroTitleWrap: {
    flex: 1,
  },
  heroTitle: {
    fontSize: 22,
    fontWeight: theme.fontWeight.bold,
    color: '#FFFFFF',
  },
  heroBadge: {
    alignSelf: 'flex-start',
    marginTop: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.success,
  },
  heroBadgeDot: {
    width: 7,
    height: 7,
    borderRadius: 4,
    backgroundColor: '#FFFFFF',
  },
  heroBadgeText: {
    fontSize: 12,
    fontWeight: theme.fontWeight.semibold,
    color: '#FFFFFF',
  },
  heroStatsRow: {
    flexDirection: 'row',
    marginTop: 20,
    backgroundColor: 'rgba(255,255,255,0.10)',
    borderRadius: 14,
    paddingVertical: 14,
    paddingHorizontal: 8,
    alignItems: 'center',
  },
  heroStatItem: {
    flex: 1,
    alignItems: 'center',
  },
  heroStatIcon: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  heroStatValue: {
    fontSize: 20,
    fontWeight: theme.fontWeight.bold,
    color: '#FFFFFF',
  },
  heroStatLabel: {
    marginTop: 2,
    fontSize: 12,
    color: 'rgba(255,255,255,0.85)',
  },
  heroDivider: {
    width: 1,
    height: 50,
    backgroundColor: 'rgba(255,255,255,0.25)',
  },
  quickRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 22,
  },
  quickCard: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: theme.colors.surface,
    borderRadius: 14,
    padding: 12,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  quickIconWrap: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  quickInfo: {
    flex: 1,
  },
  quickTitle: {
    fontSize: 14,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
  },
  quickSub: {
    marginTop: 2,
    fontSize: 11,
    color: theme.colors.muted,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
  },
  sectionSub: {
    marginTop: 4,
    marginBottom: 14,
    fontSize: 13,
    color: theme.colors.muted,
  },
  methodsRow: {
    flexDirection: 'row',
    gap: 10,
  },
  methodCard: {
    flex: 1,
    backgroundColor: theme.colors.surface,
    borderRadius: 14,
    paddingVertical: 18,
    paddingHorizontal: 10,
    borderWidth: 1,
    borderColor: theme.colors.border,
    alignItems: 'center',
  },
  methodIconWrap: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  methodTitle: {
    fontSize: 13,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
    textAlign: 'center',
  },
  methodSub: {
    marginTop: 4,
    fontSize: 11,
    color: theme.colors.muted,
    textAlign: 'center',
    lineHeight: 15,
  },
});
