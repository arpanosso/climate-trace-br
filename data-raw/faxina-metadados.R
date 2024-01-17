library(tidyverse)
source("R/my-function.R")

# buscando o caminho dos setores
tbl_directorys <- as_tibble(
  list.files("data-raw/BRA/",
             full.names = TRUE,
             recursive = TRUE)
) %>%
  filter(str_detect(value,"agriculture|forestry_and_land_use|fossil_fuel_operations")) %>%
  filter(str_detect(value, "emissions-sources.csv"))

list_sector <- list.files("data-raw/BRA/",
                          full.names = TRUE,
                          pattern = "agriculture|forestry|fossil_fuel_operations")

my_file_stack <- function(sector_name){
  names <- read.csv(sector_name) %>%
    select(!starts_with("other")) %>%
    mutate(directory = sector_name)
}

value <- tbl_directorys %>% pull(value)
my_file_stack(value[1])
dados <- map_dfr(value, my_file_stack)
glimpse(dados)

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

base_sigla_uf <- dados %>%
  group_by(source_name, lon, lat) %>%
  summarise(
    ano = mean(year)
  ) %>%
  mutate(
    sigla_uf = get_geobr_state(lon,lat)
  )



brazil_ids <- read_rds("data/df_nome.rds")

base_sigla_uf <- left_join(base_sigla_uf,brazil_ids %>%
            group_by(sigla_uf,nome_regiao) %>%
            summarise(count=n()) %>%
            select(sigla_uf,nome_regiao),
          by = c("sigla_uf"))


dados_sigla <- left_join(
  dados,
  base_sigla_uf %>%
    ungroup() %>%
    select(source_name, lon, lat, sigla_uf, nome_regiao),
  by = c("source_name","lat","lon")
) %>% as_tibble()
dados_sigla$nome_regiao %>%  unique()
write_rds(dados_sigla, "data/emissions_sources.rds")




