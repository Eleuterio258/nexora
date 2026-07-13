import React, { useMemo, useState } from 'react';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  Modal,
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

const requestTypes = ['Férias anuais', 'Dispensa', 'Licença pessoal'];

export default function SolicitarFeriasFormScreen({ navigation, route }) {
  const [selectedType, setSelectedType] = useState(route?.params?.requestType || requestTypes[0]);
  const [isTypeOpen, setIsTypeOpen] = useState(false);
  const [startDate, setStartDate] = useState('2026-06-12');
  const [endDate, setEndDate] = useState('2026-06-22');
  const [reason, setReason] = useState(route?.params?.reason || 'Pedido submetido com antecedência e cobertura interna alinhada.');
  const [attachmentName, setAttachmentName] = useState('');
  const [pickerVisible, setPickerVisible] = useState(false);
  const [pickerField, setPickerField] = useState('start');
  const [pickerDate, setPickerDate] = useState(new Date('2026-06-12'));

  const requestedDays = useMemo(() => {
    const start = new Date(startDate);
    const end = new Date(endDate);

    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || end < start) {
      return 0;
    }

    return Math.floor((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1;
  }, [endDate, startDate]);

  const formatDate = (date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };

  const formatDateLabel = (value) => {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return value;
    }

    return new Intl.DateTimeFormat('pt-PT', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    }).format(date);
  };

  const shiftPickerDate = (days) => {
    const next = new Date(pickerDate);
    next.setDate(next.getDate() + days);
    setPickerDate(next);
  };

  const openDatePicker = (field, value) => {
    const parsed = new Date(value);
    setPickerField(field);
    setPickerDate(Number.isNaN(parsed.getTime()) ? new Date() : parsed);
    setPickerVisible(true);
  };

  const applyPickedDate = () => {
    const formatted = formatDate(pickerDate);

    if (pickerField === 'start') {
      setStartDate(formatted);
    } else {
      setEndDate(formatted);
    }

    setPickerVisible(false);
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.surface} />

      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()} activeOpacity={0.85}>
          <MaterialCommunityIcons name="arrow-left" size={20} color={theme.colors.text} />
        </TouchableOpacity>
        <View style={styles.headerInfo}>
          <Text style={styles.headerTitle}>Novo Pedido</Text>
          <Text style={styles.headerSub}>Férias ou dispensa para aprovação do gestor</Text>
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.body} showsVerticalScrollIndicator={false}>
        <View style={styles.balanceCard}>
          <View style={styles.balanceIcon}>
            <MaterialCommunityIcons name="calendar-plus" size={20} color={theme.colors.accent} />
          </View>
          <View style={styles.balanceInfo}>
            <Text style={styles.balanceLabel}>Saldo disponível</Text>
            <Text style={styles.balanceValue}>18 dias úteis</Text>
            <Text style={styles.balanceMeta}>Pedidos enviados entram na caixa do gestor</Text>
          </View>
        </View>

        <Text style={styles.formLabel}>Tipo de pedido</Text>
        <View style={styles.dropdownWrap}>
          <TouchableOpacity
            style={styles.dropdownTrigger}
            onPress={() => setIsTypeOpen((open) => !open)}
            activeOpacity={0.9}
          >
            <Text style={styles.dropdownTriggerText}>{selectedType}</Text>
            <MaterialCommunityIcons
              name={isTypeOpen ? 'chevron-up' : 'chevron-down'}
              size={20}
              color={theme.colors.muted}
            />
          </TouchableOpacity>

          {isTypeOpen ? (
            <View style={styles.dropdownMenu}>
              {requestTypes.map((type) => {
                const isSelected = selectedType === type;

                return (
                  <TouchableOpacity
                    key={type}
                    style={[styles.dropdownItem, isSelected && styles.dropdownItemActive]}
                    onPress={() => {
                      setSelectedType(type);
                      setIsTypeOpen(false);
                    }}
                    activeOpacity={0.9}
                  >
                    <Text style={[styles.dropdownItemText, isSelected && styles.dropdownItemTextActive]}>
                      {type}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          ) : null}
        </View>

        <View style={styles.dateRow}>
          <View style={styles.dateField}>
            <Text style={styles.formLabel}>Data inicial</Text>
            <TouchableOpacity
              style={styles.datePickerField}
              onPress={() => openDatePicker('start', startDate)}
              activeOpacity={0.9}
            >
              <Text style={styles.datePickerValue}>{formatDateLabel(startDate)}</Text>
              <MaterialCommunityIcons name="calendar-month-outline" size={18} color={theme.colors.muted} />
            </TouchableOpacity>
          </View>
          <View style={styles.dateField}>
            <Text style={styles.formLabel}>Data final</Text>
            <TouchableOpacity
              style={styles.datePickerField}
              onPress={() => openDatePicker('end', endDate)}
              activeOpacity={0.9}
            >
              <Text style={styles.datePickerValue}>{formatDateLabel(endDate)}</Text>
              <MaterialCommunityIcons name="calendar-month-outline" size={18} color={theme.colors.muted} />
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.daysCard}>
          <Text style={styles.daysLabel}>Dias solicitados</Text>
          <Text style={styles.daysValue}>{requestedDays} dias</Text>
        </View>

        <Text style={styles.formLabel}>Justificação</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          value={reason}
          onChangeText={setReason}
          placeholder="Descreva o motivo do pedido"
          placeholderTextColor={theme.colors.muted}
          multiline
          textAlignVertical="top"
        />

        <Text style={styles.formLabel}>Arquivo de suporte</Text>
        <TouchableOpacity
          style={styles.uploadButton}
          onPress={() => setAttachmentName('atestado-medico.pdf')}
          activeOpacity={0.9}
        >
          <View style={styles.uploadIconWrap}>
            <MaterialCommunityIcons name="paperclip" size={18} color={theme.colors.accent} />
          </View>
          <View style={styles.uploadInfo}>
            <Text style={styles.uploadTitle}>Fazer upload de arquivo</Text>
            <Text style={styles.uploadMeta}>
              {attachmentName || 'Anexe comprovativo, declaração ou outro documento'}
            </Text>
          </View>
          <MaterialCommunityIcons name="upload" size={18} color={theme.colors.muted} />
        </TouchableOpacity>

        <Button label="Enviar pedido" onPress={() => {}} />
      </ScrollView>

      <Modal visible={pickerVisible} transparent animationType="fade" onRequestClose={() => setPickerVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>
              {pickerField === 'start' ? 'Selecionar data inicial' : 'Selecionar data final'}
            </Text>
            <Text style={styles.modalDate}>{formatDateLabel(formatDate(pickerDate))}</Text>

            <View style={styles.modalControls}>
              <TouchableOpacity style={styles.modalStepButton} onPress={() => shiftPickerDate(-1)} activeOpacity={0.9}>
                <Text style={styles.modalStepButtonText}>-1 dia</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.modalStepButton} onPress={() => shiftPickerDate(1)} activeOpacity={0.9}>
                <Text style={styles.modalStepButtonText}>+1 dia</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.modalControls}>
              <TouchableOpacity style={styles.modalGhostButton} onPress={() => shiftPickerDate(-7)} activeOpacity={0.9}>
                <Text style={styles.modalGhostButtonText}>-7 dias</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.modalGhostButton} onPress={() => shiftPickerDate(7)} activeOpacity={0.9}>
                <Text style={styles.modalGhostButtonText}>+7 dias</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.modalActions}>
              <TouchableOpacity style={styles.modalCancelButton} onPress={() => setPickerVisible(false)} activeOpacity={0.9}>
                <Text style={styles.modalCancelButtonText}>Cancelar</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.modalConfirmButton} onPress={applyPickedDate} activeOpacity={0.9}>
                <Text style={styles.modalConfirmButtonText}>Confirmar</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

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
  balanceCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
  },
  balanceIcon: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  balanceInfo: {
    flex: 1,
  },
  balanceLabel: {
    fontSize: 11,
    color: theme.colors.muted,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  balanceValue: {
    fontSize: 18,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
    marginTop: 3,
  },
  balanceMeta: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
  formLabel: {
    fontSize: 12,
    color: theme.colors.muted,
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  dropdownWrap: {
    marginBottom: 14,
  },
  dropdownTrigger: {
    minHeight: 48,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 14,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  dropdownTriggerText: {
    fontSize: 14,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  dropdownMenu: {
    marginTop: 8,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    overflow: 'hidden',
  },
  dropdownItem: {
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  dropdownItemActive: {
    backgroundColor: theme.colors.infoDim,
  },
  dropdownItemText: {
    fontSize: 14,
    color: theme.colors.text,
  },
  dropdownItemTextActive: {
    color: theme.colors.accent,
    fontWeight: theme.fontWeight.semibold,
  },
  dateRow: {
    flexDirection: 'row',
    gap: 12,
  },
  dateField: {
    flex: 1,
  },
  datePickerField: {
    minHeight: 48,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 14,
    paddingHorizontal: 14,
    marginBottom: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  datePickerValue: {
    fontSize: 14,
    color: theme.colors.text,
    fontWeight: theme.fontWeight.medium,
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 14,
    color: theme.colors.text,
    marginBottom: 14,
  },
  textArea: {
    minHeight: 96,
  },
  uploadButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border2,
    borderRadius: 14,
    padding: 14,
    marginBottom: 14,
  },
  uploadIconWrap: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: theme.colors.infoDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  uploadInfo: {
    flex: 1,
  },
  uploadTitle: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  uploadMeta: {
    marginTop: 2,
    fontSize: 12,
    color: theme.colors.muted,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.35)',
    justifyContent: 'center',
    padding: 20,
  },
  modalCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: 18,
    padding: 18,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  modalTitle: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  modalDate: {
    marginTop: 8,
    fontSize: 20,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.accent,
  },
  modalControls: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 14,
  },
  modalStepButton: {
    flex: 1,
    backgroundColor: theme.colors.accent,
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: 'center',
  },
  modalStepButtonText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: theme.fontWeight.semibold,
  },
  modalGhostButton: {
    flex: 1,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 12,
    paddingVertical: 12,
    alignItems: 'center',
  },
  modalGhostButtonText: {
    color: theme.colors.text,
    fontSize: 13,
    fontWeight: theme.fontWeight.medium,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 10,
    marginTop: 18,
  },
  modalCancelButton: {
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  modalCancelButtonText: {
    color: theme.colors.muted,
    fontSize: 13,
    fontWeight: theme.fontWeight.medium,
  },
  modalConfirmButton: {
    backgroundColor: theme.colors.accent,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  modalConfirmButtonText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: theme.fontWeight.semibold,
  },
  daysCard: {
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
    marginBottom: 14,
  },
  daysLabel: {
    fontSize: 12,
    color: theme.colors.muted,
  },
  daysValue: {
    marginTop: 4,
    fontSize: 20,
    fontWeight: theme.fontWeight.bold,
    color: theme.colors.text,
  },
});
