preparar_auditoria_complementos <- function(raiz, config, destino) {
  for(lib in c('jsonlite','digest'))if(!requireNamespace(lib,quietly=TRUE))stop('Pacote existente necessario: ',lib)
  raiz<-normalizePath(raiz,winslash='/',mustWork=TRUE);dir.create(destino,recursive=TRUE,showWarnings=FALSE)
  destino<-normalizePath(destino,winslash='/',mustWork=TRUE)
  hash<-function(f){con<-file(f,'rb');on.exit(close(con));digest::digest(readBin(con,'raw',n=file.info(f)$size),algo='sha256',serialize=FALSE)}
  path<-file.path(raiz,config$fonte_rds);stopifnot(hash(path)==config$fonte_sha256)
  p<-readRDS(path);c<-p$SINAN$casos_minimos_locais;anos<-as.integer(config$anos)
  controles<-list();ck<-function(id,obs,esp,pass,bloq=TRUE,nota=''){controles[[length(controles)+1L]]<<-data.frame(controle=id,observado=paste(obs,collapse='|'),esperado=paste(esp,collapse='|'),aprovado=isTRUE(pass),bloqueante=bloq,detalhe=nota)}
  ck('hash_entrada',hash(path),config$fonte_sha256,hash(path)==config$fonte_sha256)
  ck('coorte',nrow(c),config$n_coorte,nrow(c)==config$n_coorte)
  norm<-function(x){z<-trimws(as.character(x));z[is.na(x)|z=='']<-NA_character_;z}
  num<-function(x)suppressWarnings(as.integer(norm(x)))
  dominios<-list(CS_RACA=1:5,CS_ESCOL_N=0:8,CLA_SOROGR=1:9,CLA_ME_BAC=c(9:16,18:23,26,28,45,46,49,81),CLA_ME_ASS=c(37:41,55,70,56,63,59,71:75),CLA_ME_ETI=c(42,43,44,47,48,50,52,76,77,64),LAB_CTLIQU=c(61,62,1,6,7,28,51),LAB_PCLIQU=c(62,37:41,55,72,61,75,70,56,63,59,71,73,74,1,6,7,28,43,42,48,52,51),LAB_PCSANG=c(62,37:41,55,72,61,75,70,56,63,59,71,73,74,1,6,7,28,43,42,48,52,51))
  binarios<-c('ATE_HOSPIT','LAB_PUNCAO','ANT_CONJ_C','ANT_PNEUMO','ANT_HEMO_T','ANT_BCG','ANT_AC','ANT_BC','ANT_TRIPLI','ANT_AIDS','ANT_IMUNO','MED_QUIMIO')
  for(f in binarios)dominios[[f]]<-c(1,2)
  dominios$ATE_INTERN<-NA_integer_
  mc<-c$etiologia_codigo%in%c('01','02','03')
  idade<-c$idade_anos_aproximados
  grupos<-c('toda_coorte',sort(unique(c$grupo_etiologia)))
  elig<-function(f){if(f=='CLA_SOROGR')return(mc);if(f=='CLA_ME_BAC')return(c$etiologia_codigo=='05'&!is.na(c$etiologia_codigo));if(f=='CLA_ME_ASS')return(c$etiologia_codigo=='07'&!is.na(c$etiologia_codigo));if(f=='CLA_ME_ETI')return(c$etiologia_codigo=='08'&!is.na(c$etiologia_codigo));if(f=='CS_ESCOL_N')return(!is.na(idade)&idade>=25&c$idade_interpretavel);if(f=='ATE_INTERN')return(c$ATE_HOSPIT%in%'1');if(f%in%c('LAB_CTLIQU','LAB_PCLIQU'))return(c$LAB_PUNCAO%in%'1');if(f=='MED_QUIMIO')return(c$etiologia_codigo%in%c('01','02','03','05','09'));rep(TRUE,nrow(c))}
  regra<-function(f){if(f=='CLA_SOROGR')return('MCC/MM/MM+MCC somente');if(f=='CLA_ME_BAC')return('CON_DIAGES05');if(f=='CLA_ME_ASS')return('CON_DIAGES07');if(f=='CLA_ME_ETI')return('CON_DIAGES08');if(f=='CS_ESCOL_N')return('adultos25+; idade interpretavel');if(f=='ATE_INTERN')return('ATE_HOSPIT1; data essencial');if(f%in%c('LAB_CTLIQU','LAB_PCLIQU'))return('puncao1; elegibilidade operacional liquórica');if(f=='MED_QUIMIO')return('CON_DIAGES01/02/03/05/09; comunicantes');if(f=='LAB_PCSANG')return('coorte; indicacao de exame nao disponivel, nao obrigatoriedade');'toda coorte; historia registrada entre casos'}
  estados<-list();aud<-list();dom<-list();dist<-list();parecer<-list()
  for(f in names(dominios)) {
    x<-norm(c[[f]]);v<-num(x);e<-elig(f);e[is.na(e)]<-FALSE
    estado<-rep('codigo_fora_dominio_documental',length(x));estado[is.na(x)]<-'vazio'
    if(f=='ATE_INTERN') {
      dt<-suppressWarnings(as.Date(x));estado[!is.na(dt)]<-'data_interpretavel';estado[!is.na(x)&is.na(dt)]<-'data_nao_interpretavel'
    } else {
      estado[!is.na(v)&v%in%dominios[[f]]]<-'valido_documental'
      if(f%in%binarios||f%in%c('CS_RACA','CS_ESCOL_N'))estado[v%in%9]<-'ignorado'
      if(f=='CS_ESCOL_N')estado[v%in%10]<-'nao_se_aplica'
      if(grepl('^LAB_',f)&&f!='LAB_PUNCAO') {estado[v%in%61]<-'nao_realizado';estado[v%in%62]<-'ignorado';estado[v%in%51]<-'nenhum_agente';estado[v%in%75]<-'nao_identificado'}
      if(f=='CLA_ME_BAC')estado[v%in%81]<-'bacteria_nao_especificada'
      if(f=='CLA_ME_ASS')estado[v%in%75]<-'nao_identificado'
    }
    estados[[f]]<-estado
    known<-estado%in%c('valido_documental','data_interpretavel','nao_realizado','nenhum_agente','bacteria_nao_especificada','nao_identificado')
    for(y in anos)for(g in grupos){sel<-c$ano_sintomas==y&(if(g=='toda_coorte')TRUE else c$grupo_etiologia==g);ee<-sel&e;den<-sum(ee)
      tt<-table(factor(estado[ee],levels=unique(estado)))
      z<-data.frame(campo=f,ano=y,grupo=g,estado=names(tt),n=as.integer(tt),denominador_elegivel=den,proporcao=if(den)as.integer(tt)/den else NA_real_,regra_elegibilidade=regra(f))
      aud[[length(aud)+1L]]<-z
      ck(paste0('conservacao_',f,'_',y,'_',g),sum(tt),den,sum(tt)==den)
    }
    xx<-x;if(f=='ATE_INTERN')xx<-ifelse(is.na(dt),ifelse(is.na(x),'VAZIO','DATA_NAO_INTERPRETAVEL'),paste0('ANO_DATA_',format(dt,'%Y')))
    xx[is.na(xx)]<-'VAZIO';dom[[f]]<-aggregate(rep(1L,nrow(c)),list(campo=rep(f,nrow(c)),ano=c$ano_sintomas,codigo=xx,estado=estado,elegivel=e),sum);names(dom[[f]])[6]<-'n'
    ck(paste0('dominio_coorte_',f),sum(dom[[f]]$n),nrow(c),sum(dom[[f]]$n)==nrow(c))
    dd<-table(xx[e]);dist[[f]]<-data.frame(campo=f,codigo=names(dd),n=as.integer(dd),denominador_elegivel=sum(e),proporcao=if(sum(e))as.integer(dd)/sum(e)else NA_real_,regra_elegibilidade=regra(f))
    desconhecido<-sum(e&estado%in%c('vazio','ignorado','codigo_fora_dominio_documental','data_nao_interpretavel'))
    per<-if(sum(e))100*desconhecido/sum(e)else NA_real_
    deciso<-if(is.na(per))'universo vazio; nao analisar'else if(per>30)'qualidade prioritaria; nao associacao principal'else if(per>10)'descricao e sensibilidade; perdas relevantes'else'descricao possivel apos coerencia; associacao somente condicional'
    if(f%in%c('ANT_AIDS','ANT_IMUNO'))deciso<-paste(deciso,'doenca pre-existente registrada; selecao/ausencias impedem inferencia causal',sep='; ')
    else if(grepl('^ANT_',f))deciso<-paste(deciso,'antecedente vacinal entre casos; nao eficacia/protecao',sep='; ')
    if(f%in%c('CLA_ME_ASS','CLA_ME_BAC'))deciso<-paste(deciso,'campo preenchido nao equivale agente especificado',sep='; ')
    if(grepl('^LAB_',f)&&f!='LAB_PUNCAO')deciso<-paste(deciso,'dominios de agente/exame; nao binario positivo/negativo',sep='; ')
    n_informativo<-sum(e&estado%in%c('valido_documental','data_interpretavel'))
    if(f=='CLA_ME_BAC')deciso<-'Descrever agentes registrados, mas81bacteria nao especificada domina; nao usar especificacao como prova etiologica independente; associacao restrita e condicionada a criterio/eventos'
    if(f=='CLA_ME_ASS')deciso<-'75nao identificado domina; completude aparente nao valida agente viral; descrever identificacao/qualidade, nao agente em toda MV ou associacao principal'
    if(f=='CLA_ME_ETI')deciso<-'Descricao das outras etiologias registradas; numeros pequenos e criterio exigem auditoria antes de associacoes; nao confirmar agente por campo isolado'
    if(f=='ATE_HOSPIT')deciso<-'Descricao entre casos apta com25desconhecidos; 37nao hospitalizados limitam associacao; nao vincular aAIHs e nao chamar eficacia'
    if(f=='ATE_INTERN')deciso<-'Data interpretavel em hospitalizados; descricao por ano permitida; sem data completa sintomas nao derivar intervalo clinico'
    parecer[[f]]<-data.frame(campo=f,elegibilidade=regra(f),n_elegivel=sum(e),n_desconhecido=desconhecido,percentual_desconhecido=per,n_informativo=n_informativo,n_preenchido_fora_elegibilidade=sum(!e&!is.na(x)),tipos_reais=paste(class(c[[f]]),collapse='/'),parecer=deciso,dominio_fonte='dicionario meningite v5 julho2010; notificacao2018; ficha/instrucional para escolaridade0')
  }
  auditoria<-do.call(rbind,aud);dominios_observados<-do.call(rbind,dom);distribuicoes<-do.call(rbind,dist);parecer_campos<-do.call(rbind,parecer)
  esquema_path<-file.path(raiz,'dados/tratados/sinan_br_20261009/esquema_campos.csv')
  esquema<-read.csv(esquema_path,sep=';',fileEncoding='UTF-8-BOM',stringsAsFactors=FALSE)
  grid<-expand.grid(arquivo=sprintf('MENIBR%02d.dbc',14:26),campo=names(dominios),stringsAsFactors=FALSE)
  esquema_campos<-merge(grid,esquema,by=c('arquivo','campo'),all.x=TRUE)
  esquema_campos$presente<-!is.na(esquema_campos$classe)
  ck('esquema_13particoes22campos',nrow(esquema_campos),286,nrow(esquema_campos)==286)
  ck('esquema_ATE_INTERN_date',sum(esquema_campos$campo=='ATE_INTERN'&esquema_campos$classe=='Date'),13,all(esquema_campos$classe[esquema_campos$campo=='ATE_INTERN']=='Date'))
  inc<-list();flag<-function(id,flag,universo,nota){for(y in anos)inc[[length(inc)+1L]]<<-data.frame(controle=id,ano=y,n=sum(flag&c$ano_sintomas==y,na.rm=TRUE),denominador=sum(universo&c$ano_sintomas==y,na.rm=TRUE),nota=nota)}
  dt<-suppressWarnings(as.Date(norm(c$ATE_INTERN)));cutdate<-as.Date(config$versao,'%Y%m%d')
  flag('internacao_data_sem_hospitalizacao_sim',!is.na(dt)&!c$ATE_HOSPIT%in%'1',rep(TRUE,nrow(c)),'data fora da habilitacao; nao inferir hospitalizacao')
  flag('hospitalizado_sem_data',c$ATE_HOSPIT%in%'1'&is.na(dt),c$ATE_HOSPIT%in%'1','data essencial ausente; auditoria no universo hospitalizado')
  flag('internacao_ano_anterior_sintomas',!is.na(dt)&as.integer(format(dt,'%Y'))<c$ano_sintomas,c$ATE_HOSPIT%in%'1','somente anos; data completa sintomas nao preservada na base minima')
  flag('internacao_futura',!is.na(dt)&dt>cutdate,c$ATE_HOSPIT%in%'1','corte pela versao de auditoria')
  flag('escolaridade_nao_aplica_idade_maior7',num(c$CS_ESCOL_N)%in%10&idade>7,!is.na(idade),'nao_aplica mantido distinto de desconhecido; critica documental')
  flag('sorogrupo_fora_meningococica',!is.na(norm(c$CLA_SOROGR))&!mc,rep(TRUE,nrow(c)),'dominio condicional etiologias01/02/03')
  for(f in c('CLA_ME_BAC','CLA_ME_ASS','CLA_ME_ETI','LAB_CTLIQU','LAB_PCLIQU','MED_QUIMIO'))flag(paste0(f,'_fora_elegibilidade'),!is.na(norm(c[[f]]))&!elig(f),rep(TRUE,nrow(c)),'preenchimento fora habilitacao/indicacao operacional; nao corrigido automaticamente')
  inconsistencias<-do.call(rbind,inc)
  s<-p$SIH$dados;prof<-s[s$tipo_tabela=='perfil',];tot<-s[s$tipo_tabela=='total',]
  orig<-p$populacao$original;sexo<-p$populacao$por_sexo
  mapa<-list('Menor 1 ano'='Menor 1 ano','1 a 4 anos'='1 a 4 anos','5 a 9 anos'='5 a 9 anos','10 a 14 anos'='10 a 14 anos','15 a 19 anos'='15 a 19 anos','20 a 29 anos'=c('20 a 24 anos','25 a 29 anos'),'30 a 39 anos'=c('30 a 34 anos','35 a 39 anos'),'40 a 49 anos'=c('40 a 44 anos','45 a 49 anos'),'50 a 59 anos'=c('50 a 54 anos','55 a 59 anos'),'60 a 69 anos'=c('60 a 64 anos','65 a 69 anos'),'70 a 79 anos'=c('70 a 74 anos','75 a 79 anos'),'80 anos e mais'='80 anos e mais')
  prof$denominador<-NA_real_;prof$correspondencia<-'pendente'
  for(i in seq_len(nrow(prof))) {
    y<-prof$ano[i]
    if(prof$dimensao[i]=='idade') {fa<-mapa[[prof$estrato[i]]];o<-orig[orig$ano==y&orig$faixa_etaria%in%fa,];ok<-length(fa)>0&&nrow(o)==2*length(fa);pop<-if(ok)sum(o$populacao)else NA_real_}
    else {sex<-c(Masc='M',Fem='F')[prof$estrato[i]];o<-sexo[sexo$ano==y&sexo$sexo_id%in%sex,];ok<-nrow(o)==1;pop<-if(ok)o$populacao else NA_real_}
    prof$denominador[i]<-pop;prof$correspondencia[i]<-if(ok)'faixas_e_sexo_compativeis'else'nao_compativel'
  }
  prof$taxa_100mil<-100000*prof$valor/prof$denominador
  prof$ic95_inferior<-ifelse(prof$valor==0,0,qchisq(.025,2*prof$valor)/2)/prof$denominador*100000
  prof$ic95_superior<-qchisq(.975,2*(prof$valor+1))/2/prof$denominador*100000
  prof$nota_taxa<-'AIHs/episodios administrativos por populacao residente; nao pessoas unicas; ano processamento; IC contagem nao corrige cobertura'
  ck('SIH_denominadores_perfis',sum(is.na(prof$denominador)),0,all(!is.na(prof$denominador)&prof$denominador>0))
  for(y in anos){for(cid in c('G00','A87')){z<-prof[prof$cid_grupo==cid&prof$dimensao=='idade'&prof$ano==y,];n<-p$populacao$total$populacao[p$populacao$total$ano==y];ck(paste0('pop_soma_faixas_SIH_',cid,'_',y),sum(z$denominador),n,nrow(z)==12&&sum(z$denominador)==n)};for(cid in c('A87','A39')){z<-prof[prof$cid_grupo==cid&prof$dimensao=='sexo'&prof$ano==y,];n<-p$populacao$total$populacao[p$populacao$total$ano==y];ck(paste0('pop_soma_sexos_SIH_',cid,'_',y),sum(z$denominador),n,nrow(z)==2&&sum(z$denominador)==n)}}
  for(cid in unique(prof$cid_grupo))for(dim in unique(prof$dimensao[prof$cid_grupo==cid]))for(y in anos){z<-prof[prof$cid_grupo==cid&prof$dimensao==dim&prof$ano==y,];n<-tot$valor[tot$cid_grupo==cid&tot$ano==y&tot$medida=='internacoes'];ck(paste0('SIH_perfil_',cid,'_',dim,'_',y),sum(z$valor),n,nrow(z)>0&&length(n)==1&&!anyNA(z$valor)&&sum(z$valor)==n)}
  unidades<-data.frame(medida=c('internacoes','dias_permanencia','valor_total','obitos'),universo=c('internacoes: AIHs aproximam episodios; longa permanencia/conceitos conforme notas oficiais','dias de AIHs aprovadas; nao tempo de pessoas unicas','valores administrativos aprovados de AIHs; BRL nominal','altas por obito; sem vinculacao ao SINAN'),derivacao_razao='nao_aprovada_nesta_frente',motivo='mesmo filtro CID/ano nao comprova identidade administrativa entre medidas; bases agregadas insuficientes para validar correspondencia; apresentar separadamente')
  ck('G01_obitos_ausentes',sum(is.na(tot$valor[tot$cid_grupo=='G01'&tot$medida=='obitos'])),11,all(is.na(tot$valor[tot$cid_grupo=='G01'&tot$medida=='obitos'])))
  ck('internacoes_G01_G02_G03_ausentes',sum(is.na(tot$valor[tot$cid_grupo%in%c('G01','G02','G03')&tot$medida=='internacoes'])),33,sum(is.na(tot$valor[tot$cid_grupo%in%c('G01','G02','G03')&tot$medida=='internacoes']))==33)
  tri<-list();sintgroups<-list(G00=c('MB','MH','MP'),A87='MV',A39=c('MCC','MM','MM+MCC'))
  for(cid in names(sintgroups)) {
    si<-tot[tot$cid_grupo==cid&tot$medida=='internacoes',];sn<-as.integer(table(factor(c$ano_sintomas[c$etiologia%in%sintgroups[[cid]]],levels=anos)))
    tri[[length(tri)+1L]]<-data.frame(sistema='SINAN',serie=paste(sintgroups[[cid]],collapse='+'),painel_comparacao=cid,ano=anos,n=sn,referencia_tempo='primeiros_sintomas')
    tri[[length(tri)+1L]]<-data.frame(sistema='SIH',serie=cid,painel_comparacao=cid,ano=si$ano,n=si$valor,referencia_tempo='processamento')
  }
  triangulacao<-do.call(rbind,tri);triangulacao$base_2014<-NA_real_
  for(sys in unique(triangulacao$sistema))for(ser in unique(triangulacao$serie[triangulacao$sistema==sys])){ii<-triangulacao$sistema==sys&triangulacao$serie==ser;b<-triangulacao$n[ii&triangulacao$ano==2014];stopifnot(length(b)==1&&b>0);triangulacao$base_2014[ii]<-b}
  triangulacao$indice2014_100<-100*triangulacao$n/triangulacao$base_2014;triangulacao$nota<-'pares conceituais amplos, nao equivalentes; SINAN inclui MCC; A39amplo; MVnaoigualA87; G00naoigualMB/MH/MP; indice nao fracao internada/vinculo ou causalidade'
  triangulacao$variacao_percentual_desde2014<-triangulacao$indice2014_100-100
  triangulacao$diferenca_pontos_indice_SINAN_menos_SIH<-NA_real_
  for(cid in names(sintgroups))for(y in anos){ii<-triangulacao$painel_comparacao==cid&triangulacao$ano==y;z<-triangulacao[ii,];triangulacao$diferenca_pontos_indice_SINAN_menos_SIH[ii]<-z$indice2014_100[z$sistema=='SINAN']-z$indice2014_100[z$sistema=='SIH']}
  ck('triangulacao_66_linhas',nrow(triangulacao),66,nrow(triangulacao)==66)
  ck('triangulacao_base100',triangulacao$indice2014_100[triangulacao$ano==2014],100,all(triangulacao$indice2014_100[triangulacao$ano==2014]==100))
  estado_externo<-data.frame(sistema=c('SIM','PNI','Bahia_exclui_Salvador'),status=c('202obitos registroBA; nacional nao demonstrado','17observacoes/44chaves;27ausentes; metodos separados','somente viabilidade; nenhuma extracao adicional'),limites=c('nao calcular SIM/SINAN para letalidade','dois anos RNDS; BCGqualidade; sem eficacia; conjugados nao produtos exclusivos','exige recorte nacional confirmado residenciaBA fora292740, sintomasmesmajanela, finais/prelim, deduplicacao tecnica e denominadores anuais mesmoRIPSA; BH=BA-Salvador com somas auditadas; nao reprocessado'))
  ck('PNI_17_observados',sum(!is.na(p$PNI$dados$cobertura_percentual)),17,sum(!is.na(p$PNI$dados$cobertura_percentual))==17)
  ck('PNI_grade44',nrow(p$PNI$dados),44,nrow(p$PNI$dados)==44)
  ck('SIM_total202',sum(p$SIM$dados$valor[p$SIM$dados$tipo_tabela=='total']),202,sum(p$SIM$dados$valor[p$SIM$dados$tipo_tabela=='total'])==202)
  refnames<-c('sinan_dicionario_meningite_v5.txt','sinan_dicionario_notificacao_individual_2018.txt','sinan_ficha_meningite_v5.txt','sinan_instrucional_meningite_v5.txt')
  arquivos<-c(path,file.path(raiz,'referencias',refnames),file.path(raiz,'analise/aprofundamento/configuracao.json'),file.path(destino,'preparar_auditoria_complementos.R'),esquema_path)
  fontes<-data.frame(caminho=vapply(arquivos,function(x)substring(normalizePath(x,winslash='/',mustWork=TRUE),nchar(raiz)+2L),character(1)),sha256=vapply(arquivos,hash,character(1)),bytes=file.info(arquivos)$size,uso=c('entrada_analitica',rep('dominio_documental',4),'configuracao','funcao_reproduzivel','esquema_real_13particoes'))
  escopo<-data.frame(item=c('sinais_sintomas_clinicos','datas_completas_sintomas_evolucao_encerramento','doses_datas_vacinais','ANT_IMUNO'),estado=c('nao_preservados_base_minima','datas_completas_nao_preservadas','nao_preservadas_base_minima','1976vazios_base_minima; campo fisico presente13particoes'),implicacao=c('nao auditar coerencia clinica nem inferir ausencia de sinais','indicadores de ausencia nao permitem intervalo clinico ou sobrevivencia','antecedente1nao implica esquema/cartao','esquema confirma presenca fisica, mas nao preenchimento nacional; nao concluir ausencia de imunodepressao'))
  tabela_list<-list(auditoria_campos=auditoria,dominios_observados=dominios_observados,distribuicoes_elegiveis=distribuicoes,parecer_campos=parecer_campos,inconsistencias=inconsistencias,perfis_sih=prof,medidas_sih=tot,correspondencia_universos=unidades,triangulacao_indices=triangulacao,estado_SIM_PNI=estado_externo,fontes=fontes,limites_base_minima=escopo,esquema_campos=esquema_campos)
  est<-data.frame(analise='B2_perfis_SIH',sistema='SIH',ano=prof$ano,dimensao=prof$dimensao,estrato=paste(prof$cid_grupo,prof$estrato,sep=':'),medida='taxa_AIHS_100mil',estimativa=prof$taxa_100mil,numerador=prof$valor,denominador=prof$denominador,unidade='episodios_por100mil',ic95_inferior=prof$ic95_inferior,ic95_superior=prof$ic95_superior,status=prof$status,nota=prof$nota_taxa)
  est2<-data.frame(analise='B3_triangulacao',sistema=triangulacao$sistema,ano=triangulacao$ano,dimensao='serie',estrato=triangulacao$serie,medida='indice2014_100',estimativa=triangulacao$indice2014_100,numerador=triangulacao$n,denominador=triangulacao$base_2014,unidade='indice',ic95_inferior=NA_real_,ic95_superior=NA_real_,status='descritivo',nota=triangulacao$nota)
  estimativas_longo<-rbind(est,est2)
  decisoes<-c('ATE_INTERN e data; jamais codificar como sim/nao','Escolaridade10 naoaplica distinta de ignorado9; adultos25+','Raca apenas distribuicao entre casos, sem taxa racial','Sorogrupos somente MCC/MM/MM+MCC; ausencia fora nao e falha de completude','Exames61naorealizado62ignorado51nenhumagente75naoidentificado distintos; nao binario','Antecedentes vacinais registrados nao esquema/cartao ou eficacia','Somente taxas de perfis com populacao correspondente; idade original reagrupada','Razoes administrativas nao aprovadas; medidas separadas','Triangulacao indice relativo sem equivalencia de diagnósticos/fontes ou vinculo individual','C2 requisitos apenas, sem novas bases/rede')
  validacao<-do.call(rbind,controles);stopifnot(nrow(validacao)>0,all(validacao$aprovado[validacao$bloqueante]))
  resumo<-list(coorte=nrow(c),campos=nrow(parecer_campos),n_meningococicas=sum(mc),n_adultos25=sum(!is.na(idade)&idade>=25),perfis_sih=nrow(prof),estimativas=nrow(estimativas_longo),hash_entrada=hash(path),versao=config$versao)
  result<-list(tabelas=tabela_list,estimativas_longo=estimativas_longo,validacao=validacao,decisoes=decisoes,resumo=resumo)
  for(n in names(tabela_list))write.table(tabela_list[[n]],file.path(destino,paste0(n,'.csv')),sep=';',dec='.',na='',row.names=FALSE,fileEncoding='UTF-8')
  write.table(estimativas_longo,file.path(destino,'estimativas_longo.csv'),sep=';',na='',row.names=FALSE,fileEncoding='UTF-8')
  write.table(validacao,file.path(destino,'validacao.csv'),sep=';',na='',row.names=FALSE,fileEncoding='UTF-8')
  saveRDS(result,file.path(destino,'candidato.rds'),compress='xz');stopifnot(identical(readRDS(file.path(destino,'candidato.rds')),result))
  totals_inc<-aggregate(n~controle,inconsistencias,sum)
  report<-c('# Auditoria aprofundada candidata — 12/10/2026',paste('Coorte:',nrow(c),'; campos:',nrow(parecer_campos),'; controles:',nrow(validacao),'; todos aprovados. Os controles validam conservacao e contratos; inconsistencias documentadas nao foram corrigidas.'),'','## Parecer por campo',paste(parecer_campos$campo,paste0('elegiveis=',parecer_campos$n_elegivel),paste0('desconhecidos=',round(parecer_campos$percentual_desconhecido,1),'%'),parecer_campos$parecer,sep=' — '),'','## Achados de elegibilidade e especificidade','MV:807/874 tem75nao identificado; o campo preenchido nao demonstra agente viral. MB:180/261 tem81bacteria nao especificada. Sorogrupo:47/85 registrados (B9/C32/Y2/W4);38ausentes, nao avaliar preenchimento em1976. Escolaridade25+:588/960desconhecidos, sem associacao principal. ANT_IMUNO integralmente vazio na base minima; nao equivale ausencia de imunodepressao.',paste(totals_inc$controle,paste0('n=',totals_inc$n),sep=': '),'Preenchimento de CLA_ME_ASS fora elegibilidade inclui os residuais etiologicos nao canonicos; nao corrigir esses codigos por agentes nem apagar inconsistencias.','## Limites',decisoes,'Os dominios documentais2010/2018 nao provam estabilidade anual/implementacao ETL. Presenca de campo nao comprova habilitacao por versao. As inconsistencias estao agregadas por ano; nenhuma correcao individual ou exclusao foi aplicada.','Data completa de sintomas nao esta na base minima: auditoria de internacao anterior limita-se ao ano; nao calcular tempo sintomas-internacao. Datas individuais nao foram exportadas emCSV; domínios deATE_INTERN usam ano da data.','308perfisSIH têm taxas com denominador compatível eIC95Poisson; 66indicesSINAN/SIH e diferencas de indices sao somente descritivos. Nao derivadas medias/razoes administrativas.','Sem associacoes ajustadas nesta frente; mestre decide apos qualidade/seleção/eventos. Estatísticas raciais nao estimam risco populacional.','source() verificado sem criar arquivos pelo executor; candidato relido identico. CSVs apenas agregados. Sem coletas externas, reprocessamento nacional, figuras finais ou Git.')
  writeLines(report,file.path(destino,'RELATORIO_CANDIDATO.md'),useBytes=TRUE)
  result
}
