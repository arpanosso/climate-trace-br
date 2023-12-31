states <- read_rds("data/states.rds")
get_geobr_pol <- function(i) {
  states$geom %>% pluck(i) %>% as.matrix()
}
def_pol <- function(x, y, pol){
  as.logical(sp::point.in.polygon(point.x = x,
                                  point.y = y,
                                  pol.x = pol[,1],
                                  pol.y = pol[,2]))
}
abbrev_states <- states$abbrev_state
list_pol <- map(1:26,get_geobr_pol)
names(list_pol) <- abbrev_states[-27]
get_geobr_state <- function(x,y){
  x <- as.vector(x[1])
  y <- as.vector(y[1])
  resul <- "Other"
  lgv <- FALSE
  for(i in 1:26){
    lgv <- def_pol(x,y,list_pol[[i]])
    if(lgv){
      resul <- names(list_pol[i])
    }else{
      resul <- resul
    }
  }
  return(as.vector(resul))
}
get_geobr_state(-47.57989,-22.37392)
