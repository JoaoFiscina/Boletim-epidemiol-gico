"""Conferência mecânica local: hashes, chaves, escopos e conservação; não acessa a rede."""
from pathlib import Path
from decimal import Decimal
import argparse, csv, hashlib, json, platform

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def read_csv(path):
    with path.open(encoding='utf-8-sig', newline='') as stream: return list(csv.DictReader(stream, delimiter=';'))

def main():
    args = argparse.ArgumentParser()
    args.add_argument('--diretorio-projeto', default=str(Path(__file__).resolve().parents[1]))
    args.add_argument('--versao', default='complementos_20261009')
    config = args.parse_args()
    base = Path(config.diretorio_projeto).resolve()
    meta = base / 'metadados' / config.versao
    data = base / 'dados' / 'tratados' / config.versao
    result = json.loads((meta / 'RESULTADO_COLETA_COMPLEMENTOS.json').read_text(encoding='utf-8'))
    records, errors = [], []
    for source in result['fontes']:
        if source['status'] != 'conferido': continue
        path = base / source['arquivo_html']
        assert path.exists() and sha(path) == source['sha256_html']
        assert source['municipio_residencia'] == '292740'
        assert source['anos_retornados'] == list(range(2014, 2025))
        pairs = source['parametros']
        archives = [v for k, v in pairs if k == 'Arquivos']
        expected = 132 if source['sistema'] == 'SIH' else 11
        assert len(archives) == len(set(archives)) == expected
        raw_csv = read_csv(data / (source['id'] + '_tabela.csv'))
        has_dash = any(value == '-' for row in raw_csv for value in row.values())
        if has_dash: assert source['zero_legenda_conferido']
        records.append({'consulta': source['id'], 'sha256_conferido': True,
                        'arquivos_periodo': expected, 'anos_retornados': 11,
                        'medida': source['medida'], 'unidade': source['unidade'],
                        'dimensao': source['dimensao'], 'grupo': source['grupo'],
                        'referencia_tempo': source['referencia_tempo'], 'tracos_presentes': has_dash,
                        'legenda_zero_confirmada': source['zero_legenda_conferido'], 'status': 'conferido'})
    schemas = {
        'sih_medidas_anuais_longo.csv': ['cid_grupo', 'ano_processamento', 'medida'],
        'perfis_anuais_longo.csv': ['consulta_id', 'estrato', 'ano'],
        'sih_internacoes_anuais_totais_das_marginais.csv': ['cid_grupo', 'ano_processamento'],
        'comparacao_piloto_versoes.csv': ['cid_grupo', 'ano', 'medida'],
    }
    checks_csv = []
    for output in result['arquivos_tratados']:
        path = base / output['arquivo']
        assert path.exists() and sha(path) == output['sha256']
        rows = read_csv(path)
        keys = schemas.get(path.name)
        if keys:
            tuples = [tuple(r[k] for k in keys) for r in rows]
            assert len(tuples) == len(set(tuples)), 'Chaves duplicadas: ' + path.name
        checks_csv.append({'arquivo': output['arquivo'], 'linhas': len(rows), 'hash_conferido': True,
                           'chave': keys, 'chave_unica': True if keys else None})
    conservation = read_csv(data / 'conferencias.csv')
    assert all(Decimal(r['diferenca']) == 0 for r in conservation)
    totals = read_csv(data / 'sih_internacoes_anuais_totais_das_marginais.csv')
    marginal_sources = [s for s in result['fontes'] if s['status'] == 'conferido' and s['sistema'] == 'SIH'
                        and s['medida'] == 'internacoes' and s['dimensao'] in ('idade', 'sexo')]
    expected_keys = {(s['grupo'], str(y)) for s in marginal_sources for y in s['anos_retornados']}
    assert {(r['cid_grupo'], r['ano_processamento']) for r in totals} == expected_keys
    for source in marginal_sources:
        observed = sum(int(r['internacoes']) for r in totals if r['cid_grupo'] == source['grupo'])
        assert observed == int(source['tabela_total']['Total'].replace('.', ''))
    assert result['POST_realizados'] <= result['limites']['POST']
    assert result['bytes_brutos'] < result['limites']['bytes']
    scope = {'csv_longo_SIH': 'grupo diagnostico × ano processamento × medida; obitos e valores separados por unidade',
             'csv_perfis': 'consulta × estrato × ano; medidas separadas SIH/SIM; nao e sexo×idade conjunto',
             'csv_totais_marginais': 'um total de internacoes por CID×ano; origens concordantes nao sao somadas',
             'tabelas_SIH_originais': 'incluem capitulos e subtotais; nao agregar pais com folhas',
             'tabela_SIM_idade': 'obitos causa basica do conjunto G00-G03/A39/A87, e nao tipos individuais',
             'csv_comparacao': 'snapshots separados; branco nao significa zero nem falta de internacoes'}
    verified = {'status': 'conferencia_mecanica_passou', 'python': platform.python_version(),
                'consultas_validas': records, 'csvs_conferidos': checks_csv,
                'conservacoes_sem_diferenca': len(conservation), 'escopos': scope,
                'pendencias_coleta': [s['id'] for s in result['pendencias']],
                'status_coleta': result['status'],
                'nota': 'Conferencia mecanica confirma arquivo e contagem; nao valida clinicamente diagnostico ou pessoas unicas.'}
    (meta / 'CONFERENCIA_MECANICA.json').write_text(json.dumps(verified, ensure_ascii=False, indent=2), encoding='utf-8')
    print('Hashes/chaves/escopos conferidos; ' + str(len(conservation)) + ' conservações; coleta ' + str(result['consultas_conferidas']) + '/11.')

if __name__ == '__main__': main()
