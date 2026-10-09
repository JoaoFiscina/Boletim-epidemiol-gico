"""Coleta retomável e limitada de MENIBR14-26, via catálogo/ZIP HTTPS oficiais.

Por padrão só inventaria. --baixar solicita apenas partições ainda não conferidas.
Não modifica piloto anterior, não instala dependências, não exporta registros pessoais.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import io
import json
from pathlib import Path
import re
import ssl
import sys
from urllib.parse import urlencode, urlparse
from urllib.request import Request, urlopen
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CATALOG_URL = "https://datasus.saude.gov.br/wp-content/ftp.php"
DOWNLOAD_URL = "https://datasus.saude.gov.br/wp-content/download.php"
YEAR_FILES = {f"MENIBR{year % 100:02d}.dbc": year for year in range(2014, 2027)}


def now():
    return datetime.now(timezone.utc).isoformat()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def dump(path, obj):
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")
    temp.replace(path)


class Transport:
    def __init__(self, maximum):
        self.maximum = maximum
        self.bytes = 0
        self.requests = []

    def fetch(self, url, data=None, per_request=30 * 1024 * 1024):
        parsed = urlparse(url)
        if parsed.scheme != "https" or parsed.hostname != "datasus.saude.gov.br":
            raise ValueError("Só é permitido HTTPS no host oficial DATASUS")
        errors = []
        for attempt in (1, 2):
            item = {"url": url, "metodo": "POST" if data else "GET", "inicio_utc": now(), "tentativa": attempt}
            self.requests.append(item)
            try:
                req = Request(url, data=data, headers={
                    "User-Agent": "Pesquisa-Meningites-Salvador/2.0",
                    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                })
                chunks, length = [], 0
                with urlopen(req, timeout=40, context=ssl.create_default_context()) as response:
                    item["status_http"] = response.status
                    final = urlparse(response.geturl())
                    if final.scheme != "https" or final.hostname != "datasus.saude.gov.br":
                        raise ValueError("Redirecionamento fora do host oficial")
                    while True:
                        block = response.read(65536)
                        if not block:
                            break
                        self.bytes += len(block)
                        length += len(block)
                        if self.bytes > self.maximum or length > per_request:
                            raise ValueError("Teto de bytes atingido; retomar apenas pendentes")
                        chunks.append(block)
                item.update(status="obtido", bytes=length, url_final=response.geturl(), fim_utc=now())
                return b"".join(chunks)
            except Exception as exc:
                if getattr(exc, "code", None) is not None:
                    item["status_http"] = exc.code
                item.update(status="falha", erro=f"{type(exc).__name__}: {exc}", fim_utc=now())
                errors.append(item["erro"])
                if self.bytes >= self.maximum:
                    break
        raise RuntimeError(" | ".join(errors))


def flatten_urls(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, list):
        for v in value:
            yield from flatten_urls(v)
    else:
        raise ValueError("Resposta inesperada do serviço ZIP")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--versao", default="20261009")
    parser.add_argument("--baixar", action="store_true")
    parser.add_argument("--lote", type=int, default=3, choices=range(1, 4))
    parser.add_argument("--teto-mb", type=int, default=80)
    args = parser.parse_args()
    if not re.fullmatch(r"\d{8}", args.versao) or not 10 <= args.teto_mb <= 150:
        parser.error("Versão deve ser AAAAMMDD e teto deve estar entre10 e150MB")
    out = ROOT / f"dados/brutos/sinan_br_{args.versao}"
    out.mkdir(parents=True, exist_ok=True)
    registry = out / "manifesto.json"
    catalog_path = out / "catalogo.json"
    contract_path = out / "catalogo.contrato.json"
    previous = json.loads(registry.read_text(encoding="utf-8-sig")) if registry.exists() else {}
    transport = Transport(args.teto_mb * 1024 * 1024)
    manifest = dict(previous)
    manifest.pop("erro", None)  # Erros anteriores continuam no histórico de execuções.
    manifest.update(status="inventariando", iniciado_ou_retomado_utc=now(), versao=args.versao,
        servico_catalogo=CATALOG_URL, servico_zip=DOWNLOAD_URL, script_sha256=sha(Path(__file__).read_bytes()),
        unidade="registros publicos de agravo; pessoas unicas nao demonstradas",
        referencia="ano primeiros sintomas2014-2024; particoes de notificacao2014-2026",
        residencia="Salvador292740", teto_bytes_execucao=transport.maximum,
        limites=["fontes podem ter datas distintas; preservar proveniencia por particao",
                 "arquivo baixado nao implica qualidade ou cobertura epidemiologica validada",
                 "catalogo final/preliminar deve ser preservado; sem concatenar versoes sobrepostas"])
    valid = {}
    try:
        if catalog_path.exists():
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
            if sha(catalog_path.read_bytes()) != contract["sha256_resposta"]:
                raise ValueError("Catálogo local mudou; não reutilizar")
        else:
            fields = [("tipo_arquivo[]", "MENI"), ("modalidade[]", "1"), ("fonte[]", "SINAN"), ("uf[]", "BR")]
            fields += [("ano[]", str(y)) for y in range(2014, 2027)]
            body = urlencode(fields).encode("ascii")
            raw = transport.fetch(CATALOG_URL, body, per_request=2 * 1024 * 1024)
            parsed = json.loads(raw)
            if not isinstance(parsed, list):
                raise ValueError("Catálogo não é uma lista")
            catalog_path.write_bytes(raw)
            dump(contract_path, {"url": CATALOG_URL, "metodo": "POST", "parametros": fields,
                "coletado_utc": now(), "sha256_resposta": sha(raw), "bytes": len(raw)})
        candidates = [x for x in json.loads(catalog_path.read_text(encoding="utf-8-sig")) if x.get("arquivo") in YEAR_FILES]
        grouped = {name: [x for x in candidates if x["arquivo"] == name] for name in YEAR_FILES}
        selected = []
        for name, possibilities in grouped.items():
            finals = [x for x in possibilities if "FINAIS" in x.get("endereco", "").upper()]
            use = finals if finals else possibilities
            if len(use) != 1:
                raise ValueError(f"Catálogo sem seleção unívoca para{name}: {len(use)}opções")
            entry = use[0]
            address = urlparse(entry["endereco"])
            if address.hostname != "ftp.datasus.gov.br" or Path(address.path).name != name:
                raise ValueError("Origem do catálogo inesperada")
            selected.append(entry)
        manifest["arquivos_alvo"] = selected
        manifest["catalogo_sha256"] = sha(catalog_path.read_bytes())
        for entry in previous.get("arquivos", []):
            name = entry["nome_original"]
            expected_catalog = next((x for x in selected if x["arquivo"] == name), None)
            if expected_catalog is None or entry["origem_ftp"] != expected_catalog["endereco"] or entry["modalidade"] != expected_catalog["modalidade"]:
                raise ValueError("Origem/modalidade previamente registrada diverge do catálogo: " + name)
            path = (ROOT / entry["caminho"].replace("\\", "/")).resolve()
            if not path.is_relative_to(ROOT):
                raise ValueError("Caminho registrado fora do projeto")
            if not path.exists() or sha(path.read_bytes()) != entry["sha256"]:
                raise ValueError("Arquivo já registrado não confere: " + entry["caminho"])
            valid[name] = {**entry, "caminho": path.relative_to(ROOT).as_posix()}
        # Não copiar DBCs piloto: referenciá-los com hash e data de extração original.
        pilot = ROOT / "dados/brutos/sinan_br_piloto"
        pilot_path = pilot / "manifesto_piloto.json"
        pilot_manifest = json.loads(pilot_path.read_text(encoding="utf-8-sig")) if pilot_path.exists() else {"arquivos": []}
        for item in pilot_manifest["arquivos"]:
            name = item["nome_original"]
            expected_catalog = next(x for x in selected if x["arquivo"] == name)
            if name in valid or item["origem_ftp"] != expected_catalog["endereco"]:
                continue
            path = pilot / name
            if not path.exists() or sha(path.read_bytes()) != item["sha256"]:
                raise ValueError("Hash piloto não confere: " + name)
            valid[name] = {**item, "caminho": path.relative_to(ROOT).as_posix(), "status": "reaproveitado_hash_conferido",
                           "versao_origem": "piloto20261005", "data_fonte_utc": item["extraido_em_utc"]}
        pending = [x for x in selected if x["arquivo"] not in valid]
        manifest["arquivos"] = list(valid.values())
        manifest["pendentes"] = [x["arquivo"] for x in pending]
        dump(registry, manifest)
        print(f"CATALOGO:{len(selected)} particoes; reaproveitadas:{len(valid)}; pendentes:{len(pending)}", flush=True)
        if not args.baixar:
            manifest["status"] = "catalogo_conferido_coleta_pendente" if pending else "particoes_disponiveis_leitura_pendente"
        else:
            for batch_start in range(0, len(pending), args.lote):
                batch = pending[batch_start:batch_start + args.lote]
                fields = []
                for i, entry in enumerate(batch):
                    fields += [(f"dados[{i}][arquivo]", entry["arquivo"]), (f"dados[{i}][link]", entry["endereco"])]
                stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
                raw = transport.fetch(DOWNLOAD_URL, urlencode(fields).encode("ascii"), per_request=1048576)
                response_name = f"lote_{batch_start}_{stamp}.json"
                (out / response_name).write_bytes(raw)
                dump(out / f"lote_{batch_start}_{stamp}.contrato.json", {"metodo": "POST", "url": DOWNLOAD_URL,
                    "parametros": fields, "sha256_resposta": sha(raw), "em_utc": now()})
                links = list(flatten_urls(json.loads(raw)))
                if not 1 <= len(links) <= len(batch):
                    raise ValueError("Número inesperado de arquivos ZIP")
                for j, url in enumerate(links):
                    content = transport.fetch(url)
                    zip_name = f"lote_{batch_start}_{stamp}_{j}.zip"
                    (out / zip_name).write_bytes(content)
                    manifest.setdefault("zips", []).append({"arquivo": zip_name, "url": url,
                        "bytes": len(content), "sha256": sha(content), "coletado_utc": now()})
                    with zipfile.ZipFile(io.BytesIO(content)) as archive:
                        for entry in batch:
                            name = entry["arquivo"]
                            matches = [x for x in archive.infolist() if Path(x.filename).name.lower() == name.lower()]
                            if not matches:
                                continue
                            if len(matches) != 1 or name in valid or matches[0].file_size > 30 * 1024 * 1024:
                                raise ValueError("Arquivo ZIP ambíguo, duplicado ou excessivo")
                            data = archive.read(matches[0])
                            target = out / name
                            if target.exists() and sha(target.read_bytes()) != sha(data):
                                raise ValueError("Não sobrescrever arquivo diferente sem nova versão")
                            target.write_bytes(data)
                            valid[name] = {"nome_original": name, "ano_particao": YEAR_FILES[name],
                                "caminho": target.relative_to(ROOT).as_posix(), "bytes": len(data), "sha256": sha(data),
                                "origem_ftp": entry["endereco"], "modalidade": entry["modalidade"],
                                "zip": zip_name, "status": "baixado_leitura_pendente", "data_fonte_utc": now()}
                            manifest["arquivos"] = list(valid.values())
                            manifest["pendentes"] = [x["arquivo"] for x in selected if x["arquivo"] not in valid]
                            dump(registry, manifest)
                            print(f"OK {name}:{len(data)}bytes", flush=True)
                absent = [x["arquivo"] for x in batch if x["arquivo"] not in valid]
                if absent:
                    raise ValueError("ZIP não contém todas as partições do lote: " + ",".join(absent))
            manifest["status"] = "13_particoes_disponiveis_leitura_e_validacao_pendentes"
    except Exception as exc:
        manifest.update(status="parcial_ou_falha", erro=f"{type(exc).__name__}: {exc}")
        print(manifest["erro"], flush=True)
    finally:
        manifest["arquivos"] = list(valid.values()) or manifest.get("arquivos", [])
        manifest["pendentes"] = [name for name in YEAR_FILES if name not in valid]
        manifest.setdefault("execucoes", []).append({"em_utc": now(), "bytes_rede": transport.bytes,
            "requests": transport.requests, "modo": "baixar" if args.baixar else "inventariar"})
        manifest["finalizado_utc"] = now()
        dump(registry, manifest)
    print("STATUS:" + manifest["status"], flush=True)
    return 2 if manifest["status"] == "parcial_ou_falha" else 0


if __name__ == "__main__":
    sys.exit(main())
