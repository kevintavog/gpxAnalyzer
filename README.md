# gpxAnalyzer

Accepts a GPX file and produces a JSON file which can be viewed with the gpx-analyzer-view project.

This project attempts to identify:
- Stops & pauses
- Poor quality GPS
    - A poor fix (`2d` is poor, `3d` is good)
    - Poor horizontal or position dilution of precision (`hdop`, `pdop`)
- Transportation types:
    - `foot` - walking or running
    - `bicycle`
    - `car` - car, bus, light rail
    - `train` - commute and high speed train
    - `plane` 
