# Coordenação da execução — 10/10/2026

O pesquisador autorizou a execução com a mensagem “Agora inicie o plano”. A restrição anterior de planejamento foi substituída por esse comando. Escopo: preparar as bases, retomar exclusivamente complementos pendentes sob orçamento, integrar, descrever, gerar e inspecionar figuras, documentar e registrar no Git local.

## Propriedade dos arquivos

- Chat “Revisar contexto do projeto (2)”: somente `analise/trabalho/sinan_populacao/`.
- Chat “Revisar contexto do projeto”: somente `analise/trabalho/complementos/`, incluindo originais novos de suas consultas em subpasta própria. Não alterar coletores ou produtos antigos compartilhados.
- Chat mestre: configuração, scripts finais, integração, resultados, controles, documentação e Git.

## Contrato de integração

Cada frente entrega um arquivo R com uma função `preparar_sinan_populacao(raiz, config, destino)` ou `preparar_complementos(raiz, config, destino)`. `raiz` é a pasta Meningite; `config` é a lista lida do JSON central; `destino` é a área exclusiva da frente. Sem código de execução automática ao dar `source()`.

O retorno será uma lista com: `modulos` (SINAN/populacao ou SIH/SIM/PNI), `tabelas` (data.frames nomeados pelos sete CSVs, sem extensão), `dicionario`, `fontes`, `cobertura`, `validacao` e `decisoes`. Documentação poderá usar colunas próprias coerentes; o mestre harmoniza. `validacao` será tabela com `controle`, `observado`, `esperado`, `aprovado`, `bloqueante`, `detalhe`, com ao menos um teste real por domínio usado.

Cada frente grava candidato RDS e relatório breve, testa a própria função e os controles; entrega caminhos e limitações. Nenhum candidato é produto final antes da integração pelo mestre. Arquivos mínimos locais de casos ficam no RDS; somente agregados revisados serão copiados ao Git.

Complementos podem reutilizar caches preservados, mas qualquer aquisição terá data e hash próprios. A reprodução analítica padrão será offline; a coleta é operação separada e explícita, que não roda novamente ao abrir o pacote ou recalcular gráficos.
