"""Parser independente, derivado de scripts/tabnet_hepatites.py; sem rotinas de coleta/escrita."""
from html.parser import HTMLParser
from urllib.parse import urljoin
import html, re

class Form(HTMLParser):
    def __init__(self, data, url):
        super().__init__(convert_charrefs=True)
        self.url, self.selects, self.defaults, self.forms, self.links = url, {}, [], [], []
        self.select = self.option = None
        self.source = data.decode('latin1')
        self.feed(self.source)
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'form': self.forms.append(attrs)
        elif tag == 'select':
            self.select = attrs.get('name'); self.selects[self.select] = []
        elif tag == 'option' and self.select:
            self.option = {'label': '', 'value': attrs.get('value', ''), 'selected': 'selected' in attrs}
            self.selects[self.select].append(self.option)
        elif tag == 'input' and attrs.get('name'):
            kind = attrs.get('type', 'text').lower()
            if kind == 'hidden' or (kind in ('radio', 'checkbox') and 'checked' in attrs):
                self.defaults.append((attrs['name'], attrs.get('value', '')))
        elif tag == 'a' and 'href' in attrs: self.links.append(urljoin(self.url, attrs['href']))
    def handle_endtag(self, tag):
        if tag == 'select': self.select = self.option = None
        elif tag == 'option': self.option = None
    def handle_data(self, data):
        if self.option is not None: self.option['label'] += data.strip()
    def option_value(self, field, label):
        values = [o['value'] for o in self.selects[field] if o['label'] == label]
        if len(values) != 1: raise ValueError('Categoria inexistente/ambígua: ' + field + '=' + label)
        return values[0]
    def endpoint(self):
        if self.forms and self.forms[0].get('action'): return urljoin(self.url, self.forms[0]['action'])
        match = re.search(r'document\.Form1\.action\s*=\s*"([^"]+)"', self.source)
        if not match: raise ValueError('Formulário sem endpoint documentado')
        return urljoin(self.url, match[1])
    def pairs(self, query):
        result = []
        for name, options in self.selects.items():
            if name.startswith('listahidden') or not options: continue
            if name in query:
                chosen = query[name] if isinstance(query[name], list) else [query[name]]
                if not set(chosen).issubset({o['value'] for o in options}):
                    raise ValueError('Valores fora do formulário: ' + name)
            elif name.startswith('S'):
                chosen = [next((o['value'] for o in options if 'TODAS_AS_CATEGORIAS' in o['value']), options[0]['value'])]
            else:
                chosen = [next((o['value'] for o in options if o['selected']), options[0]['value'])]
            result.extend((name, value) for value in chosen)
        defaults = dict(self.defaults); defaults.update({'formato': 'table', 'mostre': 'Mostra'})
        return result + list(defaults.items())

class DataTable(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.active, self.rows, self.row, self.cell = False, [], None, None
        self.feed(text)
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'table' and 'tabdados' in attrs.get('class', ''): self.active = True
        elif self.active and tag == 'tr': self.finish_row(); self.row = []
        elif self.active and tag in ('td', 'th'): self.finish_cell(); self.cell = ''
    def handle_data(self, text):
        if self.cell is not None: self.cell += text
    def handle_endtag(self, tag):
        if self.active and tag in ('td', 'th') and self.row is not None and self.cell is not None: self.finish_cell()
        elif self.active and tag == 'tr' and self.row: self.finish_row()
        elif self.active and tag in ('thead', 'tfoot', 'tbody'): self.finish_row()
        elif tag == 'table': self.finish_row(); self.active = False
    def finish_cell(self):
        if self.row is not None and self.cell is not None: self.row.append(self.cell.strip())
        self.cell = None
    def finish_row(self):
        self.finish_cell()
        if self.row: self.rows.append(self.row)
        self.row = None

def parse_html(data):
    text = data.decode('latin1'); parsed = DataTable(text)
    index = next((i for i, r in enumerate(parsed.rows) if len(r) > 1 and r[-1].strip().casefold() == 'total'
                  and r[0].strip().casefold() != 'total'), None)
    if index is None: raise ValueError('Tabela HTML sem cabeçalho reconhecido')
    header = parsed.rows[index]
    rows = [r for r in parsed.rows[index+1:] if len(r) == len(header)]
    if not any(r[0].strip().casefold() == 'total' for r in rows): raise ValueError('Tabela HTML sem total geral')
    return {'cabecalho': header, 'linhas': rows}
