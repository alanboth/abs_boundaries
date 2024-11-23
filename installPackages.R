# list of packages to install
packages <- c("optparse","dplyr", "tidyr", "sf", "lwgeom", "stringi", "readxl")

# only install ones that aren't already present
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]

# install the packages using the default repository
if(length(new_packages)>0) install.packages(new_packages, repos="https://cloud.r-project.org")

