import AsyncStorage from '@react-native-async-storage/async-storage';

export const MODULE_CATALOG = [
  { key: 'dashboard',    title: 'Dashboard',       description: 'Painel principal',        icon: 'view-dashboard-outline',    route: 'ModuleDashboard'   },
  { key: 'sales',        title: 'Vendas',           description: 'Operacoes comerciais',    icon: 'cash-register',             route: 'ModuleSales'       },
  { key: 'quotes',       title: 'Cotacoes',         description: 'Cotacoes e orcamentos',   icon: 'file-document-edit-outline', route: 'ModuleQuotes'     },
  { key: 'orders',       title: 'Encomendas',       description: 'Gestao de encomendas',    icon: 'clipboard-list-outline',    route: 'ModuleOrders'      },
  { key: 'customers',    title: 'Clientes',         description: 'Base de clientes',        icon: 'account-multiple-outline',  route: 'ModuleCustomers'   },
  { key: 'products',     title: 'Produtos',         description: 'Catalogo de produtos',    icon: 'cube-outline',              route: 'ModuleProducts'    },
  { key: 'categories',   title: 'Categorias',       description: 'Categorias do catalogo',  icon: 'shape-outline',             route: 'ModuleCategories'  },
  { key: 'series',       title: 'Series',           description: 'Series documentais',      icon: 'format-list-numbered',      route: 'ModuleSeries'      },
  { key: 'invoices',     title: 'Faturas',          description: 'Emissao de faturas',      icon: 'receipt-text-outline',      route: 'ModuleInvoices'    },
  { key: 'receipts',     title: 'Recibos',          description: 'Recebimentos',            icon: 'cash-check',                route: 'ModuleReceipts'    },
  { key: 'credit-notes', title: 'Notas de Credito', description: 'Notas de credito',        icon: 'note-edit-outline',         route: 'ModuleCreditNotes' },
  { key: 'returns',      title: 'Devolucoes',       description: 'Devolucoes de artigos',   icon: 'backup-restore',            route: 'ModuleReturns'     },
  { key: 'payroll',      title: 'Folha Salarial',   description: 'Folha de pagamento',      icon: 'currency-usd',              route: 'ModulePayroll'     },
  { key: 'hr',           title: 'Recursos Humanos', description: 'Gestao de equipas',       icon: 'account-group-outline',     route: 'ModuleHR'          },
  { key: 'crm',          title: 'CRM',              description: 'Relacionamento comercial', icon: 'account-tie-outline',      route: 'ModuleCRM'         },
  { key: 'deliveries',   title: 'Entregas',         description: 'Expedicao e entregas',    icon: 'truck-delivery-outline',    route: 'ModuleDeliveries'  },
  { key: 'signatures',   title: 'Assinaturas',      description: 'Fluxos de assinatura',    icon: 'draw-pen',                  route: 'ModuleSignatures'  },
  { key: 'reports',      title: 'Relatorios',       description: 'Indicadores e analise',   icon: 'chart-box-outline',         route: 'ModuleReports'     },
  { key: 'settings',     title: 'Configuracoes',    description: 'Parametros do sistema',   icon: 'cog-outline',               route: 'ModuleSettings'    },
];

export const MODULE_GROUPS = [
  {
    key: 'comercial',
    label: 'Comercial',
    icon: 'storefront-outline',
    color: '#2563EB',
    dimColor: '#DBEAFE',
    modules: ['dashboard', 'sales', 'quotes', 'orders', 'customers'],
  },
  {
    key: 'catalogo',
    label: 'Catalogo',
    icon: 'cube-outline',
    color: '#7C3AED',
    dimColor: '#EDE9FE',
    modules: ['products', 'categories', 'series'],
  },
  {
    key: 'financeiro',
    label: 'Financeiro',
    icon: 'cash-multiple',
    color: '#059669',
    dimColor: '#D1FAE5',
    modules: ['invoices', 'receipts', 'credit-notes', 'returns', 'payroll'],
  },
  {
    key: 'pessoas',
    label: 'Pessoas',
    icon: 'account-group-outline',
    color: '#D97706',
    dimColor: '#FEF3C7',
    modules: ['hr', 'crm'],
  },
  {
    key: 'operacional',
    label: 'Operacional',
    icon: 'truck-delivery-outline',
    color: '#0891B2',
    dimColor: '#CFFAFE',
    modules: ['deliveries', 'signatures'],
  },
  {
    key: 'gestao',
    label: 'Gestao',
    icon: 'chart-box-outline',
    color: '#64748B',
    dimColor: '#F1F5F9',
    modules: ['reports', 'settings'],
  },
];

export const MODULE_ROUTE_CONFIGS = MODULE_CATALOG.map((moduleItem) => ({
  name: moduleItem.route,
  moduleKey: moduleItem.key,
}));

export const FUNCIONARIO_NAV_ITEMS = [
  { key: 'home',     label: 'Inicio',    icon: 'home-outline',           route: 'HomeFunc'        },
  { key: 'history',  label: 'Historico', icon: 'history',                route: 'Historico',       requiredModules: ['hr'] },
  { key: 'ferias',   label: 'Ferias',    icon: 'calendar-check-outline', route: 'SolicitarFerias', requiredModules: ['hr'] },
  { key: 'chat',     label: 'Chat',      icon: 'chat-outline',           route: 'Chat'            },
  { key: 'profile',  label: 'Perfil',    icon: 'account-outline',        route: 'Profile'         },
];

export const GESTOR_NAV_ITEMS = [
  { key: 'dashboard', label: 'Dashboard', icon: 'view-dashboard-outline', route: 'DashboardGestor' },
  { key: 'equipa',    label: 'Equipa',    icon: 'account-group-outline',  route: 'EquipaGestor',    requiredModules: ['hr'] },
  { key: 'modulos',   label: 'Modulos',   icon: 'view-grid-plus-outline', route: 'ModulosGestao'    },
  { key: 'relatorios',label: 'Relatorios',icon: 'chart-box-outline',      route: 'RelatoriosGestor', requiredModules: ['reports'] },
  { key: 'mais',      label: 'Mais',      icon: 'cog-outline',            route: 'Mais',             requiredModules: ['settings', 'hr'] },
];

function parseStoredArray(rawValue) {
  if (!rawValue) return [];
  try {
    const parsed = JSON.parse(rawValue);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

// Parse the API modules field — new format: [{module, permissions}, ...]
// Returns flat { moduleKeys: string[], permissions: string[] } for storage/checks.
export function parseApiModules(rawModules) {
  if (!Array.isArray(rawModules) || rawModules.length === 0) {
    return { moduleKeys: [], permissions: [] };
  }
  if (rawModules[0] !== null && typeof rawModules[0] === 'object') {
    return {
      moduleKeys: rawModules.map((m) => m.module),
      permissions: rawModules.flatMap((m) => m.permissions || []),
    };
  }
  // Legacy flat string array (super-admin path)
  return { moduleKeys: rawModules, permissions: [] };
}

export async function loadStoredAccess() {
  const [[, rawUser], [, rawModules], [, rawPermissions]] = await AsyncStorage.multiGet([
    'auth.user',
    'auth.modules',
    'auth.permissions',
  ]);

  const user = rawUser ? JSON.parse(rawUser) : null;
  const modules = parseStoredArray(rawModules);
  const permissions = parseStoredArray(rawPermissions);

  return { user, modules, permissions };
}

export async function clearStoredAccess() {
  await AsyncStorage.multiRemove([
    'auth.token',
    'auth.user',
    'auth.modules',
    'auth.permissions',
    'auth.account_sid',
    'auth.auth_token',
  ]);
}

export function hasModule(modules, moduleName) {
  return Array.isArray(modules) && modules.includes(moduleName);
}

export function hasPermission(permissions, permission) {
  return Array.isArray(permissions) && permissions.includes(permission);
}

export function hasAnyModule(modules, requiredModules = []) {
  if (!requiredModules || requiredModules.length === 0) return true;
  return requiredModules.some((moduleName) => hasModule(modules, moduleName));
}

export function filterNavItems(items, modules) {
  return items.filter((item) => hasAnyModule(modules, item.requiredModules));
}

export function getEnabledModuleEntries(modules) {
  if (!Array.isArray(modules) || modules.length === 0) return [];
  return MODULE_CATALOG.filter((moduleItem) => modules.includes(moduleItem.key));
}

export function getModuleMeta(moduleKey) {
  return MODULE_CATALOG.find((moduleItem) => moduleItem.key === moduleKey) || null;
}
