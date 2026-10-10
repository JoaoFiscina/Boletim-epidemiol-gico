# Preparacao offline; source() apenas define a funcao.
preparar_complementos <- function(raiz, config, destino) {
  for(p in c('jsonlite','digest')) if(!requireNamespace(p,quietly=TRUE)) stop('Dependencia existente necessaria: ',p)
  raiz <- normalizePath(raiz,winslash='/',mustWork=TRUE)
  destino <- normalizePath(destino,winslash='/',mustWork=TRUE)
  hash <- function(p) { con<-file(p,'rb');on.exit(close(con));digest::digest(readBin(con,'raw',n=file.info(p)$size),algo='sha256',serialize=FALSE) }
  entradas <- list(); valid <- list()
  fonte <- function(path,sistema='documentacao',perspectiva='',tempo='',abrangencia='') {
    stopifnot(file.exists(path))
    if(perspectiva=='')perspectiva<-if(sistema=='SIH')'residencia' else if(sistema=='SIM')'residencia' else if(sistema=='PNI')'legado_registro_ou_RNDS_residencia; ver tabela' else 'conforme_contrato'
    if(tempo=='')tempo<-if(sistema=='SIH')'ano_processamento'else if(sistema=='SIM')'ano_obito'else if(sistema=='PNI')'ano_indicador_vacinal'else 'conforme_contrato'
    if(abrangencia=='')abrangencia<-if(sistema=='SIH')'rede_SUS_nacional'else if(sistema=='SIM')'registro_BA'else if(sistema=='PNI')'municipal; metodos separados'else 'conforme_contrato'
    id <- paste0('fonte_',length(entradas)+1L)
    entradas[[id]] <<- data.frame(fonte_id=id,sistema=sistema,caminho=path,sha256=hash(path),bytes=file.info(path)$size,perspectiva=perspectiva,tempo=tempo,abrangencia=abrangencia,stringsAsFactors=FALSE)
    id
  }
  ler <- function(path,sistema) {
    id<-fonte(path,sistema)
    z<-read.csv(path,sep=';',fileEncoding='UTF-8-BOM',na.strings='',stringsAsFactors=FALSE,check.names=FALSE)
    for(n in intersect(c('codigo_ibge6','codigo_ibge7','municipio_residencia'),names(z)))z[[n]]<-as.character(z[[n]])
    z$fonte_id<-id;z
  }
  teste <- function(nome,obs,esp,ok,bloq=TRUE,det='') {
    valid[[length(valid)+1L]] <<- data.frame(controle=nome,observado=paste(obs,collapse='|'),esperado=paste(esp,collapse='|'),aprovado=isTRUE(ok),bloqueante=bloq,detalhe=det,stringsAsFactors=FALSE)
  }
  juntar <- function(a,b) {
    cols<-union(names(a),names(b)); for(n in setdiff(cols,names(a)))a[[n]]<-NA
    for(n in setdiff(cols,names(b)))b[[n]]<-NA
    rbind(a[cols],b[cols])
  }
  versao<-config$versao_fontes; anos<-as.integer(config$anos)
  teste('pacote_entrada_SHA',hash(file.path(raiz,config$fonte_pacote)),config$fonte_pacote_sha256,hash(file.path(raiz,config$fonte_pacote))==config$fonte_pacote_sha256)
  antigo<-file.path(raiz,paste0('dados/tratados/complementos_',versao))
  novo<-file.path(destino,'dados/tratados/retomada_20261010')
  measures<-ler(file.path(antigo,'sih_medidas_anuais_longo.csv'),'SIH')
  profiles<-ler(file.path(antigo,'perfis_anuais_longo.csv'),'SIH_SIM')
  derived<-ler(file.path(antigo,'sih_internacoes_anuais_totais_das_marginais.csv'),'SIH')
  if(file.exists(file.path(novo,'sih_internacoes_anuais_totais_das_marginais.csv')))derived<-juntar(derived,ler(file.path(novo,'sih_internacoes_anuais_totais_das_marginais.csv'),'SIH'))
  checks<-ler(file.path(antigo,'conferencias.csv'),'SIH_SIM')
  if(file.exists(file.path(novo,'sih_medidas_anuais_longo.csv')))measures<-juntar(measures,ler(file.path(novo,'sih_medidas_anuais_longo.csv'),'SIH'))
  if(file.exists(file.path(novo,'perfis_anuais_longo.csv')))profiles<-juntar(profiles,ler(file.path(novo,'perfis_anuais_longo.csv'),'SIH'))
  if(file.exists(file.path(novo,'conferencias.csv')))checks<-juntar(checks,ler(file.path(novo,'conferencias.csv'),'SIH'))
  cids<-c('G00','G01','G02','G03','A39','A87'); metricas<-c('internacoes','obitos','dias_permanencia','valor_total')
  grade<-expand.grid(cid_grupo=cids,ano_processamento=anos,medida=metricas,stringsAsFactors=FALSE)
  key<-function(d)paste(d$cid_grupo,d$ano_processamento,d$medida,sep='|')
  teste('SIH_medidas_chaves',nrow(measures),length(unique(key(measures))),!anyDuplicated(key(measures)))
  mm<-merge(grade,measures,by=c('cid_grupo','ano_processamento','medida'),all.x=TRUE,sort=TRUE)
  mm$status[is.na(mm$status)]<-'pendente_consulta'
  # Totais oficiais das marginais so suprem consulta geral ausente; nunca sao somados.
  for(i in seq_len(nrow(derived))) {
    ix<-which(mm$cid_grupo==derived$cid_grupo[i]&mm$ano_processamento==derived$ano_processamento[i]&mm$medida=='internacoes')
    if(length(ix)==1&&is.na(mm$valor[ix])&&mm$status[ix]=='pendente_consulta') {
      mm$valor[ix]<-derived$internacoes[i];mm$status[ix]<-'observado_derivado_total_oficial_marginal'
      mm$fonte_id[ix]<-derived$fonte_id[i];mm$consulta_id[ix]<-derived$consultas_origem[i]
      mm$valor_original[ix]<-as.character(derived$internacoes[i])
    }
    if(length(ix)==1&&!is.na(mm$valor[ix]))teste(paste0('total_marginal_',derived$cid_grupo[i],'_',derived$ano_processamento[i]),mm$valor[ix],derived$internacoes[i],mm$valor[ix]==derived$internacoes[i])
  }
  mm$sistema<-'SIH';mm$municipio_residencia<-as.character(config$municipio)
  mm$ano<-mm$ano_processamento;mm$referencia_tempo<-'ano_processamento';mm$tipo_tabela<-'total';mm$dimensao<-'diagnostico';mm$estrato<-mm$cid_grupo
  mm$unidade<-c(internacoes='episodios_aproximados_AIH',obitos='altas_por_obito',dias_permanencia='dias_AIH_aprovadas',valor_total='BRL_aprovados_nominais')[mm$medida]
  pp<-profiles[profiles$sistema=='SIH',,drop=FALSE];pp$tipo_tabela<-'perfil';pp$unidade<-'episodios_aproximados_AIH'
  sih<-juntar(mm,pp)
  sih$perspectiva<-'residencia';sih$abrangencia<-'rede_SUS_nacional';sih$snapshot_id<-ifelse(grepl('20261010',vapply(sih$fonte_id,function(x)if(is.na(x))''else entradas[[x]]$caminho,character(1))),'20261010','20261009')
  sih$snapshot_id[is.na(sih$fonte_id)]<-NA_character_
  sih$status[sih$status=='linha_omitida']<-'linha_omitida_sem_imputacao'
  sih$status[sih$status=='coluna_omitida']<-'coluna_omitida_sem_imputacao'
  sih$status[sih$valor==0&!is.na(sih$valor)&sih$status=='observado']<-'zero_observado'
  teste('SIH_grade_totais',nrow(mm),264,nrow(mm)==264)
  teste('SIH_folhas',unique(sih$cid_grupo),cids,all(sih$cid_grupo%in%cids))
  teste('SIH_SIM_controles_nao_vazios',nrow(checks),'>=77',nrow(checks)>=77)
  for(i in seq_len(nrow(checks))) {
    tolerance<-if(grepl('valor_total',checks$comparacao[i]))0.10 else 0
    teste(paste('conservacao',checks$sistema[i],checks$grupo[i],checks$ano[i],checks$comparacao[i],sep='_'),checks$diferenca[i],paste0('abs<=',tolerance),!is.na(checks$diferenca[i])&&abs(checks$diferenca[i])<=tolerance)
  }
  # Serie SIM explicita obtida da linha Total da tabela oficial preservada.
  simtab<-ler(file.path(antigo,'SIM_idade_ano_G00_G03_A39_A87_tabela.csv'),'SIM')
  totalrow<-which(tolower(simtab[[1]])=='total');stopifnot(length(totalrow)==1)
  converter<-function(x){x<-as.character(x);if(any(x%in%c('-','','...')|is.na(x)))stop('Total SIM sem valor explicito');as.numeric(gsub('.','',x,fixed=TRUE))}
  simtotal<-data.frame(sistema='SIM',cid_grupo='G00-G03/A39/A87',dimensao='conjunto',estrato='total',ano=anos,referencia_tempo='ano_obito',medida='obitos_causa_basica',valor=converter(unlist(simtab[totalrow,as.character(anos)])),status='observado',consulta_id='SIM_idade_ano_G00_G03_A39_A87',municipio_residencia=as.character(config$municipio),fonte_id=simtab$fonte_id[totalrow],tipo_tabela='total',stringsAsFactors=FALSE)
  simprof<-profiles[profiles$sistema=='SIM',,drop=FALSE];simprof$tipo_tabela<-'perfil'
  sim<-juntar(simtotal,simprof);sim$unidade<-'obitos_causa_basica';sim$perspectiva<-'residencia';sim$abrangencia<-'registro_BA_cobertura_nacional_nao_demonstrada';sim$snapshot_id<-'20261009'
  teste('SIM_serie_11_anos',nrow(simtotal),11,nrow(simtotal)==11&&!anyDuplicated(simtotal$ano))
  teste('SIM_202_obitos',sum(simtotal$valor),202,sum(simtotal$valor)==202)
  for(y in anos)teste(paste0('SIM_idade_',y),sum(simprof$valor[simprof$ano==y]),simtotal$valor[simtotal$ano==y],!anyNA(simprof$valor[simprof$ano==y])&&sum(simprof$valor[simprof$ano==y])==simtotal$valor[simtotal$ano==y])
  pdir<-file.path(raiz,paste0('dados/tratados/pni_',versao));md<-file.path(raiz,paste0('metadados/pni_',versao))
  observed<-ler(file.path(pdir,'pni_cobertura_municipal_2014_2024_longo.csv'),'PNI')
  availability<-ler(file.path(pdir,'disponibilidade_pni_municipal_2014_2024.csv'),'PNI')
  definitions<-ler(file.path(md,'indicadores_solicitados_disponiveis.csv'),'PNI')
  legacy_path<-file.path(destino,'aquisicao/pni_tratados/cobertura_legado_piloto_2014_2022.csv')
  if(file.exists(legacy_path)&&file.info(legacy_path)$size>0) {
    extra<-ler(legacy_path,'PNI'); if(nrow(extra)) {
      oldkeys<-paste(observed$indicador_grupo,observed$ano);newkeys<-paste(extra$indicador_grupo,extra$ano)
      stopifnot(!any(newkeys%in%oldkeys));observed<-juntar(observed,extra)
    }
  }
  pni<-merge(availability[c('codigo_ibge6','municipio','ano','indicador_grupo','fonte_sistema','status_coleta')],observed,by=c('codigo_ibge6','municipio','ano','indicador_grupo'),all.x=TRUE,sort=TRUE)
  pni<-merge(pni,definitions[c('indicador_grupo','populacao_alvo','esquema_historico','criterio_numerador_rnds_documental','denominador_legado','denominador_rnds')],by='indicador_grupo',all.x=TRUE,sort=FALSE)
  pni$sistema[is.na(pni$sistema)]<-'PNI_TabNet_legado'
  pni$metodo<-ifelse(pni$sistema=='PNI_RNDS_individual','RNDS_individual_normativo_ETL_nao_auditado','legado_ultima_dose')
  pni$geografia[is.na(pni$geografia)]<-'municipio_registro_residencia_nao_confirmada'
  pni$esquema<-ifelse(pni$sistema=='PNI_RNDS_individual',pni$criterio_numerador_rnds_documental,pni$esquema_historico)
  pni$status[is.na(pni$status)]<-pni$status_coleta[is.na(pni$status)]
  pni$indicador_fonte[is.na(pni$indicador_fonte)]<-c(bcg='BCG',meningococica='Meningococo C',pneumococica='Pneumocócica',penta_hib='Penta')[pni$indicador_grupo[is.na(pni$indicador_fonte)]]
  pni$unidade<-'percentual_cobertura_oficial';pni$referencia_tempo<-'ano_indicador_vacinal';pni$snapshot_id<-ifelse(is.na(pni$extraido_em),'20261009',ifelse(grepl('2026-10-10',pni$extraido_em),'20261010','20261009'))
  pni$pendente_inicial<-grepl('^pendente',pni$status_coleta);pni$comparabilidade_entre_metodos<-'nao_harmonizada'
  teste('PNI_grade44',nrow(pni),44,nrow(pni)==44)
  teste('PNI_chave_semantica',nrow(pni),length(unique(paste(pni$codigo_ibge6,pni$ano,pni$sistema,pni$metodo,pni$geografia,pni$indicador_fonte,pni$esquema,pni$populacao_alvo))),!anyDuplicated(pni[c('codigo_ibge6','ano','sistema','metodo','geografia','indicador_fonte','esquema','populacao_alvo')]))
  teste('PNI17_preservados',nrow(observed),'>=17',nrow(observed)>=17)
  teste('PNI27_pendencias_iniciais',sum(pni$pendente_inicial),27,sum(pni$pendente_inicial)==27)
  rn<-pni[pni$sistema=='PNI_RNDS_individual',];teste('PNI_RNDS8',nrow(rn),8,nrow(rn)==8)
  teste('PNI_RNDS_razoes',max(abs(rn$cobertura_percentual-100*rn$numerador_oficial/rn$denominador_oficial)),1e-8,nrow(rn)==8&&all(rn$denominador_oficial>0)&&all(abs(rn$cobertura_percentual-100*rn$numerador_oficial/rn$denominador_oficial)<1e-8))
  for(z in list(sih=sih,sim=sim,pni=pni))teste(paste0('tabela_nao_vazia_',unique(z$sistema)[1]),nrow(z),'>0',nrow(z)>0)
  aquisicao_path<-file.path(destino,'aquisicao/RESULTADO_RETOMADA.json')
  aquisicao<-jsonlite::fromJSON(aquisicao_path)
  teste('aquisicao_SIH_POST',aquisicao$post_sih,config$coleta$sih_post_dados_max,aquisicao$post_sih<=config$coleta$sih_post_dados_max)
  teste('aquisicao_PNI_POST',aquisicao$post_pni,config$coleta$pni_post_dados_max,aquisicao$post_pni<=config$coleta$pni_post_dados_max)
  teste('aquisicao_timeout',aquisicao$timeout,config$coleta$timeout_segundos,aquisicao$timeout==config$coleta$timeout_segundos)
  ledger<-jsonlite::fromJSON(file.path(destino,'aquisicao/requisicoes.json'))
  posts<-ledger[ledger$metodo=='POST',,drop=FALSE]
  teste('aquisicao_max2_por_consulta',max(table(posts$payload_sha256)),2,max(table(posts$payload_sha256))<=2)
  teste('aquisicao_SIH_seletiva',names(aquisicao$sih),c('SIH_internacoes_diagnostico_ano','SIH_dias_permanencia_diagnostico_ano','SIH_G00_sexo_ano','SIH_A39_sexo_ano','SIH_A39_idade_ano'),setequal(names(aquisicao$sih),c('SIH_internacoes_diagnostico_ano','SIH_dias_permanencia_diagnostico_ano','SIH_G00_sexo_ano','SIH_A39_sexo_ano','SIH_A39_idade_ano')))
  teste('SIH_territorio',unique(sih$municipio_residencia),config$municipio,all(sih$municipio_residencia==config$municipio))
  teste('SIM_territorio',unique(sim$municipio_residencia),config$municipio,all(sim$municipio_residencia==config$municipio))
  teste('PNI_territorio',unique(pni$codigo_ibge6),config$municipio,all(pni$codigo_ibge6==config$municipio))
  teste('SIH_chave_total_perfil',nrow(sih),length(unique(paste(sih$cid_grupo,sih$ano,sih$medida,sih$tipo_tabela,sih$dimensao,sih$estrato))),!anyDuplicated(sih[c('cid_grupo','ano','medida','tipo_tabela','dimensao','estrato')]))
  teste('SIM_chave_total_perfil',nrow(sim),length(unique(paste(sim$ano,sim$tipo_tabela,sim$dimensao,sim$estrato))),!anyDuplicated(sim[c('ano','tipo_tabela','dimensao','estrato')]))
  for(folder in c(file.path(raiz,'metadados/complementos_20261009'),file.path(destino,'metadados/retomada_20261010'))) {
    for(f in list.files(folder,pattern='[.]json$',full.names=TRUE)) {
      m<-jsonlite::fromJSON(f)
      if(!is.null(m$sha256_html)&&!is.null(m$arquivo_html)) {
        base<-if(grepl('retomada_20261010',folder))destino else raiz
        rawpath<-file.path(base,m$arquivo_html)
        teste(paste0('hash_html_',basename(f)),if(file.exists(rawpath))hash(rawpath)else'ausente',m$sha256_html,file.exists(rawpath)&&hash(rawpath)==m$sha256_html)
      }
    }
  }
  # Registra todas as respostas originais e contratos usados, sem reescreve-los.
  for(folder in c(file.path(raiz,'dados/brutos/complementos_20261009'),file.path(raiz,'dados/brutos/pni_20261009'),file.path(destino,'aquisicao'),file.path(destino,'metadados/retomada_20261010'),file.path(destino,'dados/brutos/retomada_20261010'))) {
    if(dir.exists(folder))for(f in list.files(folder,full.names=TRUE,recursive=TRUE))if(!dir.exists(f))fonte(f,'proveniencia','conforme_contrato','conforme_contrato','conforme_contrato')
  }
  fontes<-do.call(rbind,entradas)
  for(f in c(file.path(raiz,'analise/configuracao.json'),file.path(destino,'preparar_complementos.R'),list.files(file.path(destino,'scripts'),full.names=TRUE,pattern='[.]py$')))fonte(f,'codigo_configuracao')
  fontes<-do.call(rbind,entradas)
  fontes$caminho<-vapply(fontes$caminho,function(x)substring(normalizePath(x,winslash='/',mustWork=TRUE),nchar(raiz)+2L),character(1))
  # Associacao linha -> arquivo bruto quando disponivel (PNI); hashes antigos preservados.
  for(i in which(!is.na(pni$arquivo_bruto))) {
    rel<-pni$arquivo_bruto[i];f<-file.path(dirname(raiz),rel)
    if(!file.exists(f))f<-file.path(raiz,rel)
    if(file.exists(f)) {
      expected<-pni$sha256_bruto[i]
      if(!is.na(expected))teste(paste0('PNI_sha_',i),hash(f),expected,hash(f)==expected)
    } else teste(paste0('PNI_bruto_',i),'ausente','existente',FALSE)
  }
  cobertura_sih<-data.frame(sistema='SIH',ano=mm$ano,dimensao='diagnostico',indicador=paste(mm$cid_grupo,mm$medida,sep=':'),status=mm$status,motivo=ifelse(is.na(mm$valor),'consulta/celula ausente; sem imputacao',''),fonte_id=mm$fonte_id)
  consultas<-expand.grid(ano=anos,cid=c('G00','A87','A39'),dimensao=c('sexo','idade'),stringsAsFactors=FALSE)
  cobertura_perfis<-do.call(rbind,lapply(seq_len(nrow(consultas)),function(i){z<-pp[pp$ano==consultas$ano[i]&pp$cid_grupo==consultas$cid[i]&pp$dimensao==consultas$dimensao[i],];data.frame(sistema='SIH',ano=consultas$ano[i],dimensao=consultas$dimensao[i],indicador=consultas$cid[i],status=if(nrow(z))'perfil_retornado' else 'pendente_consulta',motivo=if(nrow(z))'' else 'consulta pendente',fonte_id=if(nrow(z))z$fonte_id[1]else NA_character_)}))
  cobertura<-rbind(cobertura_sih,cobertura_perfis,data.frame(sistema='SIM',ano=simtotal$ano,dimensao='total_idade',indicador='G00-G03/A39/A87',status='observado',motivo='registro BA; cobertura nacional nao demonstrada',fonte_id=simtotal$fonte_id),data.frame(sistema='PNI',ano=pni$ano,dimensao='cobertura',indicador=paste(pni$indicador_fonte,pni$metodo,sep=':'),status=pni$status,motivo=ifelse(is.na(pni$cobertura_percentual),'ausente; nao imputar zero','metodos separados'),fonte_id=pni$fonte_id))
  tabelas<-list(sih=sih,sim=sim,pni=pni)
  dicionario<-do.call(rbind,lapply(names(tabelas),function(base)do.call(rbind,lapply(names(tabelas[[base]]),function(campo)data.frame(base=base,campo=campo,tipo=paste(class(tabelas[[base]][[campo]]),collapse='/'),descricao=switch(campo,valor='Medida numerica administrativa ou obitos; ver unidade',ano='Ano segundo referencia_tempo',cid_grupo='Folha CID SIH ou conjunto SIM; A39 inclui outras apresentacoes',cobertura_percentual='Percentual oficial; nao harmonizar legado e RNDS',status='Estado da observacao; ausencia difere de zero',tipo_tabela='Total ou marginal; nao somar tipos',fonte_id='Ligacao ao inventario de arquivos',campo),unidade=if(campo=='cobertura_percentual')'%'else if(campo=='valor')'coluna unidade'else'',regra_ausencia='NA preservado; sem imputacao automatica',fonte='contratos oficiais e tabelas preservadas',stringsAsFactors=FALSE)))))
  validacao<-do.call(rbind,valid)
  if(any(!validacao$aprovado&validacao$bloqueante))stop('Controles bloqueantes falharam: ',paste(validacao$controle[!validacao$aprovado&validacao$bloqueante],collapse=', '))
  decisoes<-c('Sem rede na funcao; coletor separado e explicito','Nao somar totais e perfis nem marginais sexo/idade','SIH AIHs/episodios; valores aprovados nominais','A39 nao equivale a meningite exclusiva','SIM registro BA por residencia; sem cobertura nacional demonstrada','PNI legado e RNDS separados; conjugados atuais nao MenC/PCV10 exclusivos','BCG baixo exige ressalva de completude/integracao','Sem letalidade SIM/SINAN; sem pessoas unicas demonstradas','Campos ausentes permanecem NA; nenhum preenchimento de pendencias por zero')
  result<-list(modulos=list(SIH=list(dados=sih,aquisicao=aquisicao$sih),SIM=list(dados=sim),PNI=list(dados=pni,definicoes=definitions,aquisicao=aquisicao$pni)),tabelas=tabelas,dicionario=dicionario,fontes=fontes,cobertura=cobertura,validacao=validacao,decisoes=decisoes)
  for(n in names(tabelas))write.table(tabelas[[n]],file.path(destino,paste0(n,'_candidato.csv')),sep=';',dec='.',na='',row.names=FALSE,fileEncoding='UTF-8')
  for(n in c('dicionario','fontes','cobertura','validacao'))write.table(result[[n]],file.path(destino,paste0(n,'.csv')),sep=';',na='',row.names=FALSE,fileEncoding='UTF-8')
  saveRDS(result,file.path(destino,'candidato.rds'),compress='xz');stopifnot(identical(readRDS(file.path(destino,'candidato.rds')),result))
  writeLines(c('# Candidato de complementos — 10/10/2026',paste('Controles:',nrow(validacao),'; aprovados:',sum(validacao$aprovado)),paste('SIH linhas:',nrow(sih),'; SIM:',nrow(sim),'; PNI grade:',nrow(pni)),paste('PNI coberturas observadas:',sum(!is.na(pni$cobertura_percentual)),'; ausentes:',sum(is.na(pni$cobertura_percentual))),decisoes,'Aquisicao detalhada em aquisicao/RESULTADO_RETOMADA.json e requisicoes.json; historico09/10 preservado.'),file.path(destino,'RELATORIO_CANDIDATO.md'),useBytes=TRUE)
  result
}
