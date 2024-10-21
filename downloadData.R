#!/usr/bin/env Rscript

# load libraries and functions --------------------------------------------
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(readxl))

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

yearToProcess<-opt$year
# yearToProcess=2021

cat(paste0("Running downloadData.R for ",yearToProcess,"\n"))


files_df <- read.csv("data_locations.csv") %>%
  filter(year==yearToProcess)




# Download files ----------------------------------------------------------

for (i in 1:nrow(files_df)) {
  file_name_current <- paste0("data/",files_df[i,]$file_name)
  url_current <- files_df[i,]$url
  # if the file doesn't exist download it
  if (!file.exists(file_name_current)) {
    download.file(url_current, file_name_current, method="wget")
  }
}

zipped_files <- files_df$file_name[grepl("*.zip", files_df$file_name)]

for (i in 1:length(zipped_files)) {
  file_name_current <- paste0("data/",zipped_files[i])
  file_name_final <- gsub(".zip", ".gpkg", file_name_current)
  
  # if the file doesn't exist unzip it
  if (!file.exists(file_name_final)) {
    # find the geopackage within the zip
    files_gpkg <- unzip(file_name_current,list=T) %>%
      filter(grepl("*.gpkg", Name)) %>%
      first() %>%
      pull(Name)
    unzip(file_name_current,files=files_gpkg)
    file.rename(files_gpkg, file_name_final)
  }
}

xls_files <- files_df$file_name[grepl("*.xls", files_df$file_name)]

# converting excel files to csv
for (i in 1:length(xls_files)) {
  file_name_current <- paste0("data/",xls_files[i])
  file_name_final <- gsub("xlsx", "csv", file_name_current)
  file_name_final <- gsub("xls", "csv", file_name_final)
  
  # if the file doesn't exist create it
  if (!file.exists(file_name_final)) {
    convertMeshblockCountToCsv(
      input_file= file_name_current,
      output_file=file_name_final
    )
  }
}

  


