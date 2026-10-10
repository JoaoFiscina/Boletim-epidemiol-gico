# Controlador da preparação analítica. A fase de inventário não consulta rede.
options(encoding="UTF-8", warn=1)
args <- commandArgs(trailingOnly=TRUE)
raiz <- normalizePath(if(length(args)) args[1] else "Meningite", winslash="/", mustWork=TRUE)
userlib <- Sys.getenv("R_LIBS_USER")
if(nzchar(userlib)) .libPaths(c(userlib,.libPaths()))
for(p in c("jsonlite","digest")) if(!requireNamespace(p,quietly=TRUE)) stop("Dependência ausente: ",p)
config_path <- file.path(raiz,"analise/configuracao.json")
config <- jsonlite::fromJSON(config_path,simplifyVector=TRUE)
stopifnot(config$municipio=="292740", length(config$anos)==11L)
saida <- file.path(raiz,config$destino)
entrada <- file.path(raiz,config$fonte_pacote)
# A leitura binária base R aceita caminhos Unicode que algumas versões de
# digest::digest(file=...) no Windows não conseguem abrir pelo código nativo.
sha256_arquivo <- function(p) {
  tamanho <- file.info(p)$size
  if(is.na(tamanho) || tamanho > 1024^3) stop("Arquivo ausente ou grande demais para o hash local: ",p)
  con <- file(p,"rb"); on.exit(close(con))
  digest::digest(readBin(con,"raw",n=tamanho),algo="sha256",serialize=FALSE)
}
entrada_hash <- sha256_arquivo(entrada)
if(!identical(entrada_hash,config$fonte_pacote_sha256)) stop("Pacote de entrada diverge do hash congelado")
m <- readRDS(entrada)
stopifnot(nrow(m$SINAN$casos_minimos_locais)==config$controles$coorte,
          identical(as.integer(m$SINAN$serie_anual$n),as.integer(config$controles$totais_anuais)))
inventario <- list(versao_analitica=config$versao_analitica,
  fonte=list(caminho=config$fonte_pacote,bytes=unname(file.info(entrada)$size),sha256=entrada_hash),
  municipio=config$municipio,anos=config$anos,
  bibliotecas=.libPaths(),pacotes=vapply(c("jsonlite","digest","ggplot2"),function(p)
    if(requireNamespace(p,quietly=TRUE)) as.character(utils::packageVersion(p)) else "indisponivel",character(1)),
  R=R.version.string,sessionInfo=capture.output(sessionInfo()))
jsonlite::write_json(inventario,file.path(saida,"controle/inventario_entradas.json"),pretty=TRUE,auto_unbox=TRUE,na="null")
cat("Inventário validado; R:",R.version.string,"\n")
cat("Pacotes:\n"); print(inventario$pacotes)
if("--inventario" %in% args) {
  cat("Estrutura SINAN:\n");str(m$SINAN,max.level=1)
  cat("Campos mínimos locais:\n");print(names(m$SINAN$casos_minimos_locais))
  cat("População:\n");str(m$populacao,max.level=1)
  cat("Complementos:\n");str(m[c("SIH","SIM","PNI")],max.level=2)
  quit(status=0)
}

# A preparação utiliza somente arquivos locais. A aquisição seletiva foi uma
# operação separada; sua reexecução não é provocada por este controlador.
if("--relatorio" %in% args) {
  aceito <- readRDS(file.path(saida,"meningites_salvador_analitica.rds"))
  source(file.path(saida,"scripts/gerar_descritivos.R"),encoding="UTF-8")
  escrever_relatorio(aceito,file.path(saida,"resultados/RELATORIO_DESCRITIVO.md"))
  cat("Relatório regenerado sem modificar bases; atualizar hashes de apresentação.\n")
  quit(status=0)
}
if("--figura" %in% args) {
  i <- match("--figura",args)
  if(length(args)<=i) stop("Informe o identificador da figura depois de --figura")
  aceito <- readRDS(file.path(saida,"meningites_salvador_analitica.rds"))
  stopifnot(args[i+1L]%in%aceito$figuras$figura)
  source(file.path(saida,"scripts/gerar_graficos.R"),encoding="UTF-8")
  fig <- gerar_graficos(aceito,config,file.path(saida,"resultados/figuras"),somente=args[i+1L])
  cat("Figura regenerada sem modificar bases:",fig$figura,"; inspeção/hashes devem ser atualizados.\n")
  quit(status=0)
}
for(nome in c("preparar_sinan_populacao","preparar_complementos","gerar_descritivos","gerar_graficos"))
  source(file.path(saida,"scripts",paste0(nome,".R")),encoding="UTF-8")
log_path <- file.path(saida,"controle/execucao.log")
logar <- function(x) {
  linha <- paste(format(Sys.time(),tz="UTC",usetz=TRUE),x)
  cat(linha,"\n");cat(linha,"\n",file=log_path,append=TRUE)
}
logar("Início da preparação offline; configuração efetivamente lida.")
A <- preparar_sinan_populacao(raiz,config,file.path(saida,"trabalho/sinan_populacao"))
B <- preparar_complementos(raiz,config,file.path(saida,"trabalho/complementos"))
uniao <- function(a,b) {
  cols <- union(names(a),names(b))
  for(n in setdiff(cols,names(a))) a[[n]] <- NA
  for(n in setdiff(cols,names(b))) b[[n]] <- NA
  rbind(a[cols],b[cols])
}
V <- uniao(transform(A$validacao,frente="SINAN/populacao"),transform(B$validacao,frente="complementos"))
verificar <- function(id,observado,esperado,ok,bloqueante=TRUE,detalhe="") {
  V <<- rbind(V,data.frame(controle=id,observado=paste(observado,collapse="|"),esperado=paste(esperado,collapse="|"),
    aprovado=isTRUE(ok),bloqueante=bloqueante,detalhe=detalhe,frente="integracao",stringsAsFactors=FALSE))
}
barreira <- function() {
  if(!nrow(V)||any(!V$aprovado & V$bloqueante)) stop("Falha em controles: ",paste(V$controle[!V$aprovado & V$bloqueante],collapse=", "))
}
barreira()
fontes <- uniao(A$fontes,B$fontes)
verificar("fontes_ids_unicos",anyDuplicated(fontes$fonte_id),0L,!anyDuplicated(fontes$fonte_id))
cobertura <- uniao(A$cobertura,B$cobertura)
verificar("cobertura_fontes_existentes",all(na.omit(cobertura$fonte_id)%in%fontes$fonte_id),TRUE,
  all(na.omit(cobertura$fonte_id)%in%fontes$fonte_id))
dados <- c(A$tabelas,B$tabelas)
esperadas <- c("sinan_estratos_anuais","sinan_mensal","sinan_categorias_anuais","populacao","sih","sim","pni")
verificar("sete_bases_canonicas",names(dados),esperadas,setequal(names(dados),esperadas)&&length(dados)==7L)
verificar("campos_originais_conservados_na_integracao",TRUE,TRUE,
  identical(A$modulos$SINAN$casos_minimos_locais[names(m$SINAN$casos_minimos_locais)],m$SINAN$casos_minimos_locais))
dicionario <- uniao(A$dicionario,B$dicionario)
for(nm in names(dados)) {
  verificar(paste0("dicionario_",nm),all(names(dados[[nm]])%in%dicionario$campo[dicionario$base==nm]),TRUE,
    all(names(dados[[nm]])%in%dicionario$campo[dicionario$base==nm]))
}
estado <- data.frame(modulo=c("SINAN","Populacao","SIH","SIM","PNI"),
  status=c("apto","apto","apto_com_limites","apto_com_limites","parcial"),
  limite=c("Registros confirmados; inclui MCC/MNE e incompletude; não pessoas únicas",
    "Integridade local; estimativa em 1º julho",
    "Internações gerais, G00 sexo e A39 idade pendentes; AIHs e ano processamento",
    "Registro BA; cobertura nacional não demonstrada",
    "17 coberturas e 27 lacunas; métodos/geografias separados"),stringsAsFactors=FALSE)
pacote <- c(list(configuracao=config,estado=estado),A$modulos,B$modulos)
pacote$dados <- dados
pacote$documentacao <- list(dicionario=dicionario,fontes=fontes,cobertura=cobertura,
  decisoes=list(nucleo=A$decisoes,complementos=B$decisoes,
    mestre=c("Taxas anuais por população compatível; IC95 exato Poisson",
      "Taxas do período por soma das populações anuais, aproximação de exposição",
      "Hash binário base R para caminhos Unicode; nenhuma instalação de pacotes",
      "Execução padrão offline; retomada seletiva separada e encerrada",
      "Sete bases longas; registros individuais somente no RDS local")))
pacote$resultados <- complementar_descritivos(gerar_descritivos(pacote,config),pacote,config)
T <- pacote$resultados$tabelas
verificar("descritivos_D01_D10",sort(unique(pacote$resultados$descritivos$tabela)),sprintf("D%02d",1:10),
  identical(sort(unique(pacote$resultados$descritivos$tabela)),sprintf("D%02d",1:10)))
verificar("anual_mestre_vs_frente",T$serie_anual$n,A$modulos$SINAN$serie_anual$n,
  identical(as.integer(T$serie_anual$n),as.integer(A$modulos$SINAN$serie_anual$n)))
verificar("taxas_mestre_vs_frente",max(abs(T$serie_anual$taxa_100mil-A$modulos$SINAN$serie_anual$taxa_100mil)),"<1e-10",
  all(abs(T$serie_anual$taxa_100mil-A$modulos$SINAN$serie_anual$taxa_100mil)<1e-10))
verificar("IC_independente_poisson_test",TRUE,TRUE,
  max(abs(stats::poisson.test(T$serie_anual$n[1],T=T$serie_anual$populacao[1],conf.level=config$nivel_confianca)$conf.int*config$taxa_base-
    c(T$serie_anual$ic95_inferior[1],T$serie_anual$ic95_superior[1])))<1e-10)
for(nm in c("etiologia_anual","criterio_anual","evolucao_anual","mensal")) {
  ct <- tapply(T[[nm]]$n,T[[nm]]$ano,sum)
  verificar(paste0("descritivo_fecha_",nm),sum(T[[nm]]$n),config$controles$coorte,
    all(as.integer(ct)==as.integer(config$controles$totais_anuais)))
}
verificar("sexo_ignorado_conservado",sum(T$sexo_periodo$n)+pacote$resultados$resumo$sexo_ignorado,config$controles$coorte,
  sum(T$sexo_periodo$n)+pacote$resultados$resumo$sexo_ignorado==config$controles$coorte)
verificar("perfil_idade_fecha",sum(T$idade_periodo$n),config$controles$coorte,sum(T$idade_periodo$n)==config$controles$coorte)
verificar("evolucao_D_U",c(pacote$resultados$resumo$obitos_meningite,pacote$resultados$resumo$evolucao_desconhecida),c(190,144),
  identical(as.integer(c(pacote$resultados$resumo$obitos_meningite,pacote$resultados$resumo$evolucao_desconhecida)),c(190L,144L)))
barreira()
logar(paste("Frentes integradas; controles até aqui:",nrow(V)))
stage <- file.path(saida,"controle/candidato")
for(d in c("dados","documentacao","resultados/figuras")) dir.create(file.path(stage,d),recursive=TRUE,showWarnings=FALSE)
preparar_csv <- function(d) {
  d[] <- lapply(d,function(v) {if(is.factor(v))v<-as.character(v);if(is.character(v))v[!is.na(v)&v==""]<-NA_character_;v})
  rownames(d) <- NULL;d
}
gravar_csv <- function(d,rel) {
  d <- preparar_csv(d); p <- file.path(stage,rel)
  write.table(d,p,sep=config$csv$sep,dec=config$csv$dec,na=config$csv$na,row.names=FALSE,quote=TRUE,fileEncoding="UTF-8")
  cl <- vapply(d,function(v)if(inherits(v,"Date"))"character" else if(is.integer(v))"integer" else if(is.numeric(v))"numeric" else if(is.logical(v))"logical" else "character",character(1))
  b <- read.csv(p,sep=config$csv$sep,dec=config$csv$dec,na.strings=config$csv$na,colClasses=cl,stringsAsFactors=FALSE,
    check.names=FALSE,fileEncoding="UTF-8")
  for(f in names(d))if(inherits(d[[f]],"Date")) b[[f]]<-as.Date(b[[f]])
  verificar(paste0("exportacao_",basename(rel)),nrow(b),nrow(d),isTRUE(all.equal(d,b,check.attributes=FALSE,tolerance=1e-10)),
    detalhe="Reimportação com tipos explícitos; município como texto; ausências não viram zero.")
}
for(nm in names(dados)) gravar_csv(dados[[nm]],paste0("dados/",nm,".csv"))
gravar_csv(dicionario,"documentacao/dicionario.csv")
gravar_csv(fontes,"documentacao/fontes.csv")
gravar_csv(cobertura,"documentacao/cobertura.csv")
gravar_csv(pacote$resultados$descritivos,"resultados/descritivos.csv")
barreira()
pacote$figuras <- gerar_graficos(pacote,config,file.path(stage,"resultados/figuras"))
verificar("seis_figuras",nrow(pacote$figuras),6L,nrow(pacote$figuras)==6L)
barreira()
pacote$controle <- list(validacao=V,inspecao_visual="Ver QA_VISUAL.json; exige conferência dos arquivos gerados")
candidate_path <- file.path(stage,"meningites_salvador_analitica.rds")
saveRDS(pacote,candidate_path,compress="xz")
verificar("rds_final_releitura",TRUE,TRUE,identical(readRDS(candidate_path),pacote))
barreira();pacote$controle$validacao<-V
saveRDS(pacote,candidate_path,compress="xz")
stopifnot(identical(readRDS(candidate_path),pacote))
escrever_relatorio(pacote,file.path(stage,"resultados/RELATORIO_DESCRITIVO.md"))
destino_rds <- file.path(saida,"meningites_salvador_analitica.rds")
if(file.exists(destino_rds) && sha256_arquivo(destino_rds)!=sha256_arquivo(candidate_path)) {
  anterior <- file.path(saida,"versoes",paste0("anterior-",substr(sha256_arquivo(destino_rds),1,12)))
  dir.create(anterior,recursive=TRUE,showWarnings=FALSE)
  file.copy(destino_rds,file.path(anterior,"meningites_salvador_analitica.rds"),overwrite=FALSE)
  man <- file.path(saida,"controle/manifesto.json")
  if(file.exists(man)) file.copy(man,file.path(anterior,"manifesto.json"),overwrite=FALSE)
}
arquivos_stage <- list.files(stage,recursive=TRUE,full.names=TRUE)
for(p in arquivos_stage) {
  rel <- substring(p,nchar(stage)+2L);final <- file.path(saida,rel)
  dir.create(dirname(final),recursive=TRUE,showWarnings=FALSE)
  if(!file.copy(p,final,overwrite=TRUE)||sha256_arquivo(p)!=sha256_arquivo(final)) stop("Promoção divergente: ",rel)
}
jsonlite::write_json(list(versao=config$versao_analitica,status="aprovado",controles=nrow(V),aprovados=sum(V$aprovado),
  bloqueantes_reprovados=sum(!V$aprovado & V$bloqueante),testes=V,
  limite="Integridade e coerência; não validação clínica ou eficácia vacinal"),file.path(saida,"controle/validacao.json"),pretty=TRUE,auto_unbox=TRUE,na="null")
logar(paste("Preparação/descritivos/figuras concluídos;",sum(V$aprovado),"controles aprovados. Inspeção visual pendente de registro."))
outputs <- c(destino_rds,file.path(saida,"configuracao.json"),list.files(file.path(saida,"scripts"),full.names=TRUE),
  list.files(file.path(saida,"dados"),full.names=TRUE),list.files(file.path(saida,"documentacao"),full.names=TRUE),
  list.files(file.path(saida,"resultados"),recursive=TRUE,full.names=TRUE),file.path(saida,"controle/validacao.json"),log_path)
entradas_finais <- data.frame(caminho=substring(outputs,nchar(raiz)+2L),bytes=file.info(outputs)$size,
  sha256=vapply(outputs,sha256_arquivo,character(1)),stringsAsFactors=FALSE)
aquisicao <- jsonlite::fromJSON(file.path(saida,"trabalho/complementos/aquisicao/RESULTADO_RETOMADA.json"))
jsonlite::write_json(list(versao_analitica=config$versao_analitica,gerado_utc=format(Sys.time(),tz="UTC",usetz=TRUE),
  fonte_pacote=config$fonte_pacote,fonte_sha256=entrada_hash,modo_reproducao="offline",configuracao_sha256=sha256_arquivo(config_path),
  registros_sinan=nrow(pacote$SINAN$casos_minimos_locais),bases_csv=length(dados),figuras=nrow(pacote$figuras),
  validacao_controles=nrow(V),estado=estado,arquivos=entradas_finais,sessionInfo=inventario$sessionInfo,
  aquisicao_adicional=list(sih_post=aquisicao$post_sih,pni_post=aquisicao$post_pni,
    sih_consultas_validas=sum(vapply(aquisicao$sih,function(z)!is.null(z$sha256_html),logical(1))),
    pni_novas_observacoes=sum(!is.na(dados$pni$cobertura_percentual))-config$controles$pni_observados_iniciais),
  inspecao_visual="Consultar QA_VISUAL.json com hashes compatíveis"),file.path(saida,"controle/manifesto.json"),pretty=TRUE,auto_unbox=TRUE,na="null")
cat("PACOTE ACEITO:",destino_rds,"\n")
