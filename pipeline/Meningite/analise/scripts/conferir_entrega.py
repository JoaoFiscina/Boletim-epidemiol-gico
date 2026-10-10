"""Conferência offline, selo e espelho público explícito da entrega analítica.

Não baixa dados, executa R, concede aceite visual ou publica no Git.
"""
import argparse
import ast
import csv
import hashlib
import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote


BASES = {
    "sinan_estratos_anuais": 242,
    "sinan_mensal": 132,
    "populacao": 242,
    "sih": 572,
    "sim": 143,
    "pni": 44,
}
FIGURAS = ["F01_evolucao_anual", "F02_perfil_sexo_idade",
           "F03_distribuicao_mensal", "F04_classificacao_etiologica",
           "F05_internacoes_disponiveis", "F06_cobertura_vacinal_registrada"]
R_SCRIPTS = ["executar_etapa.R", "preparar_sinan_populacao.R",
             "preparar_complementos.R", "gerar_descritivos.R", "gerar_graficos.R"]


def ler_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def escrever_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def sha(path):
    with path.open("rb") as stream:
        h = hashlib.sha256()
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
        return h.hexdigest()


def linhas(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream, delimiter=";"))


def info(path, raiz):
    return {"caminho": path.relative_to(raiz).as_posix(),
            "bytes": path.stat().st_size, "sha256": sha(path)}


def publicos(raiz):
    a = raiz / "analise"
    rels = ["README.md", "configuracao.json", "scripts/conferir_entrega.py"]
    rels += ["scripts/" + n for n in R_SCRIPTS]
    rels += ["dados/" + n + ".csv" for n in [*BASES, "sinan_categorias_anuais"]]
    rels += ["documentacao/" + n for n in ["COORDENACAO.md", "decisoes.md",
             "dicionario.csv", "fontes.csv", "cobertura.csv",
             "REVISAO_SINAN_POPULACAO.md", "REVISAO_COMPLEMENTOS.md"]]
    rels += ["resultados/RELATORIO_DESCRITIVO.md", "resultados/descritivos.csv"]
    rels += ["resultados/figuras/" + n + ext for n in FIGURAS for ext in [".png", ".pdf"]]
    rels += ["controle/" + n for n in ["validacao.json", "QA_VISUAL.json",
             "VERIFICACAO_ENTREGA.json", "manifesto.json"]]
    # Operação de aquisição documentada: código e metadados, nunca HTML brutos.
    b = "trabalho/complementos/"
    rels += [b + "scripts/" + n for n in ["_tabnet_complementos.py", "retomar_seletivo.py",
             "coletor_sih_local.py", "coletor_pni_local.py"]]
    rels += [b + "aquisicao/" + n for n in ["requisicoes.json", "RESULTADO_RETOMADA.json"]]
    paths = [a / p for p in rels]
    # Respostas tratadas/controles de proveniência desta operação, com recorte explícito.
    for sub, ext in [("dados/tratados/retomada_20261010", ".csv"),
                     ("metadados/retomada_20261010", ".json")]:
        paths += sorted((a / b / sub).glob("*" + ext))
    for path in paths:
        assert path.is_file(), f"Arquivo público obrigatório ausente: {path}"
        assert path.suffix.lower() not in {".rds", ".dbc", ".zip", ".dbf", ".html"}
        assert "brutos" not in path.parts and "casos_minimos" not in path.name
    return paths


def conferir_manual(repo):
    arquivos = [p for p in repo.rglob("*") if p.is_file() and ".git" not in p.parts]
    for path in arquivos:
        if path.suffix == ".json":
            ler_json(path)
        if path.suffix == ".py":
            ast.parse(path.read_text(encoding="utf-8-sig"), filename=str(path))
        if path.suffix == ".md":
            txt = path.read_text(encoding="utf-8-sig")
            for match in re.finditer(r"\[[^\]]*\]\((<[^>]+>|[^)]+)\)", txt):
                link = match.group(1).strip().strip("<>")
                if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*://", link) or link.startswith("#"):
                    continue
                link = unquote(link.split("#", 1)[0])
                link = re.sub(r":\d+$", "", link)
                if link:
                    assert (path.parent / link).exists(), f"Link ausente em {path}: {link}"
    return {"arquivos_json": sum(p.suffix == ".json" for p in arquivos),
            "scripts_python": sum(p.suffix == ".py" for p in arquivos),
            "documentos_markdown": sum(p.suffix == ".md" for p in arquivos)}


def historico(raiz, repo):
    old = ler_json(repo / "pipeline/Meningite/manifesto_portabilidade.json")
    for row in old["arquivos"]:
        for base in [raiz, repo / "pipeline/Meningite"]:
            path = base / row["caminho"].replace("\\", "/")
            assert sha(path) == row["sha256"] and path.stat().st_size == row["bytes"], \
                f"Snapshot 09/10 alterado: {path}"
    return len(old["arquivos"])


def conferir(raiz):
    a = raiz / "analise"
    config = ler_json(a / "configuracao.json")
    assert sha(raiz / config["fonte_pacote"]) == config["fonte_pacote_sha256"]
    v = ler_json(a / "controle/validacao.json")
    assert v["status"] == "aprovado" and v["controles"] == v["aprovados"] == 352
    assert len(v["testes"]) == 352 and all(r["aprovado"] for r in v["testes"])
    assert len(list((a / "dados").glob("*.csv"))) == 7
    contagens = {}
    for nome in [*BASES, "sinan_categorias_anuais"]:
        records = linhas(a / "dados" / (nome + ".csv"))
        assert records, f"Base vazia: {nome}"
        if nome in BASES:
            assert len(records) == BASES[nome], nome
        contagens[nome] = len(records)
    assert sum(int(r["n"]) for r in linhas(a / "dados/sinan_mensal.csv")) == 1976
    assert sum(int(r["n"]) for r in linhas(a / "dados/sinan_estratos_anuais.csv")) == 1975
    pni = linhas(a / "dados/pni.csv")
    assert sum(bool(r["cobertura_percentual"]) for r in pni) == 17
    assert sum(not r["cobertura_percentual"] for r in pni) == 27
    for row in linhas(a / "documentacao/fontes.csv"):
        rel = row["caminho"].replace("\\", "/")
        path = Path(rel) if Path(rel).is_absolute() else raiz / rel
        if not path.exists() and rel.startswith("Meningite/"):
            path = raiz.parent / rel
        assert path.exists() and sha(path) == row["sha256"], f"Fonte divergente: {rel}"
        if row["bytes"]:
            assert path.stat().st_size == int(float(row["bytes"]))
    qa = ler_json(a / "controle/QA_VISUAL.json")
    assert qa["status"] == "aprovado" and len(qa["figuras"]) == 6
    assert {r["figura"] for r in qa["figuras"]} == set(FIGURAS)
    for row in qa["figuras"]:
        assert row["png_inspecionado"] and row["pdf_renderizado_inspecionado"]
        for ext in ["png", "pdf"]:
            assert sha(a / row[ext]["caminho"]) == row[ext]["sha256"], \
                f"Figura mudou após o QA: {row['figura']} ({ext})"
    ledger = ler_json(a / "trabalho/complementos/aquisicao/requisicoes.json")
    counts = {s: sum(r["metodo"] == "POST" and r["sistema"] == s for r in ledger)
              for s in ["SIH", "PNI"]}
    assert counts == {"SIH": 9, "PNI": 2}
    assert sum(r["metodo"] == "GET" for r in ledger) == 2
    repo = raiz.parent / "Boletim epidemiológico"
    old = historico(raiz, repo) if repo.exists() else None
    return {"status": "aprovado", "fonte_congelada_preservada": True,
            "controles_preparacao_aprovados": 352, "linhas_csv": contagens,
            "qa_visual_arquivos_compativeis": 12, "fontes_sha256_conferidas": True,
            "sih_post": counts["SIH"], "pni_post": counts["PNI"],
            "snapshot_09_10_arquivos_preservados_em_duas_raizes": old,
            "limite": "Integridade da entrega; não validação clínica ou aceite de nova figura."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("raiz", type=Path)
    parser.add_argument("--selar", action="store_true")
    parser.add_argument("--sincronizar", action="store_true")
    args = parser.parse_args()
    # absolute() não consulta ancestrais protegidos no sandbox Windows.
    # O inventário abaixo verifica existência, tamanhos e hashes dos alvos.
    raiz = args.raiz.absolute()
    assert raiz.is_dir(), "Raiz do projeto ausente."
    a = raiz / "analise"
    result = conferir(raiz)
    manifest_path = a / "controle/manifesto.json"
    manifest = ler_json(manifest_path)
    # Selo não altera o RDS aceito nem cria um novo aceite de figuras.
    rds = a / "meningites_salvador_analitica.rds"
    anterior = next(r for r in manifest["arquivos"] if r["caminho"].endswith("meningites_salvador_analitica.rds"))
    assert sha(rds) == anterior["sha256"], "RDS mudou: exige nova preparação/revisão."
    if args.selar:
        result["gerado_utc"] = datetime.now(timezone.utc).isoformat()
        escrever_json(a / "controle/VERIFICACAO_ENTREGA.json", result)
        paths = [p for p in publicos(raiz) if p != manifest_path]
        paths += [rds, a / "controle/inventario_entradas.json", a / "controle/execucao.log"]
        manifest["arquivos"] = [info(p, raiz) for p in sorted(paths)]
        manifest["selado_utc"] = result["gerado_utc"]
        manifest["inspecao_visual"] = "Concluída: QA_VISUAL.json confere os 12 hashes PNG/PDF."
        manifest["revisoes_independentes"] = {"sinan_populacao": 39, "complementos": 17}
        escrever_json(manifest_path, manifest)
    for row in manifest["arquivos"]:
        path = raiz / row["caminho"]
        assert sha(path) == row["sha256"] and path.stat().st_size == row["bytes"], \
            f"Entrega difere do manifesto: {path}"
    if args.sincronizar:
        repo = raiz.parent / "Boletim epidemiológico"
        destino = repo / "pipeline/Meningite"
        copied = []
        for source in publicos(raiz):
            rel = source.relative_to(raiz)
            target = destino / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            assert sha(source) == sha(target)
            copied.append(info(source, raiz))
        escrever_json(destino / "analise/manifesto_portabilidade.json", {
            "versao": "20261010", "sincronizado_utc": datetime.now(timezone.utc).isoformat(),
            "criterio": "Lista pública explícita; sem brutos/RDS/registros individuais; histórico 09/10 preservado.",
            "arquivos": copied})
        result["copias_publicas_sha256"] = len(copied)
        result["manual"] = conferir_manual(repo)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
