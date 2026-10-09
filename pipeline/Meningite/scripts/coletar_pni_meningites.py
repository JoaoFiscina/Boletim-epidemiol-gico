"""Piloto PNI municipal limitado; respostas originais e ausência preservadas.

Somente fontes públicas oficiais, sem instalação ou alteração de dados anteriores.
O modo inspecionar não faz POST. Os demais modos exigem formulário/JS inspecionados.
"""
import argparse
import ast
import base64
import csv
import hashlib
import html
import io
import json
import math
import os
import re
import secrets
import socket
import ssl
import string
import struct
import sys
from datetime import datetime
from http.cookiejar import CookieJar
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import quote, urlencode, urljoin
from urllib.request import Request, build_opener, HTTPCookieProcessor, HTTPRedirectHandler

sys.dont_write_bytecode = True
PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parent  # Only used to locate optional historical workspace caches.
RAW = PROJECT / 'dados/brutos/pni_20261009'
TREATED = PROJECT / 'dados/tratados/pni_20261009'
META = PROJECT / 'metadados/pni_20261009'
ORIGIN = 'https://infoms.saude.gov.br'
ENTRY = ORIGIN + '/extensions/SEIDIGI_DEMAS_VACINACAO_CALENDARIO_NACIONAL_COBERTURA_RESIDENCIA/index.html'
JS = ORIGIN + '/extensions/SEIDIGI_DEMAS_VACINACAO_CALENDARIO_NACIONAL_COBERTURA_RESIDENCIA/SEIDIGI_DEMAS_VACINACAO_CALENDARIO_NACIONAL_COBERTURA_RESIDENCIA.js'
TABNET = 'https://tabnet.datasus.gov.br/cgi/dhdat.exe?bd_pni/cpnibr.def'
DOCS = {
    'nota_tecnica_84_2026.pdf': 'https://www.gov.br/saude/pt-br/centrais-de-conteudo/publicacoes/notas-tecnicas/2026/nota-tecnica-no-84-2026-dpni-svsa-ms.pdf',
    'nota_tecnica_69_2026.pdf': 'https://www.gov.br/saude/pt-br/centrais-de-conteudo/publicacoes/notas-tecnicas/2026/nota-tecnica-no-69-2026-cgici-dpni-svsa-ms.pdf',
}
LEGACY = {'meningococica': 'Meningococo C', 'pneumococica': 'Pneumocócica', 'penta_hib': 'Penta', 'bcg': 'BCG'}
RECENT = {'meningococica': 'Meningocócica Conjugada', 'pneumococica': 'Pneumocócica Conjugada', 'penta_hib': 'Penta (DTP/HepB/Hib)', 'bcg': 'BCG'}
MAX_BYTES = 20 * 1024 * 1024
MAX_POST = 8  # Successful HTTP POST responses; root authorized 16 total attempts.
MAX_POST_ATTEMPTS = 16


class Form(HTMLParser):
    """Select real options in the official form; never synthesize SQL fields."""
    def __init__(self, data, url):
        super().__init__(convert_charrefs=True)
        self.url, self.selects, self.defaults, self.forms, self.links = url, {}, [], [], []
        self.select, self.option = None, None
        self.source = data.decode('latin1')
        self.feed(self.source)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'form':
            self.forms.append(attrs)
        elif tag == 'select':
            self.select = attrs.get('name')
            self.selects[self.select] = []
        elif tag == 'option' and self.select:
            self.option = {'label': '', 'value': attrs.get('value', ''), 'selected': 'selected' in attrs}
            self.selects[self.select].append(self.option)
        elif tag == 'input' and attrs.get('name'):
            if attrs.get('type', 'text').lower() == 'hidden' or (attrs.get('type', '').lower() in ('radio', 'checkbox') and 'checked' in attrs):
                self.defaults.append((attrs['name'], attrs.get('value', '')))
        elif tag == 'a' and 'href' in attrs:
            self.links.append(urljoin(self.url, attrs['href']))

    def handle_endtag(self, tag):
        if tag == 'select':
            self.select = self.option = None
        elif tag == 'option':
            self.option = None

    def handle_data(self, data):
        if self.option is not None:
            self.option['label'] += data.strip()

    def option_value(self, field, label):
        found = [o['value'] for o in self.selects[field] if o['label'] == label]
        if len(found) != 1:
            raise ValueError(f'Categoria inexistente/ambígua: {field}={label}')
        return found[0]

    def endpoint(self):
        if self.forms and self.forms[0].get('action'):
            return urljoin(self.url, self.forms[0]['action'])
        match = re.search(r'document\.Form1\.action\s*=\s*"([^"]+)"', self.source)
        if not match:
            raise ValueError('Formulário sem endpoint documentado')
        return urljoin(self.url, match[1])

    def pairs(self, query):
        result = []
        for field, options in self.selects.items():
            if field.startswith('listahidden') or not options:
                continue
            if field in query:
                chosen = query[field] if isinstance(query[field], list) else [query[field]]
                if not set(chosen).issubset({o['value'] for o in options}):
                    raise ValueError('Valores fora do formulário: ' + field)
            elif field.startswith('S'):
                chosen = [next((o['value'] for o in options if 'TODAS_AS_CATEGORIAS' in o['value']), options[0]['value'])]
            else:
                chosen = [next((o['value'] for o in options if o['selected']), options[0]['value'])]
            result.extend((field, value) for value in chosen)
        defaults = dict(self.defaults)
        defaults.update(formato='table', mostre='Mostra')
        result.extend(defaults.items())
        return result


def parse_html(data):
    """Literal Google Chart table only, without executing page JavaScript."""
    text = data.decode('latin1')
    quoted = r"(?:'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")"
    columns = re.findall(r"data\.addColumn\(\s*" + quoted + r"\s*,\s*(" + quoted + r")\s*\)", text)
    block = re.search(r'(?s)data\.addRows\(\s*\[(.*?)\]\s*\)', text)
    if not columns or not block:
        raise ValueError('Resposta não contém a tabela literal PNI observada')
    header = [ast.literal_eval(value) for value in columns]
    token = re.compile(r'\{\s*v:\s*(null|[-+0-9.eE]+)\s*,\s*f:\s*(' + quoted + r')\s*\}|(' + quoted + r')|(null|[-+0-9.eE]+)')
    rows, formatted = [], []
    for match in re.finditer(r'(?s)\[\s*(' + quoted + r')\s*,(.*?)\]', block[1]):
        row = [ast.literal_eval(match[1]).strip()]
        display, end = list(row), 0
        for cell in token.finditer(match[2]):
            if match[2][end:cell.start()].strip(' \t\r\n,'):
                raise ValueError('Célula PNI fora do formato esperado')
            if cell[1] is not None:
                row.append('' if cell[1] == 'null' else cell[1].replace('.', ','))
                display.append(str(ast.literal_eval(cell[2])))
            elif cell[3] is not None:
                row.append(str(ast.literal_eval(cell[3]))); display.append(row[-1])
            else:
                row.append('' if cell[4] == 'null' else cell[4].replace('.', ',')); display.append(row[-1])
            end = cell.end()
        if match[2][end:].strip(' \t\r\n,') or len(row) != len(header):
            raise ValueError('Largura PNI inconsistente')
        rows.append(row); formatted.append(display)
    if not rows or not any(str(row[0]).casefold() == 'total' for row in rows):
        raise ValueError('Tabela PNI sem total reconhecido')
    return {'cabecalho': header, 'linhas': rows, 'linhas_formatadas': formatted,
            'preambulo': html.unescape(re.sub('<[^>]+>', ' ', text[:text.find('<!-- Google Chart')]))}


def parse_csv(data):
    text = data.decode('utf-8-sig' if data.startswith(b'\xef\xbb\xbf') else 'latin1')
    rows = list(csv.reader(io.StringIO(text), delimiter=';'))
    if not rows or len(rows[0]) < 2 or not any(row and row[0].casefold() == 'total' for row in rows[1:]):
        raise ValueError('CSV PNI sem cabeçalho/total reconhecido')
    return {'cabecalho': rows[0], 'linhas': [row for row in rows[1:] if len(row) == len(rows[0]) and row[0].strip()]}


def resolve_file(value):
    path = Path(str(value).replace('\\', '/'))
    if path.is_absolute():
        return path
    if path.parts and path.parts[0] in ('Meningite', PROJECT.name):
        return PROJECT.joinpath(*path.parts[1:])
    return PROJECT / path


def now():
    return datetime.now().astimezone().isoformat()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def dump(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False), encoding='utf8')


def write_csv(path, rows):
    if not rows:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w', encoding='utf-8-sig', newline='') as f:
        fields = list(dict.fromkeys(key for row in rows for key in row))
        writer = csv.DictWriter(f, fieldnames=fields, delimiter=';')
        writer.writeheader()
        writer.writerows(rows)


class Evidence:
    def __init__(self):
        for p in [RAW, TREATED, META]:
            p.mkdir(parents=True, exist_ok=True)
        self.manifest = META / 'manifesto.jsonl'
        self.records = [json.loads(line) for line in self.manifest.read_text(encoding='utf8').splitlines()] if self.manifest.exists() else []
        self.bytes = sum(r.get('bytes_recebidos', 0) for r in self.records)
        self.posts = sum(r.get('metodo') == 'POST' and r.get('evento') == 'tentativa' for r in self.records)
        self.posts_success = sum(r.get('metodo') == 'POST' and r.get('evento') == 'resposta' for r in self.records)
        self.rpc = sum(r.get('evento') == 'rpc_enviado' for r in self.records)
        evidence = self
        class AuditRedirect(HTTPRedirectHandler):
            def redirect_request(self, req, fp, code, msg, headers, newurl):
                evidence.record(evento='redirecionamento_http', url_origem=req.full_url, status_http=code, url_destino=newurl)
                return super().redirect_request(req, fp, code, msg, headers, newurl)
        self.opener = build_opener(HTTPCookieProcessor(CookieJar()), AuditRedirect())

    def record(self, **record):
        value = {'em': now(), **record}
        with self.manifest.open('a', encoding='utf8') as f:
            f.write(json.dumps(value, ensure_ascii=False, allow_nan=False) + '\n')
        self.records.append(value)

    def save(self, name, data, **meta):
        path = RAW / name
        if path.exists():
            raise FileExistsError('Resposta existente não será sobrescrita: ' + str(path))
        if self.bytes + len(data) > MAX_BYTES:
            raise ValueError('Limite total de 20 MiB atingido')
        path.write_bytes(data)
        self.bytes += len(data)
        self.record(evento='resposta', arquivo=str(path.relative_to(ROOT)), sha256=sha(data), bytes_recebidos=len(data), **meta)
        return data

    def request(self, name, url, data=None, headers=None, ephemeral=False):
        method = 'POST' if data is not None else 'GET'
        if method == 'POST':
            attempts_same = sum(r.get('evento') == 'tentativa' and r.get('metodo') == 'POST' and r.get('parametros_sha256') == sha(data) for r in self.records)
            if self.posts >= MAX_POST_ATTEMPTS or self.posts_success >= MAX_POST or attempts_same >= 2:
                raise ValueError('Limite atingido: oito POST concluídos, 16 tentativas totais e duas por consulta')
        if method == 'POST':
            self.posts += 1
        public_url = url.split('?xrfkey=')[0] if ephemeral else url
        self.record(evento='tentativa', metodo=method, url=public_url,
                    parametros_sha256=sha(data) if data is not None else None)
        try:
            with self.opener.open(Request(url, data=data, headers={'User-Agent': 'Mozilla/5.0', **(headers or {})}), timeout=25) as response:
                body = response.read(MAX_BYTES - self.bytes + 1)
                if self.bytes + len(body) > MAX_BYTES:
                    raise ValueError('Limite total de bytes recebido excedido')
                status = response.status
                if ephemeral:
                    self.bytes += len(body)
                    self.record(evento='resposta_efemera', metodo=method, url=public_url, status_http=status, bytes_recebidos=len(body), nota='Tokens/cookies não persistidos')
                else:
                    self.save(name, body, metodo=method, url=public_url, url_final=response.url, status_http=status,
                              tipo_conteudo=response.headers.get('Content-Type'))
                    if method == 'POST':
                        self.posts_success += 1
                return body, response.headers
        except Exception as error:
            self.record(evento='falha', metodo=method, url=public_url, erro=str(error), tipo_erro=type(error).__name__)
            raise


def inspect(ev):
    targets = {'tabnet_cobertura_form.html': TABNET, 'painel_residencia_index.html': ENTRY,
               'painel_residencia.js': JS, **DOCS}
    results = []
    for name, url in targets.items():
        path = RAW / name
        try:
            body = path.read_bytes() if path.exists() else ev.request(name, url)[0]
            if name == 'tabnet_cobertura_form.html':
                form = Form(body, TABNET)
                dump(META / 'formulario_cobertura_inspecionado.json', {'url': TABNET, 'endpoint': form.endpoint(), 'sha256_html': sha(body),
                     'selects': form.selects, 'defaults': form.defaults, 'links': form.links, 'inspecionado_em': now()})
                print('TABNET', form.endpoint(), 'anos', [o['label'] for o in form.selects.get('PAno', [])][:15], flush=True)
            if name == 'painel_residencia.js':
                # Ignore commented development/QSE alternatives in the public script.
                apps = re.findall(r"(?m)^\s*app\s*=\s*qlik\.openApp\(['\"]([a-f0-9-]{36})['\"]", body.decode('utf8', errors='replace'))
                dump(META / 'apps_inspecionados.json', {'url': JS, 'sha256_js': sha(body), 'apps': apps, 'inspecionado_em': now()})
                print('QLIK apps', apps, flush=True)
            results.append({'arquivo': str(path.relative_to(ROOT)), 'status': 'preservado', 'bytes': len(body), 'sha256': sha(body)})
        except Exception as error:
            results.append({'url': url, 'status': 'falha', 'erro': str(error)})
            print('FALHA', name, str(error), flush=True)
    dump(META / 'resultado_inspecao.json', {'em': now(), 'resultados': results, 'http_posts': ev.posts, 'bytes_recebidos_total': ev.bytes})


def legacy(ev, indicator=None):
    source = RAW / 'tabnet_cobertura_form.html'
    if not source.exists():
        raise ValueError('Inspecione primeiro o formulário atual')
    form = Form(source.read_bytes(), TABNET)
    existing = TREATED / 'cobertura_legado_piloto_2014_2022.csv'
    rows = list(csv.DictReader(existing.open(encoding='utf-8-sig'), delimiter=';')) if existing.exists() else []
    checks = []
    for key, label in LEGACY.items():
        if indicator and key != indicator:
            continue
        penta_cache = TREATED / 'cobertura_legado_penta_cache_2014_2022.csv'
        if key == 'penta_hib' and penta_cache.exists():
            cached_rows = list(csv.DictReader(penta_cache.open(encoding='utf-8-sig'), delimiter=';'))
            if len(cached_rows) != 9 or {int(r['ano']) for r in cached_rows} != set(range(2014, 2023)):
                raise ValueError('Cache Penta incompleto; não repetir automaticamente')
            for row in cached_rows:
                path = resolve_file(row['arquivo_bruto'])
                if row['codigo_ibge6'] != '292740' or not path.exists() or sha(path.read_bytes()) != row['sha256_bruto']:
                    raise ValueError('Cache Penta com município/SHA divergente')
            rows = [r for r in rows if r['indicador_grupo'] != key] + cached_rows
            checks.append({'indicador': label, 'status': 'cache_validado_sem_repetir_download', 'anos': list(range(2014, 2023))})
            print('Penta legado CACHE validado; nenhum POST repetido', flush=True)
            continue
        query = {'Linha': form.option_value('Linha', 'Ano'), 'Coluna': form.option_value('Coluna', 'Não ativa'),
                 'Incremento': form.option_value('Incremento', label),
                 'PAno': [form.option_value('PAno', str(y)) for y in range(2014, 2023)],
                 'SCapital': form.option_value('SCapital', '292740 Salvador')}
        pairs = form.pairs(query)
        name = 'legado_' + key + '_2014_2022.html'
        payload = urlencode(pairs, encoding='latin1').encode('ascii')
        dump(META / ('parametros_legado_' + key + '.json'), {'endpoint': form.endpoint(), 'formulario_sha256': sha(source.read_bytes()),
             'parametros': pairs, 'parametros_sha256': sha(payload), 'municipio_esperado': '292740 Salvador', 'anos': list(range(2014, 2023)), 'indicador': label})
        try:
            path = RAW / name
            body = path.read_bytes() if path.exists() else ev.request(name, form.endpoint(), data=payload,
                        headers={'Content-Type': 'application/x-www-form-urlencoded', 'Referer': TABNET})[0]
            table = parse_html(body)
            dump(META / ('tabela_legado_' + key + '.json'), table)
            preamble = table['preambulo']
            if 'Salvador' not in preamble:
                raise ValueError('Resposta não confirmou Salvador no preâmbulo')
            by_year = {int(r[0]): r[1] for r in table['linhas'] if re.fullmatch(r'20\d{2}', str(r[0]))}
            if set(by_year) != set(range(2014, 2023)):
                raise ValueError('Resposta não contém exatamente os nove anos solicitados')
            rows = [r for r in rows if r['indicador_grupo'] != key]
            for year, value in sorted(by_year.items()):
                numeric = float(str(value).replace('.', '').replace(',', '.')) if value not in ('', '-', '...') else None
                rows.append({'sistema': 'PNI_TabNet_legado', 'codigo_ibge6': '292740', 'codigo_ibge7': '2927408', 'municipio': 'Salvador',
                    'ano': year, 'indicador_grupo': key, 'indicador_fonte': label, 'cobertura_percentual': numeric,
                    'numerador_oficial': None, 'denominador_oficial': None, 'geografia': 'município do registro legado; residência não confirmada',
                    'status': 'observado' if numeric is not None else 'ausente na fonte', 'valor_original': value,
                    'arquivo_bruto': str(path.relative_to(ROOT)), 'metodo_numerador': 'última dose do esquema; não pessoas deduplicadas'})
            checks.append({'indicador': label, 'municipio_confirmado': True, 'anos': sorted(by_year), 'status': 'extraído'})
            print(label, 'anos=', len(by_year), '2022=', by_year[2022], flush=True)
        except Exception as error:
            checks.append({'indicador': label, 'status': 'falha', 'erro': str(error)})
            print('FALHA legado', label, str(error), flush=True)
    write_csv(TREATED / 'cobertura_legado_piloto_2014_2022.csv', rows)
    dump(META / 'resultado_legado.json', {'em': now(), 'linhas': len(rows), 'validacoes': checks,
         'http_posts': ev.posts, 'bytes_recebidos_total': ev.bytes})


class PublicQlik:
    def __init__(self, ev, appid):
        self.ev, self.appid, self.counter, self.buffer = ev, appid, 0, b''
        ev.request(None, ENTRY, ephemeral=True)
        xrf = ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(16))
        _, headers = ev.request(None, ORIGIN + '/qps/csrftoken?xrfkey=' + xrf,
                               headers={'X-Qlik-Xrfkey': xrf, 'Origin': ORIGIN}, ephemeral=True)
        csrf = headers.get('qlik-csrf-token')
        if not csrf:
            raise ConnectionError('Sessão pública sem CSRF; interrompida')
        raw = socket.create_connection(('infoms.saude.gov.br', 443), timeout=25)
        self.socket = ssl.create_default_context().wrap_socket(raw, server_hostname='infoms.saude.gov.br')
        key = base64.b64encode(os.urandom(16)).decode()
        cookies = '; '.join(f'{c.name}={c.value}' for handler in ev.opener.handlers if isinstance(handler, HTTPCookieProcessor) for c in handler.cookiejar)
        hdr = [f'GET /app/{appid}?qlik-csrf-token={quote(csrf, safe="")} HTTP/1.1', 'Host: infoms.saude.gov.br', 'Upgrade: websocket',
               'Connection: Upgrade', f'Sec-WebSocket-Key: {key}', 'Sec-WebSocket-Version: 13', f'Origin: {ORIGIN}', f'qlik-csrf-token: {csrf}', 'User-Agent: Mozilla/5.0']
        if cookies:
            hdr.append('Cookie: ' + cookies)
        self.socket.sendall(('\r\n'.join(hdr) + '\r\n\r\n').encode())
        while b'\r\n\r\n' not in self.buffer:
            chunk = self.socket.recv(4096)
            if not chunk:
                raise ConnectionError('Handshake encerrado')
            self.buffer += chunk
            if len(self.buffer) > 65536:
                raise ValueError('Cabeçalho inesperadamente grande')
        head, self.buffer = self.buffer.split(b'\r\n\r\n', 1)
        status = head.split(b'\r\n', 1)[0].decode()
        ev.bytes += len(head) + 4
        ev.record(evento='websocket_handshake', status=status, bytes_recebidos=len(head) + 4, app=appid,
                  nota='Cabeçalho contém contexto efêmero e não foi persistido')
        if ' 101 ' not in status:
            self.socket.close()
            raise ConnectionError('Handshake recusado: ' + status)
        expected = base64.b64encode(hashlib.sha1((key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').encode()).digest()).decode()
        actual = next((line.split(':', 1)[1].strip() for line in head.decode().split('\r\n') if line.lower().startswith('sec-websocket-accept:')), None)
        if actual != expected:
            self.socket.close()
            raise ConnectionError('WebSocket não validado')
        self.app = self.call(-1, 'OpenDoc', {'qDocName': appid})['qReturn']['qHandle']

    def read(self, n):
        while len(self.buffer) < n:
            chunk = self.socket.recv(max(4096, n - len(self.buffer)))
            if not chunk:
                raise ConnectionError('WebSocket encerrado')
            self.buffer += chunk
        part, self.buffer = self.buffer[:n], self.buffer[n:]
        return part

    def send(self, data, opcode=1):
        mask, n = os.urandom(4), len(data)
        header = bytes([128 | opcode, 128 | (n if n < 126 else 126 if n < 65536 else 127)])
        if n >= 126:
            header += struct.pack('!H' if n < 65536 else '!Q', n)
        self.socket.sendall(header + mask + bytes(x ^ mask[i % 4] for i, x in enumerate(data)))

    def receive(self):
        chunks, overhead = [], 0
        while True:
            first, second = self.read(2)
            opcode, n = first & 15, second & 127
            overhead += 2
            if n == 126:
                n = struct.unpack('!H', self.read(2))[0]; overhead += 2
            elif n == 127:
                n = struct.unpack('!Q', self.read(8))[0]; overhead += 8
            if self.ev.bytes + overhead + sum(map(len, chunks)) + n > MAX_BYTES:
                raise ValueError('Frame excede orçamento total de bytes')
            mask = self.read(4) if second & 128 else None
            if mask:
                overhead += 4
            data = self.read(n)
            if mask:
                data = bytes(x ^ mask[i % 4] for i, x in enumerate(data))
            if opcode == 8:
                raise ConnectionError('Servidor encerrou sessão')
            if opcode == 9:
                self.ev.bytes += overhead + len(data)
                self.ev.record(evento='websocket_ping', bytes_recebidos=overhead + len(data))
                overhead = 0
                self.send(data, 10)
                continue
            if opcode == 10:
                continue
            if opcode not in (0, 1):
                raise ValueError('Mensagem inesperada')
            chunks.append(data)
            if first & 128:
                body = b''.join(chunks)
                self.ev.bytes += overhead
                self.ev.record(evento='websocket_envelope', bytes_recebidos=overhead)
                name = f'rpc_{self.ev.rpc:03d}_{len(self.ev.records):03d}.json'
                self.ev.save(name, body, transporte='WebSocket público', app=self.appid)
                return json.loads(body)

    def call(self, handle, method, params=None):
        self.counter += 1
        self.ev.rpc += 1
        packet = {'jsonrpc': '2.0', 'id': self.counter, 'handle': handle, 'method': method, 'params': params or {}}
        self.ev.record(evento='rpc_enviado', app=self.appid, rpc_numero_global=self.ev.rpc, requisicao=packet)
        self.send(json.dumps(packet).encode())
        while True:
            response = self.receive()
            if response.get('id') == self.counter:
                if 'error' in response:
                    raise ValueError(f'{method}: {response["error"]}')
                return response['result']

    def obj(self, code):
        return self.call(self.app, 'GetObject', {'qId': code})['qReturn']['qHandle']

    def close(self):
        try:
            self.send(b'', 8)
        finally:
            self.socket.close()


def number(cell):
    value = cell.get('qNumber')
    if not isinstance(value, (int, float)) or not math.isfinite(value):
        return None
    if value == 0.000001 or cell.get('qText') in ('0,000001', '-'):
        return None
    return value


def recent(ev, year=2024):
    target = TREATED / f'cobertura_rnds_piloto_{year}.csv'
    if target.exists():
        cached = list(csv.DictReader(target.open(encoding='utf-8-sig'), delimiter=';'))
        hashes = {r['arquivo']: r['sha256'] for r in ev.records if r.get('arquivo') and r.get('sha256')}
        inventory = META / 'inventario_sha256.csv'
        if inventory.exists():
            hashes.update({r['arquivo']: r['sha256'] for r in csv.DictReader(inventory.open(encoding='utf-8-sig'), delimiter=';')})
        if len(cached) != 4 or {r['indicador_grupo'] for r in cached} != set(RECENT):
            raise ValueError('Cache anual parcial; não sobrescrever nem declarar concluído')
        for row in cached:
            path = resolve_file(row['arquivo_bruto'])
            expected = hashes.get(row['arquivo_bruto'])
            if not path.exists() or not expected or sha(path.read_bytes()) != expected:
                raise ValueError('Cache RNDS sem resposta bruta e SHA íntegros; não repetir automaticamente')
        print('CACHE SHA validado: nenhum download RNDS repetido', target, flush=True)
        return
    apps = json.loads((META / 'apps_inspecionados.json').read_text(encoding='utf8'))['apps']
    if len(apps) != 1:
        raise ValueError('Identificação atual do aplicativo ambígua')
    client, rows, errors = None, [], []
    try:
        client = PublicQlik(ev, apps[0])
        app_layout = client.call(client.app, 'GetAppLayout')
        dump(META / 'app_layout_atual.json', app_layout)
        vocab = client.call(client.obj('LKwyNs'), 'GetLayout')
        dump(META / 'filtro_imunobiologicos_atual.json', vocab)
        available = [cell['qText'] for page in vocab['qLayout']['qListObject']['qDataPages'] for row in page['qMatrix'] for cell in row]
        if not set(RECENT.values()).issubset(available):
            raise ValueError('Indicadores esperados não encontrados no filtro atual')
        handles = {field: client.call(client.app, 'GetField', {'qFieldName': field})['qReturn']['qHandle'] for field in ['Ano', 'Município', 'Imunobiológico']}
        selection = client.call(client.app, 'CreateSessionObject', {'qProp': {'qInfo': {'qType': 'CurrentSelections'}, 'qSelectionObjectDef': {}}})['qReturn']['qHandle']
        def select(field, value):
            cell = {'qNumber': value, 'qIsNumeric': True} if isinstance(value, int) else {'qText': value}
            if client.call(handles[field], 'SelectValues', {'qFieldValues': [cell], 'qToggleMode': False}).get('qReturn') is not True:
                raise ValueError('Filtro recusado: ' + field)
        select('Município', '292740 - Salvador')
        select('Ano', year)
        variables = {}
        for name in ['v_Cobertura', 'v_Doses', 'v_Populacao', 'vCampos2']:
            handle = client.call(client.app, 'GetVariableByName', {'qName': name})['qReturn']['qHandle']
            variables[name] = client.call(handle, 'GetProperties')
        dump(META / 'expressoes_oficiais_atuais.json', variables)
        for key, label in RECENT.items():
            select('Imunobiológico', label)
            raw_selections = client.call(selection, 'GetLayout')
            selected = {s['qField']: s for s in raw_selections['qLayout']['qSelectionObject']['qSelections']}
            for field, expected in [('Município', '292740 - Salvador'), ('Ano', str(year)), ('Imunobiológico', label)]:
                if selected.get(field, {}).get('qSelectedCount') != 1 or selected[field]['qSelected'] != expected:
                    raise ValueError('Seleção inesperada: ' + field)
            # Three scalar expressions are one annual indicator extraction, not monthly sums.
            expressions = {'cobertura': '$(v_Cobertura)', 'numerador': '$(v_Doses($(vCampos2)))', 'denominador': '$(v_Populacao($(vCampos2)))'}
            values = {key2: client.call(client.app, 'EvaluateEx', {'qExpression': expression}) for key2, expression in expressions.items()}
            summary = RAW / f'rnds_{key}_{year}_resumo.json'
            dump(summary, {'selecao': selected, 'expressoes': expressions, 'respostas': values})
            ev.record(evento='derivado_anual', arquivo=str(summary.relative_to(ROOT)), sha256=sha(summary.read_bytes()),
                      bytes_arquivo=summary.stat().st_size, origem='JSON-RPC original preservado no manifesto', ano=year, indicador=label)
            cov, num, den = [number(values[k]['qValue']) for k in ['cobertura', 'numerador', 'denominador']]
            if None not in (cov, num, den) and (den <= 0 or abs(cov - num / den) > 1e-9):
                raise ValueError('Relação cobertura/numerador/denominador diverge')
            rows.append({'sistema': 'PNI_RNDS_individual', 'codigo_ibge6': '292740', 'codigo_ibge7': '2927408', 'municipio': 'Salvador',
                'ano': year, 'indicador_grupo': key, 'indicador_fonte': label, 'cobertura_percentual': cov * 100 if cov is not None else None,
                'numerador_oficial': num, 'denominador_oficial': den, 'geografia': 'residência',
                'status': 'observado' if None not in (cov, num, den) else 'ausente na fonte', 'valor_original': values['cobertura']['qValue'].get('qText'),
                'arquivo_bruto': str((RAW / (f'rnds_{key}_{year}_resumo.json')).relative_to(ROOT)),
                'metodo_numerador': 'método normativo NT84/2026 individual; esquema ou última dose; ETL não auditável'})
            print('RNDS', label, str(year) + ':', num, '/', den, '=', cov, flush=True)
    except Exception as error:
        errors.append({'erro': str(error), 'tipo': type(error).__name__})
        ev.record(evento='falha_rnds', erro=str(error), tipo=type(error).__name__)
        print('FALHA RNDS', str(error), flush=True)
    finally:
        if client:
            client.close()
    write_csv(target, rows)
    dump(META / f'resultado_rnds_{year}.json', {'em': now(), 'linhas': len(rows), 'erros': errors, 'http_post_tentativas': ev.posts,
         'http_post_concluidos': ev.posts_success, 'rpc_total': ev.rpc, 'bytes_recebidos_total': ev.bytes, 'consultas_anuais_concluidas': len(rows), 'ano_piloto': year})


def finalize(ev):
    """Consolidação offline, reutilizando somente cache com município e SHA validados."""
    old_meta_path = ROOT / 'metadados/hepatites/pni_cobertura_2.json'
    saved_provenance = META / 'proveniencia_cache_penta_legado.json'
    if old_meta_path.exists():
        old = json.loads(old_meta_path.read_text(encoding='utf8'))
        source_meta_hash = sha(old_meta_path.read_bytes())
        source_copies = {}
    elif saved_provenance.exists():
        provenance = json.loads(saved_provenance.read_text(encoding='utf8'))
        old, source_copies = provenance['metadados_originais'], provenance['copias']
        source_meta_hash = provenance['sha256_metadado_origem']
    else:
        raise FileNotFoundError('Cache Penta não disponível. Para finalizar os 17 pontos, copie o cache e sua proveniência para a pasta PNI do projeto.')
    if old['contexto']['codigo_municipio'] != '292740' or old['contexto']['conteudo'] != 'Penta':
        raise ValueError('Cache legado não corresponde a Penta/Salvador')
    copies = {}
    for field, hashfield in [('arquivo', 'sha256'), ('resposta_html', 'resposta_html_sha256')]:
        source = ROOT / old[field] if (ROOT / old[field]).exists() else resolve_file(source_copies[field])
        body = source.read_bytes()
        if sha(body) != old[hashfield]:
            raise ValueError('SHA do cache antigo divergente: ' + old[field])
        target = RAW / ('cache_20261003_' + source.name)
        if target.exists() and target.read_bytes() != body:
            raise ValueError('Cópia local do cache diverge')
        if not target.exists():
            target.write_bytes(body)
            ev.record(evento='cache_reutilizado', arquivo=str(target.relative_to(ROOT)), arquivo_origem=old[field], sha256=sha(body),
                      bytes_arquivo=len(body), extraido_em_origem=old['extraido_em'], nota='Nenhuma conexão; não são bytes recebidos neste piloto')
        copies[field] = str(target.relative_to(ROOT))
    dump(META / 'proveniencia_cache_penta_legado.json', {'metadado_origem': str(old_meta_path.relative_to(ROOT)),
         'sha256_metadado_origem': source_meta_hash, 'copias': copies, 'metadados_originais': old, 'reutilizado_em': now()})
    table = parse_csv(resolve_file(copies['arquivo']).read_bytes())
    preamble = parse_html(resolve_file(copies['resposta_html']).read_bytes())['preambulo']
    if 'Salvador' not in preamble:
        raise ValueError('HTML legado não confirma Salvador')
    legacy_rows = []
    for row in table['linhas']:
        if not re.fullmatch(r'20\d{2}', row[0]) or not 2014 <= int(row[0]) <= 2022:
            continue
        value = float(row[1].replace('.', '').replace(',', '.')) if row[1] not in ('', '-', '...') else None
        legacy_rows.append({'sistema': 'PNI_TabNet_legado', 'codigo_ibge6': '292740', 'codigo_ibge7': '2927408', 'municipio': 'Salvador',
             'ano': int(row[0]), 'indicador_grupo': 'penta_hib', 'indicador_fonte': 'Penta', 'cobertura_percentual': value,
             'numerador_oficial': None, 'denominador_oficial': None, 'geografia': 'município do registro legado; residência não confirmada',
             'status': 'observado_cache_sha_validado' if value is not None else 'ausente na fonte', 'valor_original': row[1],
             'arquivo_bruto': copies['arquivo'], 'metodo_numerador': 'última dose do esquema; não pessoas deduplicadas',
             'extraido_em': old['extraido_em'], 'fonte_url': old['formulario_url'], 'sha256_bruto': old['sha256']})
    if len(legacy_rows) != 9:
        raise ValueError('Cache Penta não contém os nove anos completos')
    write_csv(TREATED / 'cobertura_legado_penta_cache_2014_2022.csv', legacy_rows)
    rows = list(legacy_rows)
    validations = []
    for year in [2023, 2024]:
        target = TREATED / f'cobertura_rnds_piloto_{year}.csv'
        if not target.exists():
            continue
        original = list(csv.DictReader(target.open(encoding='utf-8-sig'), delimiter=';'))
        if len(original) != 4 or {r['indicador_grupo'] for r in original} != set(RECENT):
            raise ValueError('Piloto RNDS incompleto ou duplicado')
        for row in original:
            rawpath = resolve_file(row['arquivo_bruto'])
            summary = json.loads(rawpath.read_text(encoding='utf8'))
            for field, expected in [('Município', '292740 - Salvador'), ('Ano', str(year)), ('Imunobiológico', row['indicador_fonte'])]:
                selected = summary['selecao'][field]
                if selected['qSelectedCount'] != 1 or selected['qSelected'] != expected:
                    raise ValueError('Cache RNDS com contexto inesperado')
            values = [number(summary['respostas'][k]['qValue']) for k in ['cobertura', 'numerador', 'denominador']]
            cov, num, den = values
            if None in values or den <= 0 or abs(cov - num / den) > 1e-9:
                raise ValueError('Piloto RNDS contém ausência ou razão divergente')
            if abs(float(row['cobertura_percentual']) - cov * 100) > 1e-9 or float(row['numerador_oficial']) != num or float(row['denominador_oficial']) != den:
                raise ValueError('Tabela RNDS diverge da resposta original')
            row.update(ano=year, cobertura_percentual=cov * 100, numerador_oficial=num, denominador_oficial=den,
                       metodo_numerador='método normativo NT84/2026 individual; esquema ou última dose; ETL não auditável',
                       extraido_em=datetime.fromtimestamp(rawpath.stat().st_mtime).astimezone().isoformat(), fonte_url=ENTRY,
                       sha256_bruto=sha(rawpath.read_bytes()))
            rows.append(row)
            validations.append({'ano': year, 'indicador': row['indicador_fonte'], 'municipio_confirmado': True,
                 'selecao_unica_3_campos': True, 'razao_numerador_denominador_validada': True, 'arquivo': row['arquivo_bruto'], 'sha256': row['sha256_bruto']})
    rows.sort(key=lambda r: (r['indicador_grupo'], r['ano']))
    if len({(r['indicador_grupo'], r['ano']) for r in rows}) != len(rows):
        raise ValueError('Chave indicador/ano duplicada')
    write_csv(TREATED / 'pni_cobertura_municipal_2014_2024_longo.csv', rows)
    dictionary = ROOT / 'metadados/pni_recente/indicadores_oficiais.csv'
    if not dictionary.exists():
        dictionary = META / 'definicoes_indicadores_snapshot_20261003.csv'
    codes = ['IMUNMENCRE', 'IMUNPN10', 'IMUNPENTA', 'MGDI_MS_XR0']
    entries = [r for r in csv.DictReader(dictionary.open(encoding='utf-8-sig'), delimiter=';') if r['codigo'] in codes]
    write_csv(META / 'definicoes_indicadores_snapshot_20261003.csv', entries)
    if not (META / 'proveniencia_dicionario.json').exists():
        dump(META / 'proveniencia_dicionario.json', {'arquivo_origem': str(dictionary.relative_to(ROOT)), 'sha256_origem': sha(dictionary.read_bytes()),
             'snapshot_origem': '2026-10-03', 'codigos': codes, 'atualizado_nesta_coleta': False,
             'ressalva': 'Entrada IMUNPN10 ainda descreve 2023 com método antigo. A NT84/2026 vigente estende o método individual a 2023; não afirmar que o dicionário comprova a regra ETL do painel.'})
    availability = []
    for key in LEGACY:
        for year in range(2014, 2025):
            found = next((r for r in rows if r['indicador_grupo'] == key and r['ano'] == year), None)
            availability.append({'codigo_ibge6': '292740', 'municipio': 'Salvador', 'ano': year, 'indicador_grupo': key,
                 'indicador_fonte': LEGACY[key] if year <= 2022 else RECENT[key],
                 'fonte_sistema': 'TabNet legado' if year <= 2022 else 'Painel residência RNDS',
                 'disponibilidade_portal': 'campo/ano presente; não garante resposta' if year <= 2022 else 'indicador municipal retornou',
                 'status_coleta': found['status'] if found else 'pendente_falha_transporte_POST',
                 'cobertura_percentual': found['cobertura_percentual'] if found else None,
                 'numerador_oficial': found['numerador_oficial'] if found else None,
                 'denominador_oficial': found['denominador_oficial'] if found else None,
                 'ausencia_imputada_zero': False,
                 'arquivo_bruto': found['arquivo_bruto'] if found else None})
    write_csv(TREATED / 'disponibilidade_pni_municipal_2014_2024.csv', availability)
    schemes = {
         'meningococica': ('meningococo C; atual indicador conjugado inclui MenC/ACWY', 'esquema infantil duas doses; reforço separado e não coletado', 'duas doses válidas >=30 dias, primeira >=42 dias; ou registro D2', '41;74'),
         'pneumococica': ('pneumococo; cobertura atual conjugada não é PCV10 isolada', 'PCV10 três doses antes de 2016; duas desde 2016; reforço separado', 'duas doses válidas >=30 dias, primeira >=42 dias; ou D2; PCV10/13/15/20 consolidadas', '26;59;106;107'),
         'penta_hib': ('H. influenzae tipo b pelo componente Hib; não todas as meningites', 'Penta D3; esquema infantil de três doses; Hib isolada é outro indicador', 'três doses válidas >=30 dias, primeira >=42 dias; ou registro D3', '42;43'),
         'bcg': ('formas graves da tuberculose, incluindo meningite tuberculosa', 'dose única, preferencialmente ao nascer', 'uma dose válida por criança no período', '15'),
    }
    indicator_rows = []
    for key in LEGACY:
        organism, historical, current, codes_vax = schemes[key]
        present = [r for r in rows if r['indicador_grupo'] == key]
        indicator_rows.append({'indicador_grupo': key, 'relevancia_meningite': organism, 'rotulo_legado': LEGACY[key], 'rotulo_painel_atual': RECENT[key],
              'populacao_alvo': 'crianças menores de 1 ano; não população total de Salvador', 'esquema_historico': historical,
              'criterio_numerador_rnds_documental': current, 'codigos_vacina_rnds_dicionario': codes_vax,
              'denominador_rnds': 'nascidos vivos SINASC por município de residência e ano; se ano corrente não fechado, ano imediatamente anterior segundo NT84',
              'denominador_legado': 'denominador oficial da cobertura; número não exportado neste piloto/cache',
              'geografia_legado': 'município de registro; residência não confirmada', 'geografia_rnds': 'residência',
              'ano_indicador': 'ano aplicação da dose que atende critério; não ano nascimento da mesma coorte',
              'anos_solicitados': '2014–2024', 'anos_observados': ','.join(str(r['ano']) for r in present),
              'anos_pendentes': ','.join(str(y) for y in range(2014, 2025) if not any(r['ano'] == y for r in present)),
              'doses_aplicadas_coletadas': False, 'reforco_coletado': False, 'serie_harmonizada': False,
              'status': 'parcial; eras separadas' if len(present) < 11 else 'anos disponíveis; eras separadas'})
    write_csv(META / 'indicadores_solicitados_disponiveis.csv', indicator_rows)
    dump(META / 'validacao_piloto.json', {'em': now(), 'municipio': '292740 Salvador', 'linhas_observadas': len(rows),
         'chaves_solicitadas': len(availability), 'chaves_pendentes': sum(r['status_coleta'].startswith('pendente') for r in availability),
         'cache_penta_sha_validado': True, 'html_cache_confirma_municipio': True, 'validacoes_rnds': validations,
         'http_post_tentativas': ev.posts, 'http_post_concluidos': ev.posts_success, 'rpc_websocket': ev.rpc,
         'bytes_respostas_recebidas': ev.bytes, 'limite_bytes': MAX_BYTES, 'limite_post_concluidos': MAX_POST,
         'limite_tentativas_totais': MAX_POST_ATTEMPTS, 'limite_tentativas_por_consulta': 2, 'imputacoes_zero': 0,
         'microdados_individuais_baixados': False, 'doses_totais_confundidas_com_numerador': False})
    inventory = []
    script = Path(__file__).resolve()
    inventory.append({'arquivo': str(script.relative_to(ROOT)), 'bytes': script.stat().st_size, 'sha256': sha(script.read_bytes())})
    for directory in [RAW, TREATED, META]:
        for path in sorted(directory.iterdir()):
            if path.is_file() and path.name != 'inventario_sha256.csv':
                inventory.append({'arquivo': str(path.relative_to(ROOT)), 'bytes': path.stat().st_size, 'sha256': sha(path.read_bytes())})
    write_csv(META / 'inventario_sha256.csv', inventory)
    print('CONSOLIDADO', len(rows), 'observações;', len(availability), 'chaves solicitadas;', 44 - len(rows), 'pendentes', flush=True)


def main():
    global PROJECT, ROOT, RAW, TREATED, META
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('modo', choices=['inspecionar', 'legado', 'recente', 'finalizar'])
    parser.add_argument('--indicador', choices=list(LEGACY), help='Restringe o legado a uma consulta')
    parser.add_argument('--ano', choices=[2023, 2024], type=int, default=2024, help='Ano anual RNDS do piloto')
    parser.add_argument('--raiz-projeto', type=Path, default=PROJECT, help='Pasta do projeto Meningite; padrão relativo à localização do script')
    parser.add_argument('--data-lote', default='20261009', help='Identificador YYYYMMDD de uma coleta independente, sem sobrescrever outro lote')
    args = parser.parse_args()
    if not re.fullmatch(r'20\d{6}', args.data_lote):
        parser.error('--data-lote deve ser uma data YYYYMMDD')
    PROJECT = args.raiz_projeto.resolve()
    ROOT = PROJECT.parent
    RAW = PROJECT / 'dados/brutos' / ('pni_' + args.data_lote)
    TREATED = PROJECT / 'dados/tratados' / ('pni_' + args.data_lote)
    META = PROJECT / 'metadados' / ('pni_' + args.data_lote)
    ev = Evidence()
    if args.modo == 'legado':
        legacy(ev, args.indicador)
    elif args.modo == 'recente':
        recent(ev, args.ano)
    elif args.modo == 'finalizar':
        finalize(ev)
    else:
        {'inspecionar': inspect, 'recente': recent}[args.modo](ev)
    print('LIMITES: HTTP POST tentativas', ev.posts, '/', MAX_POST_ATTEMPTS, '; POST concluídos', ev.posts_success, '/', MAX_POST,
          '; bytes recebidos', ev.bytes, '/', MAX_BYTES,
          '; chamadas RPC WebSocket', ev.rpc, flush=True)


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf8')
    main()
