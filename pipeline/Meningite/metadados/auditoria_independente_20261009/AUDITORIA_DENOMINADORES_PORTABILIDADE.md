# Auditoria independente de denominadores e portabilidade

Executada em 09/10/2026 por atribuição do Chat mestre. Escopo: leitura local dos denominadores, plano, documentação operacional e scripts SINAN; único arquivo criado é este relatório. Não houve downloads, instalação, alteração de bases, scripts ou Git. O pacote portátil estava em elaboração durante a leitura; resultados abaixo descrevem o estado observado.

## Resultado dos denominadores

Os 26 controles executados passaram. Foram conferidos os hashes e tamanhos declarados em `Meningite/metadados/DENOMINADORES.json`, unicidade, anos, sexo, território, valores positivos, referência da fonte, reagrupamento e somas anuais. O reagrupamento foi recalculado independentemente com Python padrão, sem executar `preparar_denominadores.py` (que escreve arquivos).

| Arquivo em `Meningite/dados/denominadores` | Linhas de dados | SHA-256 conferido |
|---|---:|---|
| populacao_total.csv | 11 | e0d2f73029bec27820fad805b1eb47e447efdc927db60432060638050e37ad57 |
| populacao_sexo_idade_original.csv | 396 | b0317f55013b789071593a84564bd6e83cf4a90208929c6990f06a290bcf8afa |
| populacao_faixas_sinan.csv | 242 | 71cde10b4bde4ed2734935978b1add9e3a1a6c47cb86df4e2c7345564ef95ee9 |

Há 11 anos completos, 2014–2024; 18 faixas originais × 2 sexos × 11 anos e 11 faixas SINAN × 2 sexos × 11 anos. As chaves são únicas, todos os estratos identificam município 292740 e sexo M/F. Os 242 valores reagrupados coincidem exatamente com a soma das faixas originais segundo a tabela de equivalência do manifesto, inclusive 20–39, 40–59 e 70–79.

| Ano | Total | Soma original | Soma faixas SINAN |
|---|---:|---:|---:|
| 2014 | 2705138 | 2705138 | 2705138 |
| 2015 | 2693763 | 2693763 | 2693763 |
| 2016 | 2682130 | 2682130 | 2682130 |
| 2017 | 2669559 | 2669559 | 2669559 |
| 2018 | 2658252 | 2658252 | 2658252 |
| 2019 | 2647884 | 2647884 | 2647884 |
| 2020 | 2636986 | 2636986 | 2636986 |
| 2021 | 2622913 | 2622913 | 2622913 |
| 2022 | 2607447 | 2607447 | 2607447 |
| 2023 | 2589296 | 2589296 | 2589296 |
| 2024 | 2568928 | 2568928 | 2568928 |

A referência original é `DATASUS_estimativas_municipais_RIPSA_serie_2000_2025`, população residente em 1º de julho. O formulário declarado é `popsvs2024br.def`. A versão de cópia/reagrupamento foi conferida em 05/10/2026. O manifesto afirma a mesma revisão para todos os anos; esta auditoria comprova integridade dos agregados preservados e consistência interna, sem nova verificação da revisão demográfica na fonte. Os totais não trazem município em coluna própria; sua atribuição depende do manifesto e da reconciliação com os estratos que contêm o código. Não há inconsistência numérica observada.

## Portabilidade: verificações e pendências reais

1. **Comando R inline no Windows PowerShell 5.1.** `Boletim epidemiológico/docs/OPERACOES_REPRODUZIVEIS.md`, seção 2, usa `Rscript -e` com aspas duplas internas. Teste local inofensivo: `m <- list(serie_anual=123); print(m$serie_anual); print("ASPAS_PRESERVADAS")`. No PowerShell 7.6.5, retornou 123 e a string; no Windows PowerShell, executado por `-EncodedCommand` para conservar o texto de entrada, retornou 123 e erro `object 'ASPAS_PRESERVADAS' not found`. Portanto, o `$` protegido por aspas simples chegou corretamente neste teste, mas as aspas internas foram removidas pela passagem de argumentos ao executável nativo. Recomendar script `.R` chamado com argumentos; não envolver expressões com `m$campo` em aspas duplas do PowerShell. A linha documental de `readRDS("Meningite/pre_analise_meningite.rds")` está sujeita ao mesmo problema de aspas. Não executamos essa linha completa.

2. **Caminhos dependem da máquina.** A documentação fixa `C:\Pesquisa\Boletim epidemiolóico`, o Python sob `C:\Users\joaov\.cache\codex-runtimes` e R 4.5.1 sob `C:\R\R`. Existem nesta máquina; não são instalações transportáveis por Git. `Get-Command python` apontou para o alias WindowsApps, e Rscript não apareceu no PATH. Usar parâmetros explícitos ou detectar e validar executáveis, versões e pacotes antes da coleta. O coletor Python usa somente biblioteca padrão e passou análise sintática por `ast.parse`, sem executar sua rotina.

3. **Dependências R explícitas.** `processar_sinan_br_historico.R` exige `read.dbc`, `jsonlite` e `digest`, aceita `R_LIBS_USER` e tenta biblioteca Windows sob `LOCALAPPDATA`. Falta de pacote interrompe, sem instalação automática. Em outra máquina é preciso preparar bibliotecas acessíveis; a auditoria não executou o processamento nem atestou bibliotecas fora desta máquina. O teste R sem pacotes produziu avisos locais sobre `C.UTF-8`; a documentação já define `LC_ALL='Portuguese_Brazil.utf8'`. Essa localidade também deve ser validada no sistema de destino.

4. **Raiz e fontes necessárias.** O Python resolve a raiz como pai de `scripts`; R recebe raiz por argumento, com padrão relativo `Meningite`. No pacote `Boletim epidemiológico/pipeline/Meningite`, passar sua raiz explicitamente ao R e usar o coletor dessa cópia. Na inspeção, os 22 arquivos listados em `manifesto_portabilidade.json` existiam e todos os hashes/tamanhos conferiram; os denominadores e snapshot TabNet estão incluídos. O manifesto dos DBC em `dados/brutos/sinan_br_20261009/manifesto.json` não está incluído, coerentemente com a exclusão de brutos. Logo, o processamento integral exige coleta prévia nessa raiz ou transporte externo dos brutos e manifesto; o clone sozinho permite consultar agregados, mas não reler as 13 partições. Rodar a cópia Python criará sua própria pasta de brutos, não reutilizará automaticamente os dados da raiz original.

5. **Transferência entre sistemas operacionais.** O manifesto local registra caminhos com barras invertidas, por exemplo `dados\\brutos\\sinan_br_piloto\\MENIBR24.dbc`. Python e R os consomem diretamente. São adequados no Windows; transportar esse manifesto para Linux/macOS exige normalização das barras ou nova geração local. Não houve teste em outra máquina/sistema.

6. **Data e configuração de execução.** R tem corte fixo `2026-10-09` na contagem de notificações futuras; mudar somente o argumento de versão não atualiza esse corte. Python e R usam períodos fixos 2014–2026/2014–2024, embora o plano também tenha `config/coleta_integral.json`. Essa configuração não é lida pelos dois scripts SINAN. A execução atual está coerente com o plano, mas uma futura extensão necessita alterar regras explícitas ou parametrizá-las; não basta editar o JSON.

7. **Contrato de transporte.** O plano pede código HTTP quando disponível. `Transport.fetch` registra URL, método, início/fim, tentativa, bytes e erro, mas não grava o status HTTP no sucesso nem os parâmetros no próprio item de requisição. Parâmetros do catálogo e lotes são conservados nos contratos separados. Registrar também status HTTP facilitaria auditoria de futuras execuções. Isso não demonstra falha nos dados atuais.

8. **Retomada e identidade da fonte.** Para entradas já presentes no manifesto, o coletor confere existência e hash; a ligação com origem/modalidade do catálogo selecionado não é revalidada nesse trecho. Para o piloto, compara a origem FTP. Recomendar conferir origem/modalidade também nas entradas previamente registradas, antes de reutilizar um catálogo/manifesto migrado. Trata-se de prevenção para futuras migrações; não foi observada mudança de modalidade nesta rodada.

## Encaminhamento ao mestre

Denominadores aprovados quanto à integridade e reconciliação local. Recomendações imediatas: usar arquivo `.R` no lugar do exemplo inline; documentar executáveis/bibliotecas e raiz do pacote; explicitar que brutos são necessários para reproduzir o processamento. Melhorias posteriores: normalizar caminhos em manifestos, parametrizar data/períodos, registrar status HTTP e validar origem/modalidade na retomada. Nenhuma alteração foi aplicada por este chat, para preservar a autoria e coordenação do mestre.
