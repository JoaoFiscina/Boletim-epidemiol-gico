# Meningites e doença meningocócica em Salvador: análise aprofundada

Execução: 12/10/2026. SINAN por residência, ano dos primeiros sintomas 2014–2024. Análises exploratórias sobre o snapshot aprovado em 10/10. Nenhuma coleta nova nesta etapa.

## Resultados que sustentam o trabalho

- A taxa padronizada foi 8,66, 1,74 e 6,16 por 100 mil habitantes-ano nos três períodos. A recuperação de 2022–2024 permanece abaixo de 2014–2019. Isso descreve ocorrência registrada, incluindo mudanças na vigilância.
- Homens tiveram razão de taxas ajustada M/F 1,49 (IC95 1,34–1,65), considerando idade e ano. As sensibilidades mantêm a direção e magnitude aproximada da associação.
- A participação MNE subiu de 12,2% em 2014 para 25,9% em 2024, mas a taxa ficou praticamente igual: 1,63 versus 1,63 por 100 mil. O aumento proporcional não demonstra aumento populacional de meningite não especificada. MV caiu de 8,58 para 1,87 por 100 mil, contribuindo fortemente para a composição diferente.
- O critério PCR passou de 2,5% dos registros em 2014–2019 para 20,8% em 2022–2024. Quimiocitológico passou de 76,8% para 48,0%. O método de investigação mudou junto com o perfil observado. Isso impede tratar a série como se a classificação tivesse precisão constante.
- Os intervalos sintomas–notificação têm mediana de 4, 8 e 7 dias nos três períodos. São intervalos de registro, com extremos conservados; não medem tempo até diagnóstico ou tratamento.

## 1. Abrangência, idade e tempo

A coorte inclui 1.976 registros confirmados, residentes em Salvador (292740). MCC isolada permanece incluída, e a análise sem MCC retira 19 registros. O denominador municipal é população DATASUS/RIPSA de 1º de julho, por sexo e idade. A soma anual aproxima habitantes-ano. Um sexo ignorado foi conservado nos totais e taxas por idade, e retirado das comparações M/F.

| Periodo | Registros | Taxa bruta | Taxa padronizada | IC95 padronizada |
| --- | --- | --- | --- | --- |
| 2014-2019 | 1414 | 8,81 | 8,66 | 8,21–9,12 |
| 2020-2021 |   91 | 1,73 | 1,74 | 1,40–2,13 |
| 2022-2024 |  471 | 6,07 | 6,16 | 5,62–6,75 |

Padronização direta usa pesos fixos da soma das populações por idade de 2014–2024, ambos os sexos. O IC95 gamma de Fay–Feuer corresponde à taxa ponderada. Uma taxa padronizada não é o número real de casos dividido pela população total. Os períodos foram definidos no plano anterior ao ajuste dos modelos, depois da inspeção inicial da série, sem preregistro.

A taxa dos menores de um ano foi 82,45, 21,63 e 42,47 por 100 mil habitantes-ano. Em 20–59 anos, foi 5,92, 1,67 e 5,27. A recuperação é desigual entre as idades. A distribuição de contagens tem mais adultos porque essa população é maior; não confundir maior número de registros com maior taxa.

Partições 2023–2024 são preliminares. Sem 2014, o primeiro período usa efetivamente 2015–2019; sem 2023–2024, o último usa apenas 2022. As exposições são retiradas junto com os anos. A sensibilidade da fronteira de 365 dias não reclassificou registros desta coorte.

## 2. Sexo: associação e estabilidade

| Cenario | Razao M/F ajustada | IC95 |
| --- | --- | --- |
| taxas_principal | 1,49 | 1,34–1,65 |
| taxas_sensibilidade_quasi | 1,49 | 1,34–1,66 |
| taxas_sem_MCC | 1,50 | 1,35–1,66 |
| taxas_sem_2014 | 1,45 | 1,31–1,59 |
| taxas_sem_2023_2024 | 1,48 | 1,35–1,64 |
| taxas_faixas_originais | 1,48 | 1,36–1,62 |

Modelo de contagens: n ~ sexo + cinco faixas de idade + ano categórico + offset(log população). A referência é feminino, idade <1 e ano 2014. Diagnóstico Pearson detectou sobredispersão (phi 1,35; p 0,013); a binomial negativa convergiu sem avisos, com dispersão residual 1,14. A sensibilidade quasi-Poisson evita depender apenas da NB. Não comparar AIC de quasi-modelos, nem AIC entre cenários com observações diferentes.

O modelo com interação sexo×idade fica como diagnóstico exploratório. Razões específicas por idade possuem incertezas diferentes; alguns intervalos atravessam 1. Não converter a inspeção de muitos grupos em prova de heterogeneidade. Não há ajuste para exposições sociais, comorbidades, acesso ou probabilidade de notificação.

## 3. Etiologia e investigação

Sete grupos disjuntos preservam MV, MNE, outras bacterianas (MB/MH/MP), meningocócica (MM/MM+MCC/MCC), MTBC, MOE e residual. Os seis códigos não canônicos e dois vazios continuam residuais; não corrigir a etiologia usando um campo de agente isolado.

Entre os 874 MV, 807 trazem agente não identificado. Entre 261 MB, 180 indicam bactéria não especificada. Há 47 sorogrupos informados entre 85 elegíveis meningocócicos (B=9, C=32, Y=2, W=4); 38 estão ausentes. Esses números apoiam uma análise de especificidade e registro. Não estimam a distribuição populacional verdadeira de agentes ou sorogrupos.

## 4. Desfecho e dados ausentes

| Grupo | N | D | U | D/N (%) | D/(N-U) (%) | Limite superior extremo (%) |
| --- | --- | --- | --- | --- | --- | --- |
| Viral | 874 | 14 | 25 | 1,6 | 1,6 | 4,5 |
| Nao especificada | 442 | 58 | 71 | 13,1 | 15,6 | 29,2 |
| Outras bacterianas | 384 | 78 | 21 | 20,3 | 21,5 | 25,8 |
| Meningococica |  85 | 10 |  7 | 11,8 | 12,8 | 20,0 |
| Tuberculosa |  91 | 17 |  8 | 18,7 | 20,5 | 27,5 |
| Outra |  92 | 13 | 10 | 14,1 | 15,9 | 25,0 |
| Residual |   8 |  0 |  2 | 0,0 | 0,0 | 25,0 |

D é óbito por meningite, U evolução ignorada e N todos os registros do grupo. D/N, D/(N−U) e (D+U)/N respondem a denominadores ou cenários diferentes. O intervalo extremo não é IC95 e não imputa o desfecho. Na coorte integral há 190 óbitos por meningite, 76 por outra causa, 1.566 altas e 144 evoluções ignoradas. Em 2024, U=32 de N=162, uma perda relevante para comparações recentes.

A maior proporção registrada de óbito nas outras bacterianas (20,3%) e tuberculosa (18,7%) em comparação com viral (1,6%) é um contraste descritivo relevante. Idade, seleção, classificação e acompanhamento podem contribuir. A MNE acumula 71 ignorados e sua proporção extrema vai de 13,1% a 29,2%; conclusões sobre gravidade nesse grupo são particularmente frágeis.

Modelo logístico suplementar: 1.826 registros com evolução conhecida, sexo conhecido e etiologia canônica; 190 eventos e 12 parâmetros além do intercepto. Ajusta sexo, cinco idades, seis grupos e três períodos. OR não é razão de riscos. O universo elegível tem 1.967 registros: nove excluídos (um sexo ignorado e oito residuais), seis residuais com evolução conhecida. Os dois cenários adicionais atribuem os 141 ignorados elegíveis integralmente a não evento ou evento para mostrar sensibilidade, sem preencher a fonte. Não são limites matemáticos de cada coeficiente ajustado. EPV e estimativas finitas são critérios operacionais e não demonstram isoladamente ausência formal de separação. Códigos residuais e o sexo ignorado ficam fora do modelo, conservados nos descritivos. A base mínima não permite análise de sobrevivência ou vínculo individual SINAN–SIH–SIM.

As células agregadas do modelo de óbito são esparsas; por isso o diagnóstico Pearson não foi usado como teste de ajuste calibrado. A sensibilidade quasi-binomial amplia a incerteza mantendo os coeficientes. As células mistas (com evento e não evento) têm posto completo na matriz de covariáveis, condição suficiente para afastar uma direção linear de separação nesta fórmula. Isso não resolve viés de seleção, classificação ou dados ausentes.

## 5. Notificação e meses

Todos os 1.976 intervalos derivados são válidos na base mínima, sem negativos ou ausentes. Há 143 maiores de 30 dias e quatro maiores de 365 dias; máximo 1.833. Os limiares 30/365 são sensibilidades exploratórias e não critérios oficiais de validade. O gráfico acumulado integral mostra a cauda inteira; tabelas adicionais apresentam os cortes separadamente. Uma mudança de registro ou represamento pode alongar esses intervalos sem demonstrar pior assistência.

A análise de 132 meses usa componente harmônico anual, tendência linear e três períodos, com exposição mensal aproximada pelos dias de cada mês. Resíduos ainda possuem autocorrelação (diagnóstico aproximado Ljung–Box lag12, fitdf=0, p=0,008, sem calibração específica para resíduos GLM). O teste conjunto dos componentes sazonais com covariância HAC lag12 tem p=0,151. Não há suporte firme para afirmar sazonalidade constante; o gráfico é suplementar. HAC altera a incerteza, sem corrigir uma média mal especificada.

## 6. Campos adicionais e fontes complementares

| Campo | Elegiveis | Desconhecidos | Perdas (%) |
| --- | --- | --- | --- |
| CS_RACA | 1976 |  544 | 27,5 |
| CS_ESCOL_N |  960 |  588 | 61,2 |
| CLA_SOROGR |   85 |   38 | 44,7 |
| ATE_HOSPIT | 1976 |   25 | 1,3 |
| LAB_PUNCAO | 1976 |   73 | 3,7 |
| ANT_CONJ_C | 1976 | 1599 | 80,9 |
| ANT_PNEUMO | 1976 | 1677 | 84,9 |
| ANT_IMUNO | 1976 | 1976 | 100,0 |

Escolaridade foi auditada em adultos de 25 anos ou mais; 61,25% desconhecida impede associação principal. Raça tem 27,5% desconhecida e não dispõe de denominador anual específico nesta entrega; usar apenas perfil e sensibilidade entre casos. ANT_IMUNO está integralmente vazio, apesar de o campo existir nas partições, e não significa ausência de imunodepressão. Antecedentes vacinais têm perdas elevadas e não permitem estimar eficácia. Hospitalização tem 1.914 sim, 37 não e 25 desconhecidos: descrição entre casos é possível, mas o grupo não hospitalizado é pequeno e sujeito a seleção. ATE_INTERN é data, não indicador binário.

A auditoria aponta oito hospitalizados sem data, seis preenchimentos CLA_ME_ASS fora da elegibilidade etiológica, 23 culturas e 14 PCR de líquor fora da condição operacional de punção, seis quimioprofilaxias fora da elegibilidade e um código de escolaridade não aplicável acima de sete anos. As divergências são registradas sem correção automática. Critérios de elegibilidade têm limites documentais e não comprovam estabilidade do preenchimento em todos os anos.

SIH disponibiliza 308 taxas de perfis: G00/A87 por 12 faixas de idade e A87/A39 por sexo, nos 11 anos. Populações foram reagrupadas para os limites originais das faixas e as marginais conferidas. SIH mede AIHs/episódios por ano de processamento; SINAN mede registros por sintomas. Séries podem ser mostradas lado a lado ou em índices próprios 2014=100, mas não somadas ou usadas como proporção de casos internados. Dias de permanência, valores nominais e óbitos permanecem medidas separadas; médias/razões administrativas não aprovadas por correspondência de universo insuficiente. G01 óbitos e internações G01–G03 ausentes permanecem NA.

SIM: 202 óbitos por causas selecionadas no recorte de registros da Bahia; cobertura nacional dos residentes não demonstrada. PNI: 17 observações de 44 indicadores/anos, com métodos legado e RNDS distintos. Não fazer associação municipal de cobertura e incidência ou inferir efeito vacinal com essa cobertura parcial. Referência Bahia/C2 depende de população e abrangência comparáveis; não foi coletada nesta etapa.

## 7. Argumento científico e próximos usos

O trabalho pode se organizar em torno da redução e recuperação desigual da ocorrência registrada, da diferença por sexo e da mudança simultânea da investigação etiológica. A tensão principal é epidemiologia versus observabilidade: parte da alteração pode refletir circulação, investigação, acesso e registro. Os dados mostram o padrão; não identificam causalmente sua origem.

Hipóteses para discussão: mudanças na circulação e acesso em 2020–2021; retorno desigual por idade; alteração dos critérios de investigação; seleção de casos e incompletude dos desfechos. Devem ser apresentadas como hipóteses, apoiadas por literatura e contexto, sem atribuir o resultado à vacinação ou pandemia a partir destas séries.

Para uma apresentação enxuta, priorizar G01, G02, G04 e G05. G03 aprofunda idade×etiologia, G06 o processo de registro. G07 e G08 ficam suplementares. O caderno contém todas as oito figuras em PDF vetorial, e PNGs separados para consulta. As seis figuras anteriores permanecem preservadas.

Antes de inferência confirmatória: definir uma pergunta primária, escolher modelo/contraste e período, atualizar partições preliminares, delimitar testes múltiplos e, se essencial, completar o denominador e a cobertura externos. Esta etapa não substitui um protocolo confirmatório.

## Reprodução e referências de método

Executar o controlador R offline com a pasta Meningite como argumento; os exemplos estão no README. Duas tabelas CSV longas, RDS apenas com agregados/modelos e dicionário permitem reuso em R e outros programas. Não há dados individuais no pacote aprofundado. Os CSV usam ponto decimal e separador ponto e vírgula, campos vazios como NA. Filtrar tabela/medida/eixos antes de agregar.

- [Padronização direta e IC gamma, epitools](https://search.r-project.org/CRAN/refmans/epitools/html/ageadjust.direct.html). Fórmula conferida com o código CRAN e testes de zeros/estrato único; pacote não instalado.
- [GLM e offset, R](https://search.r-project.org/R/refmans/stats/html/glm.html) e [famílias quasi e AIC](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/family.html).
- [Binomial negativa, MASS](https://stat.ethz.ch/R-manual/R-devel/library/MASS/html/glm.nb.html).
- [Covariância HAC Newey–West, sandwich](https://search.r-project.org/CRAN/refmans/sandwich/html/NeweyWest.html).

Fonte aprovada SHA-256: `2fe0f7f6f02d6367b9cfa55487f24016dd57c09f4dc979f8975efd7edbb5247d`. Nenhuma alteração da fonte ou nova consulta. Os valores e testes são exploratórios; IC de contagem não corrige subnotificação ou cobertura.
