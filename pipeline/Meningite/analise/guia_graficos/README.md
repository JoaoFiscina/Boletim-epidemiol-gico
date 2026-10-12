# Guia explicativo dos gráficos — 12/10/2026

Abra **[GUIA_GRAFICOS_MENINGITES.pdf](GUIA_GRAFICOS_MENINGITES.pdf)**. São 35 páginas com os seis gráficos básicos e os oito aprofundados. Cada figura tem uma página própria, seguida de dados e cálculo, modo de leitura, resultados, interpretação possível, limites e legenda sugerida. Índice e marcadores permitem navegar. O PDF contém todas as imagens e pode ser enviado sozinho.

A [fonte em Markdown](GUIA_GRAFICOS_MENINGITES.md) permite editar o texto. As referências oficiais e os resultados aceitos sustentam as explicações. O guia acrescenta glossário, proposta de argumento científico e uma matriz das decisões de revisão. Não é uma revisão sistemática da literatura nem nova coleta ou análise dos modelos.

## Quatro gráficos básicos revisados

| Figura | Alteração de apresentação |
| --- | --- |
| F02 | Painéis empilhados de sexo e idade; contagens e valores das taxas para todas as faixas; escalas próprias declaradas |
| F04 | Total de registros acima de cada ano; distinção explícita entre composição e taxa |
| F05 | Mesma escala entre três códigos CID e contagens escritas; universo hospitalar parcial explicado |
| F06 | Métodos e épocas separados; nove Penta legados e oito indicadores RNDS; 27 lacunas explícitas |

Os novos PNGs estão somente em `figuras_revisadas/`. Os seis gráficos básicos originais, o caderno aprofundado e suas bases permanecem preservados. F01/F03 e G01–G08 são incorporados ao PDF a partir das pastas anteriores, sem duplicar seus arquivos aqui. G07 e G08 têm uso suplementar indicado, por limites inferenciais e de cobertura. PNI é contexto parcial e não permite avaliar eficácia vacinal neste conjunto.

## Reprodução

Os comandos pressupõem a pasta do projeto `Meningite`, com as duas bases RDS aceitas e as figuras anteriores. Em clone do Git, o PDF funciona sozinho e o verificador pode conferir os agregados públicos; as bases RDS não são publicadas. Transportar os dois RDS com os hashes declarados para repetir a geração. Não executar coletores ou modelos para reproduzir este guia.

1. Para regenerar somente os quatro PNGs, use R com ggplot2, patchwork e digest já disponíveis:

```powershell
$env:LC_ALL = 'Portuguese_Brazil.utf8'
$env:R_LIBS_USER = 'C:/Users/joaov/AppData/Local/R/win-library/4.5'
& 'C:/R/R/R-4.5.1/bin/x64/Rscript.exe' 'Meningite/analise/guia_graficos/scripts/revisar_basicos.R' 'C:/Pesquisa/Boletim epidemiolóico/Meningite'
```

2. Para compilar o PDF, use Python com reportlab, Pillow e pypdf, e fontes Arial. O runtime local usado está em `C:/Users/joaov/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`:

```powershell
& 'C:/Users/joaov/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' 'Meningite/analise/guia_graficos/scripts/gerar_guia.py' --raiz 'C:/Pesquisa/Boletim epidemiolóico/Meningite'
```

O parâmetro `--fonte-dir` aceita outra pasta que contenha `arial.ttf`, `arialbd.ttf` e `ariali.ttf`. A compilação bloqueia mudanças de SHA das duas bases. Não há instalação automática. Alterações de texto não justificam recalcular modelos.

3. Confira a entrega, sem mudar arquivos:

```powershell
& 'C:/Users/joaov/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' 'Meningite/analise/guia_graficos/scripts/verificar_guia.py' --raiz 'C:/Pesquisa/Boletim epidemiolóico/Meningite'
```

Em clone sem RDS, acrescente `--agregados`: verifica documento, imagens, QA e manifesto, declarando que as bases locais não foram conferidas. `--repo` permite apontar o Git para conferir também os históricos. Os parâmetros `--selar` e `--sincronizar` são exclusivos deste pacote: não usar verificadores de etapas anteriores para atualizar o guia.

## Qualidade e rastreabilidade

`controle/BUILD_OUTPUT.json` relaciona as 14 figuras, páginas e hashes das entradas. `controle/QA_VISUAL.json` registra inspeção dos 14 PNGs originais, quatro revisões e 35 páginas renderizadas a 150 dpi. Depois de acrescentar o glossário, apenas a página 3 mudou visualmente e foi reinspecionada; as outras 34 mantiveram pixels idênticos. Os PNGs de renderização permanecem no controle local, fora do Git.

`controle/MANIFESTO.json` sela a lista explícita de arquivos entregues. O espelhamento no Git inclui somente guia, quatro figuras revisadas, scripts, README e controles compactos. O verificador confere integridade; não substitui inspeção visual ou auditoria clínica. Novas mudanças invalidam a inspeção afetada: renderizar, olhar as páginas modificadas e registrar hashes antes de selar novamente.

Nesta etapa, os verificadores originais passaram: 352 controles da preparação e 3.447 do aprofundamento, com preservação dos respectivos arquivos históricos. Não foram alterados registros, denominadores, estimativas, intervalos ou lacunas.
