# Plano de aprofundamento — meningites em Salvador

Data: 10/10/2026. **Somente planejamento.** Pedido: identificar análises além dos resultados entregues e propor gráficos diferentes. Foram lidos relatório, documentação, dicionários locais e nomes dos campos/tabelas no RDS; não foram calculados novos cruzamentos, ajustados modelos, geradas figuras ou feitas novas consultas DATASUS. A implementação deste plano fica para um comando posterior.

Entrega de referência: [guia da base](analise/README.md) e [relatório já executado](analise/resultados/RELATORIO_DESCRITIVO.md).

## 1. Argumento científico e pergunta principal

A etapa entregue descreve ocorrência anual, sexo/idade separadamente, distribuição mensal, composição etiológica, evolução, internações selecionadas e vacinação parcial. O próximo ganho é relacionar essas dimensões e avaliar a estabilidade das conclusões. A existência de mais campos não implica que todos sejam utilizáveis.

**Pergunta principal proposta:** como mudaram a ocorrência registrada, o perfil por idade/sexo e a classificação/investigação de meningites e doença meningocócica em residentes de Salvador entre 2014 e 2024?

Perguntas secundárias: a diferença entre sexos persiste dentro das idades? Mudou a frequência registrada de cada grupo etiológico ou apenas sua participação no total? A mudança de critérios e a incompletude acompanham essas mudanças? Quais grupos concentram evolução registrada para óbito e maior intervalo até notificação? As séries hospitalares mostram trajetórias distintas, dentro de seus próprios universos?

O título precisa corresponder à definição: a coorte inclui meningococcemia isolada (MCC). Manter “meningites e doença meningocócica” no escopo; se o trabalho adotar exclusivamente meningites, delimitar clinicamente e apresentar sensibilidade excluindo MCC isolada, sem eliminar essa categoria silenciosamente.

Não há desenho que atribua a queda à vacinação, à pandemia ou a mudança de agentes. Essas explicações são hipóteses para discussão e estudos posteriores. O projeto atual pode avaliar padrões de registro e associações, com limites explícitos.

## 2. Ponto de partida confirmado

- RDS aceito: `analise/meningites_salvador_analitica.rds`, SHA-256 `2fe0f7f6f02d6367b9cfa55487f24016dd57c09f4dc979f8975efd7edbb5247d`; 1.976 registros, residência 292740, confirmação final, primeiros sintomas 2014–2024.
- Sete CSVs essenciais, D01–D10, seis figuras PNG/PDF, 352 controles e revisões independentes de 39/17 verificações. Onze anos, 132 meses e população por ano/sexo/idade compatível.
- Resultados já entregues: taxa anual 13,34→6,31/100 mil; razão descritiva masculino/feminino 1,57; maior taxa em menores de 1 ano. Não são resultados novos deste plano.
- A classificação MV passou de 64,3% em 2014 para 29,6% em 2024; MNE, de 12,2% para 25,9%. É necessário separar composição, frequência registrada e qualidade da classificação.
- Evolução desconhecida: 144/1.976; em 2024, 32/162. Mediana sintomas–notificação já descrita: 5 dias. Não equivale a tempo até diagnóstico.
- SIH: G00=532, A39=122, A87=489; dias e valores nominais em seis folhas; óbitos parciais em cinco folhas, com G01 ausente. SIM registra 202 óbitos em arquivos BA. PNI mantém 17 valores e 27 lacunas.

## 3. Novas análises e gráficos, por prioridade

“Viável agora” significa que os dados necessários estão locais; ainda exige derivação e controles na próxima etapa. A auditoria de novos campos é uma etapa de qualidade, não motivo para baixar tudo novamente.

| Ordem | Pergunta e informação adicional | Gráfico proposto | Situação |
|---|---|---|---|
| A1 | A queda permanece após controlar a estrutura etária? Como os perfis diferem entre 2014–2019, 2020–2021 e 2022–2024? | Pontos conectados entre períodos, por idade; painel de taxa bruta e padronizada | Viável agora com SINAN/população |
| A2 | A diferença entre sexos existe em todas as idades ou se concentra em grupos específicos? | Pontos M/F por idade e gráfico de razões de taxas com IC95 | Viável agora; um sexo ignorado separado |
| A3 | Quais etiologias predominam em cada idade e como mudaram suas taxas? | Mapa de calor idade × etiologia; pequenos painéis de taxas por grupo ao longo dos anos | Viável agora com registros individuais locais |
| A4 | Mudou a forma de confirmar/classificar, junto com MV e MNE? | Mapa de calor critério × etiologia e barras por período; painel de completude | Viável agora para campos centrais; novos exames precisam auditoria |
| A5 | Quem concentra evolução para óbito e quanto as ausências alteram a interpretação? | Pontos da proporção registrada por idade/grupo e faixas de cenários para desconhecidos | Descritivo/sensibilidade agora; inferência depende de suporte e perdas |
| A6 | O intervalo sintomas–notificação mudou e varia por grupo? | Distribuição acumulada dos dias e pontos da mediana/IQR por período | Viável agora após conferir datas/intervalos inválidos |
| B1 | Há padrão mensal que persiste após considerar tendência, dias do mês e o intervalo 2020–2021? | Curva de frequência relativa mensal ajustada com IC; caixas das contagens por mês como apoio | 132 meses locais; modelo depende de diagnóstico |
| B2 | Como mudou o perfil de internações e a carga assistencial dos grupos disponíveis? | Perfis por idade em painéis; contagem, dias e valores em painéis separados | Parcial: G00/A87 por idade, A87/A39 por sexo; não inventar G00 sexo/A39 idade |
| B3 | SINAN e SIH exibem mudanças concordantes ou distintas nos grupos comparáveis? | Painéis paralelos por sistema e índice 2014=100 como visual auxiliar | Possível com ressalvas; sem fusão/vínculo de pessoas |
| C1 | Raça/cor, escolaridade, hospitalização, exames, sorogrupos e condições prévias acrescentam informação confiável? | Barras com categoria ignorada e denominador elegível; detalhes apenas se campos aptos | Campos existem, mas falta auditoria específica |
| C2 | O padrão de Salvador difere do restante da Bahia? | Taxas comparáveis em painéis ou razões com IC | Depende de recorte dos DBC existentes e denominadores adicionais |

Para o corpo do trabalho, selecionar aproximadamente **seis figuras novas**, com uma pergunta por figura: A1, A2, A3, A4, A5 e A6. Os modelos B1 e as análises hospitalares B2/B3 são complementos; substituem figuras menos informativas, sem obrigar publicação de todas. As seis figuras atuais permanecem disponíveis, mas nem todas precisam aparecer no artigo.

## 4. Especificação das análises principais

### A1 — comparação temporal e padronização por idade

Calcular contagens e taxas por idade nos três períodos, com denominador igual à soma das populações anuais daquele período/idade. Comparar taxas, não apenas números de períodos com seis, dois e três anos. Identificar explicitamente essa soma como aproximação de exposição em habitantes-ano.

A periodização é uma escolha operacional exploratória após conhecer a série, não um ensaio de impacto da pandemia. Mostrar todos os anos também; testar a estabilidade usando 2015–2019 como referência adicional, pois 2014 tem contagem elevada. A análise principal não exclui 2014 porque sua retirada favoreceria uma conclusão.

Padronização direta: usar pesos etários fixos da população de Salvador somada em 2014–2024, ambos os sexos. Registrar tabela dos pesos e mesma referência para todos os anos/períodos. Taxa padronizada = soma dos pesos × taxas específicas. É referência interna para comparação, não taxa bruta observada ou padrão mundial. Não aplicar a fórmula de IC Poisson exato da contagem total à média ponderada; especificar IC por método apropriado para taxa padronizada ou simulação paramétrica dos estratos, com semente e pressupostos.

### A2 — sexo dentro das idades e razão ajustada

Usar a grade ano × sexo × idade; casos de sexo ignorado não recebem denominador de sexo. Mostrar as onze faixas no descritivo; avaliar uma agregação pré-especificada `<1`, `1–4`, `5–19`, `20–59`, `60+` para modelos, somando as populações correspondentes. Nunca agrupar faixas só porque um teste ficou significativo.

Primeiro, razões de taxas M/F por idade, com IC e valores absolutos. Depois, um modelo parcimonioso de contagens com `offset(log(populacao))`, sexo, idade e ano. A exponencial do coeficiente é razão de taxas registradas, não odds ratio ou risco causal individual. Avaliar dispersão, resíduos e adequação; considerar quasi-Poisson ou binomial negativa se justificado. Não comparar AIC de quasi-Poisson como se fosse verossimilhança completa. Interação sexo × idade só se houver suporte, usando teste global e incerteza das estimativas.

Estrato com zero em um sexo exige método/IC compatível ou apresentação só das taxas; não acrescentar 0,5 automaticamente nem publicar razão infinita sem contexto. A conversão etária auditada será preservada; eventual regra alternativa na fronteira de 365 dias deve ser uma sensibilidade declarada, não troca silenciosa da classificação.

### A3 — etiologia dentro das idades e no tempo

Criar cruzamentos a partir da base individual local, não combinando marginais. Utilizar grupos disjuntos já definidos, preservando categorias originais, MNE, MCC e residual. Para cada idade/período, entregar tanto `n` quanto proporção entre todos os registros daquele estrato. Taxas por grupo etiológico usam população residente compatível; não população estimada de suscetíveis àquele agente.

Separar dois gráficos: composição entre casos e taxa populacional registrada. Uma participação pode aumentar enquanto a taxa cai; o gráfico atual de barras de 100% não distingue isso. Grupos raros terão contagem/IC explícitos e poderão ficar em apêndice; não estimar numerosos modelos independentes ou fabricar estabilidade por agrupamentos sem justificativa clínica.

### A4 — critério de confirmação e qualidade

Cruzar critério, etiologia, ano/período e, secundariamente, idade. Comparar participação dos critérios, MNE e códigos não canônicos. Os denominadores precisam separar todos os casos, critérios conhecidos e universos condicionais. O resultado mede práticas/classificações registradas, sem provar capacidade laboratorial, acesso ou sensibilidade real.

Não recodificar “PCR” geral como prova viral. Conferir os critérios e exames no dicionário oficial antes de criar o grupo “laboratorial”; algumas categorias podem refletir exame inespecífico. Manter informação bruta e regra de derivação versionada.

### A5 — evolução e cenários de incompletude

Descrever, por ano/período, idade e grupo etiológico: alta, óbito por meningite, óbito por outra causa e desconhecida. Não juntar os dois tipos de óbito no desfecho principal. Para cada estrato, definir `N` total, `D` óbitos por meningite e `U` evoluções desconhecidas.

Mostrar `D/N`, `D/(N-U)` entre evoluções conhecidas e os limites de cenários `D/N` a `(D+U)/N`. Estes limites representam atribuições extremas dos desconhecidos; **não são intervalos de confiança**. Também não dão uma letalidade completa ou garantem que o caso encerrado seja representativo do desconhecido. Comparar completude entre estratos antes de interpretar diferenças.

Modelo individual de evolução só em etapa secundária, com universo e perdas explícitos, suporte de eventos, convergência e separação avaliados. Não prometer ajuste com todas as covariáveis porque há 190 óbitos no total: algumas combinações podem ser raras ou incompletas. Priorizar idade, sexo e grupos etiológicos amplos; ano entra apenas se o número de parâmetros e o padrão de perdas permitirem.

### A6 — oportunidade da notificação

Conferir duas datas válidas, intervalos negativos, extremos e mudanças por partição/ano. Intervalos muito longos não serão excluídos automaticamente; registrar validação e sensibilidade. Mostrar mediana, IQR, percentis e número válido por estrato, além das perdas. Na curva acumulada, cada ponto responde “qual fração dos registros válidos foi notificada até esse número de dias?”.

Comparar 2014–2019, 2020–2021 e 2022–2024 e grupos etiológicos amplos. Categorias 0–1, 2–7, 8–30 e >30 dias servem à comunicação, sem chamá-las de padrão oficial de oportunidade. Sintomas–notificação não mede sintomas–diagnóstico, sintomas–tratamento ou duração de internação. Não calcular tempo até encerramento/óbito: as datas completas desses eventos não estão na base mínima; existem apenas indicadores de ausência.

## 5. Complementos que exigem condições adicionais

### B1 — sazonalidade

Não declarar sazonalidade estável porque o mês agregado tem maior contagem. Examinar contribuição de cada ano, tendência, duração do mês e possíveis mudanças em 2020–2021. Um modelo inicial de contagens mensais pode usar tendência simples, indicadores dos períodos e termos cíclicos de mês. O offset pode utilizar exposição aproximada `populacao_anual × dias_mes/dias_ano`; isso não cria uma estimativa observada de população mensal e deve ficar declarado como aproximação.

Conferir sobredispersão, resíduos e autocorrelação. Se houver dependência temporal relevante, o IC de um GLM independente não basta; revisar modelo ou limitar a conclusão a descrição. Não fazer dezenas de pontos de corte, previsões longas, seleção de “melhor mês” por p-valor ou chamar desvio mensal de surto sem investigação epidemiológica.

### B2/B3 — hospitalizações e triangulação

Filtrar tipo total/perfil, medida, CID, ano de processamento, residência e fonte; jamais somar idade e sexo às séries totais. Antes de taxa hospitalar, verificar faixas/denominadores; antes de razão dias/AIHs, valores/AIHs ou óbitos/AIHs, demonstrar que as medidas têm universos administrativos compatíveis no mesmo CID/ano. Caso contrário, apresentar somente séries separadas. Valor aprovado nominal não é custo econômico ou custo por paciente. Comparação financeira temporal real requer deflator oficial, cuja coleta não integra este planejamento.

Priorizar G00/A87 por idade e A87/A39 por sexo, disponíveis. G00 sexo e A39 idade dependem de coleta pendente. Óbitos de G01 não viram zero. A ausência de totais G01/G02/G03 impede soma integral das seis folhas.

Na comparação SINAN/SIH, mostrar conceitos, unidades e tempos em cada painel. A39 não equivale à meningite meningocócica isoladamente; MV não é a mesma definição de A87. O índice 2014=100 expressa variação relativa de cada série, com denominador e valor de referência claros; não mede equivalência dos sistemas. Não calcular “fração de casos internados” dividindo SIH por SINAN.

### C1 — novos campos clínicos e sociais

Há campos `CS_RACA`, `CS_ESCOL_N`, `CLA_SOROGR`, `CLA_ME_BAC`, `CLA_ME_ASS`, `CLA_ME_ETI`, `ATE_HOSPIT`, `ATE_INTERN`, `LAB_PUNCAO`, `LAB_CTLIQU`, `LAB_PCLIQU`, `LAB_PCSANG`, antecedentes e vacinação. A primeira tarefa futura é conferir tipo/domínio, ano de introdução, mudanças de formulário, códigos ignorados, consistência com etiologia/idade e universo elegível.

O dicionário distingue `ATE_HOSPIT` (ocorreu hospitalização: sim/não/ignorado) de `ATE_INTERN` (data). Sorogrupo é condicional à classificação meningocócica; não dividir seu preenchimento por toda a coorte. Escolaridade tem “não se aplica” por idade; separar essa categoria de desconhecida e considerar análise de adultos, com faixa definida antes de calcular. Raça/cor permite perfil dos casos e completude, sem taxa populacional específica porque não temos denominadores anuais compatíveis por raça/cor.

Antecedentes vacinais entre casos não estimam eficácia: não há população comparadora de não casos e os campos podem ter perdas/mudanças. Hospitalização registrada no SINAN, se apta, é indicador entre notificações, distinto de AIHs do SIH. Punção/exames não serão chamados automaticamente de confirmação etiológica.

Triagem operacional proposta, não norma universal: até 10% desconhecidos no universo elegível permite considerar associação após auditoria; 10–30% prioriza descrição e sensibilidade; acima de 30% prioriza qualidade. Avaliar ano/grupo, plausibilidade e seleção mesmo abaixo de 10%: percentual baixo sozinho não demonstra validade. Quantidade de eventos/níveis e coerência podem impedir o uso de um campo aparentemente completo.

### C2 — contexto Bahia e dados externos

Os DBC nacionais preservados permitem estudar a viabilidade de recorte para o restante da Bahia sem repetir downloads SINAN. Ainda precisamos verificar campos territoriais/cobertura e obter denominadores compatíveis. Usar Salvador versus Bahia excluindo Salvador evita tratar a capital e um total que a contém como populações independentes. Comparação nacional exige auditoria adicional de cobertura territorial/ano e não entra na primeira rodada.

Vacinação: antes de ampliar, resolver as 27 lacunas legadas e a comparabilidade documental/operacional, além de auditar os níveis BCG. Dois anos RNDS por indicador não sustentam modelo de efeito vacinal. Novas consultas devem ser limitadas e seletivas. Mortalidade SIM só ganha papel central após comprovar cobertura nacional por residência. SIA continua sem recorte útil demonstrado para estas perguntas.

Não há base pronta para mapa de bairros, associação com clima/renda, análise de sobrevivência, recorrência/reinternação de pessoas ou prognóstico individual. Cada uma exigiria campos/denominadores adicionais e desenho próprio; não será incluída apenas para aumentar o número de gráficos.

## 6. Ordem de execução e divisão futura

1. **Gate de qualidade:** validar hash do RDS aceito; inventariar universos/domínios dos campos propostos; congelar definições, agrupamentos, referências e hipóteses. Registrar análises primárias, secundárias e exploratórias antes dos modelos.
2. **Cruzamentos e taxas:** A1–A4, gerando grades e conferindo conservação dentro de cada dimensão/universo. Zero somente derivado de coorte integral e universo elegível. Não juntar marginais como linhas individuais.
3. **Evolução e notificação:** A5–A6 com perdas/cenários explícitos; auditando possível seleção por idade/etiologia/ano.
4. **Inferência seletiva:** um modelo principal para razão de taxas ajustada; sazonalidade e evolução somente se gates passarem. Priorizar efeito e IC; testes globais, sem matriz indiscriminada de p-valores. Se houver família de testes exploratórios, declarar multiplicidade e eventual ajuste.
5. **Complementos:** B2/B3 com fontes locais; C1 apenas campos aprovados. Baixar pendências somente quando indispensáveis para a pergunta aprovada, sob orçamento próprio; não bloquear o núcleo por lacunas PNI.
6. **Redação e seleção:** escolher as seis figuras mais informativas, acompanhado de tabela descritiva e parágrafo interpretativo. Conferir PNG e PDF, denominadores, números do texto, perda de linhas e incerteza. Atualizar manual/Git local, preservando entrega anterior.

Divisão proposta, **não despachada nesta rodada**:

- Chat “Revisar contexto do projeto (2)”: preparação agregada dos cruzamentos SINAN/população, pesos de padronização, documentação de campos e auditoria da conservação. Área futura exclusiva `analise/aprofundamento/trabalho/sinan_populacao/`.
- Chat “Revisar contexto do projeto”: elegibilidade/qualidade dos campos clínicos/sociais, SIH/SIM/PNI e correspondência das medidas; sem nova coleta automática. Área futura exclusiva `analise/aprofundamento/trabalho/complementos/`.
- Mestre: integração, definições científicas, modelos, sensibilidades, gráficos, narrativa e Git. Revisão final cruzada em leitura, com arquivo exclusivo de parecer para cada frente.

## 7. Produtos compactos e critérios de aceite

Preservar a entrega atual. Destino futuro `analise/aprofundamento/`, sem criar nesta rodada: um RDS de derivados/modelos/metadados, dois CSVs longos (`cruzamentos_sinan.csv` e `estimativas_e_sensibilidades.csv`), um relatório principal, scripts R reutilizáveis, controle/manifesto e figuras PNG/PDF. Novos dicionários/mapas apenas para campos derivados. Não copiar todos os brutos ou casos individuais para essa pasta; referenciar o hash da base aceita.

Cada saída terá pergunta, fonte, período, território, grão, unidade, numerador, denominador, estado/ausência, IC ou cenários e limites. Ajustes terão fórmula, universo, perdas, referência, convergência, dispersão, resíduos/autocorrelação quando aplicável, estimativas e decisões de sensibilidade.

Gráficos: paleta legível para deficiência de visão de cores, contraste também por formas/linhas, máximo de categorias útil ao argumento, escalas declaradas e ausência de eixo duplo. Mapa de calor de composição usará percentuais com contagens na tabela de apoio; mapas de taxas e de completude terão unidades/legendas distintas. O eixo de razões explicitará escala logarítmica se usada, e linha de referência 1. Evitar gráficos 3D, pizza, radar ou redes que apenas redistribuam números sem responder à pergunta.

Aceite: registros/fonte preservados; mapas disjuntos; somas e junções conservadas; ausentes não transformados em zero; desconhecidos não desaparecem; cenários não rotulados como IC; taxa padronizada não rotulada como bruta; fórmulas/unidades independentes conferidas; modelos identificáveis/adequados; imagens legíveis e números coerentes com tabelas. Não emitir estimativa inferencial quando esses critérios falharem: entregar descrição e motivo concreto.

Sensibilidades mínimas: exclusão de MCC isolada se título clínico restrito; referência temporal alternativa sem 2014; exclusão 2023–2024 preliminares como análise secundária; manutenção/separação do residual etiológico; evolução desconhecida por extremos; intervalos longos/negativos sem descarte silencioso; faixas amplas versus originais quando houver suporte. Não escolher a versão com menor p-valor como resultado final.

## 8. Referências metodológicas e definição dos campos

As propostas usam conceitos verificados em fontes primárias; não são resultados executados nem validação automática do nosso desenho:

- [R — glm, fórmulas e offset](https://search.r-project.org/R/refmans/stats/html/glm.html).
- [R — famílias Poisson/quasi-Poisson e dispersão](https://search.r-project.org/R/refmans/stats/html/family.html).
- [NCI/SEER — padronização direta como média ponderada de taxas específicas](https://seer.cancer.gov/seerstat/tutorials/aarates/definition.html). O mecanismo é referência metodológica; a população padrão dos EUA não será importada para Salvador.
- Dicionários oficiais locais: `referencias/sinan_dicionario_meningite_v5.txt` e `referencias/sinan_dicionario_notificacao_individual_2018.txt`, com seus PDF preservados. Regras condicionais e códigos devem ser confrontados com os dados efetivos; o rótulo de um campo não basta.

Decisão recomendada: começar pelos cruzamentos, padronização, qualidade, evolução com cenários e intervalo até notificação; liberar modelos e novos campos somente após os critérios acima. Não precisamos completar toda a vacinação para obter um trabalho mais sólido com o núcleo existente.
