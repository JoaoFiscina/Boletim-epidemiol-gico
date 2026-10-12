# Atlas dos arquivos do projeto executado

Este atlas aponta para a pasta real `C:\Pesquisa\Boletim epidemiolóico\Meningite`.

## Documento atual dos gráficos — 12/10/2026

| Caminho na pasta Meningite | Uso |
| --- | --- |
| `analise/guia_graficos/GUIA_GRAFICOS_MENINGITES.pdf` | 35 páginas, todos os 14 gráficos incorporados e explicações; pode ser enviado sozinho |
| `analise/guia_graficos/GUIA_GRAFICOS_MENINGITES.md` | Texto editável, fontes, métodos, interpretação e legendas |
| `analise/guia_graficos/figuras_revisadas/` | Quatro PNGs básicos revisados, mantendo os dados aceitos |
| `analise/guia_graficos/README.md` | Entrada, reprodução, escopo e cuidados |
| `analise/guia_graficos/scripts/` | Revisão R, compilação PDF e verificação própria |
| `analise/guia_graficos/controle/` | Build, QA e manifesto; renders de 35 páginas ficam somente locais |

Espelho público: [pipeline/Meningite/analise/guia_graficos](../pipeline/Meningite/analise/guia_graficos/README.md). As figuras básicas originais e aprofundadas continuam nas pastas anteriores. Não sobrescrever essas entregas para trocar a apresentação.

## Entrada e configuração

| Caminho | Uso |
|---|---|
| `config/projeto.json` | pergunta, território, período e cortes operacionais |
| `PLANO_COLETA.md` | plano por fases e portões de decisão |
| `metadados/DICIONARIO_E_DEFINICOES.md` | definições, códigos e unidades |
| `metadados/RESULTADO_PRE_ANALISE.json` | resumo, hashes e estados do SINAN |
| `metadados/RESULTADO_PILOTO_BR.json` | resumo, hashes e limites do piloto nacional |
| `metadados/DENOMINADORES.json` | origem, regra e hash da população |

## SINAN Bahia

Brutos: `dados/brutos/sinan`. As respostas principais são `total_sem_coluna.html`, `sexo.html`, `idade.html`, `evolucao.html`, `criterio.html`, `mes_sintomas.html` e `etiologia_20261005T185635.html`. Os arquivos `.contrato.json`, `.post.txt` e `.resumo.json` documentam parâmetros, resposta e conferências.

Tratados: `dados/tratados/sinan/meningite_sinan_longo.csv`, `qualidade_anual_sinan.csv`, `concordancia_consultas_anuais.csv` e `meningite_sinan_cruzamentos_idade_etiologia.csv`.

## SINAN nacional

Brutos: `dados/brutos/sinan_br_piloto`, com ZIP, DBC e manifesto. Tratados: `dados/tratados/sinan_br_piloto`, com comparação TabNet, completude, fluxos, domínios, agregados conjuntos e auditoria de duplicatas. Não há exportação de linhas individuais no pacote analítico.

O próximo lote deve acrescentar `MENIBR14–23`, sem substituir `MENIBR24–26`.

## Denominadores

`dados/denominadores/populacao_total.csv` é a série usada nas taxas. `populacao_sexo_idade_original.csv` conserva as faixas originais. `populacao_faixas_sinan.csv` deriva as faixas compatíveis com o SINAN. Não alterar sem gerar nova versão do manifesto.

## SIH e SIM

Brutos: `dados/brutos/complementos`. Tratados: `dados/tratados/complementos`.

- SIH: `sih_anual_grupos.csv`, `sih_perfis_periodo.csv`, `sih_resumo_grupos.csv` e conferências.
- SIM: `sim_anual_causas.csv`, `sim_categoria_ano_tabela.csv`, `sim_sexo_ano_tabela.csv`, perfis e conferências.

## Resultados

`resultados/tabelas` possui CSVs para leitura; `resultados/figuras` contém três PNGs: série/taxas, composição etiológica e preenchimento. `pre_analise_meningite.rds` agrupa objetos R sem misturar suas unidades.

## Referências

`referencias` preserva PDFs/textos e manifests de ficha, dicionários, caderno de análise, nota técnica 154/2024, catálogo de arquivos e boletim SESAB. Ler documentos oficiais junto com o estado da coleta; o documento de referência não prova que todos os campos atuais estejam completos.
