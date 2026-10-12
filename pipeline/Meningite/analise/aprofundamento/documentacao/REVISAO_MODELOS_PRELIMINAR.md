# Revisao independente dos modelos candidatos

Data:12/10/2026. Escopo somente leitura de `scripts/ajustar_modelos.R`, `trabalho/modelos_candidato.rds` e das entradas aprovadas. Calculos de verificacao em memoria, sem executar a funcao ajustar_modelos ou reestimar os ajustes. Nenhum script final, candidato, configuracao ou Git alterado; este parecer e o unico arquivo produzido nesta revisao.

**Parecer:** nao foram encontrados erros numericos materiais nos coeficientes, exposicoes, IC e LRT conferidos. Modelo de taxas apto como associacao exploratoria; modelo mensal exige ressalva sobre dependencia/adequacao da media; modelo de obito permanece exploratorio no universo selecionado, com limitacoes de incerteza descritas abaixo.

## Controles independentes

29 verificacoes mecanicas aprovadas. Foram conferidos158coeficientes/erros-padrao/IC nos dez objetos compactados, incluindo sensibilidade quasi e tres modelos de evolucao. Adicionalmente, seiscoeficientes/IC HAC e o teste sazonal foram reconstruidos, bem como os diagnosticos de suporte do modelo binomial.

| Controle | Evidencia |
|---|---|
| Grade anual |110chaves unicas;1975registros M/F; uma celula com zero. Contagens e populacoes identicas a grade aprovada da FrenteA. |
| Exposicao mensal |132meses,1976registros e um zero; soma da exposicao mensal por ano igual a populacao anual, ponderando dias do mes/ano bissexto. |
| IC e SE |IC reproduzidos como exp(beta +/- quantil*SE); SE coincide com diagonal da covariancia. Quasi usa t com df residual, outros modelos normais assintoticos. |
| LRT interacao |Principal16coeficientes e interacao20:4gl. Log-verossimilhancas NB recalculadas com coeficientes/theta de cada modelo: estatistica8,0327005457 e p0,0903876496, identicos ao candidato. Theta foi estimado em cada modelo; nao conta como diferenca adicional de gl entre eles. |
| Principal M/F |RR1,4875286;IC95 1,3423744-1,648379. ReferenciaF, idade ampla e ano categorico; nao e OR nem efeito causal. |
| Sobredispersao |Poisson principal phi1,352577,pPearson0,012956; NB escolhida theta92,19487,phi residual1,140214,convergente e sem avisos registrados. Sensibilidade quasi explicita,RR1,489973,IC1,341033-1,655454. |
| Sensibilidades |SemMCC usa1956M/F, pois os19MCC sao retirados do universo conhecido1975; sem2014 usa1614,sem2023-24 usa1647; faixas originais conserva1975/242linhas. Nao comparar AIC de ajustes com dados distintos; quasi nao tem AIC publicado. |
| Mensal NB/HAC |HAC reconstruida dos scores NB, kernel Bartlett lag12, sem prewhitening, multiplicador n/(n-k). Diferenca maxima dos SE3,8e-12; seisIC conferem. Wald conjunto seno/cosseno3,780092,2gl,p0,1510649. |
| Evolucao |Universo1967apos excluir8residuais e1sexoignorado;1826conhecidos,190eventos,141desconhecidos elegiveis. Grade agregada123celulas,n1826,d190;13coeficientes/rank13. |

## Interpretacao e graus de liberdade

A formula principal e `n ~ sexo + faixa_modelo + ano_f + offset(log(populacao))`. Coeficientes exponenciados sao razoes de taxas registradas condicionadas as covariaveis. O intercepto e taxa da referencia porhabitante-ano, conforme rotulo proprio, nao uma razao entre grupos. O sexoM do modelo com interacao corresponde a faixa etaria de referencia, nao ao mesmo RR comum1,4875.

O LRT compara modelos NB aninhados com a mesma grade e theta reestimado, de acordo com a documentacao [MASS anova.negbin](https://stat.ethz.ch/R-manual/R-devel/library/MASS/html/anova.negbin.html). Os4gl estao corretos. P0,0904 nao demonstra homogeneidade absoluta; o teste e exploratorio e seu poder/suporte variam por idade.

A selecao por phi>1 e pPearson<0,05, seguida do gateNB, e regra operacional transparente, nao prova de distribuicao verdadeira. Na sensibilidade com faixas originais, pPearson0,05364 esta proximo do corte; apresentar a decisao e a sensibilidade quasi sem afirmar ausencia comprovada de sobredispersao. IC normais da NB e IC t da quasi estao conforme a regra codificada; estes IC nao sao os IC exatos das razoes descritivas.

## Mensal: dependencia e rastreabilidade

O modelo combina tendencia linear, periodos e harmonicos. A curva sazonal mantem tendencia/exposicao/periodo fixos: nao e previsao factual de um ano observado. Sua unidade e registros previstos por100mil em1/12ano; nao chamar os valores diretamente de taxa anual observada.

Autocorrelacao lag1=0,2309985 e Ljung-Box lag12 com `fitdf=2`,p0,00255584. A conclusao de dependencia residual persiste nas verificacoes `fitdf=0` (p0,00759612) e `fitdf=6` (p0,00014162). Contudo, os2harmonicos nao representam uma ordemARMA(p+q); nao apresentar a subtracao de2gl como calibracao exata demonstrada para este GLM. Documentar o teste como diagnostico aproximado e manter ACF/residuos como evidencia. [Documentacao Box.test](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/box.test.html).

HAC corrige a covariancia sob pressupostos, sem assegurar adequacao da media ou remover a autocorrelacao. P0,151 nao comprova ausencia de sazonalidade nem impossibilidade de outro padrao; limita-se ao par seno/cosseno nesta especificacao. Nao usar conclusao causal de pandemia ou vacina.

**Melhoria de rastreabilidade comunicada ao mestre:** o objeto compactado `mensal_harmonico` guarda vcov padraoNB, mas nao a matrizVhac usada nos IC robustos e Wald conjunto. Os numeros foram validados pela reconstrucao independente dos scores; recomenda-se persistir tambem Vhac, lag, kernel, prewhite, adjust e versao do pacote. Nao substituir silenciosamente a covariance padrao. Referencia:[sandwich](https://cran.r-project.org/web/packages/sandwich/sandwich.pdf).

## Obito: universo, separacao e gates

Ha12parametros explicativos mais intercepto: sexo1,idade4,etiologia5,periodo2. O criterio190/12=15,83eventos por parametro e somente operacional. O agregado possui55celulas sem obitos e4celulas com somente eventos; isso nao significa, por si, separacao do modelo aditivo.

Conferencia adicional: as64celulas com eventos e nao eventos tem matriz de desenho de rank13, igual ao rank completo. Nesta formula, isso impede uma direcao linear nao nula de separacao completa/quase-separacao: tal direcao precisaria ter produto zero com todas as linhas mistas, que ja abrangem o espaco dos13coeficientes. Probabilidades ajustadas variam de0,004164 a0,584599, sem extremos0/1. Esta evidencia e mais forte que apenas convergencia e |beta|<20; o gate futuro deve manter verificacao de suporte/identificabilidade, sem assumir que se aplica a novas fontes ou modelos.

**Incerteza binomial:**113das123celulas tem numero esperado de eventos<5. A dispersao Pearson agregada recalculada e1,341374. A aproximacao qui-quadrado global com muitas celulas raras requer cuidado; esse numero nao demonstra sozinho sobredispersao real. Ainda assim, ICWald binomiais assumem especificacao/independencia adequadas. Recomenda-se sensibilidade de covariancia robusta ou quasi-binomial se o modelo for destacado como inferencia, com justificativa e sem selecionar a versao mais significativa. O ajuste atual pode ser apresentado como exploratorio, sem chamar os IC de exatos ou prognostico validado.

Os limites de desconhecidos neste modulo sao atribuicoes dos **141desconhecidos no universo elegivel1967**, nao das144evolucoes desconhecidas da coorte1976. Se todos elegiveis desconhecidos forem nao evento, eventos190; se todos forem evento, eventos331. Seis registros residuais conhecidos sao excluidos dos1826, e o sexoignorado estava entre os desconhecidos. Essa selecao precisa constar do texto e da legenda; o descritivo principal N,D,U continua incluindo a coorte inteira.

OR entre evolucoes conhecidas nao e risco relativo, taxa populacional ou letalidade completa. Modelos extremos sao sensibilidades de classificacao, nao imputacoes plausiveis demonstradas e nao intervalos de confianca. Nenhuma analise resolve selecao por encerramento conhecido, dependencia de registros/pessoas ou validade clinica.

## Arquivos efetivamente conferidos

- `scripts/ajustar_modelos.R`: SHA-256 `8095dca03b6bad0cdf2ebc40605aadb91ecb37e751f981e1bacd2cb68360af21`.
- `trabalho/modelos_candidato.rds`: SHA-256 `532a3a814d4ccc64d226f40c997753f877e6ed9ecf2300a86af4d796ae0c44f7`.

Caminhos relativos a `Meningite/analise/aprofundamento`. Alteracoes posteriores do mestre constituem outra versao. Nao foram auditados aqui graficos/texto finais ainda em integracao. O parecer nao reexecuta todos os gates do mestre nem certifica adequacao causal/clinica.
