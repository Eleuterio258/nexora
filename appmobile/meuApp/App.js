import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { SafeAreaProvider } from 'react-native-safe-area-context';

// ==========================================
// IMPORTAÇÃO DE TODAS AS PÁGINAS DO APP
// ==========================================

// --- App Funcionário ---
import LoginScreen from './screens/funcionario/LoginScreen';
import ForgotPasswordScreen from './screens/funcionario/ForgotPasswordScreen';
import HomeFuncScreen from './screens/funcionario/HomeFuncScreen';
import AgendaScreen from './screens/funcionario/AgendaScreen';
import CriarReuniaoScreen from './screens/funcionario/CriarReuniaoScreen';
import DetalheReuniaoScreen from './screens/funcionario/DetalheReuniaoScreen';
import DetalheAgendaItemScreen from './screens/funcionario/DetalheAgendaItemScreen';
import NotificacoesScreen from './screens/funcionario/NotificacoesScreen';
import ChatScreen from './screens/funcionario/ChatScreen';
import ChatPrivadoScreen from './screens/funcionario/ChatPrivadoScreen';
import ChatGrupoScreen from './screens/funcionario/ChatGrupoScreen';
import FaceScreen from './screens/funcionario/FaceScreen';
import QRCodeScreen from './screens/funcionario/QRCodeScreen';
import SelfieGPSScreen from './screens/funcionario/SelfieGPSScreen';
import NFCScreen from './screens/funcionario/NFCScreen';
import PINScreen from './screens/funcionario/PINScreen';
import SuccessScreen from './screens/funcionario/SuccessScreen';
import HistoricoScreen from './screens/funcionario/HistoricoScreen';
import JustificarScreen from './screens/funcionario/JustificarScreen';
import ProfileScreen from './screens/funcionario/ProfileScreen';
import SolicitarFeriasScreen from './screens/funcionario/SolicitarFeriasScreen';
import SolicitarFeriasFormScreen from './screens/funcionario/SolicitarFeriasFormScreen';
import DetalhePedidoScreen from './screens/funcionario/DetalhePedidoScreen';
import ModulesHubScreen from './screens/shared/ModulesHubScreen';
import ModuleDetailScreen from './screens/shared/ModuleDetailScreen';
import { MODULE_SCREEN_COMPONENTS } from './screens/modules';

// --- Super Admin ---
import SuperAdminDashboardScreen from './screens/superadmin/SuperAdminDashboardScreen';
import SuperAdminTenantsScreen from './screens/superadmin/SuperAdminTenantsScreen';
import SuperAdminTenantDetailScreen from './screens/superadmin/SuperAdminTenantDetailScreen';
import SuperAdminPlanosScreen from './screens/superadmin/SuperAdminPlanosScreen';
import SuperAdminPlanoFormScreen from './screens/superadmin/SuperAdminPlanoFormScreen';
import SuperAdminTenantPlanoScreen from './screens/superadmin/SuperAdminTenantPlanoScreen';

// --- App Gestor (Tema Escuro) ---
import DashboardScreenGestor from './screens/gestor/DashboardScreenGestor';
import CRMScreen from './screens/gestor/CRMScreen';
import DashboardScreen from './screens/gestor/DashboardScreen';
import EquipaScreenGestor from './screens/gestor/EquipaScreenGestor';
import EquipaScreen from './screens/gestor/EquipaScreen';
import DetalheFuncionarioScreen from './screens/gestor/DetalheFuncionarioScreen';
import RegistarManualScreen from './screens/gestor/RegistarManualScreen';
import RegistoManualScreen from './screens/gestor/RegistoManualScreen';
import OcorrenciasScreen from './screens/gestor/OcorrenciasScreen';
import AlertasScreen from './screens/gestor/AlertasScreen';
import RelatoriosScreenGestor from './screens/gestor/RelatoriosScreenGestor';
import RelatoriosScreen from './screens/gestor/RelatoriosScreen';
import MaisScreen from './screens/gestor/MaisScreen';
import DispositivosScreen from './screens/gestor/DispositivosScreen';
import PedidoFeriasScreen from './screens/gestor/PedidoFeriasScreen';
import ModulosGestaoScreen from './screens/gestor/ModulosGestaoScreen';

// Tema
import { theme } from './src/theme';
import { MODULE_ROUTE_CONFIGS } from './src/access';

// ==========================================
// CONFIGURAÇÃO DO STACK NAVIGATOR
// ==========================================

const Stack = createNativeStackNavigator();

// Opções padrão para os headers
const screenOptions = {
  headerStyle: {
    backgroundColor: theme.colors.bg,
  },
  headerTintColor: theme.colors.text,
  headerTitleStyle: {
    fontWeight: theme.fontWeight.semibold,
    fontSize: 16,
    letterSpacing: -0.3,
  },
  headerShadowVisible: false,
};

export default function App() {
  return (
    <SafeAreaProvider>
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Login" screenOptions={screenOptions}>
        
        {/* ========================================
            AUTENTICAÇÃO
        ======================================== */}
        <Stack.Screen
          name="Login"
          component={LoginScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="ForgotPassword"
          component={ForgotPasswordScreen}
          options={{ headerShown: false }}
        />

        {/* ========================================
            APP FUNCIONÁRIO - Registo de Presença
        ======================================== */}
        <Stack.Screen
          name="HomeFunc"
          component={HomeFuncScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Agenda"
          component={AgendaScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="CriarReuniao"
          component={CriarReuniaoScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="DetalheReuniao"
          component={DetalheReuniaoScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="DetalheAgendaItem"
          component={DetalheAgendaItemScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Notificacoes"
          component={NotificacoesScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Chat"
          component={ChatScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="ChatPrivado"
          component={ChatPrivadoScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="ChatGrupo"
          component={ChatGrupoScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Face"
          component={FaceScreen}
          options={{ title: 'Biometria Facial' }}
        />
        <Stack.Screen
          name="QRCode"
          component={QRCodeScreen}
          options={{ title: 'QR Code' }}
        />
        <Stack.Screen
          name="SelfieGPS"
          component={SelfieGPSScreen}
          options={{ title: 'Selfie + GPS' }}
        />
        <Stack.Screen
          name="NFC"
          component={NFCScreen}
          options={{ title: 'NFC / Cartão' }}
        />
        <Stack.Screen
          name="PIN"
          component={PINScreen}
          options={{ title: 'PIN / TOTP' }}
        />
        <Stack.Screen
          name="Success"
          component={SuccessScreen}
          options={{ title: 'Confirmação' }}
        />
        <Stack.Screen
          name="Historico"
          component={HistoricoScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Justificar"
          component={JustificarScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Profile"
          component={ProfileScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="SolicitarFerias"
          component={SolicitarFeriasScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="SolicitarFeriasForm"
          component={SolicitarFeriasFormScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="DetalhePedido"
          component={DetalhePedidoScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="ModulesHub"
          component={ModulesHubScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="ModuleDetail"
          component={ModuleDetailScreen}
          options={{ headerShown: false }}
        />
        {MODULE_ROUTE_CONFIGS.map((moduleRoute) => (
          <Stack.Screen
            key={moduleRoute.name}
            name={moduleRoute.name}
            component={MODULE_SCREEN_COMPONENTS[moduleRoute.name]}
            options={{ headerShown: false }}
          />
        ))}

        {/* ========================================
            APP GESTOR - Dashboard
        ======================================== */}
        <Stack.Screen
          name="DashboardGestor"
          component={DashboardScreenGestor}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="CRM"
          component={CRMScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Dashboard"
          component={DashboardScreen}
          options={{ title: 'Dashboard' }}
        />

        {/* ========================================
            APP GESTOR - Equipa
        ======================================== */}
        <Stack.Screen
          name="EquipaGestor"
          component={EquipaScreenGestor}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Equipa"
          component={EquipaScreen}
          options={{ title: 'Equipa' }}
        />

        {/* ========================================
            APP GESTOR - Detalhe do Funcionário
        ======================================== */}
        <Stack.Screen
          name="DetalheFuncionario"
          component={DetalheFuncionarioScreen}
          options={{ title: 'Detalhe do Funcionário' }}
        />

        {/* ========================================
            APP GESTOR - Registo Manual
        ======================================== */}
        <Stack.Screen
          name="RegistarManual"
          component={RegistarManualScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="RegistoManual"
          component={RegistoManualScreen}
          options={{ title: 'Registo Manual' }}
        />

        {/* ========================================
            APP GESTOR - Ocorrências / Alertas
        ======================================== */}
        <Stack.Screen
          name="Ocorrencias"
          component={OcorrenciasScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Alertas"
          component={AlertasScreen}
          options={{ title: 'Alertas' }}
        />

        {/* ========================================
            APP GESTOR - Relatórios
        ======================================== */}
        <Stack.Screen
          name="RelatoriosGestor"
          component={RelatoriosScreenGestor}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Relatorios"
          component={RelatoriosScreen}
          options={{ title: 'Relatórios' }}
        />

        {/* ========================================
            APP GESTOR - Dispositivos & Config
        ======================================== */}
        <Stack.Screen
          name="Mais"
          component={MaisScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Dispositivos"
          component={DispositivosScreen}
          options={{ title: 'Dispositivos' }}
        />
        <Stack.Screen
          name="PedidoFerias"
          component={PedidoFeriasScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="ModulosGestao"
          component={ModulosGestaoScreen}
          options={{ headerShown: false }}
        />

        {/* ========================================
            SUPER ADMIN - Gestão da Plataforma
        ======================================== */}
        <Stack.Screen
          name="SuperAdminDashboard"
          component={SuperAdminDashboardScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="SuperAdminTenants"
          component={SuperAdminTenantsScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="SuperAdminTenantDetail"
          component={SuperAdminTenantDetailScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="SuperAdminPlanos"
          component={SuperAdminPlanosScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="SuperAdminPlanoForm"
          component={SuperAdminPlanoFormScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="SuperAdminTenantPlano"
          component={SuperAdminTenantPlanoScreen}
          options={{ headerShown: false }}
        />

      </Stack.Navigator>
    </NavigationContainer>
    </SafeAreaProvider>
  );
}
