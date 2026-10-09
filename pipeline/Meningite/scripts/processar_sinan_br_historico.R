# Processamento local das particoes nacionais: dados municipais, auditoria e agregados.
# Nao consulta rede, nao mistura snapshots TabNet e nao elimina repeticoes clinicas.
options(encoding="UTF-8", warn=1)
args <- commandArgs(trailingOnly=TRUE)
root <- normalizePath(if(length(args)) args[1] else "Meningite",winslash="/",mustWork=TRUE)
version <- if(length(args)>1) args[2] else "20261009"
stopifnot(grepl("^[0-9]{8}$",version))
audit_date <- as.Date(version,format="%Y%m%d")
stopifnot(!is.na(audit_date))
userlib <- Sys.getenv("R_LIBS_USER")
if(nzchar(userlib)) .libPaths(c(userlib,.libPaths()))
fallback <- file.path(Sys.getenv("LOCALAPPDATA"),"R/win-library",paste(R.version$major,sub("\\..*$","",R.version$minor),sep="."))
if(dir.exists(fallback)) .libPaths(c(fallback,.libPaths()))
for(p in c("read.dbc","jsonlite","digest")) if(!requireNamespace(p,quietly=TRUE)) stop("Pacote instalado necessario:",p,". Não instalar automaticamente.")
raw <- file.path(root,paste0("dados/brutos/sinan_br_",version))
out <- file.path(root,paste0("dados/tratados/sinan_br_",version))
meta <- file.path(root,paste0("metadados/sinan_br_",version))
dir.create(out,recursive=TRUE,showWarnings=FALSE)
dir.create(meta,recursive=TRUE,showWarnings=FALSE)
sha_file <- function(p) digest::digest(file=p,algo="sha256")
registry <- jsonlite::fromJSON(file.path(raw,"manifesto.json"))
entries <- registry$arquivos
expected <- sprintf("MENIBR%02d.dbc",14:26)
stopifnot(nrow(entries)==13,setequal(entries$nome_original,expected),!anyDuplicated(entries$nome_original))
entries <- entries[order(entries$nome_original),,drop=FALSE]
norm <- function(x) { z<-trimws(as.character(x));z[is.na(x)|z==""]<-NA_character_;z }
code <- function(x) { z<-norm(x);z[!is.na(z)&!grepl("^[0-9]+$",z)]<-NA_character_;suppressWarnings(as.integer(z)) }
dates <- function(x) if(inherits(x,"Date")) x else suppressWarnings(as.Date(norm(x)))
column <- function(d,f) if(f %in% names(d)) norm(d[[f]]) else rep(NA_character_,nrow(d))
write_csv <- function(d,name) write.table(d,file.path(out,name),sep=";",quote=TRUE,row.names=FALSE,na="",fileEncoding="UTF-8")
tally <- function(d,vars) {
  dd<-d[vars];dd[]<-lapply(dd,function(x){ z<-as.character(x);z[is.na(z)|z==""]<-"Ign/Branco";z })
  if(!nrow(dd)){dd$n<-integer(0);return(dd)}
  ans<-aggregate(rep(1L,nrow(dd)),dd,sum);names(ans)[ncol(ans)]<-"n"
  ans[do.call(order,ans[vars]),,drop=FALSE]
}
label_code <- function(x,values,labels,unknown="Ign/Branco",ignored=c("9"),normalize_numeric=TRUE) {
  z<-norm(x); original<-z
  if(normalize_numeric&&all(grepl("^[0-9]+$",values)))z<-as.character(code(x))
  out<-rep(unknown,length(z));m<-match(z,values)
  ok<-!is.na(m);out[ok]<-labels[m[ok]]
  unexpected<-!is.na(original)&!ok&!(z%in%ignored)
  out[unexpected]<-paste0("Codigo nao mapeado:",original[unexpected]);out
}
age <- function(x) {
  v<-code(x);u<-v%/%1000;n<-v%%1000;y<-rep(NA_real_,length(v))
  for(k in 1:4){ii<-which(u==k);y[ii]<-n[ii]/c(365.25*24,365.25,12,1)[k]}
  ok<-!is.na(u)&u%in%1:4&!is.na(y)&y>=0&y<=120
  f<-as.character(cut(y,c(-Inf,1,5,10,15,20,40,60,65,70,80,Inf),right=FALSE,
    labels=c("<1 Ano","1-4","5-9","10-14","15-19","20-39","40-59","60-64","65-69","70-79","80 e +")))
  f[!ok]<-"Ign/Em Branco"
  list(anos=y,faixa=f,interpretavel=ok,unidade=u)
}
etiol<-c("MCC","MM","MM+MCC","MTBC","MB","MNE","MV","MOE","MH","MP")
criteria<-c("Cultura","CIE","AG. Latex","Clínico","Bacterioscopia","Quimiocitológico","Clínico-epidemiológico","Isolamento viral","PCR","Outra técnica")
months<-c("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")
secondary<-c("CS_RACA","CS_ESCOL_N","CLA_SOROGR","CLA_ME_BAC","CLA_ME_ASS","CLA_ME_ETI",
  "ATE_HOSPIT","ATE_INTERN","LAB_PUNCAO","LAB_CTLIQU","LAB_PCLIQU","LAB_PCSANG",
  "ANT_CONJ_C","ANT_PNEUMO","ANT_HEMO_T","ANT_BCG","ANT_AC","ANT_BC","ANT_TRIPLI",
  "ANT_AIDS","ANT_IMUNO","MED_QUIMIO")
core<-c("ID_MN_RESI","CLASSI_FIN","DT_SIN_PRI","DT_NOTIFIC","CS_SEXO","NU_IDADE_N","CON_DIAGES","CRITERIO","EVOLUCAO","SG_UF_NOT")
flow<-list();schemas<-list();baseparts<-list();sources<-list()
for(i in seq_len(nrow(entries))) {
  path<-file.path(root,gsub("\\", "/", entries$caminho[i],fixed=TRUE));stopifnot(file.exists(path),tolower(sha_file(path))==tolower(entries$sha256[i]))
  d<-read.dbc::read.dbc(path,as.is=TRUE)
  stopifnot(all(core%in%names(d)))
  schemas[[i]]<-data.frame(arquivo=basename(path),campo=names(d),classe=vapply(d,function(x)paste(class(x),collapse="/"),character(1)))
  res<-norm(d$ID_MN_RESI)=="292740";res[is.na(res)]<-FALSE
  confirmed<-res&code(d$CLASSI_FIN)==1;confirmed[is.na(confirmed)]<-FALSE
  sint<-dates(d$DT_SIN_PRI);not<-dates(d$DT_NOTIFIC);year<-as.integer(format(sint,"%Y"))
  chosen<-confirmed&!is.na(year)&year>=2014&year<=2024;chosen[is.na(chosen)]<-FALSE
  flow[[i]]<-data.frame(arquivo=basename(path),n_nacional=nrow(d),n_residentes=sum(res),n_confirmados=sum(confirmed),
    n_confirmados_sem_data=sum(confirmed&is.na(sint)),n_confirmados_fora_janela=sum(confirmed&!is.na(year)&!year%in%2014:2024),
    n_coorte=sum(chosen),n_not_antes_sintomas=sum(chosen&!is.na(not)&not<sint),n_not_sem_data=sum(chosen&is.na(not)),
    n_not_futura=sum(chosen&!is.na(not)&not>audit_date))
  dr<-d[confirmed,,drop=FALSE]
  a<-age(dr$NU_IDADE_N);dt_s<-dates(dr$DT_SIN_PRI);dt_n<-dates(dr$DT_NOTIFIC)
  # Hash original identifica apenas repeticoes tecnicas exatas; nao e identificador de pessoa.
  technical<-if(nrow(dr))vapply(seq_len(nrow(dr)),function(j)digest::digest(lapply(dr[j,,drop=FALSE],unname),algo="sha256"),character(1)) else character(0)
  b<-data.frame(arquivo_origem=rep(basename(path),nrow(dr)),hash_tecnico=technical,
    ano_sintomas=as.integer(format(dt_s,"%Y")),mes_sintomas=as.integer(format(dt_s,"%m")),
    ano_notificacao=as.integer(format(dt_n,"%Y")),dias_sintomas_notificacao=as.numeric(dt_n-dt_s),
    sexo_codigo=norm(dr$CS_SEXO),idade_codigo=norm(dr$NU_IDADE_N),idade_anos_aproximados=a$anos,
    idade_interpretavel=a$interpretavel,faixa_etaria=a$faixa,etiologia_codigo=norm(dr$CON_DIAGES),
    evolucao_codigo=norm(dr$EVOLUCAO),criterio_codigo=norm(dr$CRITERIO),uf_notificacao_codigo=norm(dr$SG_UF_NOT),
    sintomas_sem_data=is.na(dt_s),notificacao_sem_data=is.na(dt_n),
    evolucao_sem_data=if("MED_DT_EVO"%in%names(dr))is.na(dates(dr$MED_DT_EVO))else rep(TRUE,nrow(dr)),
    encerramento_sem_data=if("DT_ENCERRA"%in%names(dr))is.na(dates(dr$DT_ENCERRA))else rep(TRUE,nrow(dr)),stringsAsFactors=FALSE)
  for(f in secondary)b[[f]]<-column(dr,f)
  baseparts[[i]]<-b
  sources[[i]]<-list(arquivo=basename(path),sha256=entries$sha256[i],modalidade=entries$modalidade[i],
    n_nacional=nrow(d),n_campos=ncol(d),n_coorte=sum(chosen),data_fonte_utc=entries$data_fonte_utc[i])
  cat("LIDO",basename(path),": nacionais",nrow(d),"; coorte",sum(chosen),"\n");flush.console()
  rm(d,dr,b);invisible(gc())
}
all_confirmed<-do.call(rbind,baseparts)
cohort<-all_confirmed[!is.na(all_confirmed$ano_sintomas)&all_confirmed$ano_sintomas%in%2014:2024,,drop=FALSE]
flows<-do.call(rbind,flow)
stopifnot(sum(flows$n_coorte)==nrow(cohort),all(cohort$ano_sintomas%in%2014:2024))
cohort$sexo<-label_code(cohort$sexo_codigo,c("M","F"),c("Masculino","Feminino"),unknown="Ignorado",ignored=c("I","9"))
# CON_DIAGES tem categorias canonicas01-10. O TabNet omite valores7/7./7%/%7/X.
# Preservar esses registros sem inferir sua etiologia pela aparencia do codigo.
cohort$etiologia<-label_code(cohort$etiologia_codigo,sprintf("%02d",1:10),etiol,
  unknown="IGN/EM BRANCO",ignored=character(0),normalize_numeric=FALSE)
cohort$evolucao<-label_code(cohort$evolucao_codigo,as.character(1:3),c("Alta","Óbito por meningite","Óbito por outra causa"))
cohort$criterio<-label_code(cohort$criterio_codigo,as.character(1:10),criteria,unknown="Em branco")
cohort$grupo_etiologia<-cohort$etiologia
cohort$grupo_etiologia[cohort$etiologia%in%c("MCC","MM","MM+MCC")]<-"Doenca meningococica incluiMCC"
cohort$grupo_etiologia[cohort$etiologia%in%c("MB","MH","MP")]<-"Outras bacterianas MB/MH/MP"
cohort$duplicata_tecnica<-duplicated(cohort$hash_tecnico)|duplicated(cohort$hash_tecnico,fromLast=TRUE)
write_csv(flows,"fluxos_selecao.csv")
write_csv(do.call(rbind,schemas),"esquema_campos.csv")
annual<-data.frame(ano=2014:2024,n=as.integer(table(factor(cohort$ano_sintomas,levels=2014:2024))))
stopifnot(sum(annual$n)==nrow(cohort))
pop<-read.csv(file.path(root,"dados/denominadores/populacao_total.csv"),fileEncoding="UTF-8-BOM")
stopifnot(setequal(pop$ano,annual$ano),!anyDuplicated(pop$ano),all(pop$populacao>0))
annual<-merge(annual,pop,by="ano",sort=TRUE)
annual$taxa_registrada_100mil<-annual$n/annual$populacao*100000
annual$municipio_residencia<-"292740";annual$referencia_temporal<-"primeiros_sintomas"
annual$taxa_ic95_inferior<-ifelse(annual$n==0,0,qchisq(.025,2*annual$n)/2)/annual$populacao*100000
annual$taxa_ic95_superior<-qchisq(.975,2*(annual$n+1))/2/annual$populacao*100000
write_csv(annual,"serie_anual.csv")
monthly<-tally(cohort,c("ano_sintomas","mes_sintomas"))
write_csv(monthly,"serie_mensal.csv")
marginals<-list()
for(v in c("sexo","faixa_etaria","etiologia","evolucao","criterio")) {
  t<-tally(cohort,c("ano_sintomas",v));names(t)<-c("ano","categoria","n");t$dimensao<-v
  stopifnot(sum(t$n)==nrow(cohort));marginals[[v]]<-t
}
marginals<-do.call(rbind,marginals)
write_csv(marginals,"marginais_anuais.csv")
joint<-tally(cohort,c("ano_sintomas","sexo","faixa_etaria","etiologia","evolucao"))
stopifnot(sum(joint$n)==nrow(cohort));write_csv(joint,"base_conjunta_agregada.csv")
write_csv(tally(cohort,c("ano_sintomas","ano_notificacao","uf_notificacao_codigo")),"notificacoes_tardias_uf.csv")
# Dominios mantem codigo original, vazio e valores inesperados para revisao de versao.
dom<-list()
for(f in c("sexo_codigo","idade_codigo","etiologia_codigo","evolucao_codigo","criterio_codigo","uf_notificacao_codigo",secondary)) {
  t<-tally(cohort,c("ano_sintomas",f));names(t)<-c("ano","codigo_original","n");t$campo<-f;dom[[f]]<-t
}
write_csv(do.call(rbind,dom),"dominios_anuais.csv")
quality<-list()
for(y in 2014:2024) {
  z<-cohort[cohort$ano_sintomas==y,,drop=FALSE]
  present<-list(sexo=z$sexo_codigo%in%c("M","F"),idade=z$idade_interpretavel,
    etiologia_categoria=z$etiologia_codigo%in%sprintf("%02d",1:10),
    evolucao=code(z$evolucao_codigo)%in%1:3,criterio=code(z$criterio_codigo)%in%1:10,
    raca_cor=z$CS_RACA%in%as.character(1:5),
    hospitalizacao=z$ATE_HOSPIT%in%c("1","2"),
    internacao=z$ATE_INTERN%in%c("1","2"))
  for(f in names(present))quality[[paste(y,f)]]<-data.frame(ano=y,campo=f,universo="coorte_confirmada",total=nrow(z),
    n_conhecido=sum(present[[f]]),n_ausente_ignorado_nao_interpretavel=sum(!present[[f]]),
    percentual=if(nrow(z))100*mean(present[[f]])else NA_real_)
  # Codigo preenchido em secundarios NAO prova aplicabilidade, agente ou vacina.
  for(f in secondary)quality[[paste(y,f,"preenchido")]]<-data.frame(ano=y,campo=paste0(f,"_nao_vazio"),
    universo="coorte_confirmada_avaliar_aplicabilidade",total=nrow(z),n_conhecido=sum(!is.na(z[[f]])),
    n_ausente_ignorado_nao_interpretavel=sum(is.na(z[[f]])),percentual=if(nrow(z))100*mean(!is.na(z[[f]]))else NA_real_)
}
quality<-do.call(rbind,quality);write_csv(quality,"qualidade_anual.csv")
applicable<-cohort[cohort$etiologia%in%c("MCC","MM","MM+MCC"),,drop=FALSE]
write_csv(tally(applicable,c("ano_sintomas","etiologia","CLA_SOROGR")),"sorogrupo_entre_doenca_meningococica.csv")
labcols<-intersect(c("LAB_CTLIQU","LAB_PCLIQU","LAB_PCSANG"),names(cohort))
lab<-list()
for(f in labcols){t<-tally(cohort,c("ano_sintomas","etiologia","criterio_codigo",f));names(t)<-c("ano","etiologia","criterio_codigo","codigo_resultado","n");t$exame<-f;lab[[f]]<-t}
write_csv(do.call(rbind,lab),"tecnica_etiologia_laboratorio.csv")
date_audit<-data.frame(arquivo=all_confirmed$arquivo_origem,ano_sintomas=all_confirmed$ano_sintomas,
  sintomas_sem_data=all_confirmed$sintomas_sem_data,notificacao_sem_data=all_confirmed$notificacao_sem_data,
  notificacao_antes_sintomas=!is.na(all_confirmed$dias_sintomas_notificacao)&all_confirmed$dias_sintomas_notificacao<0)
write_csv(tally(date_audit,names(date_audit)),"auditoria_datas_confirmados_todos.csv")
comparison<-list()
tabpath<-file.path(root,"dados/tratados/sinan/meningite_sinan_longo.csv")
tn<-read.csv(tabpath,sep=";",fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE)
for(axis in c("total_sem_coluna","sexo","idade","evolucao","criterio","etiologia","mes_sintomas"))for(y in 2014:2024){
  old<-tn[tn$consulta==axis&tn$ano==y,c("categoria","n"),drop=FALSE];names(old)[2]<-"n_tabnet"
  if(!nrow(old))next
  z<-cohort[cohort$ano_sintomas==y,,drop=FALSE]
  if(axis=="total_sem_coluna") national<-data.frame(categoria="Todos os casos confirmados",n_br=nrow(z)) else {
    v<-switch(axis,idade="faixa_etaria",mes_sintomas="mes_sintomas",axis)
    zz<-z
    if(axis=="mes_sintomas")zz[[v]]<-months[z$mes_sintomas]
    if(axis=="criterio")zz[[v]][zz[[v]]=="PCR"]<-"PCR - viral" # equivalencia de rotulo somente na comparacao
    national<-tally(zz,v);names(national)<-c("categoria","n_br")
  }
  m<-merge(old,national,by="categoria",all=TRUE)
  m$n_br[is.na(m$n_br)]<-0L # ausencia na coorte integralmente lida significa categoria observada comzero
  m$diferenca_br_menos_tabnet<-m$n_br-m$n_tabnet;m$ano<-y;m$consulta<-axis
  comparison[[paste(axis,y)]]<-m
}
comparison<-do.call(rbind,comparison);write_csv(comparison,"comparacao_tabnet_snapshot20261005.csv")
general_cmp<-comparison[comparison$consulta=="total_sem_coluna",,drop=FALSE]
stopifnot(nrow(general_cmp)==11,!anyNA(general_cmp$n_br),sum(general_cmp$n_br)==nrow(cohort))
unexpected<-cohort[!is.na(cohort$etiologia_codigo)&!cohort$etiologia_codigo%in%sprintf("%02d",1:10),,drop=FALSE]
write_csv(tally(unexpected,c("ano_sintomas","etiologia_codigo","arquivo_origem")),"etiologia_codigos_fora_dominio_1_10.csv")
dups<-data.frame(grupos_hash_repetidos=length(unique(cohort$hash_tecnico[duplicated(cohort$hash_tecnico)])),
  linhas_em_grupos_repetidos=sum(cohort$duplicata_tecnica),linhas_excedentes=sum(duplicated(cohort$hash_tecnico)),linhas_removidas=0)
write_csv(dups,"duplicatas_tecnicas.csv")
package<-list(configuracao=list(municipio="292740",periodo=2014:2024,versao=version),
  casos_minimos_locais=cohort,serie_anual=annual,serie_mensal=monthly,marginais=marginals,conjunto=joint,
  qualidade=quality,comparacao_tabnet=comparison,fluxos=flows,fontes=sources,
  limites=c("nao exportar casos individuais aoGit", "pessoas unicas nao validadas", "nao excluir MNE/MCC sem regra",
    "codigoPCR geral nao provaagente", "completude de datas filtradas nao mede total semdata", "TabNet preservado em05/10/2026; fontes podem ter datasdistintas"))
rds<-file.path(out,"meningites_salvador_sinan.rds");saveRDS(package,rds,compress="xz");stopifnot(identical(readRDS(rds),package))
result<-list(status=if(all(general_cmp$diferenca_br_menos_tabnet==0))"serie_nacional_geral_concordante_demais_auditorias_documentadas" else "serie_nacional_lida_divergencia_snapshot_pendente",
  versao=version,data_corte_auditoria=as.character(audit_date),gerado_utc=format(Sys.time(),tz="UTC",usetz=TRUE),particoes_lidas=13,registros_nacionais=sum(flows$n_nacional),
  residentes_confirmados_todas_datas=nrow(all_confirmed),coorte_confirmada=nrow(cohort),
  confirmados_sem_data=sum(all_confirmed$sintomas_sem_data),confirmados_fora_janela=sum(flows$n_confirmados_fora_janela),
  notificados_foraBA=sum(!is.na(cohort$uf_notificacao_codigo)&cohort$uf_notificacao_codigo!="29"),
  n_MNE=sum(cohort$etiologia=="MNE"),n_MCC=sum(cohort$etiologia=="MCC"),
  n_etiologia_fora_dominio=nrow(unexpected),n_etiologia_vazia=sum(is.na(cohort$etiologia_codigo)),
  regra_etiologia="dominio canonicoCON_DIAGES01-10; seis codigosnao padronizados preservados, sem correcao automatica",
  n_evolucao_desconhecida=sum(!code(cohort$evolucao_codigo)%in%1:3),
  diferenca_total_por_ano=general_cmp,duplicatas_tecnicas=dups,
  n_linhas_comparacao=nrow(comparison),n_celulas_comparadas=sum(!is.na(comparison$n_tabnet)),n_celulas_diferenca_observada=sum(comparison$diferenca_br_menos_tabnet!=0,na.rm=TRUE),
  n_categorias_nacionais_sem_equivalente_tabnet=sum(is.na(comparison$n_tabnet)),
  fontes=sources,script_sha256=sha_file(file.path(root,"scripts/processar_sinan_br_historico.R")),
  tabnet_snapshot_sha256=sha_file(tabpath),pacote=list(arquivo=rds,sha256=sha_file(rds),bytes=file.info(rds)$size),
  limites=package$limites)
result$saidas<-lapply(list.files(out,full.names=TRUE),function(p)list(arquivo=basename(p),bytes=file.info(p)$size,sha256=sha_file(p)))
jsonlite::write_json(result,file.path(meta,"RESULTADO_PROCESSAMENTO.json"),pretty=TRUE,auto_unbox=TRUE,na="null")
cat("CONCLUIDO: coorte",nrow(cohort),";foraBA",result$notificados_foraBA,";etiologia fora1-10",result$n_etiologia_fora_dominio,
  ";vazia",result$n_etiologia_vazia,";divergenciasgerais",sum(general_cmp$diferenca_br_menos_tabnet!=0),"\n")
