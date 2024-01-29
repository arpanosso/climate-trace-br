library(tidyverse)
library(ggsci)
library(geobr)
source('r/my-function.R')


emissions_sources <- read_rds("data/emissions_sources.rds") %>%
  mutate(source_name_1 = str_to_title(source_name))
states <- read_rds("data/states.rds") %>%
  mutate(name_region = ifelse(name_region == "Centro Oeste","Centro-Oeste",name_region))

brazil_ids <- read_rds("data/df_nome.rds")
glimpse(emissions_sources)
nomes_uf <- c(brazil_ids$nome_uf %>% unique(),"Brazil")
abbrev_states <- brazil_ids$sigla_uf %>% unique()
region_names <- brazil_ids$nome_regiao %>% unique()



file_name <- list.files('precipitation/data/',full.names = T)
df <- read_rds(file_name)

df_n <- df |>
  mutate(year= year(YYYYMMDD),
         month = month(YYYYMMDD),
         longitude=LON,
         latitude=LAT) |>
  group_by(longitude, latitude, year) |>
  summarise(
    prec = sum(PRECTOTCORR),
    biomes = get_geobr_biomes(longitude,latitude)
  ) |>
  mutate(
    biomes_n =
      case_when(
        biomes=='Other'& longitude>=-45 & latitude <0~'AF',
        biomes=='Amazônia'~'AMZ',
        biomes=='Other'& longitude< -45 & latitude >=-10 ~'AMZ',
        biomes == 'Mata Atlântica' ~ 'AF',
        biomes=='Cerrado'~'CERR',
        biomes =='Pampa'~'PMP',
        biomes == 'Pantanal' ~ 'PNT',
        biomes=='Caatinga'~'CAAT',
        .default = 'Other'
      )
  )


rm(df)


emissions_sources |>
  filter(
    gas == "co2e_100yr",
    !source_name %in% nomes_uf,
    !sub_sector %in% c("forest-land-clearing",
                       "forest-land-degradation",
                       "shrubgrass-fires",
                       "forest-land-fires",
                       "wetland-fires",
                       "removals")
  ) |>
  mutate(
    biomes_n=biome
  ) |>
  select(year,biomes_n,emissions_quantity) |>
  left_join(df_n |> select(year,biomes_n,prec)) |>
  ggplot(aes(x=prec,y=emissions_quantity,col=biomes_n))+
  geom_point()

