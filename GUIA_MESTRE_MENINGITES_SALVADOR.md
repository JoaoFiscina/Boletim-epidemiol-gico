# Guia mestre para análise de meningites em Salvador

## 1. Para que este manual serve

Este documento reúne o procedimento que funcionou no projeto, as decisões metodológicas, os erros encontrados, as preferências de organização e o estado dos dados. Ele é um manual de pesquisa e reprodução, não uma declaração de que todas as bases estejam completas ou prontas para publicação.

Uma IA que receber este arquivo deve primeiro ler as seções 2, 4, 6 e 9, verificar os arquivos disponíveis e só depois executar qualquer download. A prioridade é continuar o que está pendente, não baixar novamente arquivos já validados.

## 2. Pergunta e escopo atuais

Pergunta recomendada:

> Como variaram os casos confirmados registrados de meningites e doença meningocócica entre moradores de Salvador de 2014 a 2024, segundo idade, sexo, mês dos sintomas e qualidade da classificação diagnóstica?

O título deve mencionar “meningites e doença meningocócica”, porque o banco inclui 19 casos de meningococcemia isolada. Uma análise restrita a acometimento meníngeo pode ser derivada depois, mas a regra de inclusão precisa ser escrita antes de calcular taxas.

O primeiro objetivo é avaliar viabilidade e qualidade. Ainda não é permitido tratar os resultados como incidência verdadeira, cobertura completa, eficácia vacinal ou letalidade final.

## 3. Preferências de organização do pesquisador

- Idioma de trabalho: português do Brasil.
- Entregáveis preferidos: arquivos reais, nomes descritivos, comandos reaproveitáveis, tabelas CSV, pacote RDS e relatório legível.
- Preservar dados brutos e saídas anteriores; não apagar para “limpar”.
- Usar PowerShell no Windows e R/RStudio para tabelas e gráficos.
- Manter base longa por ano, variável e categoria; derivar tabelas largas apenas para leitura.
- Organizar em poucos diretórios: configuração, scripts, brutos, tratados, metadados, resultados e referências.
- Explicar claramente o que está completo, parcial, pendente ou inconclusivo.
- Preferir poucos gráficos úteis e interpretações palatáveis a dezenas de testes automáticos.
- Não preencher valores faltantes com zero sem evidência explícita.
- Ao coordenar frentes, dividir responsabilidades, evitar download duplicado e registrar o caminho de cada saída.

## 4. Constantes do projeto

| Elemento | Valor a usar |
|---|---|
| Município | Salvador |
| Código IBGE | `292740` |
| Perspectiva principal | residência do caso/óbito/internação, sempre declarada |
| SINAN | ano dos primeiros sintomas, 2014–2024 |
| Arquivos nacionais de apoio | partições de notificação 2014–2026; 2024–2026 já testadas |
| População | residente municipal, referência de 1º de julho, mesma revisão RIPSA |
| População usada nas taxas | 2014: 2.705.138; 2015: 2.693.763; 2016: 2.682.130; 2017: 2.669.559; 2018: 2.658.252; 2019: 2.647.884; 2020: 2.636.986; 2021: 2.622.913; 2022: 2.607.447; 2023: 2.589.296; 2024: 2.568.928 |
| Fonte populacional | `popsvs2024br.def`, formulário TabNet oficial |

Não usar população da Bahia para produzir taxa de Salvador. Conferir sempre se a tabela consultada está em “residência” ou “ocorrência/atendimento”.

## 5. Fontes e unidades corretas

### SINAN/TabNet

Use para casos/notificações conforme definição da ficha de meningite. As tabelas que foram validadas foram ano × total, sexo, idade, evolução, critério, mês dos sintomas e etiologia. A tabela de etiologia tem universo diferente do total geral e não deve ser colada automaticamente à série principal.

### SINAN nacional em DBC

Use para verificar cobertura dos arquivos BA, notificações fora da Bahia, atrasos, códigos reais e cruzamentos conjuntos. O catálogo oficial distingue arquivos finais e preliminares. Arquivos posteriores podem conter notificações tardias; não concatenar versões sobrepostas sem regra de deduplicação demonstrada.

Campos relevantes encontrados nos DBC: `CLASSI_FIN`, `EVOLUCAO`, `DT_SIN_PRI`, `DT_NOTIFIC`, `NU_ANO`, `ID_MN_RESI`, `SG_UF`, `ID_MUNICIP`, `SG_UF_NOT`, `ID_AGRAVO`, `CON_DIAGES`, `CRITERIO`, `NU_IDADE_N`, `CS_SEXO`, `CLA_SOROGR`, `MED_DT_EVO` e `DT_ENCERRA`.

### SIH/SUS

Use para carga hospitalar, internações/AIHs e óbitos hospitalares. Uma AIH é episódio administrativo, não necessariamente pessoa. A série testada usa residência Salvador e ano de processamento. Mantenha grupos CID separados: `G00`, `G01`, `G02`, `G03`, `A39` e `A87`. `A39` é infecção meningocócica, não sinônimo perfeito de meningite meningocócica.

### SIM

Use para óbitos por causa básica, com ano do óbito e residência declarados. A ausência de uma linha no retorno não autoriza preencher zero. O SIM não é o denominador de letalidade do SINAN sem vinculação individual e desenho específico.

### PNI

Ainda não coletado nesta etapa. Só incluir depois de conferir imunobiológico, população-alvo, dose, calendário vigente e unidade do indicador. Cobertura municipal é medida ecológica; não prova vacinação individual ou proteção contra toda a categoria de meningite.

## 6. Sequência de trabalho recomendada

### 6.1 Inventário e preservação

1. Verificar se `C:\Pesquisa\Boletim epidemiolóico\Meningite` existe.
2. Ler `PLANO_COLETA.md`, `RELATORIO_PRE_ANALISE.md`, `metadados/RESULTADO_PRE_ANALISE.json` e `metadados/RESULTADO_PILOTO_BR.json`.
3. Listar scripts e manifests antes de executar.
4. Conferir SHA-256 dos arquivos já validados.
5. Criar uma nova pasta de coleta/versionamento quando a fonte ou parâmetros mudarem; não sobrescrever HTML, CSV, ZIP ou DBC.

### 6.2 Descoberta do TabNet

Não inventar URL, nome de arquivo ou parâmetro. Abrir o formulário `.def`, registrar os nomes dos campos, testar uma tabela pequena e salvar resposta, parâmetros, data e hash. O formulário pode usar ISO-8859-1 e o link CSV pode ser temporário.

As consultas do SINAN Bahia foram feitas por POST ao formulário oficial. O total geral exigiu uma consulta adicional para reconciliar a tabela de etiologia; essa exceção já está documentada. Não repetir consultas em lote sem necessidade.

### 6.3 Coleta nacional

O catálogo oficial `ftp.php` foi usado para confirmar os nomes reais. A rota HTTPS `download.php` permitiu baixar rapidamente `MENIBR24`, `MENIBR25` e `MENIBR26`. O piloto nacional leu 25.485, 26.983 e 19.450 registros, todos com 131 campos.

Para completar a série, baixar uma vez cada partição `MENIBR14`–`MENIBR23`, preservando finais e preliminares. Filtrar:

```text
ID_MN_RESI = 292740
CLASSI_FIN = 1
ano(DT_SIN_PRI) entre 2014 e 2024
```

Manter notificações tardias, ano de notificação e UF notificadora em colunas separadas. Nunca remover registros somente porque a UF notificadora não é BA.

### 6.4 Tratamento e auditoria

Para cada arquivo, registrar linhas nacionais, linhas de Salvador, casos confirmados, sintomas fora do período, datas ausentes, notificações tardias, UF notificadora e duplicatas técnicas exatas. Não declarar pessoas únicas sem chave suficiente.

Comparar o agregado nacional com o TabNet no mesmo universo por total, sexo, idade, evolução, critério e etiologia. Se houver diferença, conservar ambos, quantificar e investigar; não forçar igualdade.

### 6.5 Denominadores

Reutilizar a população já conferida, gerar faixas compatíveis com o SINAN e testar conservação das somas:

- `<1 Ano`, `1-4`, `5-9`, `10-14`, `15-19`;
- `20-39`, `40-59`, `60-64`, `65-69`, `70-79`, `80 e +`.

Uma taxa simples é `casos / população × 100.000`. O intervalo de Poisson usado no diagnóstico é intervalo da contagem registrada; não corrige subnotificação.

### 6.6 Análise no R

Executar primeiro validações, depois tabelas e só então gráficos. Os gráficos essenciais são:

1. casos e taxa anual com população;
2. composição das categorias etiológicas com denominador explícito;
3. preenchimento anual de campos, distinguindo ausência de coleta de zero.

Não começar com dezenas de regressões ou p-valores. Com onze pontos anuais, modelos temporais complexos ficam frágeis. Planejar poucos desfechos e agrupar categorias raras.

## 7. Resultados já obtidos

- SINAN/TabNet: 1.976 casos, 2014–2024.
- Taxa registrada: 13,34/100 mil em 2014; 1,52/100 mil em 2020; 6,31/100 mil em 2024.
- Sexo: 1.132 masculinos, 843 femininos, 1 ignorado.
- Faixa 20–39: 537 casos, 27,2% do período.
- Etiologia: 1.970 tabulados; 874 MV, 442 MNE, 261 MB, 115 MP, 91 MTBC, 92 MOE, 44 MM, 22 MM+MCC, 19 MCC, 8 MH e 2 ignorados.
- Evolução no total geral: 1.566 altas, 190 óbitos por meningite, 76 óbitos por outra causa e 144 ignorados.
- Em 2024, 32/162 (19,8%) estavam sem evolução conhecida.
- Piloto nacional 2024: 162 casos de Salvador, concordância zero nas células comparadas com TabNet; um caso notificado fora da Bahia.
- SIH: 532 G00, 489 A87 e 122 A39 no período; manter demais grupos separados.
- SIM: 202 óbitos nos códigos selecionados; G00=100, G03=75, A39=15 e A87=12. G01/G02 não retornaram linhas; não imputar zero.

## 8. Interpretação correta das principais inconsistências

O total geral e as tabelas de sexo, idade, evolução, critério e mês fecham em 1.976. A tabela de etiologia fecha em 1.970. A diferença é de seis registros em 2014, 2015, 2016, 2017 e 2022. A causa não foi demonstrada. Não atribuir automaticamente a atualização, código vazio, revisão ou erro de extração.

`MNE` significa meningite não especificada e é uma limitação de especificidade, não um dado inútil. `MV` aparece como rótulo viral/asséptico no TabNet, mas o dicionário oficial precisa ser consultado antes de chamar todos os casos de virais. O piloto mostrou que `CRITERIO=9`/PCR aparece em categorias bacterianas; não publicar “confirmação viral por PCR” com base somente no rótulo do TabNet.

Preenchimento alto indica disponibilidade do campo, não validade clínica. Evolução abaixo de 95% em vários anos, especialmente 2023–2024, reduz a confiança em comparações de letalidade.

## 9. Critérios de decisão

Seguir com série geral se totais, população e referência temporal estiverem íntegros. Seguir com idade/sexo se preenchimento anual for pelo menos 95% e as faixas tiverem denominador compatível. Usar subtipos somente em grupos amplos quando houver volume suficiente. Tratar letalidade como secundária se evolução estiver abaixo de 95%. Recusar uma conclusão específica quando o campo não foi coletado, quando os universos divergem sem explicação ou quando o número de eventos é pequeno.

Não abandonar o tema inteiro por causa de uma categoria rara ou de um módulo incompleto. Ajustar a pergunta e separar claramente o que é válido.

## 10. O que funcionou e o que não funcionou

Funcionou: consultar o formulário real antes de automatizar; preservar HTML/CSV/DBC e hashes; usar o catálogo oficial; usar a rota HTTPS oficial para os ZIPs MENIBR; ler DBC em R com `read.dbc`; comparar agregados nacionais com TabNet; manter SIH e SIM separados; criar um RDS compacto com objetos distintos.

Não funcionou ou não deve ser repetido: presumir nomes de download sem consultar o catálogo; tratar erro de rede como zero; usar a série BA como cobertura nacional; concatenar arquivos preliminares/finais sem deduplicação; reconstruir cruzamentos individuais a partir de marginais; interpretar `A39` como meningite meningocócica completa; transformar a ausência de linha SIM em zero; usar SIM/SIH para corrigir automaticamente a evolução do SINAN; instalar pacotes durante a coleta sem necessidade; rodar modelos complexos antes de fechar a qualidade.

No Windows, `python` pode não estar no PATH. Use o runtime documentado em `C:\Users\joaov\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`, ou confirme outro Python antes de executar. Para R, foi usado `C:\R\R\R-4.5.1\bin\x64\Rscript.exe`.

## 11. Próximos passos obrigatórios

1. Coletar e auditar `MENIBR14`–`MENIBR23`.
2. Comparar a série nacional completa com o TabNet por ano e categoria.
3. Esclarecer a diferença histórica de seis registros.
4. Completar SIH sexo/idade anual e SIM idade somente se esses módulos entrarem na pergunta.
5. Definir uma análise principal antes dos modelos: tendência/taxa, perfil ou sazonalidade.
6. Considerar PNI somente depois de escolher meningocócica, pneumocócica, Hib ou outro agravo específico e seus indicadores.
7. Congelar uma versão analítica, gerar manifesto final e registrar a data de atualização das fontes.

## 12. Fontes oficiais usadas

- SINAN/TabNet: `https://tabnet.datasus.gov.br/cgi/deftohtm.exe?sinannet/cnv/meninba.def`
- Transferência de arquivos DATASUS: `https://datasus.saude.gov.br/transferencia-de-arquivos/`
- Ficha de meningite: `https://portalsinan.saude.gov.br/images/documentos/Agravos/Meningite/Meningite_v5.pdf`
- Dicionário: `https://portalsinan.saude.gov.br/images/documentos/Agravos/Meningite/DIC_DADOS_Meningite_v5.pdf`
- Caderno: `https://portalsinan.saude.gov.br/images/documentos/Agravos/Meningite/Caderno_analises_Meningites.pdf`
- Nota Técnica Conjunta 154/2024: `https://www.gov.br/saude/pt-br/centrais-de-conteudo/publicacoes/notas-tecnicas/2024/nota-tecnica-conjunta-no-154-2024-dpni-svsa-ms.pdf`
- População: `https://tabnet.datasus.gov.br/cgi/deftohtm.exe?ibge/cnv/popsvs2024br.def`
- SIH residência: `https://tabnet.datasus.gov.br/cgi/deftohtm.exe?sih/cnv/nrbr.def`
- SIM: `https://tabnet.datasus.gov.br/cgi/deftohtm.exe?sim/cnv/obt10ba.def`

As URLs não substituem os parâmetros completos. Toda coleta deve salvar os parâmetros e a resposta real.
