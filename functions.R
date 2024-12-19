#!/usr/bin/env Rscript



# ensures the geometry column is called 'geom'
renameGeometryColumn <- function(df) {
  if (
    intersect(colnames(df),
              c("GEOM", "GEOMETRY", "geometry")) %>% length() > 0
  ) {
    st_geometry(df) <- "geom"
  }
  return(df)
}
  


# converts a meshblock count excel spreadsheet to a csv
convertMeshblockCountToCsv <- function(input_file, output_file) {
  # input_file <- "mb_count_2021.xlsx"; output_file <- "mb_count_2021.csv"
  
  # all the sheet names in the file
  sheet_names <- excel_sheets(input_file)
  #just the ones that start with Table
  sheet_names <- sheet_names[grepl("Table *", sheet_names)]
  
  mb_count_df <- NULL
  
  start_row <- read_excel(
      input_file,
      sheet = sheet_names[1],
      range = "A1:A20"
    )
  colnames(start_row) <-"first_column"
  start_row <- start_row %>%
    mutate(row_num=row_number()+1) %>%
    mutate(is_start=grepl("MB_CODE*|Mesh_Block*",first_column,ignore.case=T)) %>%
    filter(is_start) %>%
    pull(row_num)

  # loop through each sheet, adding the data to mb_count_df
  for (i in sheet_names) {
    # i=sheet_names[1]
    
    # Mesh_Block_ID	| Dwellings | Persons_Usually_Resident
    # MB_CODE_2016 | MB_CATEGORY_NAME_2016 | AREA_ALBERS_SQKM | Dwelling | Person | State
    
    
    sheet_current <- read_excel(
      input_file,
      sheet = i,
      range = cell_rows(start_row:1000000)
    )
    mb_col <- sheet_current %>% dplyr::select(c(starts_with("Mesh"),starts_with("MB_CODE"))) %>% colnames() %>% first()
    dwelling_col <- sheet_current %>% dplyr::select(starts_with("Dwelling")) %>% colnames() %>% first()
    person_col <- sheet_current %>% dplyr::select(starts_with("Person")) %>% colnames() %>% first()

    if(!is.na(mb_col)) sheet_current <- sheet_current %>% rename("mb_code"=mb_col)
    if(!is.na(dwelling_col)) sheet_current <- sheet_current %>% rename("dwelling"=dwelling_col)
    if(!is.na(person_col)) sheet_current <- sheet_current %>% rename("person"=person_col)
    
    sheet_current <- sheet_current %>%
      dplyr::select(any_of(c("mb_code","dwelling","person"))) %>%
      mutate(mb_code = as.numeric(mb_code)) %>%
      filter(!is.na(mb_code))
    
    mb_count_df <- bind_rows(
      mb_count_df,
      sheet_current
    )
    cat(paste0("converted ", i, " (", nrow(sheet_current), " rows)\n"))
  }
  
  # in case there are duplicate rows
  mb_count_df <- mb_count_df %>%
    distinct()
  
  # save cleaned file to specified location
  write.csv(mb_count_df, output_file, row.names=F, quote=F)
}



# ensures that the various community codes are numeric
cleanDatatypes <- function(df) {
  output <- df %>%
    mutate(
      across(any_of(c("mb_code", "sa1_code", "sa2_code", "sa3_code", "sa4_code",
                      "poa_code", "ssc_code", "lga_code", "state_code")),
             ~ as.double(.x))
    ) %>%
    filter(!st_is_empty(.))
  if("area_albers_sqkm"%in%colnames(df)) {
    output <- output %>%
      mutate(area_albers_sqkm=as.numeric(area_albers_sqkm))
  }

  return(output)
}


# determine the city the sa1/sa2/etc is in
findCity <- function(aggregate_by) {
  output <- mb_no_geom %>%
    dplyr::select(community_code=!!aggregate_by,city_code,city_name,person,area_albers_sqkm) %>%
    group_by(community_code, city_code, city_name) %>%
    summarise(person=sum(person, na.rm=T), area=sum(area_albers_sqkm, na.rm=T)) %>%
    group_by(community_code) %>%
    arrange(-person, -area, city_name) %>%
    mutate(rank=row_number()) %>%
    slice_min(rank) %>%
    ungroup() %>%
    dplyr::select(!!aggregate_by:=community_code, city_code, city_name)

  return(output)
}

# determine the top two lga/ssc/etc the sa1/sa2/etc is in
findTopTwo <- function(aggregate_by, boundary_type) {
  output <- mb_no_geom %>%
    dplyr::select(community_code=!!aggregate_by, boundary_code=!!paste0(boundary_type,'_code'), 
                  boundary_name=!!paste0(boundary_type,'_name'), person, area_albers_sqkm) %>%
    group_by(community_code, boundary_code, boundary_name) %>%
    summarise(person=sum(person, na.rm=T), area=sum(area_albers_sqkm, na.rm=T)) %>%
    group_by(community_code) %>%
    arrange(-person, -area, boundary_name) %>%
    mutate(rank=row_number()) %>%
    ungroup() %>%
    dplyr::select(community_code, boundary_code, boundary_name, rank) %>%
    filter(rank<=2) %>%
    pivot_wider(names_from=rank,
                values_from=c("boundary_code", "boundary_name")) %>%
    rename(!!aggregate_by:=community_code)
  
  # if the geometries never cross two boundaries, we need to add in those columns
  if(!"boundary_code_2"%in%colnames(output)) {
    output <- output %>%
      mutate(boundary_code_2=NA) %>%
      mutate(boundary_name_2=NA)
  }
  
  output <- output %>%
    rename_with(~ gsub("boundary_", paste0(boundary_type,"_"), .x, fixed = TRUE))

  return(output)
}

# sums the population and dwelling count for the sa1/sa2/etc
findPopulation <- function(aggregate_by) {
  output <- mb_no_geom
  # the meshblocks don't store the australia code
  if(aggregate_by=="aus_code") {
    output <- output %>%
      mutate(aus_code="AUS")
  }
  output <- output %>%
    dplyr::select(community_code=!!aggregate_by, dwelling, person) %>%
    group_by(community_code) %>%
    summarise(dwelling=sum(dwelling, na.rm=T), person=sum(person, na.rm=T)) %>%
    dplyr::select(!!aggregate_by:=community_code, dwelling, person)

  return(output)
}

# Calculates the centroid for a given dataframe. If the centroid lies outside
# the initial region's polygon, the point_on_surface algorithm is used to ensure
# the point is always inside the region. 
calculateCentroids <- function(df, id_column) {
  # df=mb
  
  df <- df %>%
    mutate(temp_row_id=row_number())

  centroids_initial <- df %>%
    st_centroid()
  
  distance_to_df <- st_distance(centroids_initial, df, by_element=T) %>%
    as.numeric()
  
  df_centroids_outside <- df %>%
    mutate(centroid_distance=distance_to_df) %>%
    filter(centroid_distance>0) %>%
    st_point_on_surface()
  
  df_centroids_inside <- centroids_initial %>%
    mutate(centroid_distance=distance_to_df) %>%
    filter(centroid_distance==0)
  
  df_centroids <- bind_rows(
    df_centroids_outside,
    df_centroids_inside
  ) %>%
    st_sf() %>%
    arrange(temp_row_id) %>%
    dplyr::select(-temp_row_id,-centroid_distance)
  
  return(df_centroids)
}

# Calculates the population-weighted centroid for the sa1/sa2/etc. If the total 
# population for the sa1/sa2/etc region is zero, a standard centroid is used.
# If the centroid lies outside the sa1/sa2/etc region, the point_on_surface
# algorithm is used to ensure the point is always inside the region. 
calculateWeightedCentroids <- function(aggregate_by, df) {
  # aggregate_by="sa1_code";df=sa1_combined
  # aggregate_by="city_code";df=cities_combined
  # aggregate_by="state_code";df=state_combined
  # aggregate_by="sa4_code";df=sa4_combined
  
  df_regions <- df %>%
    rename(community_code=!!aggregate_by) %>%
    dplyr::select(community_code) %>%
    arrange(community_code)
    
  # find the population in each region
  pop_count <- mb_no_geom %>%
    rename(community_code=!!aggregate_by) %>%
    group_by(community_code) %>%
    summarise(person=sum(person, na.rm=T)) %>%
    # in case some of the regions don't have geometries, but their meshblocks do
    filter(community_code%in%df_regions$community_code)
    
  regions_with_population <- pop_count %>%
    filter(person>0) %>%
    pull(community_code)
  regions_without_population <- pop_count %>%
    filter(person==0 | is.na(person)) %>%
    pull(community_code)
  
  # if we don't have a population, just use a standard centroid
  standard_centroids <- df_regions %>%
    filter(community_code%in%regions_without_population) %>%
    st_centroid()
  
  # if we do have a population some regions, take the populated meshblocks
  # within them
  weighted_centroids <- mb_centroids_final %>%
    rename(community_code=!!aggregate_by) %>%
    filter(community_code%in%regions_with_population) %>%
    filter(!is.na(community_code)) %>% # some meshblocks don't have a city
    filter(person>0) %>%
    dplyr::select(community_code, person)
  
  # converting the points to X, Y columns
  crs_current <- st_crs(weighted_centroids)
  weighted_centroids <- bind_cols(
    weighted_centroids%>%st_drop_geometry(),
    weighted_centroids%>%st_coordinates()%>%as.data.frame()
  ) %>%
    group_by(community_code) %>%
    summarise(X=weighted.mean(X, person, na.rm=T),
              Y=weighted.mean(Y, person, na.rm=T)) %>%
    ungroup() %>%
    st_as_sf(coords = c("X", "Y"), crs = crs_current)
  
  # fixing the geometry column so it's consistent with the others
  if(!"geom"%in%colnames(weighted_centroids)) {
    st_geometry(weighted_centroids) <- "geom"
  }
  
  # a single dataframe with all centroids
  combined_centroids <- bind_rows(
    standard_centroids,
    weighted_centroids
  ) %>%
    st_sf() %>%
    arrange(community_code)
  
  # find the distance from each centroid to its region. If > 0, it's outside of
  # the region and must be replaced
  distance_to_region <- st_distance(combined_centroids, df_regions, by_element=T) %>%
    as.numeric()
  region_distance <- df_regions %>%
    mutate(centroid_distance=distance_to_region)
  
  # centroids outside of their regions make use of a different algorithm to
  # ensure the point is always within the region
  centroids_outside <- region_distance %>%
    filter(centroid_distance>0) %>%
    dplyr::select(community_code) %>%
    st_point_on_surface()
  
  centroids_corrected <- bind_rows(
    combined_centroids %>%
      filter(!community_code %in% centroids_outside$community_code),
    centroids_outside
  ) %>%
    st_sf() %>%
    arrange(community_code)
  
  centroids_final <- df %>%
    rename(community_code=!!aggregate_by) %>%
    st_drop_geometry() %>%
    right_join(centroids_corrected, by=c("community_code")) %>%
    rename(!!aggregate_by:=community_code) %>%
    st_sf()
  
  return(centroids_final)
}


