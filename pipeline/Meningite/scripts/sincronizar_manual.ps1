param(
    [string]$Projeto = (Split-Path -Parent $PSScriptRoot),
    [string]$Repositorio = '',
    [string]$Versao = '20261009'
)
$ErrorActionPreference = 'Stop'
$Projeto = (Resolve-Path -LiteralPath $Projeto).Path
if (-not $Repositorio) { $Repositorio = Join-Path (Split-Path -Parent $Projeto) 'Boletim epidemiológico' }
$Repositorio = (Resolve-Path -LiteralPath $Repositorio).Path
if ($Versao -notmatch '^\d{8}$') { throw 'Versão deve ser AAAAMMDD.' }
$destino = Join-Path $Repositorio 'pipeline\Meningite'
New-Item -Path $destino -ItemType Directory -Force | Out-Null

# Lista explícita: nunca sincronizar DBC,ZIP,HTML,RDS,logs ou registros individuais.
$obrigatorios = @(
    'config\coleta_integral.json',
    'PLANO_COLETA_INTEGRAL.md',
    'scripts\coletar_sinan_br_historico.py',
    'scripts\processar_sinan_br_historico.R',
    'dados\denominadores\populacao_total.csv',
    'dados\denominadores\populacao_sexo_idade_original.csv',
    'dados\denominadores\populacao_faixas_sinan.csv',
    'dados\tratados\sinan\meningite_sinan_longo.csv',
    'metadados\DENOMINADORES.json'
)
$opcionais = @(
    'scripts\abrir_pacote.R',
    'scripts\consolidar_coleta.R',
    'scripts\sincronizar_manual.ps1',
    'scripts\verificar_entrega_manual.py',
    'scripts\_tabnet_complementos.py',
    'scripts\coletar_complementos_20261009.py',
    'scripts\conferir_complementos_20261009.py',
    'scripts\coletar_pni_meningites.py',
    'RELATORIO_COLETA_INTEGRAL_20261009.md',
    "metadados\sinan_br_$Versao\RESULTADO_PROCESSAMENTO.json",
    "dados\tratados\sinan_br_$Versao\serie_anual.csv",
    "dados\tratados\sinan_br_$Versao\serie_mensal.csv",
    "dados\tratados\sinan_br_$Versao\qualidade_anual.csv",
    "dados\tratados\sinan_br_$Versao\marginais_anuais.csv",
    "dados\tratados\sinan_br_$Versao\base_conjunta_agregada.csv",
    "dados\tratados\sinan_br_$Versao\comparacao_tabnet_snapshot20261005.csv",
    "dados\tratados\sinan_br_$Versao\etiologia_codigos_fora_dominio_1_10.csv",
    'dados\tratados\pni_20261009\cobertura_rnds_piloto_2023.csv',
    'dados\tratados\pni_20261009\cobertura_rnds_piloto_2024.csv',
    'dados\tratados\pni_20261009\cobertura_legado_penta_cache_2014_2022.csv',
    'dados\tratados\pni_20261009\pni_cobertura_municipal_2014_2024_longo.csv',
    'dados\tratados\pni_20261009\disponibilidade_pni_municipal_2014_2024.csv',
    'metadados\pni_20261009\RELATORIO_PNI.md',
    'metadados\pni_20261009\validacao_piloto.json',
    'metadados\pni_20261009\indicadores_solicitados_disponiveis.csv',
    'metadados\pni_20261009\definicoes_indicadores_snapshot_20261003.csv',
    'metadados\complementos_20261009\RELATORIO_COMPLEMENTOS.md',
    'metadados\complementos_20261009\RESULTADO_COLETA_COMPLEMENTOS.json',
    'metadados\complementos_20261009\CONFERENCIA_MECANICA.json',
    'dados\tratados\complementos_20261009\sih_medidas_anuais_longo.csv',
    'dados\tratados\complementos_20261009\sih_internacoes_anuais_totais_das_marginais.csv',
    'dados\tratados\complementos_20261009\perfis_anuais_longo.csv',
    'dados\tratados\complementos_20261009\conferencias.csv',
    'metadados\CONSOLIDACAO_20261009.json',
    'metadados\auditoria_independente_20261009\AUDITORIA_SINAN.md',
    'metadados\auditoria_independente_20261009\AUDITORIA_DENOMINADORES_PORTABILIDADE.md'
)
foreach ($relativo in $obrigatorios) {
    if (-not (Test-Path -LiteralPath (Join-Path $Projeto $relativo) -PathType Leaf)) { throw "Fonte obrigatória ausente: $relativo" }
}
$manifesto = @()
foreach ($relativo in ($obrigatorios + $opcionais)) {
    $origem = Join-Path $Projeto $relativo
    if (-not (Test-Path -LiteralPath $origem -PathType Leaf)) { continue }
    $saida = Join-Path $destino $relativo
    New-Item -Path (Split-Path -Parent $saida) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $origem -Destination $saida
    $hashOrigem = (Get-FileHash -LiteralPath $origem -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashSaida = (Get-FileHash -LiteralPath $saida -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hashOrigem -ne $hashSaida) { throw "Cópia divergente: $relativo" }
    $manifesto += [PSCustomObject]@{ caminho = $relativo.Replace('\','/'); bytes = (Get-Item -LiteralPath $origem).Length; sha256 = $hashOrigem }
}
$controle = [PSCustomObject]@{
    sincronizado_em = (Get-Date).ToString('o'); versao = $Versao
    criterio = 'Somente código,configuração,planos,agregados públicos e denominadores; sem brutos e bases individuais'
    arquivos = $manifesto
}
$controle | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $destino 'manifesto_portabilidade.json') -Encoding UTF8
Write-Output "SINCRONIZADOS: $($manifesto.Count) arquivos com SHA-256 idêntico. Git não foi publicado."
