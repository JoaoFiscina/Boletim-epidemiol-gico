# Leitura sem downloads nem pacotes adicionais; compativel com PowerShell 5.1/7.
args <- commandArgs(trailingOnly=TRUE)
if(!length(args)) stop("Informe o caminho de um arquivo RDS.")
m <- readRDS(args[1])
cat("OBJETOS:\n");print(names(m))
if("SINAN" %in% names(m)) print(m$SINAN$serie_anual) else if("serie_anual" %in% names(m)) print(m$serie_anual)
if("estado" %in% names(m)) print(m$estado)
