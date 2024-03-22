
# CARREGANDO OS PACOTES ---------------------------------------------------

library(tidyverse)
library(ggsci)
library(geobr)
source("R/my-function.R")


# IMPORTANDO A BASE DE DADOS ----------------------------------------------

dados2 <- read_rds('data/emissions_sources.rds')


# VERIFICAR SE OS DADOS COINCIDEM COM OS DO CT ----------------------------

# 5 cidades verificadas (Betânia, Coqueiro Seco, Salgadinho PB e PE, Campo Grande MS)

dados2 %>%
  select(gas, emissions_quantity, sigla_uf, source_type,
         activity_units, year, sector_name, sub_sector, city_ref) %>% #, lat, lon
  filter(city_ref == 'Campo Grande',     #mudar aqui para alterar cidade
         year == 2022,
         sigla_uf == 'MS',               #mudar aqui para alterar estado
         gas == 'co2e_100yr',
         str_detect(activity_units, 'animal')) %>%
  group_by(gas, emissions_quantity, year, city_ref, sector_name, sub_sector,
           sigla_uf, source_type, activity_units) %>%
  summarise(
    media_emissao =  mean(emissions_quantity, na.rm = T),
    soma_emissao_animal =  sum(emissions_quantity, na.rm = T)

  )



# MAPEAR ------------------------------------------------------------------

# CARREGANDO OS PACOTES ---------------------------------------------------

library(tidyverse)
library(gstat)
library(skimr)
library(geobr)


# CONTRUINDO MAPA COM CLASSES ---------------------------------------------
estado <- "MS"
states %>%
  filter(
    abbrev_state == estado) %>%           #mude aqui para alterar estado
  ggplot() +
  geom_sf(fill="white", color="black",
          size=.15, show.legend = FALSE) +
  geom_point(data = dados2 %>%
               select(lat, lon, gas, emissions_quantity, sigla_uf, source_type,
                      activity_units, year, sector_name, sub_sector, city_ref) %>%
               rename(Longitude = lon,
                      Latitude = lat) %>%
               filter(year == 2022,
                      sigla_uf == 'MS',                       #comentar linha caso queira para todo o Brasil
                      str_detect(activity_units, 'animal'),
                      gas == 'co2e_100yr') %>%
               mutate(
                 classe_emissao = case_when(
                   emissions_quantity <0.1e6 ~ '< 0.1 Mton',
                   emissions_quantity <0.4e6 ~ '< 0.4 Mton',
                   emissions_quantity <0.7e6 ~ '< 0.7 Mton',
                   emissions_quantity >=1 ~ '>= 1 Mton'
                 )
               ),
             size = 1.5,
             aes(x=Longitude,y=Latitude,
                 col = classe_emissao)) +
  theme_bw() +
  theme(title = element_text(face = 'bold')) +
  labs(title = paste0('Emissão de CO2e para ',name_state),
       caption = 'Fonte dos dados: Climate Trace',
       col = "Classe de Emissão")




### Elecando as cidades

dados2 %>%
  select(lat, lon, gas, emissions_quantity, sigla_uf, source_type,
         activity_units, year, sector_name, sub_sector, city_ref) %>%
  rename(Longitude = lon,
         Latitude = lat) %>%
  filter(year == 2022,
         sigla_uf == 'MS',                       #comentar linha caso queira para todo o Brasil
         str_detect(activity_units, 'animal'),
         gas == 'co2e_100yr') %>%
  mutate(
    classe_emissao = case_when(
      emissions_quantity <0.1e6 ~ '< 0.1 Mton',
      emissions_quantity <0.4e6 ~ '< 0.4 Mton',
      emissions_quantity <0.7e6 ~ '< 0.7 Mton',
      emissions_quantity >=1 ~ '>= 1 Mton'
    )
  ) %>%
  group_by(city_ref) %>%
  summarise(
    emission = sum(emissions_quantity, na.rm=TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    city_ref = city_ref %>% fct_reorder(emission) %>%
      fct_lump(n=5, w=emission)

  ) %>%
  filter(city_ref != "Other") %>%
  ggplot(aes(x=emission, y= city_ref)) +
  geom_col(col="black")


### Obserrvando os subsetores

dados2 %>%
  select(lat, lon, gas, emissions_quantity, sigla_uf, source_type,
         activity_units, year, sector_name, sub_sector, city_ref) %>%
  rename(Longitude = lon,
         Latitude = lat) %>%
  filter(year == 2022,
         sigla_uf == 'MS',                       #comentar linha caso queira para todo o Brasil
         str_detect(activity_units, 'animal'),
         gas == 'co2e_100yr') %>%
  mutate(
    classe_emissao = case_when(
      emissions_quantity <0.1e6 ~ '< 0.1 Mton',
      emissions_quantity <0.4e6 ~ '< 0.4 Mton',
      emissions_quantity <0.7e6 ~ '< 0.7 Mton',
      emissions_quantity >=1 ~ '>= 1 Mton'
    )
  ) %>%
  group_by(city_ref,sub_sector) %>%
  summarise(
    emission = sum(emissions_quantity, na.rm=TRUE)
  ) %>%
  group_by(city_ref) %>%
  mutate(
    emission_total = sum(emission, na.rm=TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    city_ref = city_ref %>% fct_reorder(emission_total) %>%
      fct_lump(n=20, w=emission_total)

  ) %>%
    filter(city_ref != "Other") %>%
    ggplot(aes(x=emission, y= city_ref,fill=sub_sector)) +
    geom_col(col="black")


# FAZER MEDIA PARA OS ESTADOS ----------------------------------------------

dados2 %>%
  select(gas, emissions_quantity, sigla_uf,
         activity_units, year, sector_name) %>%
  filter(year == 2022,
         # sigla_uf == 'MS',                      #Filtrar, caso queira um em especifico
         str_detect(activity_units, 'animal'),
         gas == 'co2e_100yr',
  ) %>%
  group_by(sigla_uf) %>%                  #!!
  summarise(
    soma_emissao= sum(emissions_quantity)/1e6,   #Toneladas para Mega toneladas
    media_ms = mean(emissions_quantity)/1e6
  ) |>
  print(n = 28)



# BARRAS DE ERRO ----------------------------------------------------------

dados2 %>%
  select(gas, emissions_quantity, sigla_uf,
         activity_units, year, sector_name, sub_sector) %>%
  filter(year == 2022,
         sigla_uf == 'MS',
         str_detect(activity_units, 'animal'),
         gas == 'co2e_100yr',
  ) %>%
  summarise(
    soma_emissao= sum(emissions_quantity)/1e6,
    media_emissao = mean(emissions_quantity)/1e6,
    sd_emissao = sd(emissions_quantity/1e6)
  ) %>%
  rbind(dados2 %>%
          ungroup() %>%
          select(gas, emissions_quantity, sigla_uf,
                 activity_units, year, sector_name, sub_sector) %>%
          rename(
            cattle = activity_units,) %>%
          filter(year == 2022,
                 sigla_uf == 'MS',
                 str_detect(cattle, 'animal'),
                 gas == 'co2e_100yr',
          ) %>%
          summarise(
            soma_emissao= sum(emissions_quantity)/1e6,
            media_emissao = mean(emissions_quantity)/1e6,
            sd_emissao = sd(emissions_quantity/1e6)
          )
  ) %>%
  mutate(
    uf=c('Br','MS')
  ) %>%
  ggplot(aes(x=uf,y=media_emissao,
             ymax=media_emissao+sd_emissao,
             ymin=media_emissao))+              #??
  geom_col()+
  geom_errorbar()+
  theme_bw()



# SERIE TEMPORAL, 2015 A 2022 ---------------------------------------------

dados2 %>%
  select(gas, emissions_quantity, sigla_uf,
         activity_units, year, sector_name, sub_sector) %>%
  filter(str_detect(activity_units, 'animal'),
         gas == 'co2e_100yr',
  ) |>
  group_by(year) %>%
  summarise(
    soma_emissao= sum(emissions_quantity)/1e6,
    media_emissao = mean(emissions_quantity)/1e6,
    sd_emissao = sd(emissions_quantity/1e6)
  ) %>%
  rbind(dados2 %>%
          ungroup() %>%
          select(gas, emissions_quantity, sigla_uf,
                 activity_units, year, sector_name, sub_sector) %>%
          filter(sigla_uf == 'MS',
                 str_detect(activity_units, 'animal'),
                 gas == 'co2e_100yr',
          ) %>%
          group_by(year) %>%
          summarise(
            soma_emissao= sum(emissions_quantity)/1e6,
            media_emissao = mean(emissions_quantity)/1e6,
            sd_emissao = sd(emissions_quantity/1e6)
          )
  ) %>%
  mutate(
    uf=c(rep('Br',8),rep('MS',8))
  ) %>%
  ggplot(aes(x=year,y=media_emissao,
             col=uf))+
  geom_point()+
  geom_smooth(method = 'lm')+
  ggpubr::stat_cor()+
  theme_bw()


