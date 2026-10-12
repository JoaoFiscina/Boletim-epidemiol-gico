# Revisão de apresentação, sem alterar bases ou gráficos históricos.
# Rscript revisar_basicos.R C:/caminho/Meningite
args <- commandArgs(TRUE)
raiz <- if(length(args)) args[1] else stop('Informe a pasta Meningite')
library(ggplot2)
library(patchwork)
library(digest)
fonte <- file.path(raiz,'analise/meningites_salvador_analitica.rds')
sha <- digest(readBin(fonte,'raw',n=file.info(fonte)$size),algo='sha256',serialize=FALSE)
stopifnot(identical(sha,'2fe0f7f6f02d6367b9cfa55487f24016dd57c09f4dc979f8975efd7edbb5247d'))
x <- readRDS(fonte)
T <- x$resultados$tabelas
destino <- file.path(raiz,'analise/guia_graficos/figuras_revisadas')
dir.create(destino,recursive=TRUE,showWarnings=FALSE)
tema <- theme_minimal(base_size=13) + theme(panel.grid.minor=element_blank(),
 panel.grid.major.x=element_blank(),plot.title=element_text(size=17,face='bold'),
 plot.subtitle=element_text(size=12),plot.caption=element_text(size=10,hjust=0),
 strip.text=element_text(size=13,face='bold'),legend.position='bottom',plot.margin=margin(12,18,12,14))
theme_set(tema)
fmt <- function(z,d=2) formatC(z,format='f',digits=d,decimal.mark=',')
salvar <- function(p,nome,h=8.5) ggsave(file.path(destino,paste0(nome,'.png')),p,
 width=11,height=h,units='in',dpi=260,bg='white')
# F02: preserva as duas marginais; mostra contagens, taxas e IC sem esconder o denominador.
s <- T$sexo_periodo; a <- T$idade_periodo
s$rotulo <- paste0(ifelse(s$sexo=='M','Masculino','Feminino'),' (n = ',s$n,')')
s$rotulo <- factor(s$rotulo,levels=rev(s$rotulo[s$sexo %in% c('M','F')][order(s$sexo[s$sexo %in% c('M','F')],decreasing=TRUE)]))
a$rotulo <- paste0(a$faixa,' (n = ',a$n,')')
a$rotulo <- factor(a$rotulo,levels=rev(a$rotulo[match(x$configuracao$faixas,a$faixa)]))
taxa <- function(d,titulo,maximo,desloc) ggplot(d,aes(taxa_100mil,rotulo)) +
 geom_segment(aes(x=ic95_inferior,xend=ic95_superior,yend=rotulo),color='#24567A',linewidth=.7) +
 geom_point(size=2.6,color='#24567A') +
 geom_text(aes(x=ic95_superior+desloc,label=fmt(taxa_100mil)),hjust=0,size=4) +
 scale_x_continuous(limits=c(0,maximo),labels=function(z) fmt(z,0)) +
 labs(title=titulo,x='Registros por 100 mil habitantes-ano',y=NULL) + tema
p <- taxa(s,'Sexo',11,.2)/taxa(a,'Idade em anos',83,1) + plot_layout(heights=c(2,6)) +
 plot_annotation(title='Ocorrência por sexo e idade em Salvador',
 subtitle='2014–2024  |  Contagens nos rótulos; pontos e segmentos mostram taxas e IC95',
 caption='Fonte: SINAN nacional e população DATASUS/RIPSA. Exposição: soma das populações anuais.\nEscalas próprias por painel. Sexo ignorado: 1, conservado no total e no perfil etário.')
stopifnot(sum(s$n)==1975,sum(a$n)==1976,all.equal(s$taxa_100mil,s$n/s$populacao*1e5)==TRUE)
salvar(p,'F02_perfil_sexo_idade',9)
# F04: mostra N anual acima das barras, sem transformar composição em taxa.
e <- T$grupos_etiologia_anuais
ordem <- c('Viral (MV)','Não especificada (MNE)','Outras bacterianas','Doença meningocócica',
 'Tuberculosa (MTBC)','Outra etiologia (MOE)','Vazio/não canônico')
e$grupo <- factor(e$grupo,levels=ordem)
n <- T$serie_anual
cores <- setNames(c('#487EA4','#ADB3BA','#D09358','#765989','#639B79','#CD7880','#E3E5E7'),ordem)
p <- ggplot(e,aes(factor(ano),percentual,fill=grupo)) + geom_col(width=.76) +
 geom_text(data=n,aes(factor(ano),104,label=paste0('n=',n)),inherit.aes=FALSE,size=3.7) +
 scale_fill_manual(values=cores,drop=FALSE) + scale_y_continuous(limits=c(0,109),breaks=seq(0,100,25)) +
 guides(fill=guide_legend(nrow=3,byrow=TRUE)) +
 labs(title='Composição etiológica dos registros confirmados',subtitle='Salvador, 2014–2024  |  Cada barra usa seu próprio total anual',
 x='Ano dos primeiros sintomas',y='Percentual dos registros do ano (%)',fill=NULL,
 caption='Fonte: SINAN nacional. Outras bacterianas = MB + MH + MP; meningocócica inclui MCC isolada.\nIncluídos seis códigos não canônicos e dois vazios. Uma proporção maior não demonstra maior taxa populacional.') + tema
stopifnot(sum(e$n)==1976,max(abs(aggregate(percentual~ano,e,sum)$percentual-100))<1e-10)
salvar(p,'F04_classificacao_etiologica',7.5)
# F05: mesma unidade e mesma escala vertical nos três códigos.
sih <- T$sih_serie_figura
sih$cid <- factor(sih$cid,levels=c('G00','A39','A87'))
p <- ggplot(sih,aes(ano,valor)) + geom_line(color='#24567A',linewidth=.7) +
 geom_point(color='#24567A',size=2.4) + geom_text(aes(label=valor),vjust=-.7,size=3.6) +
 facet_wrap(~cid,ncol=1,labeller=as_labeller(c(G00='G00  Meningite bacteriana',A39='A39  Infecção meningocócica',A87='A87  Meningite viral'))) +
 scale_x_continuous(breaks=2014:2024) + scale_y_continuous(limits=c(0,105),breaks=seq(0,100,25)) +
 labs(title='Internações disponíveis por diagnóstico no SIH/SUS',subtitle='Residentes de Salvador, 2014–2024  |  Mesma escala nos três painéis',
 x='Ano de processamento',y='Internações/AIHs',
 caption='Fonte: SIH/SUS, marginais oficiais. Totais: G00 = 532; A39 = 122; A87 = 489.\nAIHs/episódios, não pessoas únicas. A39 inclui outras apresentações. G01–G03 ausentes; não há total completo.') + tema
stopifnot(nrow(sih)==33,all(aggregate(valor~cid,sih,sum)$valor==c(532,122,489)))
salvar(p,'F05_internacoes_disponiveis',9)
# F06: apresenta os períodos de cada método sem criar continuidade entre eles.
v <- T$pni_figura
leg <- subset(v,metodo=='Legado: município do registro')
rnd <- subset(v,metodo=='RNDS: residência')
rnd$indicador <- factor(rnd$indicador,levels=c('Pneumocócica','Pentavalente','Meningocócica','BCG'))
rnd$ano <- factor(rnd$ano)
p1 <- ggplot(leg,aes(ano,valor)) + geom_point(size=2.8,color='#A77735') +
 geom_text(aes(label=fmt(valor,1)),vjust=-1,size=4) +
 scale_x_continuous(breaks=2014:2022) + scale_y_continuous(limits=c(0,108),breaks=seq(0,100,25)) +
 labs(title='Penta no legado de 2014–2022',subtitle='Município do registro  |  Residência não confirmada',x='Ano do indicador',y='Cobertura registrada (%)') + tema
pos <- position_dodge(width=.45)
p2 <- ggplot(rnd,aes(valor,indicador,color=ano)) +
 geom_point(position=pos,size=3.3) + geom_text(aes(label=fmt(valor,2)),position=pos,hjust=-.25,size=4,show.legend=FALSE) +
 scale_color_manual(values=c('2023'='#24567A','2024'='#368673')) +
 scale_x_continuous(limits=c(0,105),breaks=seq(0,100,25)) +
 scale_y_discrete(labels=c('Pneumocócica'='Pneumocócica conjugada','Pentavalente'='Penta (DTP/HepB/Hib)','Meningocócica'='Meningocócica conjugada','BCG'='BCG')) +
 labs(title='Indicadores RNDS em 2023 e 2024',subtitle='Residência em Salvador  |  População alvo infantil',x='Cobertura registrada (%)',y=NULL,color='Ano') + tema
p <- p1/p2 + plot_layout(heights=c(1,1.25)) +
 plot_annotation(title='Cobertura vacinal registrada por método e período',
 caption='Fontes: TabNet PNI legado e painel público RNDS por residência, snapshot validado em 09/10/2026.\n17 valores observados; 27 lacunas históricas não desenhadas como zeros. Não conectar métodos.\nBCG requer auditoria de registro. Indicadores conjugados não representam produtos exclusivos MenC ou PCV10.')
stopifnot(nrow(v)==17,nrow(leg)==9,nrow(rnd)==8,!anyNA(rnd$indicador),!anyNA(v$valor))
salvar(p,'F06_cobertura_vacinal_registrada',9)
cat('Quatro figuras revisadas; controles numéricos aprovados. Fonte não modificada.\n')
