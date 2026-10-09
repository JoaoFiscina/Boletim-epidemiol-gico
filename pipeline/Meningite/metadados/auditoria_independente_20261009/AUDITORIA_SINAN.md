# Auditoria independente SINAN — Salvador

Data: 09/10/2026. Escopo atribuído pelo Chat mestre: controles mecânicos do processamento nacional de meningites, versão 20261009. **Resultado final: controles dos dados concordantes; divergência transitória do hash do script resolvida pela nova execução, conforme reconciliação abaixo.**

Auditoria exclusivamente local: nenhum acesso à rede, alteração de scripts, bases, manifestos ou Git. Este relatório é o único arquivo produzido. Não constitui validação clínica, identificação de pessoas únicas ou avaliação de vacinação.

## Método e evidência

Foram recalculados SHA-256 e tamanhos dos 13 DBC e dos 16 produtos listados no resultado do processamento, além dos hashes do processador e do snapshot TabNet: 31 verificações de hash. Os 15 CSV foram lidos com Python padrão, delimitador ponto e vírgula e UTF-8. Foram examinados o código do processador, o manifesto bruto e o resultado JSON.

Em execução independente, R 4.5.1 com os pacotes já instalados `read.dbc`, `jsonlite` e `digest` releu integralmente os 13 DBC, sem executar o processador de produção. Reaplicou residência `ID_MN_RESI=292740`, confirmação `CLASSI_FIN=1` e ano dos primeiros sintomas `DT_SIN_PRI` entre 2014 e 2024, inclusive. O teste de confirmação aceitou as representações textuais `1` e `01`; as contagens coincidiram com o processamento. Para duplicatas técnicas, foram recalculados hashes das 131 colunas originais de cada registro selecionado. Os conjuntos desses hashes coincidiram com os do RDS.

Avisos do ambiente R sobre locale e representação UTF-8 não impediram a leitura; a execução final terminou com código zero. Uma primeira tentativa não encontrou a biblioteca por variável de ambiente e outra teve problema de caminho com acento; ambas foram substituídas por biblioteca explícita e caminhos relativos, sem instalar pacotes ou modificar arquivos.

## Controles

| Controle | Resultado | Evidência recomputada |
|---|---|---|
| Integridade dos dados | Concordante | Na primeira passagem, 31 hashes corretos; tamanhos dos 29 arquivos com tamanho declarado também corretos. DBC, produtos e snapshot sem divergência nessa passagem. |
| Integridade do script ao finalizar | Divergente | Na conferência final, o processador atual passou a SHA-256 `6353322886b18df9e3ce37aadd089fe3b08a716d0dbf6b2711537564a828f387`, distinto do hash registrado no JSON. Indica alteração entre as verificações; não se atribui aqui autoria ou motivo. RDS e snapshot reconferidos mantêm os hashes registrados. |
| Partições | Concordante | MENIBR14 a MENIBR26, 13 arquivos; 131 campos originais em cada esquema. |
| Fluxo nacional → residência → confirmação | Concordante | 295.369 registros nacionais; 3.871 residentes de Salvador; 2.255 residentes confirmados em todas as datas. Releitura dos DBC e fechamento dos fluxos concordam. |
| Janela temporal | Concordante | 2.255 = 1.976 com sintomas em 2014–2024 + 279 fora da janela + 0 sem data de sintomas; fechamento também por partição. |
| Totais anuais | Concordante | Todos os 11 totais da releitura coincidem com série anual e total geral TabNet. |
| Comparação TabNet | Concordante | 578 linhas = 572 células comparáveis + 6 linhas extras de etiologia. Valores TabNet confrontados diretamente com o snapshot longo, sem confiar somente na coluna de diferença. Todas as 572 células comparáveis concordam. |
| Seis códigos etiológicos não canônicos | Concordante | Seis registros preservados, sem recodificação; seis células extras com `n_br=1`, `n_tabnet` e diferença ausentes. Ausência no snapshot não convertida em zero. |
| Etiologia vazia | Concordante | Dois registros, distintos dos seis códigos não canônicos. |
| Evolução desconhecida | Concordante | 144 registros fora dos códigos interpretáveis 1–3, confirmados nos DBC e nos marginais. Não redistribuídos entre alta e óbitos. |
| Notificação fora da Bahia | Concordante | Dois residentes: sintomas em 2018, UF de notificação 41; sintomas em 2024, UF 35. Incluídos na perspectiva por residência. |
| Duplicatas técnicas | Concordante | Zero hashes repetidos na coorte dos 1.976 registros; zero remoções declaradas. Conjunto de hashes originais recalculados igual ao RDS. |
| Unicidade das chaves agregadas | Concordante | Nenhuma chave repetida nos 15 CSV, conforme definição abaixo. |
| Fechamento dos agregados | Concordante | Por ano, meses, conjunto, cada marginal, cada domínio original, notificações por ano/UF e cada exame laboratorial somam o total anual. Nenhum desvio. |
| Qualidade anual | Concordante | Em todas as 330 linhas, conhecidos + ausentes/ignorados/não interpretáveis = total. |

## Série e residual etiológico

| Ano de sintomas | Total confirmado | Registros com código etiológico não canônico |
|---|---:|---:|
| 2014 | 361 | 1 (`7.`) |
| 2015 | 292 | 1 (`7.`) |
| 2016 | 241 | 1 (`7%`) |
| 2017 | 198 | 2 (`7`, `X`) |
| 2018 | 141 | 0 |
| 2019 | 181 | 0 |
| 2020 | 40 | 0 |
| 2021 | 51 | 0 |
| 2022 | 142 | 1 (`%7`) |
| 2023 | 167 | 0 |
| 2024 | 162 | 0 |
| **Total** | **1.976** | **6** |

O domínio textual utilizado é `01`–`10`. A aparência do código `7` não autoriza convertê-lo em `07` nesta auditoria. Os seis registros explicam a diferença entre a soma das categorias etiológicas exportadas no snapshot e o total geral, sem diferença nos totais gerais. Não inferir agente etiológico desses códigos.

As contagens por arquivo de notificação não são os totais por ano de sintomas: MENIBR25 contribui com cinco registros de sintomas anteriores, dentro da janela; MENIBR26 contribui com zero. As partições foram mantidas para captar notificações posteriores.

## Chaves e contagens examinadas

| CSV | Linhas | Chave de agregação verificada |
|---|---:|---|
| auditoria_datas_confirmados_todos | 35 | arquivo, ano_sintomas, sintomas_sem_data, notificacao_sem_data, notificacao_antes_sintomas |
| base_conjunta_agregada | 934 | ano_sintomas, sexo, faixa_etaria, etiologia, evolucao |
| comparacao_tabnet_snapshot20261005 | 578 | ano, consulta, categoria |
| dominios_anuais | 3.499 | ano, campo, codigo_original |
| duplicatas_tecnicas | 1 | Tabela de resumo única; não é uma chave individual. |
| esquema_campos | 1.703 | arquivo, campo |
| etiologia_codigos_fora_dominio_1_10 | 6 | ano_sintomas, etiologia_codigo, arquivo_origem |
| fluxos_selecao | 13 | arquivo |
| marginais_anuais | 382 | ano, dimensao, categoria |
| notificacoes_tardias_uf | 26 | ano_sintomas, ano_notificacao, uf_notificacao_codigo |
| qualidade_anual | 330 | ano, campo, universo |
| serie_anual | 11 | ano |
| serie_mensal | 131 | ano_sintomas, mes_sintomas |
| sorogrupo_entre_doenca_meningococica | 43 | ano_sintomas, etiologia, CLA_SOROGR |
| tecnica_etiologia_laboratorio | 1.238 | ano, etiologia, criterio_codigo, codigo_resultado, exame |

Zero chaves repetidas não demonstra que exista uma linha para cada combinação possível. A série mensal tem 131 linhas observadas, não uma grade completa de 132 meses; a ausência de combinação em agregado local integralmente lido deve ser documentada ao construir grades para análise.

## Limites e pontos para replicação

1. O manifesto bruto conserva o status de etapa `13_particoes_disponiveis_leitura_e_validacao_pendentes` e erro de rede histórico. O resultado posterior do processamento e a releitura desta auditoria demonstram disponibilidade e leitura; aquele status não representa a situação final. Nenhum dos dois documentos foi alterado.
2. O snapshot TabNet é de 05/10/2026. MENIBR14–23 têm data de fonte de 09/10; MENIBR24–26 foram reaproveitados da coleta de 05/10 com hashes conferidos. A concordância cobre os recortes comparados entre essas versões, sem afirmar que todas as fontes tenham a mesma atualização.
3. Fontes 2014–2022 estão identificadas como finais; 2023–2026, como preliminares no registro de origem. Não congelar a interpretação de dados preliminares como definitiva.
4. `n_celulas_comparadas=578` no JSON inclui as seis linhas sem equivalente TabNet. Para comunicar a concordância, usar **572 células comparáveis**, mais seis extras documentadas. Valores ausentes dessas seis linhas não são diferenças iguais a zero.
5. O processador preenche `n_br` ausente com zero quando há categoria no TabNet sem registro na coorte integralmente lida. Essa regra difere da ausência de `n_tabnet`, que permanece ausente. A replicação deve preservar a distinção e justificar qualquer grade de zeros.
6. A equivalência de rótulo `PCR` → `PCR - viral` é aplicada somente na comparação. Isso não valida agente viral, bactéria, indicação de vacina ou interpretação clínica.
7. A idade usa a unidade codificada em NU_IDADE_N e limites de faixas; esta auditoria examinou a regra e os fechamentos, mas não recalculou individualmente todas as idades nem validou os denominadores ou as taxas/intervalos. Esses controles não foram atribuídos a esta frente.
8. Zero duplicatas técnicas refere-se à coorte selecionada e à igualdade exata de todos os campos originais. Não significa zero duplicatas epidemiológicas, zero repetição de notificação com campos distintos ou 1.976 pessoas únicas. Não se auditou duplicação em todo o universo nacional ou nos 279 confirmados fora da janela.
9. MNE e MCC permanecem categorias próprias; não houve revisão clínica dos códigos ou validação de sorogrupo, técnica laboratorial ou situação vacinal. Completude entre confirmados selecionados não descreve completude de toda a base nacional.

## Arquivos de referência

Todos os caminhos abaixo são relativos a `C:\Pesquisa\Boletim epidemiolóico\Meningite`:

- `dados/brutos/sinan_br_20261009/manifesto.json` (inclui referências aos três DBC reutilizados em `sinan_br_piloto`).
- `dados/tratados/sinan_br_20261009/` (15 CSV e um RDS).
- `metadados/sinan_br_20261009/RESULTADO_PROCESSAMENTO.json`.
- `dados/tratados/sinan/meningite_sinan_longo.csv` — SHA-256 `44f7f2e017199c2b01b141f17d47c970a35f4495004b0833d07c6d6041f54c17`.
- `scripts/processar_sinan_br_historico.R` — SHA-256 `8102fe8596013e19365ea754d89909c873ff95bb6414f6d37dfcb109ed50eec5`.
- `dados/tratados/sinan_br_20261009/meningites_salvador_sinan.rds` — SHA-256 `1f3ed66d13b3c5c7474879a78447389bad3df9f029556ced5cf74d205ed785d6`.

## Reconciliação final após nova execução

O mestre confirmou que alterou o processador para normalizar as barras dos caminhos, derivar a data de corte da versão e separar os contadores de linhas e células comparáveis. As observações anteriores sobre divergência do script e contador JSON registram o estado anterior e estão superadas pela verificação abaixo; foram preservadas como histórico.

O novo `RESULTADO_PROCESSAMENTO.json` registra geração em **09/10/2026 às 21:27:19 UTC (18:27:19 em Salvador)**. Após essa execução, foram novamente recalculados, diretamente dos arquivos:

| Controle final | Resultado | Evidência |
|---|---|---|
| Hash do processador atual versus JSON | Concordante | Ambos `6353322886b18df9e3ce37aadd089fe3b08a716d0dbf6b2711537564a828f387`. |
| Hash do RDS versus JSON | Concordante | Ambos `1f3ed66d13b3c5c7474879a78447389bad3df9f029556ced5cf74d205ed785d6`; 111.460 bytes declarados. O hash permaneceu igual ao pacote auditado por releitura dos DBC. |
| Contagem de comparações no novo JSON | Concordante | `n_linhas_comparacao=578` e `n_celulas_comparadas=572`, compatíveis com as seis linhas extras verificadas anteriormente. |

Não foi repetida a leitura DBC, conforme orientação do mestre: o RDS da nova execução é idêntico em SHA-256 ao pacote previamente auditado. A reconciliação final cobre o script, o RDS e os contadores declarados; não afirma uma segunda auditoria integral de todos os CSV após a nova execução.

Conclusão restrita final: a seleção, os produtos auditados e o RDS preservado são mecanicamente concordantes com o snapshot comparado. A identidade do script atual com o novo registro de processamento foi reconciliada. Os demais limites metodológicos acima permanecem necessários para qualquer análise epidemiológica posterior.
