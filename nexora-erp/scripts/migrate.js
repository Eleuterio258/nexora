'use strict';

/**
 * Migration Runner para Nexora ERP
 * 
 * Este script executa migrações SQL incrementalmente.
 * Uso: node migrate.js [service-name]
 * 
 * Exemplos:
 *   node migrate.js                    # Executa migrações para todos os serviços
 *   node migrate.js auth               # Executa migrações apenas para auth-service
 *   node migrate.js --list             # Lista migrações pendentes
 */

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Configuração da base de dados
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  user: process.env.DB_USER || 'nexora',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'nexora_erp',
});

// Mapeamento de serviços para schemas
const SERVICES = {
  auth: 'auth',
  empresa: 'empresa',
  faturacao: 'faturacao',
  autorizacao: 'autorizacao',
  clientes: 'clientes',
  produtos: 'produtos',
  impostos: 'impostos',
  stock: 'stock',
  financeiro: 'financeiro',
  tesouraria: 'tesouraria',
  compras: 'compras',
  contabilidade: 'contabilidade',
  'recursos-humanos': 'recursos_humanos',
  'multi-moeda': 'multi_moeda',
  'sistema-configuracao': 'sistema_configuracao',
  auditoria: 'auditoria',
  crm: 'crm',
  pos: 'pos',
  'centros-custo': 'centros_custo',
  seguranca: 'seguranca',
  assinaturas: 'assinaturas',
  notifications: 'notifications',
  logistica: 'logistica',
  'gestao-escolar': 'gestao_escolar',
};

const SERVICES_DIR = path.join(__dirname, '..', 'services');

async function createMigrationsTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS public.schema_migrations (
      id SERIAL PRIMARY KEY,
      schema_name VARCHAR(255) NOT NULL,
      migration_file VARCHAR(255) NOT NULL,
      applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(schema_name, migration_file)
    );
  `);
}

async function getAppliedMigrations(schemaName) {
  const result = await pool.query(
    'SELECT migration_file FROM public.schema_migrations WHERE schema_name = $1 ORDER BY migration_file',
    [schemaName]
  );
  return result.rows.map((row) => row.migration_file);
}

async function applyMigration(schemaName, migrationFile, sqlContent) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(`SET search_path TO ${schemaName}`);
    await client.query(sqlContent);
    await client.query(
      'INSERT INTO public.schema_migrations (schema_name, migration_file) VALUES ($1, $2)',
      [schemaName, path.basename(migrationFile)]
    );
    await client.query('COMMIT');
    console.log(`  ✅ ${path.basename(migrationFile)} aplicada`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`  ❌ Erro ao aplicar ${path.basename(migrationFile)}:`, err.message);
    throw err;
  } finally {
    client.release();
  }
}

async function migrateService(serviceKey) {
  const schemaName = SERVICES[serviceKey];
  if (!schemaName) {
    console.error(`Serviço desconhecido: ${serviceKey}`);
    return;
  }

  const serviceDir = path.join(SERVICES_DIR, `${serviceKey}-service`);
  const migrationsDir = path.join(serviceDir, 'migrations');

  if (!fs.existsSync(migrationsDir)) {
    console.log(`  ⚠️  Pasta migrations não encontrada para ${serviceKey}`);
    return;
  }

  const files = fs
    .readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  const applied = await getAppliedMigrations(schemaName);
  const pending = files.filter((f) => !applied.includes(f));

  if (pending.length === 0) {
    console.log(`  ✓ ${serviceKey}: sem migrações pendentes`);
    return;
  }

  console.log(`\n📦 ${serviceKey} (${pending.length} migrações pendentes):`);

  for (const file of pending) {
    const sqlContent = fs.readFileSync(path.join(migrationsDir, file), 'utf-8');
    await applyMigration(schemaName, path.join(migrationsDir, file), sqlContent);
  }
}

async function listPendingMigrations() {
  console.log('\n📋 Migrações pendentes:\n');

  for (const [serviceKey, schemaName] of Object.entries(SERVICES)) {
    const serviceDir = path.join(SERVICES_DIR, `${serviceKey}-service`);
    const migrationsDir = path.join(serviceDir, 'migrations');

    if (!fs.existsSync(migrationsDir)) continue;

    const files = fs
      .readdirSync(migrationsDir)
      .filter((f) => f.endsWith('.sql'))
      .sort();

    const applied = await getAppliedMigrations(schemaName);
    const pending = files.filter((f) => !applied.includes(f));

    if (pending.length > 0) {
      console.log(`  ${serviceKey}: ${pending.join(', ')}`);
    }
  }
}

async function main() {
  const args = process.argv.slice(2);

  try {
    await createMigrationsTable();

    if (args.includes('--list')) {
      await listPendingMigrations();
    } else if (args.length > 0) {
      // Migrar serviços específicos
      for (const arg of args) {
        await migrateService(arg);
      }
    } else {
      // Migrar todos os serviços
      console.log('🚀 A executar migrações para todos os serviços...\n');
      for (const serviceKey of Object.keys(SERVICES)) {
        await migrateService(serviceKey);
      }
    }

    console.log('\n✅ Migrações concluídas!');
  } catch (err) {
    console.error('\n❌ Erro durante migração:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();
