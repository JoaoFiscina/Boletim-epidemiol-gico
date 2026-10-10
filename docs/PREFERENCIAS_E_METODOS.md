# Preferências do pesquisador e métodos de trabalho

Atualizado em 10/10/2026. Preferências expressas pelo usuário são separadas das decisões tomadas para executar a pesquisa.

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
- Quando pedir explicitamente apenas o plano, concluir e avisar antes de iniciar a execução; aguardar o próximo comando.
- Centralizar a próxima entrada analítica em uma pasta e entregar resultados descritivos junto aos gráficos, com dados limpos, organizados e cobertura explícita.
- Após a entrega de 10/10, pediu planejar análises adicionais e gráficos diferentes, identificando informação além do que já foi descrito. As escolhas específicas de cruzamentos/modelos no plano são propostas da equipe.

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
- Execução de 10/10 autorizada por “Agora inicie o plano”: RDS e sete CSVs essenciais em `Meningite/analise`; SINAN/população como núcleo, complementos com critérios independentes.
- Preparar/validar, descrever e gerar poucas figuras: seis foram entregues, com SIH/PNI sob limites explícitos. Essa quantidade é decisão operacional, não exigência do pesquisador.
- Duas frentes prepararam candidatos em áreas exclusivas; somente o mestre integrou produtos finais e Git. Foram concluídas revisões independentes com 39 e 17 verificações.
- Taxas do período usam soma das populações anuais como aproximação de habitantes-ano; IC95 Poisson não corrige subnotificação. Nenhuma modelagem causal ou busca de p-valores nesta entrega.
- Preparação R offline separada da aquisição. Retomada de 10/10 fez 9 POST SIH e 2 PNI; obteve dias e A39 sexo. Não repetir consultas válidas nem ampliar orçamento sem justificativa.
- Aprofundamento proposto em 10/10: priorizar cruzamentos, padronização etária, qualidade, evolução com cenários e intervalo até notificação; campos clínicos/sociais e modelos só após gates explícitos. Planejamento concluído, não executado.

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
| Planejamento de 10/10 | Os dois chats entregaram propostas em leitura local. Contratos, dependências e critérios de aceite foram registrados antes de implementar |
| Grade mensal | Entrega atual tem 132 meses; agosto/2020 zero derivado da coorte integral. Ausência de exportação externa continua ausente |
| Caminho acentuado no R | Hash nativo digest(file=...) falhou; leitura binária base R seguida de SHA-256 reproduziu o hash congelado |
| Bibliotecas locais | Definir R_LIBS_USER resolveu a descoberta de jsonlite; nenhum pacote precisou ser instalado |
| Texto SIH parcial | Soma textual NA corrigida para 75 em cinco folhas; G01 continua sem valor. Não esconder cobertura com na.rm |
| Figuras e revisão | PNG e PDF exigem inspeção própria; seis PDF renderizados com Poppler e conferidos. Regeneração muda hashes e exige reconciliar QA/manifesto |
| Retomada SIH | `--priorizar-restantes` apenas muda a ordem; uma rodada futura precisa selecionar consultas pendentes explicitamente para não repetir respostas válidas |
| PNI legado | 27 chaves pendentes correspondem a três consultas com nove anos; separar quantidade de observações de quantidade de requisições |
| Controle vazio | Conferência precisa de quantidade esperada de testes; `all(...)` em vetor vazio não demonstra conservação |

Para decisões novas, registrar data, evidência e impacto no próximo comando. Erro de transporte não determina ausência de casos; revisão de método não é resultado epidemiológico.
