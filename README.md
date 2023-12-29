
<!-- README.md is generated from README.Rmd. Please edit that file -->

# climate-trace-br

## Aquisição dos dados

![](img/img-01.png) ![](img/img-02.png) ![](img/img-03.png)

![](img/img-04.png) \## Carregando Pacotes

``` r
library(tidyverse)
library(geobr)
source("R/gafico.R")
```

## Mesclando base com ids

### Carregando as bases de dados

``` r
brazil_ids <- read_rds("data/df_nome.rds")
emissions_sources <- read_rds("data/emissions_sources.rds")
```

### Lendo o polígono dos estados

``` r
# base geobr
# states <- read_state(showProgress = FALSE)
# write_rds(states, "data/states.rds")
states <- read_rds("data/states.rds")

get_geobr_pol <- function(i) {
  states$geom %>% pluck(i) %>% as.matrix()
}

def_pol <- function(x, y, pol){
  as.logical(sp::point.in.polygon(point.x = x,
                                  point.y = y,
                                  pol.x = pol[,1],
                                  pol.y = pol[,2]))
}

abbrev_states <- states$abbrev_state

list_pol <- map(1:26,get_geobr_pol)
names(list_pol) <- abbrev_states[-27]
list_pol[[20]] %>% plot()
```

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

``` r

get_geobr_state <- function(x,y){
  for(i in 1:26){
    lgv <- def_pol(x,y,list_pol[[i]])
    if(lgv){return(names(list_pol[i]))}
  }
}
get_geobr_state(-44,-22)
#> [1] "MG"
```

``` r
# emissions_sources  %>% 
#   filter(source_name == "AC") %>% 
#   mutate(
#     sigla_uf = get_geobr_state(lon,lat)
#   )
# my_vect <- 0
# for(j in 1:nrow(emissions_sources)){
#  
#   my_vect[j] <- get_geobr_state(emissions_sources$lon[j],
#                                 emissions_sources$lat[j])
# }
```

``` r
# df_br <- brazil_ids %>% 
#   select(nome,sigla_uf,nome_uf) %>%
#   mutate(source_name = nome) %>%
#   distinct(source_name,.keep_all = TRUE) %>% 
#   relocate(source_name)
# 
# emissions_sources_brid <- left_join(emissions_sources,
#                                     df_br,
#                                     by = "source_name") %>% 
#   relocate(source_name,nome,sigla_uf,nome_uf)
```

``` r
# emissions_sources_brid %>%
#   filter(sigla_uf == "AC",
#          sector_name == "agriculture",
#          gas == "co2e_100yr",
#          year == 2022
#          ) %>%
#   group_by(original_inventory_sector) %>%
#   summarise( emission = sum(emissions_quantity,
#                             na.rm = TRUE)) %>% 
#   mutate(
#     emission_cum = cumsum(emission)
#   )
```

``` r
# states  %>% 
#   ggplot() +
#   geom_sf(fill="white", color="black",
#           size=.15, show.legend = FALSE) +
#   geom_point(
#     data = emissions_sources_brid %>%
#       filter(sigla_uf == "RJ",
#              sector_name == "agriculture",
#              gas == "co2e_100yr",
#              year == 2022),
#     aes(lon,lat)) +
#   tema_mapa()
```

``` r
# emissions_sources_brid %>%
#       filter(sigla_uf == "RJ",
#              sector_name == "agriculture",
#              gas == "co2e_100yr",
#              year == 2022) %>% 
#   arrange(lon)
```
