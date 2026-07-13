/**
 * FaceScreen — Biometria Facial (REST)
 *
 * Fluxo:
 *  1. Carrega user_id e token do AsyncStorage
 *  2. Pede permissão de câmara
 *  3. Captura frames a cada FRAME_INTERVAL ms
 *  4. Envia base64 para POST /api/v1/biometric/verify
 *  5. Após CONSECUTIVE_HITS matches consecutivos → POST /api/v1/clock/register
 *  6. Navega para SuccessScreen
 */

import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  Animated,
  Easing,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { theme } from '../../src/theme';
import { API_BASE_URL } from '../../src/config';

const CONSECUTIVE_HITS = 3;
const FRAME_INTERVAL = 1200; // ms entre capturas (REST é mais lento que WS)
const SESSION_TIMEOUT = 45_000;

const PHASE = {
  LOADING:     'loading',
  PERMISSION:  'permission',
  NO_PERM:     'no_permission',
  CONNECTING:  'connecting',
  SCANNING:    'scanning',
  LIVENESS:    'liveness',
  SUCCESS:     'success',
  ERROR:       'error',
  TIMEOUT:     'timeout',
};

const PHASE_META = {
  [PHASE.LOADING]:    { label: 'A carregar…',                   color: theme.colors.muted,   icon: 'loading' },
  [PHASE.CONNECTING]: { label: 'A iniciar câmara…',             color: theme.colors.muted,   icon: 'wifi' },
  [PHASE.SCANNING]:   { label: 'Posicione o rosto no círculo',  color: theme.colors.blue,    icon: 'face-recognition' },
  [PHASE.LIVENESS]:   { label: 'A confirmar identidade…',       color: theme.colors.amber,   icon: 'shield-check-outline' },
  [PHASE.SUCCESS]:    { label: 'Identidade confirmada!',         color: theme.colors.success, icon: 'check-circle' },
  [PHASE.ERROR]:      { label: 'Erro de verificação',            color: theme.colors.error,   icon: 'alert-circle-outline' },
  [PHASE.TIMEOUT]:    { label: 'Tempo esgotado',                 color: theme.colors.warning, icon: 'clock-alert-outline' },
  [PHASE.NO_PERM]:    { label: 'Permissão de câmara negada',    color: theme.colors.error,   icon: 'camera-off-outline' },
};

export default function FaceScreen({ navigation, route }) {
  const recordType = route?.params?.record_type ?? 'ENTRY';

  const [permission, requestPermission] = useCameraPermissions();
  const [phase, setPhase]       = useState(PHASE.LOADING);
  const [statusMsg, setStatusMsg] = useState('');
  const [hitCount, setHitCount] = useState(0);
  const [cameraReady, setCameraReady] = useState(false);

  const cameraRef      = useRef(null);
  const cameraReadyRef = useRef(false);
  const frameTimerRef  = useRef(null);
  const sessionTimer   = useRef(null);
  const consecutiveRef = useRef(0);
  const activeRef      = useRef(true);
  const sendingRef     = useRef(false); // evita envios sobrepostos
  const requestedPermRef = useRef(false);

  const authRef = useRef({ token: null, userId: null, employeeCode: null });

  const pulseAnim = useRef(new Animated.Value(1)).current;

  // ─── Animação ────────────────────────────────────────────────────────────────
  useEffect(() => {
    if (phase === PHASE.SCANNING || phase === PHASE.LIVENESS) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, { toValue: 1.06, duration: 700, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
          Animated.timing(pulseAnim, { toValue: 1.00, duration: 700, easing: Easing.inOut(Easing.ease), useNativeDriver: true }),
        ])
      ).start();
    } else {
      pulseAnim.stopAnimation();
      pulseAnim.setValue(1);
    }
  }, [phase]);

  // ─── Carregar auth do storage ─────────────────────────────────────────────
  useEffect(() => {
    AsyncStorage.multiGet(['auth.token', 'auth.user']).then((pairs) => {
      const token = pairs[0][1] || '';
      const user  = JSON.parse(pairs[1][1] || '{}');
      authRef.current = {
        token,
        userId: user?.id || null,
        employeeCode: user?.username || null,
      };
      if (!token || !user?.id) {
        setPhase(PHASE.ERROR);
        setStatusMsg('Sessão expirada. Faça login novamente.');
      } else {
        setPhase(PHASE.PERMISSION);
      }
    });

    return () => {
      activeRef.current = false;
      _cleanup();
    };
  }, []);

  // ─── Permissão ────────────────────────────────────────────────────────────
  useEffect(() => {
    if (phase !== PHASE.PERMISSION) return;
    if (!permission) return;
    if (!permission.granted) {
      if (!requestedPermRef.current && permission.canAskAgain) {
        requestedPermRef.current = true;
        requestPermission();
      } else {
        setPhase(PHASE.NO_PERM);
      }
      return;
    }
    setPhase(PHASE.CONNECTING);
  }, [permission, phase, requestPermission]);

  // ─── Iniciar sessão quando câmara estiver pronta ─────────────────────────
  useEffect(() => {
    if (phase === PHASE.CONNECTING && cameraReady && activeRef.current) {
      _startSession();
    }
  }, [cameraReady, phase]);

  const _startSession = useCallback(() => {
    if (!activeRef.current) return;
    consecutiveRef.current = 0;
    setHitCount(0);
    setPhase(PHASE.SCANNING);

    sessionTimer.current = setTimeout(() => {
      if (activeRef.current) {
        _cleanup();
        setPhase(PHASE.TIMEOUT);
      }
    }, SESSION_TIMEOUT);

    frameTimerRef.current = setInterval(_captureAndVerify, FRAME_INTERVAL);
  }, []);

  const _cleanup = () => {
    if (frameTimerRef.current) { clearInterval(frameTimerRef.current); frameTimerRef.current = null; }
    if (sessionTimer.current)  { clearTimeout(sessionTimer.current);   sessionTimer.current  = null; }
  };

  // ─── Captura + verificação ────────────────────────────────────────────────
  const _captureAndVerify = async () => {
    const cam = cameraRef.current;
    if (!cam || !activeRef.current || !cameraReadyRef.current || sendingRef.current) return;
    const { token, userId } = authRef.current;
    if (!token || !userId) return;

    sendingRef.current = true;
    try {
      const photo = await cam.takePictureAsync({
        quality: 0.5,
        base64: true,
        skipProcessing: true,
        exif: false,
      });
      if (!photo?.base64 || !activeRef.current) return;

      const res = await fetch(`${API_BASE_URL}/biometric/verify`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ user_id: userId, image_base64: photo.base64 }),
      });

      if (!activeRef.current) return;

      if (!res.ok) {
        // Não interromper a sessão — aguardar próximo frame
        return;
      }

      const data = await res.json();

      if (data.match) {
        consecutiveRef.current += 1;
        const hits = consecutiveRef.current;
        setHitCount(hits);
        if (hits === 1) setPhase(PHASE.LIVENESS);
        if (hits >= CONSECUTIVE_HITS) {
          await _onConfirmed(data);
        }
      } else {
        // Face não reconhecida — reset progressivo
        if (consecutiveRef.current > 0) {
          consecutiveRef.current = 0;
          setHitCount(0);
          setPhase(PHASE.SCANNING);
        }
      }
    } catch (_) {
      // Erro de rede — ignorar e tentar no próximo intervalo
    } finally {
      sendingRef.current = false;
    }
  };

  // ─── Confirmação + registo de ponto ──────────────────────────────────────
  const _onConfirmed = async (verifyData) => {
    activeRef.current = false;
    _cleanup();
    setPhase(PHASE.SUCCESS);
    await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

    const { token, userId } = authRef.current;
    try {
      await fetch(`${API_BASE_URL}/clock/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          user_id: userId,
          event_type: recordType,
          source: 'MOBILE_APP',
          recorded_at: new Date().toISOString(),
          idempotency_key: `face-${userId}-${Date.now()}`,
          confidence_score: verifyData.confidence_score ?? null,
          liveness_score:   verifyData.liveness_score   ?? null,
        }),
      });
    } catch (_) {
      // Registo falhou — mostrar sucesso na UI mas avisar
    }

    setTimeout(() => {
      navigation.replace('Success', {
        employee_id:   userId,
        employee_name: authRef.current.employeeCode ?? 'Funcionário',
        employee_code: authRef.current.employeeCode ?? '',
        confidence:    verifyData.confidence_score ?? 0,
        record_type:   recordType,
        method:        'facial',
        occurred_at:   new Date().toISOString(),
      });
    }, 800);
  };

  // ─── Retry ────────────────────────────────────────────────────────────────
  const handleRetry = () => {
    activeRef.current = true;
    sendingRef.current = false;
    consecutiveRef.current = 0;
    setHitCount(0);
    setStatusMsg('');
    setPhase(cameraReadyRef.current ? PHASE.CONNECTING : PHASE.PERMISSION);
  };

  // ─── Render ───────────────────────────────────────────────────────────────
  const meta       = PHASE_META[phase] ?? PHASE_META[PHASE.SCANNING];
  const ringColor  = meta.color;
  const showCamera = permission?.granted && phase !== PHASE.SUCCESS && phase !== PHASE.LOADING;
  const showRetry  = phase === PHASE.ERROR || phase === PHASE.TIMEOUT;
  const progressPct = Math.min(1, hitCount / CONSECUTIVE_HITS);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Biometria Facial</Text>
        <Text style={styles.headerSub}>
          {recordType === 'ENTRY' ? 'Registo de entrada' : 'Registo de saída'}
        </Text>
      </View>

      <View style={styles.body}>
        <Animated.View style={[
          styles.ringOuter,
          { borderColor: ringColor, transform: [{ scale: pulseAnim }] },
          phase === PHASE.SUCCESS && styles.ringSuccess,
        ]}>
          {showCamera ? (
            <CameraView
              ref={cameraRef}
              style={styles.camera}
              facing="front"
              autofocus="on"
              active={showCamera}
              onCameraReady={() => {
                cameraReadyRef.current = true;
                setCameraReady(true);
              }}
              onMountError={(err) => {
                cameraReadyRef.current = false;
                setCameraReady(false);
                setPhase(PHASE.ERROR);
                setStatusMsg(err?.message ?? 'Erro ao inicializar câmara.');
              }}
            />
          ) : (
            <View style={styles.cameraPlaceholder} />
          )}

          {phase === PHASE.SUCCESS && (
            <View style={styles.overlay}>
              <MaterialCommunityIcons name="check-circle" size={56} color={theme.colors.success} />
            </View>
          )}
          {(phase === PHASE.ERROR || phase === PHASE.TIMEOUT || phase === PHASE.NO_PERM) && (
            <View style={styles.overlay}>
              <MaterialCommunityIcons name={meta.icon} size={56} color={meta.color} />
            </View>
          )}
        </Animated.View>

        <View style={styles.progressWrap}>
          <View style={styles.progressTrack}>
            <View style={[
              styles.progressFill,
              { width: `${Math.round(progressPct * 100)}%`, backgroundColor: ringColor },
            ]} />
          </View>
          {phase === PHASE.LIVENESS && (
            <Text style={[styles.progressLabel, { color: ringColor }]}>
              {hitCount}/{CONSECUTIVE_HITS} confirmações
            </Text>
          )}
        </View>

        <View style={styles.statusRow}>
          <MaterialCommunityIcons name={meta.icon} size={16} color={meta.color} />
          <Text style={[styles.statusText, { color: meta.color }]}>{meta.label}</Text>
        </View>

        {statusMsg ? <Text style={styles.errorDetail}>{statusMsg}</Text> : null}

        {phase === PHASE.NO_PERM && (
          <TouchableOpacity style={styles.btnPrimary} onPress={requestPermission}>
            <Text style={styles.btnPrimaryText}>Permitir câmara</Text>
          </TouchableOpacity>
        )}

        {(phase === PHASE.SCANNING || phase === PHASE.LIVENESS) && (
          <Text style={styles.livenessHint}>
            {phase === PHASE.LIVENESS ? 'Mantenha o rosto visível…' : 'Liveness detection activa'}
          </Text>
        )}

        {showRetry && (
          <TouchableOpacity style={[styles.btnOutline, { borderColor: ringColor }]} onPress={handleRetry}>
            <Text style={[styles.btnOutlineText, { color: ringColor }]}>Tentar novamente</Text>
          </TouchableOpacity>
        )}

        <TouchableOpacity
          style={styles.btnCancel}
          onPress={() => { activeRef.current = false; _cleanup(); navigation.goBack(); }}
        >
          <Text style={styles.btnCancelText}>Cancelar</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const RING = 220;
const styles = StyleSheet.create({
  container:       { flex: 1, backgroundColor: theme.colors.surface },
  header:          { paddingHorizontal: 20, paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: theme.colors.border },
  headerTitle:     { fontSize: 16, fontWeight: theme.fontWeight.semibold, color: theme.colors.text },
  headerSub:       { fontSize: 12, color: theme.colors.muted, marginTop: 2 },
  body:            { flex: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 24, gap: 16 },
  ringOuter:       { width: RING, height: RING, borderRadius: RING / 2, borderWidth: 3, overflow: 'hidden', backgroundColor: theme.colors.surface2 },
  ringSuccess:     { borderColor: theme.colors.success },
  camera:          { width: '100%', height: '100%' },
  cameraPlaceholder: { width: '100%', height: '100%', backgroundColor: theme.colors.hint },
  overlay:         { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(255,255,255,0.85)', justifyContent: 'center', alignItems: 'center' },
  progressWrap:    { width: '80%', alignItems: 'center', gap: 4 },
  progressTrack:   { width: '100%', height: 4, backgroundColor: theme.colors.border, borderRadius: 2, overflow: 'hidden' },
  progressFill:    { height: '100%', borderRadius: 2 },
  progressLabel:   { fontSize: 11, fontWeight: theme.fontWeight.medium },
  statusRow:       { flexDirection: 'row', alignItems: 'center', gap: 6 },
  statusText:      { fontSize: 14, fontWeight: theme.fontWeight.medium },
  errorDetail:     { fontSize: 12, color: theme.colors.muted, textAlign: 'center', paddingHorizontal: 16 },
  livenessHint:    { fontSize: 11, color: theme.colors.muted },
  btnOutline:      { width: '80%', paddingVertical: 12, borderRadius: 12, borderWidth: 1.5, alignItems: 'center', marginTop: 4 },
  btnOutlineText:  { fontSize: 14, fontWeight: theme.fontWeight.medium },
  btnPrimary:      { width: '80%', paddingVertical: 12, borderRadius: 12, alignItems: 'center', backgroundColor: theme.colors.accent },
  btnPrimaryText:  { fontSize: 14, fontWeight: theme.fontWeight.semibold, color: '#FFFFFF' },
  btnCancel:       { paddingVertical: 10, paddingHorizontal: 24 },
  btnCancelText:   { fontSize: 14, color: theme.colors.muted },
});
