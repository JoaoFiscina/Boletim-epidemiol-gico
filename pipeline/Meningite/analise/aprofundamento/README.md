# Meningites em Salvador — aprofundamento analítico

Etapa executada em 12/10/2026 sobre a entrega aprovada de 10/10. Trabalho offline, fonte preservada, sem novos downloads.

- [Relatório com resultados e argumento científico](resultados/RELATORIO_APROFUNDADO.md)
- [Caderno de oito gráficos vetoriais](resultados/figuras/CADERNO_GRAFICOS_APROFUNDADOS.pdf)
- `meningites_aprofundamento.rds`: tabelas por análise, modelos compactos, configuração, validação e fontes; apenas agregados.
- [Cruzamentos e auditoria](dados/cruzamentos_sinan.csv) e [estimativas e sensibilidades](dados/estimativas_e_sensibilidades.csv): dois CSVs canônicos. Arquivos de trabalho são candidatos/revisões e não novas bases concorrentes.
- [Dicionário e decisões](documentacao/dicionario_e_decisoes.json), [proveniência](documentacao/proveniencia.json) e [validação](controle/validacao.json).

## Rodar novamente no PowerShell

```powershell
$env:LC_ALL = 'Portuguese_Brazil.utf8'
$env:R_LIBS_USER = 'C:/Users/joaov/AppData/Local/R/win-library/4.5'
& 'C:/R/R/R-4.5.1/bin/x64/Rscript.exe' 'C:/Pesquisa/Boletim epidemiolóico/Meningite/analise/aprofundamento/scripts/executar_aprofundamento.R' 'C:/Pesquisa/Boletim epidemiolóico/Meningite'
```

O comando recalcula os agregados, modelos, relatório e figuras desta etapa a partir do RDS aprovado. Não baixa dados ou instala pacotes. Uma base com outro SHA exige nova versão e revisão dos filtros. source() dos módulos somente define funções; source() do controlador não executa a etapa.

## Usar no R/RStudio

```r
a <- readRDS('C:/Pesquisa/Boletim epidemiolóico/Meningite/analise/aprofundamento/meningites_aprofundamento.rds')
a$sinan$tabelas$padronizadas_periodos
subset(a$modelos$coeficientes, modelo == 'taxas_principal' & termo == 'sexoM')
e <- read.csv('C:/Pesquisa/Boletim epidemiolóico/Meningite/analise/aprofundamento/dados/estimativas_e_sensibilidades.csv', sep=';', dec='.', na.strings='', fileEncoding='UTF-8')
subset(e, tabela == 'padronizadas_anuais' & medida == 'taxa')
```

Modelo de óbito entrega OR, não razão de riscos. Limites dos ignorados não são IC. Índices de fontes diferentes não ligam pessoas. PNI incompleto, SIM com recorte Bahia e comparação Bahia não liberada para inferência. Partições 2023–2024 preliminares. Consulta de novas fontes é uma etapa separada.

O Git recebe scripts, configuração, agregados e gráficos; os RDS e fontes individuais ficam somente na pasta de trabalho. Reproduzir em outra máquina requer reconstruir a fonte conforme o manual de coleta; o RDS aceito não é distribuído pelo repositório.
