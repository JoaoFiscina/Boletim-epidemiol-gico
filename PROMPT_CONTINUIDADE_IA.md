# Prompt para entregar este projeto a outra IA

**Estado mais recente em 12/10:** documento explicativo dos 14 gráficos concluído em `pipeline/Meningite/analise/guia_graficos/README.md`. PDF de 35 páginas com figura, dados/sistemas, cálculo, leitura, interpretação, limites e legenda; fonte Markdown editável. F02/F04/F05/F06 foram revisados somente na apresentação e guardados em pasta própria. 526 controles aprovados e inspeção visual de todas as páginas. Preservadas bases, estimativas e entregas anteriores. Para compartilhar os gráficos com explicação, enviar esse PDF, que incorpora todas as imagens.

**Atualização em 12/10:** o pesquisador autorizou “Inicie o plano de analise aprofundada coordenando os outros dois chats também”. O plano foi executado offline e integrado em `pipeline/Meningite/analise/aprofundamento/README.md`. Ler relatório, dicionário/decisões, proveniência, validação e revisões. Há oito figuras (um caderno PDF), duas tabelas CSV e RDS local apenas com agregados/modelos. Taxa masculina ajustada M/F 1,49 (IC95 1,34–1,65); taxas padronizadas dos períodos 8,66/1,74/6,16 por100mil habitantes-ano; sazonalidade sem suporte firme após HAC. Não repetir a preparação nem baixar novamente as fontes. Dados aceitos e manifestos de 09/10 e 10/10 permanecem preservados. A antiga pausa para planejamento foi revogada por essa autorização.

Você está continuando a investigação de meningites e doença meningocócica em residentes de Salvador. Leia `AGENTS.md`, `docs/ESTADO_COLETA.md`, `docs/PREFERENCIAS_E_METODOS.md`, `pipeline/Meningite/analise/README.md`, relatório descritivo e decisões. **Estado vigente: guia explicativo e revisão visual concluídos em 12/10/2026; aprofundamento e preparação preservados**. A antiga pausa para planejar foi substituída pelas autorizações de execução. A coleta de 09/10 e a pré-análise de 05/10 são snapshots preservados.

## Entrada para trabalhar

O projeto original fica em `C:\Pesquisa\Boletim epidemiolóico\Meningite`. A pasta `analise/` contém RDS local, sete CSVs essenciais, D01–D10, relatório e seis figuras PNG/PDF. Em clone Git, as tabelas públicas estão em `pipeline/Meningite/analise/`; brutos e RDS não são publicados. Outra pessoa pode ler CSVs diretamente; reprodução integral requer transferir/coletar fontes com manifestos. Não prometer mesmos hashes após nova coleta de fonte revisável.

SINAN é o núcleo: residência `292740`, confirmação `CLASSI_FIN=1`, primeiros sintomas 2014–2024, partições MENIBR14–26. Fluxo: 295.369 nacionais → 3.871 residentes → 2.255 confirmados → 1.976 na janela. Totais anuais: 361,292,241,198,141,181,40,51,142,167,162. Há 572 células comparáveis ao TabNet sem diferença e seis extras sem referência. Preservados seis códigos etiológicos não canônicos, dois vazios, MCC isolada, MNE, 144 evoluções desconhecidas e duas notificações fora BA. Zero duplicatas técnicas não comprova pessoas únicas.

População: onze totais, 396 chaves originais e 242 estratos harmonizados. Grade mensal de 132 meses; agosto/2020 zero derivado da coorte integral. Sexo conhecido soma 1.975; registro ignorado permanece no total/idade e no RDS, sem denominador fabricado.

SIH: internações G00=532, A39=122, A87=489, grupos separados; ano de processamento e unidade AIH/episódio. Dias=12.250 e valores aprovados nominais=R$ 2.354.667,12 têm seis folhas observadas. Óbitos=75 é soma parcial de cinco folhas; G01 permanece sem linha nos onze anos. Não calcular total integral ou médias com universos incompletos.

SIM: 202 óbitos por causa básica selecionada, residência Salvador, registro BA; cobertura nacional não demonstrada. PNI: 17/44 percentuais e 27 ausências. Nove Penta legados 2014–2022 e oito valores de quatro indicadores RNDS 2023/2024. Métodos/geografias distintos; NT84/2026 inclui 2023, NT69/2026 combina conjugadas pneumocócicas. Não renomear atuais como MenC/PCV10 exclusivas. BCG baixo exige auditoria, sem inferência de falta de vacinação ou eficácia.

## O que já foi executado e conferido

Dois chats trabalharam em áreas exclusivas: “Revisar contexto do projeto (2)” preparou SINAN/população; “Revisar contexto do projeto” preparou SIH/SIM/PNI. O mestre integrou, descreveu, gerou figuras e atualizou o Git. As tarefas estão encerradas; não reenviar implementação automaticamente.

352 controles aprovados; revisões adicionais de 39 e 17 verificações com escopos distintos. IC de 409 linhas conferidos contra poisson.test, diferença máxima zero. O mestre inspecionou todos os PNG e PDF renderizados; QA e manifestos registram os hashes atuais. Corrigidos texto SIH parcial, descrição da redução de 2024 e escalas F02/F05. RDS permaneceu inalterado após ajustes de apresentação.

Retomada de 10/10: 9 POST SIH, 2 POST PNI e 2 GET; obtidos dias e A39 sexo. Restam internações gerais, G00 sexo e A39 idade. BCG falhou duas vezes e interrompeu PNI antes das outras consultas. Formulários reais preservados foram reaproveitados quando GET falhou. Histórico de 24 POST conservado. Falhas operacionais não viraram zero epidemiológico.

## Como continuar com eficiência

1. Abrir pacote/tabelas e conferir estado/manifestos antes de calcular ou baixar. Usar analise/README.md como guia de importação e comandos.
2. Preparação R padrão é offline; configuração lida e SHA da fonte bloqueante. Abrir RDS requer R; repetir preparação precisa jsonlite/digest/ggplot2 e fontes locais.
3. Utilizar arquivos .R em PowerShell 5.1; verificar R_LIBS_USER/.libPaths antes de instalar. SHA binário base R contorna falha nativa em caminhos Unicode.
4. Selecionar tabelas por grão, tipo, dimensão, medida e status. Não somar marginais/total, dimensões independentes ou fontes.
5. Taxa anual usa população correspondente; taxa média do período usa soma das populações anuais como aproximação de habitantes-ano. IC95 Poisson não inclui subnotificação/incerteza demográfica.
6. Escolher pergunta antes de modelos. Entrega descritiva, sem teste causal, eficácia ou busca de p-valores. Recortes raros, evolução desconhecida e ruptura de método exigem sensibilidade.
7. Se nova coleta for necessária, retomar somente pendências, com parâmetros reais, seleção exclusiva e orçamento registrado. Coletores históricos usam perfil explícito no código; JSON analítico não amplia automaticamente a coleta.
8. Mudou apresentação: conferir arquivos afetados, atualizar QA e selar com conferir_entrega.py --selar. O selo recusa hash de figura diferente do inspecionado. Mudou base: preparar/revisar novamente; não trocar apenas hash.
9. Atualizar métodos, estado, changelog e espelho por lista explícita; preservar manifesto/45 arquivos de 09/10. Conferir bytes/Git antes do commit local. Publicação remota depende de instrução humana.

## Regras de interpretação

Não somar SINAN/SIH/SIM como pessoas. Não tratar ausência como zero. Não chamar todo A39 de meningite meningocócica ou MV de isolamento viral. Não excluir MNE para fabricar identificação etiológica. Não dividir SIM por SINAN como letalidade. Não emendar PNI legado/RNDS, calcular eficácia ecológica ou misturar geografias/denominadores. Não publicar casos individuais, RDS, DBC, ZIP ou HTML brutos no Git. Não alterar snapshots silenciosamente.

## Comunicação esperada

Responder em português com resultados claros, caminhos, filtros/unidades/denominadores, cobertura e pendências concretas. Preferir poucos gráficos legíveis e descritivos completos. Separar dado, descrição, associação, hipótese e causalidade. Preservar organização compacta, rastreabilidade e preferências expressas, sem atribuir escolhas da equipe ao usuário.
