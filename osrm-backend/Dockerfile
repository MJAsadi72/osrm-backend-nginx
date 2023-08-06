FROM ghcr.io/project-osrm/osrm-backend:v5.27.1  
ARG TYPE
ARG MAP=iran-latest
ENV MAP=${MAP}
COPY ./assets/${MAP}.osm.pbf /data/
RUN osrm-extract -p /opt/${TYPE}.lua /data/${MAP}.osm.pbf && \
	osrm-partition /data/${MAP}.osrm && \
	osrm-customize /data/${MAP}.osrm && \
	rm -f /data/${MAP}.osm.pbf
CMD osrm-routed  --algorithm  mld /data/${MAP}.osrm

EXPOSE 5000
