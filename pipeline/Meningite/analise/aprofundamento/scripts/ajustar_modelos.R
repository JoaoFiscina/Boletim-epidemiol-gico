# Modelos exploratórios. Fonte aprovada permanece imutável; nenhum modelo contém microdados.
ajustar_modelos <- function(base, config) {
  broad <- c("<1", "1-4", "5-19", "20-59", "60+")
  mapa <- unlist(config$faixas_amplas)
  linhas <- list(); diagn <- list(); estim <- list(); checks <- list(); objetos <- list()
  validar <- function(id, ok, detalhe) {
    checks[[length(checks)+1L]] <<- data.frame(id=id, aprovado=isTRUE(ok), detalhe=detalhe)
  }
  periodo <- function(a) ifelse(a<=2019,"2014-2019",ifelse(a<=2021,"2020-2021","2022-2024"))
  fonte <- base$SINAN$casos_minimos_locais
  grupo <- function(e) ifelse(e=="MV","Viral",ifelse(e=="MNE","Nao especificada",
    ifelse(e %in% c("MM","MM+MCC","MCC"),"Meningococica",ifelse(e %in% c("MB","MH","MP"),"Outras bacterianas",
    ifelse(e=="MTBC","Tuberculosa",ifelse(e=="MOE","Outra etiologia","Residual"))))))
  casos <- data.frame(ano=fonte$ano_sintomas, sexo=fonte$sexo_id, faixa=fonte$faixa_id,
    faixa_ampla=unname(mapa[fonte$faixa_id]), etiologia=fonte$etiologia, grupo=grupo(fonte$etiologia),
    evolucao=fonte$evolucao_codigo, stringsAsFactors=FALSE)
  pop <- base$populacao$basica
  pop <- data.frame(ano=pop$ano,sexo=pop$sexo_id,faixa=pop$faixa_id,populacao=pop$populacao)
  grade <- function(ca, ampla=TRUE, anos=config$anos) {
    pp <- pop[pop$ano %in% anos,]
    pp$faixa_modelo <- if(ampla) unname(mapa[pp$faixa]) else pp$faixa
    pp <- aggregate(populacao~ano+sexo+faixa_modelo,pp,sum)
    cc <- ca[ca$sexo %in% c("F","M") & ca$ano %in% anos,]
    cc$faixa_modelo <- if(ampla) cc$faixa_ampla else cc$faixa
    nn <- aggregate(rep(1,nrow(cc)),cc[c("ano","sexo","faixa_modelo")],sum); names(nn)[4]<-"n"
    out <- merge(pp,nn,by=c("ano","sexo","faixa_modelo"),all.x=TRUE,sort=TRUE)
    # Zero é derivado de coorte completa e grade populacional observada.
    out$n[is.na(out$n)] <- 0L
    out$sexo <- factor(out$sexo,levels=c("F","M"))
    out$faixa_modelo <- factor(out$faixa_modelo,levels=if(ampla)broad else config$faixas)
    out$ano_f <- factor(out$ano); out
  }
  coeficientes <- function(fit, id, escala="RR", cov=NULL, metodo=NULL, n=NULL) {
    b <- coef(fit); V <- if(is.null(cov)) vcov(fit) else cov
    se <- sqrt(diag(V)); quasi <- grepl("quasi",fit$family$family)
    q <- if(quasi && is.null(cov)) qt(.975,fit$df.residual) else qnorm(.975)
    p <- if(quasi && is.null(cov)) 2*pt(-abs(b/se),fit$df.residual) else 2*pnorm(-abs(b/se))
    d <- data.frame(modelo=id,termo=names(b),escala=escala,estimativa=exp(b),
      ic95_inferior=exp(b-q*se),ic95_superior=exp(b+q*se),p_exploratorio=p,
      log_estimativa=unname(b),erro_padrao=unname(se),n_observacoes=if(is.null(n))nobs(fit) else n,
      metodo=if(is.null(metodo))fit$family$family else metodo,row.names=NULL)
    # Intercepto de contagem/odds não é razão entre grupos.
    d$escala[d$termo=="(Intercept)"] <- if(escala=="OR")"odds_referencia" else "taxa_referencia_por_habitante_ano"
    estim[[length(estim)+1L]] <<- d; d
  }
  compactar <- function(fit) list(formula=paste(deparse(formula(fit)),collapse=" "),
    familia=fit$family$family,coeficientes=coef(fit),covariancia=vcov(fit),
    theta=if(inherits(fit,"negbin"))fit$theta else NA_real_,convergiu=fit$converged,
    deviance=fit$deviance,df_residual=fit$df.residual,n=nobs(fit))
  selecionar <- function(d, f, id) {
    warnings <- character()
    fitp <- glm(f,data=d,family=poisson())
    phi <- sum(residuals(fitp,type="pearson")^2)/fitp$df.residual
    gof <- pchisq(sum(residuals(fitp,type="pearson")^2),fitp$df.residual,lower.tail=FALSE)
    fit <- fitp; escolha <- "Poisson"; razao <- "Sem sobredispersao no diagnostico Pearson (phi>1 e p<0.05)"
    fitnb <- NULL
    if(phi>1 && gof<.05) {
      fitnb <- tryCatch(withCallingHandlers(MASS::glm.nb(f,data=d,control=glm.control(maxit=100)),
        warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart("muffleWarning")}),error=function(e)NULL)
      dnb <- if(is.null(fitnb))NA_real_ else sum(residuals(fitnb,type="pearson")^2)/fitnb$df.residual
      if(!is.null(fitnb) && isTRUE(fitnb$converged) && is.finite(fitnb$theta) && fitnb$theta>0 &&
         all(is.finite(coef(fitnb))) && !length(warnings) && dnb<=2) {
        fit <- fitnb; escolha <- "Binomial negativa"; razao <- "Sobredispersao Poisson; NB convergente, sem aviso, dispersao residual <=2"
      } else {fit <- glm(f,data=d,family=quasipoisson()); escolha <- "Quasi-Poisson";
        razao <- "Sobredispersao; NB nao satisfez os criterios diagnosticos"}
    }
    dr <- sum(residuals(fit,type="pearson")^2)/fit$df.residual
    diagn[[length(diagn)+1L]] <<- data.frame(modelo=id,familia=escolha,n=nrow(d),n_eventos=sum(d$n),
      parametros=length(coef(fit)),phi_poisson=phi,pearson_gof_p=gof,phi_final=dr,
      theta=if(inherits(fit,"negbin"))fit$theta else NA_real_,aic=if(grepl("quasi",fit$family$family))NA_real_ else AIC(fit),
      convergiu=fit$converged,criterio=razao,avisos=paste(warnings,collapse=" | "))
    validar(paste0(id,"_ajuste"),fit$converged && all(is.finite(coef(fit))) && all(is.finite(vcov(fit))),"Convergencia, coeficientes e matriz de covariancia finitos")
    objetos[[id]] <<- compactar(fit)
    fit
  }
  f <- n ~ sexo + faixa_modelo + ano_f + offset(log(populacao))
  g <- grade(casos)
  validar("modelo_grade110",nrow(g)==110 && sum(g$n)==1975 && all(g$populacao>0),"110 estratos; 1975 registros com sexo conhecido")
  fit <- selecionar(g,f,"taxas_principal")
  coeficientes(fit,"taxas_principal")
  fq <- glm(f,data=g,family=quasipoisson())
  coeficientes(fq,"taxas_sensibilidade_quasi")
  objetos$taxas_sensibilidade_quasi <- compactar(fq)
  g$ajustado <- fitted(fit); g$residuo_pearson <- residuals(fit,type="pearson")
  linhas$grade_modelo_taxas <- g
  cenarios <- list(sem_MCC=list(ca=casos[casos$etiologia!="MCC",],anos=config$anos,ampla=TRUE),
    sem_2014=list(ca=casos,anos=config$anos[config$anos!=2014],ampla=TRUE),
    sem_2023_2024=list(ca=casos,anos=config$anos[config$anos<=2022],ampla=TRUE),
    faixas_originais=list(ca=casos,anos=config$anos,ampla=FALSE))
  for(nm in names(cenarios)) {s<-cenarios[[nm]];d<-grade(s$ca,s$ampla,s$anos)
    ff<-selecionar(d,f,paste0("taxas_",nm));coeficientes(ff,paste0("taxas_",nm))}
  # Interação é diagnóstico exploratório, não regra de seleção pela significância.
  fint <- n ~ sexo * faixa_modelo + ano_f + offset(log(populacao))
  int <- if(inherits(fit,"negbin")) MASS::glm.nb(fint,data=g,control=glm.control(maxit=100)) else
    glm(fint,data=g,family=fit$family)
  if(isTRUE(int$converged) && all(is.finite(coef(int)))) {
    coeficientes(int,"taxas_interacao_sexo_idade")
    objetos$taxas_interacao_sexo_idade <- compactar(int)
    # Quasi exige teste F; modelos com likelihood usam qui-quadrado.
    av <- if(grepl("quasi",fit$family$family)) anova(fit,int,test="F") else
      if(inherits(fit,"negbin")) anova(fit,int) else anova(fit,int,test="Chisq")
    pp <- grep("Pr\\(",names(av),value=TRUE)
    linhas$teste_interacao <- data.frame(teste=if(grepl("quasi",fit$family$family))"F" else "LRT",
      df=length(coef(int))-length(coef(fit)),p_exploratorio=if(length(pp))av[[pp[1]]][nrow(av)] else NA_real_,
      interpretacao="Heterogeneidade exploratoria M/F por idade; testes multiplos sem ajuste")
  }
  # Sazonalidade: exposição mensal aproximada em habitantes-ano, ponderada por dias.
  mm <- base$SINAN$mensal; mm<-mm[order(mm$ano,mm$mes),c("ano","mes","n")]
  pt <- base$populacao$total
  mm$pop_ano <- pt$populacao[match(mm$ano,pt$ano)]
  inicio <- as.Date(sprintf("%04d-%02d-01",mm$ano,mm$mes))
  prox <- as.Date(sprintf("%04d-%02d-01",mm$ano+(mm$mes==12),mm$mes%%12+1))
  diasano <- as.numeric(as.Date(paste0(mm$ano+1,"-01-01"))-as.Date(paste0(mm$ano,"-01-01")))
  mm$exposicao <- mm$pop_ano*as.numeric(prox-inicio)/diasano
  mm$periodo <- factor(periodo(mm$ano),levels=c("2014-2019","2020-2021","2022-2024"))
  mm$t <- seq_len(nrow(mm))/12; mm$seno <- sin(2*pi*mm$mes/12);mm$cosseno <- cos(2*pi*mm$mes/12)
  mm$populacao <- mm$exposicao
  fm <- selecionar(mm,n~t+periodo+seno+cosseno+offset(log(populacao)),"mensal_harmonico")
  # fitdf não é o número de harmônicos; esse ajuste é próprio de ARMA.
  # Diagnóstico aproximado de resíduos GLM, com fitdf=0 e ACF registrada.
  rr <- residuals(fm,type="pearson"); lb <- Box.test(rr,lag=12,type="Ljung-Box",fitdf=0)
  Vhac <- sandwich::NeweyWest(fm,lag=12,prewhite=FALSE,adjust=TRUE)
  objetos$mensal_harmonico$covariancia_HAC <- Vhac
  objetos$mensal_harmonico$config_HAC <- list(lag=12,prewhite=FALSE,adjust=TRUE,ordem="ano,mes")
  coeficientes(fm,"mensal_harmonico_HAC",cov=Vhac,metodo="HAC Newey-West lag12, sem prewhitening, ajuste n/(n-k)")
  idx <- c("seno","cosseno"); b<-coef(fm)[idx];vv<-Vhac[idx,idx,drop=FALSE]
  teste <- as.numeric(t(b)%*%solve(vv,b))
  linhas$diagnostico_mensal <- data.frame(n_meses=nrow(mm),ljung_box_lag=12,ljung_box_fitdf=0,ljung_box_p=lb$p.value,
    autocorrelacao_lag1=acf(rr,plot=FALSE,lag.max=12)$acf[2],wald_harmonico_HAC=teste,
    gl_harmonico=2,p_harmonico_exploratorio=pchisq(teste,2,lower.tail=FALSE),
    cautela="Ljung-Box aproximado para residuosGLM fitdf0; HAC trata dependencia das estimativas, nao garante adequacao da media; exposicao mensal aproximada")
  # Predição padronizada do componente sazonal: mesmo período, tendência e exposição.
  nd <- mm[1:12,];nd$mes<-1:12;nd$t<-mean(mm$t);nd$periodo<-factor(rep("2014-2019",12),levels=levels(mm$periodo))
  nd$populacao<-100000/12;nd$seno<-sin(2*pi*nd$mes/12);nd$cosseno<-cos(2*pi*nd$mes/12)
  X <- model.matrix(delete.response(terms(fm)),nd,contrasts.arg=fm$contrasts)
  lp <- drop(X%*%coef(fm))+log(nd$populacao);se<-sqrt(rowSums((X%*%Vhac)*X))
  linhas$sazonalidade_ajustada <- data.frame(mes=nd$mes,estimativa=exp(lp),ic95_inferior=exp(lp-1.96*se),ic95_superior=exp(lp+1.96*se),
    unidade="registros previstos por 100mil em 1/12 ano",referencia="tendencia media; periodo2014-2019")
  mm$ajustado<-fitted(fm);mm$residuo_pearson<-rr;linhas$grade_modelo_mensal<-mm
  validar("sazonalidade_132",nrow(mm)==132 && sum(mm$n)==1976 && all(is.finite(Vhac)),"132 meses, coorte integral, covariancia HAC finita")
  # Óbito por meningite entre casos com evolução conhecida; associação condicionada ao registro.
  dd <- casos[casos$sexo %in% c("F","M") & casos$grupo!="Residual",]
  dd$sexo<-factor(dd$sexo,levels=c("F","M"));dd$idade<-factor(dd$faixa_ampla,levels=broad)
  dd$grupo<-factor(dd$grupo,levels=c("Viral","Nao especificada","Meningococica","Outras bacterianas","Tuberculosa","Outra etiologia"))
  dd$periodo<-factor(periodo(dd$ano),levels=c("2014-2019","2020-2021","2022-2024"))
  dd$conhecido <- dd$evolucao %in% c("1","2","3")
  dd$evento <- as.integer(dd$evolucao=="2")
  dk <- dd[dd$conhecido,];fd<-evento~sexo+idade+grupo+periodo
  tab <- as.data.frame(table(dk$grupo,dk$evento));names(tab)<-c("grupo","evento","n")
  parametros <- ncol(model.matrix(fd,dk))-1
  gate <- sum(dk$evento)/parametros>=10 && all(tab$n>0)
  linhas$elegibilidade_modelo_obito <- data.frame(n_elegivel=nrow(dd),n_conhecido=nrow(dk),eventos=sum(dk$evento),
    parametros_excluindo_intercepto=parametros,eventos_por_parametro=sum(dk$evento)/parametros,
    executar=gate,criterio=">=10 eventos por parametro e ausencia de celula zero evento/grupo; criterio operacional, nao prova de validade")
  # Agregação por covariáveis antes do ajuste e da persistência; sem chaves individuais.
  fitob <- function(da,id) {
    da$n<-1L;da$d<-da$evento
    ag<-aggregate(cbind(d,n)~sexo+idade+grupo+periodo,da,sum)
    fo <- glm(cbind(d,n-d)~sexo+idade+grupo+periodo,data=ag,family=binomial())
    Xm <- model.matrix(fo)[ag$d>0 & ag$d<ag$n,,drop=FALSE]
    # Cada célula mista exige Xb=0 para uma direção separadora. Rank completo
    # implica b=0; é condição suficiente para afastar separação nesta fórmula.
    validar(paste0(id,"_sem_separacao"),qr(Xm)$rank==ncol(Xm),"Posto completo nas covariaveis das celulas com evento e nao evento")
    coeficientes(fo,id,"OR",n=sum(ag$n));objetos[[id]]<<-compactar(fo)
    if(id=="obito_evolucao_conhecida") {
      qob<-glm(cbind(d,n-d)~sexo+idade+grupo+periodo,data=ag,family=quasibinomial())
      coeficientes(qob,"obito_sensibilidade_quasi","OR",n=sum(ag$n))
      objetos$obito_sensibilidade_quasi<<-compactar(qob)
      linhas$diagnostico_obito<<-data.frame(n_celulas=nrow(ag),n_mistas=nrow(Xm),rank_mistas=qr(Xm)$rank,
        rank_modelo=ncol(Xm),phi_pearson=sum(residuals(fo,type="pearson")^2)/fo$df.residual,
        nota="Celulas esparsas; phi descritivo; quasi como sensibilidade, sem teste de ajuste assintotico")
    }
    validar(paste0(id,"_finito"),fo$converged && all(is.finite(vcov(fo))) && all(abs(coef(fo))<20),"Sem estimativas divergentes; IC Wald exploratorios")
    ag$modelo<-id;ag
  }
  if(gate) {
    linhas$grade_modelo_obito <- fitob(dk,"obito_evolucao_conhecida")
    db<-dd;db$evento[!db$conhecido]<-0L
    linhas$grade_obito_ignorados_nao_evento <- fitob(db,"obito_ignorados_nao_evento")
    db$evento[!db$conhecido]<-1L
    linhas$grade_obito_ignorados_evento <- fitob(db,"obito_ignorados_evento")
  }
  coef <- do.call(rbind,estim);dg<-do.call(rbind,diagn);val<-do.call(rbind,checks)
  if(any(!val$aprovado))stop("Validacao dos modelos falhou: ",paste(val$id[!val$aprovado],collapse=", "))
  list(tabelas=linhas,coeficientes=coef,diagnosticos=dg,validacao=val,modelos=objetos,
    decisoes=list(exploratorio=TRUE,poisson_sobredispersao="phi>1 e Pearson p<0.05",nb_disp_residual_max=2,
      idade_principal=broad,sexo_referencia="F",ano_referencia=2014,
      exposicao="soma populacoes anuais aproxima habitantes-ano",intervalos="Wald; t para quasi; HAC mensal",
      multiplos_testes="p exploratorios, sem ajuste; interpretacao pelas estimativas e IC",sem_causalidade=TRUE,
      modelos_obito="OR condicionadas aos registros com evolucao conhecida; ignorados como cenarios extremos"))
}
