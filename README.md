# Embargômetro: do alerta ao embargo

Observatório da resposta do poder público ao desmatamento na Amazônia Legal. Cruza no mapa os alertas de desmatamento do Inpe (Deter) com os embargos do Ibama, do ICMBio e de órgãos ambientais estaduais, e mede quanto da área desmatada recebe embargo, em quanto tempo e onde.

Site: https://maf-datascience.github.io/embargometro/

Uma iniciativa da [MAF dataScience](https://github.com/MAF-dataScience/).

## Conteúdo do repositório

- `index.qmd`, `municipios.qmd`, `metodologia.qmd`, `edicoes.qmd`: páginas do site (Quarto).
- `R/dados.R`: preparo das tabelas do site a partir das saídas do pipeline de cruzamento (fora deste repositório).
- `dados/`: tabelas agregadas publicadas (sem nome, CPF, CNPJ ou número de processo).

## Fontes

Inpe (Deter, TerraClass), Ibama (termos de embargo), ICMBio, órgãos ambientais estaduais (PA, MT, AC, AM, RO), IBGE (nomes de municípios). Detalhes na página de metodologia.

Código sob licença MIT. Os dados vêm de fontes públicas e seguem as condições de cada uma.
