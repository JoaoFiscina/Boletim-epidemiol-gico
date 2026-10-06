# Estado atual e resultados auditados

Data de referência: 05/10/2026. O detalhe completo está em `C:\Pesquisa\Boletim epidemiolóico\Meningite\RELATORIO_PRE_ANALISE.md`.

## Resultado principal

O tema continua viável para uma análise descritiva robusta de casos registrados, taxas, perfil demográfico, sazonalidade e qualidade diagnóstica. Ainda não é adequado prometer uma análise completa de letalidade, efetividade vacinal ou agentes etiológicos específicos.

## Tabela-resumo do SINAN

| Ano | Casos | Taxa registrada por 100 mil |
|---:|---:|---:|
| 2014 | 361 | 13,34 |
| 2015 | 292 | 10,84 |
| 2016 | 241 | 8,99 |
| 2017 | 198 | 7,42 |
| 2018 | 141 | 5,30 |
| 2019 | 181 | 6,84 |
| 2020 | 40 | 1,52 |
| 2021 | 51 | 1,94 |
| 2022 | 142 | 5,45 |
| 2023 | 167 | 6,45 |
| 2024 | 162 | 6,31 |

Taxa = casos confirmados registrados no banco / população residente de Salvador × 100.000. Não é incidência corrigida por subnotificação.

## Qualidade dos campos

| Campo | Faixa de preenchimento no período | Leitura |
|---|---:|---|
| Sexo | 99,4–100% | adequado para perfil e taxas específicas |
| Idade | 100% nas categorias retornadas | adequado, com agrupamento de categorias pequenas |
| Mês dos sintomas | 100% | sazonalidade promissora |
| Critério | 99,7–100% | permite descrever critérios, não prova laboratório |
| Evolução | 80,2–97,8% | limita letalidade, sobretudo 2023–2024 |
| Etiologia específica | 62,5–87,5% como categoria diferente de MNE/ignorado | baixa especificidade, não ausência de preenchimento simples |

## Confirmado no piloto nacional

Foram lidos os arquivos nacionais `MENIBR24`, `MENIBR25` e `MENIBR26`, com 131 campos cada. O filtro de residência `292740`, classificação confirmada e sintomas em 2024 retornou 162 casos. Todas as células comparadas com TabNet fecharam sem divergência. Houve um caso notificado fora da Bahia. Isso valida a rota e o filtro para 2024, mas não prova a série histórica completa.

## Pontos que exigem cautela

1. Total geral = 1.976; etiologia = 1.970. Diferença histórica de seis sem causa demonstrada.
2. O banco inclui MCC isolada. Não chamar automaticamente todos os 1.976 de meningite com acometimento meníngeo.
3. `MV`/“viral” é rótulo de categoria; não equivale a isolamento viral em todos os registros.
4. `PCR - viral` do TabNet não deve ser usado como confirmação viral sem harmonizar o código DBF.
5. SIH é internação/AIH; SIM é causa básica de óbito. Não são pessoas correspondentes ao SINAN.
6. Ausência de linha no SIM não foi convertida em zero.

## Classificação de viabilidade

| Módulo | Classificação | Condição |
|---|---|---|
| Série geral 2014–2024 | seguir | completar confronto nacional e documentar a diferença de seis |
| Sexo e idade | seguir | usar denominadores compatíveis e agrupar células pequenas |
| Mês/sazonalidade | seguir com validação | confirmar série nacional e referência do mês |
| Etiologia ampla | seguir com ressalvas | preservar MNE e categorias originais |
| Subtipos raros | ajustar | agrupar períodos ou usar somente descrição |
| Letalidade | secundária | melhorar completude da evolução e fazer sensibilidade |
| Vacinação | pendente | coletar PNI por imunobiológico e população-alvo |
| Modelos complexos | ainda não | fechar base conjunta, eventos e dados faltantes |
