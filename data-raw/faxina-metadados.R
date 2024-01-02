library(tidyverse)
source("R/my-function.R")

# buscando o caminho dos setores
tbl_directorys <- as_tibble(
  list.files("data-raw/BRA/",
             full.names = TRUE,
             recursive = TRUE)
) %>%
  filter(str_detect(value,"agriculture|forestry_and_land_use")) %>%
  filter(str_detect(value, "emissions-sources.csv"))

list_sector <- list.files("data-raw/BRA/",
                          full.names = TRUE,
                          pattern = "agriculture|forestry")

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

dados_sigla <- left_join(
  dados,
  base_sigla_uf %>%
    ungroup() %>%
    select(source_name, lon, lat, sigla_uf),
  by = c("source_name","lat","lon")
) %>% as_tibble()
dados_sigla$sigla_uf %>%  unique()
# write_rds(dados_sigla, "data/emissions_sources.rds")




