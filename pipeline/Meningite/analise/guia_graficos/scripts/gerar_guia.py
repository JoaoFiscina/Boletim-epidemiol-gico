"""Compila o guia e as 14 figuras sem reler casos ou ajustar modelos.
Dependências: reportlab, Pillow, pypdf; Python do runtime Codex.
Uso: python gerar_guia.py --raiz C:/caminho/Meningite
"""
import argparse, hashlib, json, re, html, os
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph, Table, TableStyle
from reportlab.lib.utils import ImageReader
from PIL import Image
from pypdf import PdfReader


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--raiz', required=True)
    ap.add_argument('--fonte-dir', default='C:/Windows/Fonts')
    args = ap.parse_args()
    raiz = Path(args.raiz).absolute()
    pasta = raiz / 'analise/guia_graficos'
    controle = pasta / 'controle'
    controle.mkdir(exist_ok=True)
    src = pasta / 'GUIA_GRAFICOS_MENINGITES.md'
    conteudo = src.read_text(encoding='utf-8')
    expected = {'analise/meningites_salvador_analitica.rds':
                '2fe0f7f6f02d6367b9cfa55487f24016dd57c09f4dc979f8975efd7edbb5247d',
                'analise/aprofundamento/meningites_aprofundamento.rds':
                'ddf2225151a6d638a3b7083f9d5d63cca987d7600fb5d9d6014e1a1dddd711aa'}
    for f, digest in expected.items():
        if sha(raiz / f) != digest:
            raise ValueError(f'Fonte modificada: {f}')
    fontdir = Path(args.fonte_dir)
    for n, f in [('Arial','arial.ttf'),('ArialBold','arialbd.ttf'),('ArialItalic','ariali.ttf')]:
        pdfmetrics.registerFont(TTFont(n,str(fontdir / f)))
    pdfmetrics.registerFontFamily('Arial',normal='Arial',bold='ArialBold',italic='ArialItalic')
    W, H = landscape(A4)
    styles = {'body': ParagraphStyle('body',fontName='Arial',fontSize=11.4,leading=15.6,
                textColor='#161616',spaceAfter=9),
              'head': ParagraphStyle('head',fontName='ArialBold',fontSize=12.5,leading=16.5,
                textColor='#000000',spaceAfter=7),
              'small': ParagraphStyle('small',fontName='Arial',fontSize=10,leading=13,
                textColor='#161616',spaceAfter=8)}
    out = pasta / 'GUIA_GRAFICOS_MENINGITES.pdf'
    c = canvas.Canvas(str(out),pagesize=(W,H),pageCompression=1)
    c.setTitle('Guia dos gráficos de meningites em Salvador')
    c.setAuthor('Projeto de meningites em Salvador')
    c.setSubject('Fontes, leitura, resultados, interpretações e revisão de 14 figuras')
    paginas = []
    imagens = []

    def inline(text):
        text = html.escape(text)
        text = re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',text)
        return re.sub(r'\[([^\]]+)\]\((https?[^)]+)\)',
                      lambda m: f'<link href="{m[2]}" color="#24567A">{m[1]}</link>', text)

    def blocos(text):
        ans=[]
        for p in re.split(r'\n\s*\n',text.strip()):
            if not p or p.startswith('<!--'): continue
            if p.startswith('### '):
                lines=p.splitlines()
                ans.append(('head',lines[0][4:]))
                if len(lines)>1: ans.append(('body',' '.join(lines[1:])))
            else: ans.append(('body',' '.join(p.splitlines())))
        return ans

    def draw(blocks,x,y,width,bottom=39):
        for typ,text in blocks:
            p=Paragraph(inline(text),styles[typ])
            _,h=p.wrap(width,H)
            if y-h<bottom:
                raise ValueError(f'Página {c.getPageNumber()} excedida: {text[:80]}')
            p.drawOn(c,x,y-h)
            y-=h+styles[typ].spaceAfter
        return y

    def start(title,key=None):
        n=c.getPageNumber()
        paginas.append({'pagina':n,'titulo':title,'chave':key})
        c.setFillColorRGB(0,0,0)
        c.setFont('ArialBold',18)
        c.drawString(40,H-38,title)
        if key:
            c.bookmarkPage(key)
            c.addOutlineEntry(title,key,0,False)
        c.setFont('Arial',9)
        c.drawString(40,19,'Meningites em Salvador  |  Guia explicativo  |  Edição 12/10/2026')
        c.drawRightString(W-40,19,str(n))
        return H-66

    def columns(title,text,key=None):
        y=start(title,key)
        bs=blocos(text)
        width=(W-102)/2
        # Divide somente entre parágrafos; mantém um subtítulo com o próximo bloco.
        heights=[]
        for typ,t in bs:
            p=Paragraph(inline(t),styles[typ]); heights.append(p.wrap(width,H)[1]+styles[typ].spaceAfter)
        target=sum(heights)/2
        k=min(range(1,len(bs)),key=lambda k:abs(sum(heights[:k])-target)) if len(bs)>1 else 1
        if k and bs[k-1][0]=='head': k-=1
        draw(bs[:k],40,y,width)
        draw(bs[k:],W/2+11,y,width)
        c.showPage()

    sections=re.split(r'^## ',conteudo,flags=re.M)
    intro=sections[0].split('\n',1)[1]
    docs={s.split('\n',1)[0]:s.split('\n',1)[1] for s in sections[1:]}
    # Página de abertura sem capa vazia: contexto, achados e orientação de leitura.
    y=start('Guia dos gráficos de meningites em Salvador','abertura')
    draw(blocos(intro),85,y,W-170)
    draw([('head','Organização do guia'),('body',
         'Cada figura ocupa uma página ampla, seguida de uma página com dados e cálculo, '
         'modo de leitura, resultado, interpretação, limites e legenda sugerida. '
         'O índice permite saltar diretamente para cada gráfico. '
         'São seis figuras básicas e oito aprofundadas, com quatro revisões de apresentação.')],85,280,W-170)
    c.showPage()
    columns('Dados e sistemas utilizados',docs['Dados e sistemas utilizados'],'sistemas')
    columns('Como ler medidas e incertezas',docs['Como ler medidas e incertezas'],'leitura')
    figures=[(k,v) for k,v in docs.items() if re.match(r'^[FG]\d{2} ',k)]
    assert len(figures)==14
    y=start('Índice dos gráficos','indice')
    c.setFont('Arial',11.4)
    for i,(title,_) in enumerate(figures):
        page=5+i*2; key=title[:3]
        c.drawString(48,y,title)
        c.drawRightString(W-48,y,f'Figura {page}  |  Explicação {page+1}')
        c.linkRect('',key,(44,y-4,W-44,y+12),relative=0,thickness=0)
        y-=28
    c.showPage()
    for title,body in figures:
        key=title[:3]
        rel=re.search(r'<!-- figura: (.+?) -->',body)[1]
        path=Path(os.path.abspath(pasta / rel))
        assert path.is_file()
        # Imagem completa, proporcional, sem corte. Página ampla mantém tipografia legível.
        n=c.getPageNumber()
        c.bookmarkPage(key); c.addOutlineEntry(title,key,0,False)
        paginas.append({'pagina':n,'titulo':title,'chave':key,'tipo':'figura'})
        c.setFont('ArialBold',10); c.drawString(34,H-18,f'{key}  Gráfico básico' if key[0]=='F' else f'{key}  Gráfico aprofundado')
        c.setFont('Arial',9); c.drawRightString(W-34,H-18,'Explicação na página seguinte')
        with Image.open(path) as im:
            px,py=im.size
        ratio=min((W-54)/px,(H-58)/py)
        iw,ih=px*ratio,py*ratio
        c.drawImage(ImageReader(str(path)),(W-iw)/2,30+(H-58-ih)/2,width=iw,height=ih)
        c.setFont('Arial',9); c.drawRightString(W-34,14,str(n)); c.showPage()
        images={'figura':key,'arquivo':path.relative_to(raiz).as_posix(),
                'sha256':sha(path),'pagina_figura':n,'pagina_explicacao':n+1,
                'revisada':rel.startswith('figuras_revisadas/')}
        imagens.append(images)
        text=re.sub(r'<!--.*?-->\s*','',body,flags=re.S)
        columns(title,text,key+'_explicacao')
    columns('Como organizar o argumento do trabalho',docs['Como organizar o argumento do trabalho'],'argumento')
    y=start('Revisão dos gráficos desta edição','revisao')
    revision=docs['Revisão dos gráficos desta edição']
    lines=[s for s in revision.splitlines() if s.startswith('|') and '---' not in s]
    rows=[]
    for line in lines:
        cells=[z.strip() for z in line.strip('|').split('|')]
        rows.append([Paragraph(inline(z),styles['small']) for z in cells])
    table=Table(rows,colWidths=[55,95,W-230])
    table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),'#E4E9EE'),
       ('GRID',(0,0),(-1,-1),.45,'#D9D9D9'),('VALIGN',(0,0),(-1,-1),'MIDDLE'),
       ('TOPPADDING',(0,0),(-1,-1),5),('BOTTOMPADDING',(0,0),(-1,-1),5),
       ('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7)]))
    _,th=table.wrap(W-80,H)
    assert y-th>90
    table.drawOn(c,40,y-th)
    note=re.sub(r'^\|.*\n?','',revision,flags=re.M).strip()
    draw(blocos(note),40,y-th-17,W-80,bottom=32)
    c.showPage()
    # URLs clicáveis com rótulos curtos; fontes/hash completos permanecem no texto editável.
    columns('Referências e rastreabilidade',docs['Referências e rastreabilidade'],'referencias')
    c.save()
    reader=PdfReader(out)
    assert len(reader.pages)==35, len(reader.pages)
    assert len(imagens)==14 and sum(i['revisada'] for i in imagens)==4
    for i,page in enumerate(reader.pages):
        assert len(page.images)>=1 if 4<=i<=31 and i%2==0 else len(page.extract_text())>60
    build={'paginas':paginas,'figuras':imagens,'fontes_rds':expected,
           'texto_sha256':sha(src),'pdf_sha256':sha(out),'n_paginas':len(reader.pages),
           'observacao':'Sem novos downloads, recálculo de modelos ou alteração de bases.'}
    (controle/'BUILD_OUTPUT.json').write_text(json.dumps(build,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'pdf':str(out),'paginas':len(reader.pages),'figuras':len(imagens)},ensure_ascii=False))


if __name__=='__main__':
    main()
