# Descritivos calculados a partir do pacote aceito; nenhuma consulta externa.
gerar_descritivos <- function(pacote, config) {
  casos <- pacote$SINAN$casos_minimos_locais
  pop <- pacote$populacao
  anos <- as.integer(config$anos)
  N <- nrow(casos)
  stopifnot(N==config$controles$coorte)
  faixa_padrao <- function(x) {
    x <- as.character(x)
    x[x %in% c("<1 Ano","Menor 1 ano")] <- "<1"
    x[x %in% c("80 e +","80 anos e mais")] <- "80+"
    x
  }
  casos$faixa_descritiva <- faixa_padrao(casos$faixa_etaria)
  casos$sexo_descritivo <- ifelse(casos$sexo_codigo %in% c("M","F"),casos$sexo_codigo,"Ignorado")
  populacao_faixas <- if(!is.null(pop$basica)) pop$basica else pop$faixas_sinan
  populacao_faixas$faixa <- faixa_padrao(populacao_faixas$faixa_etaria_sinan)
  stopifnot(nrow(populacao_faixas)==config$controles$estratos_populacao,
    all(populacao_faixas$faixa %in% config$faixas))
  ic_poisson <- function(n, d) {
    alfa <- 1-config$nivel_confianca
    li <- ifelse(n==0,0,stats::qchisq(alfa/2,2*n)/2)
    ls <- stats::qchisq(1-alfa/2,2*(n+1))/2
    cbind(inferior=li/d*config$taxa_base,superior=ls/d*config$taxa_base)
  }
  taxa <- function(t) {
    stopifnot(all(!is.na(t$populacao)),all(t$populacao>0))
    ci <- ic_poisson(t$n,t$populacao)
    t$taxa_100mil <- t$n/t$populacao*config$taxa_base
    t$ic95_inferior <- ci[,1]; t$ic95_superior <- ci[,2]
    t
  }
  contar_grade <- function(campos, grade) {
    valores <- lapply(campos,function(v) casos[[v]])
    names(valores) <- names(grade)
    observado <- aggregate(rep(1L,N),by=valores,FUN=sum)
    names(observado)[ncol(observado)] <- "n"
    t <- merge(grade,observado,by=names(grade),all.x=TRUE,sort=TRUE)
    t$n[is.na(t$n)] <- 0L
    t$status <- ifelse(t$n==0L,"zero_derivado_coorte","observado")
    t
  }
  anual <- contar_grade(c("ano_sintomas"),data.frame(ano=anos))
  anual <- taxa(merge(anual,pop$total,by="ano",all.x=TRUE,sort=TRUE))
  stopifnot(identical(as.integer(anual$n),as.integer(config$controles$totais_anuais)))
  mensal <- contar_grade(c("ano_sintomas","mes_sintomas"),expand.grid(ano=anos,mes=1:12))
  stopifnot(nrow(mensal)==132L,sum(mensal$n)==N)
  sex_ano <- contar_grade(c("ano_sintomas","sexo_descritivo"),expand.grid(ano=anos,sexo=c("M","F")))
  sex_pop <- aggregate(populacao~ano+sexo,populacao_faixas,sum)
  sex_ano <- taxa(merge(sex_ano,sex_pop,by=c("ano","sexo"),all.x=TRUE,sort=TRUE))
  idade_ano <- contar_grade(c("ano_sintomas","faixa_descritiva"),expand.grid(ano=anos,faixa=config$faixas))
  idade_pop <- aggregate(populacao~ano+faixa,populacao_faixas,sum)
  idade_ano <- taxa(merge(idade_ano,idade_pop,by=c("ano","faixa"),all.x=TRUE,sort=TRUE))
  sex_periodo <- taxa(merge(aggregate(n~sexo,sex_ano,sum),aggregate(populacao~sexo,sex_pop,sum),by="sexo"))
  idade_periodo <- taxa(merge(aggregate(n~faixa,idade_ano,sum),aggregate(populacao~faixa,idade_pop,sum),by="faixa"))
  sex_periodo$percentual_coorte <- 100*sex_periodo$n/N
  idade_periodo$percentual_coorte <- 100*idade_periodo$n/N
  # Soma de populações anuais aproxima a exposição em habitantes-ano; não pessoas únicas.
  categ <- function(campo) {
    x <- as.character(casos[[campo]])
    x[is.na(x)|!nzchar(x)] <- "Vazio"
    t <- aggregate(rep(1L,N),by=list(ano=casos$ano_sintomas,categoria=x),sum)
    names(t)[3] <- "n"
    t$denominador <- anual$n[match(t$ano,anual$ano)]
    t$percentual <- 100*t$n/t$denominador
    t
  }
  etiologia <- categ("etiologia"); criterio <- categ("criterio"); evolucao <- categ("evolucao")
  grupo <- rep("Vazio/não canônico",N)
  grupo[casos$etiologia=="MV"] <- "Viral (MV)"
  grupo[casos$etiologia=="MNE"] <- "Não especificada (MNE)"
  grupo[casos$etiologia %in% c("MM","MCC","MM+MCC")] <- "Doença meningocócica"
  grupo[casos$etiologia %in% c("MB","MH","MP")] <- "Outras bacterianas"
  grupo[casos$etiologia=="MTBC"] <- "Tuberculosa (MTBC)"
  grupo[casos$etiologia=="MOE"] <- "Outra etiologia (MOE)"
  grupos <- aggregate(rep(1L,N),by=list(ano=casos$ano_sintomas,grupo=grupo),sum)
  names(grupos)[3] <- "n"
  grupos$denominador <- anual$n[match(grupos$ano,anual$ano)]
  grupos$percentual <- 100*grupos$n/grupos$denominador
  qualidade <- if(!is.null(pacote$SINAN$qualidade_anual)) pacote$SINAN$qualidade_anual else pacote$SINAN$qualidade
  registros <- list()
  add <- function(tabela,fonte,ano=NA_integer_,periodo="2014-2024",dimensao="total",estrato="Todos",
                  medida,valor,unidade,numerador=NA_real_,denominador=NA_real_,denominador_tipo="inaplicavel",
                  ic95_inferior=NA_real_,ic95_superior=NA_real_,status="observado",nota="") {
    registros[[length(registros)+1L]] <<- data.frame(tabela,fonte,ano,periodo,dimensao,estrato,medida,valor,
      unidade,numerador,denominador,denominador_tipo,ic95_inferior,ic95_superior,status,nota,stringsAsFactors=FALSE)
  }
  fluxo <- pacote$SINAN$fluxos
  nomes_fluxo <- c(n_nacional="Registros nacionais",n_residentes="Residentes Salvador",
    n_confirmados="Residentes confirmados",n_coorte="Coorte sintomas 2014-2024",
    n_confirmados_fora_janela="Confirmados fora da janela",n_confirmados_sem_data="Confirmados sem data")
  for(v in names(nomes_fluxo)) add("D01","SINAN",dimensao="seleção",estrato=nomes_fluxo[[v]],
    medida="n_registros",valor=sum(fluxo[[v]]),unidade="registros de notificação",
    nota="Partições MENIBR14-26; cada linha corresponde ao estágio indicado, sem somar estágios.")
  add("D02","SINAN",ano=anual$ano,medida="n_registros",valor=anual$n,unidade="registros confirmados")
  add("D02","Populacao",ano=anual$ano,medida="populacao_residente",valor=anual$populacao,unidade="habitantes",
    nota="Estimativa em 1º de julho; mesma versão em todos os denominadores.")
  add("D02","SINAN",ano=anual$ano,medida="taxa_registrada",valor=anual$taxa_100mil,unidade="por 100 mil habitantes",
    numerador=anual$n,denominador=anual$populacao,denominador_tipo="população anual",
    ic95_inferior=anual$ic95_inferior,ic95_superior=anual$ic95_superior,
    nota="IC95 exato Poisson; não corrige subnotificação nem incerteza demográfica.")
  for(tipo in c("sexo","idade")) {
    t <- if(tipo=="sexo") sex_ano else idade_ano
    estrato <- if(tipo=="sexo") t$sexo else t$faixa
    total_ano <- anual$n[match(t$ano,anual$ano)]
    add("D03","SINAN",ano=t$ano,dimensao=tipo,estrato=estrato,medida="n_registros",valor=t$n,
      unidade="registros confirmados",status=t$status)
    add("D03","SINAN",ano=t$ano,dimensao=tipo,estrato=estrato,medida="percentual_coorte_anual",valor=100*t$n/total_ano,
      unidade="%",numerador=t$n,denominador=total_ano,denominador_tipo="todos os registros do ano",status=t$status)
    add("D03","SINAN",ano=t$ano,dimensao=tipo,estrato=estrato,medida="taxa_registrada",valor=t$taxa_100mil,
      unidade="por 100 mil habitantes",numerador=t$n,denominador=t$populacao,denominador_tipo="população anual compatível",
      ic95_inferior=t$ic95_inferior,ic95_superior=t$ic95_superior,status=t$status)
    tp <- if(tipo=="sexo") sex_periodo else idade_periodo
    ep <- if(tipo=="sexo") tp$sexo else tp$faixa
    add("D03","SINAN",dimensao=paste0(tipo,"_periodo"),estrato=ep,medida="taxa_media_ponderada",valor=tp$taxa_100mil,
      unidade="por 100 mil habitantes-ano",numerador=tp$n,denominador=tp$populacao,
      denominador_tipo="soma das populações anuais, aproximação de exposição",ic95_inferior=tp$ic95_inferior,
      ic95_superior=tp$ic95_superior,nota="Onze anos; não é taxa cumulativa nem média simples das taxas anuais.")
  }
  add("D03","SINAN",dimensao="sexo",estrato="Ignorado",medida="n_registros",valor=sum(casos$sexo_descritivo=="Ignorado"),
      unidade="registros confirmados",nota="Conservados no total; sem população correspondente para taxa específica.")
  for(tipo in c("etiologia","criterio")) {
    t <- if(tipo=="etiologia") etiologia else criterio
    add("D04","SINAN",ano=t$ano,dimensao=tipo,estrato=t$categoria,medida="n_registros",valor=t$n,unidade="registros confirmados")
    add("D04","SINAN",ano=t$ano,dimensao=tipo,estrato=t$categoria,medida="percentual_coorte_anual",valor=t$percentual,
      unidade="%",numerador=t$n,denominador=t$denominador,denominador_tipo="todos os registros do ano",
      nota="Categoria registrada; não equivale automaticamente a agente isolado em laboratório.")
  }
  add("D05","SINAN",ano=mensal$ano,dimensao="mes",estrato=sprintf("%02d",mensal$mes),medida="n_registros",
    valor=mensal$n,unidade="registros confirmados",status=mensal$status,
    nota="Ano/mês dos sintomas; zero somente derivado da coorte integralmente lida.")
  add("D06","SINAN",ano=evolucao$ano,dimensao="evolucao",estrato=evolucao$categoria,medida="n_registros",valor=evolucao$n,
    unidade="registros confirmados")
  add("D06","SINAN",ano=evolucao$ano,dimensao="evolucao",estrato=evolucao$categoria,medida="percentual_coorte_anual",valor=evolucao$percentual,
    unidade="%",numerador=evolucao$n,denominador=evolucao$denominador,denominador_tipo="todos os registros do ano")
  add("D06","SINAN",ano=qualidade$ano,dimensao="qualidade",estrato=qualidade$campo,medida="percentual_conhecido",
    valor=qualidade$percentual,unidade="%",numerador=qualidade$n_conhecido,denominador=qualidade$total,
    denominador_tipo=qualidade$universo,nota="Conhecido/interpretável conforme campo; preenchimento não é validade clínica.")
  add("D06","SINAN",ano=qualidade$ano,dimensao="qualidade",estrato=qualidade$campo,medida="n_desconhecido_inaplicavel",
    valor=qualidade$n_ausente_ignorado_nao_interpretavel,unidade="registros",denominador_tipo=qualidade$universo,
    nota="Consultar a regra de universo do campo; não interpretar todo vazio como negativo.")
  D <- sum(casos$evolucao_codigo=="2",na.rm=TRUE)
  U <- sum(!casos$evolucao_codigo %in% c("1","2","3"))
  K <- N-U
  add("D06","SINAN",dimensao="evolucao_periodo",estrato="Óbito por meningite",medida=c("percentual_coorte","percentual_entre_conhecidos"),
    valor=c(100*D/N,100*D/K),unidade="%",numerador=D,denominador=c(N,K),
    denominador_tipo=c("todos os registros","evolução conhecida"),
    nota=paste0("Desconhecidos: ",U,"/",N,". Resumo secundário, sem letalidade completa ou imputação."))
  valido_intervalo <- !is.na(casos$dias_sintomas_notificacao) & casos$dias_sintomas_notificacao>=0
  intervalo <- casos$dias_sintomas_notificacao[valido_intervalo]
  add("D06","SINAN",dimensao="intervalo_sintomas_notificacao",medida=c("q25","mediana","q75"),
      valor=unname(quantile(intervalo,c(.25,.5,.75))),unidade="dias",denominador=length(intervalo),denominador_tipo="registros com intervalo válido",
      nota="Intervalos não negativos com ambas as datas válidas; não é tempo para diagnóstico confirmado.")
  add("D06","SINAN",dimensao="intervalo_sintomas_notificacao",medida=c("n_validos","n_ausentes","n_negativos"),
      valor=c(sum(valido_intervalo),sum(is.na(casos$dias_sintomas_notificacao)),sum(casos$dias_sintomas_notificacao<0,na.rm=TRUE)),unidade="registros")
  tabelas <- list(serie_anual=anual,sexo_anual=sex_ano,idade_anual=idade_ano,sexo_periodo=sex_periodo,
    idade_periodo=idade_periodo,mensal=mensal,etiologia_anual=etiologia,grupos_etiologia_anuais=grupos,
    criterio_anual=criterio,evolucao_anual=evolucao,qualidade=qualidade)
  list(tabelas=tabelas,descritivos=do.call(rbind,registros),
    resumo=list(n=N,sexo_ignorado=sum(casos$sexo_descritivo=="Ignorado"),obitos_meningite=D,evolucao_desconhecida=U,
      intervalo_mediana=median(intervalo),variacao_contagens_2014_2024=100*(tail(anual$n,1)/anual$n[1]-1),
      variacao_taxas_2014_2024=100*(tail(anual$taxa_100mil,1)/anual$taxa_100mil[1]-1)))
}

complementar_descritivos <- function(resultado, pacote, config) {
  base <- resultado$descritivos
  montar <- function(tabela,fonte,ano,dimensao,estrato,medida,valor,unidade,
    numerador=NA_real_,denominador=NA_real_,denominador_tipo="inaplicavel",status="observado",nota="") {
    data.frame(tabela,fonte,ano,periodo="2014-2024",dimensao,estrato,medida,valor,unidade,numerador,denominador,
      denominador_tipo,ic95_inferior=NA_real_,ic95_superior=NA_real_,status,nota,stringsAsFactors=FALSE)
  }
  sih <- pacote$SIH$dados
  sim <- pacote$SIM$dados
  pni <- pacote$PNI$dados
  d7 <- montar("D07","SIH",sih$ano,paste(sih$tipo_tabela,sih$dimensao,sep=":"),
    paste(sih$cid_grupo,sih$estrato,sep=":"),sih$medida,sih$valor,sih$unidade,status=sih$status,
    nota="Residência Salvador; ano de processamento; total/perfil e medidas não podem ser somados juntos. A39 é infecção meningocócica ampla.")
  d8 <- montar("D08","SIM",sim$ano,paste(sim$tipo_tabela,sim$dimensao,sep=":"),sim$estrato,
    sim$medida,sim$valor,sim$unidade,status=sim$status,
    nota="Causa básica G00-G03/A39/A87; residência Salvador; registro BA. Cobertura de óbitos em todas as UFs não demonstrada.")
  d9 <- montar("D09","PNI",pni$ano,pni$metodo,pni$indicador_fonte,"cobertura_oficial",pni$cobertura_percentual,"%",
    pni$numerador_oficial,pni$denominador_oficial,"componentes oficiais quando fornecidos",status=pni$status,
    nota=paste(pni$geografia,pni$esquema,pni$populacao_alvo,sep="; "))
  cv <- pacote$documentacao$cobertura
  d10 <- montar("D10",cv$sistema,cv$ano,cv$dimensao,cv$indicador,"disponibilidade",rep(NA_real_,nrow(cv)),"estado da cobertura",
    status=cv$status,nota=cv$motivo)
  resultado$descritivos <- rbind(base,d7,d8,d9,d10)
  s <- sih[sih$tipo_tabela=="total" & sih$medida=="internacoes" & sih$cid_grupo%in%c("G00","A39","A87"),]
  resultado$tabelas$sih_serie_figura <- data.frame(ano=s$ano,cid=s$cid_grupo,valor=s$valor,status=s$status)
  pp <- pni[!is.na(pni$cobertura_percentual),]
  grupo_rotulo <- c(bcg="BCG",meningococica="Meningocócica",pneumococica="Pneumocócica",penta_hib="Pentavalente")
  resultado$tabelas$pni_figura <- data.frame(ano=pp$ano,valor=pp$cobertura_percentual,
    indicador=unname(grupo_rotulo[pp$indicador_grupo]),metodo=ifelse(pp$sistema=="PNI_RNDS_individual","RNDS: residência","Legado: município do registro"))
  resultado$tabelas$sih_totais <- sih[sih$tipo_tabela=="total",]
  resultado$tabelas$sim_totais <- sim[sim$tipo_tabela=="total",]
  resultado$tabelas$pni_observado <- pp
  resultado
}

escrever_relatorio <- function(pacote, destino) {
  T <- pacote$resultados$tabelas; R <- pacote$resultados$resumo
  fmt <- function(x,k=1) formatC(x,digits=k,format="f",decimal.mark=",",big.mark=".")
  tabela <- function(d) {
    d[] <- lapply(d,as.character)
    c(paste0("| ",paste(names(d),collapse=" | ")," |"),paste0("| ",paste(rep("---",ncol(d)),collapse=" | ")," |"),
      apply(d,1,function(z)paste0("| ",paste(z,collapse=" | ")," |")),"")
  }
  a <- T$serie_anual; sx <- T$sexo_periodo; ag <- T$idade_periodo
  ag <- ag[match(pacote$configuracao$faixas,ag$faixa),]
  m <- sx[sx$sexo=="M",]; f <- sx[sx$sexo=="F",]
  et <- aggregate(n~categoria,T$etiologia_anual,sum);et<-et[order(et$n,decreasing=TRUE),]
  evol <- aggregate(n~categoria,T$evolucao_anual,sum)
  hospital <- T$sih_totais
  h <- hospital[hospital$medida=="internacoes" & hospital$cid_grupo%in%c("G00","A39","A87"),]
  htotal <- aggregate(valor~cid_grupo,h,sum)
  ob <- hospital[hospital$medida=="obitos",]
  ob_retornados <- ob[!is.na(ob$valor),]
  ob_ausentes <- unique(ob$cid_grupo[is.na(ob$valor)])
  n_obitos_retornados <- sum(ob_retornados$valor)
  n_folhas_obitos_retornados <- length(unique(ob_retornados$cid_grupo))
  mm <- T$mensal
  mm_max <- mm[which.max(mm$n),]
  mes_total <- aggregate(n~mes,mm,sum)
  nomes_mes <- c("janeiro","fevereiro","março","abril","maio","junho","julho","agosto","setembro","outubro","novembro","dezembro")
  pct_etiol <- function(cat,ano) sum(T$etiologia_anual$n[T$etiologia_anual$categoria==cat & T$etiologia_anual$ano==ano])/a$n[a$ano==ano]*100
  n_hosp <- function(cid,ano) h$valor[h$cid_grupo==cid & h$ano==ano]
  pni <- T$pni_observado
  pni <- pni[order(pni$indicador_grupo,pni$ano),]
  cv <- pacote$documentacao$cobertura
  qc <- pacote$controle$validacao
  texto <- c("# Meningites e doença meningocócica em Salvador: resultados descritivos",
    "", "Versão analítica: 10/10/2026. Residentes de Salvador; sintomas de 2014–2024 no SINAN. Os complementos têm referências próprias.","",
    "## O que os dados mostram", "",
    paste0("- A coorte contém **",fmt(R$n,0)," registros confirmados**. A taxa registrada passou de **",fmt(a$taxa_100mil[1],2),
      " para ",fmt(tail(a$taxa_100mil,1),2)," por 100 mil habitantes**, de 2014 a 2024 (variação de ",fmt(R$variacao_taxas_2014_2024,1),"%)."),
    paste0("- Houve uma redução acentuada em 2020–2021 (",a$n[a$ano==2020]," e ",a$n[a$ano==2021]," registros), seguida de recuperação em 2022–2023 e pequena redução em 2024 (162 frente a 167 em 2023). O dado descreve o registro; não distingue sozinho mudanças de transmissão, acesso, investigação ou notificação."),
    paste0("- O sexo masculino teve ",fmt(m$n,0)," registros e taxa média de ",fmt(m$taxa_100mil,2)," por 100 mil habitantes-ano; o feminino, ",
      fmt(f$n,0)," e ",fmt(f$taxa_100mil,2),". A razão descritiva entre essas taxas foi ",fmt(m$taxa_100mil/f$taxa_100mil,2),". Há um registro com sexo ignorado."),
    paste0("- A maior taxa por idade foi no grupo **",ag$faixa[which.max(ag$taxa_100mil)]," ano**, com ",fmt(max(ag$taxa_100mil),2),
      " por 100 mil habitantes-ano. O maior número absoluto foi em **",ag$faixa[which.max(ag$n)]," anos**, com ",ag$n[which.max(ag$n)]," registros. Volume e taxa respondem a perguntas diferentes."),
    paste0("- MV foi a categoria etiológica mais frequente (874; ",fmt(100*874/R$n),"%), seguida de MNE (442; ",fmt(100*442/R$n),
      "%). MV é classificação registrada; MNE mede a ausência de especificação, não ausência da doença."),
    "", "## 1. Série anual principal", "",
    "Taxa = registros confirmados / população residente × 100.000. O IC95 exato de Poisson representa a incerteza da contagem registrada; não corrige subnotificação ou incerteza populacional.","",
    tabela(data.frame(Ano=a$ano,Registros=a$n,População=fmt(a$populacao,0),`Taxa/100 mil`=fmt(a$taxa_100mil,2),
      `IC95`=paste0(fmt(a$ic95_inferior,2),"–",fmt(a$ic95_superior,2)),check.names=FALSE)),
    "[Figura 1 — evolução anual](figuras/F01_evolucao_anual.png). Inclui MCC isolada e MNE; fontes nacionais de 2023 em diante estão identificadas como preliminares.","",
    "## 2. Sexo e idade", "",
    "As taxas do período usam a soma das onze populações anuais como aproximação de exposição em habitantes-ano. São taxas médias ponderadas, sem assumir pessoas únicas. Taxas específicas anuais também estão no pacote e no CSV de descritivos.","",
    tabela(data.frame(Sexo=ifelse(sx$sexo=="M","Masculino","Feminino"),Registros=sx$n,`% da coorte`=fmt(sx$percentual_coorte),
      `Taxa/100 mil habitantes-ano`=fmt(sx$taxa_100mil,2),IC95=paste0(fmt(sx$ic95_inferior,2),"–",fmt(sx$ic95_superior,2)),check.names=FALSE)),
    tabela(data.frame(`Idade (anos)`=ag$faixa,Registros=ag$n,`% da coorte`=fmt(ag$percentual_coorte),
      `Taxa/100 mil habitantes-ano`=fmt(ag$taxa_100mil,2),IC95=paste0(fmt(ag$ic95_inferior,2),"–",fmt(ag$ic95_superior,2)),check.names=FALSE)),
    "[Figura 2 — sexo e idade](figuras/F02_perfil_sexo_idade.png). Um registro de sexo ignorado fica no total e no perfil etário, mas não tem taxa por sexo. A conversão de idade preserva a regra histórica auditada; a faixa não comprova uma idade exata reconstruída.","",
    "## 3. Distribuição mensal", "",
    "A grade contém 132 meses e fecha as onze contagens anuais. Agosto/2020 tem zero registros na coorte integralmente lida; o arquivo original tinha 131 combinações observadas. Não foi atribuída população mensal. O mapa permite localizar concentrações; uma sazonalidade estável exigiria análise específica considerando tendência e mudanças de registro.","",
    paste0("O maior valor mensal foi ",mm_max$n," em ",nomes_mes[mm_max$mes],"/",mm_max$ano,". Agregando os onze anos, o maior volume foi em ",
      nomes_mes[mes_total$mes[which.max(mes_total$n)]]," (",max(mes_total$n),") e o menor em ",nomes_mes[mes_total$mes[which.min(mes_total$n)]],
      " (",min(mes_total$n),"). São contagens sem ajuste pela duração dos meses ou tendência; não demonstram por si uma sazonalidade estável."),"",
    "[Figura 3 — distribuição mensal](figuras/F03_distribuicao_mensal.png).", "",
    "## 4. Etiologia e critérios de confirmação", "",
    tabela(data.frame(Categoria=et$categoria,Registros=et$n,`% de todos os registros`=fmt(100*et$n/R$n),check.names=FALSE)),
    "Os seis registros com códigos não canônicos e os dois vazios permanecem na coorte. Não houve conversão de `7`, `7.`, `7%`, `%7` ou `X` para `07`. Os grupos meningocócicos incluem MCC, MM e MM+MCC; MCC isolada permanece identificada. PCR geral não prova agente viral; o rótulo histórico TabNet não foi usado como confirmação etiológica.","",
    "[Figura 4 — composição etiológica](figuras/F04_classificacao_etiologica.png). Os critérios e categorias originais por ano estão nos descritivos e nas bases longas.","",
    paste0("A participação de MV passou de ",fmt(pct_etiol("MV",2014)),"% em 2014 para ",fmt(pct_etiol("MV",2024)),"% em 2024; MNE, de ",
      fmt(pct_etiol("MNE",2014)),"% para ",fmt(pct_etiol("MNE",2024)),"%. Essas mudanças de composição devem ser examinadas junto aos critérios e à qualidade de classificação; não comprovam uma mudança dos agentes circulantes."),"",
    "## 5. Evolução e qualidade", "",
    tabela(data.frame(Evolução=evol$categoria,Registros=evol$n,`% da coorte`=fmt(100*evol$n/R$n),check.names=FALSE)),
    paste0("Evolução desconhecida: ",R$evolucao_desconhecida,"/",R$n," (",fmt(100*R$evolucao_desconhecida/R$n),
      "%). Em 2024: 32/162 (19,8%). Por isso, o resumo de óbito por meningite é secundário: ",R$obitos_meningite,"/",R$n," = ",
      fmt(100*R$obitos_meningite/R$n),"% entre todos, e ",R$obitos_meningite,"/",R$n-R$evolucao_desconhecida," = ",
      fmt(100*R$obitos_meningite/(R$n-R$evolucao_desconhecida)),"% entre evoluções conhecidas. Nenhuma razão é apresentada como letalidade completa."),"",
    paste0("A mediana do intervalo entre sintomas e notificação, entre datas válidas e intervalos não negativos, foi ",R$intervalo_mediana,
      " dias. Esse intervalo não equivale a tempo até confirmação diagnóstica. A qualidade por campo/ano, com seu universo, está no pacote e em D06."),"",
    "## 6. Internações e carga hospitalar", "",
    "São internações/AIHs do SUS por residência e ano de processamento. Os códigos têm conceitos diferentes e são apresentados separadamente; A39 inclui infecção meningocócica além de meningite.","",
    tabela(data.frame(CID=htotal$cid_grupo,`Internações disponíveis (2014–2024)`=htotal$valor,check.names=FALSE)),
    "A39 ganhou perfil por sexo e totais anuais nesta retomada. G00 e A87 tinham totais derivados de marginais oficiais conservados. A consulta geral ainda falhou; contagens G01/G02/G03 permanecem ausentes. Não apresentar a soma das séries disponíveis como todas as internações por meningite.","",
    paste0("Nas ",n_folhas_obitos_retornados," folhas CID com valores de óbito retornados, registram-se **",fmt(n_obitos_retornados,0),
      " altas por óbito**; ",paste(ob_ausentes,collapse=", ")," permanece sem linha/sem valor. Não é um total completo demonstrado dos seis grupos. Para as seis folhas selecionadas, os valores aprovados nominais somam R$ ",
      fmt(sum(hospital$valor[hospital$medida=="valor_total"]),2)," e os dias de permanência somam ",
      fmt(sum(hospital$valor[hospital$medida=="dias_permanencia"]),0),". Os dias foram recuperados nesta rodada. Os indicadores têm universos administrativos próprios; não representam custo econômico total e não foram calculadas médias com denominadores incompletos."),"",
    paste0("G00 passou de ",n_hosp("G00",2014)," internações em 2014 para ",n_hosp("G00",2024)," em 2024; A87, de ",n_hosp("A87",2014)," para ",
      n_hosp("A87",2024),". A composição das séries disponíveis difere da trajetória do total de notificações. Isso permite investigar perfil assistencial e registro, sem demonstrar gravidade, troca de agentes ou vínculo entre os sistemas."),"",
    "[Figura 5 — internações disponíveis](figuras/F05_internacoes_disponiveis.png). Perfis de idade/sexo e outras medidas ficam no CSV SIH, com `tipo_tabela` e unidade.","",
    "## 7. Óbitos selecionados no SIM", "",
    tabela(data.frame(Ano=T$sim_totais$ano,`Óbitos por causa básica selecionada`=T$sim_totais$valor,check.names=FALSE)),
    "O conjunto registra 202 óbitos por causa básica G00–G03/A39/A87, por residência em Salvador, na fonte de registro BA. A cobertura de óbitos registrados em outras UFs não foi demonstrada. Não são os mesmos óbitos identificados no SINAN e não foi calculada uma razão SIM/SINAN de letalidade.","",
    "## 8. Contexto vacinal", "",
    tabela(data.frame(Ano=pni$ano,Indicador=pni$indicador_fonte,`Cobertura (%)`=fmt(pni$cobertura_percentual,2),
      Método=ifelse(pni$sistema=="PNI_RNDS_individual","RNDS/residência","Legado/registro"),check.names=FALSE)),
    "Há 17 observações e 27 lacunas. As duas tentativas adicionais de BCG legado falharam; MenC e pneumocócica não foram retomadas após essa falha, conforme a interrupção planejada. Valores ausentes permanecem ausentes. Penta legado tem município do registro com residência não confirmada; RNDS usa residência e componentes oficiais. Definições/esquemas estão no dicionário e no módulo PNI.","",
    "BCG de 14,46% em 2023 e 38,95% em 2024 exige auditoria de registro/integração antes de interpretação epidemiológica. Conjugadas atuais não foram renomeadas como produtos exclusivos MenC ou PCV10. Não conectar as eras nem inferir eficácia vacinal a partir destas séries.","",
    "[Figura 6 — cobertura vacinal registrada](figuras/F06_cobertura_vacinal_registrada.png).", "",
    "## 9. O que está apto e o que continua condicionado", "",
    "- Núcleo SINAN/população: apto para ocorrência registrada, perfis, taxas anuais/específicas e qualidade dos campos, dentro dos filtros documentados.",
    "- SIH: apto com limites; há séries e medidas disponíveis, mas internações gerais, G00 sexo e A39 idade continuam pendentes.",
    "- SIM: apto para descrever o conjunto selecionado de registro BA; abrangência nacional por residência ainda não demonstrada.",
    "- PNI: contexto descritivo por método/indicador; não sustenta série completa 2014–2024 nem análise de eficácia.",
    "- Letalidade, subtipos raros, campos secundários e inferência causal exigem perguntas e controles adicionais; nenhum teste multivariável foi feito nesta entrega.","",
    "## 10. Rastreabilidade e validação", "",
    paste0("Foram aprovados ",sum(qc$aprovado)," de ",nrow(qc)," controles registrados na versão entregue. A releitura de RDS/CSVs, chaves, somas, populações, benchmark e derivações foi conferida. A inspeção das figuras é registrada em `controle/QA_VISUAL.json`, com os hashes dos arquivos efetivamente revisados."),"",
    "O pacote principal é `../meningites_salvador_analitica.rds`. Bases: `../dados/`; definições/fontes/cobertura: `../documentacao/`; código: `../scripts/`; controles/hashes: `../controle/`. O CSV `descritivos.csv` reúne D01–D10, sem substituir os sete CSVs analíticos. Os casos mínimos permanecem somente no RDS local; Git recebe código, documentação e agregados revisados.","",
    "Os brutos e a versão 09/10 foram preservados. A execução R padrão é offline e reutiliza respostas rastreáveis; executar novamente o controlador não dispara consultas externas.")
  writeLines(texto,destino,useBytes=TRUE)
}
