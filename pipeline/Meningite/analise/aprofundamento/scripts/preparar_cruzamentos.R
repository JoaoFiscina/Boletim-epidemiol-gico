# Offline; source() somente define preparar_cruzamentos.
preparar_cruzamentos <- function(raiz, config, destino) {
  stopifnot(requireNamespace('digest',quietly=TRUE))
  sha <- function(p){con<-file(p,'rb');on.exit(close(con));digest::digest(readBin(con,'raw',n=file.info(p)$size),algo='sha256',serialize=FALSE)}
  raiz<-normalizePath(raiz,winslash='/',mustWork=TRUE)
  path<-function(p)file.path(raiz,gsub('\\','/',p,fixed=TRUE))
  V<-data.frame(controle=character(),observado=character(),esperado=character(),aprovado=logical(),bloqueante=logical(),detalhe=character())
  ck<-function(id,obs,esp,ok=identical(obs,esp),detail='',block=TRUE){V<<-rbind(V,data.frame(controle=id,observado=paste(obs,collapse='|'),esperado=paste(esp,collapse='|'),aprovado=isTRUE(ok),bloqueante=block,detalhe=detail))}
  gate<-function(){if(any(!V$aprovado&V$bloqueante))stop('Controle bloqueante: ',paste(V$controle[!V$aprovado&V$bloqueante],collapse=', '))}
  ck('hash_entrada',sha(path(config$fonte_rds)),config$fonte_sha256);gate()
  m<-readRDS(path(config$fonte_rds));z<-m$SINAN$casos_minimos_locais;p<-m$populacao$basica
  anos<-as.integer(unlist(config$anos));faixas<-as.character(unlist(config$faixas));b<-as.numeric(config$taxa_base);cl<-as.numeric(config$nivel_confianca);a<-1-cl
  ck('config_offline',identical(config$coletar,FALSE),TRUE);ck('coorte',nrow(z),as.integer(config$n_coorte));ck('sexo_ignorado',sum(!z$sexo_codigo%in%c('M','F')),1L)
  ck('etiologias6naocanonicas',sum(!is.na(z$etiologia_codigo)&!z$etiologia_codigo%in%sprintf('%02d',1:10)),6L)
  ck('etiologias2vazias',sum(is.na(z$etiologia_codigo)),2L)
  ck('evolucoes144desconhecidas',sum(!z$evolucao_codigo%in%as.character(1:3)),144L)
  ck('benchmark572referencias',sum(!is.na(m$SINAN$comparacao_tabnet$n_tabnet)),572L)
  ck('benchmark6extrasNA',sum(is.na(m$SINAN$comparacao_tabnet$n_tabnet))==6&&all(is.na(m$SINAN$comparacao_tabnet$diferenca_br_menos_tabnet[is.na(m$SINAN$comparacao_tabnet$n_tabnet)])),TRUE)
  ck('origem_municipio',all(z$codigo_municipio==as.character(config$municipio)),TRUE)
  ck('chave_tecnica',anyDuplicated(z$chave_tecnica),0L)
  periodos<-config$periodos
  if(is.data.frame(periodos))periodos<-lapply(seq_len(nrow(periodos)),function(i)list(id=periodos$id[i],anos=unlist(periodos$anos[[i]])))
  yper<-setNames(rep(NA_character_,length(anos)),as.character(anos))
  py<-unlist(lapply(periodos,function(x)as.integer(unlist(x$anos))))
  ck('periodos_disjuntos',anyDuplicated(py),0L);ck('periodos_cobrem_anos',setequal(py,anos),TRUE)
  for(x in periodos)yper[as.character(unlist(x$anos))]<-as.character(x$id)
  period_ids<-vapply(periodos,function(x)as.character(x$id),character(1))
  z$ano<-z$ano_sintomas;z$sexo<-z$sexo_id;z$idade<-z$faixa_id;z$periodo<-unname(yper[as.character(z$ano)])
  p$sexo<-as.character(p$sexo_id);p$idade<-as.character(p$faixa_id);p$periodo<-unname(yper[as.character(p$ano)])
  mapa<-unlist(config$faixas_amplas);z$faixa_ampla<-unname(mapa[z$idade]);p$faixa_ampla<-unname(mapa[p$idade]);amplas<-unique(unname(mapa[faixas]))
  ck('mapa_amplo_pop',all(!is.na(p$faixa_ampla)),TRUE);ck('mapa_amplo_casos',all(!is.na(z$faixa_ampla)),TRUE)
  ck('pop_242',nrow(p),242L);ck('pop_positiva',all(p$populacao>0&is.finite(p$populacao)),TRUE)
  key<-function(d,cols)do.call(paste,c(lapply(d[cols],as.character),sep='\034'))
  ck('pop_chaves',anyDuplicated(key(p,c('ano','sexo','idade'))),0L)
  grupos<-c('MV','MNE','Bacterianas_MB_MH_MP','Meningococica_MCC_MM','MTBC','MOE','Vazio_nao_canonico')
  z$grupo<-rep('Vazio_nao_canonico',nrow(z));z$grupo[z$etiologia=='MV']<-'MV';z$grupo[z$etiologia=='MNE']<-'MNE'
  z$grupo[z$etiologia%in%c('MB','MH','MP')]<-'Bacterianas_MB_MH_MP';z$grupo[z$etiologia%in%c('MCC','MM','MM+MCC')]<-'Meningococica_MCC_MM'
  z$grupo[z$etiologia=='MTBC']<-'MTBC';z$grupo[z$etiologia=='MOE']<-'MOE'
  ck('residual_8',sum(z$grupo=='Vazio_nao_canonico'),8L);ck('MCC19',sum(z$etiologia=='MCC'),19L);ck('MNE442',sum(z$etiologia=='MNE'),442L)
  z$criterio_categoria<-as.character(z$criterio);z$criterio_categoria[is.na(z$criterio_categoria)]<-'Vazio'
  criterios<-unique(c(as.character(m$SINAN$mapa_criterio$categoria),'Em branco',z$criterio_categoria))
  dom<-list(ano=as.character(anos),periodo=period_ids,idade=faixas,sexo=c('F','M'),faixa_ampla=amplas,grupo=grupos,criterio_categoria=criterios)
  contar<-function(d,axes){
    if(!length(axes))return(data.frame(n=nrow(d)))
    if(!nrow(d)){o<-as.data.frame(setNames(lapply(axes,function(x)character()),axes));o$n<-integer();return(o)}
    dd<-d[axes];dd[]<-lapply(dd,as.character);o<-aggregate(rep(1L,nrow(dd)),dd,sum);names(o)[ncol(o)]<-'n';o
  }
  grade<-function(axes,d=d,dominio=dom){
    if(!length(axes))return(data.frame(n=nrow(d),status='observado'))
    g<-expand.grid(dominio[axes],KEEP.OUT.ATTRS=FALSE,stringsAsFactors=FALSE)
    o<-contar(d,axes);h<-match(key(g,axes),key(o,axes));g$n<-o$n[h];g$status<-ifelse(is.na(h),'zero_derivado_coorte','observado');g$n[is.na(h)]<-0L;g
  }
  ci_pois<-function(n,d){lo<-ifelse(n==0,0,qchisq(a/2,2*n)/2);hi<-qchisq(1-a/2,2*(n+1))/2;cbind(lo/d*b,hi/d*b)}
  rates<-function(d,axes,pop=p,label=''){
    if('sexo'%in%axes)d<-d[d$sexo%in%c('F','M'),,drop=FALSE]
    g<-grade(axes,d)
    pax<-intersect(axes,c('ano','periodo','sexo','idade','faixa_ampla'))
    if(length(pax)){
      expo<-aggregate(pop$populacao,lapply(pop[pax],as.character),sum);names(expo)[ncol(expo)]<-'exposicao'
      ck(paste0('join_unico_',label),anyDuplicated(key(expo,pax)),0L)
      h<-match(key(g,pax),key(expo,pax));g$populacao<-expo$exposicao[h]
    }else g$populacao<-sum(pop$populacao)
    ck(paste0('denominadores_',label),all(!is.na(g$populacao)&g$populacao>0),TRUE)
    g$taxa<-g$n/g$populacao*b;ci<-ci_pois(g$n,g$populacao);g$ic_inferior<-ci[,1];g$ic_superior<-ci[,2]
    denomaxes<-if(any(c('grupo','criterio_categoria')%in%axes))setdiff(axes,c('grupo','criterio_categoria')) else intersect(axes,c('ano','periodo'))
    if(length(denomaxes)){nc<-contar(d,denomaxes);g$N_estrato<-nc$n[match(key(g,denomaxes),key(nc,denomaxes))];g$N_estrato[is.na(g$N_estrato)]<-0L}else g$N_estrato<-nrow(d)
    g$proporcao<-ifelse(g$N_estrato>0,g$n/g$N_estrato,NA_real_)
    g$universo_proporcao<-if(length(denomaxes))paste('Todos os registros elegiveis em',paste(denomaxes,collapse='x')) else 'Todos os registros elegiveis do periodo integral'
    g$unidade_taxa<-if('ano'%in%axes)'por_100mil_habitantes' else 'por_100mil_habitantes_ano'
    g$metodo_ic<-'Poisson_exato';g
  }
  tabelas<-list()
  tabelas$periodo_idade<-rates(z,c('periodo','idade'),label='periodo_idade')
  tabelas$periodo_faixa_ampla<-rates(z,c('periodo','faixa_ampla'),label='periodo_ampla')
  # Pesos fixos internos; ambos sexos e todos os anos da fonte congelada.
  std<-aggregate(p$populacao,list(idade=p$idade),sum);std<-std[match(faixas,std$idade),];names(std)[2]<-'populacao_padrao';std$peso<-std$populacao_padrao/sum(std$populacao_padrao)
  ck('pesos_soma1',abs(sum(std$peso)-1)<1e-12,TRUE);tabelas$pesos_padrao<-std
  ff<-function(n,e,w){q<-w/e;r<-sum(q*n);v<-sum(q^2*n);wm<-max(q)
    lo<-if(r==0)0 else qgamma(a/2,shape=r*r/v,scale=v/r)
    hi<-qgamma(1-a/2,shape=(r+wm)^2/(v+wm^2),scale=(v+wm^2)/(r+wm))
    c(taxa=r*b,ic_inferior=lo*b,ic_superior=hi*b,variancia=v*b*b)
  }
  # Testes de formula: estrato unico coincide com Poisson; todos zero tem limite superior positivo.
  pp<-stats::poisson.test(7,T=1000,r=7/1000,conf.level=cl)$conf.int*b
  test<-ff(7,1000,1);ck('FayFeuer_1estrato_Poisson',max(abs(test[2:3]-pp))<1e-9,TRUE)
  zer<-ff(c(0,0),c(1000,2000),c(.4,.6));ck('FayFeuer_zeros',zer[1]==0&&zer[2]==0&&is.finite(zer[3])&&zer[3]>0,TRUE)
  # Parametrizacao equivalente usando taxa especifica e variancia por pesos, conforme fonte epitools.
  nn<-c(10,0,3);ee<-c(10000,2000,8000);ww<-c(.2,.3,.5);d0<-sum(ww*nn/ee);v0<-sum(ww^2*nn/ee^2);wm0<-max(ww/ee)
  ref<-c(d0,qgamma(a/2,d0^2/v0,scale=v0/d0),qgamma(1-a/2,(d0+wm0)^2/(v0+wm0^2),scale=(v0+wm0^2)/(d0+wm0)))*b
  ck('FayFeuer_equacao_referencia',max(abs(ff(nn,ee,ww)[1:3]-ref))<1e-9,TRUE)
  if(requireNamespace('epitools',quietly=TRUE)){
    refpkg<-epitools::ageadjust.direct(nn,ee,stdpop=ww,conf.level=cl)
    ck('FayFeuer_epitools_instalado',max(abs(ff(nn,ee,ww)[1:3]-unname(refpkg[c('adj.rate','lci','uci')])*b))<1e-9,TRUE)
  }
  standardized<-function(d,pop,axis,label){
    t<-rates(d,c(axis,'idade'),pop,label);out<-list()
    for(id in unique(t[[axis]])){
      h<-t[t[[axis]]==id,];h<-h[match(faixas,h$idade),];f<-ff(h$n,h$populacao,std$peso)
      o<-data.frame(tempo=id,n=sum(h$n),populacao=sum(h$populacao),bruta=sum(h$n)/sum(h$populacao)*b,taxa=f[1],ic_inferior=f[2],ic_superior=f[3],variancia=f[4],metodo_ic='gamma_Fay_Feuer',unidade_taxa=if(axis=='ano')'por_100mil_habitantes' else 'por_100mil_habitantes_ano',row.names=NULL)
      names(o)[1]<-axis;out[[id]]<-o
    };do.call(rbind,out)
  }
  tabelas$padronizadas_anuais<-standardized(z,p,'ano','pad_ano')
  tabelas$padronizadas_periodos<-standardized(z,p,'periodo','pad_periodo')
  # Sexo x idade, por periodo e todo o periodo; denominadores especificos por sexo.
  st<-rates(z,c('periodo','sexo','idade'),label='sexo_idade_periodo')
  st0<-rates(z,c('sexo','idade'),label='sexo_idade_total');st0$periodo<-'2014-2024';st0<-st0[names(st)]
  tabelas$sexo_idade<-rbind(st,st0)
  razoes<-list()
  for(per in unique(tabelas$sexo_idade$periodo))for(age in faixas){
    x<-tabelas$sexo_idade[tabelas$sexo_idade$periodo==per&tabelas$sexo_idade$idade==age,];M<-x[x$sexo=='M',];F<-x[x$sexo=='F',]
    if(M$n+F$n==0){rr<-NA_real_;ci<-c(NA_real_,NA_real_);status<-'sem_eventos_ambos'}else{
      pt<-stats::poisson.test(c(M$n,F$n),T=c(M$populacao,F$populacao),conf.level=cl);rr<-unname(pt$estimate);ci<-pt$conf.int;status<-if(is.finite(rr)&&all(is.finite(ci)))'estimado' else 'limite_infinito_zero_em_um_sexo'
    }
    razoes[[length(razoes)+1]]<-data.frame(periodo=per,idade=age,n_M=M$n,n_F=F$n,exposicao_M=M$populacao,exposicao_F=F$populacao,taxa_M=M$taxa,taxa_F=F$taxa,razao_M_F=rr,ic_inferior=ci[1],ic_superior=ci[2],metodo_ic='Poisson_condicional_exato',status=status)
  }
  tabelas$razoes_sexo_idade<-do.call(rbind,razoes)
  tabelas$idade_etiologia<-rates(z,c('periodo','idade','grupo'),label='idade_etiologia')
  tabelas$etiologia_anual<-rates(z,c('ano','grupo'),label='etiologia_anual')
  tabelas$etiologia_criterio<-grade(c('periodo','grupo','criterio_categoria'),z)
  ec<-tabelas$etiologia_criterio
  ng<-contar(z,c('periodo','grupo'));ec$N_grupo<-ng$n[match(key(ec,c('periodo','grupo')),key(ng,c('periodo','grupo')))];ec$N_grupo[is.na(ec$N_grupo)]<-0L
  ec$proporcao_no_grupo<-ifelse(ec$N_grupo>0,ec$n/ec$N_grupo,NA_real_);tabelas$etiologia_criterio<-ec
  tabelas$criterio_periodo<-grade(c('periodo','criterio_categoria'),z)
  cp<-tabelas$criterio_periodo;nt<-contar(z,'periodo');cp$N<-nt$n[match(cp$periodo,nt$periodo)];cp$proporcao<-cp$n/cp$N;tabelas$criterio_periodo<-cp
  conhecidos<-z$criterio_estado=='valido';conhecidos[is.na(conhecidos)]<-FALSE
  nc<-contar(z[conhecidos,],'periodo');cp$N_criterio_conhecido<-nc$n[match(cp$periodo,nc$periodo)];cp$N_criterio_conhecido[is.na(cp$N_criterio_conhecido)]<-0L
  cp$proporcao_entre_conhecidos<-ifelse(cp$criterio_categoria%in%m$SINAN$mapa_criterio$categoria&cp$N_criterio_conhecido>0,cp$n/cp$N_criterio_conhecido,NA_real_)
  tabelas$criterio_periodo<-cp
  tabelas$etiologias_originais<-contar(z,c('periodo','etiologia_codigo','etiologia'))
  # aggregate() descarta NA: tabela de codigo original deve conservar brancos explicitamente.
  zo<-z;zo$etiologia_codigo[is.na(zo$etiologia_codigo)]<-'AUSENTE';tabelas$etiologias_originais<-contar(zo,c('periodo','etiologia_codigo','etiologia'))
  evo<-function(d,axes,dim){
    g<-grade(axes,d);g$N<-g$n;g$n<-NULL
    for(spec in list(c('D','2'),c('alta','1'),c('obito_outra_causa','3'))){o<-contar(d[d$evolucao_codigo%in%spec[2],],axes);h<-match(key(g,axes),key(o,axes));g[[spec[1]]]<-o$n[h];g[[spec[1]]][is.na(h)]<-0L}
    u<-contar(d[!d$evolucao_codigo%in%as.character(1:3),],axes);h<-match(key(g,axes),key(u,axes));g$U<-u$n[h];g$U[is.na(h)]<-0L;g$K<-g$N-g$U
    g$D_sobre_N<-ifelse(g$N>0,g$D/g$N,NA_real_);g$D_sobre_K<-ifelse(g$K>0,g$D/g$K,NA_real_);g$limite_extremo_inferior<-g$D_sobre_N;g$limite_extremo_superior<-ifelse(g$N>0,(g$D+g$U)/g$N,NA_real_);g$proporcao_desconhecida<-ifelse(g$N>0,g$U/g$N,NA_real_)
    ck(paste0('evolucao_fecha_',dim),all(g$alta+g$D+g$obito_outra_causa+g$U==g$N),TRUE)
    g$dimensao<-dim;g
  }
  bind<-function(L){cols<-unique(unlist(lapply(L,names)));do.call(rbind,lapply(L,function(x){for(f in setdiff(cols,names(x)))x[[f]]<-NA;x[cols]}))}
  tabelas$evolucao<-bind(list(evo(z,'ano','ano'),evo(z,'periodo','periodo'),evo(z,'idade','idade'),evo(z,'grupo','grupo'),evo(z,c('periodo','idade'),'periodo_idade'),evo(z,c('periodo','grupo'),'periodo_grupo')))
  # Atrasos: sem reconstruir datas completas ausentes no pacote minimo.
  valid<-is.finite(z$dias_sintomas_notificacao)&z$dias_sintomas_notificacao>=0&!z$sintomas_sem_data&!z$notificacao_sem_data
  d<-z$dias_sintomas_notificacao
  resumo_atraso<-function(axes,dim){g<-grade(axes,z);out<-list()
    for(i in seq_len(nrow(g))){sel<-rep(TRUE,nrow(z));for(f in axes)sel<-sel&as.character(z[[f]])==as.character(g[[f]][i]);ok<-sel&valid;v<-d[ok]
      o<-g[i,axes,drop=FALSE];o$dimensao<-dim;o$N<-sum(sel);o$n_valido<-length(v);o$n_ausente_nao_finito<-sum(sel&!is.finite(d));o$n_negativo<-sum(sel&is.finite(d)&d<0);o$n_flags_data_ausente<-sum(sel&(z$sintomas_sem_data|z$notificacao_sem_data));o$n_nao_elegivel<-o$N-o$n_valido
      o$n_gt30<-sum(v>30);o$n_gt365<-sum(v>365);q<-if(length(v))quantile(v,c(0,.25,.5,.75,.9,.95,1),names=FALSE) else rep(NA_real_,7)
      for(j in seq_along(q))o[[c('minimo','q25','mediana','q75','p90','p95','maximo')[j]]]<-q[j]
      o$n_0_1<-sum(v<=1);o$n_2_7<-sum(v>=2&v<=7);o$n_8_30<-sum(v>=8&v<=30);o$n_mais30<-sum(v>30)
      o$mediana_sem_gt30<-if(any(v<=30))median(v[v<=30]) else NA_real_;o$mediana_sem_gt365<-if(any(v<=365))median(v[v<=365]) else NA_real_;out[[i]]<-o
    };do.call(rbind,out)
  }
  tabelas$atraso<-bind(list(resumo_atraso('ano','ano'),resumo_atraso('periodo','periodo'),resumo_atraso('grupo','grupo'),resumo_atraso(c('periodo','grupo'),'periodo_grupo')))
  ecdf_rows<-list()
  for(per in period_ids)for(gr in c('Todos',grupos))for(cenario in c('integral','ate30','ate365')){
    sel<-valid&z$periodo==per;if(gr!='Todos')sel<-sel&z$grupo==gr
    v<-d[sel];if(cenario=='ate30')v<-v[v<=30];if(cenario=='ate365')v<-v[v<=365]
    if(!length(v)){ecdf_rows[[length(ecdf_rows)+1]]<-data.frame(periodo=per,grupo=gr,cenario=cenario,dias=NA_real_,n_valido=0L,acumulado=NA_integer_,F=NA_real_,status='sem_intervalos_validos')}else{
      pts<-sort(unique(c(0,v)));f<-stats::ecdf(v)(pts);ecdf_rows[[length(ecdf_rows)+1]]<-data.frame(periodo=per,grupo=gr,cenario=cenario,dias=pts,n_valido=length(v),acumulado=as.integer(round(f*length(v))),F=f,status='observado')
    }
  };tabelas$ecdf_atraso<-do.call(rbind,ecdf_rows)
  tabelas$modelo_grade<-rates(z,c('ano','sexo','faixa_ampla'),label='modelo_grade')
  tabelas$modelo_grade$log_exposicao<-log(tabelas$modelo_grade$populacao)
  ck('modelo_grade110',nrow(tabelas$modelo_grade),110L);ck('modelo_coorte_conhecida1975',sum(tabelas$modelo_grade$n),1975L)
  # Sensibilidades mantem o padrao fixo principal e mostram exatamente o universo removido.
  sensibilidades<-list();sensperiodos<-list()
  for(cen in c('principal','sem_MCC','sem_2014','sem_2023_2024','fronteira_365dias')){
    zz<-z;ppp<-p
    if(cen=='sem_MCC')zz<-zz[zz$etiologia!='MCC',]
    if(cen=='sem_2014'){zz<-zz[zz$ano!=2014,];ppp<-ppp[ppp$ano!=2014,]}
    if(cen=='sem_2023_2024'){zz<-zz[!zz$ano%in%c(2023,2024),];ppp<-ppp[!ppp$ano%in%c(2023,2024),]}
    changed<-0L
    if(cen=='fronteira_365dias'){hit<-zz$idade_codigo=='2365';hit[is.na(hit)]<-FALSE;changed<-sum(hit&zz$idade!='1-4');zz$idade[hit]<-'1-4'}
    # rates() usa grade global: restringir anos nos escenarios que mudam exposicao.
    keep<-as.character(sort(unique(ppp$ano)));oldyears<-dom$ano;dom$ano<-keep
    ss<-standardized(zz,ppp,'ano',paste0('sens_',cen));dom$ano<-oldyears
    ss$cenario<-cen;ss$coorte_cenario<-nrow(zz);ss$removidos<-nrow(z)-nrow(zz);ss$reclassificados<-changed
    sensibilidades[[cen]]<-ss
    sp<-standardized(zz,ppp,'periodo',paste0('sens_periodo_',cen));sp$cenario<-cen;sp$coorte_cenario<-nrow(zz);sp$removidos<-nrow(z)-nrow(zz);sp$reclassificados<-changed
    sp$anos_efetivos<-vapply(sp$periodo,function(per)paste(sort(unique(ppp$ano[ppp$periodo==per])),collapse=','),character(1))
    sp$n_anos_exposicao<-vapply(sp$periodo,function(per)length(unique(ppp$ano[ppp$periodo==per])),integer(1))
    sensperiodos[[cen]]<-sp
  };tabelas$sensibilidades<-do.call(rbind,sensibilidades)
  tabelas$sensibilidades_periodos<-do.call(rbind,sensperiodos)
  # Grade ampla e original nao substituem a principal; soma observada e exposicao iguais.
  ck('amplas_conservam',sum(tabelas$periodo_faixa_ampla$n)==nrow(z),TRUE)
  ck('periodo_idade_fecha',sum(tabelas$periodo_idade$n),nrow(z))
  ck('sexo_idade_fecha',sum(tabelas$sexo_idade$n[tabelas$sexo_idade$periodo=='2014-2024']),1975L)
  ck('idade_etiologia_fecha',sum(tabelas$idade_etiologia$n),nrow(z))
  ck('etiologia_anual_fecha',sum(tabelas$etiologia_anual$n),nrow(z))
  ck('etiologia_criterio_fecha',sum(tabelas$etiologia_criterio$n),nrow(z))
  ck('originais_incluem_brancos',sum(tabelas$etiologias_originais$n),nrow(z))
  ck('criterio_periodo_fecha',sum(tabelas$criterio_periodo$n),nrow(z))
  ev<-tabelas$evolucao[tabelas$evolucao$dimensao=='ano',];ck('evolucao_N1976_D190_U144',c(sum(ev$N),sum(ev$D),sum(ev$U)),c(1976L,190L,144L))
  ck('cenarios_limites',all(is.na(tabelas$evolucao$D_sobre_N)|tabelas$evolucao$D_sobre_N<=tabelas$evolucao$limite_extremo_superior),TRUE)
  ck('atrasos_categoria_fecha',all(tabelas$atraso$n_0_1+tabelas$atraso$n_2_7+tabelas$atraso$n_8_30+tabelas$atraso$n_mais30==tabelas$atraso$n_valido),TRUE)
  ck('atrasos_elegibilidade_fecha',all(tabelas$atraso$N==tabelas$atraso$n_valido+tabelas$atraso$n_nao_elegivel),TRUE)
  ecl<-tabelas$ecdf_atraso;ck('ECDF_limites',all(is.na(ecl$F)|(ecl$F>=0&ecl$F<=1)),TRUE)
  ck('sens_semMCC1957',unique(tabelas$sensibilidades$coorte_cenario[tabelas$sensibilidades$cenario=='sem_MCC']),1957L)
  ck('periodo2015_2019_sem2014',all(tabelas$sensibilidades_periodos$n_anos_exposicao[tabelas$sensibilidades_periodos$cenario=='sem_2014'&tabelas$sensibilidades_periodos$periodo=='2014-2019']==5L),TRUE)
  # Confere conservacao dos anos nas duas grades por idade/sexo e expo da grade de modelo.
  ck('modelo_exposicao_fecha',sum(tabelas$modelo_grade$populacao),sum(p$populacao))
  ck('periodo_exposicoes_idade_fecha',sum(tabelas$periodo_idade$populacao),sum(p$populacao))
  for(per in period_ids){ck(paste0('periodo_N_',per),sum(tabelas$periodo_idade$n[tabelas$periodo_idade$periodo==per]),sum(z$periodo==per));ck(paste0('periodo_expo_',per),sum(tabelas$periodo_idade$populacao[tabelas$periodo_idade$periodo==per]),sum(p$populacao[p$periodo==per]))}
  for(nm in c('periodo_idade','sexo_idade','idade_etiologia','etiologia_anual','modelo_grade'))ck(paste0('inteiros_nao_negativos_',nm),all(tabelas[[nm]]$n>=0&tabelas[[nm]]$n==floor(tabelas[[nm]]$n)),TRUE)
  # IC exato de razao equivale a Clopper-Pearson transformado pela exposicao.
  rt<-tabelas$razoes_sexo_idade;maxdiff<-0
  for(i in seq_len(nrow(rt))){if(rt$n_M[i]+rt$n_F[i]==0)next
    cpci<-stats::binom.test(rt$n_M[i],rt$n_M[i]+rt$n_F[i],conf.level=cl)$conf.int
    ci<-cpci/(1-cpci)*rt$exposicao_F[i]/rt$exposicao_M[i]
    obs<-unlist(rt[i,c('ic_inferior','ic_superior')],use.names=FALSE);finite<-is.finite(ci)&is.finite(obs)
    ck(paste0('razao_IC_',i),all(is.infinite(ci)==is.infinite(obs))&&all(abs(ci[finite]-obs[finite])<1e-9),TRUE)
  }
  gate()
  # Longos com uma linha por medida; chave inclui tabela, eixos e medida.
  crosslist<-list();estlist<-list()
  for(nm in names(tabelas)){
    t<-tabelas[[nm]];numeric_cols<-setdiff(names(t)[vapply(t,is.numeric,logical(1))],c('ano','dias'));ids<-setdiff(names(t),numeric_cols)
    for(col in numeric_cols){o<-t[ids];o$tabela<-nm;o$medida<-col;o$valor<-t[[col]];o$codigo_municipio<-as.character(config$municipio);o$snapshot_id<-'20261010';o$versao_analitica<-as.character(config$versao);o$fonte<-'SINAN_nacional_populacao_RIPSA'
      o$unidade<-if(col=='razao_M_F'||(nm=='razoes_sexo_idade'&&col%in%c('ic_inferior','ic_superior')))'razao_taxas' else if(col%in%c('taxa_M','taxa_F'))'por_100mil_habitantes_ano' else if(col%in%c('taxa','bruta','ic_inferior','ic_superior'))'ver_unidade_taxa_tabela' else if(grepl('proporcao|D_sobre|limite_extremo|^F$',col))'fracao_0_1' else if(grepl('populacao|exposicao',col))'habitantes_ano_ou_pop_anual_ver_tabela' else if(col%in%c('mediana','q25','q75','minimo','maximo','p90','p95','mediana_sem_gt30','mediana_sem_gt365'))'dias' else 'registros_ou_atributo_ver_tabela'
      o$numerador<-if('n'%in%names(t))t$n else if('D'%in%names(t))t$D else NA_real_
      o$denominador<-if('populacao'%in%names(t))t$populacao else if(col%in%c('D_sobre_K'))t$K else if('N'%in%names(t))t$N else if('n_valido'%in%names(t))t$n_valido else NA_real_
      if(col=='proporcao'&&'N_estrato'%in%names(t))o$denominador<-t$N_estrato
      if(col=='proporcao_no_grupo')o$denominador<-t$N_grupo
      if(col=='proporcao_entre_conhecidos')o$denominador<-t$N_criterio_conhecido
      if(col=='proporcao_desconhecida')o$numerador<-t$U
      if(col=='limite_extremo_superior')o$numerador<-t$D+t$U
      if(col=='F')o$numerador<-t$acumulado
      o$ic_inferior<-if('ic_inferior'%in%names(t)&&col%in%c('taxa','razao_M_F'))t$ic_inferior else NA_real_
      o$ic_superior<-if('ic_superior'%in%names(t)&&col%in%c('taxa','razao_M_F'))t$ic_superior else NA_real_
      if(col%in%c('taxa','bruta','razao_M_F','D_sobre_N','D_sobre_K','limite_extremo_inferior','limite_extremo_superior','proporcao','proporcao_no_grupo','proporcao_entre_conhecidos','proporcao_desconhecida','mediana','p90','p95'))estlist[[length(estlist)+1]]<-o else crosslist[[length(crosslist)+1]]<-o
    }
  }
  decisoes<-data.frame(id=c('padrao','gamma','razao','sexo_ignorado','grupos','evolucao','atrasos','idade','sensibilidades','modelo','longos'),regra=c('Pesos internos fixos ambossexos soma2014-24; iguais em todas sensibilidades','Fay-Feuer gamma: r=sum(w*n/e),v=sum(w^2*n/e^2),wm=max(w/e); zeros totais LI0,LSgamma(shape1,scale wm)','M/F e IC Poisson condicional exato via poisson.test; sem correcao0.5; infinitos/amboszero sinalizados','1registro ignorado fica total/idade/evolucao; excluido apenas denominador sexo/modelo','7grupos disjuntos; categoriaoriginalpreservada,6naocanonicos+2vazios nao recodificados','N,D,U,K=N-U; limites extremos nao sao IC e nao imputam os desconhecidos','Datas completas ausentes noRDS; flags/intervalo existentes; >30/>365 exploratorios, nao padraooficial','Faixasbenchmark mantidas; alternativa somentecodigo2365 para1-4, reclassificacoes explicitas','SemMCC remove19; semanos remove casos e exposicao; pesos principaisfixos','Grade110 para n~sexo+faixa_ampla+ano+offset(log(populacao)); nenhum modelo ajustado nesta frente','Tabelas largas sao contrato principal para graficos; longos identificam tabela,medida,eixos,unidade; nao somar niveis'),referencia=c('populacao_local_congelada','https://raw.githubusercontent.com/cran/epitools/master/R/ageadjust.direct.R','https://search.r-project.org/R/refmans/stats/html/poisson.test.html',rep('plano_local',8)),stringsAsFactors=FALSE)
  res<-list(tabelas=tabelas,cruzamentos_longo=bind(crosslist),estimativas_longo=bind(estlist),validacao=V,decisoes=decisoes,resumo=list(n_coorte=nrow(z),n_sexo_ignorado=1L,n_atrasos_validos=sum(valid),n_atrasos_negativos=sum(is.finite(d)&d<0),n_atrasos_nao_finitos=sum(!is.finite(d)),n_atrasos_gt30=sum(d[valid]>30),n_atrasos_gt365=sum(d[valid]>365),max_atraso=if(any(valid))max(d[valid]) else NA,fronteira_reclassificados=unique(tabelas$sensibilidades$reclassificados[tabelas$sensibilidades$cenario=='fronteira_365dias']),config=config,sha_entrada=sha(path(config$fonte_rds))))
  dir.create(destino,recursive=TRUE,showWarnings=FALSE)
  exports<-c(tabelas,list(cruzamentos_longo=res$cruzamentos_longo,estimativas_longo=res$estimativas_longo,decisoes=decisoes))
  for(nm in names(exports)){
    t<-exports[[nm]];f<-file.path(destino,paste0(nm,'.csv'));write.table(t,f,sep=config$csv$sep,dec=config$csv$dec,na=config$csv$na,quote=TRUE,row.names=FALSE,fileEncoding='UTF-8')
    classes<-vapply(t,function(x)if(is.integer(x))'integer' else if(is.numeric(x))'numeric' else if(is.logical(x))'logical' else 'character',character(1))
    back<-read.csv(f,sep=config$csv$sep,dec=config$csv$dec,na.strings=config$csv$na,fileEncoding='UTF-8',colClasses=classes,check.names=FALSE,stringsAsFactors=FALSE)
    rownames(t)<-NULL;rownames(back)<-NULL;ck(paste0('csv_releitura_',nm),isTRUE(all.equal(t,back,check.attributes=FALSE,tolerance=1e-10)),TRUE)
  }
  gate();res$validacao<-V;saveRDS(res,file.path(destino,'candidato.rds'),compress='xz')
  ck('RDS_releitura',identical(res,readRDS(file.path(destino,'candidato.rds'))),TRUE);gate();res$validacao<-V
  saveRDS(res,file.path(destino,'candidato.rds'),compress='xz');write.table(V,file.path(destino,'validacao.csv'),sep=';',quote=TRUE,row.names=FALSE,fileEncoding='UTF-8')
  report<-c('# Candidato A1-A6: cruzamentos SINAN/populacao',paste('Coorte',nrow(z),'; controles',nrow(V),'; aprovados',sum(V$aprovado)),'','Funcao preparar_cruzamentos(raiz, config, destino), sem autoexecucao ao source.','Contrato: tabelas largas nomeadas para graficos; dois longos por tabela/medida/eixos; fonte/hash/config no resumo.',paste(names(tabelas),collapse=', '),'','Padronizacao com pesos internos fixos2014-24 e ICgamma Fay-Feuer; zeros tratados por formula, sembootstrap.','RazoesM/F comPoisson condicional exato; sem0.5; casosignorados conservados emtotais.','Evolucao: N,D,U,K; cenarios extremos sao fracoes, nao IC.','Atrasos: todas perdas/extremos descritos; ECDF integral e cortes exploratorios30/365; datas nao reconstruidas.',paste('Intervalos validos',sum(valid),'; negativos',sum(is.finite(d)&d<0),'; >30',sum(d[valid]>30),'; >365',sum(d[valid]>365)),paste('Fronteira365dias: reclassificados',res$resumo$fronteira_reclassificados), 'Modelo: somentegrade pronta,110linhas; ajuste a cargo mestre.','Nenhuma figura/download/Git/alteracaofinal. Dadosnao demonstram pessoassunicas/causalidade/validadeclinica.','Referencia Fay-Feuer: https://raw.githubusercontent.com/cran/epitools/master/R/ageadjust.direct.R','Referencia razao: https://search.r-project.org/R/refmans/stats/html/poisson.test.html')
  writeLines(report,file.path(destino,'RELATORIO_CANDIDATO.md'),useBytes=TRUE);res
}
