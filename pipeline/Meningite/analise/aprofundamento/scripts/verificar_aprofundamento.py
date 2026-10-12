"""Confere integridade e espelha somente agregados públicos desta etapa. Sem rede/R.

Uso: python verificar_aprofundamento.py <Meningite> [--selar] [--sincronizar]
O selo exige QA humano com hashes atuais; não concede aceite visual sozinho.
"""
import argparse
import ast
import csv
import hashlib
import importlib.util
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote

sys.dont_write_bytecode = True
FIGS = ["G01_taxas_idade_periodos", "G02_razoes_sexo_idade", "G03_etiologia_idade",
        "G04_criterios_etiologia", "G05_evolucao_limites", "G06_intervalo_notificacao",
        "G07_sazonalidade_exploratoria", "G08_perfis_hospitalares"]
CSV_ROWS = {"cruzamentos_sinan": 20863, "estimativas_e_sensibilidades": 2740}
R_SCRIPTS = ["executar_aprofundamento.R", "preparar_cruzamentos.R",
             "preparar_auditoria_complementos.R", "ajustar_modelos.R", "gerar_figuras_aprofundadas.R"]


def sha(p):
    with p.open("rb") as f:
        h = hashlib.sha256()
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
        return h.hexdigest()


def read_json(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))


def write_json(p, x):
    p.write_text(json.dumps(x, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def info(p, root):
    return {"caminho": p.relative_to(root).as_posix(), "bytes": p.stat().st_size, "sha256": sha(p)}


def publicos(a, omitir_manifesto=False):
    paths = [a / "README.md", a / "configuracao.json"]
    paths += [a / "scripts" / n for n in R_SCRIPTS + ["verificar_aprofundamento.py"]]
    paths += [a / "dados" / (n + ".csv") for n in CSV_ROWS]
    paths += [a / "documentacao" / n for n in ["COORDENACAO.md", "dicionario_e_decisoes.json",
               "proveniencia.json", "REVISAO_SINAN_MODELOS.md", "REVISAO_COMPLEMENTOS.md",
               "REVISAO_MODELOS_PRELIMINAR.md"]]
    paths += [a / "controle" / n for n in ["validacao.json", "QA_VISUAL.json", "VERIFICACAO_ENTREGA.json", "manifesto.json"]]
    paths += [a / "resultados/RELATORIO_APROFUNDADO.md"]
    paths += [a / "resultados/figuras" / (n + ".png") for n in FIGS]
    paths += [a / "resultados/figuras/CADERNO_GRAFICOS_APROFUNDADOS.pdf"]
    if omitir_manifesto:
        paths = [p for p in paths if p.name != "manifesto.json"]
    for p in paths:
        assert p.is_file(), f"Ausente: {p}"
        assert p.suffix.lower() not in {".rds", ".dbc", ".zip", ".dbf", ".html"}
        assert "brutos" not in p.parts and "casos_minimos" not in p.name
    return sorted(paths)


def verificar(raiz):
    a = raiz / "analise/aprofundamento"
    config = read_json(a / "configuracao.json")
    assert config["modo"] == "offline" and config["coletar"] is False
    assert sha(raiz / config["fonte_rds"]) == config["fonte_sha256"]
    v = read_json(a / "controle/validacao.json")
    assert v["total"] == 3447 and v["aprovados"] == v["total"]
    assert all(x["aprovado"] for x in v["controles"] if x["bloqueante"])
    assert v["csv_roundtrip"] and v["rds_roundtrip"] and v["fonte_inalterada"]
    counts = {}
    for n, expected in CSV_ROWS.items():
        with (a / "dados" / (n + ".csv")).open(encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f, delimiter=";")
            assert {"tabela", "medida", "valor", "codigo_municipio", "versao_analitica"}.issubset(reader.fieldnames)
            assert not {"chave_tecnica", "hash_tecnico", "indice_linha_analitica", "ATE_INTERN"}.intersection(reader.fieldnames)
            rows = list(reader)
        assert len(rows) == expected
        assert all(x["codigo_municipio"] == "292740" and x["versao_analitica"] == "20261012" for x in rows)
        if n == "estimativas_e_sensibilidades":
            rr = [x for x in rows if x["modelo"] == "taxas_principal" and x["termo"] == "sexoM"]
            assert len(rr) == 1 and 1.48 < float(rr[0]["valor"]) < 1.50
            assert float(rr[0]["ic_inferior"]) < float(rr[0]["valor"]) < float(rr[0]["ic_superior"])
            std = [x for x in rows if x["tabela"] == "padronizadas_periodos" and x["medida"] == "taxa"]
            assert len(std) == 3
            na = [x for x in rows if x["tabela"] == "parecer_campos" and x["campo"] == "ANT_IMUNO"]
            assert len(na) == 1 and float(na[0]["valor"]) == 1
        counts[n] = len(rows)
    qa = read_json(a / "controle/QA_VISUAL.json")
    assert qa["status"] == "inspecionado_aprovado" and qa["png_inspecionados"] == 8 and qa["paginas_pdf_inspecionadas"] == 8
    for row in qa["arquivos"]:
        assert sha(a / row["caminho"]) == row["sha256"], f"Mudou após QA: {row['caminho']}"
    assert len(qa["arquivos"]) == 9
    for p in a.glob("scripts/*.py"):
        ast.parse(p.read_text(encoding="utf-8-sig"), filename=str(p))
    # Conferência anterior em leitura, sem --selar: protege dados e históricos.
    oldscript = raiz / "analise/scripts/conferir_entrega.py"
    spec = importlib.util.spec_from_file_location("verificador_baseline", oldscript)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    anterior = mod.conferir(raiz)
    oldmanifest = read_json(raiz / "analise/controle/manifesto.json")
    for row in oldmanifest["arquivos"]:
        p = raiz / row["caminho"]
        assert sha(p) == row["sha256"] and p.stat().st_size == row["bytes"]
    repo = raiz.parent / "Boletim epidemiológico"
    espelho = read_json(repo / "pipeline/Meningite/analise/manifesto_portabilidade.json")
    assert len(espelho["arquivos"]) == 58
    for row in espelho["arquivos"]:
        for p in [raiz / row["caminho"], repo / "pipeline/Meningite" / row["caminho"]]:
            assert sha(p) == row["sha256"] and p.stat().st_size == row["bytes"]
    return {"status": "aprovado", "controles_integrados": 3447, "csv_linhas": counts,
            "png_qa": 8, "paginas_pdf_qa": 8, "fonte_preservada": True,
            "baseline_58_publicos_preservados": True, "historico_baseline": anterior,
            "limite": "Integridade e correspondencia ao QA; não atesta eficácia/causalidade/validade clínica"}


def main():
    pa = argparse.ArgumentParser(description=__doc__)
    pa.add_argument("raiz", type=Path)
    pa.add_argument("--selar", action="store_true")
    pa.add_argument("--sincronizar", action="store_true")
    args = pa.parse_args()
    raiz = args.raiz.absolute()
    a = raiz / "analise/aprofundamento"
    result = verificar(raiz)
    if args.selar:
        result["gerado_utc"] = datetime.now(timezone.utc).isoformat()
        write_json(a / "controle/VERIFICACAO_ENTREGA.json", result)
        # Manifesto não inclui seu próprio hash; evita circularidade.
        paths = publicos(a, omitir_manifesto=True)
        paths += [a / "meningites_aprofundamento.rds"]
        write_json(a / "controle/manifesto.json", {"versao": "20261012", "gerado_utc": result["gerado_utc"],
            "arquivos": [info(p, raiz) for p in sorted(paths)],
            "criterio": "Lista explicita; RDS agregado local excluido do espelho Git"})
    manifest = read_json(a / "controle/manifesto.json")
    for row in manifest["arquivos"]:
        p = raiz / row["caminho"]
        assert sha(p) == row["sha256"] and p.stat().st_size == row["bytes"], f"Diverge: {p}"
    if args.sincronizar:
        repo = raiz.parent / "Boletim epidemiológico"
        dest = repo / "pipeline/Meningite/analise/aprofundamento"
        copied = []
        for p in publicos(a):
            target = dest / p.relative_to(a)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(p, target)
            assert sha(p) == sha(target)
            copied.append(info(p, raiz))
        write_json(dest / "manifesto_portabilidade.json", {"versao": "20261012", "arquivos": copied,
            "criterio": "Sem RDS, fontes individuais, brutos, candidatos e previews"})
        result["copias_publicas"] = len(copied)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
