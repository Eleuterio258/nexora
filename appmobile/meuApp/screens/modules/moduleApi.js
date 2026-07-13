import AsyncStorage from '@react-native-async-storage/async-storage';
import { API_BASE_URL } from '../../src/config';

export function extractEnvelopeData(payload) {
  return payload?.data || payload || null;
}

export async function fetchAuthJson(path) {
  const token = await AsyncStorage.getItem('auth.token');
  if (!token) {
    const error = new Error('Sessao expirada. Inicie sessao novamente.');
    error.code = 'NO_TOKEN';
    throw error;
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });

  let payload = null;
  try {
    payload = await response.json();
  } catch (_) {}

  if (!response.ok) {
    const message = payload?.error || payload?.message || `Erro HTTP ${response.status}`;
    const error = new Error(message);
    error.status = response.status;
    throw error;
  }

  return extractEnvelopeData(payload);
}

export function formatCurrency(value) {
  const amount = Number(value || 0);
  return `${amount.toLocaleString('pt-PT', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  })} MZN`;
}
