#!/usr/bin/env Rscript

# load libraries and functions --------------------------------------------
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(lwgeom))
suppressPackageStartupMessages(library(stringi))
options(dplyr.summarise.inform = FALSE) # make dplyr stop blabbing about summarise

#functions
# source('functions.R')

option_list = list(
  make_option(c("-y", "--year"), type="integer", default=NULL, 
              help="year to process", metavar="character"),
  make_option(c("-c", "--cities"), type="character", default=NA, 
              help="list of cities to filter to", metavar="character"),
  make_option(c("-s", "--states"), type="character", default=NA, 
              help="list of states to filter to", metavar="character"),
  make_option(c("-b", "--buffer"), type="double", default=NA, 
              help="buffer distance in metres", metavar="character"),
  make_option(c("-e", "--epsg"), type="integer", default=NA, 
              help="The EPSG code for the map projection", metavar="character"),
  make_option(c("-f", "--filename"), type="character", default=NA, 
              help="The file name for the dataset", metavar="character")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

year     <- opt$year
cities   <- opt$cities
states   <- opt$states
buffer   <- opt$buffer
epsg     <- opt$epsg
filename <- opt$filename
# year=2021

if(is.na(year)) stop("ERROR: no year specified. Exiting now.")
if(is.na(filename)) stop("ERROR: no filename specified. Exiting now.")



cat(paste0("Running convertData.R with the following parameters:\n"))
cat(paste0("Year:     ",year    ,"\n"))
cat(paste0("Cities:   ",cities  ,"\n"))
cat(paste0("States:   ",states  ,"\n"))
cat(paste0("Buffer:   ",buffer  ,"\n"))
cat(paste0("EPSG:     ",epsg    ,"\n"))
cat(paste0("Filename: ",filename,"\n"))

# year=2021
# buffer=3600
# cities <- "Greater Melbourne, Greater Sydney, Greater Brisbane"
# states <- NA
# epsg <- NA

cities_list <- NULL
states_list <- NULL

if (!is.na(cities)) cities_list <- strsplit(cities,",|, | ,| , ")[[1]]
if (!is.na(states)) states_list <- strsplit(states,",|, | ,| , ")[[1]]


mb_input <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="mb") %>%
  dplyr::select(any_of(c("mb_code","sa1_code","sa2_code","sa3_code","sa4_code",
                         "ssc_code","lga_code","city_name","state_name")))

# if we're not transforming the crs, just use the current one
if(is.na(epsg)) epsg <- st_crs(mb_input)

mb_filtered <- NULL

if (!is.na(cities)) {
  mb_filtered <- mb_input %>%
    filter(city_name %in% cities_list) %>%
    st_drop_geometry()
}

if (!is.na(states)) {
  mb_filtered <- mb_input %>%
    filter(state_name %in% states_list) %>%
    st_drop_geometry()
}

if (!is.na(cities) & !is.na(buffer)) {
  mb_to_check <- mb_input %>%
    filter(!mb_code %in% mb_filtered$mb_code) %>%
    st_transform(7845)
  cities_buffer <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="cities") %>%
    filter(city_name %in% cities_list) %>%
    st_transform(7845) %>%
    st_buffer(buffer)
  mb_within_buffer <- mb_to_check %>%
    st_filter(cities_buffer, .predicate = st_intersects) %>%
    st_drop_geometry()
  
  mb_filtered <- bind_rows(
    mb_filtered,
    mb_within_buffer
  ) %>%
    arrange(mb_code) %>%
    unique()
}

if (!is.na(states) & !is.na(buffer)) {
  mb_to_check <- mb_input %>%
    filter(!mb_code %in% mb_filtered$mb_code) %>%
    st_transform(7845)
  states_buffer <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="state") %>%
    filter(state_name %in% states_list) %>%
    st_transform(7845) %>%
    st_buffer(buffer)
  mb_within_buffer <- mb_to_check %>%
    st_filter(states_buffer, .predicate = st_intersects) %>%
    st_drop_geometry()
  
  mb_filtered <- bind_rows(
    mb_filtered,
    mb_within_buffer
  ) %>%
    arrange(mb_code) %>%
    unique()
}

states_included <- mb_filtered %>% pull(state_name) %>% unique()
cities_included <- mb_filtered %>% filter(!is.na(city_name)) %>% pull(city_name) %>% unique()
lga_included    <- mb_filtered %>% pull(lga_code) %>% unique()
ssc_included    <- mb_filtered %>% pull(ssc_code) %>% unique()
sa4_included    <- mb_filtered %>% pull(sa4_code) %>% unique()
sa3_included    <- mb_filtered %>% pull(sa3_code) %>% unique()
sa2_included    <- mb_filtered %>% pull(sa2_code) %>% unique()
sa1_included    <- mb_filtered %>% pull(sa1_code) %>% unique()
mb_included     <- mb_filtered %>% pull(mb_code) %>% unique()

# read in datasets --------------------------------------------------------


australia <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="australia") %>%
               st_transform(epsg)
state     <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="state"    ) %>%
               filter(state_name %in% states_included) %>%
               st_transform(epsg)
cities    <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="cities"   ) %>%
               filter(city_name %in% cities_included) %>%
               st_transform(epsg)
lga       <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="lga"      ) %>%
               filter(lga_code %in% lga_included) %>%
               st_transform(epsg)
ssc       <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="ssc"      ) %>%
               filter(ssc_code %in% ssc_included) %>%
               st_transform(epsg)
sa4       <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="sa4"      ) %>%
               filter(sa4_code %in% sa4_included) %>%
               st_transform(epsg)
sa3       <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="sa3"      ) %>%
               filter(sa3_code %in% sa3_included) %>%
               st_transform(epsg)
sa2       <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="sa2"      ) %>%
               filter(sa2_code %in% sa2_included) %>%
               st_transform(epsg)
sa1       <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="sa1"      ) %>%
               filter(sa1_code %in% sa1_included) %>%
               st_transform(epsg)
mb        <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="mb"       ) %>%
               filter(mb_code %in% mb_included) %>%
               st_transform(epsg)

state_centroids  <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="state_centroids" ) %>%
                      filter(state_name %in% states_included) %>%
                      st_transform(epsg)
cities_centroids <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="cities_centroids") %>%
                      filter(city_name %in% cities_included) %>%
                      st_transform(epsg)
lga_centroids    <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="lga_centroids"   ) %>%
                      filter(lga_code %in% lga_included) %>%
                      st_transform(epsg)
ssc_centroids    <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="ssc_centroids"   ) %>%
                      filter(ssc_code %in% ssc_included) %>%
                      st_transform(epsg)
sa4_centroids    <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="sa4_centroids"   ) %>%
                      filter(sa4_code %in% sa4_included) %>%
                      st_transform(epsg)
sa3_centroids    <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="sa3_centroids"   ) %>%
                      filter(sa3_code %in% sa3_included) %>%
                      st_transform(epsg)
sa2_centroids    <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="sa2_centroids"   ) %>%
                      filter(sa2_code %in% sa2_included) %>%
                      st_transform(epsg)
sa1_centroids    <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="sa1_centroids"   ) %>%
                      filter(sa1_code %in% sa1_included) %>%
                      st_transform(epsg)
mb_centroids     <- st_read(paste0("output/boundaries_",year,".sqlite"), layer="mb_centroids"    ) %>%
                      filter(mb_code %in% mb_included) %>%
                      st_transform(epsg)



# write converted boundaries ----------------------------------------------
cat(paste0("Writing processed boundaries\n"))

st_write(australia, paste0("final/",filename,"_",year,".sqlite"), layer="australia", append=F)
st_write(state    , paste0("final/",filename,"_",year,".sqlite"), layer="state"    , append=F)
st_write(cities   , paste0("final/",filename,"_",year,".sqlite"), layer="cities"   , append=F)
st_write(lga      , paste0("final/",filename,"_",year,".sqlite"), layer="lga"      , append=F)
st_write(ssc      , paste0("final/",filename,"_",year,".sqlite"), layer="ssc"      , append=F)
st_write(sa4      , paste0("final/",filename,"_",year,".sqlite"), layer="sa4"      , append=F)
st_write(sa3      , paste0("final/",filename,"_",year,".sqlite"), layer="sa3"      , append=F)
st_write(sa2      , paste0("final/",filename,"_",year,".sqlite"), layer="sa2"      , append=F)
st_write(sa1      , paste0("final/",filename,"_",year,".sqlite"), layer="sa1"      , append=F)
st_write(mb       , paste0("final/",filename,"_",year,".sqlite"), layer="mb"       , append=F)

st_write(state_centroids , paste0("final/",filename,"_",year,".sqlite"), layer="state_centroids" , append=F)
st_write(cities_centroids, paste0("final/",filename,"_",year,".sqlite"), layer="cities_centroids", append=F)
st_write(lga_centroids   , paste0("final/",filename,"_",year,".sqlite"), layer="lga_centroids"   , append=F)
st_write(ssc_centroids   , paste0("final/",filename,"_",year,".sqlite"), layer="ssc_centroids"   , append=F)
st_write(sa4_centroids   , paste0("final/",filename,"_",year,".sqlite"), layer="sa4_centroids"   , append=F)
st_write(sa3_centroids   , paste0("final/",filename,"_",year,".sqlite"), layer="sa3_centroids"   , append=F)
st_write(sa2_centroids   , paste0("final/",filename,"_",year,".sqlite"), layer="sa2_centroids"   , append=F)
st_write(sa1_centroids   , paste0("final/",filename,"_",year,".sqlite"), layer="sa1_centroids"   , append=F)
st_write(mb_centroids    , paste0("final/",filename,"_",year,".sqlite"), layer="mb_centroids"    , append=F)


