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
	-s, --speed: speed, or  average speed if -r specified, measured in m/s
	-t, --time <double>: epoch time to associate with the location
	-f, --force: force stop simulation
	--help: show this help
ADDITIONAL GPX OPTIONS:
	-g, --gpx: gpx file path
	    --plist: load exported plist file path instead
	-l, --lifespan: lifespan
	-p, --type: type
	-d, --delivery: location delivery behaviour
	-r, --repeat: location repeat behaviour
	--exportplist: export converted gpx file to plist
```


## Compatibility
This package tested to be working on iOS 14.3. Might or might not work on other iOS version.

## Bonus
This [Shortcut](https://www.dropbox.com/s/4kpjwbnbd7gwtu5/Simulates%20Location.shortcut?dl=0) allow you to pick any location on Maps.app and simulate it (requires localhost ssh and change port and password accordingly).

## References
- Hines, L. (2014, October 18). Custom GPS data in the IOS simulator. Custom GPS data in the iOS simulator. Retrieved December 15 2021, from https://bottleofcode.com/posts/custom-gps-data-in-the-ios-simulator/
## License
All source code in this repository are licensed under GPLv3, unless stated otherwise.

Copyright (c) 2021 udevs