# osrm-backend-nginx

This repo combining osrm-backend APIs with nginx based on docker
## Requirement

- docker
- docker-build
- docker-compose
- jq


## Quick Start

To deploy this project first download map file for example

```bash
  ./run.sh download -g "http://download.geofabrik.de/asia/iran-latest.osm.pbf"
```

after downloading map file run

```bash
  ./run.sh setup
```

for getting duration(secon) and distance(metre) between two points run

```bash
  ./run.sh get -s 51.42838,35.80697 -d 51.42088,35.68590
```
option "-s" is first point and "-d" means second point with format "<Longitude>,<Latitude>"


## Usage

```bash
Usage:
    run.sh setup -m <MAP> # setup project 
    run.sh start #start containers
    run.sh stop #stop containers
    run.sh destroy #stop and delete all containers
    run.sh download -g <URL> #download MAP file
    run.sh list #list all map files
    run.sh status #get status of containers
    run.sh get -s <FIRST_Longitude,FIRST_Latitude> -d <SECOND_Longitude,SECOND_Latitude> #get distance and duration between two point based on mode

```
## License

[BSD 2-Clause "Simplified" License](https://github.com/MJAsadi72/osrm-backend-nginx/blob/main/LICENSE)
