# Manual operacional — análise de meningites em Salvador

Este repositório é o guia reproduzível da investigação de meningites e doença meningocócica em residentes de Salvador. Ele foi escrito para que outra pessoa ou outra IA consiga entender o objetivo, repetir a coleta, conferir os resultados e continuar o trabalho sem misturar fontes ou inventar dados.

O projeto executado está em `C:\Pesquisa\Boletim epidemiolóico\Meningite`. Este Git contém o manual, o histórico e os parâmetros essenciais; os dados brutos e o pacote R permanecem no diretório de trabalho original e não são duplicados aqui. Para uma entrega completa, envie este repositório junto com a pasta `Meningite`, ou siga o manual para recriar a coleta a partir das fontes oficiais.

Comece nesta ordem:

1. [Guia mestre](GUIA_MESTRE_MENINGITES_SALVADOR.md) — método, decisões, fontes, preferências e limites.
2. [Estado atual e resultados](docs/RESULTADOS_ATUAIS.md) — o que já foi medido, o que é confiável e o que falta.
3. [Operações reproduzíveis](docs/OPERACOES_REPRODUZIVEIS.md) — comandos e sequência de execução.
4. [Checklist de qualidade](docs/CHECKLIST_QUALIDADE.md) — critérios para aceitar, ajustar ou recusar cada análise.
5. [Prompt para continuidade por outra IA](PROMPT_CONTINUIDADE_IA.md) — contexto pronto para colar em outro chat.

## Decisão atual

O tema é viável para ocorrência registrada, perfil por idade e sexo, sazonalidade e qualidade da classificação diagnóstica. A série do SINAN/TabNet possui 1.976 casos confirmados registrados entre 2014 e 2024. Um piloto nacional de 2024 reproduziu os 162 casos de Salvador nas categorias comparadas. A série histórica nacional completa, a resolução de uma diferença de seis registros entre visões do TabNet e alguns complementos ainda estão pendentes.

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
