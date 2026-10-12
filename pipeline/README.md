# Código e bases mínimas para reprodução em outra máquina

**Entrada vigente (12/10):** [aprofundamento](Meningite/analise/aprofundamento/README.md), com scripts R, duas tabelas CSV, oito PNGs, caderno PDF, relatório e auditorias. Manifesto próprio no subdiretório; RDS agregado e fontes locais permanecem fora do Git. A preparação de 10/10 e os 45 arquivos de 09/10 abaixo não foram sobrescritos.

**Entrada atual (10/10):** [base analítica](Meningite/analise/README.md) e [relatório descritivo](Meningite/analise/resultados/RELATORIO_DESCRITIVO.md). Sete CSVs, dez conjuntos descritivos, seis PNG/PDF, código R offline e aquisição seletiva documentada. O [novo manifesto](Meningite/analise/manifesto_portabilidade.json) confere a entrega pública. O pacote RDS fica no projeto original. Os arquivos abaixo de 09/10 continuam como snapshot histórico, sem substituição silenciosa.

Este diretório contém o código usado em 09/10/2026, o perfil documental, plano, relatórios, população, benchmark TabNet de 05/10 e agregados novos. Os arquivos têm SHA idêntico aos do projeto original, registrado em `Meningite/manifesto_portabilidade.json`. Brutos e RDS permanecem fora do Git.

A regra `.gitattributes` conserva os bytes do espelho, inclusive finais de linha; não normalizar esses arquivos sem regenerar o manifesto. Foram conferidas 45 cópias e seus tamanhos/hashes, sintaxe dos seis scripts Python, JSON e links locais. Essa conferência não substitui auditoria clínica ou disponibilidade futura da rede.

## Requisitos

Python 3.9+ com biblioteca padrão; R com `read.dbc`, `jsonlite` e `digest` já instalados; PowerShell para os exemplos Windows. Confirme caminhos e `.libPaths()` na própria máquina. Ausência de pacote ou erro DNS é falha operacional, não ausência de caso. Os caminhos pessoais do manual original são exemplos desta máquina, não instalações transportadas pelo Git.

## Recriar a coletaSINAN nacional

No diretório-raiz doGit, usando executáveis disponíveis na máquina:

```powershell
python 'pipeline\Meningite\scripts\coletar_sinan_br_historico.py' --versao 20261009
python 'pipeline\Meningite\scripts\coletar_sinan_br_historico.py' --versao 20261009 --baixar --lote 3 --teto-mb 80
Rscript 'pipeline\Meningite\scripts\processar_sinan_br_historico.R' 'pipeline\Meningite' 20261009
```

O primeiro comando inventaria e pode consultar o catálogo quando ainda não existir localmente. O segundo baixa apenas pendentes; em clone limpo são treze partições, pois os DBC piloto não estão no Git. Em continuação local, reaproveita o que estiver conferido. Se a fonte mudar depois de 09/10, a coleta do amigo terá outra data/hash; não prometer resultados idênticos ao snapshot preservado.

O processamento requer13partições completas, confereSHA, registra o fluxo, produzCSV agregados e umRDS local com base mínima de casos. Usa dados de residênciaSalvador e ano dos sintomas2014–2024. Não corrige automaticamente os seis códigos não padronizados, não elimina pessoas e não publica registros individuais.

O JSON documenta o plano, mas os scripts SINAN usam perfil temporal explícito no código: sintomas 2014–2024 e partições 2014–2026. `--versao` muda a pasta; no R também a data de corte de auditoria. Não basta editar o JSON para ampliar o período. Caminhos SINAN são normalizados, mas os demais metadados guardam os caminhos originais; migração de brutos exige conferir referências locais.

Para abrir o RDS gerado, usar arquivo R em PowerShell 5.1/7, evitando perda de aspas em expressões inline:

```powershell
Rscript 'pipeline\Meningite\scripts\abrir_pacote.R' 'pipeline\Meningite\dados\tratados\sinan_br_20261009\meningites_salvador_sinan.rds'
```

Se um runtime estiver fora doPATH, substitua `python`/`Rscript` pelo caminho completo. O repositório não instala dependências automaticamente.

## Complementos ePNI

Os coletores adicionais estão incluídos e usam biblioteca padrão Python; curl é opcional nos complementos. Ler `--help`, contratos e relatórios antes de executar. SIH/SIM preservou seis consultas válidas e cinco pendências; PNI preservou 17 observações e 27 lacunas. A rede TabNet foi intermitente; respeitar tentativas e retomar faltantes. Metadados de finalização dependem de formulários/respostas brutas e cópias/proveniência do legado: transportar esses arquivos externamente ou coletar em novo lote. A existência de um script não garante coleta completa.

`consolidar_coleta.R` reúne fontes em RDS local depois de gerar/transferir o RDS SINAN e metadados de cada coleta. O Git permite leitura dos CSVs agregados imediatamente; não contém todos os arquivos necessários para refazer a finalização offline dos complementos ou PNI sem coleta/transferência.

Os CSVs públicos aqui incluídos são snapshots para consulta e conferência. Não somar fontes diferentes. O relatório e os metadados indicam quais módulos e campos estão pendentes.
