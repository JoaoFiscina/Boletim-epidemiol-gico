# Reune fontes em objetos separados. Nao consulta rede nem cria vinculo entre pessoas.
options(encoding="UTF-8",warn=1)
args <- commandArgs(trailingOnly=TRUE)
root <- normalizePath(if(length(args))args[1]else"Meningite",winslash="/",mustWork=TRUE)
version <- if(length(args)>1)args[2]else"20261009"
stopifnot(grepl("^[0-9]{8}$",version))
userlib <- Sys.getenv("R_LIBS_USER")
if(nzchar(userlib)) .libPaths(c(userlib,.libPaths()))
for(p in c("jsonlite","digest"))if(!requireNamespace(p,quietly=TRUE))stop("Pacote necessario: ",p)
sha <- function(p)digest::digest(file=p,algo="sha256")
inputs <- list()
record <- function(rel) {
  p <- file.path(root,rel);stopifnot(file.exists(p))
  inputs[[length(inputs)+1L]] <<- data.frame(caminho=rel,bytes=file.info(p)$size,sha256=sha(p))
  p
}
csv <- function(rel,sep=";") read.csv(record(rel),sep=sep,fileEncoding="UTF-8-BOM",na.strings="",stringsAsFactors=FALSE,check.names=FALSE)
json <- function(rel)jsonlite::fromJSON(record(rel))
sdir <- paste0("dados/tratados/sinan_br_",version)
cdir <- paste0("dados/tratados/complementos_",version)
pdir <- paste0("dados/tratados/pni_",version)
sinan_meta <- json(paste0("metadados/sinan_br_",version,"/RESULTADO_PROCESSAMENTO.json"))
sinan <- readRDS(record(paste0(sdir,"/meningites_salvador_sinan.rds")))
stopifnot(nrow(sinan$casos_minimos_locais)==sinan_meta$coorte_confirmada,
  sum(sinan$serie_anual$n)==sinan_meta$coorte_confirmada,
  !anyDuplicated(sinan$casos_minimos_locais$hash_tecnico))
pop <- list(total=csv("dados/denominadores/populacao_total.csv",","),
  sexo_idade_original=csv("dados/denominadores/populacao_sexo_idade_original.csv",","),
  faixas_sinan=csv("dados/denominadores/populacao_faixas_sinan.csv"),
  metadados=json("metadados/DENOMINADORES.json"))
stopifnot(identical(as.integer(sinan$serie_anual$populacao),as.integer(pop$total$populacao)))
comp_meta <- json(paste0("metadados/complementos_",version,"/RESULTADO_COLETA_COMPLEMENTOS.json"))
profiles <- csv(paste0(cdir,"/perfis_anuais_longo.csv"))
measures <- csv(paste0(cdir,"/sih_medidas_anuais_longo.csv"))
intern <- csv(paste0(cdir,"/sih_internacoes_anuais_totais_das_marginais.csv"))
checks <- csv(paste0(cdir,"/conferencias.csv"))
stopifnot(all(checks$diferenca==0),!anyDuplicated(intern[c("cid_grupo","ano_processamento")]))
sim_total <- checks[checks$sistema=="SIM"&checks$comparacao=="soma_idade",c("ano","total_oficial"),drop=FALSE]
names(sim_total) <- c("ano_obito","obitos_causa_basica")
sim_total$territorio <- "residencia Salvador; arquivo SIM de registro BA"
sim_total$recorte <- "G00-G03/A39/A87; causa basica"
pni <- csv(paste0(pdir,"/pni_cobertura_municipal_2014_2024_longo.csv"))
pni_available <- csv(paste0(pdir,"/disponibilidade_pni_municipal_2014_2024.csv"))
pni_meta <- json(paste0("metadados/pni_",version,"/validacao_piloto.json"))
stopifnot(nrow(pni)==pni_meta$linhas_observadas,nrow(pni_available)==pni_meta$chaves_solicitadas,
  !anyDuplicated(pni[c("indicador_grupo","ano")]),all(pni$codigo_ibge6==292740))
rnds <- pni[pni$sistema=="PNI_RNDS_individual",,drop=FALSE]
stopifnot(nrow(rnds)==8,all(abs(rnds$cobertura_percentual-100*rnds$numerador_oficial/rnds$denominador_oficial)<1e-8))
state <- data.frame(modulo=c("SINAN","Populacao","SIH","SIM","PNI"),
  status=c("serie nacional concordante; categorias e limites preservados","integridade e somas conferidas",
    "coleta parcial; cinco consultas pendentes","perfil etario conferido; abrangencia nacional nao demonstrada",
    "17 observacoes; 27 chaves pendentes; metodos distintos"),stringsAsFactors=FALSE)
limits <- c("Cada fonte permanece em objeto separado; nao somar como pessoas.",
  "SINAN inclui meningococcemia isolada e seis codigos de etiologia nao padronizados.",
  "SINAN 2023-2026 preliminar no catalogo; evolucao desconhecida em 144 registros da coorte.",
  "SIH usa ano de processamento, valores aprovados e AIHs; CID A39 nao equivale a meningite.",
  "SIM usa ano do obito e causa basica; arquivo BA nao demonstra cobertura de todas as UFs.",
  "PNI legado e RNDS tem metodologias/geografias distintas; cobertura BCG requer auditoria.",
  "O RDS contem uma base minima local SINAN; compartilhar publicamente somente agregados revisados.",
  "Snapshot anterior de SIH/SIM permanece no pre_analise_meningite.rds, nao substitui lacunas atuais.")
package <- list(configuracao=list(municipio="292740",versao=version,periodo_sintomas=2014:2024),
  estado=state,SINAN=sinan,populacao=pop,
  SIH=list(medidas_anuais=measures,internacoes_G00_A87=intern,
    perfis=profiles[profiles$sistema=="SIH",,drop=FALSE],pendencias=comp_meta$pendencias),
  SIM=list(serie_anual=sim_total,perfis=profiles[profiles$sistema=="SIM",,drop=FALSE],
    abrangencia="arquivo BA de registro; municipio de residencia292740; nao nacional confirmado"),
  PNI=list(cobertura=pni,disponibilidade=pni_available,validacao=pni_meta),
  manifestos=list(SINAN=sinan_meta,complementos=comp_meta),limites=limits,
  inventario_entradas=do.call(rbind,inputs))
out <- file.path(root,"dados/tratados",paste0("meningites_salvador_",version,".rds"))
saveRDS(package,out,compress="xz");stopifnot(identical(readRDS(out),package))
meta <- file.path(root,"metadados",paste0("CONSOLIDACAO_",version,".json"))
jsonlite::write_json(list(versao=version,gerado_utc=format(Sys.time(),tz="UTC",usetz=TRUE),
  pacote=basename(out),bytes=file.info(out)$size,sha256=sha(out),estado=state,
  script_sha256=sha(file.path(root,"scripts/consolidar_coleta.R")),entradas=package$inventario_entradas,limites=limits),
  meta,pretty=TRUE,auto_unbox=TRUE,na="null")
cat("CONSOLIDADO:",out,";",file.info(out)$size,"bytes; fontes separadas; releitura identica.\n")
