"""Retomada exclusiva autorizada; preserva caches e orcamentos cumulativos locais."""
import sys,json,hashlib,shutil,csv
from pathlib import Path
from datetime import datetime,timezone
from urllib.request import Request,urlopen
sys.dont_write_bytecode=True
import coletor_sih_local as c
import coletor_pni_local as p
AREA=Path(__file__).resolve().parents[1]
ROOT=AREA.parents[2]
CACHE=AREA/'aquisicao';CACHE.mkdir(exist_ok=True)
LEDGER=CACHE/'requisicoes.json'
logs=json.loads(LEDGER.read_text()) if LEDGER.exists() else []
def save():LEDGER.write_text(json.dumps(logs,ensure_ascii=False,indent=2),encoding='utf8')
def fetch(url,body=None,system='SIH',target=None):
    method='GET' if body is None else 'POST'
    maximum=10 if system=='SIH' else 6
    if method=='POST' and sum(x['sistema']==system and x['metodo']=='POST' for x in logs)>=maximum:raise RuntimeError('Teto acumulado de POST atingido')
    attempts=2 if body is not None else 1
    for n in range(attempts):
        fingerprint=hashlib.sha256(body).hexdigest() if body else None
        if body is not None and sum(x.get('payload_sha256')==fingerprint for x in logs)>=2:raise RuntimeError('Duas tentativas ja realizadas para esta consulta')
        rec=dict(sistema=system,metodo=method,url=url,tentativa=n+1,inicio_utc=datetime.now(timezone.utc).isoformat(),payload_sha256=fingerprint)
        logs.append(rec);save()
        try:
            with urlopen(Request(url,data=body,headers={'User-Agent':'Pesquisa-Meningite/20261010','Content-Type':'application/x-www-form-urlencoded'}),timeout=25) as response:
                data=response.read(20*1024*1024+1)
                if len(data)>20*1024*1024:raise RuntimeError('Resposta acima20MiB')
                rec.update(status='obtido',status_http=response.status,bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),url_final=response.geturl())
            if target is None:
                target=CACHE/(system+'_'+str(len(logs))+'.html')
            if target.exists() and target.read_bytes()!=data:raise RuntimeError('Resposta existente diferente')
            target.write_bytes(data);rec['arquivo']=str(target.relative_to(ROOT));save();return data,rec['url_final']
        except Exception as e:
            rec.update(status='falha',erro=type(e).__name__+': '+str(e));save()
            if n==attempts-1:raise

def main():
    c.configure(AREA,'retomada_20261010',10)
    c.fetch=lambda url,body=None:fetch(url,body,'SIH')
    try:
        fetch(c.URLS['SIH'],target=c.RAW/'SIH_formulario_atual.html')
    except Exception:
        shutil.copy2(ROOT/'dados/brutos/complementos_20261009/SIH_formulario_atual.html',c.RAW/'SIH_formulario_atual.html')
        logs.append(dict(sistema='SIH',metodo='CACHE',status='formulario_preservado',arquivo=str((c.RAW/'SIH_formulario_atual.html').relative_to(ROOT)),nota='GET atual falhou; parametros reais preservados09/10'));save()
    sih=c.inspect('SIH')
    simdata=(ROOT/'dados/brutos/complementos_20261009/SIM_formulario.html').read_bytes()
    simmeta=json.loads((ROOT/'metadados/complementos_20261009/SIM_formulario.json').read_text(encoding='utf8'))
    forms={'SIH':sih,'SIM':(c.Form(simdata,c.URLS['SIM']),simmeta)}
    wanted=['SIH_internacoes_diagnostico_ano','SIH_dias_permanencia_diagnostico_ano','SIH_G00_sexo_ano','SIH_A39_sexo_ano','SIH_A39_idade_ano']
    specs={s['id']:s for s in c.job_specs(forms)};tables={};metas={};fails=0
    for key in wanted:
        spec=specs[key]
        if fails>=3:
            metas[key]=dict(status='nao_executado_circuit_breaker',id=key);continue
        tab,meta=c.collect_one(spec,*sih,True);metas[key]=meta
        if tab:tables[key]=tab;fails=0
        else:fails+=1
    qa=c.process(tables,metas)
    p.PROJECT=AREA;p.ROOT=ROOT;p.RAW=CACHE/'pni_brutos';p.TREATED=CACHE/'pni_tratados';p.META=CACHE/'pni_metadados'
    for folder in (p.RAW,p.TREATED,p.META):folder.mkdir(exist_ok=True)
    try:fetch(p.TABNET,system='PNI',target=p.RAW/'tabnet_cobertura_form.html')
    except Exception:
        shutil.copy2(ROOT/'dados/brutos/pni_20261009/tabnet_cobertura_form.html',p.RAW/'tabnet_cobertura_form.html')
        logs.append(dict(sistema='PNI',metodo='CACHE',status='formulario_preservado',nota='GET falhou; formulario real preservado09/10'));save()
    ev=p.Evidence()
    def request(name,url,data=None,headers=None,ephemeral=False):
        body,final=fetch(url,data,'PNI',p.RAW/name)
        return body,{}
    ev.request=request
    pni_results=[]
    for i,key in enumerate(['bcg','meningococica','pneumococica']):
        p.legacy(ev,key)
        result=json.loads((p.META/'resultado_legado.json').read_text(encoding='utf8'))
        success=any(x.get('status')=='extraído' for x in result['validacoes'])
        pni_results.append(dict(indicador=key,concluido=success))
        if i==0 and not success:break
    c.dump(CACHE/'RESULTADO_RETOMADA.json',dict(sih=metas,sih_qa=qa,pni=pni_results,post_sih=sum(x['metodo']=='POST' and x['sistema']=='SIH' for x in logs),post_pni=sum(x['metodo']=='POST' and x['sistema']=='PNI' for x in logs),get=sum(x['metodo']=='GET' for x in logs),historico_preservado='24POST09/10; fora do contador adicional',timeout=25))
    print(json.dumps({'SIH_validas':list(tables),'PNI':pni_results,'requests':len(logs)},ensure_ascii=False))
if __name__=='__main__':main()
