import React, { useEffect, useRef, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { CameraView, useCameraPermissions } from 'expo-camera';
import * as Location from 'expo-location';
import {
  Image,
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
} from 'react-native';
import { theme } from '../../src/theme';
import { RegistrationHistory } from '../../src/components';

const registrationHistory = [
  { title: 'Presença capturada', day: 'Hoje', time: '08:21', method: 'Selfie + GPS', success: true },
  { title: 'Validação remota', day: 'Ontem', time: '08:05', method: 'Selfie + GPS', success: true },
  { title: 'Tentativa pendente', day: '02 Abr', time: '08:12', method: 'Selfie + GPS', success: false },
];

export default function SelfieGPSScreen() {
  const cameraRef = useRef(null);
  const [cameraPermission, requestCameraPermission] = useCameraPermissions();
  const [capturedPhotoUri, setCapturedPhotoUri] = useState('');
  const [timestamp, setTimestamp] = useState('');
  const [isCapturing, setIsCapturing] = useState(false);
  const [locationState, setLocationState] = useState({
    loading: true,
    granted: false,
    coords: null,
    accuracy: null,
    error: '',
  });

  useEffect(() => {
    let mounted = true;

    const loadLocation = async () => {
      try {
        const { status } = await Location.requestForegroundPermissionsAsync();

        if (status !== 'granted') {
          if (mounted) {
            setLocationState({
              loading: false,
              granted: false,
              coords: null,
              accuracy: null,
              error: 'Permissão de localização negada.',
            });
          }
          return;
        }

        const current = await Location.getCurrentPositionAsync({
          accuracy: Location.Accuracy.Balanced,
        });

        if (mounted) {
          setLocationState({
            loading: false,
            granted: true,
            coords: current.coords,
            accuracy: current.coords.accuracy,
            error: '',
          });
        }
      } catch (error) {
        if (mounted) {
          setLocationState({
            loading: false,
            granted: false,
            coords: null,
            accuracy: null,
            error: 'Não foi possível obter a localização.',
          });
        }
      }
    };

    loadLocation();

    return () => {
      mounted = false;
    };
  }, []);

  const handleCapture = async () => {
    if (!cameraRef.current || isCapturing) {
      return;
    }

    try {
      setIsCapturing(true);
      const photo = await cameraRef.current.takePictureAsync({
        quality: 0.7,
        skipProcessing: true,
      });

      setCapturedPhotoUri(photo.uri);
      setTimestamp(
        new Intl.DateTimeFormat('pt-PT', {
          day: '2-digit',
          month: 'short',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
        }).format(new Date())
      );
    } finally {
      setIsCapturing(false);
    }
  };

  if (!cameraPermission) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.centerState}>
          <Text style={styles.headerTitle}>Selfie + GPS</Text>
          <Text style={styles.headerSub}>A inicializar a câmara…</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (!cameraPermission.granted) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.centerState}>
          <MaterialCommunityIcons name="camera-off-outline" size={36} color={theme.colors.muted} />
          <Text style={styles.permissionTitle}>Permissão de câmara necessária</Text>
          <Text style={styles.permissionText}>Ative a câmara para capturar a selfie de presença.</Text>
          <TouchableOpacity style={styles.buttonSuccess} onPress={requestCameraPermission} activeOpacity={0.9}>
            <Text style={styles.buttonSuccessText}>Permitir câmara</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Selfie + GPS</Text>
        <Text style={styles.headerSub}>Prova de presença</Text>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.selfieBox}>
          {capturedPhotoUri ? (
            <Image source={{ uri: capturedPhotoUri }} style={styles.selfiePreview} />
          ) : (
            <CameraView ref={cameraRef} style={styles.camera} facing="front" />
          )}
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Localização capturada</Text>
          <Text style={styles.cardSub}>
            {locationState.loading
              ? 'A obter localização…'
              : locationState.error
                ? locationState.error
                : `${locationState.coords.latitude.toFixed(5)}, ${locationState.coords.longitude.toFixed(5)} · ±${Math.round(locationState.accuracy || 0)}m`}
          </Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Timestamp</Text>
          <Text style={styles.cardSub}>{timestamp || 'Ainda não capturado'}</Text>
        </View>

        <TouchableOpacity style={styles.buttonSuccess} onPress={capturedPhotoUri ? () => {} : handleCapture} activeOpacity={0.9}>
          <Text style={styles.buttonSuccessText}>{capturedPhotoUri ? 'Confirmar presença' : 'Capturar selfie'}</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.buttonOutline} onPress={() => {
          setCapturedPhotoUri('');
          setTimestamp('');
        }} activeOpacity={0.9}>
          <Text style={styles.buttonOutlineText}>Tirar nova foto</Text>
        </TouchableOpacity>

        <RegistrationHistory items={registrationHistory} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.surface,
  },
  centerState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  header: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
  },
  headerSub: {
    fontSize: 12,
    color: theme.colors.muted,
    marginTop: 2,
  },
  body: {
    padding: 16,
    paddingBottom: 24,
  },
  permissionTitle: {
    marginTop: 14,
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  permissionText: {
    marginTop: 6,
    fontSize: 13,
    color: theme.colors.muted,
    textAlign: 'center',
    lineHeight: 19,
    marginBottom: 16,
  },
  selfieBox: {
    width: '100%',
    height: 260,
    backgroundColor: theme.colors.surface2,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderStyle: 'dashed',
    marginBottom: 16,
    overflow: 'hidden',
  },
  camera: {
    flex: 1,
  },
  selfiePreview: {
    width: '100%',
    height: '100%',
  },
  card: {
    backgroundColor: theme.colors.surface2,
    borderRadius: 12,
    padding: 12,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  cardTitle: {
    fontSize: 13,
    fontWeight: theme.fontWeight.medium,
    color: theme.colors.text,
    marginBottom: 4,
  },
  cardSub: {
    fontSize: 11,
    color: theme.colors.muted,
  },
  buttonSuccess: {
    backgroundColor: theme.colors.success,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 16,
  },
  buttonSuccessText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: theme.fontWeight.medium,
  },
  buttonOutline: {
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonOutlineText: {
    color: theme.colors.text,
    fontSize: 14,
  },
});
