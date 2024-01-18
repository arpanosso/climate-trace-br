library(tidyverse)
source("R/my-function.R")

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
    sub_sector = str_remove(sub_sector,"_emissions-sources.csv")
  )
glimpse(dados)

# agrupando a base por nome e coordenada
# Classificando o ponto em um estado
base_sigla_uf <- dados %>%
  group_by(source_name, lon, lat) %>%
  summarise(
    ano = mean(year)
  ) %>%
  mutate(
    sigla_uf = get_geobr_state(lon,lat)
  )

# Classificando pelo pol da cidade ----------------------------------------
base_sigla_uf$sigla_uf %>% unique()
citys <- geobr::read_municipality()

get_geobr_city <- function(x,y,estado,dff){
  my_citys_obj <- dff[dff$abbrev_state == estado,]
  n_citys <- nrow(my_citys_obj)
  # my_citys_names <- my_citys_obj %>% pull(name_muni)
  # resul <- "Other"
  # for(i in 1:n_citys){
  #   pol_city <- my_citys_obj$geom  %>%
  #     purrr::pluck(i) %>%
  #     as.matrix()
  #   if(def_pol(x[1], y[1], pol_city[])){
  #     resul <- my_citys_names[i]
  #   }
  # }
  return(n_citys)
};get_geobr_city(-47.2, -23.1,"SP",citys)

resul <- vector()
estado <- base_sigla_uf$sigla_uf
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
base_sigla_uf$city_ref <- resul

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
    select(source_name, lon, lat, sigla_uf, nome_regiao, city_ref),
  by = c("source_name","lat","lon")
) %>% as_tibble()
dados_sigla$nome_regiao %>%  unique()
write_rds(dados_sigla, "data/emissions_sources.rds")




