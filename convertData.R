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
source('functions.R')

# extract the database name that was passed in from the command line
option_list = list(
  make_option(c("-y", "--year"), type="numeric", default=NULL, 
              help="year to process", metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

year<-opt$year
# year=2021

cat(paste0("Running convertData.R for ",year,"\n"))


# Load datasets -----------------------------------------------------------
cat(paste0("Loading datasets\n"))

australia_input <- NULL
state_input     <- NULL
gccsa_input     <- NULL
sua_input       <- NULL
sos_input       <- NULL
lga_input       <- NULL
ssc_input       <- NULL
sa4_input       <- NULL
sa3_input       <- NULL
sa2_input       <- NULL
sa1_input       <- NULL
mb_input        <- NULL
mb_count_input  <- NULL

if(year==2016) {
  australia_input <- st_read("data/asgs_vol_1_2016.gpkg", layer="AUS_2016_AUST") %>%
    dplyr::select(aus_code=AUS_CODE_2016, aus_name=AUS_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM) %>%
    mutate(aus_code="AUS")
  
  state_input <- st_read("data/asgs_vol_1_2016.gpkg", layer="STE_2016_AUST") %>%
    dplyr::select(state_code=STATE_CODE_2016, state_name=STATE_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  gccsa_input <- st_read("data/asgs_vol_1_2016.gpkg", layer="GCCSA_2016_AUST") %>%
    dplyr::select(city_code=GCCSA_CODE_2016, city_name=GCCSA_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sua_input <- st_read("data/asgs_vol_4_2016.gpkg", layer="SUA_2016_AUST") %>%
    dplyr::select(city_code=SUA_CODE_2016, city_name=SUA_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sos_input <- st_read("data/asgs_vol_4_2016.gpkg", layer="SOS_2016_AUST") %>%
    dplyr::select(sos_category=SOS_NAME_2016)
  
  lga_input <- st_read("data/asgs_vol_3_2016.gpkg", layer="LGA_2016_AUST") %>%
    dplyr::select(lga_code=LGA_CODE_2016, lga_name=LGA_NAME_2016,
                  state_code=STATE_CODE_2016, state_name=STATE_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  ssc_input <- st_read("data/asgs_vol_3_2016.gpkg", layer="SSC_2016_AUST") %>%
    dplyr::select(ssc_code=SSC_CODE_2016, ssc_name=SSC_NAME_2016,
                  state_code=STATE_CODE_2016, state_name=STATE_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sa4_input <- st_read("data/asgs_vol_1_2016.gpkg", layer="SA4_2016_AUST") %>%
    dplyr::select(sa4_code=SA4_CODE_2016,
                  state_code=STATE_CODE_2016, state_name=STATE_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sa3_input <- st_read("data/asgs_vol_1_2016.gpkg", layer="SA3_2016_AUST") %>%
    dplyr::select(sa3_code=SA3_CODE_2016, sa4_code=SA4_CODE_2016,
                  state_code=STATE_CODE_2016, state_name=STATE_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sa2_input <- st_read("data/asgs_vol_1_2016.gpkg", layer="SA2_2016_AUST") %>%
    dplyr::select(sa2_code=SA2_MAINCODE_2016,
                  sa3_code=SA3_CODE_2016, sa4_code=SA4_CODE_2016,
                  state_code=STATE_CODE_2016, state_name=STATE_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sa1_input <- st_read("data/asgs_vol_1_2016.gpkg", layer="SA1_2016_AUST") %>%
    dplyr::select(sa1_code=SA1_MAINCODE_2016, sa2_code=SA2_MAINCODE_2016,
                  sa3_code=SA3_CODE_2016, sa4_code=SA4_CODE_2016,
                  state_code=STATE_CODE_2016, state_name=STATE_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  mb_input <- st_read("data/asgs_vol_1_2016.gpkg", layer="MB_2016_AUST") %>%
    dplyr::select(mb_code=MB_CODE_2016, mb_category=MB_CATEGORY_NAME_2016,
                  sa1_code=SA1_MAINCODE_2016, sa2_code=SA2_MAINCODE_2016,
                  sa3_code=SA3_CODE_2016, sa4_code=SA4_CODE_2016,
                  state_code=STATE_CODE_2016, state_name=STATE_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM) 
  
  mb_count_input <- read.csv("data/mb_count_2016.csv") %>%
    dplyr::select(mb_code=MB_CODE_2016, dwelling=Dwelling, person=Person)
}

if(year==2021) {
  australia_input <- st_read("data/asgs_vol_1_2021.gpkg", layer="AUS_2021_AUST_GDA2020") %>%
    dplyr::select(aus_code=AUS_CODE_2021, aus_name=AUS_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  state_input <- st_read("data/asgs_vol_1_2021.gpkg", layer="STE_2021_AUST_GDA2020") %>%
    dplyr::select(state_code=STATE_CODE_2021, state_name=STATE_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  gccsa_input <- st_read("data/asgs_vol_1_2021.gpkg", layer="GCCSA_2021_AUST_GDA2020") %>%
    dplyr::select(city_code=GCCSA_CODE_2021, city_name=GCCSA_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sua_input <- st_read("data/asgs_vol_4_2021.gpkg", layer="SUA_2021_AUST_GDA2020") %>%
    dplyr::select(city_code=SUA_CODE_2021, city_name=SUA_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sos_input <- st_read("data/asgs_vol_4_2021.gpkg", layer="SOS_2021_AUST_GDA2020") %>%
    dplyr::select(sos_category=SOS_NAME_2021)
  
  lga_input <- st_read("data/asgs_vol_3_2021.gpkg", layer="LGA_2021_AUST_GDA2020") %>%
    dplyr::select(lga_code=LGA_CODE_2021, lga_name=LGA_NAME_2021,
                  state_code=STATE_CODE_2021, state_name=STATE_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  ssc_input <- st_read("data/asgs_vol_3_2021.gpkg", layer="SAL_2021_AUST_GDA2020") %>%
    dplyr::select(ssc_code=SAL_CODE_2021, ssc_name=SAL_NAME_2021,
                  state_code=STATE_CODE_2021, state_name=STATE_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sa4_input <- st_read("data/asgs_vol_1_2021.gpkg", layer="SA4_2021_AUST_GDA2020") %>%
    dplyr::select(sa4_code=SA4_CODE_2021,
                  state_code=STATE_CODE_2021, state_name=STATE_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sa3_input <- st_read("data/asgs_vol_1_2021.gpkg", layer="SA3_2021_AUST_GDA2020") %>%
    dplyr::select(sa3_code=SA3_CODE_2021, sa4_code=SA4_CODE_2021,
                  state_code=STATE_CODE_2021, state_name=STATE_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sa2_input <- st_read("data/asgs_vol_1_2021.gpkg", layer="SA2_2021_AUST_GDA2020") %>%
    dplyr::select(sa2_code=SA2_CODE_2021,
                  sa3_code=SA3_CODE_2021, sa4_code=SA4_CODE_2021,
                  state_code=STATE_CODE_2021, state_name=STATE_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  sa1_input <- st_read("data/asgs_vol_1_2021.gpkg", layer="SA1_2021_AUST_GDA2020") %>%
    dplyr::select(sa1_code=SA1_CODE_2021, sa2_code=SA2_CODE_2021,
                  sa3_code=SA3_CODE_2021, sa4_code=SA4_CODE_2021,
                  state_code=STATE_CODE_2021, state_name=STATE_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM)
  
  mb_input <- st_read("data/asgs_vol_1_2021.gpkg", layer="MB_2021_AUST_GDA2020") %>%
    dplyr::select(mb_code=MB_CODE_2021, mb_category=MB_CATEGORY_2021,
                  sa1_code=SA1_CODE_2021, sa2_code=SA2_CODE_2021,
                  sa3_code=SA3_CODE_2021, sa4_code=SA4_CODE_2021,
                  state_code=STATE_CODE_2021, state_name=STATE_NAME_2021,
                  area_albers_sqkm=AREA_ALBERS_SQKM) 
  
  mb_count_input <- read.csv("data/mb_count_2021.csv") %>%
    dplyr::select(mb_code=MB_CODE_2021, dwelling=Dwelling, person=Person)
}

# create cities dataset ---------------------------------------------------
cat(paste0("Creating the cities dataset\n"))

gccsa <- gccsa_input %>%
  cleanDatatypes() %>%
  filter(city_name %in% c(
    "Greater Sydney", "Greater Melbourne", "Greater Brisbane", "Greater Adelaide", 
    "Greater Perth", "Greater Hobart", "Greater Darwin", "Australian Capital Territory")) %>%
  st_make_valid()

sua <- sua_input %>%
  cleanDatatypes() %>%
  filter(!grepl("Not in any Significant*", city_name)) %>%
  st_make_valid()

sua_to_exclude <- sua %>%
  st_centroid() %>%
  st_filter(gccsa, .predicate=st_intersects) %>%
  pull(city_name)

sua_filtered <- sua %>%
  filter(!city_name %in% sua_to_exclude)

cities <- bind_rows(gccsa, sua_filtered) %>%
  arrange(city_name) %>%
  st_sf()



# section of state and state suburbs --------------------------------------

sos <- sos_input %>%
  cleanDatatypes()

ssc <- ssc_input %>%
  cleanDatatypes() %>%
  dplyr::select(ssc_code, ssc_name)
  
lga <- lga_input %>%
  cleanDatatypes() %>%
  dplyr::select(lga_code, lga_name)



# meshblock ---------------------------------------------------------------
cat(paste0("Processing meshblocks\n"))

mb <- mb_input %>%
  cleanDatatypes()

mb_centroids_initial <- mb %>%
  dplyr::select(mb_code) %>%
  st_centroid()

distance_to_mb <- st_distance(mb_centroids_initial, mb, by_element=T) %>%
  as.numeric()

mb_distance <- mb %>%
  dplyr::select(mb_code) %>%
  mutate(centroid_distance=distance_to_mb)


mb_centroids_outside <- mb_distance %>%
  filter(centroid_distance>0) %>%
  dplyr::select(mb_code) %>%
  st_point_on_surface()

mb_centroids <- bind_rows(
  mb_centroids_initial %>% filter(!mb_code%in%mb_centroids_outside$mb_code),
  mb_centroids_outside
) %>%
  st_sf() %>%
  arrange(mb_code)

mb_sos    <- st_join(mb_centroids, sos, join=st_intersects)
mb_cities <- st_join(mb_sos      , cities%>%dplyr::select(city_code,city_name), join=st_intersects)
mb_ssc    <- st_join(mb_cities   , ssc, join=st_intersects)
mb_lga    <- st_join(mb_ssc      , lga, join=st_intersects)


mb_count <- mb_count_input %>%
  mutate(across(everything() , ~ stri_trans_general(.x, "Latin-ASCII") )) %>%
  mutate(across(any_of(c("mb_code", "dwelling", "person")), ~ as.double(.x))) %>%
  filter(!is.na(mb_code))

mb_combined <- left_join(mb, mb_count, by="mb_code") %>%
  left_join(mb_lga%>%st_drop_geometry(), by="mb_code") %>%
  dplyr::select(mb_code, mb_category, sa1_code, sa2_code, sa3_code, sa4_code,
                ssc_code, ssc_name, lga_code, lga_name, city_code, city_name,
                state_code, state_name, sos_category, dwelling, person,
                area_albers_sqkm) %>%
  arrange(mb_code)

mb_no_geom <- mb_combined %>%
  st_drop_geometry()

mb_centroids_final <- left_join(mb_centroids, mb_no_geom, by="mb_code")
  


# Finalising cities -------------------------------------------------------
cat(paste0("Finalising cities\n"))

cities_combined <- cities %>%
  cleanDatatypes() %>%
  left_join(findTopTwo(aggregate_by="city_code",boundary_type="state"), by="city_code") %>%
  left_join(findPopulation(aggregate_by="city_code")                  , by="city_code") %>%
  dplyr::select(city_code, city_name,
                state_code_1, state_name_1, state_code_2, state_name_2,
                dwelling, person, area_albers_sqkm) %>%
  arrange(city_code)



# sa1 ---------------------------------------------------------------------
cat(paste0("Processing sa1\n"))

sos_ranking <- tribble(
  ~sos_category     , ~sos_rank,
  "Major Urban"     , 1        ,
  "Other Urban"     , 2        ,
  "Bounded Locality", 3        ,
  "Rural Balance"   , 4        ,
  NA                , 5
)

# just one section of state per sa1
sa1_sos <- mb_no_geom %>%
  dplyr::select(sa1_code,sos_category) %>%
  distinct() %>%
  left_join(sos_ranking, by="sos_category") %>%
  group_by(sa1_code) %>%
  slice_min(sos_rank) %>%
  ungroup() %>%
  dplyr::select(sa1_code,sos_category)


sa1_combined <- sa1_input %>%
  cleanDatatypes() %>%
  left_join(sa1_sos                                                , by="sa1_code") %>%
  left_join(findCity(aggregate_by="sa1_code")                      , by="sa1_code") %>%
  left_join(findTopTwo(aggregate_by="sa1_code",boundary_type="ssc"), by="sa1_code") %>%
  left_join(findTopTwo(aggregate_by="sa1_code",boundary_type="lga"), by="sa1_code") %>%
  left_join(findPopulation(aggregate_by="sa1_code")                , by="sa1_code") %>%
  dplyr::select(sa1_code, sa2_code, sa3_code, sa4_code,
                ssc_code_1, ssc_name_1, ssc_code_2, ssc_name_2, 
                lga_code_1, lga_name_1, lga_code_2, lga_name_2, 
                city_code, city_name, state_code, state_name, sos_category,
                dwelling, person, area_albers_sqkm) %>%
  arrange(sa1_code)



# sa2 ---------------------------------------------------------------------
cat(paste0("Processing sa2\n"))

sa2_combined <- sa2_input %>%
  cleanDatatypes() %>%
  left_join(findCity(aggregate_by="sa2_code")                      , by="sa2_code") %>%
  left_join(findTopTwo(aggregate_by="sa2_code",boundary_type="ssc"), by="sa2_code") %>%
  left_join(findTopTwo(aggregate_by="sa2_code",boundary_type="lga"), by="sa2_code") %>%
  left_join(findPopulation(aggregate_by="sa2_code")                , by="sa2_code") %>%
  dplyr::select(sa2_code, sa3_code, sa4_code,
                ssc_code_1, ssc_name_1, ssc_code_2, ssc_name_2, 
                lga_code_1, lga_name_1, lga_code_2, lga_name_2, 
                city_code, city_name, state_code, state_name,
                dwelling, person, area_albers_sqkm) %>%
  arrange(sa2_code)



# sa3 ---------------------------------------------------------------------
cat(paste0("Processing sa3\n"))

sa3_combined <- sa3_input %>%
  cleanDatatypes() %>%
  left_join(findCity(aggregate_by="sa3_code")                      , by="sa3_code") %>%
  left_join(findTopTwo(aggregate_by="sa3_code",boundary_type="ssc"), by="sa3_code") %>%
  left_join(findTopTwo(aggregate_by="sa3_code",boundary_type="lga"), by="sa3_code") %>%
  left_join(findPopulation(aggregate_by="sa3_code")                , by="sa3_code") %>%
  dplyr::select(sa3_code, sa4_code,
                ssc_code_1, ssc_name_1, ssc_code_2, ssc_name_2, 
                lga_code_1, lga_name_1, lga_code_2, lga_name_2, 
                city_code, city_name, state_code, state_name,
                dwelling, person, area_albers_sqkm) %>%
  arrange(sa3_code)



# sa4 ---------------------------------------------------------------------
cat(paste0("Processing sa4\n"))

sa4_combined <- sa4_input %>%
  cleanDatatypes() %>%
  left_join(findCity(aggregate_by="sa4_code")                      , by="sa4_code") %>%
  left_join(findTopTwo(aggregate_by="sa4_code",boundary_type="ssc"), by="sa4_code") %>%
  left_join(findTopTwo(aggregate_by="sa4_code",boundary_type="lga"), by="sa4_code") %>%
  left_join(findPopulation(aggregate_by="sa4_code")                , by="sa4_code") %>%
  dplyr::select(sa4_code,
                ssc_code_1, ssc_name_1, ssc_code_2, ssc_name_2, 
                lga_code_1, lga_name_1, lga_code_2, lga_name_2, 
                city_code, city_name, state_code, state_name,
                dwelling, person, area_albers_sqkm) %>%
  arrange(sa4_code)



# ssc ---------------------------------------------------------------------
cat(paste0("Processing ssc\n"))

ssc_combined <- ssc_input %>%
  cleanDatatypes() %>%
  left_join(findTopTwo(aggregate_by="ssc_code",boundary_type="city"), by="ssc_code") %>%
  left_join(findTopTwo(aggregate_by="ssc_code",boundary_type="lga") , by="ssc_code") %>%
  left_join(findPopulation(aggregate_by="ssc_code")                 , by="ssc_code") %>%
  dplyr::select(ssc_code, ssc_name,
                lga_code_1, lga_name_1, lga_code_2, lga_name_2, 
                city_code_1, city_name_1, city_code_2, city_name_2,
                state_code, state_name, dwelling, person, area_albers_sqkm) %>%
  arrange(ssc_code)



# lga ---------------------------------------------------------------------
cat(paste0("Processing lga\n"))

lga_combined <- lga_input %>%
  cleanDatatypes() %>%
  left_join(findTopTwo(aggregate_by="lga_code",boundary_type="city"), by="lga_code") %>%
  left_join(findPopulation(aggregate_by="lga_code")                 , by="lga_code") %>%
  dplyr::select(lga_code, lga_name,
                city_code_1, city_name_1, city_code_2, city_name_2,
                state_code, state_name, dwelling, person, area_albers_sqkm) %>%
  arrange(lga_code)



# states and Australia ----------------------------------------------------
cat(paste0("Processing states and Australia boundaries\n"))

state_combined <- state_input %>%
  cleanDatatypes() %>%
  left_join(findPopulation(aggregate_by="state_code"), by="state_code")

australia_combined <- australia_input %>%
  cleanDatatypes() %>%
  left_join(findPopulation(aggregate_by="aus_code"), by="aus_code")


# centroids ---------------------------------------------------------------
cat(paste0("Calculating centroids\n"))

cities_centroids <- calculateCentroids("city_code",cities_combined)

state_centroids <- calculateCentroids("state_code",state_combined) 

lga_centroids <- calculateCentroids("lga_code",lga_combined) 

ssc_centroids <- calculateCentroids("ssc_code",ssc_combined) 

sa4_centroids <- calculateCentroids("sa4_code",sa4_combined) 
sa3_centroids <- calculateCentroids("sa3_code",sa3_combined) 
sa2_centroids <- calculateCentroids("sa2_code",sa2_combined) 
sa1_centroids <- calculateCentroids("sa1_code",sa1_combined) 



# write converted boundaries ----------------------------------------------
cat(paste0("Writing processed boundaries\n"))

st_write(australia_combined, paste0("output/boundaries_",year,".sqlite"), layer="australia", append=F)
st_write(state_combined    , paste0("output/boundaries_",year,".sqlite"), layer="state"    , append=F)
st_write(cities_combined   , paste0("output/boundaries_",year,".sqlite"), layer="cities"   , append=F)
st_write(lga_combined      , paste0("output/boundaries_",year,".sqlite"), layer="lga"      , append=F)
st_write(ssc_combined      , paste0("output/boundaries_",year,".sqlite"), layer="ssc"      , append=F)
st_write(sa4_combined      , paste0("output/boundaries_",year,".sqlite"), layer="sa4"      , append=F)
st_write(sa3_combined      , paste0("output/boundaries_",year,".sqlite"), layer="sa3"      , append=F)
st_write(sa2_combined      , paste0("output/boundaries_",year,".sqlite"), layer="sa2"      , append=F)
st_write(sa1_combined      , paste0("output/boundaries_",year,".sqlite"), layer="sa1"      , append=F)
st_write(mb_combined       , paste0("output/boundaries_",year,".sqlite"), layer="mb"       , append=F)

st_write(state_centroids   , paste0("output/boundaries_",year,".sqlite"), layer="state_centroids" , append=F)
st_write(cities_centroids  , paste0("output/boundaries_",year,".sqlite"), layer="cities_centroids", append=F)
st_write(lga_centroids     , paste0("output/boundaries_",year,".sqlite"), layer="lga_centroids"   , append=F)
st_write(ssc_centroids     , paste0("output/boundaries_",year,".sqlite"), layer="ssc_centroids"   , append=F)
st_write(sa4_centroids     , paste0("output/boundaries_",year,".sqlite"), layer="sa4_centroids"   , append=F)
st_write(sa3_centroids     , paste0("output/boundaries_",year,".sqlite"), layer="sa3_centroids"   , append=F)
st_write(sa2_centroids     , paste0("output/boundaries_",year,".sqlite"), layer="sa2_centroids"   , append=F)
st_write(sa1_centroids     , paste0("output/boundaries_",year,".sqlite"), layer="sa1_centroids"   , append=F)
st_write(mb_centroids_final, paste0("output/boundaries_",year,".sqlite"), layer="mb_centroids"    , append=F)


