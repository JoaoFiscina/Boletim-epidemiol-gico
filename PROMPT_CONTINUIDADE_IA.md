# Prompt para entregar este projeto a outra IA

Você está continuando a coleta e preparação analítica de meningites e doença meningocócica em residentes de Salvador, Brasil. Primeiro leia `AGENTS.md`, `docs/ESTADO_COLETA.md`, `docs/PREFERENCIAS_E_METODOS.md`, o plano e relatório em `pipeline/Meningite`. Estado vigente: 09/10/2026. A pré-análise de 05/10 é histórica. Confirme arquivos/hashes antes de executar e atualize o Git local após cada etapa.

## Contexto fixo

- Município: Salvador, IBGE `292740`.
- Período principal: ano dos primeiros sintomas 2014–2024.
- SINAN é a fonte principal de casos/notificações.
- SIH é complemento de internações/AIHs e SIM é complemento de óbitos por causa básica.
- População municipal já conferida; não substituir por população da Bahia.
- O trabalho original está em `C:\Pesquisa\Boletim epidemiolóico\Meningite`.

## Resultado que não pode ser perdido

As 13 partições MENIBR14–26 foram lidas: 295.369 linhas nacionais, 2.255 residentes confirmados e 1.976 com sintomas 2014–2024. Os onze totais anuais e 572 células comparáveis concordam com TabNet de 05/10. Seis categorias adicionais ficam sem referência TabNet. A diferença de seis na etiologia foi localizada em códigos não canônicos, preservados sem adivinhar agente. Há duas notificações fora BA, zero duplicatas técnicas exatas e 144 evoluções desconhecidas; em 2024, 32/162. Isso não prova pessoas únicas.

SIH/SIM: seis consultas válidas, cinco SIH pendentes após 24 POST. SIM idade conserva 202 óbitos, mas arquivo BA não comprova cobertura nacional. SIH tem 75 óbitos hospitalares e R$ 2.354.667,12 aprovados; somar folhas CID sem subtotais-pai. PNI tem 17 observações e 27 lacunas; legado/RNDS e geografias são distintos. NT84/2026 revoga NT90/2025 e inclui 2023; NT69/2026 consolida conjugadas pneumocócicas. Não renomear atuais como MenC/PCV10 exclusivas. BCG baixo exige qualidade, não prova ausência de vacinação.

## O que fazer agora

1. Verificar o estado dos arquivos antes de baixar qualquer coisa.
2. Não repetir SINAN, seis consultas complementares válidas ou oito RNDS já validados sem motivo.
3. Usar o pacote local `dados/tratados/meningites_salvador_20261009.rds`; em clone Git seguir `pipeline/README.md`, pois brutos/RDS não são enviados.
4. Definir pergunta principal com núcleo SINAN e denominadores íntegros; os cruzamentos nacionais são reais, não marginais combinadas.
5. Retomar apenas SIH internações gerais, dias, G00 sexo e A39 sexo/idade se úteis; PNI legado tem 27 lacunas.
6. Conferir abrangência SIM e recorte clínico se mortalidade/subtipos forem eixo principal.
7. Atualizar plano, relatório, manifestos, RDS, estado, preferências/métodos e changelog; sincronizar código/agregados por lista explícita e conferir SHA antes do commit.

Os scripts SINAN têm perfil temporal fixo explícito no código; o JSON documenta o plano, não amplia automaticamente o período. Usar scripts `.R` em PowerShell para preservar aspas. Rede/timeout é falha operacional, não ausência epidemiológica. Coordenar chats por diretórios exclusivos e não deixar duas frentes escreverem a mesma base ou Git.

## Proibições

Não somar SINAN, SIH e SIM como pessoas. Não tratar ausência como zero. Não usar “PCR - viral” como prova de agente viral. Não chamar todo A39 de meningite meningocócica. Não excluir MNE. Não calcular letalidade final com evolução incompleta. Não apagar saídas anteriores. Não inventar URL ou nome de arquivo. Não instalar dependências ou fazer dezenas de consultas sem registrar motivo.

## Forma de resposta esperada

Ao finalizar uma etapa, informe em português: o que foi executado, caminhos exatos, quantidade de registros, filtros, hashes, divergências, limites e próximo passo. Separe claramente “validado”, “parcial”, “pendente” e “não demonstrado”.
