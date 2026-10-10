# Base analítica de meningites — Salvador, 2014–2024

Entrega executada em **10/10/2026**, após o comando “Agora inicie o plano”. Esta pasta é a entrada principal para análise. O núcleo contém **1.976 registros confirmados do SINAN**, residentes de Salvador, selecionados pelo ano dos primeiros sintomas. A população corresponde ao mesmo município, ano, sexo e faixa etária. Dados brutos e versões anteriores permanecem preservados fora desta pasta.

Comece pelo [relatório descritivo](resultados/RELATORIO_DESCRITIVO.md): resultados, denominadores, limites e seis figuras em PNG/PDF. Para analisar no R, abra o pacote local `meningites_salvador_analitica.rds`. Para outros programas, use apenas as sete bases em `dados/`, junto ao [dicionário](documentacao/dicionario.csv), às [fontes](documentacao/fontes.csv) e à [cobertura](documentacao/cobertura.csv).

## Abrir no RStudio

```r
pasta <- "C:/Pesquisa/Boletim epidemiolóico/Meningite"
m <- readRDS(file.path(pasta, "analise/meningites_salvador_analitica.rds"))
names(m)
m$estado
names(m$resultados$tabelas)
m$resultados$tabelas$serie_anual
m$dados$sinan_mensal
m$dados$sih
m$documentacao$cobertura
# Registros individuais: somente no pacote local, sem envio ao Git.
m$SINAN$casos_minimos_locais
```

Só abrir o RDS requer R; não exige instalar pacotes adicionais. O RDS reúne módulos por fonte, sete bases canônicas, tabelas descritivas, configuração, dicionário, fontes, cobertura e validação. Evite somar tabelas ou marginais de fontes distintas.

## Sete bases essenciais

| CSV em `dados/` | Uma linha representa | Cuidados de análise |
|---|---|---|
| `sinan_estratos_anuais.csv` | Ano dos sintomas × sexo conhecido × faixa etária; 242 estratos | Soma 1.975 registros. Um sexo ignorado permanece no RDS, sem denominador fabricado. |
| `sinan_mensal.csv` | Ano × mês dos sintomas; 132 meses | Soma 1.976. Agosto/2020 é zero derivado da coorte integral; outras fontes não receberam preenchimento por zero. |
| `sinan_categorias_anuais.csv` | Ano × dimensão × categoria | Sexo, idade, etiologia, evolução e critério são marginais distintas; não somar dimensões entre si. Categorias originais e resíduos preservados. |
| `populacao.csv` | Ano × sexo × faixa etária; 242 estratos | Somar só estratos disjuntos. Totais e mapas separados estão no RDS. |
| `sih.csv` | Ano de processamento × CID × medida × tipo/dimensão/estrato | Filtrar `tipo_tabela` e `medida`. AIHs/episódios; marginais não são registros individuais. 572 linhas, com ausências explícitas. |
| `sim.csv` | Ano de ocorrência × tipo/dimensão/estrato | 143 linhas; separar total e perfil. Causa básica, residência Salvador, arquivo de registro BA; cobertura nacional não demonstrada. |
| `pni.csv` | Ano × indicador × método/geografia/esquema | 44 chaves: 17 percentuais disponíveis e 27 ausentes. Legado e RNDS não constituem automaticamente uma série harmonizada. |

CSV: UTF-8, separador `;`, decimal `.`, campo numérico vazio = `NA`. Não preencher toda a tabela com zero. Manter códigos municipais e códigos originais como texto; o dicionário especifica os tipos. Exemplo:

```r
d <- read.csv(file.path(pasta, "analise/dados/sih.csv"), sep=";", dec=".",
              fileEncoding="UTF-8", na.strings="", check.names=FALSE,
              colClasses=c(municipio_residencia="character", cid_grupo="character"))
internacoes <- subset(d, tipo_tabela == "total" & medida == "internacoes")
```

O CSV único `resultados/descritivos.csv` contém D01–D10 em formato longo. A coluna `tabela` identifica o conjunto; numerador, denominador, unidade, status e intervalo de confiança acompanham os valores. Contagem e proporção são medidas diferentes do mesmo resultado e não devem ser somadas.

## Qualidade e abrangência

Os **352 controles da preparação** foram aprovados. As revisões independentes acrescentaram **39 verificações SINAN/população** e **17 verificações dos complementos**, com escopos distintos; não são 408 testes independentes da mesma propriedade. Todos os seis PNGs e os seis PDFs renderizados foram inspecionados. Consulte [validação](controle/validacao.json), [QA visual](controle/QA_VISUAL.json), [revisão SINAN](documentacao/REVISAO_SINAN_POPULACAO.md) e [revisão dos complementos](documentacao/REVISAO_COMPLEMENTOS.md).

- SINAN: 572 células comparáveis ao TabNet sem diferença; seis códigos etiológicos não canônicos e dois vazios conservados. Há 144 evoluções desconhecidas. Não demonstra pessoas únicas, ausência de subnotificação ou validação clínica.
- SIH: totais disponíveis G00 = 532, A39 = 122 e A87 = 489. Dias de permanência = 12.250 e valores aprovados nominais = R$ 2.354.667,12 nas seis folhas selecionadas. Óbitos = **75 somente nas cinco folhas com retorno**; G01 permanece sem valor em onze anos. Não há total completo de internações dos seis grupos nem média de permanência com denominador completo.
- SIM: 202 óbitos nos códigos selecionados; não usar SIM/SINAN como letalidade nem assumir cobertura de registro em todas as UFs.
- PNI: 27 lacunas legadas persistem. Conjugadas atuais não equivalem a produtos exclusivos MenC/PCV10. BCG baixo exige auditoria; este conjunto não demonstra eficácia vacinal.

A taxa anual usa a população do mesmo ano. A taxa média do período usa a soma das onze populações anuais como aproximação de habitantes-ano. IC95 exato de Poisson representa incerteza da contagem registrada e não corrige subnotificação ou incerteza populacional. Esta entrega é descritiva; modelos devem responder a uma pergunta previamente definida.

## Reproduzir a preparação

O controlador funciona **offline**. Não baixa dados ao abrir o RDS ou ao repetir a preparação. Usa o pacote congelado `dados/tratados/meningites_salvador_20261009.rds` e as fontes/caches complementares auditadas. A flag `coletar_complementos` na configuração registra a aquisição autorizada desta rodada; não dispara rede no controlador R.

Na máquina original, a partir de `C:\Pesquisa\Boletim epidemiolóico`:

```powershell
$env:LC_ALL = 'Portuguese_Brazil.utf8'
$env:R_LIBS_USER = 'C:/Users/joaov/AppData/Local/R/win-library/4.5'
& 'C:\R\R\R-4.5.1\bin\x64\Rscript.exe' 'Meningite\analise\scripts\executar_etapa.R' 'Meningite' --inventario
& 'C:\R\R\R-4.5.1\bin\x64\Rscript.exe' 'Meningite\analise\scripts\executar_etapa.R' 'Meningite'
```

Foram usados R 4.5.1, jsonlite 2.0.0, digest 0.6.37 e ggplot2 4.0.2. Em outro computador, adapte executáveis/bibliotecas. O controlador verifica hash de entrada, configuração, grades, tipos, junções e releitura antes de promover saídas. A preparação exige fontes locais compatíveis; somente copiar o código do Git não transporta DBC, respostas brutas ou RDS.

Para regenerar somente apresentação, use `--relatorio` ou `--figura F02_perfil_sexo_idade`, sem recalcular a base. **Qualquer regeneração exige conferir as figuras afetadas e atualizar o QA e os hashes.** Com Python disponível:

```powershell
python 'Meningite\analise\scripts\conferir_entrega.py' 'Meningite' --selar
python 'Meningite\analise\scripts\conferir_entrega.py' 'Meningite'
```

O selo recusa figuras cujo hash difira do QA inspecionado. Não cria aceite visual automaticamente. `--sincronizar` copia apenas a lista pública permitida ao manual local e confere hashes; não executa commit nem push.

## Coleta seletiva e continuidade

A rodada adicional usou 9 POST SIH, 2 POST PNI e 2 GET; obteve dias de permanência e A39 por sexo. Persistem três consultas SIH: internações gerais, G00 por sexo e A39 por idade. BCG falhou duas vezes e interrompeu o PNI antes das outras consultas. O ledger preserva erros, parâmetros e hashes; falhas não viraram ausência epidemiológica.

Os coletores em `trabalho/complementos/scripts/` pertencem ao perfil executado de 10/10, com seleção exclusiva e orçamento limitado. Parâmetros, resultados e requisições estão em `trabalho/complementos/aquisicao/`. A configuração R não parametriza automaticamente esses coletores históricos: alterar janela, limite ou perfil exige conferir o código e as fontes antes de executar. Evitar repetir consultas válidas.

Para trabalhar em outra máquina, as sete bases públicas e descritivos do Git podem ser lidos imediatamente. Para abrir tudo no R, transferir o RDS local por meio privado apropriado. Para reprodução integral, transportar as fontes com manifestos ou repetir a coleta oficial; novos downloads podem ter revisões e outros hashes. As [decisões](documentacao/decisoes.md) explicam filtros, mudanças e limites. `trabalho/` e `controle/` guardam preparação e auditoria; não são novas bases concorrentes para análise.
