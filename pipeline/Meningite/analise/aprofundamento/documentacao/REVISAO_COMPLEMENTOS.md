# Revisão independente C1/B2/B3 — 12/10/2026

Aceite no escopo revisado, com limites documentados e duas sugestões editoriais menores. Foram lidos o pacote integrado, o relatório e os scripts de integração/figuras; inspecionados G08 PNG e a página 8 do PDF renderizada com Poppler. Nenhum final, código, candidato ou Git foi alterado. A imagem intermediária de inspeção está nesta área exclusiva.

## Controles independentes

19 verificações, todas aprovadas:

1. Hash da entrada aceita preservado nos metadados.
2. 308 perfis SIH.
3. 264 observações etárias SIH (2 CID × 12 faixas × 11 anos).
4. Unicidade de CID/ano/faixa.
5. Agregação da G08 com 24 células (2 CID × 12 faixas).
6–9. G00 soma 532 e A87 489; em cada CID, soma dos denominadores das faixas corresponde à soma das onze populações anuais. Não há duplicação por sexo, total ou outro CID dentro de cada taxa.
10. Escolaridade usa 960 adultos de 25 anos ou mais.
11. Sorogrupos: 47 registrados entre 85 elegíveis, preservando 38 ausentes.
12–13. Código 75 em 807 MV e código 81 em 180 MB.
14–15. Onze valores de óbito G01 ausentes e 33 internações G01/G02/G03 ausentes preservados.
16. Razões/médias administrativas continuam não aprovadas.
17–18. 66 linhas de triangulação e 374 estimativas da frente preservadas no pacote.
19. G08 corresponde à página 8 do caderno PDF.

Esses controles adicionais não substituem a auditoria clínica e não significam ausência de inconsistências de preenchimento. Na primeira tentativa de executar os controles houve erro de sintaxe no comando de leitura (`else489`); foi corrigido para `else 489` no comando, sem qualquer alteração do pacote ou scripts finais. A execução válida subsequente aprovou os 19 controles.

## Parecer científico e visual

C1: raça é perfil entre casos, sem taxa populacional por raça. Escolaridade 10 não se aplica está separada de ignorado, com distribuição restringida a adultos25+. O relatório distingue especificidade etiológica de preenchimento: MV75 não identificado e MB81 bactéria não especificada. Sorogrupo usa somente meningocócicas; 47/85 não mede distribuição verdadeira na população. Hospitalização é indicação entre notificações, ATE_INTERN é data; antecedentes vacinais não estimam eficácia. ANT_IMUNO vazio não significa ausência de imunodepressão. Inconsistências permanecem documentadas.

B2: G08 filtra apenas perfis de idade G00/A87; agrega contagens e populações nos onze anos por CID/faixa e usa razão de totais. Não é média simples das taxas anuais, não mistura perfis sexuais nem adiciona totais. O eixo corresponde a AIHs por 100 mil habitantes-ano, com população anual como aproximação de exposição. PNG e página 8 legíveis, sem cortes de título, eixos, legenda ou notas. As 12 faixas estão em ordem e o rodapé distingue episódios de pessoas únicas, residência e ano de processamento. G00 deve ser interpretado pelo grupo CID, não como todas as meningites bacterianas.

B3: índices 2014=100 são próprios de cada série, com diagnósticos não equivalentes e anos de sintomas/processamento distintos. Não há proporção de casos internados nem vinculação individual. Medidas de dias, BRL nominal e óbitos permanecem separadas; nenhum custo econômico total ou média com denominador incompatível foi produzido. As lacunas G01/G02/G03 estão preservadas.

SIM permanece 202 óbitos de registro BA, sem abrangência nacional demonstrada; nenhuma letalidade SIM/SINAN. PNI permanece 17/44, com 27 ausentes, legado/RNDS separados e sem teste de eficácia. Bahia excluindo Salvador continua requisito/viabilidade, não resultado coletado.

## Sugestões editoriais menores

- A frase “61,3% desconhecida” para escolaridade usa aproximação diferente da tabela (61,2%). A fração exata é 588/960 = 61,25%; unificar a regra de arredondamento ou apresentar a fração. Isso não altera o parecer de perdas elevadas.
- Preferir “seis preenchimentos de CLA_ME_ASS fora da elegibilidade etiológica” a “seis registros de agente viral fora da elegibilidade”, para evitar sugerir isolamento/identificação de vírus onde existem códigos de agente não identificado e residuais etiológicos.

Nenhuma inconsistência numérica material foi encontrada no escopo C1/B2/B3 ou na agregação/visualização G08. Modelos inferenciais de outras frentes e as outras sete páginas PDF não foram objeto desta revisão.

## Hashes da versão efetivamente revisada

| Arquivo relativo a `analise/aprofundamento` | SHA-256 |
|---|---|
| meningites_aprofundamento.rds | ddf2225151a6d638a3b7083f9d5d63cca987d7600fb5d9d6014e1a1dddd711aa |
| resultados/RELATORIO_APROFUNDADO.md | 547ff92daeeadf8760929e37554be8dc98797db980db783fdb74dfffe838d561 |
| resultados/figuras/G08_perfis_hospitalares.png | ad1f414e9a48f8a97b660ad13ae27c6d76143a65408ad8b042133f7cbcea2add |
| resultados/figuras/CADERNO_GRAFICOS_APROFUNDADOS.pdf | 156aa97952e32cbe81dc28a0bf7780b54a3d7355832d4568c278c8335a555405 |

Se o mestre regenerar os produtos, esses hashes continuam como histórico desta revisão, e o QA final deve referenciar os novos bytes.

## Adendo de encerramento — 12/10/2026

As duas sugestões editoriais foram implementadas e conferidas: a prosa informa 61,25% (588/960) para escolaridade, com a tabela mantendo uma casa decimal; o texto agora usa “seis preenchimentos CLA_ME_ASS fora da elegibilidade etiológica”. Ambas aceitas. Não permanecem pendências deste parecer no escopo C1/B2/B3.

Hashes novos conferidos após regeneração pelo mestre:

- Relatório aprofundado: `d61bb6376aaf1d6f5fe131a5214e4ed03e021ba66225dac5b526caeb9bdc9733`.
- Caderno PDF: `286d671e71bdda2de094fa3e7323ded3dab9cb606e3d40b99bbfda8f44d054f0`.
- G08 PNG permanece `ad1f414e9a48f8a97b660ad13ae27c6d76143a65408ad8b042133f7cbcea2add`, idêntico ao inspecionado.

Os hashes anteriores permanecem como histórico. Não foram repetidos cálculos nem reavaliadas as outras figuras; a revisão visual da página 8 refere-se à renderização anterior, conforme sua preservação informada pelo mestre. O QA do PDF regenerado, manifesto e Git ficam sob responsabilidade do mestre. Frente encerrada.
