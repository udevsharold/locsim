# locsim
A tool to simulate GPS location system-wide. This tool simulates GPS location natively without any runtime injection, and it's how Apple do it.

## Usage

```
Usage: locsim <SUBCOMMAND> [LATITUDE] [LONGITUDE] [OPTIONS]
if LATITUDE and LONGITUDE not specified, random values will be generated

SUBCOMMAND:
	start	start location simulation
	stop	stop location simulation
OPTIONS:
	-x, --latitude <double>: latitude of geographical coordinate
	-y, --longitude <double>: longitude of geographical coordinate
	-a, --altitude <double>: location altitude
	-h, --haccuracy <double>: radius of uncertainty for the geographical coordinate, measured in meters
	-v, --vaccuracy <double>: accuracy of the altitude value, measured in meters
	-s, --speed <double>: speed, or  override average speed if -g specified, measured in m/s
	    --saccuracy <double>: accuracy of the speed value, measured in m/s	
	-c, --course <double>: direction values measured in degrees
	    --caccuracy <double>: accuracy of the course value, measured in degress	
	-t, --time <double>: epoch time to associate with the location
	-f, --force: force stop simulation, requires root access
	--help: show this help
ADDITIONAL GPX OPTIONS:
	-g, --gpx <file>: gpx file path
	    --plist <file>: exported or valid plist file path
	-l, --lifespan <double>: lifespan
	-p, --type <int>: type
	-d, --delivery <int>: location delivery behaviour
	-r, --repeat <int>: location repeat behaviour
	--export-plist <file>: export converted gpx file to plist
	--export-only: export converted gpx file to plist without running simulation	
```


## Compatibility
This package tested to be working on iOS 14.3. Might or might not work on other iOS version.

## Bonus
- This [Shortcut](https://www.icloud.com/shortcuts/da26c522bb4d4757abcb818f0515dd5d) allow you to pick any location on Maps.app and simulate it (requires localhost ssh, change port and password accordingly).
- Stop simulation [Shortcut](https://www.icloud.com/shortcuts/baad5ee4e7414047b92197be3d562045)
- Convert any route to gpx using this [online tool](https://mapstogpx.com/)

## References
- Hines, L. (2014, October 18). Custom GPS data in the IOS simulator. Luke Hines : Bottle of Code. Retrieved December 15 2021, from https://bottleofcode.com/posts/custom-gps-data-in-the-ios-simulator/
## License
All source code in this repository are licensed under GPLv3, unless stated otherwise.

Copyright (c) 2021 udevs
