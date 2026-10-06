# Contexto histórico do projeto

## De onde viemos

O trabalho começou com um boletim de hepatites em Salvador. Foram organizados denominadores populacionais, consultas SINAN, SIH/SUS, SIA/SUS, SIGTAP e PNI. A análise exploratória mostrou problemas de comparabilidade, cobertura parcial e excesso de ruído para a pergunta pretendida. O tema foi mantido preservado em `Hepatite- Descartado`, mas não deve contaminar a nova análise.

Essa experiência deixou regras importantes: guardar respostas originais, nunca transformar produção de procedimentos em pacientes, separar moradores de local de atendimento, registrar cobertura por competência, não preencher anos faltantes com zero e manter uma base longa para comparação.

## Por que meningites

Meningites foi escolhido por combinar um agravo menos comum com possibilidade de observar notificações, diagnósticos, internações e óbitos em fontes públicas. A triagem comparou possibilidades como leucemias, epilepsias e meningite; meningite apresentou volume e fontes complementares suficientes para um piloto.

## Frentes coordenadas na execução

O trabalho foi dividido em frentes sem editar o mesmo conjunto de arquivos:

- SINAN/TabNet: formulário, consultas anuais, etiologia, qualidade e cruzamentos.
- SINAN nacional: catálogo, download DBC, leitura e agregação do piloto 2024.
- SIH/SIM: grupos CID, internações, óbitos hospitalares e causas básicas.
- População: reaproveitamento conferido, compatibilização de faixas e denominadores.
- Análise: tabelas, RDS, gráficos, relatório e decisão de viabilidade.

Cada frente preservou arquivos brutos e registrou metadados. A coordenação final conferiu que os dados não fossem unidos apenas porque tinham o mesmo município ou ano.

## Estado do projeto anterior que deve ser respeitado

O manual geral de pesquisa epidemiológica e DATASUS, criado anteriormente em `C:\Fizzi\outputs\INSTRUCOES_CODEX_PESQUISA_EPIDEMIOLOGICA_DATASUS.md`, descreve o fluxo inventário → piloto → lote → validação → diagnóstico → foco → análise. Este repositório adapta o fluxo a meningites e registra o que foi realmente executado aqui.

Os denominadores reaproveitados foram conferidos antes da cópia. A população municipal tem 11 totais anuais, 396 chaves originais e 242 chaves compatíveis com as faixas SINAN. A cópia no projeto possui manifesto e hashes.

## O que não deve ser feito por uma continuação

Não misturar o SIH-RD parcial de hepatites com meningites. Não reutilizar uma URL ou parâmetro só porque funcionou em hepatites. Não usar o nome “incidência” sem informar que o numerador é registro de vigilância. Não importar a lógica de procedimentos SIA para casos SINAN. Não apagar o projeto antigo para tornar a pasta mais simples.
