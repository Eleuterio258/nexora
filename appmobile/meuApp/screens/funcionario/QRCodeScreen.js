import React, { useEffect, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { CameraView, useCameraPermissions } from 'expo-camera';
import * as Location from 'expo-location';
import {
  ScrollView,
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { theme } from '../../src/theme';
import { RegistrationHistory } from '../../src/components';

const registrationHistory = [
  { title: 'Entrada principal', day: 'Hoje', time: '08:17', method: 'QR Code', success: true },
  { title: 'Saída almoço', day: 'Ontem', time: '12:31', method: 'QR Code', success: true },
  { title: 'Entrada tardia', day: 'Ontem', time: '13:42', method: 'QR Code', success: false },
];

export default function QRCodeScreen() {
  const [permission, requestPermission] = useCameraPermissions();
  const [scannedData, setScannedData] = useState('');
  const [locationState, setLocationState] = useState({
    loading: true,
    granted: false,
    distanceMeters: null,
    insideFence: false,
    coords: null,
    error: '',
  });

  const officeCoords = { latitude: -25.9653, longitude: 32.5892 };
  const allowedRadiusMeters = 75;

  const handleBarcodeScanned = ({ data }) => {
    if (scannedData) {
      return;
    }

    setScannedData(data);
  };

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
              distanceMeters: null,
              insideFence: false,
              coords: null,
              error: 'Permissão de localização negada.',
            });
          }
          return;
        }

        const current = await Location.getCurrentPositionAsync({
          accuracy: Location.Accuracy.Balanced,
        });

        const distanceMeters = Math.round(
          Location.getDistance(
            {
              latitude: current.coords.latitude,
              longitude: current.coords.longitude,
            },
            officeCoords
          )
        );

        if (mounted) {
          setLocationState({
            loading: false,
            granted: true,
            distanceMeters,
            insideFence: distanceMeters <= allowedRadiusMeters,
            coords: current.coords,
            error: '',
          });
        }
      } catch (error) {
        if (mounted) {
          setLocationState({
            loading: false,
            granted: false,
            distanceMeters: null,
            insideFence: false,
            coords: null,
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

  if (!permission) {
    return (
      <SafeAreaView style={styles.container} edges={['top']}>
        <View style={styles.centerState}>
          <Text style={styles.headerTitle}>QR Code</Text>
          <Text style={styles.headerSub}>A inicializar a câmara…</Text>
        </View>
      </SafeAreaView>
    );
  }

  if (!permission.granted) {
    return (
      <SafeAreaView style={styles.container} edges={['top']}>
        <View style={styles.centerState}>
          <MaterialCommunityIcons name="camera-off-outline" size={36} color={theme.colors.muted} />
          <Text style={styles.permissionTitle}>Permissão de câmara necessária</Text>
          <Text style={styles.permissionText}>Ative a câmara para ler o QR Code do painel de entrada.</Text>
          <TouchableOpacity style={styles.permissionButton} onPress={requestPermission} activeOpacity={0.9}>
            <Text style={styles.permissionButtonText}>Permitir câmara</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>QR Code</Text>
        <Text style={styles.headerSub}>Leia o painel da entrada</Text>
      </View>

      <ScrollView
        style={styles.content}
        contentContainerStyle={styles.body}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.cameraFrame}>
          <CameraView
            style={styles.camera}
            facing="back"
            barcodeScannerSettings={{ barcodeTypes: ['qr'] }}
            onBarcodeScanned={scannedData ? undefined : handleBarcodeScanned}
          />
          <View style={styles.scanOverlay}>
            <View style={styles.scanBox}>
              <View style={[styles.scanCorner, styles.scanCornerTopLeft]} />
              <View style={[styles.scanCorner, styles.scanCornerTopRight]} />
              <View style={[styles.scanCorner, styles.scanCornerBottomLeft]} />
              <View style={[styles.scanCorner, styles.scanCornerBottomRight]} />
            </View>
          </View>
        </View>

        <Text style={styles.statusValidation}>
          {scannedData ? 'QR Code lido com sucesso.' : 'Aponte a câmara para o QR Code do painel.'}
        </Text>

        {scannedData ? (
          <View style={styles.resultCard}>
            <Text style={styles.resultLabel}>Conteúdo lido</Text>
            <Text style={styles.resultText}>{scannedData}</Text>
            <TouchableOpacity style={styles.retryButton} onPress={() => setScannedData('')} activeOpacity={0.9}>
              <Text style={styles.retryButtonText}>Ler novamente</Text>
            </TouchableOpacity>
          </View>
        ) : null}

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
  content: {
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
    flexGrow: 1,
    width: '100%',
    alignItems: 'center',
    padding: 24,
    paddingBottom: 24,
    backgroundColor: theme.colors.surface,
    minHeight: '100%',
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
  permissionButton: {
    backgroundColor: theme.colors.accent,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  permissionButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
  },
  cameraFrame: {
    width: '100%',
    height: 280,
    borderRadius: 20,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: theme.colors.border,
    marginBottom: 16,
    backgroundColor: theme.colors.surface2,
  },
  camera: {
    flex: 1,
    backgroundColor: theme.colors.surface2,
  },
  scanOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scanBox: {
    width: 190,
    height: 190,
    borderRadius: 22,
    backgroundColor: 'rgba(15, 23, 42, 0.08)',
  },
  scanCorner: {
    position: 'absolute',
    width: 28,
    height: 28,
    borderColor: '#FFFFFF',
  },
  scanCornerTopLeft: {
    top: 0,
    left: 0,
    borderTopWidth: 4,
    borderLeftWidth: 4,
    borderTopLeftRadius: 18,
  },
  scanCornerTopRight: {
    top: 0,
    right: 0,
    borderTopWidth: 4,
    borderRightWidth: 4,
    borderTopRightRadius: 18,
  },
  scanCornerBottomLeft: {
    bottom: 0,
    left: 0,
    borderBottomWidth: 4,
    borderLeftWidth: 4,
    borderBottomLeftRadius: 18,
  },
  scanCornerBottomRight: {
    bottom: 0,
    right: 0,
    borderBottomWidth: 4,
    borderRightWidth: 4,
    borderBottomRightRadius: 18,
  },
  statusValidation: {
    fontSize: 13,
    color: theme.colors.muted,
    marginBottom: 16,
    textAlign: 'center',
  },
  resultCard: {
    width: '100%',
    backgroundColor: theme.colors.infoDim,
    borderWidth: 1,
    borderColor: theme.colors.blueBorder,
    borderRadius: 14,
    padding: 14,
    marginBottom: 16,
  },
  resultLabel: {
    fontSize: 11,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  resultText: {
    marginTop: 6,
    fontSize: 13,
    color: theme.colors.text,
  },
  retryButton: {
    alignSelf: 'flex-start',
    marginTop: 10,
    backgroundColor: theme.colors.accent,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  retryButtonText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: theme.fontWeight.semibold,
  },
  mapContainer: {
    width: '100%',
    height: 100,
    backgroundColor: theme.colors.surface2,
    borderRadius: 12,
    position: 'relative',
    marginBottom: 12,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  mapGrid: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    opacity: 0.3,
  },
  mapCircle: {
    position: 'absolute',
    top: '50%',
    left: '50%',
    transform: [{ translateX: -30 }, { translateY: -30 }],
    width: 60,
    height: 60,
    borderRadius: 30,
    borderWidth: 1.5,
    borderColor: theme.colors.blue,
    opacity: 0.4,
  },
  mapPin: {
    position: 'absolute',
    top: '45%',
    left: '50%',
    marginLeft: -12,
    marginTop: -14,
  },
  locationStatus: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 6,
  },
  dotInside: {
    backgroundColor: theme.colors.success,
  },
  dotOutside: {
    backgroundColor: theme.colors.error,
  },
  locationText: {
    fontSize: 11,
    color: theme.colors.text,
  },
  coordsText: {
    marginTop: 8,
    fontSize: 11,
    color: theme.colors.muted,
    textAlign: 'center',
  },
});
