# ABS-derived boundary files

The purpose of this repository is to provide a convenient method for downloading the various boundary files from the Australian Bureau of Statistics (ABS) and converting them into a consistent format. Some benefits of this code include:

* A single place to get all the ABS boundary files across 2011, 2016 and 2021

* Automatically downloads all necessary files

* Consistently formatted column headings across the years (SA1_MAIN11, SA1_MAINCODE_2016, SA1_CODE_2021 are now all now sa1_code)

* Includes population-weighted centroids for each boundary type that are guaranteed to lie within the original region’s geometry (i.e., no centroids in the ocean)

* Manually extracting the population and dwelling counts from ABS excel spreadsheets is usually an error-prone manual task. This code automatically converts them into clean CSVs

* Some suburbs can lie in multiple LGAs. This code will store the largest two for each suburb

* Produces a single [sqlite](https://www.gaia-gis.it/fossil/libspatialite/index) file for each census year, which can be used across projects

* Includes code that can filter the boundaries down to just the cities or states required, optionally including a user-specified buffer

Output files are available [here](https://research-repository.rmit.edu.au/articles/dataset/ABS-derived_boundary_files/27966567).

## Quick setup

This assumes you have [R](https://www.r-project.org/) installed

```bash
# install any missing R packages
Rscript installPackages.R
# download the raw boundary files from the ABS
Rscript downloadData.R --year='2021'
# convert the data into a consistent output format
Rscript convertData.R --year='2021'
```

--------------------------------------------------------------------------------

## downloadData.R

#### Synopsis

```bash
Rscript downloadData.R [--year]
```

#### Description

**downloadData.R** downloads data for a given year from the abs website. It also converts meshblock count spreadsheets into plain csv files and extracts geopackage files from zips. If a file is already downloaded, then it will not be downloaded again.

``--year``

Specify the year desired. Currently 2011, 2016 and 2021 are supported.

#### Example

```bash
Rscript downloadData.R --year='2011'
Rscript downloadData.R --year='2016'
Rscript downloadData.R --year='2021'
```

--------------------------------------------------------------------------------

## convertData.R

#### Synopsis

```bash
Rscript convertData.R [--year]
```

#### Prerequisites

* [downloadData.R](README.md#downloaddatar)

#### Description

**convertData.R** converts the downloaded data into a single sqlite file. The following tables are created:

* australia
* state
* cities
* lga *(local government areas)*
* ssc *(state suburbs/suburbs and localities)*
* poa *(postcodes)*
* sa4 *(statistical area level 4)*
* sa3 *(statistical area level 3)*
* sa2 *(statistical area level 2)*
* sa1 *(statistical area level 1)*
* mb *(meshblocks)*
* state_centroids
* cities_centroids
* lga_centroids
* ssc_centroids
* poa_centroids
* sa4_centroids
* sa3_centroids
* sa2_centroids
* sa1_centroids
* mb_centroids

``--year``

Specify the year desired. Currently 2011, 2016 and 2021 are supported. **Note:** 2011 lacks an Australia shapefile so the one from 2016 is used instead. `downloadData.R` will have to be run for both years before 2011 can be converted.

#### Example

```bash
Rscript convertData.R --year='2011'
Rscript convertData.R --year='2016'
Rscript convertData.R --year='2021'
```

--------------------------------------------------------------------------------

## filterToStudyRegion.R

#### Synopsis

```bash
Rscript filterToStudyRegion.R [--year] [--cities] [--states] [--buffer] [--epsg] [--filename]
```

#### Prerequisites

* [convertData.R](README.md#convertdatar)

#### Description

**filterToStudyRegion.R** filters the converted data to the desired study region

``--year``

Specify the year desired. Currently 2011, 2016 and 2021 are supported.

``--cities``

Comma separated list of cities to filter to. Not mandatory, but cannot be used with ``--states``. Can list a single city.

``--states``

Comma separated list of states to filter to. Not mandatory, but cannot be used with ``--cities``. Can list a single state.

``--buffer``

Specify the buffer distance in metres around the desired cities or states to be included. Not mandatory.

``--epsg``

Specify the EPSG (i.e., coordinate reference system to transform the data into). Not mandatory, but if nothing is specified, the source dataset's EPSG will be used.

``--filename``

Specify the filename for your output dataset.

#### Example

```bash
# A Victoria study region
Rscript filterToStudyRegion.R \
  --year='2016' \
  --states='Victoria' \
  --epsg='7899' \
  --filename='Victoria'

# Melbourne and Sydney plus a 10km buffer
Rscript filterToStudyRegion.R \
  --year='2021' \
  --cities='Greater Melbourne, Greater Sydney' \
  --buffer='10000' \
  --epsg='7845' \
  --filename='MelbourneAndSydney'
```

---

## Useful Coordinate Reference Systems

Geographic coordinate reference systems use latitude and longitude, measuring distance in degrees whereas projected ones use easting and northing, measuring distance in metres. Any geospatial analysis that involves distances will generally use a projected coordinate reference system.

| EPSG | Name                                          | Extent    | Notes                                                       |
| ---- | --------------------------------------------- | --------- | ----------------------------------------------------------- |
| 7845 | [GDA2020 / GA LCC](https://epsg.io/7845)      | Australia | Best projected CRS for Australia-wide distance calculations |
| 4326 | [WGS 84](https://epsg.io/4326)                | World     | Default geographic CRS for Australia. Useful for webmaps    |
| 7842 | [GDA2020](https://epsg.io/7842)               | Australia | Latest geographic CRS for Australia                         |
| 7899 | [GDA2020 / Vicgrid](https://epsg.io/7899)     | Victoria  | Latest projected CRS for Victoria                           |
| 8058 | [GDA2020 / NSW Lambert](https://epsg.io/8058) | NSW       | Latest projected CRS for NSW                                |
| 8059 | [GDA2020 / SA Lambert](https://epsg.io/8059)  | SA        | Latest projected CRS for SA                                 |

### MGA Zones:

MGA Zones are more accurate than the state or country-wide projections, but cover a much smaller extent. There are seven MGA zones covering mainland Australia and they are typically used for projects where the region of interest is city-scale. It's generally recommend to use the new MGA zones.

| MGA Zone | Older EPSG | Older Name                                   | New EPSG | New Name                                      |
| -------- | ---------- | -------------------------------------------- | -------- | --------------------------------------------- |
| 50       | 28350      | [GDA94 / MGA zone 50](https://epsg.io/28350) | 7850     | [GDA2020 / MGA zone 50](https://epsg.io/7850) |
| 51       | 28351      | [GDA94 / MGA zone 51](https://epsg.io/28351) | 7851     | [GDA2020 / MGA zone 51](https://epsg.io/7851) |
| 52       | 28352      | [GDA94 / MGA zone 52](https://epsg.io/28352) | 7852     | [GDA2020 / MGA zone 52](https://epsg.io/7852) |
| 53       | 28353      | [GDA94 / MGA zone 53](https://epsg.io/28353) | 7853     | [GDA2020 / MGA zone 53](https://epsg.io/7853) |
| 54       | 28354      | [GDA94 / MGA zone 54](https://epsg.io/28354) | 7854     | [GDA2020 / MGA zone 54](https://epsg.io/7854) |
| 55       | 28355      | [GDA94 / MGA zone 55](https://epsg.io/28355) | 7855     | [GDA2020 / MGA zone 55](https://epsg.io/7855) |
| 56       | 28356      | [GDA94 / MGA zone 56](https://epsg.io/28356) | 7856     | [GDA2020 / MGA zone 56](https://epsg.io/7856) |

### Cities and towns in each MGA Zone:

Capital cities are in bold

| Zone 50           | Zone 51              | Zone 52            | Zone 53       | Zone 54                | Zone 55                          | Zone 56                            |
| ----------------- | -------------------- | ------------------ | ------------- | ---------------------- | -------------------------------- | ---------------------------------- |
| Albany            | Broome               | **Greater Darwin** | Alice Springs | Ballarat               | Airlie Beach - Cannonvale        | Armidale                           |
| Bunbury           | Esperance            |                    | Port Augusta  | Broken Hill            | Albury - Wodonga                 | Ballina                            |
| Busselton         | Kalgoorlie - Boulder |                    | Port Lincoln  | Colac                  | **Australian Capital Territory** | Batemans Bay                       |
| Geraldton         |                      |                    | Port Pirie    | **Greater Adelaide**   | Bairnsdale                       | Bowral - Mittagong                 |
| **Greater Perth** |                      |                    | Whyalla       | Horsham                | Bathurst                         | Bundaberg                          |
| Karratha          |                      |                    |               | Mildura - Buronga      | Bendigo                          | Byron Bay                          |
| Port Hedland      |                      |                    |               | Mount Gambier          | Burnie - Somerset                | Camden Haven                       |
|                   |                      |                    |               | Mount Isa              | Cairns                           | Coffs Harbour                      |
|                   |                      |                    |               | Murray Bridge          | Castlemaine                      | Forster - Tuncurry                 |
|                   |                      |                    |               | Portland               | Devonport                        | Gladstone                          |
|                   |                      |                    |               | Swan Hill              | Dubbo                            | Gold Coast - Tweed Heads           |
|                   |                      |                    |               | Victor Harbor - Goolwa | Echuca - Moama                   | Grafton                            |
|                   |                      |                    |               | Warrnambool            | Emerald                          | **Greater Brisbane**               |
|                   |                      |                    |               |                        | Geelong                          | **Greater Sydney**                 |
|                   |                      |                    |               |                        | Goulburn                         | Gympie                             |
|                   |                      |                    |               |                        | **Greater Hobart**               | Hervey Bay                         |
|                   |                      |                    |               |                        | **Greater Melbourne**            | Kempsey                            |
|                   |                      |                    |               |                        | Griffith                         | Kingaroy                           |
|                   |                      |                    |               |                        | Launceston                       | Lismore                            |
|                   |                      |                    |               |                        | Mackay                           | Lithgow                            |
|                   |                      |                    |               |                        | Moe - Newborough                 | Maryborough                        |
|                   |                      |                    |               |                        | Mudgee                           | Medowie                            |
|                   |                      |                    |               |                        | Orange                           | Morisset - Cooranbong              |
|                   |                      |                    |               |                        | Sale                             | Muswellbrook                       |
|                   |                      |                    |               |                        | Shepparton - Mooroopna           | Nelson Bay                         |
|                   |                      |                    |               |                        | Townsville                       | Newcastle - Maitland               |
|                   |                      |                    |               |                        | Traralgon - Morwell              | Nowra - Bomaderry                  |
|                   |                      |                    |               |                        | Ulverstone                       | Port Macquarie                     |
|                   |                      |                    |               |                        | Wagga Wagga                      | Rockhampton                        |
|                   |                      |                    |               |                        | Wangaratta                       | Singleton                          |
|                   |                      |                    |               |                        | Warragul - Drouin                | St Georges Basin - Sanctuary Point |
|                   |                      |                    |               |                        |                                  | Sunshine Coast                     |
|                   |                      |                    |               |                        |                                  | Tamworth                           |
|                   |                      |                    |               |                        |                                  | Taree                              |
|                   |                      |                    |               |                        |                                  | Toowoomba                          |
|                   |                      |                    |               |                        |                                  | Ulladulla                          |
|                   |                      |                    |               |                        |                                  | Warwick                            |
|                   |                      |                    |               |                        |                                  | Wollongong                         |
|                   |                      |                    |               |                        |                                  | Yeppoon                            |

### Older Coordinate Reference Systems

These are generally no longer used, but are included for completeness.

| EPSG | Name                                                         | Extent    | Notes                                                                      |
| ---- | ------------------------------------------------------------ | --------- | -------------------------------------------------------------------------- |
| 3112 | [GDA94 / Geoscience Australia Lambert](https://epsg.io/3112) | Australia | Older projected CRS that's useful for Australia-wide distance calculations |
| 3111 | [GDA94 / Vicgrid](https://epsg.io/3111)                      | Victoria  | Older projected CRS for Victoria                                           |
| 3308 | [GDA94 / NSW Lambert](https://epsg.io/3308)                  | NSW       | Older projected CRS for NSW                                                |
| 3107 | [GDA94 / SA Lambert](https://epsg.io/3107)                   | SA        | Older projected CRS for SA                                                 |
