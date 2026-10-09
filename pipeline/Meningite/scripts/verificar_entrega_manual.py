"""Verifica copias, sintaxe e links do manual local; nao consulta rede nem altera dados."""
import argparse
import ast
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
from urllib.parse import unquote

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repositorio", required=True)
    parser.add_argument("--git-index", action="store_true", help="Confere tambem bytes preparados para commit")
    args = parser.parse_args()
    repo = Path(args.repositorio).resolve()
    project = Path(__file__).resolve().parents[1]
    mirror = repo / "pipeline/Meningite"
    manifest = json.loads((mirror / "manifesto_portabilidade.json").read_text(encoding="utf-8-sig"))
    errors = []
    git_exe = shutil.which("git") if args.git_index else None
    if args.git_index and not git_exe:
        errors.append("Git nao encontrado para conferir index")
    for item in manifest["arquivos"]:
        rel = item["caminho"].replace("\\", "/")
        for base in (project, mirror):
            p = base / rel
            if not p.is_file() or sha(p) != item["sha256"] or p.stat().st_size != item["bytes"]:
                errors.append(f"Copia/hash/tamanho divergente: {p}")
        if git_exe:
            staged = subprocess.run([git_exe,"-c",f"safe.directory={repo.as_posix()}","-C",str(repo),
                "show",":pipeline/Meningite/"+rel],capture_output=True)
            if staged.returncode or hashlib.sha256(staged.stdout).hexdigest()!=item["sha256"]:
                errors.append(f"Bytes do index Git divergentes: {rel}")
    json_count = python_count = md_count = 0
    for p in repo.rglob("*"):
        if not p.is_file() or ".git" in p.relative_to(repo).parts:
            continue
        rel = p.relative_to(repo)
        if "brutos" in rel.parts or p.suffix.lower() in (".dbc", ".dbf", ".rds", ".zip", ".html", ".rdata"):
            errors.append(f"Arquivo fora do contrato de entrega: {rel}")
        try:
            if p.suffix == ".json":
                json.loads(p.read_text(encoding="utf-8-sig")); json_count += 1
            elif p.suffix == ".py":
                ast.parse(p.read_text(encoding="utf-8-sig"), filename=str(p)); python_count += 1
            elif p.suffix == ".md":
                md_count += 1
                for match in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", p.read_text(encoding="utf-8-sig")):
                    target = match.group(1).strip().strip("<>")
                    if target.startswith(("http:", "https:", "#", "app:", "codex:")) or re.match(r"^[A-Za-z]:", target):
                        continue
                    target = unquote(target.split("#", 1)[0])
                    if target and not (p.parent / target).exists():
                        errors.append(f"Link local ausente: {rel} -> {target}")
        except Exception as exc:
            errors.append(f"Leitura/sintaxe: {rel}: {exc}")
    result = {"versao": manifest["versao"], "copias_sha_tamanho": len(manifest["arquivos"]),
        "json_legiveis": json_count, "python_sintaxe": python_count, "markdown_links": md_count,
        "erros": errors, "status": "aprovado" if not errors else "corrigir",
        "git_index_conferido": bool(git_exe),
        "limite": "Integridade e reproducao local; nao auditoria clinica nem acesso aos links web."}
    out = project / "metadados" / f"VERIFICACAO_MANUAL_{manifest['versao']}.json"
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False))
    return 1 if errors else 0

if __name__ == "__main__":
    raise SystemExit(main())
