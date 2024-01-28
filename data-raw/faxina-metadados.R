library(tidyverse)
library(ggsci)
source("R/my-function.R")

# arquivo emissions-sources -----------------------------------------------
# buscando o caminho dos setores
tbl_directorys <- as_tibble(
  list.files("data-raw/BRA/", full.names = TRUE, recursive = TRUE)) %>%
  filter(str_detect(value, "emissions-sources.csv"))

# Extraindo os caminhos dos arquvios
value <- tbl_directorys %>% pull(value)

# Empilhando todos os arquivos no objeto dados
my_file_read(value[1])
dados <- map_dfr(value, my_file_read)
glimpse(dados)

# Tratanto as colunas de data, nome de setores e sub setores
dados <- dados %>%
  mutate(
    start_time = as_date(start_time),
    end_time = as_date(end_time),
    created_date = as_date(created_date),
    modified_date = as_date(modified_date),
    year = lubridate::year(end_time)
  ) %>%
  mutate(
    sector_name = str_split(directory,
                            "/|_",
                            simplify = TRUE)[,3],
    sub_sector = str_split(directory,
                           "/",
                           simplify = TRUE)[,4],
    sub_sector = str_remove(sub_sector,"_emissions-sources.csv|_country_emissions.csv")
  )

dados$sector_name %>% unique()
dados$sub_sector %>% unique()
dados$type_of_data %>% unique()

# agrupando a base por nome e coordenada
# Classificando o ponto em um estado

base_sigla_uf <- dados %>%
  group_by(source_name, lon, lat) %>%
  summarise(
    ano = mean(year)
  ) %>%
  mutate(
    sigla_uf = get_geobr_state(lon,lat),
    biome = get_geobr_biomes(lon,lat)
  )
base_sigla_uf %>% dplyr::glimpse()

# Classificando pelo pol da cidade ----------------------------------------
base_sigla_uf$sigla_uf %>% unique()
citys <- geobr::read_municipality()
resul <- vector()
estado <- base_sigla_uf$sigla_uf
tictoc::tic()
for(i in 1:nrow(base_sigla_uf)){
  if(estado[i]!="Other"){
    my_citys_obj <- citys %>%
      filter(abbrev_state == estado[i])
    n_citys <- nrow(my_citys_obj)
    my_citys_names <- my_citys_obj %>% pull(name_muni)
    resul[i] <- "Other"
    for(j in 1:n_citys){
      pol_city <- my_citys_obj$geom  %>%
        purrr::pluck(j) %>%
        as.matrix()
      if(def_pol(base_sigla_uf$lon[i],
                 base_sigla_uf$lat[i],
                 pol_city)){
        resul[i] <- my_citys_names[j]
      }
    }
  }
}
tictoc::toc()
base_sigla_uf$city_ref <- resul

get_geobr_city_n <- function(x, y, estado){
  my_citys_obj <- citys %>%
    tibble() %>%
    filter(abbrev_state == estado)
  n_citys <-  my_citys_obj %>% nrow()
  return(n_citys)
};get_geobr_city_n(-47.2, -23.1,"SP")

get_geobr_city <- function(arg){
  resul <- "Other"
    if(!is.na(arg)){
    arg <- as.vector(as.character(arg))
    marg <- str_split(arg," ",simplify = TRUE)
    n_citys <- marg[1,1] %>% as.numeric()
    x <- marg[1,2] %>% as.numeric()
    y <- marg[1,3] %>% as.numeric()
    estado <- marg[1,4]
    my_citys_obj <- citys %>%
      tibble() %>%
      filter(abbrev_state == estado)
    if(estado != "Other"){
      my_citys_names <- my_citys_obj %>% pull(name_muni)
      for(i in 1:n_citys){
        pol_city <- my_citys_obj$geom  %>%
          purrr::pluck(i) %>%
          as.matrix()
        if(def_pol(x, y, pol_city)){
          resul <- my_citys_names[i]
        }
      }
    }
  }
  return(resul)
};get_geobr_city(NA)

# tictoc::tic()
# base_sigla_uf <- base_sigla_uf %>%
#   group_by(sigla_uf) %>%
#   nest() %>%
#   #filter(sigla_uf != "DF") %>%
#   mutate(
#     nr = map(sigla_uf,
#              ~get_geobr_city_n(data$lon,
#                                data$lat,
#                                .x))
#   ) %>%
#   unnest(cols = c(data, nr)) %>%
#   ungroup() %>%
#   # sample_n(10) %>%
#   mutate(
#     list_par = str_c(nr, lon, lat, sigla_uf,sep=" "),
#   ) %>%
#   mutate(
#     city_ref = map(list_par,get_geobr_city)
#   ) %>%
#   unnest(cols = c(city_ref_2))
# tictoc::toc()


# Final da faxina ---------------------------------------------------------
# lendo arquivo da base nacional
brazil_ids <- read_rds("data/df_nome.rds")

# mesclando as bases
base_sigla_uf <- left_join(base_sigla_uf,brazil_ids %>%
            group_by(sigla_uf,nome_regiao) %>%
            summarise(count=n()) %>%
            select(sigla_uf,nome_regiao),
          by = c("sigla_uf"))

# Mesclando e salvando o arquivo final
dados_sigla <- left_join(
  dados,
  base_sigla_uf %>%
    ungroup() %>%
    select(source_name, lon, lat, sigla_uf, nome_regiao, biome,city_ref),
  by = c("source_name","lat","lon")
) %>% as_tibble()

dados_sigla$nome_regiao %>%  unique()

write_rds(dados_sigla, "data/emissions_sources.rds")

# country data -----------------------------------------------------------------
# buscando o caminho dos setores
tbl_directorys <- as_tibble(
  list.files("data-raw/BRA/", full.names = TRUE, recursive = TRUE)) %>%
  filter(str_detect(value, "country_emissions.csv"))

# Extraindo os caminhos dos arquvios
value <- tbl_directorys %>% pull(value)

# Empilhando todos os arquivos no objeto dados
my_file_read(value[1])
dados_country <- map_dfr(value, my_file_read) %>%
  as_tibble()
glimpse(dados_country)

dados_country <- dados_country %>%
  # filter(gas == "co2e_100yr") %>%
  mutate(
    start_time = as_date(start_time),
    end_time = as_date(end_time),
    created_date = as_date(created_date),
    modified_date = as_date(modified_date),
    year = lubridate::year(end_time)
  ) %>%
  mutate(
    sector_name = str_split(directory,
                            "/|_",
                            simplify = TRUE)[,3]
  )
write_rds(dados_country, "data/country_emissions.rds")

###########################################################
emissions_sources <- read_rds("data/emissions_sources.rds") %>%
  mutate(source_name_1 = str_to_title(source_name))
states <- read_rds("data/states.rds") %>%
  mutate(name_region = ifelse(name_region == "Centro Oeste","Centro-Oeste",name_region))

brazil_ids <- read_rds("data/df_nome.rds")
glimpse(emissions_sources)
nomes_uf <- c(brazil_ids$nome_uf %>% unique(),"Brazil")
abbrev_states <- brazil_ids$sigla_uf %>% unique()
region_names <- brazil_ids$nome_regiao %>% unique()

granular <- emissions_sources %>%
  filter(
    gas == "co2e_100yr",
    !source_name %in% nomes_uf,
    !sub_sector %in% c("forest-land-clearing",
                       "forest-land-degradation",
                       "shrubgrass-fires",
                       "forest-land-fires",
                       "wetland-fires",
                       "removals")
  ) %>%
  group_by(year, sector_name) %>%
  summarise(
    emission = sum(emissions_quantity, na.rm=TRUE)
  ) %>%
  ungroup()

dados_country <- read_rds("data/country_emissions.rds")
dados_country %>%
  filter(gas == "co2e_100yr",
         year < 2023) %>%
  # filter(!original_inventory_sector %in% c("forest-land-clearing",
  #                               "forest-land-degradation",
  #                               "shrubgrass-fires",
  #                               "forest-land-fires",
  #                               "wetland-fires",
  #                               "removals")) %>%
  group_by(year,sector_name) %>%
  filter(sector_name != "forestry") %>%
  summarize(emission = sum(emissions_quantity,
                           na.rm = TRUE)) %>%
  ggplot(aes(x=year,y=emission,
             fill=sector_name)) +
  geom_col(color="black") +
  theme_bw() +
  scale_fill_npg()

country <- dados_country %>%
  group_by(year,sector_name) %>%
  filter(sector_name != "forestry",
         gas == "co2e_100yr") %>%
  summarize(emission = sum(emissions_quantity,
                           na.rm = TRUE))

add <- rbind(granular %>%
               filter(sector_name == "forestry"), country)

add %>%
  filter(sector_name == "forestry") %>%
  group_by(year) %>%
  summarise(
    emission = sum(emission)
  ) %>%
  ggplot(aes(x=year,y=emission)) +
  geom_col(fill="darkgreen")


df1 <- add %>%
  filter(sector_name == "forestry") %>%
  group_by(year) %>%
  summarise(
    emission = sum(emission)
  )

df2 <- dados_country %>%
  # filter(!original_inventory_sector %in% c("forest-land-clearing",
  #                               "forest-land-degradation",
  #                               "shrubgrass-fires",
  #                               "forest-land-fires",
  #                               "wetland-fires",
  #                               "removals")) %>%
  group_by(year,sector_name) %>%
  filter(sector_name != "forestry",
         gas == "co2e_100yr") %>%
  summarize(emission = sum(emissions_quantity,
                           na.rm = TRUE))
df1$sector_name <- "forestry"


balanço <- rbind(df1,df2) %>%
  group_by(year) %>%
  summarise(
    emission = sum(emission)
  ) %>%
  filter(year != 2023)

altura <- rbind(df1,df2) %>%
  mutate(emission = ifelse(emission < 0, 0, emission)
  ) %>%
  filter(year != 2023) %>%
  group_by(year) %>%
  summarise(
    emission = sum(emission)
  ) %>% pull(emission)

cores <- c("#00A087FF", "#4DBBD5FF", "#E64B35FF", "#3C5488FF",
           "#F39B7FFF", "#8491B4FF",
           "#91D1C2FF", "#DC0000FF", "#7E6148FF", "#B09C85FF")
rbind(df1,df2) %>%
  filter(year != 2023) %>%
  mutate(
    sector_name = sector_name %>% as_factor()
  ) %>%
  ggplot(aes(x=year,y=emission/1e9,
             fill=sector_name)) +
  geom_col() +
  annotate("text",
          x=2015:2022,
          y=altura/1e9+.10,
          label = round(balanço$emission/1e9,2),
          size=4, fontface="bold") +
  geom_col(color="black") +
  theme_bw() +
  scale_fill_manual(values = cores) +
  labs(x="Year",
       y="Emission (G ton)",
       fill = "Sector")+
  theme(
    axis.text.x = element_text(size = rel(1.25)),
    axis.title.x = element_text(size = rel(1.5)),
    axis.text.y = element_text(size = rel(1.25)),
    axis.title.y = element_text(size = rel(1.5)),
    legend.text = element_text(size = rel(1.3)),
    legend.title = element_text(size = rel(1.3) )
  )



