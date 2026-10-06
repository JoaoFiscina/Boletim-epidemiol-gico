# Operações reproduzíveis

Os comandos abaixo pressupõem Windows PowerShell e a estrutura original em `C:\Pesquisa\Boletim epidemiolóico`. Execute a leitura e a auditoria antes de fazer qualquer nova consulta.

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
& $rscript -e "m <- readRDS('Meningite/pre_analise_meningite.rds'); print(names(m)); print(m\$serie_anual)"
```

O pacote contém objetos separados para série, etiologia, qualidade, denominadores, piloto nacional, SIH e SIM. Não transformar o RDS em uma tabela única que misture unidades.

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
Get-FileHash "$projeto\dados\tratados\sinan_br_piloto\MENIBR24.dbc" -Algorithm SHA256
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

O script de piloto existente é `Meningite\scripts\baixar_piloto_sinan_br.py`; o analisador é `Meningite\scripts\analisar_piloto_br.R`. Inspecione argumentos e manifestos antes de executar. Os arquivos `MENIBR24–26` já foram baixados e não devem ser baixados novamente sem necessidade.

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
git -c safe.directory="$gitmanual" -C $gitmanual add .
git -c safe.directory="$gitmanual" -C $gitmanual commit -m "Documenta manual de analise de meningites"
```

Não adicionar DBC, ZIP, HTML, RDS ou dados brutos ao Git. Se for necessário compartilhar dados públicos, preparar um pacote separado e versionado com manifesto.
