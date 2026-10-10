# Preparação da base analítica, descritivos e gráficos — meningites em Salvador

Versão do plano: **10/10/2026**. Responsável pela integração: **Chat mestre**.

**Estado: planejamento concluído para revisão do pesquisador; execução aguardando seu próximo comando.** Este documento especifica trabalho futuro. A pasta analítica, as bases novas, os scripts novos, os descritivos e os gráficos aqui descritos ainda não foram produzidos. As leituras e propostas dos chats de apoio foram limitadas ao planejamento.

## 1. Resultado esperado e pergunta principal

Preparar uma entrada analítica central, compreensível e reproduzível, que permita descrever **a evolução temporal e o perfil das meningites e doença meningocócica registradas em residentes de Salvador, 2014–2024**. O núcleo será SINAN nacional e população. SIH, SIM e PNI permanecerão como módulos complementares com suas próprias unidades, períodos e limitações.

A entrega deve permitir abrir um pacote no R e localizar rapidamente os CSVs, definições, cobertura, descritivos e figuras. A organização deve evitar um arquivo para cada ano, sexo ou diagnóstico. Resultados descritivos, denominadores e interpretação acompanharão os gráficos.

Esta etapa futura terá três produtos sequenciais:

1. **Base preparada:** esquemas, códigos, chaves, grades, denominadores e rastreabilidade conferidos.
2. **Descritivos:** contagens, proporções, taxas, intervalos de confiança e qualidade dos dados, com fórmulas e universos explícitos.
3. **Gráficos focados:** poucas figuras ligadas a perguntas claras, com tabela de origem e texto descritivo.

Modelos multivariáveis, busca automática de p-valores, eficácia vacinal e conclusões causais ficam fora desta primeira entrega. A base será preparada para permitir análises posteriores sem reconstrução do projeto.

## 2. Ponto de partida preservado

As referências de entrada são as versões já documentadas, principalmente:

- `dados/tratados/meningites_salvador_20261009.rds`: pacote integrado, 129.144 bytes; SHA-256 declarado `9fec05cb6c73b51d6cf30669d186d740fbf0f4b200121e2ad30f713713571dd5`.
- `dados/tratados/sinan_br_20261009/meningites_salvador_sinan.rds`: registros mínimos locais e agregados nacionais.
- `dados/tratados/sinan_br_20261009/`: série, comparação, qualidade, domínios, seleção e tabelas de auditoria.
- `dados/denominadores/`: população total, sexo/idade original e faixas SINAN; manifesto `metadados/DENOMINADORES.json`.
- `dados/tratados/complementos_20261009/` e `metadados/complementos_20261009/`: SIH/SIM e suas conferências.
- `dados/tratados/pni_20261009/` e `metadados/pni_20261009/`: PNI, grade de disponibilidade, definições e validação.
- `dados/tratados/sinan/meningite_sinan_longo.csv`: benchmark TabNet preservado em 05/10.
- `pre_analise_meningite.rds`: versão histórica de 05/10, que não deve substituir silenciosamente lacunas da rodada atual.

O [relatório da coleta](RELATORIO_COLETA_INTEGRAL_20261009.md) e o [plano integral de coleta](PLANO_COLETA_INTEGRAL.md) permanecem referências para fontes e métodos.

| Módulo | Situação documentada em 09/10 | Consequência para a preparação |
|---|---|---|
| SINAN | 13 partições nacionais; 295.369 linhas; 2.255 residentes confirmados; 1.976 com sintomas 2014–2024 | Reutilizar o pacote local após conferir identidade e esquema; reler DBC somente se houver necessidade demonstrada |
| Comparação | Onze totais anuais e 572 células TabNet concordantes; seis categorias adicionais sem referência | Preservar referência ausente; não preencher o residual com zero ou etiologia presumida |
| Etiologia/evolução | Seis registros com códigos não canônicos, dois vazios, 442 MNE, 19 MCC isolada; 144 evoluções desconhecidas | Conservar registros e estados; manter letalidade secundária |
| População | 11 totais, 396 chaves originais e 242 harmonizadas | Usar a mesma versão demográfica e verificar as junções |
| SIH/SIM | Seis consultas válidas de onze; cinco consultas SIH pendentes | Preparar dados existentes e grade de cobertura, com complementação futura seletiva |
| PNI | 17 observações de 44 chaves solicitadas | Conservar 27 lacunas e separar legado/RNDS |

As quantidades são controles da versão de entrada, não resultados novos desta etapa. Com fontes idênticas, a preparação não deve alterar a coorte de 1.976. Se uma fonte for substituída por atualização, criar outro snapshot e investigar diferenças antes de mudar os controles esperados.

## 3. Pasta central e organização proposta

Pasta futura: **`C:\Pesquisa\Boletim epidemiolóico\Meningite\analise`**. A raiz é um parâmetro de projeto, permitindo a reprodução em outro computador.

```text
Meningite/
  analise/                              # criar somente na execução autorizada
    README.md                           # entrada, versão, objetos e limitações
    meningites_salvador_analitica.rds     # pacote principal; casos mínimos locais
    configuracao.json                   # parâmetros efetivamente lidos pelos scripts futuros
    dados/
      sinan_estratos_anuais.csv
      sinan_mensal.csv
      sinan_categorias_anuais.csv
      populacao.csv
      sih.csv
      sim.csv
      pni.csv
    documentacao/
      dicionario.csv
      fontes.csv
      cobertura.csv
      decisoes.md
    scripts/
      executar_etapa.R
      preparar_sinan_populacao.R
      preparar_complementos.R
      gerar_descritivos.R
      gerar_graficos.R
    resultados/
      RELATORIO_DESCRITIVO.md
      descritivos.csv
      figuras/                          # PNG e PDF das figuras aprovadas
    controle/
      manifesto.json
      validacao.json
      execucao.log
    trabalho/                           # áreas temporárias exclusivas das frentes
      sinan_populacao/
      complementos/
```

Os nomes acima são especificações, não arquivos já existentes. Se um script auxiliar for indispensável, justificar sua função; evitar camadas e bancos equivalentes sem necessidade. RDS é a entrada principal para R; os sete CSVs longos são exportações interoperáveis. Não criar SQLite, Parquet e XLSX simultaneamente por padrão.

Os brutos e versões anteriores continuarão nos diretórios atuais de `Meningite`, referenciados por caminhos e hashes. Centralizar a entrada analítica não exige duplicar ZIP/DBC ou mover o acervo histórico. Os CSVs analíticos serão UTF-8, separador `;`, decimal `.`, com ausências documentadas. A base de linhas de casos ficará no RDS local; não será exportada ao Git.

Na primeira execução haverá uma versão candidata e depois uma versão aceita. Antes de substituir uma versão aceita em execução posterior, preservar o pacote e seu manifesto anterior em uma pasta datada de versões, sem duplicar os brutos. A versão de fonte e a versão de processamento terão identificadores distintos.

## 4. Contrato comum dos dados

Cada tabela deverá declarar, diretamente ou por vínculo no dicionário/manifesto:

- `versao_analitica`, `snapshot_id`, origem, consulta e hash correspondente;
- município como texto: `292740`; código de sete dígitos, se houver, em campo separado;
- perspectiva territorial e abrangência: residência, município do registro ou registro BA;
- referência temporal: sintomas, processamento, óbito ou ano do indicador vacinal;
- granularidade, chave, categoria original, categoria harmonizada e regra aplicada;
- medida, unidade, valor e estado da observação;
- motivo de ausência e disponibilidade do numerador/denominador;
- versão preliminar/final, datas de extração e definição/método do indicador.

Uma linha não poderá reunir pessoas, AIHs, óbitos e coberturas sob uma unidade única. Não somar dimensões, medidas, totais e componentes. Todo cálculo deverá selecionar previamente sua fonte, medida e nível de agregação.

### Estados que não podem ser confundidos

| Estado | Valor numérico | Significado |
|---|---|---|
| `observado` | valor recebido | Observação aceita após interpretação do retorno |
| `zero_observado` | 0 | Zero explícito ou símbolo com legenda oficial compatível |
| `zero_derivado_coorte` | 0 | Nenhum registro na combinação de uma coorte integralmente lida e coberta |
| `pendente_falha_transporte` | ausente | Consulta falhou; não informa ausência de eventos |
| `nao_executado_teto` | ausente | Consulta não realizada por limite operacional |
| `linha_omitida_sem_imputacao` | ausente | A fonte não retornou a linha |
| `validacao_pendente` | conservado separadamente | Existe resposta, mas a observação não está aceita |
| `divergente` | conservado separadamente | Fontes/recortes comparáveis discordam; derivação afetada bloqueada |
| `inaplicavel` | ausente | A combinação não tem significado para o campo/indicador |
| `denominador_indisponivel` | taxa ausente | O numerador pode estar observado, mas falta população/denominador compatível |

O estado da cobertura é distinto do estado de um campo. No PNI legado, percentual observado com numerador/denominador não fornecidos continua sendo uma observação de cobertura oficial; não transformar toda a linha em ausente. Nunca aplicar preenchimento global de valores ausentes por zero.

## 5. SINAN: limpeza, chaves e variáveis

**Unidade:** registro de notificação confirmada, residente de Salvador, com sintomas em 2014–2024. Não é pessoa única demonstrada. Preservar notificações tardias e as duas fora da Bahia.

### 5.1 Identidade e rastreabilidade

Usar `snapshot_id + arquivo_origem + hash_tecnico` como chave operacional da versão atual, sob teste de unicidade. Hash representa igualdade técnica do registro, não identidade clínica da pessoa. Se houver repetição futura, sinalizar e investigar antes de excluir.

O RDS atual não contém a posição original da linha no DBC. Se essa referência se tornar necessária, sua extração exigirá alteração futura do leitor local; não inventar uma posição original a partir da ordem atual do RDS. Um índice de linha analítica poderá existir, com esse significado explícito.

Conservar códigos originais e rótulos derivados, ano/mês dos sintomas, ano da notificação, intervalo entre sintomas e notificação, flags existentes, arquivo/hash e versão. Retirar nomes e identificadores nominais de qualquer exportação pública; não incorporar novas variáveis pessoais sem necessidade analítica.

### 5.2 Regras de harmonização

| Campo | Regra futura |
|---|---|
| Município | Texto `292740`, residência; não confundir com município notificante |
| Sexo | Harmonizar M/F e rótulos; preservar ignorado, vazio e inesperado em estado próprio |
| Idade | Conservar código e unidade original; revisar conversão horas/dias/meses/anos e limites de faixa; sinalizar valores não interpretáveis |
| Etiologia | Domínio textual canônico `01`–`10`; conservar vazio e não canônico separadamente; não transformar `7`, `7.`, `7%`, `%7` ou `X` em `07` |
| Evolução | Alta, óbito por meningite e óbito por outra causa; conservar ignorado/vazio/inesperado e sua origem |
| Critério | Conservar os dez critérios; PCR geral não comprova agente viral. Equivalência “PCR - viral” somente no confronto histórico TabNet |
| Datas | Usar ano/mês e flags existentes; não reconstruir datas completas que não estão no pacote mínimo |
| Campos secundários | Raça/cor, escolaridade, exames, sorogrupo, hospitalização e história vacinal exigem domínio e universo de aplicação próprios |

Antes de alterar a conversão de idade, verificar limites de 1, 5, 10, 15, 20, 40, 60, 65, 70 e 80 anos; doze meses; dias próximos de um ano; unidades inválidas e limites extremos. A conversão aproximada atual usa 365,25 dias: uma correção não pode modificar silenciosamente faixas que já concordam com o benchmark.

Flags de data ausente não permitem distinguir retrospectivamente todo branco de todo erro de parsing. Se a análise exigir essa distinção, consultar os DBC locais de forma direcionada. Intervalos negativos entre sintomas e notificação serão preservados e contados na qualidade; não entrarão automaticamente em resumos de duração válida.

### 5.3 Inclusões e agrupamentos

A principal mantém MNE e MCC isolada. O título e o texto abrangem meningites e doença meningocócica. Uma sensibilidade excluindo somente MCC poderá ser derivada, com regra, denominador e controle explícitos; não substitui a coorte principal nem revalida diagnóstico.

Conservar categorias etiológicas originais exclusivas. Grupos derivados devem ter mapa explícito, sem sobreposição. O agrupamento meningocócico inclui MCC/MM/MM+MCC; outros agrupamentos deverão ser confrontados com as definições arquivadas antes de uso. Categoria registrada não equivale a agente isolado em laboratório.

Raça/cor e escolaridade não terão taxas populacionais sem denominadores correspondentes. Sorogrupo terá universo de aplicação documentado, especialmente doença meningocócica. Campo preenchido não será considerado automaticamente válido, negativo ou aplicável.

## 6. População, junções e grades completas

Manter as onze faixas compatíveis: `<1`, `1–4`, `5–9`, `10–14`, `15–19`, `20–39`, `40–59`, `60–64`, `65–69`, `70–79`, `80+`. Derivar agrupamentos mais amplos apenas por soma das mesmas faixas em numerador e denominador, com mapa salvo.

O CSV analítico `populacao.csv` conterá as **242 combinações ano × sexo M/F × faixa** como linhas básicas. Totais anuais, por sexo ou por idade serão derivados separadamente no RDS e conferidos contra os onze totais originais. Não adicionar linhas TOTAL à mesma soma dos componentes.

Herdar fonte, município, referência de 1º de julho e versão RIPSA do manifesto. A auditoria anterior valida integridade local e reagrupamento; não constitui nova revisão demográfica na fonte.

Toda junção terá cardinalidade declarada e testes de linhas antes/depois. Para taxa específica, o denominador deverá corresponder ao ano, sexo e faixa usados no numerador. Categoria ignorada permanece nas contagens totais, mas sua taxa específica fica ausente se não houver população correspondente.

### Bases SINAN para exportação

| Base | Granularidade | Controle |
|---|---|---|
| Registros mínimos no RDS | registro local da coorte | 1.976 linhas na versão de entrada; códigos/flags e origem preservados |
| `sinan_estratos_anuais.csv` | ano dos sintomas × sexo × faixa | Grade de 242 estratos válidos; ignorados preservados separadamente e sem denominador fictício |
| `sinan_mensal.csv` | ano dos sintomas × mês | 132 chaves, janeiro/2014–dezembro/2024 |
| `sinan_categorias_anuais.csv` | ano × dimensão × categoria | Sexo, idade, etiologia, evolução e critério em tabela longa; não somar dimensões diferentes |
| Qualidade no RDS e documentação | ano × campo × universo | Total, interpretável/conhecido, desconhecido e inaplicável conforme definição |

A grade mensal partirá das 131 combinações observadas. O mês sem registro receberá zero somente após confirmação de coorte integral e cobertura da janela, com `zero_derivado_coorte` e regra de origem. Não reutilizar essa regra para lacunas de consultas externas.

Taxa anual/específica = `n / populacao_compativel × 100000`. IC95 de Poisson representa incerteza da contagem registrada; não corrige subnotificação ou incerteza demográfica. Não inventar população mensal. A figura sazonal inicial usará contagens e distribuição mensal; eventual taxa mensal ou exposição em modelo posterior exigirá definição explícita.

## 7. Complementos: bases próprias e limites

### 7.1 SIH

Normalizar `sih.csv` com `tipo_tabela` (total anual ou perfil), CID, ano de processamento, medida, unidade, dimensão, estrato, snapshot e status. A chave incluirá todos esses componentes pertinentes.

- Usar apenas folhas CID G00–G03/A39/A87 nas somas analíticas. Capítulos/grupos-pai ficam na reprodução da fonte e auditoria.
- Uma observação G00/A87 obtida de marginal e repetida em consulta geral terá uma linha de fato e múltiplas origens documentadas, depois de conferir igualdade; não somar as origens.
- Perfis de sexo e idade são marginais separadas; não criar sexo × idade hospitalar por produto dessas marginais.
- Internações/AIHs são episódios administrativos. Óbitos hospitalares são altas por óbito. Valores aprovados são reais nominais; não são custo econômico total.
- A39 conserva o significado amplo de infecção meningocócica, sem equivalência automática com meningite meningocócica.
- Permanência média e valor por internação só serão derivados se dias, valores e denominadores tiverem universos administrativos compatíveis. Nunca calcular média simples das médias de grupos.

### 7.2 SIM

Normalizar `sim.csv` com tipo total/perfil, ano do óbito, recorte de causa básica, dimensão/estrato, residência, abrangência e snapshot. Criar uma tabela anual explícita com origem na resposta oficial; manter `conferencias.csv` como auditoria, sem tratá-la como banco primário de eventos.

A série atual representa os 202 óbitos no conjunto selecionado e fonte de registro BA. Não representa necessariamente todos os óbitos de residentes em todas as UFs. Não vincular esses óbitos ao SINAN ou calcular letalidade como SIM/SINAN. Uma futura fonte nacional terá outra abrangência/snapshot e deverá ser comparada antes de substituir a atual.

### 7.3 PNI

Normalizar `pni.csv` com as 44 chaves solicitadas, 17 observadas e 27 pendentes, preservando definição de série, ano, sistema/método, geografia, indicador, esquema, público, percentual e componentes oficiais disponíveis.

A chave semântica incluirá método/perspectiva/definição, e não apenas `indicador_grupo + ano`. Mesmo grupo temático não significa a mesma série histórica.

- Legado Penta: município do registro, residência não confirmada; percentual observado, componentes não fornecidos no agregado reaproveitado.
- RNDS: residência Salvador, numerador/denominador oficiais e seleção de indicador/ano/município conferida; implementação ETL não auditada.
- Preservar rótulos Meningocócica Conjugada e Pneumocócica Conjugada; não renomear como MenC/PCV10 exclusivas.
- Registrar as normas/definições arquivadas, incluindo NT84/2026, NT69/2026 e a inconsistência documental identificada no dicionário.
- Não emendar as curvas legado/RNDS, somar numeradores mensais deduplicados ou usar população municipal total como denominador vacinal.
- Cobertura BCG baixa será apresentada como registro do indicador com ressalva de qualidade, sem inferir ausência de vacinação. Se a fonte retornar cobertura acima de 100%, conservar e sinalizar, sem truncamento.

### 7.4 O que significa “completo para análise”

O núcleo SINAN/população poderá ser aceito com seus universos e grades completos. SIH, SIM e PNI terão classificação independente: `apto`, `apto_com_limites`, `parcial` ou `nao_utilizar_para_pergunta`.

Uma grade com todas as chaves e estados de ausência é completa como documentação de cobertura, mas não como série de valores observados. A aceitação do núcleo não autoriza declarar os complementos integralmente coletados. Lacunas complementares não precisam impedir os descritivos do núcleo; impedirão apenas as derivações que delas dependem.

## 8. Retomada seletiva da coleta — somente em execução futura autorizada

Esta seção é planejamento; **nenhuma requisição será feita agora**. O próximo comando determinará se a execução inclui complementação online ou apenas preparação dos dados existentes.

### SIH: cinco consultas, não um novo lote de onze

Prioridade: (1) internações por diagnóstico/ano; (2) dias de permanência; (3) G00 sexo; (4) A39 sexo; (5) A39 idade.

Proposta de orçamento adicional: dez POST de dados, até duas tentativas por consulta, contadores próprios e interrupção após três consultas consecutivas malsucedidas. Inspeção do formulário, tentativas, bytes e erros também deverão ser registrados. Reutilizar as seis respostas válidas e não zerar o histórico de 24 tentativas anteriores.

**Correção futura necessária:** `--priorizar-restantes` no coletor atual apenas reordena. Não garante seleção exclusiva das cinco pendências; uma versão sem caches pode repetir onze consultas. Antes de executar, implementar seleção explícita por consulta ou reutilização rastreável dos contratos/caches. Os novos resultados terão data/hash próprios, sem aparentar que foram extraídos em 09/10.

### PNI: 27 chaves correspondem a três consultas anuais

Consultar separadamente BCG, Meningococo C e Pneumocócica, com anos 2014–2022. Proposta: seis POST de dados no máximo, duas tentativas por consulta. A primeira consulta necessária será o teste real do transporte; se suas duas tentativas falharem, interromper esse módulo e documentar a indisponibilidade.

Não repetir os oito valores RNDS nem os nove Penta já conferidos. Preservar dose/esquema/calendário histórico e a distinção pneumocócica 2014–2015. Só aceitar resposta que confirme município, indicador, anos e contexto. Fonte indisponível mantém estado pendente.

### SIM e recorte clínico

Verificação nacional de mortalidade e CIDs etiológicos específicos será extensão condicionada ao eixo escolhido. Não baixar SIH-RD nacional ou microdados nacionais em massa para esta preparação. SIA permanece fora da entrega inicial, por não haver pergunta e recorte assistencial demonstrados.

## 9. Resultados descritivos previstos

Os resultados serão organizados no RDS e em um CSV longo `descritivos.csv`, com identificador de tabela, medida, unidade, período, estrato, valor, numerador, denominador, universo, status e referência à fonte. O relatório apresentará tabelas legíveis e interpretação; nenhuma estatística será produzida nesta rodada de planejamento.

| ID | Tabela futura | Conteúdo e denominador |
|---|---|---|
| D01 | Inventário e seleção | Arquivos, versões, residentes, confirmação, exclusões temporais, coorte e cobertura por fonte |
| D02 | Série anual principal | n, população, taxa registrada/100 mil e IC95; onze anos |
| D03 | Perfil por sexo/idade | n, percentual no total e no ano, desconhecidos, população compatível, taxas específicas e IC95 |
| D04 | Etiologia e critério | Categorias originais, grupos declarados, n/% anual, MNE, vazios e não canônicos separados |
| D05 | Distribuição mensal | Grade 132, totais mensais/anuais, distribuição por mês do calendário e regra do zero derivado |
| D06 | Evolução e qualidade | Alta, óbitos por meningite/outra causa e desconhecidos; completude por ano/campo/universo |
| D07 | Carga hospitalar | Internações disponíveis, óbitos, valores nominais e perfis; CID/medida/snapshot separados |
| D08 | Mortalidade selecionada | n anual e distribuição etária do conjunto, com abrangência BA explícita |
| D09 | Contexto vacinal | Coberturas oficiais e componentes disponíveis; método, geografia, lacunas e qualidade |
| D10 | Disponibilidade e limites | Módulo/período/campo, status, motivo, análises permitidas e condicionais |

Percentuais terão denominador escrito: total da coorte, total anual ou total de registros com campo interpretável. Uma proporção “entre conhecidos” não será apresentada como proporção entre todos. MNE é categoria válida da fonte, mas não agente identificado; disponibilidade de categoria e especificidade etiológica são medidas diferentes.

Para evolução, descrever primeiro contagens e `U/N` (desconhecidos/total). Se houver resumo secundário de óbito por meningite, mostrar `D/N` e `D/K`, com K = evolução conhecida, além de U. Não chamar uma dessas razões de letalidade completa sem ressalva. Sensibilidades adicionais poderão ser planejadas depois; não imputar desconhecidos.

Comparações descritivas 2014–2019, 2020–2021 e 2022–2024 terão os diferentes números de anos/exposição considerados. Não comparar apenas somas brutas de períodos com durações diferentes nem atribuir causalidade à pandemia. Intervalo sintomas–notificação, se incluído, terá mediana e quartis somente entre registros válidos, com n ausente/inválido/negativo declarado.

## 10. Plano de gráficos e texto interpretativo

Quatro figuras iniciais; complementos entram em figuras adicionais somente se contribuírem para a pergunta. Cada figura terá tabela de origem, unidade, território, referência temporal, universo, versão e nota de lacuna/preliminaridade pertinente.

| ID | Pergunta | Forma prevista | Condição de uso |
|---|---|---|---|
| F01 | Como variou a ocorrência registrada? | Dois painéis alinhados: contagens e taxa anual com IC95 | Núcleo e população aceitos; escalas separadas, sem eixo duplo |
| F02 | Quais diferenças existem por sexo e idade? | Painéis de taxas específicas e IC; categorias pequenas agrupadas com regra explícita | Numeradores e denominadores compatíveis; desconhecidos informados |
| F03 | Há concentração em determinados meses? | Mapa ano × mês ou distribuição mensal simples, conforme legibilidade | Grade 132 validada; zero diferente de dado ausente |
| F04 | Como mudou a classificação etiológica? | Composição por ano/período, poucos grupos disjuntos e tabela das categorias originais | MNE/MCC/residuais conservados; legenda sem confirmação laboratorial presumida |
| F05 | Como evoluiu a carga hospitalar? | Linhas por CID/medida em painéis próprios | Cada série com sua cobertura; linha não atravessa ausência |
| F06 | O que o PNI registra e onde faltam dados? | Pontos/painéis separados por método e grade de disponibilidade | Sem linha contínua legado/RNDS; BCG e componentes com ressalvas |

Qualidade da evolução poderá ser uma pequena tabela/figura no relatório, sem multiplicar gráficos de todos os campos. Figuras complementares SIM terão o rótulo de causas selecionadas e registro BA; não serão combinadas com SINAN para aparentar uma letalidade.

Exportar PNG para consulta e PDF vetorial para uso no trabalho, com nomes correspondentes. Usar cores distinguíveis, fontes legíveis, escalas consistentes e poucos painéis. Barras de contagem terão origem em zero. Evitar gráficos 3D, todas as variáveis em um painel e dezenas de arquivos automáticos.

Para cada figura, o relatório trará: pergunta, dois ou três resultados descritivos verificados, fórmula/universo e interpretação limitada aos dados. Número de casos maior não implica risco maior sem população; categoria MV não prova todos os diagnósticos virais por laboratório; queda temporal não comprova sua causa.

## 11. Tarefas delimitadas e propriedade dos arquivos

As duas propostas de apoio desta rodada já foram recebidas. A atribuição abaixo reserva responsabilidades para uma execução futura; não dispara implementação agora.

| Responsável | Tarefa futura exclusiva | Entrega para integração | Área de escrita futura |
|---|---|---|---|
| **Chat mestre** | Coordenar versões, fechar contratos, integrar frentes, gerar pacote final, descritivos/gráficos e atualizar manual/Git | Entrada única, relatório, figuras, manifesto, controle final | `analise/` final e Git; arquivos finais escritos somente pelo mestre |
| **Revisar contexto do projeto (2)** | Frente A: preparar SINAN e população; revisar domínios/idades; completar grades; validar junções, totais e benchmark | Bloco SINAN/população candidato, tabelas agregadas, funções R e relatório de controles | `analise/trabalho/sinan_populacao/` |
| **Revisar contexto do projeto** | Frente B: normalizar SIH/SIM/PNI; grades/status, unidades e semântica; especificar/realizar retomada seletiva quando autorizada | Bloco complementar candidato, definições, cobertura, funções R e relatório de controles | `analise/trabalho/complementos/`; novas coletas em diretórios próprios designados pelo mestre |

### Frente A — lista operacional para o próximo comando

1. Validar entradas congeladas, sem repetir download nacional.
2. Conferir identidade da coorte, códigos originais, conversão de idade e regras de desconhecidos.
3. Preparar grade anual sexo/idade e mensal; preservar desconhecidos e justificar zeros derivados.
4. Preparar população harmonizada e mapas de agrupamento, testar cardinalidade das junções.
5. Gerar categorias/qualidade necessárias a D01–D06 e F01–F04.
6. Entregar candidato e controles, sem sobrescrever bases de 09/10, pacote final ou Git.

### Frente B — lista operacional para o próximo comando

1. Validar entradas complementares preservadas e suas abrangências.
2. Separar folhas CID, totais, perfis e medidas/unidades; documentar múltiplas origens do mesmo fato.
3. Construir grades de cobertura, com cinco consultas SIH e 27 chaves PNI pendentes.
4. Corrigir futuramente seleção exclusiva das consultas faltantes antes de coleta; cumprir orçamento e interrupção.
5. Preparar tabelas D07–D10 e insumos de F05/F06, sem cruzamentos artificiais ou emenda vacinal.
6. Entregar candidato e controles; não gerar pacote final, editar arquivos da Frente A ou fazer Git.

Uma frente avisará o mestre ao concluir ou encontrar incompatibilidade, com caminhos, fontes e controle afetado. Não assumir autorização para alterar arquivos de outra frente. O mestre será o único a promover candidatos para o diretório final e editar o manual Git. Ao fim das tarefas, os chats encerram e aguardam atribuição; não iniciam fases seguintes por conta própria.

## 12. Sequência, dependências e critérios de aceite

| Etapa | Responsável | Depende de | Aceite e produto |
|---|---|---|---|
| P0 — planejamento | Mestre + propostas A/B | leitura local de documentos | Este plano e tarefas delimitadas; encerrar aguardando comando |
| P1 — configuração/inventário | Mestre | novo comando humano de execução | Raiz, versões, parâmetros, dependências, entradas e hashes identificados |
| P2A — núcleo | Frente A | P1 | Candidato SINAN/população, grades e controles completos |
| P2B — complementos | Frente B | P1 | Candidato por fonte, lacunas explícitas e retomada seletiva se incluída no comando |
| P3 — integração/validação | Mestre | P2A e entregas P2B | Pacote candidato e CSVs coerentes; status independente por módulo |
| P4 — descritivos | Mestre | aceite das bases usadas | D01–D10 pertinentes, fórmulas/universos e relatório de qualidade |
| P5 — figuras | Mestre | descritivos e tabelas de origem | F01–F04 e complementares pertinentes, com inspeção visual |
| P6 — entrega | Mestre | P3–P5 aprovadas | Pacote aceito, documentação, manifesto, relatório e Git local atualizado |

P2A e P2B podem ocorrer em paralelo após P1. Falha de complemento não libera uma análise que exige esse dado, mas também não invalida automaticamente o núcleo. Os critérios abaixo são verificações técnicas; não criam pedidos adicionais de aprovação a cada passo.

### Controles obrigatórios na execução futura

1. **Identidade:** hashes/tamanhos, scripts e parâmetros registrados; sem mistura silenciosa de snapshots.
2. **Fluxo SINAN:** conservar os controles da versão congelada: 295.369 linhas nacionais, 3.871 residentes, 2.255 confirmados, 1.976 na janela, 279 fora e zero confirmados sem data; confirmar referência no fluxo preservado.
3. **Somas:** anual, mês, categorias e conjunto fecham a coorte; nenhuma perda de linha em junções. Em estratos com sexo conhecido, declarar o registro ignorado fora do denominador específico, conservado no total.
4. **Chaves/grades:** onze anos, 132 meses, 242 estratos válidos, categorias desconhecidas preservadas; contagens inteiras não negativas; combinação inaplicável distinta de zero.
5. **Domínios:** seis não canônicos e dois vazios de etiologia; 144 evoluções desconhecidas; MNE/MCC e UF fora BA preservadas; técnica PCR com significado correto.
6. **Duplicação:** verificar chave operacional e repetições técnicas; não deduplicar pessoas por idade/sexo/datas coincidentes. Zero duplicatas atual não é regra de exclusão futura.
7. **População:** 396 chaves originais e 242 harmonizadas, unicidade/positividade; somas conservam onze totais; junção muitos-para-um sem multiplicação.
8. **Benchmark:** 572 células comparáveis sem divergência para as mesmas fontes; seis extras com referência ausente. Diferença nova implica investigação, não ajuste para forçar igualdade.
9. **SIH/SIM:** folhas sem subtotal duplicado; G00/A87 conferidos entre origens; idade SIM conserva onze totais. Exigir quantidade esperada de controles: tabela vazia não passa porque `all(...)` retornou verdadeiro.
10. **PNI:** 44 chaves semânticas esperadas; 17 observações atuais e 27 pendências antes de complementação; filtros e razões RNDS conferidos; ausência de componentes legados não apaga percentual observado.
11. **Derivações:** denominador correto/positivo; nenhuma taxa com denominador indisponível; nenhuma razão de universos incompatíveis; percentuais com universo explícito.
12. **Interoperabilidade:** reler RDS e CSVs, comparar conteúdo, tipos e ausências; município permanece texto; nenhuma coluna nominal publicada.
13. **Figuras:** inspeção visual de rótulos, cores, escala, IC, legibilidade, unidades, lacunas e concordância numérica com tabelas.

Controles de integridade/seleção/junção são bloqueantes para a saída afetada. Incompletude conhecida é registrada e limita a interpretação; não se corrige por exclusão automática. Valores inesperados vão para relatório de decisões e investigação da fonte.

## 13. R, portabilidade e execução reproduzível futura

O controlador futuro `executar_etapa.R` terá fases explícitas e configuração realmente lida, contendo raiz, versões de entrada, município, janela, mapas, critérios, orçamento e diretórios. Distinguir modo offline de coleta autorizada. Não passar `20261010` aos scripts antigos como se isso migrasse automaticamente dados de 09/10: eles esperam arquivos nas pastas da versão informada.

Reaproveitar funções e conhecimento de `processar_sinan_br_historico.R` e `consolidar_coleta.R`, preservando seus produtos históricos. Evitar reexecutar treze DBC para produzir tabelas já deriváveis do pacote mínimo. Novos scripts somente serão escritos após autorização de execução.

Na execução, verificar R, bibliotecas acessíveis, pacotes e versões antes de começar; não instalar automaticamente durante coleta. Usar arquivos `.R` chamados com argumentos, evitando aspas perdidas em comandos inline no Windows PowerShell 5.1. Caminhos serão relativos à raiz parametrizada, com normalização de separadores. Registrar `sessionInfo()`, parâmetros e código no manifesto.

A implementação preferirá base R e pacotes já disponíveis. Um pacote de gráficos será usado se instalado e necessário à entrega; a falta de dependência deverá ser resolvida sem fabricação de saídas. Não prometer compatibilidade entre sistemas sem teste real. A definição dos contratos será independente do caminho pessoal do pesquisador.

A liberação será feita a partir de área temporária dentro do projeto, depois dos controles. Uma interrupção não deve substituir o pacote aceito por um pacote parcial. Não excluir ou mover recursivamente o acervo; qualquer operação de organização deverá verificar o destino absoluto e preservar os arquivos anteriores.

## 14. Atualização do Git e documentação

Durante esta rodada, atualizar somente o plano e documentação: estado, preferências, prompt, README e changelog. Copiar o plano ao manual Git com hash idêntico. Não editar scripts de processamento, criar bases, executar descritivos ou gerar gráficos.

Na execução futura, versionar código, configuração, dicionários, métodos, decisões, cobertura e agregados revisados. Manter DBC/ZIP/HTML e RDS/casos individuais fora do Git. Atualizar manifesto antes de aceitar novas cópias; não normalizar bytes de arquivos espelhados sem registrar novos hashes.

O relatório final da execução dirá, em português: o que foi feito, onde abrir, registros/universos, controles aprovados, módulos parciais, interpretação permitida e próximos passos. Git será atualizado localmente; publicação remota depende da autorização pertinente.

## 15. Registro da coordenação e condição de início

Em 10/10, o Chat mestre atribuiu **somente planejamento** aos chats “Revisar contexto do projeto (2)” e “Revisar contexto do projeto”. Ambos entregaram propostas em leitura local e informaram não ter executado R/Python, consultas externas, alterações de bases ou geração de gráficos. O mestre integrou suas contribuições neste documento.

As principais contribuições incorporadas foram: chave local sem confundir hash/pessoa; revisão de idade e dados ausentes; grade de 132 meses; cardinalidade nas junções populacionais; chaves semânticas PNI; distinção de abrangência SIM; controle de tabelas vazias; seleção exclusiva de pendências SIH; 27 chaves PNI em três consultas; áreas de escrita exclusivas e critérios de liberação.

**Encerramento desta rodada:** salvar e conferir a documentação, atualizar o Git local, informar o pesquisador e terminar. A execução P1–P6 ficará aguardando o próximo comando humano. “Continuar” nesta rodada mantém o escopo de terminar o plano; não revoga por si só o pedido explícito de não iniciar a implementação.

Um próximo comando poderá autorizar “executar o plano completo” ou especificar “preparar apenas os dados existentes, sem nova coleta”. O mestre aplicará o escopo efetivamente pedido e reutilizará estas tarefas, sem iniciar todas as fases por inferência antes desse comando.
