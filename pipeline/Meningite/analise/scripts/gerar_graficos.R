# Figuras derivadas dos descritivos, com PNG de consulta e PDF vetorial.
gerar_graficos <- function(pacote, config, destino, somente=NULL) {
  if(!requireNamespace("ggplot2",quietly=TRUE)) stop("ggplot2 não está disponível")
  dir.create(destino,recursive=TRUE,showWarnings=FALSE)
  T <- pacote$resultados$tabelas
  tema <- ggplot2::theme_minimal(base_size=12,base_family="sans") +
    ggplot2::theme(panel.grid.minor=ggplot2::element_blank(),panel.grid.major.x=ggplot2::element_blank(),
      plot.title=ggplot2::element_text(face="bold",size=15),plot.subtitle=ggplot2::element_text(size=11),
      plot.caption=ggplot2::element_text(size=9,hjust=0),legend.position="bottom",
      strip.text=ggplot2::element_text(face="bold",size=12),plot.margin=ggplot2::margin(12,16,12,12))
  criadas <- list()
  salvar <- function(p,nome,largura,altura,origem) {
    if(!is.null(somente) && !nome %in% somente) return(invisible(NULL))
    png <- file.path(destino,paste0(nome,".png")); pdf <- file.path(destino,paste0(nome,".pdf"))
    ggplot2::ggsave(png,p,width=largura,height=altura,units="in",dpi=220,bg="white")
    ggplot2::ggsave(pdf,p,width=largura,height=altura,units="in",device=grDevices::cairo_pdf,bg="white")
    criadas[[nome]] <<- data.frame(figura=nome,tabela_origem=origem,png=basename(png),pdf=basename(pdf))
  }
  a <- T$serie_anual
  pa <- rbind(data.frame(a,painel="Registros confirmados",valor=a$n,li=NA_real_,ls=NA_real_),
    data.frame(a,painel="Taxa por 100 mil habitantes",valor=a$taxa_100mil,li=a$ic95_inferior,ls=a$ic95_superior))
  pa$painel <- factor(pa$painel,levels=c("Registros confirmados","Taxa por 100 mil habitantes"))
  p <- ggplot2::ggplot(pa,ggplot2::aes(ano,valor)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin=li,ymax=ls),fill="#4682A9",alpha=.18,na.rm=TRUE) +
    ggplot2::geom_line(color="#24567A",linewidth=.8) + ggplot2::geom_point(color="#24567A",size=2.2) +
    ggplot2::facet_wrap(~painel,ncol=1,scales="free_y") +
    ggplot2::scale_x_continuous(breaks=config$anos) + ggplot2::scale_y_continuous(limits=c(0,NA),expand=ggplot2::expansion(mult=c(0,.08))) +
    ggplot2::labs(title="Meningites e doença meningocócica em Salvador",subtitle="Ocorrência registrada em residentes, 2014–2024",
      x="Ano dos primeiros sintomas",y=NULL,
      caption="Fonte: SINAN nacional; população DATASUS/RIPSA em 1º de julho. Faixa: IC95 exato de Poisson.\nInclui MCC isolada e MNE; 2023–2024 em partições preliminares. Registros não equivalem a pessoas únicas.") + tema
  salvar(p,"F01_evolucao_anual",10.5,7.5,"D02/serie_anual")
  sx <- T$sexo_periodo; ag <- T$idade_periodo
  sx$rotulo <- ifelse(sx$sexo=="M","Masculino","Feminino")
  ag$rotulo <- ag$faixa
  rp <- rbind(data.frame(painel="Sexo",rotulo=sx$rotulo,n=sx$n,taxa=sx$taxa_100mil,li=sx$ic95_inferior,ls=sx$ic95_superior),
    data.frame(painel="Idade",rotulo=ag$rotulo,n=ag$n,taxa=ag$taxa_100mil,li=ag$ic95_inferior,ls=ag$ic95_superior))
  ordem <- c("Feminino","Masculino",rev(config$faixas))
  rp$rotulo <- factor(rp$rotulo,levels=ordem)
  rp$painel <- factor(rp$painel,levels=c("Sexo","Idade"))
  p <- ggplot2::ggplot(rp,ggplot2::aes(x=taxa,y=rotulo)) +
    ggplot2::geom_segment(ggplot2::aes(x=li,xend=ls,yend=rotulo),color="#24567A",linewidth=.65) +
    ggplot2::geom_point(color="#24567A",size=2.7) +
    ggplot2::geom_text(data=rp[rp$painel=="Sexo",],
      ggplot2::aes(label=formatC(taxa,format="f",digits=2,decimal.mark=",")),nudge_x=.6,hjust=0,size=4) +
    ggplot2::facet_wrap(~painel,ncol=2,scales="free") +
    ggplot2::scale_x_continuous(limits=c(0,NA),expand=ggplot2::expansion(mult=c(.01,.20))) +
    ggplot2::labs(title="Perfil de ocorrência por sexo e idade",subtitle="Taxa média ponderada do período 2014–2024, com IC95",
      x="Registros por 100 mil habitantes-ano",y=NULL,
      caption=paste0("Fonte: SINAN nacional e população DATASUS/RIPSA. Exposição aproximada pela soma das populações anuais.\n",
        "Escalas próprias por painel; marginais separadas. Sexo ignorado: ",pacote$resultados$resumo$sexo_ignorado,"; conservado no total, sem taxa específica.")) + tema
  salvar(p,"F02_perfil_sexo_idade",11,6.5,"D03/sexo_periodo e idade_periodo")
  mm <- T$mensal
  meses <- c("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")
  mm$mes_nome <- factor(meses[mm$mes],levels=meses)
  mm$ano_factor <- factor(mm$ano,levels=rev(config$anos))
  mm$cor_texto <- ifelse(mm$n>max(mm$n)*.55,"alto","baixo")
  p <- ggplot2::ggplot(mm,ggplot2::aes(mes_nome,ano_factor,fill=n)) +
    ggplot2::geom_tile(color="white",linewidth=.7) +
    ggplot2::geom_text(ggplot2::aes(label=n,color=cor_texto),size=3.4,show.legend=FALSE) +
    ggplot2::scale_color_manual(values=c(alto="white",baixo="#202020")) +
    ggplot2::scale_fill_gradient(low="#F4F6F8",high="#24567A",name="Registros") +
    ggplot2::labs(title="Distribuição dos registros por mês dos sintomas",subtitle="Salvador, 2014–2024: 132 meses conferidos",x=NULL,y=NULL,
      caption="Fonte: SINAN nacional, residentes de Salvador. As células representam contagens, sem população mensal.\nAgosto/2020 teve zero registros na coorte integral; esse zero não foi imputado a uma exportação ausente.") +
    tema + ggplot2::theme(panel.grid=ggplot2::element_blank())
  salvar(p,"F03_distribuicao_mensal",10.5,7,"D05/mensal")
  eg <- T$grupos_etiologia_anuais
  ordem_etiol <- c("Viral (MV)","Não especificada (MNE)","Outras bacterianas","Doença meningocócica",
    "Tuberculosa (MTBC)","Outra etiologia (MOE)","Vazio/não canônico")
  eg$grupo <- factor(eg$grupo,levels=ordem_etiol)
  cores <- setNames(c("#487EA4","#ADB3BA","#D09358","#765989","#639B79","#CD7880","#E3E5E7"),ordem_etiol)
  p <- ggplot2::ggplot(eg,ggplot2::aes(factor(ano),percentual,fill=grupo)) +
    ggplot2::geom_col(width=.75) + ggplot2::scale_fill_manual(values=cores,drop=FALSE) +
    ggplot2::scale_y_continuous(limits=c(0,100),breaks=c(0,25,50,75,100),expand=ggplot2::expansion(mult=c(0,0))) +
    ggplot2::guides(fill=ggplot2::guide_legend(nrow=3,byrow=TRUE)) +
    ggplot2::labs(title="Composição da classificação etiológica",subtitle="Categorias registradas, com denominador de todos os registros de cada ano",
      x="Ano dos primeiros sintomas",y="Percentual (%)",fill=NULL,
      caption="Fonte: SINAN nacional. Grupos disjuntos; categorias originais permanecem nas tabelas e no pacote.\nMV não comprova isolamento viral. MNE e MCC isolada conservadas; seis códigos não canônicos e dois vazios incluídos.") + tema
  salvar(p,"F04_classificacao_etiologica",10.5,7,"D04/grupos_etiologia_anuais")
  # Complementos são adicionados somente quando suas séries foram aceitas.
  sih <- T$sih_serie_figura
  if(!is.null(sih) && nrow(sih)>0) {
    sih$cid <- factor(sih$cid,levels=c("G00","A39","A87"))
    p <- ggplot2::ggplot(sih,ggplot2::aes(ano,valor)) + ggplot2::geom_line(color="#24567A",linewidth=.8,na.rm=TRUE) +
      ggplot2::geom_point(color="#24567A",size=2,na.rm=TRUE) +
      ggplot2::facet_wrap(~cid,ncol=1,scales="free_y",labeller=ggplot2::as_labeller(c(G00="G00: meningite bacteriana",
        A39="A39: infecção meningocócica",A87="A87: meningite viral"))) +
      ggplot2::scale_x_continuous(breaks=config$anos) + ggplot2::scale_y_continuous(limits=c(0,NA)) +
      ggplot2::labs(title="Internações registradas no SIH/SUS",subtitle="Residentes de Salvador; séries disponíveis por CID",
        x="Ano de processamento",y="Internações/AIHs",
        caption="Fonte: SIH/SUS. AIHs/episódios; ano de processamento. Escalas próprias por CID.\nA39 inclui outras apresentações meningocócicas. Ano distinto dos sintomas no SINAN; ausências interrompem linhas.") + tema
    salvar(p,"F05_internacoes_disponiveis",10.5,8,"D07/sih_serie_figura")
  }
  pni <- T$pni_figura
  if(!is.null(pni) && nrow(pni)>0) {
    p <- ggplot2::ggplot(pni,ggplot2::aes(ano,valor,color=metodo,shape=metodo,group=metodo)) +
      ggplot2::geom_point(size=2.7,na.rm=TRUE) + ggplot2::facet_wrap(~indicador,ncol=2) +
      ggplot2::scale_x_continuous(breaks=seq(2014,2024,2),limits=c(2014,2024)) +
      ggplot2::scale_y_continuous(limits=c(0,NA)) +
      ggplot2::scale_color_manual(values=c("Legado: município do registro"="#A77735","RNDS: residência"="#24567A")) +
      ggplot2::labs(title="Coberturas vacinais registradas no PNI",subtitle="Séries e métodos apresentados separadamente; lacunas não são zeros",
        x="Ano do indicador",y="Cobertura registrada (%)",color=NULL,shape=NULL,
        caption="Fonte: PNI legado e painel RNDS; definições e componentes oficiais disponíveis no pacote.\nConjugadas atuais não equivalem a produtos exclusivos; BCG baixo exige auditoria. Não conectar métodos nem inferir eficácia.") + tema
    salvar(p,"F06_cobertura_vacinal_registrada",11,7.5,"D09/pni_figura")
  }
  do.call(rbind,criadas)
}
