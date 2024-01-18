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

get_geobr_city <- function(x,y,state){
  my_state <- as.vector(state[1])
  x <- as.vector(x[1])
  y <- as.vector(y[1])
  my_citys_obj <- citys %>%
    filter(abbrev_state == my_state)
  n_citys <- nrow(my_citys_obj)
  my_citys_names <- my_citys_obj %>% pull(name_muni)
  resul <- "Other"
  lgv <- FALSE
  for(i in 1:n_citys){
    pol_city <- my_citys_obj$geom %>%
      purrr::pluck(i)  %>%
      as.matrix()
    lgv <-def_pol(x, y, pol_city)
    if(lgv){
      resul <- my_citys_names[i]
    }
  }
  return(as.vector(resul))
};get_geobr_city(-54.3, -24.6,"PR")

base_sigla_uf %>%
  ungroup() %>%
  sample_n(10) %>%
  mutate(
    city_ref = get_geobr_city(lon,lat,sigla_uf)
  )

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
    select(source_name, lon, lat, sigla_uf, nome_regiao),
  by = c("source_name","lat","lon")
) %>% as_tibble()
dados_sigla$nome_regiao %>%  unique()
write_rds(dados_sigla, "data/emissions_sources.rds")




