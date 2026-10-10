# Histórico do manual

## 2026-10-10 — plano de aprofundamento, sem nova execução

- Inspecionados relatório/documentação/dicionários e nomes dos campos/tabelas do RDS aceito, para distinguir dados disponíveis de campos ainda sem auditoria específica. Nenhum novo cruzamento, modelo, gráfico ou consulta foi executado.
- Propostos seis eixos prioritários: períodos/padronização etária, sexo dentro da idade, etiologia por idade e taxas por grupo, critérios/completude, evolução com cenários de desconhecidos e intervalo sintomas–notificação.
- Especificados gráficos de pontos conectados, razões de taxas com IC, mapas de calor, pequenos painéis, faixas de cenários e curvas acumuladas; figuras condicionais de sazonalidade e SIH. Evitar repetir totais apenas mudando a aparência.
- Delimitados modelos de contagens com exposição e diagnóstico; sensibilidade, dispersão, dependência temporal, multiplicidade e raridade. Cenários de desconhecidos não são IC; taxa padronizada não é taxa bruta.
- Campos sociais/clínicos e sorogrupo dependem de universos condicionais/domínios; ATE_HOSPIT é indicador e ATE_INTERN data. Sem denominadores raciais anuais, cobertura SIM nacional ou série PNI harmonizada, respectivas perguntas ficam limitadas.
- Proposta divisão futura dos dois chats, sem despacho, e saída compacta separada que preserva a entrega atual. Consultadas referências primárias R/NCI de métodos; documentação atualizada e plano espelhado com hash próprio, fora dos manifestos históricos.

## 2026-10-10 — execução autorizada e base analítica entregue

- Após “Agora inicie o plano”, coordenados os dois chats existentes em áreas exclusivas. SINAN/população e complementos entregaram candidatos; o mestre integrou e revisou os produtos finais.
- Entrada central em `Meningite/analise`: RDS local, sete CSVs longos essenciais, configuração, dicionário, fontes/cobertura, decisões, D01–D10, relatório descritivo e seis figuras PNG/PDF.
- 1.976 registros preservados; 242 estratos compatíveis, um sexo ignorado sem taxa fabricada; 132 meses, com zero de agosto/2020 derivado da coorte. Taxas anuais e do período com denominadores compatíveis e IC95 exato Poisson.
- Retomada seletiva: 9 POST SIH, 2 POST PNI, 2 GET. Dias e A39 sexo concluídos; internações gerais, G00 sexo e A39 idade seguem pendentes. PNI interrompido após duas falhas BCG; conserva 17 observações e 27 lacunas.
- 352 controles da preparação aprovados. Revisões independentes: 39 verificações SINAN/população (incluindo 409 IC e 715 proporções) e 17 dos complementos. Texto hospitalar corrigido para 75 óbitos parciais de cinco folhas, sem G01; não há total integral demonstrado. Ajustadas escalas/legendas F02 e F05 e trajetória temporal 2022–2024.
- Seis PNG inspecionados e seis PDF renderizados com Poppler/inspecionados; hashes atuais registrados em QA_VISUAL. RDS aceito mantido após correções apenas de apresentação; código, relatório e hashes reconciliados no selo final.
- Resolvida biblioteca R via R_LIBS_USER, sem instalação; SHA binário base R contornou falha de digest nativo em caminhos Unicode. Conferência Python usa absolute() para evitar consulta de ancestrais protegidos no sandbox Windows.
- Atualizados estado, métodos, continuidade e comandos. Novo espelho público com lista explícita e manifesto próprio; 45 arquivos históricos de 09/10 e fontes preservados. Sem brutos, RDS ou casos individuais no Git. Commit local, sem publicação remota.

## 2026-10-10 — plano de preparação analítica, sem execução

- Concluído plano detalhado para centralizar a entrada em `Meningite/analise`, com pacote RDS, sete CSVs longos, configuração, dicionário, fontes, cobertura e controles.
- Recebidas propostas de planejamento dos chats “Revisar contexto do projeto (2)” (SINAN/população) e “Revisar contexto do projeto” (SIH/SIM/PNI); áreas futuras de escrita exclusivas e integração/Git reservadas ao mestre.
- Especificados seleção, domínios, identidade técnica, preservação de desconhecidos, população, cardinalidade das junções, grade de 132 meses e estados de ausência sem preenchimento global por zero.
- Planejados dez conjuntos descritivos, quatro figuras iniciais e complementos condicionais; unidades, universos, qualidade e limites acompanharão os resultados.
- Registrados requisitos para eventual retomada seletiva: cinco consultas SIH; 27 chaves PNI em três consultas. A opção atual `--priorizar-restantes` apenas reordena e precisa seleção exclusiva antes de uso futuro.
- Atualizados README, estado, preferências, prompt e AGENTS para distinguir planejamento de execução. Plano copiado ao Git como documento adicional; manifesto e 45 espelhamentos históricos de 09/10 preservados.
- Nenhuma coleta, limpeza, implementação, análise ou figura foi executada; `analise/` não foi criada. A próxima etapa aguarda novo comando do pesquisador.

## 2026-10-09 — coleta nacional, complementos e reprodução

- Elaborado plano integral com contratos, períodos, território, fontes, orçamento de consultas, aceite, qualidade e desenho posterior.
- Coletadas dez partições MENIBR14–23; reutilizadas três do piloto; lidas 295.369 linhas e obtida coorte de 1.976 registros.
- Concordância em onze totais anuais e 572 células TabNet; seis extras mantidas sem referência; residual etiológico localizado em códigos não canônicos.
- Adicionados cruzamentos reais e auditorias de campos/duplicatas/UFs/atrasos, preservando MNE/MCC e incompletude da evolução.
- SIH/SIM: seis consultas válidas, 77 conservações; cinco consultas pendentes após 24 POST. Excluídos subtotais-pai de somas de folhas CID; originais intactos.
- PNI: 17 observações, 27 lacunas; documentos NT84/2026 e NT69/2026; métodos legado/RNDS separados e BCG com ressalva de qualidade.
- Coordenados dois chats para auditorias independentes de SINAN e denominadores/portabilidade; bases e Git sob integração do mestre.
- Corrigidos comando R para PowerShell 5.1, normalização de caminhos, retomada por origem/modalidade, status HTTP futuro, data de auditoria e contador de células comparáveis. Processamento repetido para alinhar código e hashes.
- Criado pacote RDS por fonte, com releitura idêntica e manifesto; preservada pré-análise anterior.
- Atualizados métodos, preferências, estado, prompt e AGENTS; enviado código e agregados por lista explícita com hashes. Brutos e RDS ficam fora do Git.
- Verificados 45 arquivos espelhados, oito JSON, seis scripts Python e links de dezenove documentos Markdown. Pipeline preserva finais de linha no Git para conservar SHA entre sistemas. RDS principal abriu no Windows PowerShell 5.1.

## 2026-10-05 — criação

- Criado o Git `Boletim epidemiológico` como manual independente para continuidade da análise de meningites.
- Registrado o fluxo de inventário → piloto → coleta → validação → diagnóstico → foco → análise.
- Documentados parâmetros de Salvador, código 292740, população e referências oficiais.
- Documentados resultados do SINAN/TabNet, piloto nacional, SIH e SIM já executados.
- Registradas diferenças entre casos, internações/AIHs e óbitos.
- Registrados limites de evolução, etiologia, MCC, MNE, PCR e versões preliminares.
- Adicionado prompt de continuidade para outra IA.
- Mantidos os dados brutos e o pacote R no diretório original `Meningite`; nenhum dado bruto foi duplicado no manual.

## Próxima entrada esperada

Registrar a pergunta analítica escolhida e eventuais novos recortes/modelos, com cobertura, pressupostos e sensibilidade. Coleta adicional deve ser seletiva e justificar o ganho; manter versões anteriores e resultados descritivos.
