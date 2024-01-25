library(tidyverse)
library(geobr)
source('r/my-function.R')


df <- read.csv('precipitation/brazil_coord.csv') |> select(lon,lat)


# download dados precipitação

for (i in 1:nrow(df)){
  repeat{
    dw <- try(
      power_data_download(df[i,1],df[i,2],
                          startdate='2020-01-01',
                          enddate = '2023-01-01')
    )
    if (!(inherits(dw,"try-error")))
      break
  }
}
