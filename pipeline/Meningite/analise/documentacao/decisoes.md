# Decisões da preparação analítica — 10/10/2026

O comando humano “Agora inicie o plano” autorizou a implementação do plano de preparação, antes encerrado apenas como documento. O mestre delegou SINAN/população ao chat “Revisar contexto do projeto (2)” e SIH/SIM/PNI ao chat “Revisar contexto do projeto”. Cada frente escreveu candidatos e revisões em área exclusiva; produtos finais e Git ficaram sob o mestre. Preferências expressas e decisões operacionais continuam separadas no manual.

## Núcleo e rastreabilidade

Entrada congelada: `dados/tratados/meningites_salvador_20261009.rds`, SHA-256 `9fec05cb6c73b51d6cf30669d186d740fbf0f4b200121e2ad30f713713571dd5`. Os campos originais dos 1.976 registros foram conservados e comparados integralmente. Partições MENIBR14–26, residência `ID_MN_RESI=292740`, confirmação `CLASSI_FIN=1`, sintomas 2014–2024. Coorte: 295.369 linhas nacionais → 3.871 residentes → 2.255 confirmados → 1.976 na janela; 279 confirmados fora da janela. Não foram deduplicadas pessoas por coincidência de atributos.

Mantidos MCC isolada, MNE, seis códigos etiológicos não canônicos, dois vazios, 144 evoluções desconhecidas e notificações fora BA de residentes. Zero duplicatas técnicas exatas não comprova pessoas únicas. A comparação contém 572 células com referência TabNet e seis extras sem referência; não são 578 células comparadas.

População: 396 chaves originais, 242 estratos harmonizados e onze totais anuais. Somar apenas faixas/sexos disjuntos. O registro de sexo ignorado fica no RDS e nos totais/idade, sem taxa específica por sexo. A grade mensal tem 132 células; agosto/2020 é zero derivado da leitura integral da coorte, não de falha de exportação.

CSV longo por fonte, sete bases essenciais. Códigos originais permanecem como texto; estados separam valor observado, zero derivado, linha não retornada e coleta pendente. Bases candidatas não substituem a entrada central. O manifesto final identifica a versão aceita e os hashes de código, dados e apresentação.

## Estatística descritiva

Taxas anuais: registros/população do mesmo ano × 100.000. Taxas específicas do período: registros/soma das populações anuais compatíveis × 100.000. Esta soma aproxima exposição em habitantes-ano; não é número de pessoas diferentes. IC95 de Poisson calculado por limites exatos de contagem, conferidos independentemente contra `stats::poisson.test` em 409 linhas, com diferença máxima zero.

Percentuais têm denominador explícito. Evolução desconhecida fica na distribuição e na sensibilidade, sem letalidade final. Etiologia é categoria registrada; MV e “PCR - viral” não demonstram isolamento de agente. Os sete grupos do gráfico são disjuntos e incluem residual; categorias originais continuam disponíveis.

D01–D10 acompanham o relatório e o CSV longo: seleção/qualidade, série anual, sexo/idade, mensal, etiologia/critério, evolução/atrasos, SIH, SIM, PNI e disponibilidade. Não foram executados modelos causais, ajuste multivariável ou busca sistemática de p-valores. Primeiro escolher a pergunta e avaliar completude/volume de eventos.

## Complementos e retomada efetiva

SIH: seleção exclusiva das cinco pendências da rodada anterior. Foram 9 POST SIH e 2 GET de formulários, com até duas tentativas por consulta e limite registrado. Dias de permanência e A39 por sexo tiveram retorno válido. Internações gerais, G00 sexo e A39 idade continuam pendentes. Formulários do cache real de 09/10 foram utilizados após falha dos GET, com essa origem registrada. O histórico anterior de 24 POST não foi sobrescrito.

Internações/AIHs usam residência e ano de processamento; totais e perfis não são somados. G00=532, A39=122, A87=489 são grupos separados. A39 inclui outras apresentações meningocócicas. Dias=12.250 e valores aprovados nominais=R$ 2.354.667,12 têm seis folhas CID observadas; óbitos=75 são soma parcial de cinco folhas. G01 não retornou linha de óbitos nos onze anos; falta de linha permanece `NA`. Não calcular total integral, permanência média ou custo por paciente com universos incompatíveis.

SIM: 202 óbitos por causa básica selecionada, residência Salvador, arquivo de registro BA. Cobertura nacional não demonstrada. Não dividir SIM por SINAN como letalidade; dados de ocorrência/registro não corrigem automaticamente o núcleo.

PNI: 2 POST BCG sem sucesso; circuito interrompeu antes de MenC/pneumocócica. Permanecem 17/44 percentuais e 27 lacunas. RNDS mantém numeradores/denominadores oficiais; Penta legado mantém percentuais sem fabricar componentes ausentes. Métodos, geografia, público, esquema e nota técnica separados. Nenhuma linha une os métodos nas figuras. BCG é sinal de qualidade a investigar, não evidência de falta de vacinação. SIA não foi incluído sem recorte útil demonstrado.

## Execução, revisões e correções

Configuração efetivamente lida pelo controlador R, preparação offline, hash de entrada bloqueante, escrita em estágio, releitura RDS idêntica e verificação de CSV/tipos antes de promoção. Bibliotecas já instaladas foram usadas. No Windows com caminho acentuado, `digest(file=...)` falhou no código nativo; leitura binária base R seguida de SHA-256 conservou o hash correto. Comandos em arquivos `.R` evitaram perda de aspas no PowerShell 5.1.

352 controles da preparação aprovados. As revisões independentes fizeram 39 verificações SINAN/população e 17 dos complementos. Encontraram soma textual hospitalar `NA`; o mestre corrigiu para 75 óbitos parciais com cobertura de cinco folhas e G01 ausente. Texto temporal passou a distinguir recuperação em 2022–2023 da redução de 167 para 162 em 2024.

F02 recebeu escalas próprias por painel, com aviso e rótulos para tornar ICs por sexo legíveis. F05 explicita escalas próprias por CID. As versões afetadas foram reinspecionadas pelas frentes. O mestre inspecionou os seis PNGs e renderizou/inspecionou os seis PDFs com Poppler. Aceite visual, arquivos e hashes estão em `controle/QA_VISUAL.json`. Isso valida apresentação/integridade, não causalidade, validade clínica ou eficácia vacinal.

O RDS aprovado não foi recalculado após ajustes apenas de texto/figura. Reportagem, código e hashes foram reconciliados no fechamento. O manifesto de portabilidade de 09/10 e os 45 arquivos históricos permanecem preservados; a entrega analítica tem manifesto separado. O Git recebe código, agregados, documentação e figuras, sem dados individuais, brutos ou RDS. Registro local; publicação remota depende de instrução humana própria.
