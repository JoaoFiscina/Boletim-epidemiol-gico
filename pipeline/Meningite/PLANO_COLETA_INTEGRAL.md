# Plano de coleta integral, organização e auditoria — meningites em Salvador

Versão 20261009, iniciada em 09/10/2026. Este plano amplia a pré-análise de 05/10/2026. O perfil documental está em `config/coleta_integral.json`; os dois scripts SINAN têm os períodos explícitos no código e não leem esse JSON automaticamente. Resultados e falhas estão no [relatório executado](RELATORIO_COLETA_INTEGRAL_20261009.md); itens previstos não são automaticamente considerados coletados.

## 1. Objetivo e decisões iniciais

Construir um conjunto municipal reproduzível que sustente análise de ocorrência registrada, taxas por população, perfis demográficos, sazonalidade, diagnóstico, desfechos, carga hospitalar, mortalidade e contexto vacinal. O núcleo é SINAN nacional e população. SIH, SIM e PNI são módulos complementares, cada qual com unidade e referência temporal próprias.

Janela principal:2014–2024. Partições SINAN:2014–2026 para incluir notificações tardias referentes a sintomas do período principal. Os anos2025–2026 são usados como partições de captação, sem incorporá-los silenciosamente à série de resultados. Uma futura extensão a2025 exige nova versão, corte epidemiológico, denominadores e análise de encerramento.

Território: residentes de Salvador, códigoIBGE292740. Município de notificação, internação, atendimento e óbito são atributos diferentes. Local de atendimento pode entrar como módulo assistencial, com rótulo próprio e sem ser usado como numerador de risco de residentes.

Definição inicial: casos confirmados do banco de meningites e doença meningocócica. Preservar meningococcemia isolada (MCC) como categoria própria. Produzir análises de sensibilidade retirando MCC isolada somente com regra explícita; um registro sem etiologia interpretable não vira automaticamente meningite anatômica certificada.

## 2. Perguntas, dados necessários e prioridade

| Prioridade | Pergunta | Dados mínimos | Saída prevista |
|---|---|---|---|
| P0 | Como variam os registros e taxas no tempo? | SINAN ano/mês dos sintomas, residência, confirmação; população anual | série anual e mensal; taxas de casos registrados |
| P0 | Qual o perfil por idade e sexo? | idade codificada, sexo e denominadores compatíveis | taxas específicas e base conjunta; agrupamentos quando necessário |
| P0 | A classificação diagnóstica mudou? | etiologia, critério, domínios/versões e campos laboratoriais | MNE, ignorados, categorias amplas e técnicas registradas |
| P1 | Como são os desfechos registrados? | evolução e datas de evolução/encerramento | completude, desfechos e sensibilidade; letalidade condicionada à qualidade |
| P1 | Qual a carga hospitalar? | SIH por residência; CID, internações, óbitos, dias e valores | perfis, permanência e valores administrativos; episódios SUS |
| P1 | Como varia a mortalidade registrada? | SIM por residência; causa básica, ano, sexo, idade | mortalidade por códigos definidos e população; sem dividir por SINAN |
| P1 | Há contexto vacinal utilizável? | PNI por município, imunobiológico, dose/esquema, população alvo e método | cobertura/doses separadas, antes e depois da mudança de sistema |
| P2 | Raça/cor, escolaridade e antecedente vacinal dos casos são utilizáveis? | SINAN secundário, aplicabilidade e completude | diagnóstico de qualidade; análise somente se possível |
| P2 | Há agentes/sorogrupos com volume para análise? | campo aplicável, domínio vigente, número de eventos | descrição ou agrupamento; modelos raros condicionais |
| P2 | Distribuição intraurbana ou vínculo entre sistemas? | dados geográficos/chaves acessíveis e válidos | somente após demonstrar disponibilidade; não prometido pelo banco público |

SIA não é coleta obrigatória neste desenho: procedimento pode não identificar meningite, etiologia ou residente. Só coletar SIA/SIGTAP se surgir uma pergunta de produção ambulatorial com códigos pertinentes, vigência e unidade demonstradas. Isso evita baixar bases volumosas que não respondem às perguntas municipais.

## 3. Inventário inicial e versão preservada

A pré-análise anterior tem1.976 registros gerais doTabNet,1.970 na etiologia, população total e estratificada, três DBC nacionais, SIH por grupos e SIM causa/sexo. Seus arquivos não serão editados durante a nova coleta. A divergência histórica de seis está aberta;2024 fechou em162 no piloto nacional.

Organização por versão:

```text
Meningite/
  config/coleta_integral.json
  dados/brutos/sinan_br_20261009/         catálogo, ZIP/DBC e manifesto
  dados/tratados/sinan_br_20261009/       tabelas longas e pacote local
  dados/brutos/complementos_20261009/    respostas SIH/SIM
  dados/tratados/complementos_20261009/  perfis e medidas administrativas
  dados/brutos/pni_20261009/             fontes vacinais originais
  dados/tratados/pni_20261009/           cobertura/doses separadas
  dados/denominadores/                  população já conferida
  metadados/                            estado, critérios e auditorias
  scripts/                             coletores e processamento local
  resultados/                          gráficos e tabelas escolhidos
```

Os DBC do piloto podem ser referenciados por caminho e hash no manifesto novo, sem duplicar os mesmos bytes. Datas de extração distintas permanecem visíveis. Se uma partição passou a final ou a versão mudou, ela deve ser coletada em nova versão e substituir analiticamente a anterior, sem concatenar ambas.

## 4. Contrato de cada coleta

Cada resposta registra: fonte e URL; método; parâmetros completos; município/perspectiva; período selecionado e observado; referência temporal; versão/modalidade; início e fimUTC; códigoHTTP quando disponível; caminho; tamanho; SHA-256; contagem de registros/células; status; erros/tentativas; cobertura e limites.

Estados distintos: `pendente`, `baixado_leitura_pendente`, `lido_auditoria_pendente`, `validado_no_recorte`, `parcial`, `divergente`, `vazio_observado`, `linha_omitida_sem_imputacao` e `inaplicavel`. Um contador de falhas não vira contador de casos. O manifesto é salvo após cada lote para permitir retomada apenas dos pendentes.

## 5. SINAN nacional: coleta e leitura

1. Consultar o catálogo oficial no portalDATASUS; conservar a respostaJSON e seu contrato. Selecionar MENIBR14–26 reais, uma modalidade por partição; finais têm preferência quando existem.
2. Conferir hashes dos arquivos locais. Reaproveitar somente quando nome, origem/modalidade e hash forem compatíveis. Não baixar novamente apenas para movimentar a coleta.
3. Solicitar ZIP por rotaHTTPS oficial em lotes de atétrês partições. Teto inicial80MB de rede, timeout40s por requisição e atéduas tentativas. Falha repetida interrompe o lote e preserva o manifesto; reduzir lote ou retomar pendentes, sem varredura infinita.
4. Extrair apenas nomes esperados, conferirCRC pelo leitorZIP, rejeitar ambiguidades e arquivos excessivos. Preservar ZIP e DBC. Conferir SHA antes da leitura emR.
5. Ler uma partição por vez e registrar número nacional de linhas, número/tipos de campos e campos faltantes. Manter somente residentes de Salvador para a etapa de processamento municipal, com fluxo de seleção auditável.
6. Usar `ID_MN_RESI=292740`, `CLASSI_FIN=1`, `ano(DT_SIN_PRI)` em2014–2024. Notificação foraBA continua incluída. Investigar códigos inesperados antes de transformá-los em ignorados.
7. Conservar confirmados fora da janela e sem data na auditoria agregada; não excluí-los sem contabilizar. Ano dos sintomas não deve ser trocado silenciosamente por ano de notificação.
8. Verificar duplicatas exatas técnicas e repetições entre partições; registrar sem afirmar pessoas únicas. Remover apenas duplicação demonstrada, preservando base/contagem anterior e regra. Sem chave clínica válida, informar a limitação.

Campos principais: `ID_MN_RESI`, `CLASSI_FIN`, `DT_SIN_PRI`, `DT_NOTIFIC`, `CS_SEXO`, `NU_IDADE_N`, `CON_DIAGES`, `CRITERIO`, `EVOLUCAO`, `SG_UF_NOT`. Conservar código bruto e categoria derivada. Domínios de sexo, idade, evolução e etiologia dependem da fonte; índices de opção doTabNet não são códigos doDBF.

Campos secundários: `CS_RACA`, `CS_ESCOL_N`, `CLA_SOROGR`, `LAB_*`, `ATE_HOSPIT`, `ATE_INTERN`, `ANT_*`, `MED_DT_EVO`, `DT_ENCERRA`. Medir preenchimento com denominador aplicável. Sorogrupo deve ser avaliado entre doença meningocócica, não em todos os casos. Escolaridade não deve ser cobrada de lactentes; adequar por idade/versão. Antecedente vacinal preenchido não implica esquema completo nem prova do cartão.

## 6. Harmonização e bases SINAN previstas

- Série anual e mensal com anos observados e total reconciliado.
- Marginais longas por ano × dimensão × categoria, incluindo ignorados/códigos inesperados.
- Base conjunta ano × sexo × faixa × etiologia × evolução, agregada e sem identificadores.
- Qualidade por ano/campo: conhecido, vazio, ignorado, inesperado, inaplicável e método usado.
- Fluxo por arquivo, UF notificadora e ano de notificação/sintomas; atraso derivado somente de datas válidas.
- Dicionário do esquema real e domínios anuais dos códigos.
- PacoteRDS local mínimo: bases separadas e metadados, sem sobrescrever o pacote prévio.

IdadeSINAN codifica unidade e magnitude. Traduzir horas/dias/meses/anos com validação da unidade; manter códigos inválidos como não interpretáveis. Compatibilizar `<1`,1–4,5–9,10–14,15–19,20–39,40–59,60–64,65–69,70–79,80+ com população. Para evitar células instáveis, grupos mais amplos podem ser derivados depois, com soma conservada.

Categorias etiológicas originais são exclusivas. Grupos derivados (por exemplo doença meningocócica) não são somados novamente às categorias componentes. PreservarMNE eMCC. O critérioPCR precisa ser descrito pela técnica/código e pelo domínio vigente; o rótulo“PCR-viral” doTabNet não prova agenteviral.

## 7. Comparação e divergências SINAN

Comparar o novo agregado com oTabNet preservado sob os mesmos filtros: total, sexo, idade, evolução, critério, mês e etiologia. Contagens/categorias devem ser comparadas exatamente; diferenças de rótulo entram numa tabela de equivalência explícita.

Data de atualização diferente pode produzir revisões, mas só considerar essa explicação se for documentada. Separar divergência entre snapshots de divergência entre recortes do mesmo snapshot. Para os seis registros históricos, conferir códigos não tabulados/ausentes e o ano em que ocorrem; não preencher o residual com“MNE” ou“ignorado” sem dados que sustentem.

Se totais nacionais gerais divergirem do snapshotTabNet, fazer uma consulta atual curta com universo equivalente e versioná-la, antes de declarar a base validada. Não lançar uma série de consultas repetidas para buscar igualdade.

## 8. SIH: módulo hospitalar eficiente

Primeira rodada: quatro consultas anuais por grupoCID (internações, óbitos, dias de permanência, valores aprovados) e perfis anuais de sexo/idade separados paraG00,A87,A39. G01–G03 permanecem na sérieCID, sem cruzamentos raros em massa. Validar cada perfil contra seu total do mesmo snapshot.

A perspectiva é SIH nacional por residênciaSalvador. Não substituir pela série de internações realizadas naBahia. Ano é processamento, diferente de ano de admissão e de sintomas. Dias de permanência totais permitem média ponderada como razão de totais compatíveis; nunca média simples das médias de grupos. Valores são aprovados administrativamente peloSUS, não custo econômico total, e podem exigir correção monetária somente na futura análise.

Grupos iniciais: G00/G01/G02/G03/A39/A87. Para análise estrita, revisar códigos etiológicos comoA17.0,B00.3,B01.0,B02.1,B26.1,B37.5,B45.1. Nem todos têm a mesma definição ou aparecem como categoria específica noTabNet; não incluir todoA17/B45 automaticamente. A extração detalhada porCID pode exigirSIH-RD; isso é fase posterior se a pergunta não puder ser respondida por agregados.

Não baixar milhares de arquivos nacionaisSIH-RD antes de justificar a necessidade. Um eventual móduloRD terá competência,UFprocessadora,diagnóstico principal, residência e longa permanência declarados; AIHs não serão deduplicadas arbitrariamente para fabricar pessoas.

## 9. SIM: mortalidade

Completar faixa etária por ano para o conjunto inicialG00–G03/A39/A87 e comparar com causa e sexo. A coletaBA por residência não demonstra óbitos de moradores registrados em outrasUFs; manter essa fronteira explícita. Se mortalidade entrar como eixo forte, comparar comTabNet nacional por residência ou coletar microdados nacionais com corte/documentação próprios.

Conservar causa básica; causa múltipla é outro desenho. Avaliar códigos etiológicos depois da revisão clínica, evitando duplicação entre manifestações e doença subjacente. Linhasomitidas ficam sem valor. Só traços/células convertem emzero quando a legenda do retorno permitir. Denominadores por sexo/idade precisam corresponder aos estratos.

Os202 óbitos do piloto não são óbitos“dentro dos1.976 casos” demonstrados. Não calcular letalidade comoSIM/SINAN nemSINAN/SIH. Uma vinculação individual exigiria chaves, validação e desenho específicos, fora desta primeira coleta pública.

## 10. PNI: cobertura e doses sem misturar métodos

Indicadores prioritários:MenC,pneumocócica10,penta/componenteHib eBCG. Separar dose/esquema e população alvo. Penta não corresponde a vacina exclusivamenteHib; coberturaBCG não mede diretamente proteção contra toda meningite. AcrescentarMenACWY/reforços apenas quando calendário, público e fonte puderem ser interpretados.

Investigar cobertura legada2014–2022 noTabNet e indicadores2023–2024 nos painéis atuais. A frente documental encontrou aNT84/2026, que revoga aNT90/2025 e estende retrospectivamente o cálculo individual a2023, e aNT69/2026, que consolida pneumocócicas conjugadas10/13/15/20 no indicador atual. Conferir implementação e definir fonte/método por indicador: não rotular o atual comoPCV10 exclusiva nem emendar séries por terem nomes parecidos. Preservar cobertura acima100% quando vier dafonte e investigar método, sem truncar artificialmente.

O piloto usa no máximooito consultas bem-sucedidas/20MB e operações públicas de leitura. Depois de falhasDNS, o teto de tentativasPOST foi ajustado para16; SIH/SIM tem teto24tentativas e11consultas exitosas. Tentativas e consultas lógicas são contadores separados, registrados no manifesto. Preservar exportação/resposta que realmente contenha município,ano,imunobiológico,indicador e definição. Se não houver exportação utilizável, documentar portal/filtro/campo e pendência concreta. Não estimar cobertura dividindo doses por população municipal total.

História vacinal dos casosSINAN e cobertura municipalPNI são variáveis diferentes. Associação ecológica não demonstra eficácia ou causalidade individual. Uma pergunta vacinal só avança se séries e eventos de agente/subtipo tiverem qualidade e volume suficientes.

## 11. População e demais denominadores

Reaproveitar os arquivos já congelados após conferirSHA:11totais,396chaves originais e242chaves compatíveisSINAN. Somas de sexo/idade devem conservar todos os totais. Preservar versãoRIPSA e referência1ºjulho.

Denominadores específicos por raça,escolaridade,gestação,imunobiológico ou população alvo não devem ser inferidos da população total. Quando inexistentes, limitar a descrição de proporções ou coletar fonte adequada. Não calcular riscos por categoria apenas pelo número bruto de registros.

## 12. Controle de qualidade e portões de aceite

| Controle | Aceite para a pergunta | Se falhar |
|---|---|---|
| Integridade | todos os hashes conferem; arquivos legíveis | preservar fontes; nova versão se necessário |
| Cobertura | anos/partições esperados presentes; fluxo e datas explícitos | marcar parcial; não produzir taxa final de lacunas |
| Identificação territorial | município de residência conferido em cada fonte | corrigir contrato/filtro antes do processamento |
| Totais | somas por dimensões conservadas e diferenças explicadas | preservar recortes separados e investigar |
| Sexo/idade | ≥95% conhecido por ano e faixas compatíveis | agrupar/períodos/sensibilidade; não usar campo faltante comozero |
| Evolução | ≥95% para comparação principal; eventos suficientes | secundária com sensibilidade; <90% impede tratá-la como completa |
| Etiologia | códigos interpretáveis e MNE explícita | estudar qualidade/grupos amplos; não chamar todo registro de agenteidentificado |
| Aplicabilidade | denominador de cada campo definido | não penalizar sorogrupo foraDM ou escolaridade em crianças pequenas |
| Duplicação | duplicatas técnicas explicadas | não retirar registros só por coincidência demográfica |
| Vacinas | indicador/dose/alvo/método comparáveis | separar séries por método e restringir pergunta |

Oslimites95%/90% e critérios de volume são escolhas operacionais do projeto, não escalas universalmente validadas nem cálculo de poder. Poucos óbitos/células exigem reduzircovariáveis ou descrição. Não selecionar subtipos e modelos porque geraram p-valores interessantes.

## 13. Desenho analítico posterior

Depois do congelamento:taxas anuais específicas,padronização por idade quando houver uma população padrão definida,Poisson/binomial negativa conforme dispersão,sazonalidade mensal e perfis de categorias amplas. Onze pontos anuais não sustentam automaticamente muitos parâmetros. Modelos de desfecho precisam banco conjunto validado,eventos suficientes e tratamento explícito dos dadosfaltantes.

Descrever separadamente2014–2019,2020–2021,2022–2024 pode apoiar sensibilidade, mas não prova efeito causal da pandemia. Registrar aNT154/2024 como mudança documental sem presumir implantação imediata ou atribuir tendências ànota. Subregistro, diagnóstico e acesso podem afetar contagens; diferenças entre sistemas serão discutidas como fronteiras de captação, não corrigidas por soma.

## 14. Entrega organizada

Um pacoteRDS principal pode reunir listas por fonte, sua configuração e manifestos. CSVs essenciais: SINAN anual/mensal/conjunto/qualidade, população,SIHannual/perfis,SIManual/perfis ePNIindicadores. Auditorias menores ficam nosmetadados/tabelas decontrole. Não criar um arquivo por sexo,mês,CID quando uma tabela longa basta.

Dadosbrutos ficam foraGit; scripts,configurações,planos,definições,preferências,achados metodológicos e status resumidos entram noGit. O repositório deve ter código/estrutura suficientes para reprodução por outraIA, sem depender apenas de caminhos pessoais ou scripts não enviados.

## 15. Como atualizar o manual a cada etapa

Atualizar `Boletim epidemiológico/docs/ESTADO_COLETA.md`, `docs/PREFERENCIAS_E_METODOS.md`, comandos, prompt decontinuidade eCHANGELOG. Registrar o que foi feito, o que funcionou/falhou, versão,dados/recortesvalidados, comandos testados e próximas pendências. Diferenciar achado novo de resultado prévio. Fazer commitlocal após verificação; publicação remota só quando solicitada/autorizada.

O manual será alimentado durante as próximas operações deste projeto. Esse procedimento não implica um monitor externo ou atualização automática enquanto ochat estiver inativo.

## 16. Sequência de execução desta rodada

1. Inventário e hash do piloto/população.
2. Catálogo atual e coletaSINAN em lotes deaté3.
3. LeituraSINAN local, esquema,seleção,domínios e comparaçãoTabNet.
4. Em frentes independentes:SIH/SIM ePNI, com diretórios distintos e limites deconsulta.
5. Consolidar cobertura,qualidade e estado dos módulos sem misturaruniversos.
6. AtualizarGit, gerar estado legível e indicar comandos/pendências.

O plano completo continua válido quando algum portal estiver indisponível: manter pendência e retomar apenas o quefaltou. Limites ou falhas não devem ser escondidos para chamar uma coleta de completa.
