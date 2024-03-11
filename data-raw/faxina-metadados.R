library(tidyverse)
library(ggsci)
source("R/my-function.R")


# download do arquivo zip - climate trace ---------------------------------
# my_url <- "https://downloads.climatetrace.org/v02/country_packages/BRA.zip"
# temp_file_path <- tempfile(fileext = ".zip")
# download.file(my_url, destfile = "data-raw/BRA.zip", mode = "wb")
# unzip("data-raw/BRA.zip", exdir = "data-raw/BRA")

# arquivo emissions-sources -----------------------------------------------
# buscando o caminho dos setores
tbl_directorys <- as_tibble(
  list.files("data-raw/BRA/", full.names = TRUE, recursive = TRUE)) %>%
  filter(str_detect(value, "emissions-sources.csv"))

# Extraindo os caminhos dos arquvios
value <- tbl_directorys %>% pull(value)

# Mapeando Transportation -------------------------------------------------
trans_values <- tbl_directorys %>%
  filter(str_detect(value,"transportation")) %>%
  pull(value)

row_count <- function(sector_name){
  read.csv(sector_name) %>%
    nrow()
}

# row_count(value[1])
# map_dbl(value, row_count) %>% sum

# Atualizando o banco todo ------------------------------------------------
# Empilhando todos os arquivos no objeto dados
# my_file_read(value[1])
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
                            "/",
                            simplify = TRUE)[,3],
    sub_sector = str_split(directory,
                           "/",
                           simplify = TRUE)[,4],
    sub_sector = str_remove(sub_sector,"_emissions-sources.csv|_country_emissions.csv")
  )

# dados$sector_name %>% unique()
# dados$sub_sector %>% unique()
# dados$type_of_data %>% unique()
# dados$year %>% table()



# agrupando a base por nome e coordenada
# Classificando o ponto em um estado
base_sigla_uf <- dados %>%
  group_by(source_name, lon, lat) %>%
  summarise(
    ano = mean(year)
  ) %>%
  mutate(
    sigla_uf = get_geobr_state(lon,lat),
    biome = get_geobr_biomes(lon,lat),
    flag_conservation = get_geobr_conservation(lon,lat),
    flag_indigenous = get_geobr_indigenous(lon,lat)
  )

### testando flag_indigenous
base_sigla_uf |>
  filter(flag_indigenous) %>%
  ggplot(aes(x=lon,y=lat))+
  geom_point()

indigenous   %>%
  ggplot() +
  geom_sf(fill="white", color="black",
          size=.15, show.legend = FALSE) +
  geom_point(
    data = base_sigla_uf %>%
      filter(flag_indigenous),
    aes(lon,lat))


### testando flag_conservation
base_sigla_uf |>
  filter(flag_conservation) %>%
  ggplot(aes(x=lon,y=lat))+
  geom_point()

conservation   %>%
  ggplot() +
  geom_sf(fill="white", color="black",
          size=.15, show.legend = FALSE) +
  geom_point(
    data = base_sigla_uf %>%
      filter(flag_conservation),
    aes(lon,lat))

### testando classificação por bioma
base_sigla_uf |>
  ggplot(aes(x=lon,y=lat,col=biome))+
  geom_point()
base_sigla_uf$biome %>% unique() == "Amazônia"

base_sigla_uf %>%
  mutate(
    biome_n = biome == "Amazônia"
  ) %>% glimpse()

### Arrumando classificação
base_sigla_uf |>
  mutate(
    biome_n = case_when(
        biome=='Other'& lon>= -45 & lat < -6~'AF',
        biome == "Amazônia" ~ "AMZ",
        biome=='Other'& lon< -45 & lat >=-10 ~'AMZ',
        biome == 'Mata Atlântica' & lon> -40 & lat < -20 ~'Other',
        biome == 'Mata Atlântica' & lon> -34 & lat > -5 ~'Other',
        biome == 'Mata Atlântica' ~ 'AF',
        biome=='Cerrado'~'CERR',
        biome =='Pampa'~'PMP',
        biome == 'Pantanal' ~ 'PNT',
        biome=='Caatinga'~'CAAT',
        TRUE ~ 'Other'
      )
  ) |>
  ggplot(aes(x=lon,y=lat,color=biome_n))+
  geom_point()

base_sigla_uf <- base_sigla_uf |>
  mutate(
    biomes =
      case_when(
        biome=='Other'& lon>=-45 & lat <0~'AF',
        biome=='Amazônia'~'AMZ',
        biome=='Other'& lon< -45 & lat >=-10 ~'AMZ',
        biome == 'Mata Atlântica' & lon> -40 & lat < -20 ~'Other',
        biome == 'Mata Atlântica' & lon> -34 & lat > -5 ~'Other',
        biome == 'Mata Atlântica' ~ 'AF',
        biome=='Cerrado'~'CERR',
        biome =='Pampa'~'PMP',
        biome == 'Pantanal' ~ 'PNT',
        biome=='Caatinga'~'CAAT',
        .default = 'Other'
      )
    )

base_sigla_uf |>
  ggplot(aes(x=lon,y=lat,col=biomes))+
  geom_point()

###
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
    select(source_name, lon, lat, sigla_uf, nome_regiao, biomes,
           flag_indigenous, flag_conservation, city_ref),
  by = c("source_name","lat","lon")
) %>% as_tibble()

dados_sigla$nome_regiao %>%  unique()

 write_rds(dados_sigla %>%
             rename(biome = biomes), "data/emissions_sources.rds")

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
                            "/",
                            simplify = TRUE)[,3],
    sector_name = str_remove(sector_name,"_country_emissions.csv")
  )

dados_country$directory[1]

dados_country %>%
  select( sector_name ) %>%
  distinct()
write_rds(dados_country, "data/country_emissions.rds")
