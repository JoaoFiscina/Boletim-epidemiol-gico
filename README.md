# Manual operacional — análise de meningites em Salvador

Este repositório é o guia reproduzível da investigação de meningites e doença meningocócica em residentes de Salvador. Ele foi escrito para que outra pessoa ou outra IA consiga entender o objetivo, repetir a coleta, conferir os resultados e continuar o trabalho sem misturar fontes ou inventar dados.

O projeto executado está em `C:\Pesquisa\Boletim epidemiolóico\Meningite`. Este Git contém manual, código, configuração, denominadores e resultados agregados com hashes em [pipeline](pipeline/README.md). Dados brutos e pacotes R permanecem locais. Para repetir a leitura integral, transportar os brutos com seus manifestos ou coletá-los pela rotina oficial na própria cópia do projeto.

Comece nesta ordem:

1. [Estado atual da coleta](docs/ESTADO_COLETA.md) — rodada 09/10, validações e pendências concretas.
2. [Guia mestre](GUIA_MESTRE_MENINGITES_SALVADOR.md) e [preferências/métodos](docs/PREFERENCIAS_E_METODOS.md).
3. [Operações reproduzíveis](docs/OPERACOES_REPRODUZIVEIS.md) — comandos e sequência de execução.
4. [Checklist de qualidade](docs/CHECKLIST_QUALIDADE.md) — critérios para aceitar, ajustar ou recusar cada análise.
5. [Prompt para continuidade por outra IA](PROMPT_CONTINUIDADE_IA.md) — contexto pronto para colar em outro chat.

## Decisão atual

O tema é viável para ocorrência registrada, perfil por idade/sexo, sazonalidade e qualidade diagnóstica. A leitura nacional das 13 partições confirmou **1.976 notificações confirmadas com sintomas em 2014–2024**. Os onze totais anuais e 572 células comparáveis concordaram com o TabNet de 05/10. A diferença de seis na etiologia foi localizada em códigos não canônicos, preservados sem inferir agente.

Complementos: seis consultas SIH/SIM válidas, cinco pendentes; PNI com 17 observações e 27 lacunas. O plano detalhado e relatório executado estão em [pipeline/Meningite](pipeline/Meningite/RELATORIO_COLETA_INTEGRAL_20261009.md). A entrada R atual é `Meningite/dados/tratados/meningites_salvador_20261009.rds`; o pacote anterior permanece histórico.

Letalidade, vacinação e subtipos raros não devem ser o eixo principal antes de resolver incompletude e cobertura. SINAN, SIH e SIM são fontes diferentes e não podem ser somados como pessoas.

## Estrutura do trabalho original

```text
C:\Pesquisa\Boletim epidemiolóico\
├── Meningite\                         # projeto e dados executados
│   ├── dados\brutos\                  # respostas, ZIP e DBC originais
│   ├── dados\tratados\                # tabelas analíticas por fonte
│   ├── dados\denominadores\           # população de Salvador
│   ├── metadados\                      # contratos, hashes, dicionários, status
│   ├── resultados\figuras\             # gráficos de diagnóstico
│   ├── resultados\tabelas\             # CSVs para R e conferência
│   ├── scripts\                        # coletores e análise local
│   ├── referencias\                     # documentos oficiais
│   ├── pre_analise_meningite.rds        # pacote compacto para R
│   ├── PLANO_COLETA.md
│   └── RELATORIO_PRE_ANALISE.md
└── Boletim epidemiológico\             # este manual Git
```

O diretório `Hepatite- Descartado` contém o projeto anterior de hepatites e denominadores reaproveitados. Ele foi preservado e não deve ser alterado durante a continuação de meningites.

## Regras rápidas

- Sempre declarar numerador, denominador, território, perspectiva e referência temporal.
- SINAN representa notificações/casos segundo a definição do agravo; SIH representa internações/AIHs; SIM representa óbitos por causa básica. Nenhuma dessas fontes representa automaticamente pessoas únicas.
- Preservar respostas originais, versão, data, parâmetros e SHA-256. Não sobrescrever coleta anterior.
- Diferenciar consulta vazia, arquivo ausente e zero eventos. Ausência não é zero.
- Manter uma base longa para análise e derivar tabelas largas somente para consulta.
- Não juntar tabelas marginais de sexo, idade e etiologia como se fossem registros individuais.
- Não transformar preenchimento de campo em validade clínica do diagnóstico.
- Não usar o rótulo TabNet “PCR - viral” como prova de confirmação viral sem conferir o domínio do DBF e os códigos laboratoriais.

O manual completo explica o motivo de cada regra.
