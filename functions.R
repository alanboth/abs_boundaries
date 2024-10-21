#!/usr/bin/env Rscript


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
    mutate(is_start=grepl("MB_CODE*",first_column,ignore.case=T)) %>%
    filter(is_start) %>%
    pull(row_num)

  # loop through each sheet, adding the data to mb_count_df
  for (i in sheet_names) {
    # i=sheet_names[1]
    sheet_current <- read_excel(
      input_file,
      sheet = i,
      range = cell_rows(start_row:1000000)
    ) %>%
      filter(!is.na(State)) %>%
      mutate(across(starts_with("MB_CODE"), ~ as.numeric(.x)))
    
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
  write.csv(mb_count_df, output_file, row.names=F)
}

cleanDatatypes <- function(df) {
  output <- df %>%
    mutate(
      across(any_of(c("mb_code", "sa1_code", "sa2_code", "sa3_code", "sa4_code", "ssc_code", "lga_code", "state_code")),
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
    rename(!!aggregate_by:=community_code) %>%
    rename_with(~ gsub("boundary_", paste0(boundary_type,"_"), .x, fixed = TRUE))

  return(output)
}


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

calculateCentroids <- function(aggregate_by, df) {
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

