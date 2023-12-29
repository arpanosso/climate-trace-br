
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

``` r
df_br <- brazil_ids %>% 
  select(nome,sigla_uf,nome_uf) %>%
  mutate(source_name = nome) %>%
  distinct(source_name,.keep_all = TRUE) %>% 
  relocate(source_name)

emissions_sources_brid <- left_join(emissions_sources,
                                    df_br,
                                    by = "source_name") %>% 
  relocate(source_name,nome,sigla_uf,nome_uf)
```

``` r
emissions_sources_brid %>%
  filter(sigla_uf == "AC",
         sector_name == "agriculture",
         gas == "co2e_100yr",
         year == 2022
         ) %>%
  group_by(original_inventory_sector) %>%
  summarise( emission = sum(emissions_quantity,
                            na.rm = TRUE)) %>% 
  mutate(
    emission_cum = cumsum(emission)
  )
#> # A tibble: 5 × 3
#>   original_inventory_sector           emission emission_cum
#>   <chr>                                  <dbl>        <dbl>
#> 1 cropland-fires                       373653.      373653.
#> 2 enteric-fermentation-cattle-pasture  922418.     1296071.
#> 3 manure-left-on-pasture-cattle        265498.     1561569.
#> 4 rice-cultivation                      10938.     1572507.
#> 5 synthetic-fertilizer-application     180908.     1753415.
```

``` r
states <- read_state(showProgress = FALSE)
states  %>% 
  ggplot() +
  geom_sf(fill="white", color="black",
          size=.15, show.legend = FALSE) +
  geom_point(
    data = emissions_sources_brid %>%
      filter(sigla_uf == "RJ",
             sector_name == "agriculture",
             gas == "co2e_100yr",
             year == 2022),
    aes(lon,lat)) +
  tema_mapa()
```

![](README_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

``` r
# emissions_sources_brid %>%
#       filter(sigla_uf == "RJ",
#              sector_name == "agriculture",
#              gas == "co2e_100yr",
#              year == 2022) %>% 
#   arrange(lon)
```
