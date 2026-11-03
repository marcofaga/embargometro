# Dados do site (03/11/2026). Lê as saídas aprovadas da v4 (scripts/07_funil_v4.R) e monta as tabelas das páginas.
# Regra: porcentagem = soma da área respondida / soma da área elegível (colunas eleg_*), como no relatório.
# Confere contra a tabela 1.2 do relatório (serie_amazonia_ib730.csv) e para se não bater.
suppressMessages({library(data.table)})
V4 <- "../scripts/saidas/v4"
para <- function(ok, msg) if (!isTRUE(ok)) stop(msg, call. = FALSE)

S <- fread(file.path(V4, "serie_mensal_municipio_v4.csv"), colClasses = list(character = "mun_geocod"))
S[, `:=`(ano = as.integer(substr(mes, 1, 4)), data = as.Date(paste0(mes, "-01")))]
F <- fread(file.path(V4, "funil_uf_ano_v4.csv"))
ULTIMO_MES <- max(S$mes)                         # último mês com alertas na base (DETER)
ANO_FECHADO <- 2023L                             # último ano com o prazo de 2 anos fechado
ANOS <- 2016:ANO_FECHADO

pct <- function(num, den) fifelse(den > 0, 100 * num / den, NA_real_)
agrega <- function(D, by) D[, .(alertas = sum(alertas), area_ha = sum(area_ha),
  ib730 = pct(sum(ha_resp_730d_ib_min), sum(eleg_ha_resp_730d_ib_min)),
  ib365 = pct(sum(ha_resp_365d_ib_min), sum(eleg_ha_resp_365d_ib_min)),
  ib182 = pct(sum(ha_resp_182d_ib_min), sum(eleg_ha_resp_182d_ib_min)),
  tod730_min = pct(sum(ha_resp_730d_todas_min), sum(eleg_ha_resp_730d_todas_min)),
  tod730_max = pct(sum(ha_resp_730d_todas_max), sum(eleg_ha_resp_730d_todas_max)),
  ja_emb30 = pct(sum(ha_ja_emb_ib_30d), sum(eleg_ha_ja_emb_ib_30d)),
  eleg730 = sum(eleg_ha_resp_730d_ib_min), eleg182 = sum(eleg_ha_resp_182d_ib_min)), by = by]

# ---- Amazônia por ano ----
AMZ <- agrega(S[grupo == "corte_raso"], "ano")[order(ano)]
REF <- fread(file.path(V4, "figuras/serie_amazonia_ib730.csv"))
cmp <- merge(AMZ[, .(ano, ib730)], REF[, .(ano, pct)], by = "ano")
para(nrow(cmp) == length(ANOS) && max(abs(cmp$ib730 - cmp$pct)) < 0.05, "site: % IBAMA 2 anos não bate com a tabela 1.2 do relatório")
AMZ[REF, on = "ano", ib730 := i.pct]           # mesmo arredondamento do relatório
MIN <- agrega(S[grupo == "mineracao"], "ano")[order(ano)]

# ---- por UF (do funil, que já aplica a cobertura de cada fonte) ----
UF <- F[grupo == "corte_raso" & ano %in% ANOS, .(uf, ano, area_mil_ha, base_pequena, ib = resp730_ib,
         tod_min = fifelse(is.na(resp730_todascomp_min), resp730_todas_min, resp730_todascomp_min),
         tod_max = fifelse(is.na(resp730_todascomp_max), resp730_todas_max, resp730_todascomp_max))]

# ---- série mensal curta (Amazônia): área de alertas e % embargada em 6 e 12 meses, só meses com o prazo fechado ----
MES <- S[grupo == "corte_raso", .(area_ha = sum(area_ha),
  ib182 = if (all(mes_completo_ha_resp_182d_ib_min)) pct(sum(ha_resp_182d_ib_min), sum(eleg_ha_resp_182d_ib_min)) else NA_real_,
  ib365 = if (all(mes_completo_ha_resp_365d_ib_min)) pct(sum(ha_resp_365d_ib_min), sum(eleg_ha_resp_365d_ib_min)) else NA_real_),
  by = .(mes, data)][order(data)]
MES_6M <- MES[!is.na(ib182)][.N]                 # mês mais recente com 6 meses de prazo fechados

# ---- municípios ----
MUN <- agrega(S[grupo == "corte_raso" & ano %in% 2019:ANO_FECHADO], c("uf", "mun_geocod", "municipality"))
REC <- S[grupo == "corte_raso" & data > seq(as.Date(paste0(ULTIMO_MES, "-01")), by = "-12 months", length.out = 2)[2],
         .(area_12m = sum(area_ha)), by = mun_geocod]
MUN <- merge(MUN, REC, by = "mun_geocod", all.x = TRUE)[is.na(area_12m), area_12m := 0]
MUN[, base_pequena := area_ha < 1000]
NOMES <- fread("dados/municipios_ibge.csv", colClasses = list(character = "mun_geocod"))
MUN <- merge(MUN, NOMES[, .(mun_geocod, municipio)], by = "mun_geocod", all.x = TRUE)
para(!anyNA(MUN$municipio), "site: município sem nome no IBGE")
setorder(MUN, -area_ha)

# ---- formatação ----
br <- function(x, d = 1) formatC(x, format = "f", digits = d, big.mark = ".", decimal.mark = ",")
mes_pt <- function(d) paste(c("janeiro","fevereiro","março","abril","maio","junho","julho","agosto","setembro","outubro","novembro","dezembro")[as.integer(format(d, "%m"))], format(d, "%Y"))
