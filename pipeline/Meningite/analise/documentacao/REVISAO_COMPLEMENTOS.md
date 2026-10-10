# Revisão independente da integração — complementos

10/10/2026. Somente leitura dos produtos integrados e inspeção visual das imagens F05/F06. Única escrita: este relatório, na área exclusiva da Frente B. Não foram alterados código, candidatos, finais ou Git.

## Resultado

Aceite dos dados e das figuras no escopo revisado, com uma correção editorial necessária no relatório descritivo. Foram executados 17 controles independentes, todos aprovados: quantidade e multiconjunto de valores D07/D08/D09 versus tabelas analíticas, grade D10, totais hospitalares, observações e lacunas de internações, total e abrangência SIM, grade PNI, razões RNDS, ausência dos componentes legados e limites do ledger. A comparação dos valores como multiconjunto é uma conferência global; não substitui as verificações de chaves da integração.

## Achado concreto a corrigir pelo mestre

`analise/resultados/RELATORIO_DESCRITIVO.md`, seção 6, contém: “os dados disponíveis somam NA altas por óbito”. A origem está em `analise/scripts/gerar_descritivos.R`, linha 263: soma sem tratamento explícito da cobertura parcial. Os 66 estratos folha CID × ano têm 55 valores de óbitos observados e 11 ausentes de G01. A soma dos observados é 75; não há total completo demonstrado dos seis grupos.

Redação sugerida: “Nas cinco folhas CID com valores de óbito retornados, registram-se 75 altas por óbito em 2014–2024; G01 permanece sem linha e sem valor. Para as seis folhas selecionadas, os valores aprovados nominais somam R$ 2.354.667,12 e os dias de permanência somam 12.250. Esses indicadores têm universos administrativos próprios; não foram calculadas médias com denominadores incompletos.”

Não corrigir apenas acrescentando `na.rm=TRUE` e mantendo a afirmação de total dos seis grupos. A cobertura precisa continuar no texto. Esta pendência afeta apresentação, sem demonstrar corrupção da base.

## Dados e interpretações conferidos

- D07 tem 572 linhas, preserva total/perfil, medida, unidade e estado. O código descritivo e F05 selecionam totais de internações; não somam perfis às séries nem sexo e idade entre si. A39=122, A87=489 e G00=532; 33 valores anuais observados e 33 ausentes de G01/G02/G03. Nenhuma soma foi descrita como todas as internações por meningite.
- Dias: 66 valores observados, soma 12.250. Valores aprovados: 66 valores observados, soma R$ 2.354.667,12 nominal. Óbitos: 55 valores observados, soma parcial 75; G01 sem linha. Não foram derivados custo econômico total, custo por pessoa ou permanência média com os denominadores disponíveis.
- D08 conserva total e perfil separados: 202 óbitos por causa básica G00–G03/A39/A87; todas as linhas identificam registro BA, residência Salvador e cobertura nacional não demonstrada. Não há razão SIM/SINAN de letalidade.
- D09/PNI conserva 44 chaves, 17 percentuais observados e 27 ausentes. Os oito RNDS têm componentes oficiais e razões conferidas; os nove Penta legados conservam percentuais mesmo sem numerador/denominador. Métodos, geografia, esquemas e público estão explícitos. D10 conserva a grade de disponibilidade da documentação.
- Ledger: nove POST SIH, dois POST PNI e dois GET. Nenhuma consulta ultrapassou duas tentativas. Duas consultas SIH concluídas: dias e A39 sexo. Três consultas SIH permanecem pendentes: internações gerais, G00 sexo e A39 idade. BCG legado falhou duas vezes e interrompeu o PNI antes de MenC/pneumocócica. O histórico anterior de 24 POST não foi apagado.

## Inspeção visual efetivamente realizada

F05 PNG: legível, sem cortes; três séries separadas por CID, eixo de ano de processamento e unidade internações/AIHs. A39 está identificado como infecção meningocócica, com ressalva de outras apresentações. As escalas verticais diferem por painel, portanto comparar magnitude pelos eixos, não pela altura visual. G00 é grupo CID, não conjunto de todas as meningites bacterianas. Ausências das demais séries são declaradas no relatório.

F06 PNG: 17 pontos, sem linhas entre eras; círculos legados e triângulos RNDS, legenda com perspectivas distintas. Não há pontos zero substituindo as 27 ausências. O rodapé explicita conjugadas não exclusivas, ressalva de BCG e proibição de inferir eficácia. A legenda impede interpretar os pontos como uma série harmonizada.

Hashes dos PNGs inspecionados:

- F05: `0e8af27017cc6014a3d7c983eaa121e158a7616d075bae7f69247cb78b6078c6`.
- F06: `6e186b40240d013c56a8c1fa5c0b4dee7353961846430410871ecf5d4ad6da26`.

Os PDFs não foram renderizados nesta revisão; a inspeção visual refere-se aos PNGs acima. Não houve nova execução de processamento, coleta ou geração de figuras. A correção editorial e eventual regeneração são responsabilidade do mestre.

## Adendo — correção conferida em 10/10/2026

Conferida a nova redação da seção 6 do relatório, linha 118: informa 75 altas por óbito nas cinco folhas com retorno, G01 sem linha/sem valor e ausência de total completo demonstrado dos seis grupos. Valores nominais e dias são descritos separadamente para as seis folhas. O achado editorial está resolvido.

O PNG F05 atualizado foi novamente inspecionado: rodapé legível com “Escalas próprias por CID”, mantendo AIHs/episódios, ano de processamento e ressalva de A39. Aceito no escopo visual revisado. Novo SHA-256: `b702fa9f43cc4df1e1c3f47a146e1fb3c1ce81bdc11eac666f0b7b1118106fea`. O hash F05 anterior acima permanece como histórico da primeira revisão; F06 não foi reavaliada neste adendo.

Não foram repetidos testes completos nem alterados produtos finais. Renderização e inspeção dos PDFs e registro QA_VISUAL.json permanecem com o mestre.
