
<!-- README.md is generated from README.Rmd. Please edit that file -->

# climate-trace-br

## Aquisição dos dados

![](img/img-01.png) ![](img/img-02.png) ![](img/img-03.png)

![](img/img-04.png) \## Carregando Pacotes

``` r
library(tidyverse)
```

## Mesclando base com ids

``` r
brazil_ids <- read_rds("data/df_nome.rds")
# emissions_sources <- read_rds("data/emissions_sources.rds")
```

``` r
# source_name <- emissions_sources %>% 
#   pull(source_name) %>% 
#   unique()
# 
# brazil_ids_name <- brazil_ids %>% 
#   pull(nome) %>% 
#   unique()
# 
# flag_name <- source_name %in% brazil_ids_name
# 
# sources_city <- emissions_sources %>% 
#   dplyr::filter(source_name %in% brazil_ids_name)

# emissions_sources <- left_join(emissions_sources,
#           brazil_ids %>% 
#   rename(source_name = nome) %>% 
#     select(source_name,sigla_uf,nome_uf,nome_regiao),
#   by = "source_name")
```

``` r
uf_nome <- brazil_ids$nome_uf %>% unique()
# emissions_sources %>% 
#   filter(!source_name %in% uf_nome,
#          !source_name == "Brazil")
```

``` r
# emissions_sources %>% 
#   filter(sigla_uf == "SP",
#          source_name == "Jaboticabal",
#          sector_name == "agriculture",
#          gas == "co2e_100yr",
#          year == 2022
#          ) %>% 
#   group_by(original_inventory_sector) %>% 
#   summarise( emission = sum(emissions_quantity,
#                             na.rm = TRUE))
```

``` r
# emissions_sources %>% 
#   filter(sigla_uf == "SP",
#          source_name == "Jaboticabal",
#          sector_name == "forestry",
#          gas == "co2e_100yr",
#          year == 2022
#          ) %>%
#   group_by(sub_sector) %>% 
#   summarise( emission = sum(emissions_quantity,
#                             na.rm = TRUE))
```

``` r
# states_id <- brazil_ids$sigla_uf %>% unique()
# emissions_sources %>% 
#   filter(
#     #source_name != "Acre",
#     #sigma_uf == "SP", # %in% states_id,
#     sector_name == "agriculture",
#     gas == "co2e_100yr",
#     year == 2022
#   ) %>% 
#   group_by(lon,lat) %>% 
#   summarise(emissions_quantity = sum(emissions_quantity,na.rm=TRUE)) %>% 
#   arrange(desc(emissions_quantity)) %>% 
#   ggplot(aes(lon,lat,size=emissions_quantity)) +
#   geom_point(color="black", fill= "blue",shape=21)
```
