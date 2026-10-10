# Estado do projeto — preparação analítica executada em 10/10/2026

O comando humano “Agora inicie o plano” autorizou a execução. A entrada central é [Meningite/analise](../pipeline/Meningite/analise/README.md), com RDS local, sete CSVs essenciais, configuração, dicionário/fontes/cobertura, dez conjuntos descritivos e seis figuras PNG/PDF. O [relatório descritivo](../pipeline/Meningite/analise/resultados/RELATORIO_DESCRITIVO.md) apresenta resultados e limites.

## Dados disponíveis e limites

| Módulo | Evidência atual | Situação e limite |
|---|---|---|
| SINAN | 13 DBC; 295.369 nacionais → 3.871 residentes → 2.255 confirmados → 1.976 com sintomas 2014–2024 | Apto para descrição; 2023–2026 preliminares; não comprova pessoas únicas |
| Confronto TabNet | 572 células comparáveis, zero diferenças; seis extras sem referência | Referência de 05/10, sem presumir mesma data de revisão das fontes |
| Etiologia/evolução | Seis códigos não canônicos, dois vazios, MCC/MNE preservadas; 144 evoluções desconhecidas | Não inventar agente; letalidade final não indicada |
| População | Onze totais, 396 chaves originais, 242 harmonizadas | Integridade/somas locais conferidas; referência em 1º de julho |
| Grade mensal | 132 meses; soma 1.976; agosto/2020 zero derivado da coorte | Não atribuir zeros a consultas externas que falharam |
| Sexo/idade | 242 estratos com denominador; soma 1.975 de sexo conhecido; idade/total conservam 1.976 | Um sexo ignorado fica separado, sem taxa fabricada |
| SIH internações | G00=532, A39=122, A87=489; totais anuais derivados de marginais oficiais | AIHs/episódios, ano de processamento; três outros grupos sem totais observados |
| SIH medidas | 12.250 dias; R$ 2.354.667,12 aprovados nominais, seis folhas CID | Não calcular permanência média/custo por paciente com denominadores incompletos |
| SIH óbitos | 75 em cinco folhas observadas; onze células G01 sem linha/valor | Soma parcial; não total completo de todos os grupos |
| SIM | 202 óbitos por causa básica selecionada; 143 linhas total/perfil | Residência Salvador, registro BA; cobertura nacional não demonstrada |
| PNI | 44 chaves; 17 percentuais e 27 lacunas | Legado/RNDS separados por método/geografia; BCG exige auditoria |
| SIA | Não coletado | Utilidade de recorte específico ainda não demonstrada |

## Retomada efetivamente realizada em 10/10

Foram selecionadas exclusivamente cinco consultas SIH pendentes, com até duas tentativas por consulta, limite de 10 POST e timeout de 25 segundos. A rodada fez **9 POST SIH**, concluindo dias de permanência e A39 por sexo. Restam internações gerais, G00 por sexo e A39 por idade. O conjunto ampliado de 09/10 tinha seis consultas SIH/SIM válidas; passou a oito válidas entre as onze previstas.

PNI fez **2 POST BCG**, ambos sem retorno válido, e interrompeu antes de MenC/pneumocócica. Os oito valores RNDS e nove Penta legados validados não foram baixados novamente. O ledger adicional contém também **2 GET**; formulários reais preservados de 09/10 foram reaproveitados após falhas de transporte, com origem registrada. Contadores não substituem nem apagam os 24 POST históricos de complementos ou a rodada PNI anterior.

Parâmetros, respostas tratadas e falhas estão no [resultado da retomada](../pipeline/Meningite/analise/trabalho/complementos/aquisicao/RESULTADO_RETOMADA.json) e no [ledger](../pipeline/Meningite/analise/trabalho/complementos/aquisicao/requisicoes.json). Não converter erro de transporte, linha ausente ou cobertura parcial em zero. Nenhuma consulta adicional foi realizada depois de atingir os critérios de interrupção.

## Validação, coordenação e apresentação

“Revisar contexto do projeto (2)” preparou SINAN/população em área exclusiva e realizou 39 verificações independentes. “Revisar contexto do projeto” preparou os complementos e realizou 17 verificações. O mestre integrou e validou **352 controles**, gerou D01–D10 e seis figuras. Os campos originais da coorte foram comparados integralmente; IC95 de 409 linhas conferidos contra Poisson exato, diferença máxima zero.

As revisões localizaram soma textual hospitalar com NA; a redação atual declara 75 óbitos parciais em cinco folhas e G01 sem valor. F02 torna ICs por sexo legíveis com escalas próprias declaradas; F05 explicita escalas por CID. Os seis PNGs e os seis PDFs renderizados foram inspecionados. O RDS aceito foi mantido após alterações de apresentação; hashes atualizados no fechamento.

Consultar [validação](../pipeline/Meningite/analise/controle/validacao.json), [QA visual](../pipeline/Meningite/analise/controle/QA_VISUAL.json), [revisão do núcleo](../pipeline/Meningite/analise/documentacao/REVISAO_SINAN_POPULACAO.md), [revisão dos complementos](../pipeline/Meningite/analise/documentacao/REVISAO_COMPLEMENTOS.md), [decisões](../pipeline/Meningite/analise/documentacao/decisoes.md) e [selo final](../pipeline/Meningite/analise/controle/VERIFICACAO_ENTREGA.json). Integridade/apresentação não comprovam validade clínica, eficácia vacinal ou causalidade.

## Reprodução e históricos

Entrada atual local: `Meningite/analise/meningites_salvador_analitica.rds`. A preparação R é offline, lê configuração e confere a entrada congelada de 09/10. Abrir o RDS exige somente R. Em clone Git, sete CSVs e descritivos podem ser usados diretamente; a reprodução integral exige transferir/coletar DBC, respostas/caches e RDS compatíveis. Bibliotecas locais foram descobertas via R_LIBS_USER; não houve instalação de pacotes.

O [manifesto analítico](../pipeline/Meningite/analise/manifesto_portabilidade.json) usa lista pública explícita. Os 45 arquivos do [manifesto histórico de 09/10](../pipeline/Meningite/manifesto_portabilidade.json) foram novamente conferidos em ambas as raízes e permanecem intactos. O [relatório de coleta de 09/10](../pipeline/Meningite/RELATORIO_COLETA_INTEGRAL_20261009.md), o plano que antecedeu a execução e a pré-análise de 05/10 continuam históricos. Não reescrever um resultado antigo como se fosse calculado pela nova versão.

## Próximas decisões científicas

O núcleo permite estudar ocorrência registrada por ano, sexo/idade, distribuição mensal, mudança das categorias etiológicas e qualidade do preenchimento. SIH oferece comparação descritiva de grupos selecionados; vacinação é contexto parcial, sem teste de eficácia. Antes de modelar, definir pergunta principal, recorte, confusão, volume de eventos e análise de sensibilidade.

Se necessário, retomar somente três consultas SIH e 27 chaves PNI legadas; conferir abrangência SIM nacional se mortalidade for eixo principal. Não somar fontes como pessoas, emendar eras vacinais, tratar todo A39 como meningite meningocócica ou interpretar MV como isolamento viral. Novos modelos devem ser planejados a partir da qualidade real desta entrega.
