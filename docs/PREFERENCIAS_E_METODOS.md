# Preferências do pesquisador e métodos de trabalho

Atualizado em 09/10/2026. Preferências expressas pelo usuário são separadas das decisões tomadas para executar a pesquisa.

## Preferências expressas

- Manter o Git crescendo durante coleta, processamento e análise, incorporando métodos, preferências, o que funciona e dificuldades.
- Produzir um manual detalhado para outra IA ou um amigo conseguir reproduzir e continuar o trabalho.
- Trabalhar em português, com arquivos reais e organização compreensível.
- Reunir dados na pasta do tema, com pacote compacto para R e poucos CSV essenciais. Não precisa caber tudo em um único arquivo; evitar arquivos soltos desnecessários.
- Preservar dados brutos e distinguir o que está pronto, parcial e pendente.
- Usar R/RStudio para análise, com scripts reutilizáveis.
- Preferir taxas anuais, sexo, idade, cobertura vacinal e internações com interpretação clara.
- Reavaliar qualidade antes de investir em muitas análises quando os dados parecerem estranhos.
- Dividir frentes quando autorizado e coordenar sem duplicar downloads ou alterações.
- Executar as etapas autorizadas e avançar nas pendências; não encerrar apenas com promessa de plano.

## O que o pesquisador não quer

- Dezenas de arquivos com recortes isolados que poderiam estar numa tabela longa.
- Gráficos com muita informação de ruído, sem uma pergunta clara.
- Resultados estranhos ou pouco utilizáveis apresentados sem reavaliação da qualidade. O pedido anterior de script grande não é proibição de scripts extensos; a escolha atual da equipe é validar antes de modelar.
- Dados misturados por unidade, território ou tempo e apresentados como se fossem a mesma população.
- Um manual que descreva só o resultado final e omita como fazer, problemas e próximos passos.

## Decisões operacionais desta equipe

Estas escolhas podem mudar com evidência; não são preferências atribuídas ao usuário:

- Janela 2014–2024, com partições de notificação até 2026 para captar atrasos.
- Preservar snapshots datados e uma versão por partição.
- SINAN e população são núcleo; SIH, SIM e PNI são complementos separados.
- Coleta SINAN por HTTPS em lotes de até três, teto 80 MB e duas tentativas por requisição.
- Orçamento SIH/SIM: onze consultas exitosas, 24 tentativas POST incluindo falhas; PNI: oito consultas exitosas, 16 tentativas POST, 20 MB. Operações públicas JSON-RPC têm contagem separada.
- Meningococcemia isolada fica identificada; MNE permanece nas análises de qualidade.
- Evolução e raridade de eventos condicionam análises de letalidade.
- Nenhum modelo causal ou busca sistemática de p-valores integra a coleta.

## Aprendizados confirmados

| Situação | O que funcionou ou precisa mudar |
|---|---|
| Catálogo/downloadSINAN | Consultar nomes reais e gerarZIP pelo serviçoHTTPS oficial permitiu obter10partições pendentes; pilotoconferido foi reaproveitado |
| DNS11001 emambiente restrito | Nova execução autorizada fora dosandbox funcionou paraSINAN; alguns portais podem continuar comfalhas e precisam de pendência explícita |
| PacotesR instalados | R pode rodar sob usuário/bibliotecadiferentes; conferir `.libPaths()` e `R_LIBS_USER` antes de instalarqualquercoisa |
| Comandos PowerShell/R | Aspas simples preservam `$`, mas aspas internas de R inline se perderam no Windows PowerShell 5.1. Usar arquivo `.R`; leitura do pacote atual testada com sucesso nesse shell |
| Caminhos do manual | Corrigido nome do coletor e localização dosDBC: ficam emdados/brutos, não emtratados |
| PNImétodos2026 | NT84/2026 estende cálculo individual a2023; NT69/2026 combina pneumocócicas conjugadas noindicador atual. Conferirimplementação porfonte |
| Fonte primária e complementos | Dados assistenciais não devem corrigir automaticamente casos/óbitos do SINAN |
| Etiologia SINAN | Seis códigos não canônicos explicam o residual; recodificar numericamente pode fabricar agente válido. Preservar domínio/categoria própria |
| Subtotais SIH | O retorno trouxe capítulos/grupos e folhas; somar somente folhas CID e conferir TOTAL, evitando dupla contagem |
| PNI e rupturas | Conjugadas atuais não equivalem a produtos exclusivos; BCG baixo exige auditoria e não prova ausência de vacinação |
| Auditorias paralelas | Chats com escopo de leitura e arquivo exclusivo conferiram dados sem editar bases/Git; mudanças posteriores exigem reconciliação de hash |

Para decisões novas, registrar data, evidência e impacto no próximo comando. Erro de transporte não determina ausência de casos; revisão de método não é resultado epidemiológico.
