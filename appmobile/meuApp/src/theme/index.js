/**
 * Tema Global - Omnisys ERP Assiduidade
 * Design "Premium" com gradientes Azul/Roxo e interface Slate moderna.
 */

export const theme = {
  colors: {
    // ==========================================
    // CORES PRINCIPAIS (SISTEMA)
    // ==========================================
    primary: '#171717',       // hsl(0, 0%, 9%) - Texto forte e elementos de destaque
    secondary: '#F5F5F5',     // hsl(0, 0%, 96.1%) - Fundos secundários
    accent: '#2563EB',        // hsl(220, 70%, 50%) - Azul vibrante para interações
    destructive: '#EF4444',   // hsl(0, 84.2%, 60.2%) - Erro/Eliminação

    // ==========================================
    // PALETA PREMIUM (SIDEBAR & LOGIN)
    // ==========================================
    sidebarStart: '#161D2F',  // hsl(220, 40%, 12%) - Azul Marinho Profundo
    sidebarMiddle: '#111726', // hsl(230, 45%, 10%) - Azul Noite
    sidebarEnd: '#0C0E1A',    // hsl(240, 50%, 8%) - Roxo Escuro/Preto
    sidebarAccent: '#2563EB', // hsl(220, 70%, 50%) - Azul Vibrante
    sidebarHover: '#3B82F6',  // hsl(220, 70%, 55%) - Azul Claro Vibrante

    // ==========================================
    // CORES DE INTERFACE (UI)
    // ==========================================
    background: '#F8FAFC',    // Fundo geral das páginas (Slate 50)
    surface: '#FFFFFF',       // Cards e superfícies brancas
    surface2: '#F1F5F9',      // Superfícies secundárias (Slate 100)
    
    border: '#E2E8F0',        // Bordas de inputs e divisores (Slate 200)
    border2: '#CBD5E1',       // Bordas mais visíveis (Slate 300)
    
    text: '#1E293B',          // Texto principal (Slate 800)
    muted: '#64748B',         // Texto secundário ou desativado (Slate 500)
    hint: '#E2E8F0',          // Placeholder e dicas
    
    // Status
    success: '#10B981',       // Verde para sucesso e confirmação
    successDim: '#D1FAE5',
    successBorder: '#6EE7B7',
    
    error: '#EF4444',         // Vermelho para alertas e validações
    errorDim: '#FEE2E2',
    errorBorder: '#FCA5A5',
    
    warning: '#F59E0B',       // Âmbar para avisos
    warningDim: '#FEF3C7',
    warningBorder: '#FCD34D',
    
    info: '#3B82F6',          // Azul para informações
    infoDim: '#DBEAFE',
    infoBorder: '#93C5FD',

    // Compatibilidade com nomes antigos
    bg: '#F8FAFC',
    green: '#10B981',
    greenDim: '#D1FAE5',
    greenBorder: '#6EE7B7',
    red: '#EF4444',
    redDim: '#FEE2E2',
    redBorder: '#FCA5A5',
    amber: '#F59E0B',
    amberDim: '#FEF3C7',
    amberBorder: '#FCD34D',
    blue: '#3B82F6',
    blueDim: '#DBEAFE',
    blueBorder: '#93C5FD',
  },

  spacing: {
    xs: 4,
    sm: 6,
    md: 8,
    base: 10,
    lg: 12,
    xl: 14,
    '2xl': 16,
    '3xl': 20,
    '4xl': 24,
  },

  borderRadius: {
    sm: 6,
    base: 8,
    lg: 12,
    xl: 16,
    '2xl': 20,
    full: 9999,
  },

  fontSize: {
    xs: 10,
    sm: 11,
    base: 12,
    md: 13,
    lg: 14,
    xl: 16,
    '2xl': 20,
    '3xl': 24,
    '4xl': 30,
  },

  fontWeight: {
    light: '300',
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
  },

  shadows: {
    sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
    base: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1)',
    md: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1)',
    lg: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1)',
  },

  gradients: {
    sidebar: ['#161D2F', '#111726', '#0C0E1A'],
    primary: ['#2563EB', '#1D4ED8'],
    success: ['#10B981', '#059669'],
    error: ['#EF4444', '#DC2626'],
  },
};

export default theme;
