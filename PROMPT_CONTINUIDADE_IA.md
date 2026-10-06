# Prompt para entregar este projeto a outra IA

Você está continuando uma pré-análise de meningites e doença meningocócica em residentes de Salvador, Brasil. Leia todo este repositório antes de agir. O manual é normativo para organização e rastreabilidade; o relatório do projeto original contém os resultados executados.

## Contexto fixo

- Município: Salvador, IBGE `292740`.
- Período principal: ano dos primeiros sintomas 2014–2024.
- SINAN é a fonte principal de casos/notificações.
- SIH é complemento de internações/AIHs e SIM é complemento de óbitos por causa básica.
- População municipal já conferida; não substituir por população da Bahia.
- O trabalho original está em `C:\Pesquisa\Boletim epidemiolóico\Meningite`.

## Resultado que não pode ser perdido

O SINAN/TabNet tem 1.976 casos gerais, mas a tabela de etiologia tem 1.970; há diferença de seis registros sem causa demonstrada. Sexo, idade e mês têm bom preenchimento. Evolução tem piora recente: 32/162 casos de 2024 sem evolução conhecida. O piloto nacional `MENIBR24–26` reproduziu os 162 casos de 2024 do TabNet sem divergências nas células comparadas e encontrou um caso notificado fora da Bahia.

## O que fazer agora

1. Verificar o estado dos arquivos antes de baixar qualquer coisa.
2. Completar `MENIBR14–23` uma vez cada, pelo catálogo oficial, preservando ZIP/DBC, modalidade e hashes.
3. Filtrar residência 292740, `CLASSI_FIN=1` e sintomas 2014–2024.
4. Comparar a série nacional com TabNet por total, sexo, idade, evolução, critério e etiologia.
5. Explicar ou manter explicitamente a diferença de seis; não forçar igualdade.
6. Completar SIH sexo/idade anual e SIM idade somente se necessário para a pergunta final.
7. Atualizar o relatório, manifestos, RDS e changelog.

## Proibições

Não somar SINAN, SIH e SIM como pessoas. Não tratar ausência como zero. Não usar “PCR - viral” como prova de agente viral. Não chamar todo A39 de meningite meningocócica. Não excluir MNE. Não calcular letalidade final com evolução incompleta. Não apagar saídas anteriores. Não inventar URL ou nome de arquivo. Não instalar dependências ou fazer dezenas de consultas sem registrar motivo.

## Forma de resposta esperada

Ao finalizar uma etapa, informe em português: o que foi executado, caminhos exatos, quantidade de registros, filtros, hashes, divergências, limites e próximo passo. Separe claramente “validado”, “parcial”, “pendente” e “não demonstrado”.
