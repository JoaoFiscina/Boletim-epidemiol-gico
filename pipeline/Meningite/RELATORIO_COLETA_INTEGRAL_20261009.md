# Coleta de meningites em Salvador — rodada de 09/10/2026

O núcleo nacional do SINAN foi coletado e auditado. Os complementos hospitalares, de mortalidade e vacinação avançaram com lacunas explícitas. Esta é uma versão para organizar a análise; não representa conclusão de todas as fontes ou resultados finais para publicação.

## Escopo e execução

Residência Salvador, IBGE `292740`; SINAN confirmado (`CLASSI_FIN=1`), primeiros sintomas em 2014–2024. Foram lidas as 13 partições nacionais de notificação `MENIBR14–26`, para captar registros tardios. Dez arquivos foram baixados pelo serviço HTTPS oficial, e três do piloto de 05/10 foram reutilizados com SHA-256. A aquisição nova consumiu 20.940.926 bytes. Os originais, contratos, catálogo e falhas foram preservados em `dados/brutos/sinan_br_20261009`.

| Etapa SINAN | Registros |
|---|---:|
| Linhas nacionais lidas | 295.369 |
| Residentes confirmados, todas as datas disponíveis | 2.255 |
| Fora da janela de sintomas 2014–2024 | 279 |
| Confirmados sem data de sintomas | 0 |
| Coorte analítica | **1.976** |
| Notificados fora da Bahia dentro da coorte | 2 |
| Duplicatas técnicas exatas na coorte | 0 |

Nenhum registro foi removido por coincidência demográfica. Ausência de repetição técnica não demonstra pessoas únicas nem ausência de episódios repetidos.

## Concordância histórica e a diferença de seis

A série nacional reproduziu os onze totais anuais do TabNet preservado em 05/10/2026. Das 578 linhas de comparação, **572 têm referência TabNet e nenhuma diferença observada**. Seis categorias nacionais adicionais não têm equivalente tabulado e conservam a referência como ausente, nunca zero.

| Ano dos sintomas | Confirmados | Taxa registrada por 100 mil |
|---:|---:|---:|
| 2014 | 361 | 13,34 |
| 2015 | 292 | 10,84 |
| 2016 | 241 | 8,99 |
| 2017 | 198 | 7,42 |
| 2018 | 141 | 5,30 |
| 2019 | 181 | 6,84 |
| 2020 | 40 | 1,52 |
| 2021 | 51 | 1,94 |
| 2022 | 142 | 5,45 |
| 2023 | 167 | 6,45 |
| 2024 | 162 | 6,31 |

Taxa = notificações confirmadas com sintomas no ano / população residente municipal do mesmo ano × 100.000. O intervalo de Poisson está no CSV; ele não corrige subnotificação. Ano de partição não substitui ano dos sintomas. Por exemplo, a partição de 2025 contém cinco registros da janela histórica.

Os seis registros residuais da visão etiológica foram localizados em códigos não padronizados de `CON_DIAGES`: `7.` (2014 e 2015), `7%` (2016), `7` e `X` (2017), `%7` (2022). O domínio canônico preservado é `01`–`10`. As categorias canônicas e os brancos reproduzem a tabela etiológica de 1.970; os seis adicionais completam os 1.976. Esta reconciliação não autoriza adivinhar que os códigos malformados significam meningite viral. Todos permanecem na coorte e em categoria própria.

O primeiro processamento tentou harmonizar códigos numericamente; essa opção poderia converter código malformado em etiologia válida. Foi corrigida antes da entrega, exigindo domínio canônico para etiologia. O erro e a correção estão documentados para não serem repetidos.

## Qualidade e análise possível

- 442 registros estão em MNE; 19 em MCC isolada. O tema deve abranger **meningites e doença meningocócica**. Restrição a meningite com acometimento meníngeo precisa de regra derivada explícita.
- Evolução desconhecida: 144/1.976. Em 2024, 32/162; letalidade não deve ser apresentada como completa.
- Sexo: 1.132 masculino, 843 feminino e um ignorado. Comparação de risco exige denominadores por sexo, não apenas contagens.
- A base conjunta agora vem dos registros nacionais, permitindo cruzamentos reais de idade, sexo, etiologia, mês e evolução. Não é reconstruída pela combinação de marginais.
- A série mensal tem 131 combinações observadas, não uma grade completa de 132 meses. Construir uma grade futura com regra explícita: zero derivado da coorte integralmente lida difere de exportação externa ausente.
- Existem campos laboratoriais, sorogrupo, história vacinal e hospitalização, mas preenchimento não demonstra aplicabilidade ou validade clínica. Usar primeiro as auditorias de domínio e denominadores pertinentes.
- O catálogo classifica 2014–2022 como finais e 2023–2026 como preliminares. Não interpretar uma versão preliminar como série definitivamente encerrada.

A população foi auditada independentemente: hashes dos três arquivos conferidos, 11 totais anuais, 396 chaves originais e 242 reagrupamentos compatíveis; todas as somas conservadas. Esta auditoria valida a integridade local e o reagrupamento, sem nova revisão demográfica na fonte.

## SIH e SIM: o que esta rodada acrescentou

Foram validadas **6 das 11 consultas previstas**, com 24 POST tentados e 1.065.310 bytes de respostas brutas. As falhas DNS/timeout foram conservadas. Não significam zero eventos.

| Consulta válida | Uso |
|---|---|
| SIM idade × ano | Perfil etário anual do conjunto G00–G03/A39/A87 |
| SIH óbitos × diagnóstico × ano | Óbitos hospitalares por grupo CID |
| SIH valores aprovados × diagnóstico × ano | Valores administrativos aprovados em reais nominais |
| SIH G00 idade × ano | Perfil etário e total anual do grupo |
| SIH A87 sexo × ano | Perfil por sexo e total anual do grupo |
| SIH A87 idade × ano | Perfil etário e conferência independente do total A87 |

O SIH registra 75 óbitos hospitalares e R$ 2.354.667,12 aprovados no conjunto filtrado durante o período. As tabelas também trazem capítulos e grupos intermediários: somar somente as folhas CID G00–G03/A39/A87, evitando dupla contagem. As internações anuais derivadas das marginais totalizam G00 = 532 e A87 = 489; as duas marginais A87 concordam e não são somadas entre si.

O SIM por idade conserva o total anterior de 202 óbitos por causa básica selecionada. O arquivo é de registro BA, filtrado por residência Salvador; sua abrangência nacional não foi demonstrada. Não são óbitos vinculados aos 1.976 registros SINAN. O recorte CID inicial é exploratório e não abrange automaticamente todas as meningites etiológicas: códigos específicos adicionais exigem revisão clínica e de fonte.

Pendências novas: SIH internações por diagnóstico/ano, dias de permanência, G00 sexo e A39 sexo/idade. As extrações anteriores permanecem preservadas no pacote de pré-análise de 05/10; não foram usadas para esconder as falhas da rodada atual.

## PNI: dados obtidos e ruptura de método

Foram validadas **17 observações anuais**: nove coberturas Penta de 2014–2022 reaproveitadas com contexto/HTML/SHA, e oito indicadores atuais RNDS, quatro imunobiológicos × 2023/2024. A grade solicitada tem 44 chaves e 27 pendências explícitas: BCG, meningocócica C e pneumocócica de 2014–2022.

Os atuais são Meningocócica Conjugada, Pneumocócica Conjugada, Penta e BCG, por residência Salvador. Os numeradores e denominadores oficiais e seus filtros estão preservados. As razões foram conferidas, sem recalcular independentemente o denominador SINASC. Não renomear os conjugados atuais como MenC/PCV10 exclusivas.

A NT 84/2026 revoga a NT 90/2025 e estende o método individual retrospectivamente a 2023. A NT 69/2026 consolida vacinas pneumocócicas conjugadas. Legado e RNDS têm métodos e perspectivas que não permitem emenda automática. As baixas coberturas BCG registradas, 14,46% em 2023 e 38,95% em 2024, exigem investigação de integração/completude; não provam ausência de vacinação.

O relatório próprio está em `metadados/pni_20261009/RELATORIO_PNI.md`. Foram cinco POST tentados, zero concluídos, 76 chamadas públicas JSON-RPC e 4.837.074 bytes. O acesso ao painel público permitiu oito observações úteis apesar da instabilidade TabNet. Nenhum microdado vacinal individual foi baixado. SIA não foi coletado: procedimentos não fornecem cobertura vacinal ou casos confirmados, e falta um recorte SIGTAP justificado para esta pergunta.

## Organização para R e outros programas

Entrada principal: `dados/tratados/meningites_salvador_20261009.rds`, com listas `SINAN`, `populacao`, `SIH`, `SIM`, `PNI`, `estado` e manifestos. A base mínima local SINAN fica em `m$SINAN$casos_minimos_locais`. Não contém nome ou identificador nominal, mas continua sendo uma base de linhas de casos; compartilhar publicamente apenas agregados revisados. O pacote anterior foi preservado.

O pacote principal foi gravado com compressão `xz` (129.144 bytes, cerca de 126 KiB) e relido com identidade completa. SHA e arquivos de entrada estão em `metadados/CONSOLIDACAO_20261009.json`. O script de processamento foi executado novamente após as correções de portabilidade; a coorte e o hash do RDS SINAN permaneceram iguais, com identidade do código atualizado reconferida pelo chat auditor.

CSVs principais, separados por fonte e versão:

- `dados/tratados/sinan_br_20261009`: anual, mensal, marginais, conjunto agregado, qualidade e comparação.
- `dados/tratados/complementos_20261009`: medidas anuais, internações derivadas e perfis longos SIH/SIM.
- `dados/tratados/pni_20261009`: cobertura municipal longa e grade de disponibilidade.
- `dados/denominadores`: população total e por sexo/faixa.

Scripts distinguem coleta online e processamento offline. JSON `config/coleta_integral.json` documenta o plano; os dois scripts SINAN têm o perfil 2014–2024/partições 2014–2026 explicitamente no código, e não leem esse JSON automaticamente. Para outro período, alterar as regras e validar novamente. A data de auditoria de notificações futuras deriva do argumento de versão. Comandos R por arquivo evitam perda de aspas no Windows PowerShell 5.1.

## Coordenação e próximos passos

O mestre integra, documenta e faz Git; frentes mecânicas SIH/SIM e PNI têm diretórios exclusivos. Os chats **“Revisar contexto do projeto (2)”** e **“Revisar contexto do projeto”** receberam, respectivamente, auditoria independente SINAN e auditoria de denominadores/portabilidade, sem novos downloads ou alterações de bases/Git. Os relatórios ficam em `metadados/auditoria_independente_20261009`.

Próxima prioridade: escolher um eixo descritivo de ocorrência registrada, taxa por idade/sexo e sazonalidade usando o núcleo concordante; concluir apenas as consultas hospitalares úteis para esse eixo. Vacinação fica exploratória até resolver a comparabilidade e as 27 lacunas. Se mortalidade for eixo principal, ampliar a verificação SIM para cobertura nacional por residência. Não lançar um lote de modelos e p-valores antes de definir desfechos e hipóteses.

O Git recebe plano, código, preferências, métodos, resultados agregados e auditorias. Brutos e RDS permanecem locais. A documentação será atualizada durante as próximas etapas executadas; isso não cria atualização automática com o chat inativo.
