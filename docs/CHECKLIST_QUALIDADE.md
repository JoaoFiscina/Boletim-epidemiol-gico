# Checklist de qualidade e decisão

## Antes da coleta

- [ ] O agravo e a definição de caso estão escritos.
- [ ] Município, código 292740 e perspectiva estão confirmados.
- [ ] Ano dos sintomas, ano de processamento e ano do óbito estão separados.
- [ ] O formulário real foi consultado; parâmetros não foram inventados.
- [ ] A pasta de dados brutos e o manifesto da nova versão foram criados.

## Para cada resposta TabNet

- [ ] HTML/CSV original preservado.
- [ ] URL, endpoint, parâmetros e data registrados.
- [ ] Categorias e legenda lidas antes de converter símbolos.
- [ ] Total da resposta comparado com pelo menos uma visão equivalente.
- [ ] Consulta vazia, arquivo ausente e zero eventos mantidos como estados distintos.
- [ ] Campo de total não confundido com coluna de categoria.

## Para cada DBC

- [ ] ZIP e DBC preservados.
- [ ] SHA-256 registrado.
- [ ] Número nacional de linhas e campos registrado.
- [ ] Domínios de `CLASSI_FIN`, `EVOLUCAO`, `CRITERIO`, sexo, idade e etiologia conferidos.
- [ ] Filtra-se residência 292740, sem excluir notificações de outra UF.
- [ ] Datas de sintomas e notificação avaliadas separadamente.
- [ ] Duplicatas técnicas pesquisadas; pessoa única não presumida.
- [ ] Preliminar/final e partições sobrepostas não concatenadas sem regra.

## Para população

- [ ] Código municipal confirmado.
- [ ] Mesma revisão usada em todos os anos.
- [ ] Totais de sexo e idade somam o total municipal.
- [ ] Faixas do denominador correspondem às categorias do SINAN.
- [ ] Taxa apresenta numerador, denominador e unidade.

## Para interpretação

- [ ] SINAN, SIH e SIM continuam separados.
- [ ] `MCC` isolada está explicitamente tratada.
- [ ] `MNE` não foi removida para melhorar artificialmente a especificidade.
- [ ] “PCR - viral” não foi convertido em confirmação viral sem dicionário.
- [ ] Evolução ignorada foi mantida e usada em análise de sensibilidade.
- [ ] Categoria rara não recebeu modelo anual sem volume suficiente.
- [ ] IC de Poisson não foi apresentado como correção de subnotificação.
- [ ] Nenhuma conclusão causal foi tirada de uma queda ou aumento descritivo.

## Portões de decisão

| Situação | Decisão |
|---|---|
| Total anual e denominador íntegros | pode seguir para série geral |
| Sexo/idade ≥95% e faixas compatíveis | pode seguir para perfil/taxas específicas |
| Evolução <90% em algum ano | não usar letalidade anual como resultado principal |
| Etiologia com MNE elevada | manter MNE e usar grupos amplos |
| Subtipo com poucos eventos | descrição ou agrupamento, sem modelo específico |
| Divergência entre universos sem causa | preservar tabelas separadas e investigar |
| Arquivo não coletado | pendente; nunca chamar de zero |
| Fonte SIH/SIM com códigos diferentes | complemento separado, sem soma com SINAN |
