# Coleta ampliada SIH/SIM: Salvador, 2014–2024

Rodada de 9 de outubro de 2026. **Foram obtidas e conferidas 6 das 11 consultas planejadas. O teto de 24 tentativas POST foi atingido; cinco consultas permanecem pendentes.** As respostas válidas, contratos, hashes, tabelas e erros foram preservados em `complementos_20261009`, sem alterar os pilotos anteriores. Nenhuma nova consulta será realizada nesta rodada.

## Resultados realmente coletados

| Consulta | Medida e abrangência | Resultado 2014–2024 | Situação |
|---|---|---:|---|
| SIM idade × ano | Óbitos por causa básica; residentes de Salvador; G00–G03/A39/A87 | 202 óbitos | Completa: onze anos, faixas de idade e totais conservados |
| SIH diagnóstico × ano — óbitos | Altas por óbito; residência Salvador; rede SUS nacional | 75 óbitos nas internações | Completa: grupos identificados separadamente |
| SIH diagnóstico × ano — valor total | Produção administrativa aprovada, valores nominais | R$ 2.354.667,12 | Completa: grupos separados e centavos preservados |
| SIH G00 idade × ano | Internações por meningite bacteriana não classificada em outra parte | 532 internações | Completa: onze anos |
| SIH A87 sexo × ano | Internações por meningite viral | 489 internações | Completa: onze anos |
| SIH A87 idade × ano | Internações por meningite viral | 489 internações | Completa: onze anos |

Os totais anuais oficiais das marginais de G00 e A87 também foram preservados em uma tabela de 22 linhas, uma por CID × ano. As marginais de sexo e idade de A87 concordam entre si; elas são duas conferências do mesmo total, e não registros a adicionar. Esta derivação fornece contagens anuais novas de G00/A87 apesar da falha da consulta geral de internações por diagnóstico.

### Medidas hospitalares por grupo

| Grupo | Óbitos nas internações | Valores nominais aprovados |
|---|---:|---:|
| G00 | 49 | R$ 1.416.229,43 |
| A87 | 10 | R$ 601.345,64 |
| A39 | 13 | R$ 300.824,66 |
| G01 | Linha não retornada para óbitos | R$ 44,22 |
| G02 | 1 | R$ 17.868,08 |
| G03 | 2 | R$ 18.355,09 |

G01 sem linha de óbitos permanece sem valor no CSV. A ausência de linha não foi automaticamente transformada em zero. A39 inclui outras apresentações de infecção meningocócica além da meningite.

### Idade no SIM

A consulta de idade que estava pendente no piloto foi resolvida. As faixas retornadas somam os totais em todos os onze anos. O período registra 9 óbitos em menores de 1 ano, 8 em 1–4 anos, 5 em 5–9, 6 em 10–14, 9 em 15–19, 20 em 20–29, 24 em 30–39, 20 em 40–49, 37 em 50–59, 24 em 60–69, 24 em 70–79 e 16 em 80+. Os 202 óbitos referem-se ao **conjunto filtrado**, sem cruzamento individual de idade por etiologia/CID nesta consulta.

O filtro e os totais anuais coincidem com o piloto: 34, 19, 19, 15, 22, 14, 14, 11, 14, 18 e 22. A versão do SIM permanece final até 2024, com extração oficial indicada em 02/12/2025. Os anos 2025/2026 não foram acrescentados.

## Conferência de qualidade e conservação

Foram concluídas **77 comparações de conservação**, todas com diferença zero depois de considerar a hierarquia da tabela SIH. Os CSVs longos têm chaves explícitas e sem duplicação. Os hashes das seis respostas válidas e dos arquivos tratados foram conferidos mecanicamente.

As tabelas oficiais SIH incluem capítulos e subtotais mesmo quando se selecionam seis diagnósticos. A soma inicial de todas as linhas apontou duplicação por categorias-pai. A conferência passou a somar **somente as folhas G00–G03/A39/A87**, preservando as tabelas originais. Não agregar diretamente todos os registros dos CSVs terminados em `_tabela.csv`.

Há 77 comparações numéricas possíveis com o piloto anterior de internações/óbitos. Nenhuma apresentou revisão numérica. As combinações que não têm observação na rodada nova continuam assinaladas como ausência em uma versão, e não como queda a zero. Os snapshots não foram emendados.

Os perfis de idade SIH/SIM e o perfil de sexo A87 conservam seus totais anuais. Isso mostra consistência das marginais retornadas; não valida clinicamente os diagnósticos, não identifica pessoas únicas e não substitui auditoria da confirmação e evolução no SINAN.

## Cinco consultas pendentes

| Consulta | Estado final | Retomada |
|---|---|---|
| SIH internações por diagnóstico × ano | Falhas DNS/timeout | Solicitar somente este item; G00/A87 já têm totais das marginais |
| SIH dias de permanência por diagnóstico × ano | Timeout | Solicitar somente este item |
| SIH G00 sexo × ano | Timeout | Solicitar somente este item |
| SIH A39 sexo × ano | Timeout; teto atingido antes da segunda tentativa final | Solicitar somente este item |
| SIH A39 idade × ano | Não executada por esgotamento do teto | Solicitar somente este item |

O script reutiliza respostas válidas existentes e confere seus hashes e parâmetros antes de preparar qualquer download. O teto acumulado desta versão continua em 24 POST. **Aumentar o teto ou iniciar uma nova rodada requer uma decisão explícita; ele não se renova sozinho.**

## Transporte e limites

- Limite inicial: 12 POST. O coordenador ajustou explicitamente a 24 após falhas de DNS, mantendo onze consultas de dados distintas como máximo da rodada e duas tentativas por item em cada execução.
- Realizados: 24 POST, entre sucessos e falhas, todos registrados em `requisicoes.json`.
- Teto de dados brutos: 100 MiB. Armazenados: 1.065.310 bytes, aproximadamente 1,02 MiB. Não houve download de SIH-RD nacional ou de microdados individuais.
- Foram observadas falhas `WinError 10060`, `Errno 11001` e timeouts do curl. As chamadas foram executadas com autorização de rede pública; não houve rejeição de aprovação automática.
- O SIM respondeu por HTTPS. O SIH teve respostas HTTPS intermitentes; sua leitura atual do formulário também foi obtida pela versão HTTP pública. O hash do formulário atual SIH é idêntico ao preservado no piloto, confirmando rótulos e valores dos parâmetros.
- O IP usado no diagnóstico/recuperação foi observado no DNS do computador, com hostname e validação TLS preservados nas consultas HTTPS. O script não fixa esse IP para execuções futuras.

## Escopo dos arquivos e unidades

| Arquivo tratado | Grão | Uso correto |
|---|---|---|
| `sih_medidas_anuais_longo.csv` | CID × ano de processamento × medida | Óbitos e valores aprovados em colunas/unidades explícitas; internações gerais e dias ainda ausentes |
| `perfis_anuais_longo.csv` | Consulta × dimensão × estrato × ano | Marginais de idade ou sexo; SIH e SIM separados |
| `sih_internacoes_anuais_totais_das_marginais.csv` | CID × ano de processamento | Um total por chave; múltiplas origens concordantes documentadas sem soma |
| `comparacao_piloto_versoes.csv` | CID × ano × medida | Comparação entre versões; ausência mantida explícita |
| `conferencias.csv` | Comparação × CID/conjunto × ano | Auditoria de conservação; não é uma base de eventos |
| `*_tabela.csv` | Reprodução da tabela oficial | Consulta e rastreio; a hierarquia SIH contém subtotais |

Internações SIH aproximam episódios com AIH aprovada e podem incluir transferências/reinternações. O tempo é o de processamento. Óbitos SIH são altas hospitalares por óbito. Dias de permanência e valores referem-se às AIHs aprovadas, incluindo diferenças conceituais em relação ao indicador de internações; não calcular médias ou custos por pessoa automaticamente. [Notas oficiais SIH por residência](https://tabnet.datasus.gov.br/cgi/sih/Morb_geral_loc_res_2008.pdf).

No SIM, os óbitos são por causa básica e ano de ocorrência, segundo residência. Não representam necessariamente óbitos entre os casos confirmados do SINAN. Não dividir esses óbitos por notificações para estimar letalidade. [Notas oficiais SIM](https://tabnet.datasus.gov.br/cgi/sim/Mortalidade_Geral_1996_2012.pdf).

## Portabilidade e reprodução

O coletor não depende do projeto de hepatites, de pacotes R ou de bibliotecas Python externas. Requer Python 3.8+; foi testado com o Python incluído no ambiente atual. Os imports externos ao próprio arquivo são todos da biblioteca padrão: `pathlib`, `datetime`, `urllib`, `decimal`, `argparse`, `csv`, `hashlib`, `html`, `ipaddress`, `json`, `re`, `shutil`, `subprocess` e `time`. O único módulo local é `scripts/_tabnet_complementos.py`, que contém os parsers de formulário/tabela, sem escrita ou coleta em importação.

O transporte padrão é `urllib`. Para `--transporte curl`, é necessário curl no PATH ou um executável indicado em `--curl-path`; nenhum caminho pessoal ou caminho obrigatório de instalação foi embutido. `--ip-resolvido` é opcional e deve receber um IP diagnosticado na execução atual. `--sih-http` é uma opção para o tabulador público SIH quando HTTPS falhar. O diretório padrão é o pai de `scripts/`, podendo ser indicado por `--diretorio-projeto`.

Reprocessar e conferir a rodada preservada, sem nova coleta:

```powershell
python scripts/coletar_complementos_20261009.py
python scripts/conferir_complementos_20261009.py
```

Para uma cópia nova do projeto, a opção `--versao` permite escolher uma pasta e um contador de requisições próprios, sem sobrescrever esta rodada. Exemplo de primeira coleta em outra máquina, após definir sua nova rodada:

```powershell
python scripts/coletar_complementos_20261009.py --versao complementos_amigo_20261009 --coletar
python scripts/conferir_complementos_20261009.py --versao complementos_amigo_20261009
```

O verificador é local e não faz requisições. Produz `CONFERENCIA_MECANICA.json` com hashes, chaves, escopos, conservação e pendências. O coordenador é responsável por incluir estes scripts e métodos no Git; esta frente não executou comandos Git.
