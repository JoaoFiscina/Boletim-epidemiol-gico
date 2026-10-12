"""Audita apenas a edição ilustrada; não recalcula modelos nem consulta serviços.

Uso local: python verificar_guia.py --raiz C:/caminho/Meningite
Clone público: acrescentar --agregados (RDS ausentes declarados, não validados).
Fechamento: --selar --sincronizar --repo C:/caminho/do/manual
"""
import argparse
import hashlib
import json
import re
import shutil
from pathlib import Path

from pypdf import PdfReader


PUBLICOS = [
    'README.md', 'GUIA_GRAFICOS_MENINGITES.md', 'GUIA_GRAFICOS_MENINGITES.pdf',
    'scripts/revisar_basicos.R', 'scripts/gerar_guia.py', 'scripts/verificar_guia.py',
    'figuras_revisadas/F02_perfil_sexo_idade.png',
    'figuras_revisadas/F04_classificacao_etiologica.png',
    'figuras_revisadas/F05_internacoes_disponiveis.png',
    'figuras_revisadas/F06_cobertura_vacinal_registrada.png',
    'controle/BUILD_OUTPUT.json', 'controle/QA_VISUAL.json',
]
FONTES = {
    'analise/meningites_salvador_analitica.rds':
        '2fe0f7f6f02d6367b9cfa55487f24016dd57c09f4dc979f8975efd7edbb5247d',
    'analise/aprofundamento/meningites_aprofundamento.rds':
        'ddf2225151a6d638a3b7083f9d5d63cca987d7600fb5d9d6014e1a1dddd711aa',
}
CODIGOS = [f'F{i:02d}' for i in range(1, 7)] + [f'G{i:02d}' for i in range(1, 9)]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ler(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--raiz', required=True)
    ap.add_argument('--repo')
    ap.add_argument('--agregados', action='store_true')
    ap.add_argument('--selar', action='store_true')
    ap.add_argument('--sincronizar', action='store_true')
    args = ap.parse_args()
    raiz = Path(args.raiz).absolute()
    guia = raiz / 'analise/guia_graficos'
    repo = Path(args.repo).absolute() if args.repo else raiz.parent / 'Boletim epidemiológico'
    if not repo.is_dir():
        repo = None
    if args.agregados and (args.selar or args.sincronizar):
        ap.error('Selar/sincronizar exige conferência local das duas bases RDS.')
    if args.sincronizar and not repo:
        ap.error('Informe --repo existente para sincronizar.')
    checks = []

    def conferir(ok, nome):
        if not ok:
            raise ValueError(nome)
        checks.append(nome)

    for caminho in PUBLICOS:
        conferir((guia / caminho).is_file(), f'Arquivo público presente: {caminho}')
    status_fontes = {}
    for caminho, digest in FONTES.items():
        arq = raiz / caminho
        if args.agregados and not arq.is_file():
            status_fontes[caminho] = 'não conferido: ausente no clone público'
        else:
            conferir(arq.is_file() and sha(arq) == digest, f'Base original preservada: {caminho}')
            status_fontes[caminho] = 'SHA original conferido'

    md = guia / 'GUIA_GRAFICOS_MENINGITES.md'
    pdf = guia / 'GUIA_GRAFICOS_MENINGITES.pdf'
    build = ler(guia / 'controle/BUILD_OUTPUT.json')
    qa = ler(guia / 'controle/QA_VISUAL.json')
    conferir(build['fontes_rds'] == FONTES, 'Bases declaradas no build compatíveis')
    conferir(build['texto_sha256'] == sha(md), 'Texto compatível com PDF compilado')
    conferir(build['pdf_sha256'] == sha(pdf), 'PDF compatível com build')
    conferir(qa['pdf_sha256'] == sha(pdf) and qa['texto_sha256'] == sha(md), 'QA da versão final')
    conferir(qa['status'] == 'aprovado' and len(qa['paginas_pdf']) == 35, '35 páginas inspecionadas')
    conferir([p['pagina'] for p in qa['paginas_pdf']] == list(range(1, 36)), 'QA cobre todas as páginas')
    for pagina in qa['paginas_pdf']:
        render = guia / pagina['png_local']
        if render.is_file():
            conferir(sha(render) == pagina['sha256_png'], f'Render inspecionado preservado: {pagina["pagina"]}')
        elif not args.agregados:
            raise ValueError(f'Render local ausente: {render}')

    figuras = build['figuras']
    conferir([f['figura'] for f in figuras] == CODIGOS, 'Ordem das 14 figuras')
    conferir(sum(f['revisada'] for f in figuras) == 4, 'Quatro básicos revisados')
    conferir([f['pagina_figura'] for f in figuras] == list(range(5, 32, 2)), 'Páginas de figuras')
    conferir([f['pagina_explicacao'] for f in figuras] == list(range(6, 33, 2)), 'Explicação junto a cada figura')
    for figura in figuras + qa['figuras_originais'] + qa['figuras_revisadas']:
        caminho = Path(figura['arquivo'])
        conferir(not caminho.is_absolute() and '..' not in caminho.parts, f'Caminho relativo válido: {figura["figura"]}')
        conferir(sha(raiz / caminho) == figura['sha256'], f'Figura conferida: {figura["arquivo"]}')
    conferir(len(qa['figuras_originais']) == 14 and len(qa['figuras_revisadas']) == 4, 'Escopo visual declarado')
    texto = md.read_text(encoding='utf-8')
    blocos = re.findall(r'^## ([FG]\d{2} [^\n]+)\n(.*?)(?=^## |\Z)', texto, flags=re.M | re.S)
    conferir([b[0][:3] for b in blocos] == CODIGOS, '14 explicações em texto editável')
    for titulo, corpo in blocos:
        for secao in ['Dados e cálculo', 'Como ler', 'Resultado e interpretação', 'Limites e uso no trabalho']:
            conferir(f'### {secao}' in corpo, f'{titulo[:3]}: {secao}')
        conferir('**Legenda sugerida:**' in corpo and '<!-- figura:' in corpo, f'{titulo[:3]}: legenda e imagem')
    reader = PdfReader(pdf)
    conferir(len(reader.pages) == build['n_paginas'] == 35, 'PDF de 35 páginas')
    for numero, page in enumerate(reader.pages, 1):
        if numero in range(5, 32, 2):
            conferir(len(page.images) == 1, f'Imagem incorporada na página {numero}')
        else:
            conferir(len(page.extract_text()) > 60, f'Texto pesquisável na página {numero}')
    conferir(len(reader.pages[3].get('/Annots', [])) == 14, 'Índice clicável com 14 entradas')
    conferir(len(reader.pages[34].get('/Annots', [])) >= 10, 'Links de referências incorporados')

    historicos = []
    if repo:
        espelho = repo / 'pipeline/Meningite'
        for rel in ['manifesto_portabilidade.json', 'analise/manifesto_portabilidade.json',
                    'analise/aprofundamento/manifesto_portabilidade.json']:
            antigo = ler(espelho / rel)
            for item in antigo['arquivos']:
                for origem in [raiz, espelho]:
                    arquivo = origem / item['caminho']
                    conferir(sha(arquivo) == item['sha256'] and arquivo.stat().st_size == item['bytes'],
                             f'Histórico preservado: {origem.name}/{item["caminho"]}')
            historicos.append({'manifesto': rel, 'arquivos_por_raiz': len(antigo['arquivos']),
                               'sha256_manifesto': sha(espelho / rel)})

    manifesto_path = guia / 'controle/MANIFESTO.json'
    if args.selar:
        manifesto = {
            'versao': '20261012-guia-graficos',
            'criterio': 'Lista explícita; documentos e gráficos agregados; sem RDS, fontes individuais ou renders.',
            'arquivos': [{'caminho': f, 'bytes': (guia / f).stat().st_size,
                          'sha256': sha(guia / f)} for f in PUBLICOS],
            'bases_rds': FONTES, 'pdf_paginas': 35, 'figuras': 14, 'revisadas': 4,
            'historicos_preservados': historicos,
        }
        manifesto_path.write_text(json.dumps(manifesto, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    manifesto = ler(manifesto_path)
    conferir([f['caminho'] for f in manifesto['arquivos']] == PUBLICOS, 'Lista pública explícita do manifesto')
    for item in manifesto['arquivos']:
        arquivo = guia / item['caminho']
        conferir(sha(arquivo) == item['sha256'] and arquivo.stat().st_size == item['bytes'],
                 f'Manifesto compatível: {item["caminho"]}')

    if args.sincronizar:
        destino = repo / 'pipeline/Meningite/analise/guia_graficos'
        for rel in PUBLICOS + ['controle/MANIFESTO.json']:
            arquivo = destino / rel
            arquivo.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(guia / rel, arquivo)
    if repo and (repo / 'pipeline/Meningite/analise/guia_graficos').is_dir():
        destino = repo / 'pipeline/Meningite/analise/guia_graficos'
        for rel in PUBLICOS + ['controle/MANIFESTO.json']:
            conferir(sha(guia / rel) == sha(destino / rel), f'Espelho compatível: {rel}')
        conferidos = {p.relative_to(destino).as_posix() for p in destino.rglob('*') if p.is_file()}
        conferir(conferidos == set(PUBLICOS + ['controle/MANIFESTO.json']), 'Git contém somente 13 arquivos autorizados')
    print(json.dumps({'status': 'aprovado', 'controles': len(checks), 'paginas': 35,
                      'figuras': 14, 'revisadas': 4, 'fontes': status_fontes,
                      'historicos': historicos, 'publicos': 13,
                      'limite': 'Integridade e apresentação; sem auditoria clínica ou recálculo de modelos.'},
                     ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
