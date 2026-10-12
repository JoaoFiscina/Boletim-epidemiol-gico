gerar_figuras_aprofundadas <- function(pacote, config, destino) {
  library(ggplot2)
  library(patchwork)
  T <- pacote$sinan$tabelas; C <- pacote$complementos$tabelas; M <- pacote$modelos
  dir.create(destino,recursive=TRUE,showWarnings=FALSE)
  theme_set(theme_minimal(base_size=12,base_family="sans") + theme(panel.grid.minor=element_blank(),
    panel.grid.major.x=element_blank(),plot.title=element_text(face="bold",size=16),
    plot.subtitle=element_text(size=11),plot.caption=element_text(size=9,hjust=0),
    legend.position="bottom",strip.text=element_text(face="bold"),plot.margin=margin(12,20,12,14)))
  cols <- c("2014-2019"="#24567A","2020-2021"="#BD6C38","2022-2024"="#39816C")
  grupos <- c("MV","MNE","Bacterianas_MB_MH_MP","Meningococica_MCC_MM","MTBC","MOE","Vazio_nao_canonico")
  labs <- c("Viral (MV)","Não especificada (MNE)","Outras bacterianas","Meningocócica, inclui MCC","Tuberculosa","Outra etiologia","Vazio/não canônico")
  ng <- setNames(labs,grupos)
  figs <- list();origens<-list(); f <- function(id,p,src) {figs[[id]]<<-p;origens[[id]]<<-src}
  # A1: comparações no mesmo eixo e população padrão fixa.
  a<-T$padronizadas_anuais;a$ano<-as.integer(a$ano)
  p1<-ggplot(a,aes(ano,taxa))+geom_ribbon(aes(ymin=ic_inferior,ymax=ic_superior),fill="#24567A",alpha=.15)+
    geom_line(color="#24567A",linewidth=.8)+geom_point(color="#24567A",size=2.4)+
    geom_line(aes(y=bruta),color="#999999",linetype=2)+scale_x_continuous(breaks=config$anos)+
    scale_y_continuous(limits=c(0,NA))+labs(title="Taxas com a mesma composição de idades",subtitle="Linha azul: padronizada por idade, IC95 gamma. Tracejada: taxa bruta.",x="Ano dos sintomas",y="Registros por 100 mil")
  aa<-T$periodo_faixa_ampla;aa$faixa_ampla<-factor(aa$faixa_ampla,levels=c("<1","1-4","5-19","20-59","60+"))
  p2<-ggplot(aa,aes(faixa_ampla,taxa,color=periodo,group=periodo))+geom_line()+geom_point(size=2.4)+
    geom_errorbar(aes(ymin=ic_inferior,ymax=ic_superior),width=.12,position=position_dodge(.05))+
    scale_color_manual(values=cols)+scale_y_continuous(limits=c(0,NA))+labs(title="A queda varia entre as idades",x="Idade (anos)",y="Registros por 100 mil habitantes-ano",color="Período")
  p<-(p1/p2)+patchwork::plot_annotation(title="Ocorrência registrada em Salvador, 2014–2024",
    caption="SINAN nacional e DATASUS/RIPSA. Pesos fixos: população por idade somada de 2014–2024.\nExposição aproximada pela soma das populações anuais. MCC incluída; partições 2023–2024 preliminares. Sem atribuição causal aos períodos.")
  f("G01_taxas_idade_periodos",p,"padronizadas_anuais; periodo_faixa_ampla")
  # A2: razão de taxas e não comparação de contagens sem denominador.
  sx<-T$razoes_sexo_idade[T$razoes_sexo_idade$periodo=="2014-2024",]
  sx$rotulo<-sx$idade;sx$valor<-sx$razao_M_F;sx$li<-sx$ic_inferior;sx$ls<-sx$ic_superior;sx$tipo<-"Razões específicas por idade"
  rr<-M$coeficientes[M$coeficientes$modelo=="taxas_principal" & M$coeficientes$termo=="sexoM",]
  forest<-rbind(sx[c("rotulo","valor","li","ls","tipo")],data.frame(rotulo="Ajuste por idade e ano",valor=rr$estimativa,li=rr$ic95_inferior,ls=rr$ic95_superior,tipo="Estimativa ajustada"))
  forest$rotulo<-factor(forest$rotulo,levels=rev(c(config$faixas,"Ajuste por idade e ano")))
  p<-ggplot(forest,aes(valor,rotulo,color=tipo))+geom_vline(xintercept=1,linetype=2,color="#777777")+
    geom_segment(aes(x=li,xend=ls,yend=rotulo),linewidth=.8)+geom_point(size=3)+
    scale_x_log10(breaks=c(.5,1,1.5,2,3,5))+scale_color_manual(values=c("Estimativa ajustada"="#BD6C38","Razões específicas por idade"="#24567A"))+
    labs(title="Diferença de taxas entre homens e mulheres",subtitle=sprintf("Estimativa ajustada M/F: %.2f (IC95 %.2f–%.2f)",rr$estimativa,rr$ic95_inferior,rr$ic95_superior),
      x="Razão de taxas M/F (escala logarítmica)",y="Idade (anos)",color=NULL,
      caption="SINAN e população DATASUS/RIPSA, 2014–2024. Específicas: IC exato de Poisson; ajuste: binomial negativa, IC Wald.\n1.975 registros com sexo conhecido; um ignorado permanece no total. Ajuste usa cinco faixas amplas. Associação exploratória.")
  f("G02_razoes_sexo_idade",p,"razoes_sexo_idade; modelos/coeficientes taxas_principal")
  # A3: somar exposições uma vez por idade, antes de expandir os grupos.
  ie<-T$idade_etiologia;ie$faixa<-unname(unlist(config$faixas_amplas)[ie$idade])
  ag<-aggregate(n~faixa+grupo,ie,sum)
  pop<-aggregate(populacao~faixa,ie[ie$grupo==grupos[1],],sum)
  ag<-merge(ag,pop,by="faixa",sort=FALSE); totals<-aggregate(n~faixa,ag,sum);names(totals)[2]<-"N"
  ag<-merge(ag,totals,by="faixa");ag$taxa<-ag$n/ag$populacao*100000;ag$percentual<-ag$n/ag$N*100
  ag$faixa<-factor(ag$faixa,levels=c("<1","1-4","5-19","20-59","60+"));ag$grupo<-factor(ng[ag$grupo],levels=rev(labs))
  heat<-function(campo,titulo,legenda) ggplot(ag,aes(faixa,grupo,fill=.data[[campo]]))+
    geom_tile(color="white",linewidth=.7)+geom_text(aes(label=ifelse(n>0 & .data[[campo]]<.1,"<0,1",sprintf("%.1f",.data[[campo]]))),size=3.7)+
    scale_fill_gradient(low="#F2F4F6",high="#80B0CD",name=legenda)+labs(title=titulo,x="Idade (anos)",y=NULL)+theme(legend.position="bottom")
  p<-(heat("percentual","Composição dentro de cada idade","% dos registros")/heat("taxa","Taxa na população de cada idade","Por 100 mil/ano"))+
    patchwork::plot_annotation(title="Idade e classificação etiológica",caption="SINAN e DATASUS/RIPSA, 2014–2024. Percentuais: todos os registros da idade, inclusive residuais.\nTaxas: contagem dividida pela soma da população da idade. Classificação registrada; MV não comprova isolamento viral.")
  f("G03_etiologia_idade",p,"idade_etiologia, agregada em cinco faixas; populações sem duplicação de grupo")
  # A4: critérios agrupados apenas para apresentação, categorias originais na base.
  ec<-T$etiologia_criterio
  agrup<-c("Cultura"="Cultura/CIE/látex", "CIE"="Cultura/CIE/látex","AG. Latex"="Cultura/CIE/látex",
    "Bacterioscopia"="Bacterioscopia/PCR","PCR"="Bacterioscopia/PCR", "Quimiocitológico"="Quimiocitológico",
    "Clínico"="Clínico/clínico-epid.","Clínico-epidemiológico"="Clínico/clínico-epid.",
    "Isolamento viral"="Isolamento viral/outra","Outra técnica"="Isolamento viral/outra","Em branco"="Em branco")
  ec$criterio<-unname(agrup[ec$criterio_categoria]);ec<-aggregate(n~grupo+criterio,ec,sum)
  N<-aggregate(n~grupo,ec,sum);names(N)[2]<-"N";ec<-merge(ec,N,by="grupo");ec$p<-ec$n/ec$N*100
  ec$grupo<-factor(ng[ec$grupo],levels=rev(labs));ec$criterio<-factor(ec$criterio,levels=unique(agrup))
  p1<-ggplot(ec,aes(criterio,grupo,fill=p))+geom_tile(color="white",linewidth=.7)+geom_text(aes(label=sprintf("%.1f",p)),size=3.7)+
    scale_fill_gradient(low="#F2F4F6",high="#80B0CD",name="% dentro do grupo")+
    scale_x_discrete(labels=function(x)gsub("/","/\n",x,fixed=TRUE))+
    labs(title="Critérios por classificação etiológica",subtitle="Percentual dentro de cada grupo, 2014–2024",x=NULL,y=NULL)
  cp<-T$criterio_periodo;cp<-cp[cp$criterio_categoria %in% c("PCR","Quimiocitológico"),]
  p2<-ggplot(cp,aes(periodo,100*proporcao,color=criterio_categoria,group=criterio_categoria))+geom_line(linewidth=.8)+geom_point(size=2.6)+
    scale_color_manual(values=c(PCR="#BD6C38","Quimiocitológico"="#24567A"))+scale_y_continuous(limits=c(0,100))+
    labs(title="Dois critérios que mudaram no período",x=NULL,y="% de todos os registros",color="Critério registrado")
  p<-(p1/p2)+patchwork::plot_layout(heights=c(1.5,1))+patchwork::plot_annotation(title="Como os registros foram confirmados",
    caption="SINAN nacional. Dez critérios originais e brancos preservados no pacote; linhas mostram dois critérios selecionados.\nQuimiocitológico pode confirmar meningite sem identificar o agente. PCR registrado não comprova, por si, etiologia viral.")
  f("G04_criterios_etiologia",p,"etiologia_criterio; criterio_periodo; mapa de apresentação documentado no script")
  # A5: faixas são limites extremos pelos ignorados, não intervalos estatísticos.
  ev<-T$evolucao[T$evolucao$dimensao=="ano",];ev$ano<-as.integer(ev$ano)
  p1<-ggplot(ev,aes(ano,100*D_sobre_N))+geom_ribbon(aes(ymin=100*limite_extremo_inferior,ymax=100*limite_extremo_superior),fill="#BD6C38",alpha=.18)+
    geom_line(color="#BD6C38")+geom_point(color="#BD6C38",size=2.5)+
    geom_line(aes(y=100*D_sobre_K),color="#24567A",linetype=2)+scale_x_continuous(breaks=config$anos)+
    scale_y_continuous(limits=c(0,NA))+labs(title="Óbito por meningite e incerteza dos ignorados",subtitle="Laranja: D/N. Tracejada: D/(N−U). Faixa: de D/N a (D+U)/N.",x="Ano dos sintomas",y="Percentual (%)")
  ee<-T$evolucao[T$evolucao$dimensao=="grupo",];ee$rotulo<-paste0(ng[ee$grupo]," (n=",ee$N,")")
  ee$rotulo<-factor(ee$rotulo,levels=rev(ee$rotulo[match(grupos,ee$grupo)]))
  p2<-ggplot(ee,aes(100*D_sobre_N,rotulo))+geom_segment(aes(x=100*limite_extremo_inferior,xend=100*limite_extremo_superior,yend=rotulo),color="#BD6C38",linewidth=1.3)+
    geom_point(color="#BD6C38",size=3)+geom_point(aes(x=100*D_sobre_K),shape=1,color="#24567A",size=3)+
    scale_x_continuous(limits=c(0,NA))+labs(title="Desfecho por grupo etiológico",subtitle="Cheio: D/N. Vazado: D/(N−U). Segmentos: limites extremos.",x="Óbitos por meningite (%)",y=NULL)
  p<-(p1/p2)+patchwork::plot_annotation(caption="SINAN, residentes de Salvador. D: óbito por meningite; U: evolução ignorada; N: todos os registros.\n190 óbitos por meningite, 76 por outra causa, 144 ignorados. Faixas não são IC95. Mistura de casos e qualidade limitam comparações.")
  f("G05_evolucao_limites",p,"evolucao dimensões ano/grupo")
  # A6: distribuição inteira, inclusive quatro extremos >365 dias.
  ed<-T$ecdf_atraso[T$ecdf_atraso$grupo=="Todos" & T$ecdf_atraso$cenario=="integral",]
  ed$dia_log<-log1p(ed$dias);ad<-T$atraso[T$atraso$dimensao=="periodo",]
  lbl<-setNames(paste0(ad$periodo," (n=",ad$n_valido,"; mediana ",ad$mediana," d)"),ad$periodo)
  p<-ggplot(ed,aes(dia_log,100*F,color=periodo))+geom_step(linewidth=.95)+
    geom_vline(xintercept=log1p(30),linetype=2,color="#888888")+
    scale_color_manual(values=cols,labels=lbl)+scale_x_continuous(breaks=log1p(c(0,1,3,7,14,30,90,365,1833)),labels=c(0,1,3,7,14,30,90,365,1833))+
    scale_y_continuous(limits=c(0,100),breaks=seq(0,100,20))+
    labs(title="Intervalo entre sintomas e notificação",subtitle="Distribuição acumulada: proporção notificada até cada intervalo",x="Dias após os sintomas (escala log de dias + 1)",y="Percentual acumulado (%)",color=NULL,
      caption="SINAN nacional. 1.976 intervalos válidos: 143 >30 dias e quatro >365 dias; máximo 1.833 dias.\nNenhum extremo excluído deste gráfico. Intervalo de registro; não mede tempo até diagnóstico ou atendimento.")
  f("G06_intervalo_notificacao",p,"ecdf_atraso cenário integral; atraso por periodo")
  # B1: resultado exploratório com correção de dependência temporal.
  sz<-M$tabelas$sazonalidade_ajustada;di<-M$tabelas$diagnostico_mensal
  p<-ggplot(sz,aes(mes,estimativa))+geom_ribbon(aes(ymin=ic95_inferior,ymax=ic95_superior),fill="#24567A",alpha=.16)+
    geom_line(color="#24567A",linewidth=.9)+geom_point(color="#24567A",size=2.5)+
    scale_x_continuous(breaks=1:12,labels=c("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"))+
    scale_y_continuous(limits=c(0,NA))+labs(title="Componente mensal ajustado: evidência limitada",
      subtitle=sprintf("Modelo harmônico com tendência e períodos. Teste conjunto, HAC: p=%.3f.",di$p_harmonico_exploratorio),
      x="Mês dos sintomas",y="Registros previstos por 100 mil em 1/12 ano",
      caption="132 meses, 2014–2024. Predição mantém tendência média, período 2014–2019 e exposição de 100 mil/12.\nIC95 pontual HAC, lag12. Há autocorrelação residual; o modelo não sustenta afirmação firme de sazonalidade. Análise suplementar.")
  f("G07_sazonalidade_exploratoria",p,"modelos/sazonalidade_ajustada; diagnostico_mensal")
  # B2/C1 dependem de tabelas efetivamente liberadas pela auditoria.
  if(!is.null(C$perfis_sih) && all(c("dimensao","estrato","valor") %in% names(C$perfis_sih))) {
    si<-C$perfis_sih
    si<-si[si$dimensao=="idade" & si$cid_grupo %in% c("G00","A87"),]
    if(nrow(si)>0 && "denominador" %in% names(si)) {
      si$cid<-si$cid_grupo;si$n<-si$valor;si$populacao<-si$denominador
      ss<-aggregate(cbind(n,populacao)~cid+estrato,si,sum)
      ord<-c("Menor 1 ano","1 a 4 anos","5 a 9 anos","10 a 14 anos","15 a 19 anos","20 a 29 anos","30 a 39 anos","40 a 49 anos","50 a 59 anos","60 a 69 anos","70 a 79 anos","80 anos e mais")
      ss$taxa<-ss$n/ss$populacao*100000;ss$estrato<-factor(ss$estrato,levels=ord)
      p<-ggplot(ss,aes(estrato,taxa,color=cid,group=cid))+geom_line()+geom_point(size=2.6)+
        scale_y_continuous(limits=c(0,NA))+scale_color_manual(values=c(G00="#BD6C38",A87="#24567A"))+
        scale_x_discrete(labels=c("<1","1–4","5–9","10–14","15–19","20–29","30–39","40–49","50–59","60–69","70–79","80+"))+
        labs(title="Perfil etário das internações disponíveis",subtitle="G00: meningite bacteriana; A87: meningite viral, SIH/SUS 2014–2024",x="Idade (anos)",y="AIHs por 100 mil habitantes-ano",color="CID",
          caption="SIH/SUS, residência em Salvador, ano de processamento. AIHs/episódios, não pessoas únicas.\nPopulação DATASUS/RIPSA. Apenas perfis com marginais e faixas compatíveis; nenhum total de todos os CIDs foi imputado.")
      f("G08_perfis_hospitalares",p,"complementos/perfis_sih idade G00/A87")
    }
  }
  for(id in names(figs))ggsave(file.path(destino,paste0(id,".png")),figs[[id]],width=11,height=9,units="in",dpi=220,bg="white")
  pdf<-file.path(destino,"CADERNO_GRAFICOS_APROFUNDADOS.pdf")
  grDevices::cairo_pdf(pdf,width=11,height=9,onefile=TRUE);tryCatch({for(p in figs)print(p)},finally=dev.off())
  data.frame(figura=names(figs),pagina_pdf=seq_along(figs),tabelas_origem=unlist(origens),
    png=paste0(names(figs),".png"),pdf=basename(pdf),row.names=NULL)
}
