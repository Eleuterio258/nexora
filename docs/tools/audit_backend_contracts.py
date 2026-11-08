"""Inventário e candidatos a divergências SQL, sem executar a aplicação ou ligar à BD.

Uso: python docs/tools/audit_backend_contracts.py --output docs/audit-backend-contracts.json
Análise lexical limitada: os candidatos exigem leitura humana das migrações,
defaults/triggers e rotas. Não calcula cobertura nem prova explorabilidade.
"""
import argparse
import json
import re
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    backend = root / "backend"
    baseline = backend / "migrations/20260724080001_baseline_schema.up.sql"
    source = baseline.read_text(encoding="utf-8-sig")
    tables = {}
    required = {}
    for match in re.finditer(r"CREATE TABLE IF NOT EXISTS ([\w.]+) \(\n(.*?)\n\);", source, re.S):
        columns, mandatory = set(), set()
        for line in match[2].splitlines():
            column = re.match(r"\s+(\w+)\s+(.+)", line)
            if not column or column[1] == "CONSTRAINT":
                continue
            columns.add(column[1])
            if column[1] != "id" and "NOT NULL" in column[2] and not any(x in column[2] for x in ("DEFAULT", "GENERATED")):
                mandatory.add(column[1])
        tables[match[1]], required[match[1]] = columns, mandatory
    active = sorted((backend / "migrations").glob("*.up.sql"))
    for migration in active:
        text = migration.read_text(encoding="utf-8-sig")
        for statement in re.finditer(r"ALTER TABLE\s+(?:IF EXISTS\s+)?([\w.]+)\s+([^;]+);", text, re.I):
            if statement[1] not in tables:
                continue
            for column in re.finditer(r"ADD COLUMN\s+(?:IF NOT EXISTS\s+)?(\w+)", statement[2], re.I):
                tables[statement[1]].add(column[1])
            for column in re.finditer(r"ALTER COLUMN\s+(\w+)\s+DROP NOT NULL", statement[2], re.I):
                required[statement[1]].discard(column[1])
    files = sorted(f for f in backend.rglob("*.go") if "third_party" not in f.parts and ".cache" not in f.parts)
    candidates, inventory, modules = [], [], []
    router = (backend / "internal/router/router.go").read_text(encoding="utf-8-sig")
    for file in files:
        text = file.read_text(encoding="utf-8-sig")
        inventory.append({"path": file.relative_to(root).as_posix(), "lines": len(text.splitlines()), "test": file.name.endswith("_test.go")})
        if file.name.endswith("_test.go"):
            continue
        for match in re.finditer(r"INSERT INTO\s+([\w.]+)\s*\(([^)]+)\)", text, re.I):
            names = [name for name in tables if name == match[1] or ("." not in match[1] and name.rsplit(".", 1)[-1] == match[1])]
            if len(names) != 1:
                continue
            table = names[0]
            fields = {field.strip() for field in match[2].split(",")}
            unknown = sorted(fields - tables[table])
            missing = sorted(required[table] - fields)
            if unknown or missing:
                enclosing = re.findall(r"(?m)^func\s+.*?\s+(\w+)\(", text[:match.start()])
                function = enclosing[-1] if enclosing else None
                candidates.append({"path": file.relative_to(root).as_posix(), "line": text[:match.start()].count("\n") + 1, "table": table, "columns_not_found": unknown, "mandatory_columns_omitted": missing, "function_guess": function, "handler_name_in_router": bool(function and re.search(r"\." + re.escape(function) + r"\b", router))})
    for directory in sorted((backend / "internal/modules").iterdir()):
        if not directory.is_dir():
            continue
        entries = [entry for entry in inventory if entry["path"].startswith("backend/internal/modules/" + directory.name + "/")]
        modules.append({"module": directory.name, "go_files": len(entries), "test_files": sum(entry["test"] for entry in entries), "lines": sum(entry["lines"] for entry in entries)})
    report = {
        "scope": "Código próprio Go; baseline e ALTER COLUMN lexicais em migrações ativas; nenhuma ligação à BD.",
        "limitations": "Não é parser SQL/Go completo. DO dinâmico, ALTER não reconhecido, schemas reais, triggers e wrappers podem alterar o resultado. Uma correspondência de nome no router não prova alcance nem permissões.",
        "go_files": len(files), "test_files": sum(entry["test"] for entry in inventory),
        "modules": modules, "active_migrations": [file.name for file in active],
        "missing_down": [file.name for file in active if not file.with_name(file.name.replace(".up.sql", ".down.sql")).exists()],
        "sql_contract_candidates": candidates, "files": inventory,
    }
    output = args.output if args.output.is_absolute() else root / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"go_files": len(files), "modules": len(modules), "candidates": len(candidates), "output": str(output)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
