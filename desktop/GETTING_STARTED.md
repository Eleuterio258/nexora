# 🚀 FactPro Desktop - Guia de Início Rápido

## 1. Pré-requisitos

Certifique-se de ter instalado:
- **Java 17+**: `java -version`
- **Maven 3.8+**: `mvn -version`

## 2. Compilar o Projeto

```bash
cd D:\projecto\e-258tech\2026\factPro\facturacao
mvn clean package
```

## 3. Executar a Aplicação

### Via Maven
```bash
mvn exec:java
```

### Via JAR
```bash
java -jar target/facturacao-1.0.0.jar
```

## 4. Primeira Execução

Na primeira execução:

1. **Escolha o tipo de base de dados**:
   - **SQLite** (recomendado para começar) - zero instalação
   - **MySQL** - para multi-loja
   - **PostgreSQL** - para multi-loja

2. **Se escolher MySQL/PostgreSQL**, insira:
   - Host, Porta, Nome da BD
   - Utilizador e Senha

3. **Login padrão**:
   - Email: `admin@factpro.co.mz`
   - Senha: Será necessário criar o primeiro utilizador via SQL

## 5. Estrutura de Pastas Gerada

```
facturacao/
├── pom.xml                              # Build Maven
├── README.md                            # Documentação
├── .gitignore                           # Git ignore
├── src/
│   ├── main/
│   │   ├── java/com/factpro/
│   │   │   ├── FactProApplication.java  # Entry point
│   │   │   ├── config/                  # AppConfig
│   │   │   ├── core/database/           # DatabaseManager, BaseDAO
│   │   │   ├── auth/                    # Auth models, views, services
│   │   │   ├── vendas/                  # Vendas models, views
│   │   │   ├── produtos/                # Produtos models
│   │   │   ├── clientes/                # Clientes models
│   │   │   └── ui/                      # LoginDialog, MainFrame, etc.
│   │   └── resources/
│   │       ├── db/migration/            # 13 migrações SQL
│   │       ├── logback.xml              # Logging config
│   │       └── factpro.theme.properties # FlatLaf theme
│   └── test/                            # Testes unitários
└── target/                              # Output de build
```

## 6. Comandos Úteis

| Comando | Descrição |
|---------|-----------|
| `mvn clean package` | Compila e gera JAR |
| `mvn exec:java` | Executa a aplicação |
| `mvn test` | Executa testes |
| `mvn clean` | Limpa build anterior |
| `mvn dependency:tree` | Mostra dependências |

## 7. Base de Dados

### SQLite (Padrão)
- Ficheiro criado em: `./data/factpro.db`
- Não requer configuração adicional
- Ideal para desenvolvimento

### MySQL
```sql
CREATE DATABASE factpro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'factpro'@'localhost' IDENTIFIED BY 'sua_senha';
GRANT ALL PRIVILEGES ON factpro.* TO 'factpro'@'localhost';
FLUSH PRIVILEGES;
```

### PostgreSQL
```sql
CREATE DATABASE factpro;
CREATE USER factpro WITH PASSWORD 'sua_senha';
GRANT ALL PRIVILEGES ON DATABASE factpro TO factpro;
```

## 8. Resolução de Problemas

### Erro: "Base de dados não encontrada"
- Verifique se o diretório `./data` existe
- Crie manualmente se necessário: `mkdir data`

### Erro: "Migrações falharam"
```bash
# Limpar e recriar
rm -rf data/factpro.db
mvn clean exec:java
```

### Erro: "Porta em uso"
- Verifique se outra instância está rodando
- Mate o processo e tente novamente

## 9. Próximos Passos

1. ✅ Compilar e executar o projeto
2. 🔲 Criar primeiro utilizador (via SQL ou interface)
3. 🔲 Configurar base de dados
4. 🔲 Explorar módulo POS
5. 🔲 Adicionar produtos e categorias
6. 🔲 Testar fluxo de venda completa
7. 🔲 Configurar impressora térmica

## 10. Suporte

Para ajuda ou reportar bugs, consulte:
- `README.md` - Documentação principal
- `spec.md` - Especificação técnica completa
- `documentacao.md` - Requisitos originais

---

*FactPro Desktop v1.0.0*
