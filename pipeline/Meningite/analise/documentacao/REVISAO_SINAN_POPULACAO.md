# Revisao final independente - SINAN/populacao e F01-F04

Data: 10/10/2026. Escopo: leitura do pacote integrado, descritivos, relatorio, codigo de derivacao e visualizacao dos quatro PNG. Nenhum produto final, codigo, candidato ou Git foi alterado. Este e o unico arquivo produzido nesta revisao.

**Aceite do nucleo SINAN/populacao e dos quatro PNG, dentro dos limites descritos.** Foram executadas 39 verificacoes independentes, todas aprovadas. Duas pendencias editoriais/rastreabilidade do relatorio completo foram comunicadas ao mestre; nao invalidam os calculos do nucleo.

## Conferencias numericas

- Os campos originais dos 1.976 registros coincidem integralmente com o pacote congelado20261009; a populacao original tambem foi preservada.
- Totais anuais recontados diretamente dos registros coincidem com a serie publicada. A taxa anual usa a populacao do mesmo ano, e a variacao2014-2024 arredonda para -52,7%.
- A grade mensal tem132linhas e soma1.976; agosto2020 e o unico zero, derivado da coorte integral. Nenhuma populacao mensal foi criada.
- Foram comparados os IC95 de409linhas com `stats::poisson.test(n,T=populacao,conf.level=.95)`:11totaisanuais,22sexo/ano,121idade/ano,2sexos/periodo,11idades/periodo e242estratos conjuntos. Diferenca maxima observada dos limites: **zero**.
- Os715percentuais SINAN com numerador e denominador declarados conferem com100*n/d. As167taxas SINAN dos descritivos conferem com100.000*n/d.
- Exposicao do periodo: soma das11populacoes anuais, **29.082.296 habitantes-ano aproximados**. Feminino:15.670.165,843registros; masculino:13.412.131,1.132registros. As taxas especificas do periodo foram recalculadas com essas exposicoes, sem usar uma unica populacao anual nem multiplicar novamente por11.
- Todas as11exposicoes por idade conferem com a soma dos estratos populacionais correspondentes. Menores de1:291.439habitantes-ano,183registros;20-39:9.813.955habitantes-ano,537registros. Taxas e IC conferem.
- Sexo conhecido soma1.975; o perfil etario soma1.976 e conserva o registro de sexo ignorado. A proporcao por sexo usa a coorte total como declara o relatorio, sem renormalizar para1.975.
- Foram conservados6registros etiologicos nao canonicos,2vazios,19MCC,442MNE,144evolucoes desconhecidas e2notificacoes foraBA. A tabela de qualidade coincide com a historica.
- A comparacao preserva572celulas com referencia e6extras sem referencia. Os grupos etiologicos sao disjuntos, fecham os totais anuais e100% por ano; o residual nao foi eliminado.
- As afirmacoes do nucleo conferem: MV874; alta1.566; obitos por meningite190; outra causa76; desconhecidos144; desconhecidos2024=32/162; mediana sintomas-notificacao5dias. Os denominadores190/1.976 e190/1.832 do texto sao explicitos e aritmeticamente corretos.

## Inspecao visual dos PNG por view_image

| Figura | Parecer |
|---|---|
| F01 | Dois paineis separados de contagem e taxa, eixos com origem zero, anos ordenados, IC na taxa, notas legiveis sobre filtros/preliminaridade. Valores e direcao concordam com a serie. |
| F02 | Sexo e idade sao marginais distintas; unidade habitantes-ano e aproximacao da exposicao aparecem na legenda. ICs visiveis; menores de1 no topo com maior taxa. Mesmo eixo horizontal torna os IC por sexo pequenos, mas nao corta valores nem altera a interpretacao. |
| F03 | Grade11x12, contagens inscritas e legiveis, anos/meses corretos, agosto2020 explicitamente zero. Legenda distingue contagem de taxa e explica origem do zero. |
| F04 | Onze barras de100%, legenda completa, grupos disjuntos, notas preservam MCC/MNE e residual. Segmentos residuais sao muito pequenos, como esperado; categorias originais permanecem na tabela. Sem afirmacao de comprovacao laboratorial. |

Nao foram visualizados/renderizados os PDF nesta frente; o aceite visual acima refere-se aos PNG efetivamente abertos. Nao se afirma identidade visual de PDF sem inspecao. Nenhuma nova figura foi gerada.

## Achados a corrigir pelo mestre

1. **Texto SIH fora do nucleo:** secao6 de `RELATORIO_DESCRITIVO.md` imprime “NA altas por obito”. O gerador usa soma de linhas de medida `obitos`, aparentemente incluindo ausencias. Corrigir a selecao/semantica antes de publicar um numero; nao trocar NA por zero nem usar `na.rm` sem declarar cobertura. Achado comunicado durante a revisao.
2. **Rastreabilidade ainda pendente:** o relatorio diz que a inspecao esta registrada em `controle/QA_VISUAL.json`, mas o arquivo nao existia na verificacao. Criar o registro das figuras efetivamente revisadas e hashes, ou ajustar a frase ate sua conclusao. O mestre informou que faria sua propria inspecao.

Sugestao editorial menor: “seguida de aumento em2022-2024” descreve niveis maiores que2020-2021, mas nao crescimento monotono:2024tem162 e2023tem167. Redigir “recuperacao dos registros em2022-2024, com pequena reducao em2024” evita ambiguidade.

## Identificacao dos arquivos revisados

SHA-256 recalculados ao final da leitura; alteracoes posteriores do mestre constituem outra versao a registrar:

- `meningites_salvador_analitica.rds`: `2fe0f7f6f02d6367b9cfa55487f24016dd57c09f4dc979f8975efd7edbb5247d`.
- `RELATORIO_DESCRITIVO.md`: `19321a63878928913e94ab1b40db98d60e2e931e0c8ede207a5cb24f2d5c7e58`.
- `F01_evolucao_anual.png`: `63641b6ec872c599c157600ee41513381e1c47fdf3cf8291e7b2af7c39511d90`.
- `F02_perfil_sexo_idade.png`: `bafa41d4f53d0139918465fe71d26dd1f73a4679774767fbabb49d463f452ddc`.
- `F03_distribuicao_mensal.png`: `a7f14e1415d63d16af9d3301655ea220a3b49013e00037715af7ba0c92d55a50`.
- `F04_classificacao_etiologica.png`: `4cd87e3d399196fcc4584c58ae89871fb28b721b368ad40ec08700444c15a111`.

## Limites do aceite

Aceite mecanico/descritivo da versao: nao comprova pessoas unicas, validade clinica, sensibilidade da notificacao, eficacia vacinal ou causalidade da queda temporal. IC Poisson nao incorpora subnotificacao ou incerteza demografica. A populacao anual aproxima a exposicao; o periodo agrega anos e nao identifica individuos. Mantem-se a conversao etaria historica auditada e a preliminaridade de fontes recentes. Nao foi feita uma auditoria independente completa de SIH/SIM/PNI ou dos352controles do mestre:39controles desta frente sao adicionais e delimitados.

## Adendo - nova versao F02

Em10/10/2026, apos ajuste do mestre, foi visualizado novamente somente o PNG `F02_perfil_sexo_idade.png`. SHA-256 atual: `4f23e660769daaf423a5270a91b0cec5699036a31799a258b268d4ad665629e3`, que substitui o hash F02 anteriormente listado para o aceite da versao atual.

**Aceite visual da nova F02:** escalas horizontais proprias por painel, explicitadas na legenda; pontos masculino8,44 e feminino5,38 com rotulos legiveis e intervalos agora claramente visiveis. Painel etario, fonte, exposicao aproximada e registro de sexo ignorado permanecem legiveis. Sem corte de rotulos ou intervalos. Escalas diferentes sao indicadas e nao sugerem comparacao direta das distancias entre os paineis. Nenhum novo problema concreto encontrado.

Nao foram repetidos testes numericos nem alterados produtos finais. O mestre informou a correcao do texto hospitalar e da trajetoria2022-2024, alem da renderizacao dosPDF e preparacao doQA_VISUAL.json; este adendo nao reaudita esses outros arquivos.
