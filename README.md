# locsim
A tool to simulate GPS location system-wide. This tool simulates GPS location nativitely without any runtime injection, and it's how Apple do it.

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
	-t, --time <double>: epoch time to associate with the location
	--help: show this help
```


## Compatibility
This package tested to be working on iOS 14.3. Might or might not work on other iOS version.

## License
All source code in this repository are licensed under GPLv3, unless stated otherwise.

Copyright (c) 2021 udevs