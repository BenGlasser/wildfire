## The Problem

Wildfires are raging across the country!

## Our Solution

We need to pull in accurate and timely wildfire information to help our customers remain vigilant in protecting their homes and family. The more up-to-date and faster we can push out information to our customers, the better.

## Details

ESRI has published an authoritative feed of all current wildfires, the details are available here, [USA Current Wildfires](https://www.arcgis.com/home/item.html?id=d957997ccee7408287a963600a77f61f).

The ArcGIS platform provided by ESRI provides a REST interface to query the data, you can see the details of the schema and links to the query interface here, [Feature Server](https://services3.arcgis.com/T4QMspbfLg3qTGWY/arcgis/rest/services/WFIGS_Incident_Locations_Current/FeatureServer).

You can find information about the REST interface here, [ArcGIS REST API](https://developers.arcgis.com/rest/).

This feature contains two layers, incidents and perimeters, we're only worried about the incidents.

The fastest way to distribute this information is over a websocket. I've heard [Bandit](https://github.com/mtrudel/bandit) provides a very efficient websocket server 😉

Currently we are not worried about authentication or authorization, we just want to get this data out as fast as possible to as many people as possible.

Having the geo data available in a standard format, perhaps GeoJSON, will be very helpful for anyone trying to build a UI around our data.

The rest of our geo-analytical system works on the [EPSG:4326](https://epsg.io/4326) spatial reference system, it would be ideal to work with this data in the same reference system.

## Delivery of exercise

A public VCS repository is preferred.

The project README should contain all the information and steps necessary to run the code. [asdf](https://asdf-vm.com/) is the preferred tool for declaring system dependencies, but other tools are welcome, as long as it's explained how to install and use them.

You can assume Postgres is running on localhost port 5432, although making this configurable is desirable.

You can assume docker and docker-compose are also available, but using something like asdf to declare those is preferred.

## Extra Credit

- Perimeter data
- Packaging and deployment plan
- Telemetry/Monitoring of workload
- UI to visualize current fires
- Unit/Integration tests

## Questions

Please email Christopher Coté with any questions or concerns.
