package main

import (
	"context"
	"fmt"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const connString = "postgres://postgres:Plane%40mento1@209.126.86.55:5432/nexora_erp?sslmode=disable"

type schemaInfo struct {
	name       string
	tables     []tableInfo
	views      []string
	rowCounts  int64
	sizeBytes  int64
}

type tableInfo struct {
	schema      string
	name        string
	columns     []columnInfo
	primaryKey  []string
	foreignKeys []foreignKeyInfo
	indexes     []indexInfo
	rowCount    int64
	sizeBytes   int64
	comment     string
}

type columnInfo struct {
	name         string
	dataType     string
	isNullable   bool
	defaultValue *string
	isPrimaryKey bool
	comment      string
}

type foreignKeyInfo struct {
	name       string
	columns    []string
	refSchema  string
	refTable   string
	refColumns []string
}

type indexInfo struct {
	name    string
	columns []string
	unique  bool
}

func main() {
	ctx := context.Background()

	config, err := pgxpool.ParseConfig(connString)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erro ao parsear string de conexão: %v\n", err)
		os.Exit(1)
	}
	config.MaxConns = 5
	config.ConnConfig.ConnectTimeout = 15 * time.Second

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erro ao criar pool: %v\n", err)
		os.Exit(1)
	}
	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		fmt.Fprintf(os.Stderr, "Erro ao conectar ao banco: %v\n", err)
		os.Exit(1)
	}

	fmt.Println(strings.Repeat("=", 80))
	fmt.Println("ANÁLISE COMPLETA DO BANCO DE DADOS")
	fmt.Printf("Banco: nexora_erp\n")
	fmt.Printf("Servidor: 209.126.86.55:5432\n")
	fmt.Printf("Data/Hora: %s\n", time.Now().Format(time.RFC3339))
	fmt.Println(strings.Repeat("=", 80))

	// 1. Informações do servidor
	printServerInfo(ctx, pool)

	// 2. Schemas
	schemas := getSchemas(ctx, pool)
	fmt.Printf("\nTotal de schemas encontrados: %d\n", len(schemas))

	// 3. Para cada schema, analisar tabelas
	for i := range schemas {
		analyzeSchema(ctx, pool, &schemas[i])
	}

	// 4. Resumo geral
	printSummary(schemas)

	// 5. Detalhes por schema
	for _, s := range schemas {
		printSchemaDetails(s)
	}
}

func printServerInfo(ctx context.Context, pool *pgxpool.Pool) {
	var version, dbSize string
	_ = pool.QueryRow(ctx, "SELECT version()").Scan(&version)
	_ = pool.QueryRow(ctx, "SELECT pg_size_pretty(pg_database_size(current_database()))").Scan(&dbSize)
	fmt.Printf("\nVersão do PostgreSQL:\n%s\n", version)
	fmt.Printf("Tamanho total do banco: %s\n", dbSize)
}

func getSchemas(ctx context.Context, pool *pgxpool.Pool) []schemaInfo {
	rows, err := pool.Query(ctx, `
		SELECT schema_name
		FROM information_schema.schemata
		WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
		  AND schema_name NOT LIKE 'pg_%'
		ORDER BY schema_name
	`)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erro ao listar schemas: %v\n", err)
		os.Exit(1)
	}
	defer rows.Close()

	var schemas []schemaInfo
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err == nil {
			schemas = append(schemas, schemaInfo{name: name})
		}
	}
	return schemas
}

func analyzeSchema(ctx context.Context, pool *pgxpool.Pool, s *schemaInfo) {
	// Tabelas
	tableRows, err := pool.Query(ctx, `
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema = $1
		  AND table_type = 'BASE TABLE'
		ORDER BY table_name
	`, s.name)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erro ao listar tabelas do schema %s: %v\n", s.name, err)
		return
	}
	defer tableRows.Close()

	for tableRows.Next() {
		var tname string
		if err := tableRows.Scan(&tname); err != nil {
			continue
		}
		t := tableInfo{schema: s.name, name: tname}
		analyzeTable(ctx, pool, &t)
		s.tables = append(s.tables, t)
		s.rowCounts += t.rowCount
		s.sizeBytes += t.sizeBytes
	}

	// Views
	viewRows, err := pool.Query(ctx, `
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema = $1
		  AND table_type = 'VIEW'
		ORDER BY table_name
	`, s.name)
	if err != nil {
		return
	}
	defer viewRows.Close()
	for viewRows.Next() {
		var vname string
		if err := viewRows.Scan(&vname); err == nil {
			s.views = append(s.views, vname)
		}
	}
}

func analyzeTable(ctx context.Context, pool *pgxpool.Pool, t *tableInfo) {
	fullName := pgx.Identifier{t.schema, t.name}.Sanitize()

	// Colunas
	colRows, err := pool.Query(ctx, `
		SELECT c.column_name, c.data_type, c.is_nullable, c.column_default,
		       col_description((c.table_schema||'.'||c.table_name)::regclass::oid, c.ordinal_position)
		FROM information_schema.columns c
		WHERE c.table_schema = $1 AND c.table_name = $2
		ORDER BY c.ordinal_position
	`, t.schema, t.name)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erro ao listar colunas de %s.%s: %v\n", t.schema, t.name, err)
		return
	}
	defer colRows.Close()

	for colRows.Next() {
		var c columnInfo
		var nullable string
		var def *string
		var comment *string
		if err := colRows.Scan(&c.name, &c.dataType, &nullable, &def, &comment); err != nil {
			continue
		}
		c.isNullable = nullable == "YES"
		c.defaultValue = def
		if comment != nil {
			c.comment = *comment
		}
		t.columns = append(t.columns, c)
	}

	// Chave primária
	pkRows, err := pool.Query(ctx, `
		SELECT kcu.column_name
		FROM information_schema.table_constraints tc
		JOIN information_schema.key_column_usage kcu
		  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
		WHERE tc.constraint_type = 'PRIMARY KEY'
		  AND tc.table_schema = $1
		  AND tc.table_name = $2
		ORDER BY kcu.ordinal_position
	`, t.schema, t.name)
	if err == nil {
		defer pkRows.Close()
		for pkRows.Next() {
			var col string
			if err := pkRows.Scan(&col); err == nil {
				t.primaryKey = append(t.primaryKey, col)
				for i := range t.columns {
					if t.columns[i].name == col {
						t.columns[i].isPrimaryKey = true
					}
				}
			}
		}
	}

	// Chaves estrangeiras
	fkRows, err := pool.Query(ctx, `
		SELECT tc.constraint_name,
		       kcu.column_name,
		       ccu.table_schema AS ref_schema,
		       ccu.table_name AS ref_table,
		       ccu.column_name AS ref_column
		FROM information_schema.table_constraints tc
		JOIN information_schema.key_column_usage kcu
		  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
		JOIN information_schema.constraint_column_usage ccu
		  ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
		WHERE tc.constraint_type = 'FOREIGN KEY'
		  AND tc.table_schema = $1
		  AND tc.table_name = $2
		ORDER BY tc.constraint_name, kcu.ordinal_position
	`, t.schema, t.name)
	if err == nil {
		defer fkRows.Close()
		fkMap := make(map[string]*foreignKeyInfo)
		for fkRows.Next() {
			var cname, col, refSchema, refTable, refColumn string
			if err := fkRows.Scan(&cname, &col, &refSchema, &refTable, &refColumn); err == nil {
				if _, ok := fkMap[cname]; !ok {
					fkMap[cname] = &foreignKeyInfo{name: cname, refSchema: refSchema, refTable: refTable}
				}
				fkMap[cname].columns = append(fkMap[cname].columns, col)
				fkMap[cname].refColumns = append(fkMap[cname].refColumns, refColumn)
			}
		}
		for _, fk := range fkMap {
			t.foreignKeys = append(t.foreignKeys, *fk)
		}
		sort.Slice(t.foreignKeys, func(i, j int) bool { return t.foreignKeys[i].name < t.foreignKeys[j].name })
	}

	// Índices
	idxRows, err := pool.Query(ctx, `
		SELECT indexname, indexdef
		FROM pg_indexes
		WHERE schemaname = $1 AND tablename = $2
		ORDER BY indexname
	`, t.schema, t.name)
	if err == nil {
		defer idxRows.Close()
		for idxRows.Next() {
			var iname, idef string
			if err := idxRows.Scan(&iname, &idef); err == nil {
				idx := indexInfo{name: iname}
				idx.unique = strings.Contains(idef, " UNIQUE ")
				// Extrair colunas entre parênteses
				start := strings.Index(idef, "(")
				end := strings.LastIndex(idef, ")")
				if start != -1 && end != -1 && end > start {
					cols := strings.Split(idef[start+1:end], ",")
					for _, c := range cols {
						c = strings.TrimSpace(c)
						if c != "" {
							idx.columns = append(idx.columns, c)
						}
					}
				}
				t.indexes = append(t.indexes, idx)
			}
		}
	}

	// Contagem de linhas
	_ = pool.QueryRow(ctx, fmt.Sprintf("SELECT COUNT(*) FROM %s", fullName)).Scan(&t.rowCount)

	// Tamanho da tabela
	_ = pool.QueryRow(ctx, `
		SELECT pg_total_relation_size($1)
	`, fullName).Scan(&t.sizeBytes)

	// Comentário da tabela
	var comment *string
	_ = pool.QueryRow(ctx, `
		SELECT obj_description(($1)::regclass)
	`, fullName).Scan(&comment)
	if comment != nil {
		t.comment = *comment
	}
}

func printSummary(schemas []schemaInfo) {
	fmt.Println("\n" + strings.Repeat("=", 80))
	fmt.Println("RESUMO GERAL")
	fmt.Println(strings.Repeat("=", 80))

	var totalTables, totalViews, totalRows int64
	var totalSize int64
	for _, s := range schemas {
		totalTables += int64(len(s.tables))
		totalViews += int64(len(s.views))
		totalRows += s.rowCounts
		totalSize += s.sizeBytes
	}

	fmt.Printf("Total de schemas:    %d\n", len(schemas))
	fmt.Printf("Total de tabelas:    %d\n", totalTables)
	fmt.Printf("Total de views:      %d\n", totalViews)
	fmt.Printf("Total estimado de linhas: %d\n", totalRows)
	fmt.Printf("Tamanho total:       %s\n", formatBytes(totalSize))

	fmt.Println("\n--- Resumo por Schema ---")
	fmt.Printf("%-25s %8s %8s %15s %12s\n", "Schema", "Tabelas", "Views", "Linhas", "Tamanho")
	fmt.Println(strings.Repeat("-", 75))
	for _, s := range schemas {
		fmt.Printf("%-25s %8d %8d %15d %12s\n",
			s.name, len(s.tables), len(s.views), s.rowCounts, formatBytes(s.sizeBytes))
	}
}

func printSchemaDetails(s schemaInfo) {
	fmt.Println("\n" + strings.Repeat("=", 80))
	fmt.Printf("SCHEMA: %s  (%d tabelas, %d views, %d linhas, %s)\n",
		s.name, len(s.tables), len(s.views), s.rowCounts, formatBytes(s.sizeBytes))
	fmt.Println(strings.Repeat("=", 80))

	if len(s.views) > 0 {
		fmt.Println("\nViews:")
		for _, v := range s.views {
			fmt.Printf("  - %s.%s\n", s.name, v)
		}
	}

	for _, t := range s.tables {
		fmt.Printf("\n  TABELA: %s.%s\n", t.schema, t.name)
		if t.comment != "" {
			fmt.Printf("  Comentário: %s\n", t.comment)
		}
		fmt.Printf("  Linhas: %d | Tamanho: %s\n", t.rowCount, formatBytes(t.sizeBytes))
		if len(t.primaryKey) > 0 {
			fmt.Printf("  PK: (%s)\n", strings.Join(t.primaryKey, ", "))
		}

		fmt.Println("  Colunas:")
		fmt.Printf("    %-28s %-25s %8s %8s %s\n", "Nome", "Tipo", "Nullable", "PK", "Default")
		fmt.Println("    " + strings.Repeat("-", 90))
		for _, c := range t.columns {
			nullable := "NOT NULL"
			if c.isNullable {
				nullable = "NULL"
			}
			pk := ""
			if c.isPrimaryKey {
				pk = "PK"
			}
			def := ""
			if c.defaultValue != nil {
				def = *c.defaultValue
			}
			fmt.Printf("    %-28s %-25s %8s %8s %s\n", c.name, c.dataType, nullable, pk, def)
			if c.comment != "" {
				fmt.Printf("        -> %s\n", c.comment)
			}
		}

		if len(t.foreignKeys) > 0 {
			fmt.Println("  Chaves Estrangeiras:")
			for _, fk := range t.foreignKeys {
				fmt.Printf("    - %s: (%s) -> %s.%s(%s)\n",
					fk.name,
					strings.Join(fk.columns, ", "),
					fk.refSchema, fk.refTable,
					strings.Join(fk.refColumns, ", "))
			}
		}

		if len(t.indexes) > 0 {
			fmt.Println("  Índices:")
			for _, idx := range t.indexes {
				unique := ""
				if idx.unique {
					unique = "[UNIQUE] "
				}
				fmt.Printf("    - %s%s (%s)\n", unique, idx.name, strings.Join(idx.columns, ", "))
			}
		}
	}
}

func formatBytes(b int64) string {
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%d B", b)
	}
	div, exp := int64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(b)/float64(div), "KMGTPE"[exp])
}
