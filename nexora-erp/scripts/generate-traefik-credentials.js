#!/usr/bin/env node

/**
 * Script para gerar credenciais seguras para o Traefik Dashboard
 * Execute: node generate-traefik-credentials.js
 */

const { execSync } = require('child_process');

function generatePassword(length = 16) {
  const charset =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < length; i++) {
    password += charset.charAt(Math.floor(Math.random() * charset.length));
  }
  return password;
}

function main() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  Gerador de Credenciais - Traefik Dashboard');
  console.log('═══════════════════════════════════════════════════════\n');

  const username = 'admin';
  const password = generatePassword(20);

  console.log('👤  Utilizador:', username);
  console.log('🔑  Password:', password);
  console.log('');

  try {
    // Tentar usar htpasswd se disponível
    const hash = execSync(`htpasswd -nb ${username} ${password}`, {
      encoding: 'utf-8',
    }).trim();

    console.log('📝  Linha para adicionar ao dynamic.yml:');
    console.log('');
    console.log(`  - "${hash}"`);
    console.log('');
    console.log('═══════════════════════════════════════════════════════');
    console.log('✅  Copie esta linha para infra/traefik/dynamic.yml');
    console.log('    Substitua a linha que contém "admin:$apr1$..."');
    console.log('═══════════════════════════════════════════════════════');
  } catch (err) {
    // Se htpasswd não estiver disponível, mostrar instruções alternativas
    console.log('⚠️   htpasswd não está disponível no sistema.');
    console.log('');
    console.log('📋  Siga estas instruções:');
    console.log('');
    console.log('1. Aceda a: https://www.web2generators.com/apache-tools/htpasswd-generator');
    console.log(`2. Utilizador: ${username}`);
    console.log(`3. Password: ${password}`);
    console.log('4. Cole o resultado no ficheiro infra/traefik/dynamic.yml');
    console.log('');
    console.log('═══════════════════════════════════════════════════════');
  }
}

main();
