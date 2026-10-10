"""Coleta versionada SIH/SIM Salvador; 24 POST reais no máximo e teto de 100 MB."""
from pathlib import Path
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.parse import urlencode
from decimal import Decimal
import argparse, csv, hashlib, html, ipaddress, json, re, shutil, subprocess, time
from _tabnet_complementos import Form, parse_html

BASE = Path(__file__).resolve().parents[1]
VERSION = 'complementos_20261009'
RAW = BASE / 'dados' / 'brutos' / VERSION
OUT = BASE / 'dados' / 'tratados' / VERSION
META = BASE / 'metadados' / VERSION
YEARS = list(range(2014, 2025))
MAX_POST, MAX_BYTES = 24, 100 * 1024 * 1024
URLS = {'SIH': 'https://tabnet.datasus.gov.br/cgi/deftohtm.exe?sih/cnv/nrbr.def',
        'SIM': 'https://tabnet.datasus.gov.br/cgi/deftohtm.exe?sim/cnv/obt10ba.def'}
GROUPS = {'A39': 'Infecção meningocócica', 'A87': 'Meningite viral',
          'G00': 'Meningite bacteriana não classif outra parte',
          'G01': 'Meningite em doenças bacters class outr parte',
          'G02': 'Mening em doenç infec/parasit class outr part',
          'G03': 'Mening dev outras causas e causas não especif'}
DOCS = ['https://tabnet.datasus.gov.br/cgi/sih/Morb_geral_loc_res_2008.pdf',
        'https://tabnet.datasus.gov.br/cgi/sim/Mortalidade_Geral_1996_2012.pdf']
LEDGER = META / 'requisicoes.json'
requests = []
TRANSPORT = 'urllib'
RESOLVED_IP = None
CURL_PATH = None
SIH_HTTP = False

def configure(directory=None, version='complementos_20261009', limit=24):
    global BASE, VERSION, RAW, OUT, META, LEDGER, MAX_POST, requests
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]*', version): raise ValueError('Versão inválida: use letras, números, _ e -.')
    if not 1 <= limit <= 100: raise ValueError('Limite de POST deve estar entre 1 e 100.')
    BASE = Path(directory).expanduser().resolve() if directory else Path(__file__).resolve().parents[1]
    VERSION, MAX_POST = version, limit
    RAW, OUT, META = BASE / 'dados' / 'brutos' / VERSION, BASE / 'dados' / 'tratados' / VERSION, BASE / 'metadados' / VERSION
    for folder in (RAW, OUT, META): folder.mkdir(parents=True, exist_ok=True)
    LEDGER = META / 'requisicoes.json'
    requests = json.loads(LEDGER.read_text(encoding='utf-8')) if LEDGER.exists() else []

def now(): return datetime.now().astimezone().isoformat(timespec='seconds')
def sha(data): return hashlib.sha256(data).hexdigest()
def dump(path, obj): path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding='utf-8')
def clean(data): return re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', ' ', data.decode('latin1')))).strip()
def plain_label(value): return re.sub(r'^[.\s]+', '', value).strip()
def csv_out(path, records):
    if not records: return
    with path.open('w', encoding='utf-8-sig', newline='') as stream:
        w = csv.DictWriter(stream, fieldnames=list(records[0]), delimiter=';'); w.writeheader(); w.writerows(records)
def numeric(value, zero, currency=False):
    if value == '-' and zero: return Decimal(0) if currency else 0
    if value in ('', '-', '..', '...', '*'): return None
    if currency:
        if not re.fullmatch(r'[0-9.]+(?:,[0-9]+)?', value): raise ValueError('Valor financeiro desconhecido: ' + value)
        return Decimal(value.replace('.', '').replace(',', '.'))
    if not re.fullmatch(r'[0-9.]+', value): raise ValueError('Contagem desconhecida: ' + value)
    return int(value.replace('.', ''))
def total(table): return next(dict(zip(table['cabecalho'], r)) for r in table['linhas'] if r[0].casefold() == 'total')
def size_used(): return sum(p.stat().st_size for p in RAW.rglob('*') if p.is_file())

def fetch(url, body=None):
    method = 'POST' if body is not None else 'GET'
    for attempt in range(2):
        if method == 'POST' and sum(r['metodo'] == 'POST' for r in requests) >= MAX_POST:
            raise RuntimeError('Teto de ' + str(MAX_POST) + ' POST atingido; item permanece pendente.')
        if size_used() >= MAX_BYTES: raise RuntimeError('Teto de 100 MB atingido.')
        record = {'em': now(), 'url': url, 'metodo': method, 'tentativa': attempt + 1, 'status': 'iniciado'}
        if body is not None: record['sha256_body'] = sha(body)
        requests.append(record); dump(LEDGER, requests)
        try:
            headers = {'User-Agent': 'Pesquisa-Meningites-Salvador/20261009'}
            if body is not None: headers['Content-Type'] = 'application/x-www-form-urlencoded'
            if TRANSPORT == 'curl':
                response_path, payload_path = RAW / '_http_response.tmp', META / '_http_payload.tmp'
                executable = CURL_PATH or shutil.which('curl.exe') or shutil.which('curl')
                if not executable: raise RuntimeError('curl não encontrado; instale-o ou use --transporte urllib.')
                args = [executable, '--silent', '--show-error', '--fail',
                        '--connect-timeout', '12', '--max-time', '35', '--output', str(response_path)]
                if RESOLVED_IP:
                    port = '80' if url.startswith('http://') else '443'
                    args += ['--resolve', 'tabnet.datasus.gov.br:' + port + ':' + RESOLVED_IP]
                    record['ip_dns_observado'] = RESOLVED_IP
                if body is not None:
                    payload_path.write_bytes(body)
                    args += ['--request', 'POST', '--header', 'Content-Type: application/x-www-form-urlencoded',
                             '--data-binary', '@' + str(payload_path)]
                args.append(url)
                try:
                    run = subprocess.run(args, capture_output=True, timeout=45)
                    if run.returncode: raise RuntimeError('curl ' + str(run.returncode) + ': ' + run.stderr.decode(errors='replace').strip())
                    data, final = response_path.read_bytes(), url
                finally:
                    response_path.unlink(missing_ok=True); payload_path.unlink(missing_ok=True)
                record['transporte'] = 'curl, TLS verificado quando HTTPS'
            else:
                with urlopen(Request(url, data=body, headers=headers), timeout=35) as response:
                    data, final = response.read(MAX_BYTES - size_used() + 1), response.geturl()
            if len(data) + size_used() > MAX_BYTES: raise RuntimeError('Resposta ultrapassa teto de bytes.')
            record.update({'status': 'ok', 'bytes': len(data), 'url_final': final, 'sha256': sha(data)})
            dump(LEDGER, requests); return data, final
        except Exception as exc:
            record.update({'status': 'erro', 'erro': type(exc).__name__ + ': ' + str(exc)}); dump(LEDGER, requests)
            if attempt == 1 or '10013' in str(exc): raise
            time.sleep(2)

def inspect(system):
    current = RAW / (system + '_formulario_atual.html')
    path = current if current.exists() else RAW / (system + '_formulario.html')
    old_path = META / (system + '_formulario.json')
    if not path.exists():
        data, final = fetch(URLS[system]); path.write_bytes(data)
        observed = now()
    else:
        data, final = path.read_bytes(), URLS[system]
        observed = json.loads(old_path.read_text(encoding='utf-8')).get('coletado_em', now()) if old_path.exists() else now()
    form = Form(data, final)
    relevant = ['Linha', 'Coluna', 'Incremento', 'Arquivos']
    if system == 'SIH':
        field = 'SLista_Morb__CID-10'
        wanted = [o for o in form.selects[field] if plain_label(o['label']) in GROUPS.values()]
        assert len(wanted) == 6, wanted
        geog = next(k for k, opts in form.selects.items() if k.startswith('S') and any('292740 Salvador' == o['label'] for o in opts))
        selected_geo = next(o for o in form.selects[geog] if o['label'] == '292740 Salvador')
    else:
        field = 'SCategoria_CID-10'
        wanted = [o for o in form.selects[field] if o['label'][:3] in GROUPS]
        assert len(wanted) == 6
        geog = next(k for k, opts in form.selects.items() if k.startswith('S') and any('292740 SALVADOR' == o['label'] for o in opts))
        selected_geo = next(o for o in form.selects[geog] if o['label'] == '292740 SALVADOR')
    prior = json.loads(old_path.read_text(encoding='utf-8')) if old_path.exists() else {}
    live_refresh = current.exists()
    if live_refresh: observed = datetime.fromtimestamp(current.stat().st_mtime).astimezone().isoformat(timespec='seconds')
    meta = {'sistema': system, 'url': URLS[system], 'endpoint': form.endpoint(), 'sha256_html': sha(data),
            'bytes': len(data), 'coletado_em': observed, 'reconferido_em': now(),
            'selects': {k: form.selects[k] for k in relevant}, 'campo_diagnostico': field,
            'diagnosticos_selecionados': wanted, 'campo_geografico': geog, 'categoria_geografica': selected_geo,
            'links_documentacao': [l for l in form.links if '.pdf' in l], 'notas_formulario': clean(data)[-3000:],
            'origem_formulario': str(path.relative_to(BASE)) if live_refresh else prior.get('origem_formulario', 'coleta_rede_20261009'),
            'atualizacao_formulario_pendente': False if live_refresh else prior.get('atualizacao_formulario_pendente', False),
            'motivo_reuso_formulario': None if live_refresh else prior.get('motivo_reuso_formulario'),
            'url_coleta_formulario': prior.get('url_coleta_formulario', URLS[system])}
    dump(old_path, meta)
    print(system + ': formulário real conferido; diagnósticos=' + str([(o['value'], o['label']) for o in wanted]), flush=True)
    return form, meta

def job_specs(forms):
    sih, sm = forms['SIH']; sim, mm = forms['SIM']
    monthly = [o['value'] for o in sih.selects['Arquivos'] if re.fullmatch(r'nrbr(?:1[4-9]|2[0-4])(?:0[1-9]|1[0-2])\.dbf', o['value'])]
    assert len(monthly) == len(set(monthly)) == 132
    yearly = [o['value'] for o in sim.selects['Arquivos'] if re.fullmatch(r'201[4-9]|202[0-4]', o['label'])]
    assert len(yearly) == 11
    sbase = {'Coluna': sih.option_value('Coluna', 'Ano processamento'), 'Arquivos': monthly,
             sm['campo_geografico']: sm['categoria_geografica']['value'],
             sm['campo_diagnostico']: [o['value'] for o in sm['diagnosticos_selecionados']]}
    mbase = {'Linha': sim.option_value('Linha', 'Faixa Etária'), 'Coluna': sim.option_value('Coluna', 'Ano do Óbito'),
             'Incremento': sim.option_value('Incremento', 'Óbitos p/Residênc'), 'Arquivos': yearly,
             mm['campo_geografico']: mm['categoria_geografica']['value'],
             mm['campo_diagnostico']: [o['value'] for o in mm['diagnosticos_selecionados']]}
    specs = [{'id': 'SIM_idade_ano_G00_G03_A39_A87', 'sistema': 'SIM', 'dimensao': 'idade',
              'medida': 'obitos_causa_basica', 'unidade': 'obitos', 'grupo': 'conjunto_filtrado', 'selecao': mbase}]
    for metric, label, unit in [('internacoes', 'Internações', 'episodios_aproximados'),
                                ('obitos', 'Óbitos', 'altas_por_obito'),
                                ('dias_permanencia', 'Dias permanência', 'dias_AIH_aprovadas'),
                                ('valor_total', 'Valor total', 'BRL_aprovados_nominais')]:
        specs.append({'id': 'SIH_' + metric + '_diagnostico_ano', 'sistema': 'SIH', 'dimensao': 'diagnostico',
                      'medida': metric, 'unidade': unit, 'grupo': 'grupos_separados',
                      'selecao': {**sbase, 'Linha': sih.option_value('Linha', 'Lista Morb  CID-10'),
                                  'Incremento': sih.option_value('Incremento', label)}})
    for code in ('G00', 'A87', 'A39'):
        option = next(o for o in sm['diagnosticos_selecionados'] if plain_label(o['label']) == GROUPS[code])
        for axis, label in [('sexo', 'Sexo'), ('idade', 'Faixa Etária 1')]:
            specs.append({'id': 'SIH_' + code + '_' + axis + '_ano', 'sistema': 'SIH', 'dimensao': axis,
                          'medida': 'internacoes', 'unidade': 'episodios_aproximados', 'grupo': code,
                          'selecao': {**sbase, sm['campo_diagnostico']: option['value'],
                                      'Linha': sih.option_value('Linha', label), 'Incremento': sih.option_value('Incremento', 'Internações')}})
    assert len(specs) == 11
    return specs

def collect_one(spec, form, contract, collect):
    pairs = form.pairs(spec['selecao'])
    endpoint = form.endpoint().replace('https://', 'http://', 1) if SIH_HTTP and spec['sistema'] == 'SIH' else form.endpoint()
    path = RAW / (spec['id'] + '.html')
    meta_path = META / (spec['id'] + '.json')
    old_meta = json.loads(meta_path.read_text(encoding='utf-8')) if meta_path.exists() else {}
    query = {'id': spec['id'], 'sistema': spec['sistema'], 'metodo': 'POST', 'endpoint': old_meta.get('endpoint', endpoint) if path.exists() else endpoint,
             'url_formulario': form.url, 'sha256_formulario': contract['sha256_html'], 'parametros': pairs,
             'medida': spec['medida'], 'unidade': spec['unidade'], 'dimensao': spec['dimensao'], 'grupo': spec['grupo'],
             'municipio_residencia': '292740', 'periodo_solicitado': [2014, 2024],
             'referencia_tempo': 'ano_processamento' if spec['sistema'] == 'SIH' else 'ano_obito',
             'arquivo_html': str(path.relative_to(BASE)), 'reconferido_em': now()}
    try:
        if not path.exists():
            if not collect:
                digest = sha(urlencode(pairs, encoding='latin1').encode('ascii'))
                attempts = [r for r in requests if r['metodo'] == 'POST' and r.get('sha256_body') == digest]
                errors = [r['erro'] for r in attempts if r.get('erro')]
                query.update({'status': 'pendente', 'tentativas_registradas': len(attempts),
                              'erro': errors[-1] if errors else ('Teto acumulado atingido antes da consulta.' if sum(r['metodo'] == 'POST' for r in requests) >= MAX_POST else 'Consulta ainda não realizada.')})
                dump(meta_path, query); return None, query
            print(spec['id'] + ': consultando', flush=True)
            data, final = fetch(endpoint, urlencode(pairs, encoding='latin1').encode('ascii'))
            table = parse_html(data); path.write_bytes(data)
            query['coletado_em'] = now(); query['url_final'] = final
        else:
            data = path.read_bytes(); table = parse_html(data)
            assert not old_meta.get('sha256_html') or sha(data) == old_meta['sha256_html']
            assert not old_meta.get('parametros') or [list(p) for p in pairs] == old_meta['parametros']
            query['coletado_em'] = old_meta.get('coletado_em', 'arquivo_preexistente_sem_data_confirmada')
        text = clean(data)
        assert '292740 SALVADOR' in text.upper(), 'Território ausente na resposta'
        expected = 'local de residência - Brasil' if spec['sistema'] == 'SIH' else 'Óbitos p/Residênc'
        assert expected in text, 'Perspectiva/conteúdo incompatível'
        cols = [int(h) for h in table['cabecalho'] if re.fullmatch(r'20\d\d', h)]
        assert cols and set(cols).issubset(YEARS)
        zero = 'Dado numérico igual a 0 não resultante de arredondamento' in text
        query.update({'status': 'conferido', 'sha256_html': sha(data), 'bytes_html': len(data),
                      'anos_retornados': cols, 'anos_omitidos': sorted(set(YEARS)-set(cols)),
                      'zero_legenda_conferido': zero, 'cabecalho': table['cabecalho'], 'linhas_retornadas': len(table['linhas']),
                      'notas_resposta': text[text.find('Fonte:'):text.find('TOTAL')] if 'TOTAL' in text else '',
                      'tabela_total': total(table)})
        csv_out(OUT / (spec['id'] + '_tabela.csv'), [dict(zip(table['cabecalho'], r)) for r in table['linhas']])
        print(spec['id'] + ': conferido, total=' + str(query['tabela_total'].get('Total')), flush=True)
        dump(meta_path, query); return table, query
    except Exception as exc:
        query.update({'status': 'pendente', 'erro': type(exc).__name__ + ': ' + str(exc)})
        dump(meta_path, query); print(spec['id'] + ': pendente ' + query['erro'], flush=True)
        return None, query

def process(tables, metas):
    annual, profiles, checks, revisions = [], [], [], []
    for metric in ('internacoes', 'obitos', 'dias_permanencia', 'valor_total'):
        key = 'SIH_' + metric + '_diagnostico_ano'
        if key not in tables: continue
        table, meta = tables[key], metas[key]
        for code, label in GROUPS.items():
            row = next((dict(zip(table['cabecalho'], r)) for r in table['linhas'] if plain_label(r[0]) == label), None)
            for year in YEARS:
                value = row.get(str(year), '') if row else ''
                annual.append({'sistema': 'SIH', 'cid_grupo': code, 'ano_processamento': year, 'medida': metric,
                               'valor': numeric(value, meta['zero_legenda_conferido'], metric == 'valor_total'),
                               'valor_original': value, 'unidade': meta['unidade'],
                               'status': 'linha_omitida' if row is None else ('coluna_omitida' if str(year) not in row else 'observado'),
                               'consulta_id': key, 'municipio_residencia': '292740'})
            if row:
                vals = [a['valor'] for a in annual if a['cid_grupo'] == code and a['medida'] == metric]
                n = numeric(row['Total'], meta['zero_legenda_conferido'], metric == 'valor_total')
                if None not in vals:
                    checks.append({'sistema': 'SIH', 'grupo': code, 'ano': '2014_2024', 'comparacao': metric + '_soma_anos',
                                   'total_oficial': n, 'soma': sum(vals), 'diferenca': n-sum(vals)})
        # The official output also includes chapters/parents. Sum selected leaf groups only.
        observed_rows = [r for r in table['linhas'] if plain_label(r[0]) in GROUPS.values()]
        tr = total(table)
        for year in meta['anos_retornados']:
            vals = [numeric(dict(zip(table['cabecalho'], r))[str(year)], meta['zero_legenda_conferido'], metric == 'valor_total') for r in observed_rows]
            n = numeric(tr[str(year)], meta['zero_legenda_conferido'], metric == 'valor_total')
            if None not in vals:
                checks.append({'sistema': 'SIH', 'grupo': 'conjunto_filtrado', 'ano': year, 'comparacao': metric + '_soma_diagnosticos',
                               'total_oficial': n, 'soma': sum(vals), 'diferenca': n-sum(vals)})
    for key, table in tables.items():
        meta = metas[key]
        if meta['dimensao'] not in ('sexo', 'idade'): continue
        for row in table['linhas']:
            if row[0].casefold() == 'total': continue
            bycol = dict(zip(table['cabecalho'], row))
            for year in YEARS:
                value = bycol.get(str(year), '')
                profiles.append({'sistema': meta['sistema'], 'cid_grupo': meta['grupo'], 'dimensao': meta['dimensao'],
                                 'estrato': row[0], 'ano': year, 'referencia_tempo': meta['referencia_tempo'],
                                 'medida': meta['medida'], 'valor': numeric(value, meta['zero_legenda_conferido']),
                                 'valor_original': value, 'status': 'coluna_omitida' if str(year) not in bycol else 'observado',
                                 'consulta_id': key, 'municipio_residencia': '292740'})
        tr = total(table)
        for year in meta['anos_retornados']:
            vals = [p['valor'] for p in profiles if p['consulta_id'] == key and p['ano'] == year]
            n = numeric(tr[str(year)], meta['zero_legenda_conferido'])
            if None not in vals:
                checks.append({'sistema': meta['sistema'], 'grupo': meta['grupo'], 'ano': year,
                               'comparacao': 'soma_' + meta['dimensao'], 'total_oficial': n, 'soma': sum(vals), 'diferenca': n-sum(vals)})
            if meta['sistema'] == 'SIH':
                core = next((a['valor'] for a in annual if a['cid_grupo'] == meta['grupo'] and a['ano_processamento'] == year and a['medida'] == 'internacoes'), None)
                if core is not None: checks.append({'sistema': 'SIH', 'grupo': meta['grupo'], 'ano': year,
                                                   'comparacao': 'perfil_vs_internacoes_ano', 'total_oficial': core, 'soma': n, 'diferenca': core-n})
    derived = []
    for key, table in tables.items():
        meta = metas[key]
        if meta['sistema'] != 'SIH' or meta['medida'] != 'internacoes' or meta['dimensao'] not in ('idade', 'sexo'): continue
        tr = total(table)
        for year in YEARS:
            value = tr.get(str(year), '')
            derived.append({'sistema': 'SIH', 'cid_grupo': meta['grupo'], 'ano_processamento': year,
                            'internacoes': numeric(value, meta['zero_legenda_conferido']), 'valor_original': value,
                            'origem': 'total_oficial_da_marginal_' + meta['dimensao'], 'consulta_id': key,
                            'status': 'coluna_omitida' if str(year) not in tr else 'observado'})
    unique_derived = []
    for code, year in sorted({(d['cid_grupo'], d['ano_processamento']) for d in derived}):
        matching = [d for d in derived if d['cid_grupo'] == code and d['ano_processamento'] == year]
        assert len({d['internacoes'] for d in matching}) == 1
        unique_derived.append({'cid_grupo': code, 'ano_processamento': year, 'internacoes': matching[0]['internacoes'],
                               'origem': 'total_oficial_das_marginais', 'consultas_origem': '|'.join(d['consulta_id'] for d in matching),
                               'origens_concordantes': len(matching), 'status': matching[0]['status']})
    csv_out(OUT / 'sih_internacoes_anuais_totais_das_marginais.csv', unique_derived)
    previous = BASE / 'dados' / 'tratados' / 'complementos' / 'sih_anual_grupos.csv'
    if previous.exists():
        with previous.open(encoding='utf-8-sig', newline='') as stream: prior = list(csv.DictReader(stream, delimiter=';'))
        for p in prior:
            for metric, field in [('internacoes', 'internacoes'), ('obitos', 'obitos_internacoes')]:
                n = next((a['valor'] for a in annual if a['cid_grupo'] == p['cid_grupo'] and a['ano_processamento'] == int(p['ano_processamento']) and a['medida'] == metric), None)
                origin = 'diagnostico_por_ano'
                if n is None and metric == 'internacoes':
                    matches = [d for d in derived if d['cid_grupo'] == p['cid_grupo'] and d['ano_processamento'] == int(p['ano_processamento']) and d['internacoes'] is not None]
                    if matches:
                        assert len({d['internacoes'] for d in matches}) == 1
                        n, origin = matches[0]['internacoes'], 'total_oficial_das_marginais_novas'
                old = int(p[field]) if p[field] else None
                revisions.append({'sistema': 'SIH', 'cid_grupo': p['cid_grupo'], 'ano': p['ano_processamento'], 'medida': metric,
                                  'piloto_20261005': old, 'versao_20261009': n,
                                  'diferenca': n-old if n is not None and old is not None else None,
                                  'origem_valor_novo': origin,
                                  'resultado': 'mesmo_valor' if n == old else ('revisao_possivel' if n is not None and old is not None else 'ausencia_em_uma_versao')})
    csv_out(OUT / 'sih_medidas_anuais_longo.csv', annual)
    csv_out(OUT / 'perfis_anuais_longo.csv', profiles)
    csv_out(OUT / 'conferencias.csv', checks)
    csv_out(OUT / 'comparacao_piloto_versoes.csv', revisions)
    failures = [c for c in checks if c['diferenca'] != 0]
    # Currency cells are rounded to cents independently; retain rather than erase small differences.
    severe = [c for c in failures if not c['comparacao'].startswith('valor_total_') or abs(c['diferenca']) > Decimal('0.10')]
    return {'medidas_anuais_linhas': len(annual), 'perfis_linhas': len(profiles), 'conferencias': len(checks),
            'divergencias_conservacao': [{**c, 'diferenca': str(c['diferenca']), 'soma': str(c['soma']), 'total_oficial': str(c['total_oficial'])} for c in failures],
            'divergencias_materialmente_pendentes': len(severe),
            'comparacoes_piloto': len(revisions),
            'comparacoes_numericas_piloto': sum(r['piloto_20261005'] is not None and r['versao_20261009'] is not None for r in revisions),
            'revisoes_numericas_piloto': sum(r['resultado'] == 'revisao_possivel' for r in revisions)}

def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--coletar', action='store_true'); parser.add_argument('--inspecionar', action='store_true')
    parser.add_argument('--transporte', choices=['urllib', 'curl'], default='urllib')
    parser.add_argument('--ip-resolvido', help='IP observado em diagnóstico DNS; curl mantém domínio, SNI e validação TLS.')
    parser.add_argument('--priorizar-restantes', action='store_true')
    parser.add_argument('--diretorio-projeto', help='Pasta do projeto; padrão é a pasta que contém scripts/.')
    parser.add_argument('--versao', default='complementos_20261009')
    parser.add_argument('--limite-post', type=int, default=24, help='Teto acumulado na versão; aumentar exige autorização da nova rodada.')
    parser.add_argument('--curl-path', help='Caminho opcional do executável curl; padrão é localizar no PATH.')
    parser.add_argument('--sih-http', action='store_true', help='Transporte HTTP do tabulador público SIH, se HTTPS estiver indisponível.')
    args = parser.parse_args()
    configure(args.diretorio_projeto, args.versao, args.limite_post)
    global TRANSPORT, RESOLVED_IP, CURL_PATH, SIH_HTTP
    TRANSPORT = args.transporte
    RESOLVED_IP = str(ipaddress.ip_address(args.ip_resolvido)) if args.ip_resolvido else None
    CURL_PATH, SIH_HTTP = args.curl_path, args.sih_http
    if SIH_HTTP: URLS['SIH'] = URLS['SIH'].replace('https://', 'http://', 1)
    forms = {system: inspect(system) for system in ('SIM', 'SIH')}
    specs = job_specs(forms)
    if args.priorizar_restantes:
        priority = ['SIM_idade_ano_G00_G03_A39_A87', 'SIH_dias_permanencia_diagnostico_ano', 'SIH_valor_total_diagnostico_ano',
                    'SIH_G00_sexo_ano', 'SIH_G00_idade_ano', 'SIH_A87_idade_ano']
        specs.sort(key=lambda s: (priority.index(s['id']) if s['id'] in priority else len(priority)))
    dump(META / 'plano_consultas.json', {'consultas': specs, 'teto_POST': MAX_POST, 'teto_bytes': MAX_BYTES,
                                       'documentacao_consultada': DOCS, 'data_revisao_documentacao': '2026-10-09'})
    if args.inspecionar: return
    tables, metas, consecutive_errors = {}, {}, 0
    for spec in specs:
        table, meta = collect_one(spec, *forms[spec['sistema']], args.coletar and consecutive_errors < 3)
        if consecutive_errors >= 3 and meta['status'] == 'planejado':
            meta['status'] = 'pendente'; meta['erro'] = 'Circuit breaker: três consultas consecutivas falharam; sem repetir lote.'
            dump(META / (spec['id'] + '.json'), meta)
        metas[spec['id']] = meta
        if table:
            tables[spec['id']] = table; consecutive_errors = 0
        elif args.coletar: consecutive_errors += 1
    qa = process(tables, metas)
    result = {'etapa': 'coleta_ampla_complementos', 'em': now(), 'versao': VERSION,
              'status': 'coleta_conferida' if len(tables) == len(specs) and not qa['divergencias_materialmente_pendentes'] else 'coleta_parcial_ou_conferencia_pendente',
              'consultas_planejadas': len(specs), 'consultas_conferidas': len(tables), 'POST_realizados': sum(r['metodo'] == 'POST' for r in requests),
              'bytes_brutos': size_used(), 'limites': {'POST': MAX_POST, 'bytes': MAX_BYTES}, 'qa': qa,
              'pendencias': [m for m in metas.values() if m['status'] != 'conferido'],
              'fontes': list(metas.values()), 'territorio': 'residentes Salvador 292740',
              'contratos_formulario': {s: m for s, (f, m) in forms.items()},
              'piloto_comparacao': {'arquivo': 'dados/tratados/complementos/sih_anual_grupos.csv',
                                   'sha256': sha((BASE / 'dados/tratados/complementos/sih_anual_grupos.csv').read_bytes())}
                                   if (BASE / 'dados/tratados/complementos/sih_anual_grupos.csv').exists() else None,
              'recorte_SIH': 'nacional por residencia; rede SUS; ano_processamento 2014-2024',
              'recorte_SIM': 'formulario Bahia; obitos por residencia; ano_obito 2014-2024; G00-G03,A39,A87',
              'restricoes': ['Dados separados; não somar sistemas como pessoas.', 'Não produzir letalidade SINAN usando SIH ou SIM.',
                             'Internações incluem transferências/reinternações.', 'A39 inclui outras apresentações além de meningite.',
                             'Valores aprovados nominais são produção administrativa, não custos econômicos completos.',
                             'G01/G02/G03 têm perfil anual separado ainda fora deste lote.'],
              'scripts': [{'arquivo': str(p.relative_to(BASE)), 'sha256': sha(p.read_bytes())} for p in (Path(__file__).resolve(), BASE / 'scripts' / '_tabnet_complementos.py')],
              'arquivos_tratados': [{'arquivo': str(p.relative_to(BASE)), 'sha256': sha(p.read_bytes()), 'bytes': p.stat().st_size} for p in sorted(OUT.glob('*.csv'))]}
    dump(META / 'RESULTADO_COLETA_COMPLEMENTOS.json', result)
    print('RESULTADO: ' + result['status'] + '; conferidas=' + str(len(tables)) + '/11; POST=' + str(result['POST_realizados']) + '; bytes=' + str(result['bytes_brutos']), flush=True)

if __name__ == '__main__': main()
