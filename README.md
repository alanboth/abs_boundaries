# ABS boundaries

Scripts for downloading and processing ABS boundaries



--------------------------------------------------------------------------------



## downloadData.R

#### Synopsis
```bash
Rscript downloadData.R [--year]
```

#### Prerequisites
* None

#### Description
**downloadData.R** downloads data for a given year from the abs website. It also converts meshblock count spreadsheets into plain csv files and extracts geopackage files from zips. If a file is already downloaded, then it will not be downloaded again.

``--year``

Specify the year desired. Currently 2016 and 2021 are supported.


#### Example
```bash
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
* lga
* ssc
* sa4
* sa3
* sa2
* sa1
* mb
* state_centroids
* cities_centroids
* lga_centroids
* ssc_centroids
* sa4_centroids
* sa3_centroids
* sa2_centroids
* sa1_centroids
* mb_centroids

``--year``

Specify the year desired. Currently 2016 and 2021 are supported.


#### Example
```bash
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

Specify the year desired. Currently 2016 and 2021 are supported.


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
filterToStudyRegion.R
  --year='2016' \
  --states='Victoria' \
  --epsg='7899' \
  --filename='Victoria'

# Melbourne and Sydney plus a 10km buffer
filterToStudyRegion.R
  --year='2021' \
  --cities='Greater Melbourne, Greater Sydney' \
  --buffer='10000' \
  --epsg='7845' \
  --filename='MelbourneAndSydney'
```








## Useful Coordinate Reference Systems

| EPSG | Name                                          | Extent    | Notes                                                                     |
| ---- | --------------------------------------------- | --------- | ------------------------------------------------------------------------- |
| 7845 | [GDA2020 / GA LCC](https://epsg.io/7845)      | Australia | Best projected CRS for Australia-wide distance calculations               |
| 4326 | [WGS 84](https://epsg.io/4326)                | World     | Default geographic CRS for Australia. Useful for webmaps                  |
| 7842 | [GDA2020](https://epsg.io/7842)               | Australia | New geographic CRS for Australia                                          |
| 7855 | [GDA2020 / MGA zone 55](https://epsg.io/7855) | Melbourne | New projected CRS for Melbourne. Other zones can be used for other cities |
| 7899 | [GDA2020 / Vicgrid](https://epsg.io/7899)     | Victoria  | New projected CRS for Victoria                                            |
| 8058 | [GDA2020 / NSW Lambert](https://epsg.io/8058) | NSW       | New projected CRS for NSW                                                 |
| 8059 | [GDA2020 / SA Lambert](https://epsg.io/8059)  | SA        | New projected CRS for SA                                                  |

### Older Coordinate Reference Systems

| EPSG  | Name                                                         | Extent    | Notes                                                                       |
| ----- | ------------------------------------------------------------ | --------- | --------------------------------------------------------------------------- |
| 3112  | [GDA94 / Geoscience Australia Lambert](https://epsg.io/3112) | Australia | Older projected CRS that's useful for Australia-wide distance calculations  |
| 28355 | [GDA94 / MGA zone 55](https://epsg.io/28355)                 | Melbourne | Older projected CRS for Melbourne. Other zones can be used for other cities |
| 7855  | [GDA2020 / MGA zone 55](https://epsg.io/7855)                | Melbourne | New projected CRS for Melbourne. Other zones can be used for other cities   |
| 3111  | [GDA94 / Vicgrid](https://epsg.io/3111)                      | Victoria  | Older projected CRS for Victoria                                            |
| 3308  | [GDA94 / NSW Lambert](https://epsg.io/3308)                  | NSW       | Older projected CRS for NSW                                                 |
| 3107  | [GDA94 / SA Lambert](https://epsg.io/3107)                   | SA        | Older projected CRS for SA                                                  |
