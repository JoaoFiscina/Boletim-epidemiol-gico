# Revisão final independente — SINAN/população e integração

Data: 12/10/2026. Revisão solicitada pelo chat mestre. Resultado: entrega consistente no escopo examinado, sem pendência bloqueante identificada. Nenhuma fonte, figura, cálculo ou produto final foi modificado por esta revisão.

## Escopo e procedimento

Leitura do RDS integrado e relatório, comparação com o candidato SINAN corrente, conferências aritméticas sem reestimar modelos, teste de `source()` do controlador sem executá-lo e inspeção visual de G01–G06. O PDF de oito páginas foi renderizado com Poppler; suas páginas 1–6 foram efetivamente inspecionadas. Renderizações estão em `qa_pdf/` nesta área. G07/G08 e páginas 7/8 não receberam aceitação visual nesta revisão. A revisão anterior dos modelos está em `REVISAO_MODELOS.md`; seus hashes antigos não representam esta versão integrada.

## Conferências numéricas

34 conferências da integração aprovadas: 33 na primeira passagem e uma após corrigir o tratamento de NA no próprio comando de revisão. O máximo da ECDF integral deve ser calculado com `na.rm=TRUE`, pois há estratos vazios; ele é 1.833 dias. Isso não exigiu alteração dos dados. Os 165 controles SINAN e 14 controles dos modelos estão aprovados; os controles de complementos também estão aprovados. Aprovação desses controles não substitui auditoria independente completa dos complementos.

- SINAN integrado idêntico ao candidato corrente; 18 tabelas, 10.707 linhas de cruzamentos e 2.167 linhas de estimativas SINAN. O candidato corrente contém 165 controles da função; os seis testes adicionais da revisão anterior continuam documentados, sem serem confundidos com os controles integrados.
- Coorte de 1.976 registros; períodos com 1.414, 91 e 471 registros e exposições 16.056.726, 5.259.899 e 7.765.671 habitantes-ano aproximados. Taxas padronizadas 8,658266; 1,735349; 6,163950, com IC gamma próprios.
- Grade de taxas: 110 estratos e 1.975 registros com sexo conhecido. Um sexo ignorado permanece nos descritivos integrais. RR M/F ajustada 1,4875286, IC95 1,3423744–1,648379, mantida no pacote e G02.
- Totais de evolução: 190 óbitos por meningite, 76 por outra causa, 1.566 altas, 144 ignorados. Em 2024: 32 ignorados/162 registros. Limite extremo superior reproduzido por (D+U)/N, separado de D/N e D/(N−U).
- Modelo de óbito: 1.967 elegíveis, 1.826 conhecidos e 190 eventos; os 141 ignorados elegíveis entram nos dois cenários agregados. Cenário não evento: N=1.967, D=190; cenário evento: N=1.967, D=331. A matriz das células mistas tem posto 13, igual ao modelo aditivo. A sensibilidade quasi-binomial está salva e preserva os coeficientes do ajuste principal.
- Mensal: 132 meses, 1.976 registros. Covariância HAC e configuração persistidas: lag12, sem pré-branqueamento, ajuste n/(n−k), ordem ano/mês. Reconstrução independente a partir da matriz de desenho, escores NB e covariância convencional: diferença máxima absoluta 1,852379361011458e−12. Wald harmônico reproduzido, 3,780092, df=2, p=0,1510649. Ljung–Box fitdf=0 é explicitamente diagnóstico aproximado, p=0,007596124.
- Intervalos: medianas 4/8/7 dias; 143 maiores de 30, quatro maiores de 365; máximo 1.833. Taxas em <1 ano: 82,45/21,63/42,47; em 20–59: 5,92/1,67/5,27.
- Leitura cruzada do relatório com tabelas: MNE 12,2%→25,9%, taxas 1,63→1,63; MV 8,58→1,87; PCR 2,5%→20,8%; quimiocitológico 76,8%→48,0%. O mestre uniformizou escolaridade: 588/960=61,25% na prosa, 61,2% na tabela com uma casa decimal.
- `source()` do controlador em ambiente novo define somente `executar_aprofundamento`, sem disparar o pipeline. Nenhum download ou ajuste foi executado nesta revisão.

## Inspeção visual e interpretação

G01 distingue taxas brutas e padronizadas e unidades anuais/períodos. G02 distingue IC exato descritivo e IC Wald ajustado. G03 conserva grupos residuais e mostra `<0,1` para taxas positivas pequenas. G04 conserva critérios originais no pacote e esclarece o agrupamento visual. G05 explica pontos cheios/vazados e limites extremos, que não são IC95. G06 mostra toda a cauda na escala log(dias+1), com unidades e medianas legíveis. Não foram observados cortes de títulos, legendas ou notas nas páginas 1–6 renderizadas.

O relatório mantém associação exploratória, OR distinta de RR, critérios de confirmação distintos de identificação do agente e universos próprios de SINAN/SIH/SIM/PNI. As limitações de cobertura, dados ausentes, partições preliminares e inferência causal permanecem explícitas. Esta aprovação não prova completude epidemiológica, ausência de subnotificação, validade clínica individual ou estabilidade futura dos resultados.

## Identidade dos arquivos revisados

Os hashes SHA-256 abaixo identificam a versão aprovada nesta revisão. Alterações posteriores requerem avaliar quais verificações foram afetadas.

| Arquivo | SHA-256 |
| --- | --- |
| meningites_salvador_analitica.rds | `2fe0f7f6f02d6367b9cfa55487f24016dd57c09f4dc979f8975efd7edbb5247d` |
| meningites_aprofundamento.rds | `ddf2225151a6d638a3b7083f9d5d63cca987d7600fb5d9d6014e1a1dddd711aa` |
| RELATORIO_APROFUNDADO.md | `d61bb6376aaf1d6f5fe131a5214e4ed03e021ba66225dac5b526caeb9bdc9733` |
| executar_aprofundamento.R | `056723540c9a01417b0902ca33689e32c5dc61e31c241a0778290d5c528ddd0e` |
| CADERNO_GRAFICOS_APROFUNDADOS.pdf | `286d671e71bdda2de094fa3e7323ded3dab9cb606e3d40b99bbfda8f44d054f0` |
| G01_taxas_idade_periodos.png | `66ba0757233a5a3109fdc6853f976b7995fdc06ebdba907f3eec5edecda49483` |
| G02_razoes_sexo_idade.png | `cee4ce997b3be2a508624ec37e502b2633adc189fa3b61ce70bf83884baa727b` |
| G03_etiologia_idade.png | `ce0427da4a86ac6d2b5220d1b3b1ac0b975d98d7085eb362f0a3e6b6d5db61eb` |
| G04_criterios_etiologia.png | `ccbb653cdf5d36408a0a6960ca61a2bdcf5b19b5db3c0942fd7398c13b35f2e1` |
| G05_evolucao_limites.png | `573d320b453411dc216caa15ccaa4c3e5b3e8dc4e6c5cb2a4f38b25050bee1b5` |
| G06_intervalo_notificacao.png | `640bbfd1acedba18906e4ee696387dc760aaa5f02fdb5c97e8b4a2b04312be7f` |
