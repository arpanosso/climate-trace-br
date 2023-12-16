library(tidyverse)

# buscando o caminho dos setores
list_sector <- list.files("data-raw/BRA/",
           full.names = TRUE,
           pattern = "agriculture|forestry")

padroes <- c("country","confidence","sources.csv")


list_sector_source <- c(list.files(list_sector[1],
          pattern = "sources.csv",
           full.names =TRUE)[-1],
list.files(list_sector[2],
          pattern = "sources.csv",
           full.names =TRUE)[-1])

# list_sector_source <- list_sector_source[-(1:2)]

my_file_stack <- function(sector_name){
  read.csv(sector_name) %>%
        select(!starts_with("other"))
}
lvec <- str_remove(list_sector_source,".csv")
dados <- map_dfr(list_sector_source,my_file_stack,
      .id="list_sector_source") %>%
  mutate(
    list_sector_source =case_when(
      list_sector_source == "1" ~ lvec[1],
      list_sector_source == "2" ~ lvec[2],
      list_sector_source == "3" ~ lvec[3],
      list_sector_source == "4" ~ lvec[4],
      list_sector_source == "5" ~ lvec[5],
      list_sector_source == "6" ~ lvec[6],
      list_sector_source == "7" ~ lvec[7],
      list_sector_source == "8" ~ lvec[8],
      list_sector_source == "9" ~ lvec[9],
      list_sector_source == "10" ~ lvec[10],
      list_sector_source == "11" ~ lvec[11],
      list_sector_source == "12" ~ lvec[12],
      list_sector_source == "13" ~ lvec[13],
      list_sector_source == "14" ~ lvec[14],
      list_sector_source == "15" ~ lvec[15],
    )
  )
glimpse(dados)

dados <- dados %>%
  mutate(
    sector = str_split(list_sector_source,
                       "/|_",
                       simplify = TRUE)[,3],
    sub_sector = str_split(list_sector_source,
                       "/|_",
                       simplify = TRUE)[,4],
    type = str_split(list_sector_source,
                     "/|_",
                     simplify = TRUE)[,5],
  )

