# Uso: Rscript executar_aprofundamento.R <pasta Meningite>. Sem rede ou instalação.
executar_aprofundamento <- function(raiz) {
  for(p in c("ggplot2","patchwork","jsonlite","digest","MASS","sandwich"))
    if(!requireNamespace(p,quietly=TRUE))stop("Pacote necessario ausente: ",p)
  raiz<-normalizePath(raiz,winslash="/",mustWork=TRUE)
  out<-file.path(raiz,"analise/aprofundamento")
  config<-jsonlite::read_json(file.path(out,"configuracao.json"),simplifyVector=TRUE)
  sha<-function(p){con<-file(p,"rb");on.exit(close(con));digest::digest(readBin(con,"raw",n=file.info(p)$size),algo="sha256",serialize=FALSE)}
  origem<-file.path(raiz,config$fonte_rds);stopifnot(sha(origem)==config$fonte_sha256,identical(config$coletar,FALSE))
  set.seed(config$semente)
  for(d in c("dados","resultados/figuras","documentacao","controle"))dir.create(file.path(out,d),recursive=TRUE,showWarnings=FALSE)
  # Os quatro módulos são source-only; apenas o controlador executa.
  for(n in c("preparar_cruzamentos.R","preparar_auditoria_complementos.R","ajustar_modelos.R","gerar_figuras_aprofundadas.R"))
    source(file.path(out,"scripts",n),encoding="UTF-8",local=environment())
  s<-preparar_cruzamentos(raiz,config,file.path(out,"trabalho/sinan_populacao"))
  c<-preparar_auditoria_complementos(raiz,config,file.path(out,"trabalho/complementos"))
  b<-readRDS(origem);m<-ajustar_modelos(b,config)
  pkg<-list(metadados=list(versao=config$versao,fonte_sha256=sha(origem),fonte=config$fonte_rds,
      escopo="residentes Salvador; sintomas2014-2024; SINAN; complementos em universos proprios",
      exploratorio=TRUE,configuracao=config,casos_individuais=FALSE,unidade="registros confirmados, inclui MCC isolada",
      periodo_predefinido_antes_ajuste=TRUE,preregistro=FALSE),sinan=s,complementos=c,modelos=m)
  # Contrato longo: tabela + medida + eixos. Níveis distintos não são somáveis.
  bind<-function(xs){cols<-unique(unlist(lapply(xs,names)));xs<-lapply(xs,function(x){for(n in setdiff(cols,names(x)))x[[n]]<-NA;x[cols]});do.call(rbind,xs)}
  au<-c$tabelas$auditoria_campos;au$tabela<-"auditoria_campos";au$medida<-"n_estado";au$valor<-au$n
  au$numerador<-au$n;au$denominador<-au$denominador_elegivel;au$unidade<-"registros_elegiveis";au$fonte<-"SINAN_nacional"
  dc<-c$tabelas$distribuicoes_elegiveis;dc$tabela<-"distribuicoes_elegiveis";dc$medida<-"n_codigo";dc$valor<-dc$n
  dc$numerador<-dc$n;dc$denominador<-dc$denominador_elegivel;dc$unidade<-"registros_elegiveis";dc$fonte<-"SINAN_nacional"
  cross<-bind(list(s$cruzamentos_longo,au,dc))
  ce<-c$estimativas_longo;ce$tabela<-ce$analise;ce$valor<-ce$estimativa;ce$estimativa<-NULL
  ce$ic_inferior<-ce$ic95_inferior;ce$ic_superior<-ce$ic95_superior;ce$fonte<-ce$sistema
  me<-m$coeficientes;me$tabela<-"coeficientes_modelos";me$medida<-me$escala;me$valor<-me$estimativa;me$estimativa<-NULL
  me$ic_inferior<-me$ic95_inferior;me$ic_superior<-me$ic95_superior;me$unidade<-me$escala;me$fonte<-"SINAN_populacao"
  ed<-c$tabelas$parecer_campos;ed$tabela<-"parecer_campos";ed$medida<-"proporcao_desconhecida";ed$valor<-ed$percentual_desconhecido/100
  ed$numerador<-ed$n_desconhecido;ed$denominador<-ed$n_elegivel;ed$unidade<-"fracao_0_1";ed$fonte<-"SINAN_nacional";ed$nota<-ed$parecer
  est<-bind(list(s$estimativas_longo,ce,me,ed))
  for(z in c("cross","est")){
    d<-get(z);d$codigo_municipio<-config$municipio;d$versao_analitica<-config$versao
    nome<-if(z=="cross")"cruzamentos_sinan.csv" else "estimativas_e_sensibilidades.csv"
    path<-file.path(out,"dados",nome)
    write.table(d,path,sep=";",dec=".",na="",row.names=FALSE,quote=TRUE,fileEncoding="UTF-8")
    classes<-vapply(d,function(v)if(is.numeric(v))"numeric" else if(is.logical(v))"logical" else "character",character(1))
    back<-read.csv(path,sep=";",dec=".",na.strings="",colClasses=classes,check.names=FALSE,fileEncoding="UTF-8",stringsAsFactors=FALSE)
    stopifnot(isTRUE(all.equal(d,back,check.attributes=FALSE,tolerance=1e-10)))
    assign(z,d)
  }
  pkg$cruzamentos_longo<-cross;pkg$estimativas_longo<-est
  figs<-gerar_figuras_aprofundadas(pkg,config,file.path(out,"resultados/figuras"));pkg$figuras<-figs
  saveRDS(pkg,file.path(out,"meningites_aprofundamento.rds"),compress="xz")
  stopifnot(identical(pkg,readRDS(file.path(out,"meningites_aprofundamento.rds"))),sha(origem)==config$fonte_sha256)
  control<-bind(list(transform(s$validacao,frente="SINAN_populacao"),transform(c$validacao,frente="auditoria_complementos"),
    transform(m$validacao,controle=id,bloqueante=TRUE,frente="modelos")))
  stopifnot(nrow(control)>0,all(control$aprovado[control$bloqueante]))
  jsonlite::write_json(list(controles=control,aprovados=sum(control$aprovado),total=nrow(control),
    nota="Verificacoes estruturais e numericas; inconsistencias clinicas documentadas nao sao apagadas",
    csv_roundtrip=TRUE,rds_roundtrip=TRUE,fonte_inalterada=TRUE),file.path(out,"controle/validacao.json"),pretty=TRUE,auto_unbox=TRUE,na="null")
  jsonlite::write_json(list(tabelas_sinan=lapply(s$tabelas,function(x)list(linhas=nrow(x),colunas=names(x))),
    tabelas_complementos=lapply(c$tabelas,function(x)list(linhas=nrow(x),colunas=names(x))),
    modelos=m$decisoes,figuras=figs,csv=list(sep=";",dec=".",encoding="UTF-8",ausente="campo vazio",infinito="Inf, acompanhado por status original"),
    regra="Filtrar tabela/medida/eixos; nunca somar populacao ou n entre niveis diferentes"),
    file.path(out,"documentacao/dicionario_e_decisoes.json"),pretty=TRUE,auto_unbox=TRUE,na="null")
  jsonlite::write_json(list(entrada=list(caminho=config$fonte_rds,sha256=sha(origem)),
    fontes_complementos=c$tabelas$fontes,pacotes=setNames(lapply(c("ggplot2","patchwork","jsonlite","digest","MASS","sandwich"),
      function(p)as.character(packageVersion(p))),c("ggplot2","patchwork","jsonlite","digest","MASS","sandwich")),
    R=R.version.string,configuracao_sha256=sha(file.path(out,"configuracao.json"))),
    file.path(out,"documentacao/proveniencia.json"),pretty=TRUE,auto_unbox=TRUE)
  # Relatório principal dinâmico, sem copiar números de uma versão anterior.
  fmt<-function(v,d=2)formatC(v,format="f",digits=d,decimal.mark=",")
  mdtable<-function(d){head<-paste0("| ",paste(names(d),collapse=" | ")," |");line<-paste0("| ",paste(rep("---",ncol(d)),collapse=" | ")," |");
    body<-apply(d,1,function(x)paste0("| ",paste(x,collapse=" | ")," |"));c(head,line,body)}
  rr<-m$coeficientes[m$coeficientes$modelo=="taxas_principal" & m$coeficientes$termo=="sexoM",]
  per<-s$tabelas$padronizadas_periodos;ev<-s$tabelas$evolucao
  pe<-data.frame(Periodo=per$periodo,Registros=per$n,`Taxa bruta`=fmt(per$bruta),`Taxa padronizada`=fmt(per$taxa),
    `IC95 padronizada`=paste0(fmt(per$ic_inferior),"–",fmt(per$ic_superior)),check.names=FALSE)
  gd<-ev[ev$dimensao=="grupo",];grouplab<-c(MV="Viral",MNE="Nao especificada",Bacterianas_MB_MH_MP="Outras bacterianas",Meningococica_MCC_MM="Meningococica",MTBC="Tuberculosa",MOE="Outra",Vazio_nao_canonico="Residual")
  gg<-data.frame(Grupo=unname(grouplab[gd$grupo]),N=gd$N,D=gd$D,U=gd$U,`D/N (%)`=fmt(gd$D_sobre_N*100,1),
    `D/(N-U) (%)`=fmt(gd$D_sobre_K*100,1),`Limite superior extremo (%)`=fmt(gd$limite_extremo_superior*100,1),check.names=FALSE)
  ms<-m$coeficientes[m$coeficientes$termo=="sexoM" & grepl("^taxas_",m$coeficientes$modelo) & m$coeficientes$modelo!="taxas_interacao_sexo_idade",]
  st<-data.frame(Cenario=ms$modelo,`Razao M/F ajustada`=fmt(ms$estimativa),`IC95`=paste0(fmt(ms$ic95_inferior),"–",fmt(ms$ic95_superior)),check.names=FALSE)
  q<-c$tabelas$parecer_campos
  qt<-q[q$campo %in% c("CS_RACA","CS_ESCOL_N","CLA_SOROGR","ATE_HOSPIT","LAB_PUNCAO","ANT_IMUNO","ANT_CONJ_C","ANT_PNEUMO"),]
  qt<-data.frame(Campo=qt$campo,Elegiveis=qt$n_elegivel,Desconhecidos=qt$n_desconhecido,`Perdas (%)`=fmt(qt$percentual_desconhecido,1),check.names=FALSE)
  report<-c("# Meningites e doença meningocócica em Salvador: análise aprofundada", "", "Execução: 12/10/2026. SINAN por residência, ano dos primeiros sintomas 2014–2024. Análises exploratórias sobre o snapshot aprovado em 10/10. Nenhuma coleta nova nesta etapa.", "",
    "## Resultados que sustentam o trabalho", "",
    sprintf("- A taxa padronizada foi %s, %s e %s por 100 mil habitantes-ano nos três períodos. A recuperação de 2022–2024 permanece abaixo de 2014–2019. Isso descreve ocorrência registrada, incluindo mudanças na vigilância.",fmt(per$taxa[1]),fmt(per$taxa[2]),fmt(per$taxa[3])),
    sprintf("- Homens tiveram razão de taxas ajustada M/F %s (IC95 %s–%s), considerando idade e ano. As sensibilidades mantêm a direção e magnitude aproximada da associação.",fmt(rr$estimativa),fmt(rr$ic95_inferior),fmt(rr$ic95_superior)),
    "- A participação MNE subiu de 12,2% em 2014 para 25,9% em 2024, mas a taxa ficou praticamente igual: 1,63 versus 1,63 por 100 mil. O aumento proporcional não demonstra aumento populacional de meningite não especificada. MV caiu de 8,58 para 1,87 por 100 mil, contribuindo fortemente para a composição diferente.",
    "- O critério PCR passou de 2,5% dos registros em 2014–2019 para 20,8% em 2022–2024. Quimiocitológico passou de 76,8% para 48,0%. O método de investigação mudou junto com o perfil observado. Isso impede tratar a série como se a classificação tivesse precisão constante.",
    "- Os intervalos sintomas–notificação têm mediana de 4, 8 e 7 dias nos três períodos. São intervalos de registro, com extremos conservados; não medem tempo até diagnóstico ou tratamento.","",
    "## 1. Abrangência, idade e tempo", "",
    "A coorte inclui 1.976 registros confirmados, residentes em Salvador (292740). MCC isolada permanece incluída, e a análise sem MCC retira 19 registros. O denominador municipal é população DATASUS/RIPSA de 1º de julho, por sexo e idade. A soma anual aproxima habitantes-ano. Um sexo ignorado foi conservado nos totais e taxas por idade, e retirado das comparações M/F.","",
    mdtable(pe),"",
    "Padronização direta usa pesos fixos da soma das populações por idade de 2014–2024, ambos os sexos. O IC95 gamma de Fay–Feuer corresponde à taxa ponderada. Uma taxa padronizada não é o número real de casos dividido pela população total. Os períodos foram definidos no plano anterior ao ajuste dos modelos, depois da inspeção inicial da série, sem preregistro.","",
    "A taxa dos menores de um ano foi 82,45, 21,63 e 42,47 por 100 mil habitantes-ano. Em 20–59 anos, foi 5,92, 1,67 e 5,27. A recuperação é desigual entre as idades. A distribuição de contagens tem mais adultos porque essa população é maior; não confundir maior número de registros com maior taxa.","",
    "Partições 2023–2024 são preliminares. Sem 2014, o primeiro período usa efetivamente 2015–2019; sem 2023–2024, o último usa apenas 2022. As exposições são retiradas junto com os anos. A sensibilidade da fronteira de 365 dias não reclassificou registros desta coorte.","",
    "## 2. Sexo: associação e estabilidade", "",mdtable(st),"",
    "Modelo de contagens: n ~ sexo + cinco faixas de idade + ano categórico + offset(log população). A referência é feminino, idade <1 e ano 2014. Diagnóstico Pearson detectou sobredispersão (phi 1,35; p 0,013); a binomial negativa convergiu sem avisos, com dispersão residual 1,14. A sensibilidade quasi-Poisson evita depender apenas da NB. Não comparar AIC de quasi-modelos, nem AIC entre cenários com observações diferentes.","",
    "O modelo com interação sexo×idade fica como diagnóstico exploratório. Razões específicas por idade possuem incertezas diferentes; alguns intervalos atravessam 1. Não converter a inspeção de muitos grupos em prova de heterogeneidade. Não há ajuste para exposições sociais, comorbidades, acesso ou probabilidade de notificação.","",
    "## 3. Etiologia e investigação", "",
    "Sete grupos disjuntos preservam MV, MNE, outras bacterianas (MB/MH/MP), meningocócica (MM/MM+MCC/MCC), MTBC, MOE e residual. Os seis códigos não canônicos e dois vazios continuam residuais; não corrigir a etiologia usando um campo de agente isolado.","",
    "Entre os 874 MV, 807 trazem agente não identificado. Entre 261 MB, 180 indicam bactéria não especificada. Há 47 sorogrupos informados entre 85 elegíveis meningocócicos (B=9, C=32, Y=2, W=4); 38 estão ausentes. Esses números apoiam uma análise de especificidade e registro. Não estimam a distribuição populacional verdadeira de agentes ou sorogrupos.","",
    "## 4. Desfecho e dados ausentes", "",mdtable(gg),"",
    "D é óbito por meningite, U evolução ignorada e N todos os registros do grupo. D/N, D/(N−U) e (D+U)/N respondem a denominadores ou cenários diferentes. O intervalo extremo não é IC95 e não imputa o desfecho. Na coorte integral há 190 óbitos por meningite, 76 por outra causa, 1.566 altas e 144 evoluções ignoradas. Em 2024, U=32 de N=162, uma perda relevante para comparações recentes.","",
    "A maior proporção registrada de óbito nas outras bacterianas (20,3%) e tuberculosa (18,7%) em comparação com viral (1,6%) é um contraste descritivo relevante. Idade, seleção, classificação e acompanhamento podem contribuir. A MNE acumula 71 ignorados e sua proporção extrema vai de 13,1% a 29,2%; conclusões sobre gravidade nesse grupo são particularmente frágeis.","",
    "Modelo logístico suplementar: 1.826 registros com evolução conhecida, sexo conhecido e etiologia canônica; 190 eventos e 12 parâmetros além do intercepto. Ajusta sexo, cinco idades, seis grupos e três períodos. OR não é razão de riscos. O universo elegível tem 1.967 registros: nove excluídos (um sexo ignorado e oito residuais), seis residuais com evolução conhecida. Os dois cenários adicionais atribuem os 141 ignorados elegíveis integralmente a não evento ou evento para mostrar sensibilidade, sem preencher a fonte. Não são limites matemáticos de cada coeficiente ajustado. EPV e estimativas finitas são critérios operacionais e não demonstram isoladamente ausência formal de separação. Códigos residuais e o sexo ignorado ficam fora do modelo, conservados nos descritivos. A base mínima não permite análise de sobrevivência ou vínculo individual SINAN–SIH–SIM.","",
    "As células agregadas do modelo de óbito são esparsas; por isso o diagnóstico Pearson não foi usado como teste de ajuste calibrado. A sensibilidade quasi-binomial amplia a incerteza mantendo os coeficientes. As células mistas (com evento e não evento) têm posto completo na matriz de covariáveis, condição suficiente para afastar uma direção linear de separação nesta fórmula. Isso não resolve viés de seleção, classificação ou dados ausentes.","",
    "## 5. Notificação e meses", "",
    "Todos os 1.976 intervalos derivados são válidos na base mínima, sem negativos ou ausentes. Há 143 maiores de 30 dias e quatro maiores de 365 dias; máximo 1.833. Os limiares 30/365 são sensibilidades exploratórias e não critérios oficiais de validade. O gráfico acumulado integral mostra a cauda inteira; tabelas adicionais apresentam os cortes separadamente. Uma mudança de registro ou represamento pode alongar esses intervalos sem demonstrar pior assistência.","",
    sprintf("A análise de 132 meses usa componente harmônico anual, tendência linear e três períodos, com exposição mensal aproximada pelos dias de cada mês. Resíduos ainda possuem autocorrelação (diagnóstico aproximado Ljung–Box lag12, fitdf=0, p=%s, sem calibração específica para resíduos GLM). O teste conjunto dos componentes sazonais com covariância HAC lag12 tem p=%s. Não há suporte firme para afirmar sazonalidade constante; o gráfico é suplementar. HAC altera a incerteza, sem corrigir uma média mal especificada.",fmt(m$tabelas$diagnostico_mensal$ljung_box_p,3),fmt(m$tabelas$diagnostico_mensal$p_harmonico_exploratorio,3)),"",
    "## 6. Campos adicionais e fontes complementares", "",mdtable(qt),"",
    "Escolaridade foi auditada em adultos de 25 anos ou mais; 61,25% desconhecida impede associação principal. Raça tem 27,5% desconhecida e não dispõe de denominador anual específico nesta entrega; usar apenas perfil e sensibilidade entre casos. ANT_IMUNO está integralmente vazio, apesar de o campo existir nas partições, e não significa ausência de imunodepressão. Antecedentes vacinais têm perdas elevadas e não permitem estimar eficácia. Hospitalização tem 1.914 sim, 37 não e 25 desconhecidos: descrição entre casos é possível, mas o grupo não hospitalizado é pequeno e sujeito a seleção. ATE_INTERN é data, não indicador binário.","",
    "A auditoria aponta oito hospitalizados sem data, seis preenchimentos CLA_ME_ASS fora da elegibilidade etiológica, 23 culturas e 14 PCR de líquor fora da condição operacional de punção, seis quimioprofilaxias fora da elegibilidade e um código de escolaridade não aplicável acima de sete anos. As divergências são registradas sem correção automática. Critérios de elegibilidade têm limites documentais e não comprovam estabilidade do preenchimento em todos os anos.","",
    "SIH disponibiliza 308 taxas de perfis: G00/A87 por 12 faixas de idade e A87/A39 por sexo, nos 11 anos. Populações foram reagrupadas para os limites originais das faixas e as marginais conferidas. SIH mede AIHs/episódios por ano de processamento; SINAN mede registros por sintomas. Séries podem ser mostradas lado a lado ou em índices próprios 2014=100, mas não somadas ou usadas como proporção de casos internados. Dias de permanência, valores nominais e óbitos permanecem medidas separadas; médias/razões administrativas não aprovadas por correspondência de universo insuficiente. G01 óbitos e internações G01–G03 ausentes permanecem NA.","",
    "SIM: 202 óbitos por causas selecionadas no recorte de registros da Bahia; cobertura nacional dos residentes não demonstrada. PNI: 17 observações de 44 indicadores/anos, com métodos legado e RNDS distintos. Não fazer associação municipal de cobertura e incidência ou inferir efeito vacinal com essa cobertura parcial. Referência Bahia/C2 depende de população e abrangência comparáveis; não foi coletada nesta etapa.","",
    "## 7. Argumento científico e próximos usos", "",
    "O trabalho pode se organizar em torno da redução e recuperação desigual da ocorrência registrada, da diferença por sexo e da mudança simultânea da investigação etiológica. A tensão principal é epidemiologia versus observabilidade: parte da alteração pode refletir circulação, investigação, acesso e registro. Os dados mostram o padrão; não identificam causalmente sua origem.","",
    "Hipóteses para discussão: mudanças na circulação e acesso em 2020–2021; retorno desigual por idade; alteração dos critérios de investigação; seleção de casos e incompletude dos desfechos. Devem ser apresentadas como hipóteses, apoiadas por literatura e contexto, sem atribuir o resultado à vacinação ou pandemia a partir destas séries.","",
    "Para uma apresentação enxuta, priorizar G01, G02, G04 e G05. G03 aprofunda idade×etiologia, G06 o processo de registro. G07 e G08 ficam suplementares. O caderno contém todas as oito figuras em PDF vetorial, e PNGs separados para consulta. As seis figuras anteriores permanecem preservadas.","",
    "Antes de inferência confirmatória: definir uma pergunta primária, escolher modelo/contraste e período, atualizar partições preliminares, delimitar testes múltiplos e, se essencial, completar o denominador e a cobertura externos. Esta etapa não substitui um protocolo confirmatório.","",
    "## Reprodução e referências de método", "",
    "Executar o controlador R offline com a pasta Meningite como argumento; os exemplos estão no README. Duas tabelas CSV longas, RDS apenas com agregados/modelos e dicionário permitem reuso em R e outros programas. Não há dados individuais no pacote aprofundado. Os CSV usam ponto decimal e separador ponto e vírgula, campos vazios como NA. Filtrar tabela/medida/eixos antes de agregar.","",
    "- [Padronização direta e IC gamma, epitools](https://search.r-project.org/CRAN/refmans/epitools/html/ageadjust.direct.html). Fórmula conferida com o código CRAN e testes de zeros/estrato único; pacote não instalado.",
    "- [GLM e offset, R](https://search.r-project.org/R/refmans/stats/html/glm.html) e [famílias quasi e AIC](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/family.html).",
    "- [Binomial negativa, MASS](https://stat.ethz.ch/R-manual/R-devel/library/MASS/html/glm.nb.html).",
    "- [Covariância HAC Newey–West, sandwich](https://search.r-project.org/CRAN/refmans/sandwich/html/NeweyWest.html).",
    "",paste0("Fonte aprovada SHA-256: `",config$fonte_sha256,"`. Nenhuma alteração da fonte ou nova consulta. Os valores e testes são exploratórios; IC de contagem não corrige subnotificação ou cobertura."))
  writeLines(report,file.path(out,"resultados/RELATORIO_APROFUNDADO.md"),useBytes=TRUE)
  readme<-c("# Meningites em Salvador — aprofundamento analítico","","Etapa executada em 12/10/2026 sobre a entrega aprovada de 10/10. Trabalho offline, fonte preservada, sem novos downloads.","",
    "- [Relatório com resultados e argumento científico](resultados/RELATORIO_APROFUNDADO.md)",
    "- [Caderno de oito gráficos vetoriais](resultados/figuras/CADERNO_GRAFICOS_APROFUNDADOS.pdf)",
    "- `meningites_aprofundamento.rds`: tabelas por análise, modelos compactos, configuração, validação e fontes; apenas agregados.",
    "- [Cruzamentos e auditoria](dados/cruzamentos_sinan.csv) e [estimativas e sensibilidades](dados/estimativas_e_sensibilidades.csv): dois CSVs canônicos. Arquivos de trabalho são candidatos/revisões e não novas bases concorrentes.",
    "- [Dicionário e decisões](documentacao/dicionario_e_decisoes.json), [proveniência](documentacao/proveniencia.json) e [validação](controle/validacao.json).", "",
    "## Rodar novamente no PowerShell", "", "```powershell", "$env:LC_ALL = 'Portuguese_Brazil.utf8'", "$env:R_LIBS_USER = 'C:/Users/joaov/AppData/Local/R/win-library/4.5'",
    "& 'C:/R/R/R-4.5.1/bin/x64/Rscript.exe' 'C:/Pesquisa/Boletim epidemiolóico/Meningite/analise/aprofundamento/scripts/executar_aprofundamento.R' 'C:/Pesquisa/Boletim epidemiolóico/Meningite'", "```", "",
    "O comando recalcula os agregados, modelos, relatório e figuras desta etapa a partir do RDS aprovado. Não baixa dados ou instala pacotes. Uma base com outro SHA exige nova versão e revisão dos filtros. source() dos módulos somente define funções; source() do controlador não executa a etapa.","",
    "## Usar no R/RStudio", "", "```r", "a <- readRDS('C:/Pesquisa/Boletim epidemiolóico/Meningite/analise/aprofundamento/meningites_aprofundamento.rds')",
    "a$sinan$tabelas$padronizadas_periodos", "subset(a$modelos$coeficientes, modelo == 'taxas_principal' & termo == 'sexoM')",
    "e <- read.csv('C:/Pesquisa/Boletim epidemiolóico/Meningite/analise/aprofundamento/dados/estimativas_e_sensibilidades.csv', sep=';', dec='.', na.strings='', fileEncoding='UTF-8')",
    "subset(e, tabela == 'padronizadas_anuais' & medida == 'taxa')", "```", "",
    "Modelo de óbito entrega OR, não razão de riscos. Limites dos ignorados não são IC. Índices de fontes diferentes não ligam pessoas. PNI incompleto, SIM com recorte Bahia e comparação Bahia não liberada para inferência. Partições 2023–2024 preliminares. Consulta de novas fontes é uma etapa separada.","",
    "O Git recebe scripts, configuração, agregados e gráficos; os RDS e fontes individuais ficam somente na pasta de trabalho. Reproduzir em outra máquina requer reconstruir a fonte conforme o manual de coleta; o RDS aceito não é distribuído pelo repositório.")
  writeLines(readme,file.path(out,"README.md"),useBytes=TRUE)
  cat("Etapa integrada: ",nrow(control)," controles; ",nrow(cross)," cruzamentos/auditoria; ",nrow(est)," estimativas; ",nrow(figs)," figuras.\n",sep="")
  invisible(pkg)
}
if(sys.nframe()==0L){args<-commandArgs(trailingOnly=TRUE);if(length(args)!=1L)stop("Informe a pasta Meningite");executar_aprofundamento(args[1])}
