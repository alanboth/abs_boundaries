# 2011 --------------------------------------------------------------------

if(year==2011) {
  # there doesn't seem to be a 2011 Australia shapefile so using 2016 instead
  australia_input <- st_read("data/asgs_vol_1_2016.gpkg", layer="AUS_2016_AUST") %>%
    dplyr::select(aus_code=AUS_CODE_2016, aus_name=AUS_NAME_2016,
                  area_albers_sqkm=AREA_ALBERS_SQKM) %>%
    mutate(aus_code="AUS")


  state_input <- st_read("/vsizip/data/state_2011.zip") %>%
    dplyr::select(state_code=STE_CODE11, state_name=STE_NAME11,
                  area_albers_sqkm=ALBERS_SQM) %>%
    renameGeometryColumn()


  gccsa_input <- st_read("/vsizip/data/gccsa_2011.zip") %>%
    dplyr::select(city_code=GCC_CODE11, city_name=GCC_NAME11,
                  area_albers_sqkm=ALBERS_SQM) %>%
    renameGeometryColumn()


  sua_input <- st_read("/vsizip/data/sua_2011.zip") %>%
    dplyr::select(city_code=SUA_CODE11, city_name=SUA_NAME11,
                  area_albers_sqkm=AREA_SQKM) %>%
    renameGeometryColumn()


  sos_input <- st_read("/vsizip/data/sos_2011.zip") %>%
    dplyr::select(sos_category=SOS_NAME11) %>%
    renameGeometryColumn()


  lga_input <- st_read("/vsizip/data/lga_2011.zip") %>%
    dplyr::select(lga_code=LGA_CODE11, lga_name=LGA_NAME11,
                  state_code=STE_CODE11, state_name=STE_NAME11,
                  area_albers_sqkm=AREA_SQKM) %>%
    renameGeometryColumn()


  ssc_input <- st_read("/vsizip/data/ssc_2011.zip") %>%
    dplyr::select(ssc_code=SSC_CODE, ssc_name=SSC_NAME,
                  # state_code=STATE_CODE_2016, state_name=STATE_NAME_2016,
                  area_albers_sqkm=SQKM) %>%
    renameGeometryColumn()

  # the states aren't included in the 2011 state suburbs shapefile
  ssc_states <- st_join(ssc_input%>%dplyr::select(ssc_code)%>%st_centroid(of_largest_polygon=T),
                 state_input%>%dplyr::select(state_code,state_name),
                 join=st_intersects) %>%
    st_drop_geometry()
  ssc_input <- ssc_input %>%
    left_join(ssc_states, by="ssc_code") %>%
    dplyr::select(ssc_code, ssc_name, state_code, state_name, area_albers_sqkm)


  sa4_input <- st_read("/vsizip/data/sa4_2011.zip") %>%
    dplyr::select(sa4_code=SA4_CODE11,
                  state_code=STE_CODE11, state_name=STE_NAME11,
                  area_albers_sqkm=ALBERS_SQM) %>%
    renameGeometryColumn()


  sa3_input <- st_read("/vsizip/data/sa3_2011.zip") %>%
    dplyr::select(sa3_code=SA3_CODE11, sa4_code=SA4_CODE11,
                  state_code=STE_CODE11, state_name=STE_NAME11,
                  area_albers_sqkm=ALBERS_SQM) %>%
    renameGeometryColumn()


  sa2_input <- st_read("/vsizip/data/sa2_2011.zip") %>%
    dplyr::select(sa2_code=SA2_MAIN11,
                  sa3_code=SA3_CODE11, sa4_code=SA4_CODE11,
                  state_code=STE_CODE11, state_name=STE_NAME11,
                  area_albers_sqkm=ALBERS_SQM) %>%
    renameGeometryColumn()


  sa1_input <- st_read("/vsizip/data/sa1_2011.zip") %>%
    dplyr::select(sa1_code=SA1_MAIN11, sa2_code=SA2_MAIN11,
                  sa3_code=SA3_CODE11, sa4_code=SA4_CODE11,
                  state_code=STE_CODE11, state_name=STE_NAME11,
                  area_albers_sqkm=ALBERS_SQM) %>%
    renameGeometryColumn()


  mb_input <- NULL
  # the 2011 meshblocks are split into individual shapefiles by state, so
  # it is necessary to loop over all of them
  for (i in c("act","nsw","nt","ot","qld","sa","taz","vic","wa")) {
    mb_input_tmp <- st_read(paste0("/vsizip/data/mb_",i,"_2011.zip")) %>%
      dplyr::select(mb_code=MB_CODE11, mb_category=MB_CAT11,
                    sa1_code=SA1_MAIN11, sa2_code=SA2_MAIN11,
                    sa3_code=SA3_CODE11, sa4_code=SA4_CODE11,
                    state_code=STE_CODE11, state_name=STE_NAME11,
                    area_albers_sqkm=ALBERS_SQM) %>%
      renameGeometryColumn()
    
    mb_input <- bind_rows(mb_input, mb_input_tmp)
  }
  mb_input <- mb_input %>%
    st_sf()
  
  mb_count_input <- read.csv("data/mb_count_2011.csv")
}



# 2016 --------------------------------------------------------------------

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
  
  mb_count_input <- read.csv("data/mb_count_2016.csv")
}




# 2021 --------------------------------------------------------------------

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
  
  mb_count_input <- read.csv("data/mb_count_2021.csv")
}