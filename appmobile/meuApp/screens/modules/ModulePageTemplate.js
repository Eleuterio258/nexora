import React from 'react';
import { View, Text, StyleSheet, SafeAreaView, StatusBar, ScrollView } from 'react-native';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { theme } from '../../src/theme';
import { AppHeader } from '../../src/components';
import { getModuleMeta } from '../../src/access';

const moduleHighlights = {
  dashboard: ['Resumo operacional', 'Indicadores principais', 'Acesso rapido a areas criticas'],
  sales: ['Funil comercial', 'Metas e desempenho', 'Seguimento de vendas'],
  categories: ['Organizacao do catalogo', 'Classificacao de produtos', 'Estrutura comercial'],
  products: ['Catalogo', 'Stock e disponibilidade', 'Preco e referencia'],
  customers: ['Base de clientes', 'Relacionamento', 'Historico comercial'],
  series: ['Series documentais', 'Sequencias', 'Padroes de emissao'],
  crm: ['Contas e contactos', 'Leads', 'Pipeline comercial'],
  payroll: ['Folha salarial', 'Processamento', 'Resumo financeiro'],
  hr: ['Equipas', 'Funcionarios', 'Operacoes de RH'],
  signatures: ['Documentos', 'Fluxos de assinatura', 'Acompanhamento'],
  quotes: ['Cotacoes', 'Propostas', 'Conversao comercial'],
  orders: ['Pedidos', 'Estado operacional', 'Seguimento'],
  deliveries: ['Expedicao', 'Entregas', 'Confirmacoes'],
  invoices: ['Emissao de faturas', 'Resumo de cobranca', 'Documentos'],
  receipts: ['Recebimentos', 'Comprovativos', 'Caixa'],
  'credit-notes': ['Ajustes', 'Credito ao cliente', 'Documentos relacionados'],
  returns: ['Devolucoes', 'Motivos e fluxo', 'Tratamento operacional'],
  reports: ['Indicadores', 'Analise', 'Exportacao'],
  settings: ['Parametros', 'Preferencias', 'Configuracoes gerais'],
};

export default function ModulePageTemplate({ moduleKey }) {
  const moduleItem = getModuleMeta(moduleKey);
  const highlights = moduleHighlights[moduleKey] || ['Visao geral', 'Acoes principais', 'Monitorizacao'];

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={theme.colors.bg} />
      <AppHeader
        title={moduleItem?.title || 'Modulo'}
        subtitle={moduleItem?.key || 'sem identificador'}
      />

      <ScrollView style={styles.scroll} showsVerticalScrollIndicator={false}>
        <View style={styles.body}>
          <View style={styles.hero}>
            <View style={styles.heroIcon}>
              <MaterialCommunityIcons
                name={moduleItem?.icon || 'view-grid-outline'}
                size={22}
                color={theme.colors.blue}
              />
            </View>
            <Text style={styles.title}>{moduleItem?.title || 'Modulo'}</Text>
            <Text style={styles.text}>
              {moduleItem?.description || 'Modulo habilitado para este utilizador.'}
            </Text>
          </View>

          <Text style={styles.sectionTitle}>Capacidades</Text>
          {highlights.map((item) => (
            <View key={item} style={styles.highlightCard}>
              <MaterialCommunityIcons name="check-circle-outline" size={18} color={theme.colors.green} />
              <Text style={styles.highlightText}>{item}</Text>
            </View>
          ))}

          <View style={styles.noteCard}>
            <Text style={styles.noteTitle}>Estado da pagina</Text>
            <Text style={styles.noteText}>
              Esta pagina do modulo {moduleItem?.key || moduleKey} foi criada como tela individual no app mobile e pode ser integrada ao backend em seguida.
            </Text>
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.bg,
  },
  scroll: {
    flex: 1,
  },
  body: {
    padding: 16,
  },
  hero: {
    backgroundColor: theme.colors.surface,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: 16,
    marginBottom: 18,
  },
  heroIcon: {
    width: 46,
    height: 46,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.blueDim,
    marginBottom: 12,
  },
  title: {
    fontSize: 16,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  text: {
    marginTop: 8,
    fontSize: 13,
    lineHeight: 20,
    color: theme.colors.muted,
  },
  sectionTitle: {
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    color: theme.colors.muted,
    marginBottom: 12,
  },
  highlightCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
    marginBottom: 10,
  },
  highlightText: {
    flex: 1,
    fontSize: 13,
    color: theme.colors.text,
  },
  noteCard: {
    marginTop: 8,
    backgroundColor: theme.colors.surface2,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 14,
    padding: 14,
  },
  noteTitle: {
    fontSize: 14,
    fontWeight: theme.fontWeight.semibold,
    color: theme.colors.text,
  },
  noteText: {
    marginTop: 6,
    fontSize: 12,
    lineHeight: 18,
    color: theme.colors.muted,
  },
});
