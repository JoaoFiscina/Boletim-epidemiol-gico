# Estado da coleta — 09/10/2026

Esta página é a entrada para continuar o projeto. A rodada nacional SINAN está completa quanto às 13 partições previstas e ao confronto histórico; os complementos têm lacunas explícitas. O relatório executado e plano estão em [pipeline/Meningite](../pipeline/Meningite/RELATORIO_COLETA_INTEGRAL_20261009.md) e [plano integral](../pipeline/Meningite/PLANO_COLETA_INTEGRAL.md).

| Módulo | Evidência executada | Situação/limite |
|---|---|---|
| SINAN nacional | 13 DBC; 295.369 linhas; 2.255 residentes confirmados; 1.976 com sintomas 2014–2024 | Totais anuais concordantes; 2023–2026 preliminares; não demonstra pessoas únicas |
| Confronto TabNet | 572 células com referência, zero diferenças; seis categorias adicionais sem referência | Comparação com snapshot 05/10, não todas as fontes na mesma data |
| Etiologia | Seis códigos não canônicos localizados; categorias TabNet somam 1.970, coorte 1.976 | Preservados sem adivinhar/recodificar agente |
| Evolução | 144 desconhecidas; em 2024, 32/162 | Letalidade secundária com sensibilidade |
| População | 11 totais, 396 chaves originais, 242 compatibilizadas; hashes/somas conferidos independentemente | Integridade local, sem nova revisão demográfica na fonte |
| SIH/SIM ampliados | 6/11 consultas válidas; 24 POST; 77 conservações sem divergência | Cinco consultas SIH pendentes; respostas válidas preservadas |
| SIH | 75 óbitos hospitalares; R$ 2.354.667,12 aprovados; G00 idade; A87 sexo/idade | AIHs por residência e ano de processamento; folhas CID, sem duplicar subtotais |
| SIM idade | 202 óbitos selecionados; onze anos e idades conservados | Arquivo de registro BA; abrangência nacional não demonstrada |
| PNI | 17 observações: Penta legado 2014–2022 e quatro indicadores RNDS 2023/2024 | 27 lacunas; método/geografia distintos; BCG precisa auditoria |
| SIA | Não coletado | Recorte de procedimentos ainda sem utilidade demonstrada para a pergunta |

## O que não baixar novamente

MENIBR14–26 já têm SHA conferido. As seis consultas válidas de complementos, os oito valores RNDS e os nove Penta legados estão preservados. Retomar apenas pendências, com parâmetros reais e lote limitado. Os arquivos brutos, RDS e resultados de 05/10 ficam no projeto original; o Git preserva código e agregados para consulta/reprodução.

O manifesto da aquisição descreve sua etapa e guarda erros anteriores no histórico. O resultado de processamento e a consolidação descrevem a etapa posterior. Não inferir que um status antigo de leitura pendente invalida uma leitura posterior documentada. Não apagar histórico para aparentar ausência de falhas.

## Pendências concretas

1. SIH: internações por diagnóstico/ano; dias de permanência; G00 sexo; A39 sexo e idade. G00 e A87 têm totais anuais novos derivados de marginais, sem preencher A39 por adivinhação.
2. PNI: BCG, meningocócica C e pneumocócica 2014–2022 (27 chaves). Não emendar método legado/RNDS automaticamente. As NT84/2026 e NT69/2026 e a discordância do dicionário estão no relatório PNI.
3. Mortalidade: conferir cobertura nacional por residência se SIM entrar como eixo principal.
4. Revisar recorte clínico CID e aplicabilidade de campos secundários SINAN antes de análises etiológicas específicas.
5. Definir análise principal e desfechos; depois produzir poucos gráficos, taxas específicas e modelos proporcionais ao volume de eventos.

## Coordenação e reprodução

O mestre responde por integração/Git. As frentes SIH/SIM e PNI encerraram esta rodada, sem consultas novas após atingir seus limites. Os chats “Revisar contexto do projeto (2)” e “Revisar contexto do projeto” auditaram, respectivamente, SINAN e denominadores/portabilidade em arquivos próprios. Não editaram bases, coletores ou Git.

Consulte [auditoria SINAN](../pipeline/Meningite/metadados/auditoria_independente_20261009/AUDITORIA_SINAN.md) e [auditoria denominadores/portabilidade](../pipeline/Meningite/metadados/auditoria_independente_20261009/AUDITORIA_DENOMINADORES_PORTABILIDADE.md). As observações descrevem momentos da construção; correções posteriores ficam no changelog e nos metadados atualizados.

Corrigidos pelo mestre: comandos R inline substituídos por arquivo `.R`; caminhos SINAN normalizados; origem/modalidade revalidadas na retomada; status HTTP registrado em novas requisições; data de corte derivada da versão; contador de comparação distingue 572 células comparáveis de 578 linhas. JSON de configuração é declarativo e o perfil temporal SINAN permanece explícito no código.

A série mensal contém 131 combinações observadas; não é uma grade completa de 132 meses. Uma grade futura deve distinguir zero derivado de coorte integralmente lida de exportação ausente. Nenhuma lacuna de consulta externa foi convertida em zero.

Na máquina original, a entrada R é `Meningite/dados/tratados/meningites_salvador_20261009.rds`. Em clone, use [instruções portáteis](../pipeline/README.md). Git não contém DBC ou RDS; outro computador precisa runtimes/pacotes próprios e coleta ou transferência dos brutos para repetir integralmente o processamento.

Fechamento mecânico: 45 cópias SHA/tamanho idênticos, oito JSON legíveis, seis scripts Python com sintaxe válida e links locais de dezenove documentos Markdown sem ausências. O RDS principal abriu pelo script de leitura no Windows PowerShell 5.1. As auditorias não demonstram validade clínica, eficácia vacinal ou cobertura universal.
