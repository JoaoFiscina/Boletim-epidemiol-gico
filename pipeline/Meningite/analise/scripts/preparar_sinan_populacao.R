# Funcao offline. source() apenas define a funcao; nao le entradas nem grava arquivos.
preparar_sinan_populacao <- function(raiz, config, destino) {
  for (pkg in c('digest','jsonlite')) if (!requireNamespace(pkg,quietly=TRUE)) stop('Dependencia instalada necessaria: ',pkg)
  raiz <- normalizePath(raiz,winslash='/',mustWork=TRUE)
  if (!is.list(config)) stop('config deve ser lista lida do JSON central')
  anos <- as.integer(unlist(config$anos)); faixas <- as.character(unlist(config$faixas))
  municipio <- as.character(config$municipio); snapshot <- as.character(config$versao_fontes)
  versao <- as.character(config$versao_analitica); C <- config$controles
  V <- data.frame(controle=character(),observado=character(),esperado=character(),aprovado=logical(),bloqueante=logical(),detalhe=character())
  verificar <- function(id,obs,esp,ok=identical(obs,esp),bloqueante=TRUE,detalhe='') {
    V <<- rbind(V,data.frame(controle=id,observado=paste(obs,collapse='|'),esperado=paste(esp,collapse='|'),aprovado=isTRUE(ok),bloqueante=bloqueante,detalhe=detalhe,stringsAsFactors=FALSE))
  }
  barreira <- function() if(any(V$bloqueante & !V$aprovado)) stop('Controles bloqueantes falharam: ',paste(V$controle[V$bloqueante & !V$aprovado],collapse=', '))
  path <- function(p) file.path(raiz,gsub('\\','/',p,fixed=TRUE))
  sha <- function(p) {con<-file(p,'rb');on.exit(close(con));digest::digest(readBin(con,'raw',n=file.info(p)$size),algo='sha256',serialize=FALSE)}
  norm <- function(x) {z<-trimws(as.character(x));z[is.na(x)|z=='']<-NA_character_;z}
  inteiro <- function(x) {z<-norm(x);z[!is.na(z)&!grepl('^[0-9]+$',z)]<-NA_character_;suppressWarnings(as.integer(z))}
  chave <- function(d,cols) do.call(paste,c(lapply(d[cols],function(x)ifelse(is.na(x),'<NA>',as.character(x))),sep='\034'))
  contar <- function(d,cols) {
    z<-d[cols];z[]<-lapply(z,function(x){x<-as.character(x);x[is.na(x)]<-'AUSENTE';x})
    if(!nrow(z)){z$n<-integer();return(z)}
    a<-aggregate(rep(1L,nrow(z)),z,sum);names(a)[ncol(a)]<-'n';a
  }
  taxas <- function(d) {
    alpha<-1-as.numeric(config$nivel_confianca);b<-as.numeric(config$taxa_base)
    d$numerador<-d$n;d$denominador<-d$populacao
    valid<-!is.na(d$populacao)&d$populacao>0
    d$taxa_100mil<-d$ic95_inferior<-d$ic95_superior<-NA_real_
    d$taxa_100mil[valid]<-d$n[valid]/d$populacao[valid]*b
    low<-ifelse(d$n==0,0,stats::qchisq(alpha/2,2*d$n)/2)
    high<-stats::qchisq(1-alpha/2,2*(d$n+1))/2
    d$ic95_inferior[valid]<-low[valid]/d$populacao[valid]*b
    d$ic95_superior[valid]<-high[valid]/d$populacao[valid]*b
    d$status_denominador<-ifelse(valid,'observado','denominador_indisponivel')
    d
  }
  contexto <- function(d,sistema,tempo,fonte_id) {
    d$codigo_municipio<-rep(municipio,nrow(d));d$versao_analitica<-rep(versao,nrow(d));d$snapshot_id<-rep(snapshot,nrow(d))
    d$sistema<-rep(sistema,nrow(d));d$perspectiva<-rep('residencia',nrow(d));d$referencia_temporal<-rep(tempo,nrow(d));d$fonte_id<-rep(fonte_id,nrow(d));d
  }
  pacote<-path(config$fonte_pacote)
  verificar('hash_pacote_congelado',sha(pacote),config$fonte_pacote_sha256)
  verificar('anos_unicos',anyDuplicated(anos),0L)
  verificar('perfil_11_anos',length(anos),11L)
  verificar('perfil_11_faixas',length(faixas),11L)
  verificar('municipio_config',municipio,'292740')
  barreira()
  m<-readRDS(pacote);S<-m$SINAN;P<-m$populacao;z_original<-S$casos_minimos_locais
  verificar('coorte',nrow(z_original),as.integer(C$coorte))
  required<-c('arquivo_origem','hash_tecnico','ano_sintomas','mes_sintomas','sexo_codigo','idade_codigo','etiologia_codigo','evolucao_codigo','criterio_codigo','faixa_etaria')
  verificar('campos_obrigatorios',all(required%in%names(z_original)),TRUE)
  verificar('municipio_pacote',as.character(m$configuracao$municipio),municipio)
  barreira()
  # Fontes sao verificadas contra o inventario congelado; nenhuma fonte e substituida.
  inv<-m$inventario_entradas
  selected<-grepl('sinan_br_|denominadores/',gsub('\\','/',inv$caminho,fixed=TRUE))
  inv<-inv[selected,,drop=FALSE]
  verificar('inventario_nucleo_nao_vazio',nrow(inv)>0,TRUE)
  fontes<-data.frame(fonte_id='pacote_congelado',sistema='SINAN/populacao',caminho=config$fonte_pacote,sha256=sha(pacote),bytes=file.info(pacote)$size,perspectiva='residencia',tempo='sintomas/estimativa_1_julho',abrangencia='Salvador; SINAN nacional',stringsAsFactors=FALSE)
  for(i in seq_len(nrow(inv))) {
    f<-path(inv$caminho[i]);id<-paste0('entrada_',i)
    verificar(paste0('hash_',id),sha(f),inv$sha256[i],detalhe=inv$caminho[i])
    verificar(paste0('bytes_',id),as.numeric(file.info(f)$size),as.numeric(inv$bytes[i]))
    sis<-if(grepl('denominadores',inv$caminho[i]))'populacao' else 'SINAN'
    fontes<-rbind(fontes,data.frame(fonte_id=id,sistema=sis,caminho=inv$caminho[i],sha256=sha(f),bytes=file.info(f)$size,perspectiva='residencia',tempo=if(sis=='populacao')'populacao_1_julho' else 'primeiros_sintomas',abrangencia=if(sis=='populacao')'Salvador' else 'SINAN nacional; residentes Salvador'))
  }
  manifest<-jsonlite::fromJSON(path(paste0('dados/brutos/sinan_br_',snapshot,'/manifesto.json')))
  verificar('particoes_13',nrow(manifest$arquivos),13L)
  for(i in seq_len(nrow(manifest$arquivos))) {
    e<-manifest$arquivos[i,];f<-path(e$caminho)
    verificar(paste0('hash_',e$nome_original),sha(f),e$sha256,detalhe='Hash DBC sem nova leitura/descompressao')
    fontes<-rbind(fontes,data.frame(fonte_id=paste0('dbc_',e$nome_original),sistema='SINAN',caminho=e$caminho,sha256=sha(f),bytes=file.info(f)$size,perspectiva='residencia',tempo='particao_notificacao; selecao_sintomas',abrangencia='Brasil; selecionados residentes Salvador'))
  }
  # Faixas e idades mantem integralmente a regra historica que reproduz o benchmark.
  faixa_historica<-c('<1 Ano','1-4','5-9','10-14','15-19','20-39','40-59','60-64','65-69','70-79','80 e +')
  verificar('mapa_faixas_config',faixas,c('<1','1-4','5-9','10-14','15-19','20-39','40-59','60-64','65-69','70-79','80+'))
  revisar_idade <- function(x) {
    v<-inteiro(x);u<-v%/%1000;n<-v%%1000;y<-rep(NA_real_,length(v))
    for(k in 1:4){ii<-which(u==k);y[ii]<-n[ii]/c(365.25*24,365.25,12,1)[k]}
    ok<-!is.na(u)&u%in%1:4&!is.na(y)&y>=0&y<=120
    faixa<-as.character(cut(y,c(-Inf,1,5,10,15,20,40,60,65,70,80,Inf),right=FALSE,labels=faixa_historica));faixa[!ok]<-'Ign/Em Branco'
    list(unidade=u,magnitude=n,anos=y,interpretavel=ok,faixa=faixa)
  }
  idade<-revisar_idade(z_original$idade_codigo)
  verificar('faixas_idade_recalculadas',all(idade$faixa==z_original$faixa_etaria),TRUE)
  verificar('idade_interpretavel_recalculada',identical(idade$interpretavel,z_original$idade_interpretavel),TRUE)
  verificar('idade_anos_recalculada',isTRUE(all.equal(idade$anos,z_original$idade_anos_aproximados)),TRUE)
  codteste<-c('1001','2024','2365','2366','3011','3012','4000','4001','4005','4010','4015','4020','4040','4060','4065','4070','4080','4120','4121','5001','X',NA)
  esperado<-c('<1 Ano','<1 Ano','<1 Ano','1-4','<1 Ano','1-4','<1 Ano','1-4','5-9','10-14','15-19','20-39','40-59','60-64','65-69','70-79','80 e +','80 e +',rep('Ign/Em Branco',4))
  it<-revisar_idade(codteste)
  verificar('fronteiras_idade',identical(it$faixa,esperado),TRUE,detalhe='Unidades horas/dias/meses/anos; 365 dias continua <1 pela divisao historica 365.25; sem recodificacao silenciosa')
  auditoria_idade<-data.frame(codigo=codteste,unidade=it$unidade,magnitude=it$magnitude,anos=it$anos,faixa_obtida=it$faixa,faixa_esperada=esperado)
  z<-z_original;z$indice_linha_analitica<-seq_len(nrow(z));z$snapshot_id<-snapshot;z$versao_analitica<-versao;z$codigo_municipio<-municipio
  z$chave_tecnica<-paste(snapshot,z$arquivo_origem,z$hash_tecnico,sep='|')
  z$idade_unidade<-idade$unidade;z$idade_magnitude<-idade$magnitude
  z$sexo_id<-ifelse(z$sexo_codigo%in%c('M','F'),z$sexo_codigo,'IGNORADO')
  z$faixa_id<-faixas[match(z$faixa_etaria,faixa_historica)];z$faixa_id[is.na(z$faixa_id)]<-'IGNORADO'
  estado<-function(x,valid,ignorados=character()) {v<-norm(x);ifelse(is.na(v),'ausente',ifelse(v%in%valid,'valido',ifelse(v%in%ignorados,'ignorado','nao_canonico')))}
  z$sexo_estado<-estado(z$sexo_codigo,c('M','F'),c('I','9'))
  z$etiologia_estado<-estado(z$etiologia_codigo,sprintf('%02d',1:10))
  z$evolucao_estado<-estado(as.character(inteiro(z$evolucao_codigo)),as.character(1:3),'9')
  z$evolucao_estado[!is.na(norm(z$evolucao_codigo))&is.na(inteiro(z$evolucao_codigo))]<-'nao_canonico'
  z$criterio_estado<-estado(as.character(inteiro(z$criterio_codigo)),as.character(1:10),'9')
  z$criterio_estado[!is.na(norm(z$criterio_codigo))&is.na(inteiro(z$criterio_codigo))]<-'nao_canonico'
  verificar('campos_originais_conservados',identical(z[names(z_original)],z_original),TRUE)
  verificar('chaves_tecnicas_repetidas',anyDuplicated(z$chave_tecnica),0L,detalhe='Chave tecnica da versao, nao pessoa')
  verificar('hashes_tecnicos_repetidos',anyDuplicated(z$hash_tecnico),0L)
  verificar('janela_sintomas',all(z$ano_sintomas%in%anos),TRUE)
  verificar('meses_validos',all(!is.na(z$mes_sintomas)&z$mes_sintomas%in%1:12),TRUE)
  verificar('etiologia_nao_canonica',sum(z$etiologia_estado=='nao_canonico'),as.integer(C$etiologias_nao_canonicas))
  verificar('etiologia_ausente',sum(z$etiologia_estado=='ausente'),as.integer(C$etiologias_vazias))
  verificar('evolucao_desconhecida',sum(z$evolucao_estado!='valido'),as.integer(C$evolucoes_desconhecidas))
  verificar('MNE_preservada',sum(z$etiologia_codigo=='06',na.rm=TRUE),442L)
  verificar('MCC_preservada',sum(z$etiologia_codigo=='01',na.rm=TRUE),19L)
  verificar('fora_BA',sum(!is.na(z$uf_notificacao_codigo)&z$uf_notificacao_codigo!='29'),2L)
  fluxo<-S$fluxos
  for(pair in list(c('n_nacional','nacional_linhas'),c('n_residentes','residentes'),c('n_confirmados','residentes_confirmados'),c('n_confirmados_fora_janela','fora_janela')))
    verificar(paste0('fluxo_',pair[1]),sum(fluxo[[pair[1]]]),as.numeric(C[[pair[2]]]),ok=sum(fluxo[[pair[1]]])==as.numeric(C[[pair[2]]]))
  verificar('fluxo_sem_data',sum(fluxo$n_confirmados_sem_data),0L)
  verificar('fluxo_fechamento',all(fluxo$n_confirmados==fluxo$n_coorte+fluxo$n_confirmados_fora_janela+fluxo$n_confirmados_sem_data),TRUE)
  # Populacao original e harmonizada em niveis separados: nao somar totais aos componentes.
  original<-P$sexo_idade_original;pop<-P$faixas_sinan
  verificar('pop_original_396',nrow(original),as.integer(C$populacao_original_chaves))
  verificar('pop_original_chaves',anyDuplicated(chave(original,c('ano','sexo','faixa_etaria','codigo_municipio'))),0L)
  verificar('pop_242',nrow(pop),as.integer(C$estratos_populacao))
  verificar('pop_chaves',anyDuplicated(chave(pop,c('ano','sexo','faixa_etaria_sinan','codigo_municipio'))),0L)
  verificar('pop_positiva',all(is.finite(pop$populacao)&pop$populacao>0&pop$populacao==floor(pop$populacao)),TRUE)
  verificar('pop_original_positiva',all(is.finite(original$populacao)&original$populacao>0),TRUE)
  verificar('pop_territorio',all(as.character(pop$codigo_municipio)==municipio)&all(as.character(original$codigo_municipio)==municipio),TRUE)
  pop$faixa_id<-faixas[match(pop$faixa_etaria_sinan,faixa_historica)];pop$sexo_id<-as.character(pop$sexo);pop$ano<-as.integer(pop$ano)
  verificar('pop_dominios',all(!is.na(pop$faixa_id)&pop$sexo_id%in%c('F','M')&pop$ano%in%anos),TRUE)
  mapa<-data.frame(faixa_original=names(P$metadados$regra_faixas_sinan),faixa_sinan=as.character(unlist(P$metadados$regra_faixas_sinan)),stringsAsFactors=FALSE)
  mapa$faixa_id<-faixas[match(mapa$faixa_sinan,faixa_historica)]
  original$faixa_id<-mapa$faixa_id[match(original$faixa_etaria,mapa$faixa_original)]
  verificar('mapa_pop_original_completo',all(!is.na(original$faixa_id)),TRUE)
  regroup<-aggregate(original$populacao,original[c('ano','sexo','faixa_id')],sum);names(regroup)[4]<-'populacao'
  matchreg<-match(chave(pop,c('ano','sexo','faixa_id')),chave(regroup,c('ano','sexo','faixa_id')))
  verificar('reagrupamento_pop_identico',all(!is.na(matchreg))&&all(pop$populacao==regroup$populacao[matchreg]),TRUE)
  totais<-aggregate(pop$populacao,list(ano=pop$ano),sum);names(totais)[2]<-'populacao'
  verificar('pop_11_totais',nrow(totais),length(anos))
  pt<-P$total$populacao[match(totais$ano,P$total$ano)]
  verificar('pop_somas_totais',all(totais$populacao==pt),TRUE)
  pop$fonte_denominador<-unique(P$sexo_idade_original$fonte_denominador)[1]
  pop$referencia_denominador<-unique(P$sexo_idade_original$referencia_denominador)[1]
  pop<-contexto(pop,'populacao','populacao_1_julho','populacao_harmonizada')
  pop$nivel_agregacao<-'sexo_faixa';pop$status<-'observado'
  porsexo<-aggregate(pop$populacao,pop[c('ano','sexo_id')],sum);names(porsexo)[3]<-'populacao'
  poridade<-aggregate(pop$populacao,pop[c('ano','faixa_id')],sum);names(poridade)[3]<-'populacao'
  totais<-contexto(totais,'populacao','populacao_1_julho','populacao_total');totais$nivel_agregacao<-'total'
  porsexo<-contexto(porsexo,'populacao','populacao_1_julho','populacao_harmonizada');porsexo$nivel_agregacao<-'sexo'
  poridade<-contexto(poridade,'populacao','populacao_1_julho','populacao_harmonizada');poridade$nivel_agregacao<-'faixa'
  # Estratos validos derivam dos registros reais, nunca de produto de marginais.
  valid<-z$sexo_id%in%c('F','M') & z$faixa_id%in%faixas
  obs<-contar(z[valid,],c('ano_sintomas','sexo_id','faixa_id'));names(obs)[1]<-'ano'
  estratos<-expand.grid(ano=anos,sexo_id=c('F','M'),faixa_id=faixas,stringsAsFactors=FALSE)
  k<-c('ano','sexo_id','faixa_id');hit<-match(chave(estratos,k),chave(obs,k));estratos$n<-obs$n[hit]
  estratos$status_numerador<-ifelse(is.na(hit),'zero_derivado_coorte','observado');estratos$n[is.na(hit)]<-0L
  pk<-match(chave(estratos,k),chave(pop,k));estratos$populacao<-pop$populacao[pk]
  verificar('join_pop_muitos_para_um',anyDuplicated(chave(pop,k))==0 && all(!is.na(pk)) && nrow(estratos)==as.integer(C$estratos_populacao),TRUE)
  estratos<-contexto(taxas(estratos),'SINAN','primeiros_sintomas','sinan_populacao');estratos$unidade<-'registros_confirmados'
  ignorados<-contar(z[!valid,],c('ano_sintomas','sexo_id','faixa_id'));names(ignorados)[1]<-'ano'
  ignorados$populacao<-rep(NA_real_,nrow(ignorados));ignorados<-contexto(taxas(ignorados),'SINAN','primeiros_sintomas','sinan_populacao')
  ignorados$status_numerador<-rep('observado',nrow(ignorados));ignorados$motivo<-rep('sexo_ou_idade_sem_denominador_compativel',nrow(ignorados))
  anual<-data.frame(ano=anos,n=as.integer(table(factor(z$ano_sintomas,levels=anos))))
  verificar('totais_anuais',anual$n,as.integer(unlist(C$totais_anuais)))
  anual$populacao<-totais$populacao[match(anual$ano,totais$ano)];anual<-contexto(taxas(anual),'SINAN','primeiros_sintomas','sinan_populacao')
  anual$status_numerador<-ifelse(anual$n==0,'zero_derivado_coorte','observado')
  verificar('estratos_242',nrow(estratos),as.integer(C$estratos_populacao))
  verificar('estratos_mais_ignorados',sum(estratos$n)+sum(ignorados$n),as.numeric(C$coorte),ok=sum(estratos$n)+sum(ignorados$n)==C$coorte)
  mensal<-expand.grid(ano=anos,mes=1:12,stringsAsFactors=FALSE)
  mo<-contar(z,c('ano_sintomas','mes_sintomas'));names(mo)<-c('ano','mes','n')
  hit<-match(chave(mensal,c('ano','mes')),chave(mo,c('ano','mes')));mensal$n<-mo$n[hit]
  mensal$status_numerador<-ifelse(is.na(hit),'zero_derivado_coorte','observado');mensal$n[is.na(hit)]<-0L
  mensal$data_mes<-as.Date(sprintf('%04d-%02d-01',mensal$ano,mensal$mes));mensal<-mensal[order(mensal$ano,mensal$mes),]
  mensal<-contexto(mensal,'SINAN','primeiros_sintomas','sinan_coorte');mensal$unidade<-'registros_confirmados'
  mensal$regra_zero<-'Ausencia de registros na coorte integralmente lida, mesmo recorte e snapshot'
  verificar('mensal_132',nrow(mensal),as.integer(C$meses_grade))
  verificar('mensal_chaves',anyDuplicated(chave(mensal,c('ano','mes'))),0L)
  verificar('mensal_fecha_anual',all(as.integer(tapply(mensal$n,mensal$ano,sum))==anual$n),TRUE)
  # Categorias canonicas e observadas; zero derivado so no universo fechado.
  dominios<-list(sexo=c('Masculino','Feminino','Ignorado'),faixa_etaria=faixa_historica,
    etiologia=c('MCC','MM','MM+MCC','MTBC','MB','MNE','MV','MOE','MH','MP','IGN/EM BRANCO'),
    evolucao=c('Alta','\u00d3bito por meningite','\u00d3bito por outra causa','Ign/Branco'),
    criterio=c('Cultura','CIE','AG. Latex','Cl\u00ednico','Bacterioscopia','Quimiocitol\u00f3gico','Cl\u00ednico-epidemiol\u00f3gico','Isolamento viral','PCR','Outra t\u00e9cnica','Em branco'))
  categorias<-list()
  for(d in names(dominios)) {
    oo<-contar(z,c('ano_sintomas',d));names(oo)<-c('ano','categoria','n')
    g<-expand.grid(ano=anos,categoria=unique(c(dominios[[d]],as.character(z[[d]]))),stringsAsFactors=FALSE)
    h<-match(chave(g,c('ano','categoria')),chave(oo,c('ano','categoria')));g$n<-oo$n[h]
    g$status_numerador<-ifelse(is.na(h),'zero_derivado_coorte','observado');g$n[is.na(h)]<-0L;g$dimensao<-d
    g$total_ano<-anual$n[match(g$ano,anual$ano)];g$percentual_total_ano<-100*g$n/g$total_ano
    verificar(paste0('categorias_fechamento_',d),all(as.integer(tapply(g$n,g$ano,sum))==anual$n),TRUE)
    categorias[[d]]<-g
  }
  categorias<-contexto(do.call(rbind,categorias),'SINAN','primeiros_sintomas','sinan_coorte')
  qualidade<-contexto(S$qualidade,'SINAN','primeiros_sintomas','sinan_coorte')
  verificar('qualidade_nao_vazia',nrow(qualidade)>0,TRUE)
  verificar('qualidade_fechamento',all(qualidade$n_conhecido+qualidade$n_ausente_ignorado_nao_interpretavel==qualidade$total),TRUE)
  # Benchmark independente dos contadores JSON: recontar categorias da coorte.
  cmp<-S$comparacao_tabnet;novo<-numeric(nrow(cmp));mesrot<-c('Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez')
  for(i in seq_len(nrow(cmp))) {
    yy<-z[z$ano_sintomas==cmp$ano[i],,drop=FALSE];axis<-cmp$consulta[i]
    if(axis=='total_sem_coluna')novo[i]<-nrow(yy) else {
      v<-switch(axis,idade='faixa_etaria',mes_sintomas='mes_sintomas',axis)
      valores<-as.character(yy[[v]])
      if(axis=='mes_sintomas')valores<-mesrot[yy$mes_sintomas]
      if(axis=='criterio')valores[valores=='PCR']<-'PCR - viral'
      novo[i]<-sum(valores==cmp$categoria[i],na.rm=TRUE)
    }
  }
  ref<-!is.na(cmp$n_tabnet)
  verificar('benchmark_572_referencias',sum(ref),as.integer(C$comparaveis_tabnet))
  verificar('benchmark_valores_recontados',all(novo==cmp$n_br),TRUE)
  verificar('benchmark_sem_divergencias',all(novo[ref]==cmp$n_tabnet[ref]),TRUE)
  verificar('benchmark_6_extras',sum(!ref),6L)
  verificar('benchmark_extras_sem_imputacao',all(is.na(cmp$diferenca_br_menos_tabnet[!ref]))&&sum(novo[!ref])==6,TRUE)
  # Conservacao por ano incluindo os estratos ignorados.
  for(y in anos)verificar(paste0('estratos_fecha_',y),sum(estratos$n[estratos$ano==y])+sum(ignorados$n[ignorados$ano==y]),anual$n[anual$ano==y],ok=sum(estratos$n[estratos$ano==y])+sum(ignorados$n[ignorados$ano==y])==anual$n[anual$ano==y])
  verificar('contagens_nao_negativas_inteiras',all(c(estratos$n,mensal$n,categorias$n)>=0 & c(estratos$n,mensal$n,categorias$n)==floor(c(estratos$n,mensal$n,categorias$n))),TRUE)
  verificar('taxas_zeros_ic_finito',all(is.finite(estratos$ic95_superior[estratos$n==0]))&&all(estratos$ic95_inferior[estratos$n==0]==0),TRUE)
  verificar('taxas_sem_denominador_ausentes',all(is.na(ignorados$taxa_100mil)),TRUE)
  verificar('total_separado_componentes',all(pop$nivel_agregacao=='sexo_faixa')&&!any(pop$sexo_id=='TOTAL')&&!any(pop$faixa_id=='TOTAL'),TRUE)
  verificar('categoria_chaves',anyDuplicated(chave(categorias,c('ano','dimensao','categoria'))),0L)
  verificar('sinan_estratos_chaves',anyDuplicated(chave(estratos,c('ano','sexo_id','faixa_id'))),0L)
  barreira()
  # Dicionarios/estados e mapas guardam o significado, nao apenas rotulos.
  mapa_faixas<-data.frame(faixa_id=faixas,faixa_historica=faixa_historica,ordem=seq_along(faixas))
  mapa_etiologia<-data.frame(codigo=sprintf('%02d',1:10),categoria=dominios$etiologia[1:10],dominio='canonica_textual')
  mapa_criterio<-data.frame(codigo=as.character(1:10),categoria=dominios$criterio[1:10],dominio='criterio_registrado; PCR nao prova agente')
  mapa_evolucao<-data.frame(codigo=as.character(1:3),categoria=dominios$evolucao[1:3])
  codigos<-list()
  for(f in c('sexo_codigo','idade_codigo','etiologia_codigo','evolucao_codigo','criterio_codigo','uf_notificacao_codigo')) {
    t<-contar(z,c('ano_sintomas',f));names(t)<-c('ano','codigo_original','n');t$campo<-f;codigos[[f]]<-t
  }
  codigos<-do.call(rbind,codigos)
  tabelas<-list(sinan_estratos_anuais=estratos,sinan_mensal=mensal,sinan_categorias_anuais=categorias,populacao=pop)
  fontes<-rbind(fontes,data.frame(fonte_id=c('sinan_coorte','populacao_harmonizada','populacao_total','sinan_populacao'),sistema=c('SINAN','populacao','populacao','SINAN/populacao'),caminho=rep(config$fonte_pacote,4),sha256=rep(sha(pacote),4),bytes=rep(file.info(pacote)$size,4),perspectiva='residencia',tempo=c('primeiros_sintomas','populacao_1_julho','populacao_1_julho','sintomas/populacao_1_julho'),abrangencia='Salvador; objetos do pacote congelado'))
  cobertura<-rbind(data.frame(sistema='SINAN',ano=anos,dimensao='coorte',indicador='registros_confirmados',status='observado',motivo='13 particoes nacionais; sem afirmacao de pessoas unicas',fonte_id='sinan_coorte'),data.frame(sistema='populacao',ano=anos,dimensao='sexo_faixa',indicador='populacao_residente',status='observado',motivo='Mesma revisao RIPSA; referencia 1 julho; 22 estratos por ano',fonte_id='populacao_harmonizada'))
  cobertura<-rbind(cobertura,data.frame(sistema='SINAN',ano=anos,dimensao='evolucao',indicador='desconhecidos',status='incompletude_documentada',motivo='Nao imputar os 144 desconhecidos',fonte_id='sinan_coorte'))
  cobertura$modalidade<-ifelse(cobertura$sistema=='SINAN'&cobertura$ano>=2023,'preliminar','fonte_congelada')
  decisoes<-data.frame(decisao_id=c('identidade','idade','mensal','estratos','etiologia','evolucao','taxa','conservacao','privacidade','datas','secundarios'),regra=c('snapshot+arquivo+hash; indice analitico nao e posicao DBC nem pessoa','Mesmas faixas historicas e 365.25 dias; codigo/unidade preservados; fronteiras testadas','Grade132; uma ausencia observada vira zero_derivado_coorte, nao exportacao ausente','242 M/F x faixas; ignorados em objeto proprio sem denominador','Canonico textual01-10; nao converter7 em07; MCC/MNE e 6 nao canonicos+2 vazios conservados','144 desconhecidas conservadas; nao calcular letalidade completa','IC Poisson e taxa_base configurados; populacao1julho; nao corrige subnotificacao','Totais e componentes em objetos separados; joins muitos-para-um','Casos minimos somente RDS local; nenhum CSV individual','Datas completas/posicao original nao existem no pacote; nao reconstruir','Qualidade historica preservada; preenchimento nao prova aplicabilidade'),stringsAsFactors=FALSE)
  docs<-c(tabelas,list(casos_minimos_locais=z,qualidade_anual=qualidade,codigos_originais=codigos))
  dic<-lapply(names(docs),function(base){d<-docs[[base]];data.frame(base=base,campo=names(d),tipo=vapply(d,function(v)paste(class(v),collapse='/'),character(1)),descricao=paste('Campo',names(d),'da tabela',base),unidade=ifelse(names(d)%in%c('n','numerador'),'registros_confirmados',ifelse(names(d)%in%c('populacao','denominador'),'habitantes',ifelse(grepl('taxa|ic95',names(d)),'por_100mil',ifelse(grepl('percentual',names(d)),'percentual','codigo/atributo')))),regra_ausencia=ifelse(names(d)%in%c('populacao','denominador','taxa_100mil','ic95_inferior','ic95_superior'),'NA quando denominador incompativel; nunca zero',ifelse(names(d)=='n','Zero somente coorte integral; ver status_numerador','NA preservado; estados e codigos originais conservados')),fonte=if(base=='populacao')'populacao_harmonizada' else 'sinan_coorte',stringsAsFactors=FALSE)})
  dicionario<-do.call(rbind,dic)
  descr<-c(ano='Ano dos primeiros sintomas (SINAN) ou ano da estimativa (populacao)',mes='Mes dos primeiros sintomas, 1 a 12',sexo_id='M/F; IGNORADO apenas em casos e estratos sem denominador',faixa_id='Faixa harmonizada disjunta; mapa_faixas no RDS',n='Contagem de registros, nao pessoas unicas',populacao='Populacao residente no estrato; referencia 1 julho',numerador='Registros confirmados no estrato',denominador='Habitantes do mesmo ano/sexo/faixa/municipio',taxa_100mil='Numerador/denominador multiplicado por taxa_base configurada',ic95_inferior='Limite inferior Poisson exato; nivel de confianca configurado',ic95_superior='Limite superior Poisson exato; nivel de confianca configurado',status_numerador='Observado ou zero_derivado_coorte',chave_tecnica='snapshot+arquivo+hash; identifica registro tecnico, nao pessoa',hash_tecnico='Hash historico de todos os campos originais; nao recalculado com dados minimos',indice_linha_analitica='Posicao neste pacote; nao posicao no DBC',percentual_total_ano='100*n/total anual, incluindo categorias desconhecidas',codigo_original='Codigo textual da fonte; AUSENTE na tabela de frequencias nao substitui o valor original local')
  for(f in names(descr))dicionario$descricao[dicionario$campo==f]<-descr[f]
  res<-list(modulos=list(SINAN=list(casos_minimos_locais=z,serie_anual=anual,estratos_anuais=estratos,estratos_ignorados=ignorados,mensal=mensal,categorias_anuais=categorias,qualidade_anual=qualidade,codigos_originais=codigos,conjunto_original=S$conjunto,fluxos=fluxo,comparacao_tabnet=cmp,mapa_faixas=mapa_faixas,mapa_etiologia=mapa_etiologia,mapa_criterio=mapa_criterio,mapa_evolucao=mapa_evolucao,auditoria_idade=auditoria_idade),populacao=list(basica=pop,total=totais,por_sexo=porsexo,por_idade=poridade,original=original,mapa_reagrupamento=mapa,metadados=P$metadados)),tabelas=tabelas,dicionario=dicionario,fontes=fontes,cobertura=cobertura,validacao=V,decisoes=decisoes,configuracao=config,sessionInfo=utils::sessionInfo())
  dir.create(destino,recursive=TRUE,showWarnings=FALSE)
  gravar<-function(d,nome)write.table(d,file.path(destino,paste0(nome,'.csv')),sep=config$csv$sep,dec=config$csv$dec,quote=TRUE,row.names=FALSE,na=config$csv$na,fileEncoding=config$csv$encoding)
  exports<-c(tabelas,list(sinan_qualidade_anual=qualidade,sinan_estratos_ignorados=ignorados,dicionario=dicionario,fontes=fontes,cobertura=cobertura,decisoes=decisoes,mapa_faixas=mapa_faixas,mapa_populacao=mapa,auditoria_idade=auditoria_idade))
  for(nm in names(exports)) {
    d<-exports[[nm]];gravar(d,nm)
    cc<-vapply(d,function(v)if(inherits(v,'Date'))'character' else if(is.integer(v))'integer' else if(is.numeric(v))'numeric' else if(is.logical(v))'logical' else 'character',character(1))
    back<-read.csv(file.path(destino,paste0(nm,'.csv')),sep=config$csv$sep,dec=config$csv$dec,na.strings=config$csv$na,check.names=FALSE,fileEncoding='UTF-8',colClasses=cc,stringsAsFactors=FALSE)
    for(f in names(d))if(inherits(d[[f]],'Date'))back[[f]]<-as.Date(back[[f]])
    rownames(d)<-NULL;rownames(back)<-NULL
    verificar(paste0('csv_roundtrip_',nm),isTRUE(all.equal(d,back,check.attributes=FALSE,tolerance=1e-10)),TRUE)
  }
  barreira();res$validacao<-V
  gravar(V,'validacao');saveRDS(res,file.path(destino,'candidato.rds'),compress='xz')
  verificar('rds_roundtrip',identical(res,readRDS(file.path(destino,'candidato.rds'))),TRUE)
  barreira();res$validacao<-V;gravar(V,'validacao');saveRDS(res,file.path(destino,'candidato.rds'),compress='xz')
  report<-c('# Candidato SINAN/populacao - Frente A',paste('Versao analitica',versao,'; snapshot',snapshot),paste('Controles:',nrow(V),'; aprovados:',sum(V$aprovado),'; bloqueantes reprovados:',sum(V$bloqueante & !V$aprovado)),paste('Coorte:',nrow(z),'; estratos validos:',nrow(estratos),'; registros sem denominador:',sum(ignorados$n)),paste('Grade mensal:',nrow(mensal),'; zeros derivados:',sum(mensal$status_numerador=='zero_derivado_coorte')),paste('Populacao original:',nrow(original),'; harmonizada:',nrow(pop)),'','Funcao: preparar_sinan_populacao(raiz, config, destino). source() nao executa.','Pacote candidato local; casos individuais somente no RDS. CSVs sao agregados/documentacao.','Idades preservam benchmark: 365 dias permanece <1 na conversao aproximada365.25.','Seis etiologias nao canonicas, duas vazias, MCC/MNE,144 evolucoes desconhecidas e2notificacoes foraBA preservadas.','Hash tecnico nao demonstra pessoas unicas. Nenhuma deduplicacao clinica ou vinculo entre sistemas.','Taxas por populacao residente1julho e IC Poisson; nao corrigem subnotificacao/incerteza demografica.','Fontes2023+ preliminares; campos secundarios nao validados clinicamente.','Nenhuma coleta, figura, Git ou promocao para produto final nesta frente.','Reproducao: executar executar_candidato.R nesta area; requer jsonlite/digest ja instalados.')
  writeLines(report,file.path(destino,'RELATORIO_CANDIDATO.md'),useBytes=TRUE)
  res
}
