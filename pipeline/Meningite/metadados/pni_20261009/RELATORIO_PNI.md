# PNI: piloto municipal para meningites — 09/10/2026

Foram validados **17 valores anuais de Salvador (IBGE 292740; 2927408 com dígito)**: quatro indicadores do painel por residência em 2023 e 2024, mais nove valores de Penta de 2014–2022 reutilizados da extração de 03/10/2026 com SHA conferido. Há **27 chaves ainda pendentes**, referentes a BCG, meningocócica C e pneumocócica no legado de 2014–2022. Falha de transporte não significa zero nem ausência de vacinação.

A tabela de entrada para análise é `dados/tratados/pni_20261009/pni_cobertura_municipal_2014_2024_longo.csv`. A tabela `disponibilidade_pni_municipal_2014_2024.csv` contém todas as 44 combinações solicitadas, inclusive as pendências explícitas. Os sistemas e perspectivas geográficas permanecem separados por colunas.

## Valores efetivamente medidos no painel oficial

| Indicador exibido pela fonte | Ano | Numerador oficial | Denominador oficial | Cobertura (%) |
|---|---:|---:|---:|---:|
| Meningocócica Conjugada | 2023 | 16.386 | 25.708 | 63,7389 |
| Meningocócica Conjugada | 2024 | 8.689 | 23.494 | 36,9839 |
| Pneumocócica Conjugada | 2023 | 18.124 | 25.708 | 70,4995 |
| Pneumocócica Conjugada | 2024 | 17.735 | 23.494 | 75,4874 |
| Penta (DTP/HepB/Hib) | 2023 | 17.756 | 25.708 | 69,0680 |
| Penta (DTP/HepB/Hib) | 2024 | 17.138 | 23.494 | 72,9463 |
| BCG | 2023 | 3.717 | 25.708 | 14,4585 |
| BCG | 2024 | 9.150 | 23.494 | 38,9461 |

Fonte: [painel público de cobertura por residência do Ministério da Saúde](https://infoms.saude.gov.br/extensions/SEIDIGI_DEMAS_VACINACAO_CALENDARIO_NACIONAL_COBERTURA_RESIDENCIA/index.html). O aplicativo inspecionado é `c39051de-3ffe-47af-a43a-ae74f14be34f`, com recarga informada em **2026-10-09T08:50:39.859Z**. Cada consulta confirmou uma seleção única em Município = `292740 - Salvador`, Ano e Imunobiológico. A razão numerador/denominador foi conferida contra o percentual; o denominador não foi recalculado independentemente neste piloto.

Os rótulos conjugados atuais não devem ser renomeados como MenC ou PCV10 isoladas. O dicionário disponível inclui códigos 41/74 no indicador meningocócico e 26/59/106/107 no pneumocócico. A composição histórica dos produtos administrados não foi aberta neste piloto.

## Penta legada reutilizada

| Ano | Cobertura oficial (%) |
|---:|---:|
| 2014 | 90,42 |
| 2015 | 95,13 |
| 2016 | 87,31 |
| 2017 | 86,63 |
| 2018 | 78,15 |
| 2019 | 59,25 |
| 2020 | 72,31 |
| 2021 | 36,74 |
| 2022 | 59,06 |

Fonte: [TabNet PNI cobertura](https://tabnet.datasus.gov.br/cgi/dhdat.exe?bd_pni/cpnibr.def), exportação municipal de 03/10/2026, consulta `pni_cobertura_2`. Foram conferidos os SHA do CSV e HTML originais, o contexto Penta/Salvador e a menção a Salvador no HTML. As cópias e a cadeia de proveniência estão na pasta nova. Não houve novo download desses dados. O campo geográfico legado foi mantido como município do registro; residência não foi confirmada documentalmente.

## Indicadores, população alvo e mudanças de método

Todos os quatro indicadores selecionados são infantis, para **menores de um ano**. Não utilizar a população total municipal como denominador. Penta é o indicador pertinente ao componente Hib; Hib isolada é outra variável. O reforço de meningocócica/pneumocócica, para outra idade, não foi coletado nem misturado ao esquema básico. BCG é pertinente à meningite tuberculosa, e não a todas as etiologias de meningite.

A [NT 84/2026](https://www.gov.br/saude/pt-br/centrais-de-conteudo/publicacoes/notas-tecnicas/2026/nota-tecnica-no-84-2026-dpni-svsa-ms.pdf) revoga a NT 90/2025 e estende retrospectivamente a metodologia individual a **2023**. Até 2022, o método utilizava a última dose do esquema. No método individual, a RNDS identifica pessoas por CNS/CPF, valida doses/intervalos/idades e admite o registro da última dose como segundo critério. O denominador infantil vem do SINASC; se o ano corrente ainda não estiver fechado, usa-se o imediatamente anterior. A contagem anual é do período considerado e não deve ser obtida somando numeradores mensais deduplicados. Essa norma define o método vigente; o código ETL de deduplicação não é exposto pelo aplicativo público e não foi auditado aqui.

As definições locais de quatro indicadores foram copiadas do dicionário oficial extraído em 03/10/2026, com proveniência e SHA. A entrada IMUNPN10 ainda descreve 2023 pelo método antigo, apesar da NT 84 vigente. Essa inconsistência documental está registrada; o dicionário não comprova a implementação retrospectiva do ETL. Não emendar legado e RNDS em uma tendência única nem atribuir toda ruptura a comportamento vacinal.

A [NT 69/2026](https://www.gov.br/saude/pt-br/centrais-de-conteudo/publicacoes/notas-tecnicas/2026/nota-tecnica-no-69-2026-cgici-dpni-svsa-ms.pdf) define a cobertura pneumocócica conjugada consolidando PCV10, PCV13, PCV15 e PCV20. A soma de indicadores por produto pode divergir da cobertura consolidada. O esquema infantil PCV10 também exige distinguir o período anterior a 2016 do esquema de duas doses adotado em 2016; ver [calendário de 2016](https://bvs.saude.gov.br/bvs/saudelegis/gm/2016/prt1533_18_08_2016.html) e [manual histórico do MS](https://bvsms.saude.gov.br/bvs/publicacoes/manual_vigilancia_epidemiologica_eventos_adversos_pos_vacinacao.pdf). Não aplicar a regra atual de duas doses retrospectivamente a 2014–2015.

As baixas coberturas registradas de BCG e a variação meningocócica exigem investigação da completude e integração dos registros. Há uma pista oficial indexada no informe de qualidade dos dados de abril/2024 que menciona BCG/Salvador, mas o documento integral não pôde ser verificado no acesso atual (redirecionamento para autenticação/timeout). [Link da pista, não utilizado para substituir dados](https://www.gov.br/saude/pt-br/composicao/svsa/pni/monitoramento-dos-dados/informe-qualidade-dos-dados-de-vacinacao-de-abril-de-2024.pdf). Os valores coletados não provam falta de vacinação, vacinação individual nem efetividade.

## Limites do piloto e retomada

Foram registrados **cinco POST tentados, nenhum POST concluído**, 76 chamadas JSON-RPC de leitura em sessões públicas WebSocket, e **4.837.074 bytes** de respostas/envelopes recebidos, abaixo de 20 MiB. Houve quatro falhas iniciais DNS `11001` no TabNet; uma única repetição MenC terminou em timeout `10060`. A MenC já atingiu duas tentativas e foi encerrada. GET do formulário funcionou, mas isso não prova que o serviço POST de tabulação esteja acessível. Nenhum token, cookie ou credencial foi persistido. As respostas JSON originais, os parâmetros e os SHA foram preservados.

O coletor `scripts/coletar_pni_meningites.py` é independente e usa apenas a biblioteca padrão do Python, sem importar scripts de hepatites. O projeto é localizado pelo caminho do próprio script; `--raiz-projeto` permite indicar outra pasta e `--data-lote YYYYMMDD` identifica uma nova coleta independente. O manifesto conserva limites de oito POST concluídos, 16 tentativas totais e duas tentativas por consulta. Na execução atual, não fazer novas consultas RNDS: os oito valores já estão completos.

Para o restante legado, o formulário foi inspecionado e os quatro conjuntos de parâmetros ficaram em `parametros_legado_*.json`. No portal selecionar Linha = Ano, Coluna = Não ativa, anos 2014–2022, Capital = 292740 Salvador e conteúdo BCG, Meningococo C ou Pneumocócica, separadamente. Uma resposta válida precisa confirmar Salvador e conter os anos solicitados; preservar HTML/CSV original e SHA antes de incorporar. Fazer uma nova tentativa apenas com transporte POST comprovadamente funcional e novo lote explicitamente autorizado. Não remover o histórico de falhas nem substituir as pendências por zero.

Para reproduzir a coleta em um novo lote autorizado, executar `inspecionar`, `recente --ano 2023` e `recente --ano 2024`; `legado --indicador ...` restringe cada consulta. O modo `finalizar` é offline e requer as cópias da Penta e sua proveniência, além dos resumos RNDS; ele confirma município, filtros, razão, chave indicador/ano e SHA. Em uma cópia do projeto sem brutos, transportar esses arquivos antes de finalizar. Não reproduzir uma extração já validada apenas para atualizar uma data.

Não foi coletada produção SIA. Ela não fornece cobertura vacinal nem identificação etiológica individual. Eventual uso de procedimentos diagnósticos teria caráter de produção assistencial e exigiria um recorte SIGTAP validado; não há evidência coletada de utilidade adicional para a pergunta atual de meningites.
