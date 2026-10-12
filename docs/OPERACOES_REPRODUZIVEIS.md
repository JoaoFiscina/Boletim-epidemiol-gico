# Operações reproduzíveis

Os comandos abaixo pressupõem Windows PowerShell e a estrutura original em `C:\Pesquisa\Boletim epidemiolóico`. Execute a leitura e a auditoria antes de fazer qualquer nova consulta.

## Entrada vigente: guia explicativo de 12/10

Abra o [PDF dos 14 gráficos](../pipeline/Meningite/analise/guia_graficos/GUIA_GRAFICOS_MENINGITES.pdf), com 35 páginas, e leia o [README do guia](../pipeline/Meningite/analise/guia_graficos/README.md). O PDF pode ser enviado sozinho; contém todas as figuras. As quatro revisões estão em `figuras_revisadas/`. O texto Markdown é a fonte editável. Não executar aquisição nem modelos para editar o documento.

Para conferir a edição local, sem mudar arquivos:

```powershell
& 'C:/Users/joaov/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' 'C:/Pesquisa/Boletim epidemiolóico/Meningite/analise/guia_graficos/scripts/verificar_guia.py' --raiz 'C:/Pesquisa/Boletim epidemiolóico/Meningite' --repo 'C:/Pesquisa/Boletim epidemiolóico/Boletim epidemiológico'
```

Regenerar gráficos exige o RDS básico aceito, ggplot2/patchwork/digest e `revisar_basicos.R`. Compilar o texto/imagens exige os dois RDS com SHA esperado, Python reportlab/Pillow/pypdf, fontes Arial e `gerar_guia.py --raiz`. Os comandos completos estão no README. Não há instalação automática. Depois de mudar texto/figura, renderizar e inspecionar as páginas afetadas, registrar hashes e só então selar com o verificador desta edição.

`--selar --sincronizar --repo` cria o manifesto do guia e espelha sua lista explícita de 13 arquivos. Esses parâmetros não atualizam manifestos históricos. Em clone público, `--agregados` permite validar o guia sem RDS, declarando as bases não conferidas. Os renders ficam locais; o QA guarda seus hashes no Git. Conferir também o SHA dos arquivos no índice antes do commit para evitar conversão de finais de linha.

## Reprodução do aprofundamento de 12/10

Ler [README do aprofundamento](../pipeline/Meningite/analise/aprofundamento/README.md), relatório, decisões, proveniência e revisões. Abrir o RDS agregado não recalcula ou baixa dados. O controlador R recalcula apenas esta etapa usando a fonte aprovada, com SHA bloqueante e módulos source-only. Pacotes existentes: jsonlite, digest, ggplot2, patchwork, MASS e sandwich; verificar bibliotecas antes de instalar.

```powershell
$env:LC_ALL = 'Portuguese_Brazil.utf8'
$env:R_LIBS_USER = 'C:/Users/joaov/AppData/Local/R/win-library/4.5'
& 'C:/R/R/R-4.5.1/bin/x64/Rscript.exe' 'C:/Pesquisa/Boletim epidemiolóico/Meningite/analise/aprofundamento/scripts/executar_aprofundamento.R' 'C:/Pesquisa/Boletim epidemiolóico/Meningite'
```

Os dois CSVs usam UTF-8, `;`, ponto decimal e vazio como NA. Reler com schema definido para preservar eixos/códigos e Inf explicitamente sinalizado. Filtrar tabela/medida/eixos; não somar níveis do longo. A função de figuras aceita o pacote integrado e carrega patchwork explicitamente. O aviso ggplot2 compilado em R4.5.3 no runtime4.5.1 foi observado; a execução, exportação e inspeção concluíram, sem instalar outro runtime.

Após mudar uma figura ou método, repetir somente verificações afetadas, renderizar páginas PDF e registrar hashes; depois selar com o verificador próprio `analise/aprofundamento/scripts/verificar_aprofundamento.py`. Não usar `--selar` ou `--sincronizar` da preparação anterior para esta etapa. Espelhar apenas a lista pública do novo pacote, sem RDS/fontes individuais, e preservar os manifestos de 09/10 e 10/10.

## Entrada atual: preparação analítica de 10/10

Comece pelo [guia da base analítica](../pipeline/Meningite/analise/README.md), com comandos R offline, tipos CSV, flags de apresentação e conferência de entrega. Abrir o RDS não baixa dados; repetir a preparação exige fontes locais/caches com os hashes declarados. Em clone, sete CSVs, descritivos e figuras estão disponíveis; RDS, brutos e bases individuais precisam ser transferidos ou coletados separadamente.

Os coletores seletivos de 10/10 ficam em `pipeline/Meningite/analise/trabalho/complementos/scripts/`, com ledgers em `aquisicao/`. O perfil/orçamento é explícito no código da rodada, sem leitura automática da configuração analítica R. Foram tentadas exclusivamente cinco pendências SIH, concluindo duas, e BCG legado com interrupção após duas falhas. Não executar novamente apenas porque o script está disponível. A preparação e o [selo](../pipeline/Meningite/analise/controle/VERIFICACAO_ENTREGA.json) foram conferidos; nenhuma consulta pendente foi transformada em zero.

## 1. Conferir ambiente

```powershell
$raiz = 'C:\Pesquisa\Boletim epidemiolóico'
$projeto = Join-Path $raiz 'Meningite'
$python = 'C:\Users\joaov\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$rscript = 'C:\R\R\R-4.5.1\bin\x64\Rscript.exe'
Test-Path $projeto
Test-Path $python
Test-Path $rscript
```

Se algum caminho não existir, localizar a instalação real antes de prosseguir. Não instalar dependências automaticamente durante uma coleta.

## 2. Ler o pacote R existente

```powershell
$env:LC_ALL = 'Portuguese_Brazil.utf8'
Set-Location $raiz
& $rscript "$projeto\scripts\abrir_pacote.R" "$projeto\dados\tratados\meningites_salvador_20261009.rds"
```

O pacote atual contém listas SINAN, população, SIH, SIM e PNI. O anterior está em `pre_analise_meningite.rds`, preservado. Use arquivo `.R`: a auditoria reproduziu perda de aspas internas em `Rscript -e` no Windows PowerShell 5.1. No RStudio, `m <- readRDS(...)` pode ser usado diretamente.

## 3. Reproduzir a pré-análise local

```powershell
& $python "$projeto\scripts\pre_analisar.py"
$env:LC_ALL = 'Portuguese_Brazil.utf8'
& $rscript "$projeto\scripts\pre_analisar.R" $projeto
```

O script local gera as três figuras, atualiza tabelas de taxas e salva/relê o RDS. Ele não baixa dados.

Para atualizar apenas o pacote após uma alteração de tabelas auxiliares:

```powershell
& $rscript "$projeto\scripts\pre_analisar.R" $projeto --somente-pacote
```

## 4. Conferir hashes sem alterar arquivos

```powershell
Get-FileHash "$projeto\dados\denominadores\populacao_total.csv" -Algorithm SHA256
Get-FileHash "$projeto\dados\denominadores\populacao_sexo_idade_original.csv" -Algorithm SHA256
Get-FileHash "$projeto\dados\brutos\sinan_br_piloto\MENIBR24.dbc" -Algorithm SHA256
```

Os valores esperados dos arquivos principais estão nos manifestos em `Meningite\metadados`. Se o hash mudar, criar nova versão e registrar por que mudou.

## 5. Completar o piloto nacional histórico

Use primeiro o catálogo oficial para confirmar os arquivos reais e a modalidade (“Dados - Finais” ou “Dados - Preliminares”). A rotina prevista é:

```text
catalogar -> selecionar MENIBR14 ... MENIBR23 -> baixar ZIP oficial
preservar ZIP e DBC -> calcular SHA-256 -> ler DBC em R
agregar por arquivo -> filtrar residência e confirmação
comparar com TabNet -> registrar divergências e cobertura
```

O script de piloto existente é `Meningite\scripts\baixar_piloto_br.py`; o analisador é `Meningite\scripts\analisar_piloto_br.R`. Inspecione argumentos e manifestos antes de executar. Os arquivos `MENIBR24–26` já foram baixados e não devem ser baixados novamente sem necessidade. A coleta histórica nova é `coletar_sinan_br_historico.py`, com leitura em `processar_sinan_br_historico.R`; consultar o estado atual antes de usar as instruções históricas desta seção.

### Rodada integral executada em 09/10/2026

```powershell
& $python "$projeto\scripts\coletar_sinan_br_historico.py" --versao 20261009 --baixar --lote 3 --teto-mb 80
$env:R_LIBS_USER = 'C:/Users/joaov/AppData/Local/R/win-library/4.5'
& $rscript "$projeto\scripts\processar_sinan_br_historico.R" $projeto 20261009
```

O primeiro comando consulta o catálogo, reaproveita hashes válidos e solicita apenas pendentes. O segundo lê os13DBC localmente. Em outra máquina, conferir a bibliotecaR e os caminhos reais. DNS11001/WinError10013 no ambiente restrito pode exigir autorização de rede; não interpretar como indisponibilidade epidemiológica ouzero. Os erros são mantidos no histórico, e uma requisição pública só deve ser repetida dentro do teto registrado.

O caminho `R_LIBS_USER` é o usado nesta máquina; substituir pela biblioteca real no computador do amigo. Pacotes necessários: `read.dbc`, `jsonlite`, `digest`. Python 3.9+; nenhuma instalação automática. O JSON de configuração documenta o perfil; os períodos SINAN são explícitos no código. A versão atualiza a pasta/data de auditoria, não amplia automaticamente anos de coleta ou sintomas.

### Consolidar a rodada já coletada, sem rede

```powershell
& $rscript "$projeto\scripts\consolidar_coleta.R" $projeto 20261009
& $rscript "$projeto\scripts\abrir_pacote.R" "$projeto\dados\tratados\meningites_salvador_20261009.rds"
```

A consolidação exige os resultados válidos dos complementos e PNI, além do RDS SINAN. Se faltarem entradas, interrompe; não fabrica uma fonte vazia. O clone Git contém agregados e código, mas não inclui DBC/RDS: coletar ou transportar os brutos para repetir o processamento integral.

## 6. Leitura DBC em R

Exemplo conceitual, usando o pacote já instalado:

```r
library(read.dbc)
dados <- read.dbc("MENIBR24.dbc")
names(dados)
```

A leitura deve ser acompanhada da contagem de linhas, número de colunas, tipos, domínios e datas. Não exportar identificadores individuais para o relatório. As saídas atuais do piloto são agregadas.

## 7. Coleta TabNet

O formulário oficial deve ser inspecionado para obter nomes exatos de campos e opções. Salvar:

```text
URL do formulário
endpoint POST
parâmetros Linha/Coluna/Incremento/Arquivos/filtros
data e hora
referência temporal
território e perspectiva
conteúdo da resposta original
SHA-256
```

O link CSV que aparece na resposta pode ser temporário. Não fixar um nome de download adivinhado. Se houver timeout, repetir uma vez com lote menor e registrar a falha; não interpretar timeout como zero.

## 8. SIH e SIM

Executar as consultas com o mesmo município e a mesma referência temporal documentados. Manter em arquivos diferentes:

```text
SINAN: ano dos primeiros sintomas / caso-notificação
SIH: ano de processamento / internação ou AIH
SIM: ano do óbito / causa básica
```

Se uma linha CID não vier na resposta, marcar `linha_omitida_sem_imputacao`; não gravar zero. Antes de incluir custo, permanência ou idade, confirmar que o campo realmente foi coletado.

As duas frentes encerraram a rodada dentro dos limites; consultar `docs/ESTADO_COLETA.md` e os relatórios próprios antes de retomar. Para inventário de argumentos, sem downloads:

```powershell
& $python "$projeto\scripts\coletar_complementos_20261009.py" --help
& $python "$projeto\scripts\coletar_pni_meningites.py" --help
```

SIH pode retornar capítulos, grupos intermediários e folhas CID na mesma tabela. Somar apenas folhas do recorte, conferindo contra TOTAL oficial. Dois perfis A87 são conferências do mesmo universo, não novas internações. PNI mantém legado e RNDS separados; não chamar cobertura conjugada atual de vacina monovalente específica.

## 9. Fechamento da coleta

Só congelar uma base analítica quando:

1. os arquivos e respostas tiverem hashes;
2. os filtros e universos estiverem escritos;
3. totais forem comparados por pelo menos três recortes;
4. ausência e zero estiverem diferenciados;
5. versões preliminares/finais não forem misturadas;
6. o relatório declarar o que continua pendente.

## 10. Comandos Git

O diretório do manual já possui um Git. Como o Windows pode acusar “dubious ownership” neste ambiente, use o `safe.directory` apenas no comando necessário:

```powershell
$gitmanual = 'C:\Pesquisa\Boletim epidemiolóico\Boletim epidemiológico'
git -c safe.directory="$gitmanual" -C $gitmanual status --short --branch
git -c safe.directory="$gitmanual" -C $gitmanual diff --stat
git -c safe.directory="$gitmanual" -C $gitmanual add README.md CHANGELOG.md docs pipeline
git -c safe.directory="$gitmanual" -C $gitmanual commit -m "Documenta manual de analise de meningites"
```

Não adicionar DBC, ZIP, HTML, RDS ou dados brutos ao Git. Se for necessário compartilhar dados públicos, preparar um pacote separado e versionado com manifesto.

O sincronizador faz cópias por lista explícita e confere SHA, sem commit/publicação automática:

```powershell
& "$projeto\scripts\sincronizar_manual.ps1" -Projeto $projeto -Repositorio $gitmanual -Versao 20261009
```
