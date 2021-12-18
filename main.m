//    Copyright (c) 2021 udevs
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, version 3.
//
//    This program is distributed in the hope that it will be useful, but
//    WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//    General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program. If not, see <http://www.gnu.org/licenses/>.

#import <stdio.h>
#import <getopt.h>
#import <libgen.h>
#import <string.h>
#import <stdlib.h>
#import <spawn.h>
#import "macros.h"
#import <CoreLocation/CoreLocation.h>
#import "LSMGPXParserDelegate.h"
#import "PrivateHeaders.h"

#define HELP_OPT 900
#define PLIST_OPT 500
#define EXPORT_PLIST_OPT 501
#define EXPORT_PLIST_ONLY_OPT 502
#define SPEED_ACCURACY_OPT 503
#define COURSE_ACCURACY_OPT 504

#define TEMP_DIR @"/tmp/"

static void post_required_timezone_update(){
	//try our best to update time zone instantly, though it totally depends on whether xpc server (locationd) did update the location before we post this, especially with stop_loc_sim()
	CFNotificationCenterPostNotificationWithOptions(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("AutomaticTimeZoneUpdateNeeded"), NULL, NULL, kCFNotificationDeliverImmediately);
}

static void start_loc_sim(CLLocation *loc){
	CLSimulationManager *simManager = [[CLSimulationManager  alloc] init];
	[simManager stopLocationSimulation];
	[simManager clearSimulatedLocations];
	[simManager appendSimulatedLocation:loc];
	[simManager flush];
	[simManager startLocationSimulation];
	post_required_timezone_update();
}

static void start_scenario_sim(NSString *path){
	CLSimulationManager *simManager = [[CLSimulationManager  alloc] init];
	[simManager stopLocationSimulation];
	[simManager clearSimulatedLocations];
	[simManager loadScenarioFromURL:[NSURL fileURLWithPath:path]];
	[simManager flush];
	[simManager startLocationSimulation];
	post_required_timezone_update();
}

static void stop_loc_sim(){
	CLSimulationManager *simManager = [[CLSimulationManager  alloc] init];
	[simManager stopLocationSimulation];
	[simManager clearSimulatedLocations];
	[simManager flush];
	post_required_timezone_update();
}

static NSArray <NSArray *>* world_capital_coor_arr(){
	return WORLD_CAPITAL_COOR_ARRAY;
}

static CLLocationCoordinate2D rand_world_capital_coor(){
	NSArray *coords = world_capital_coor_arr();
	srand(time(NULL));
	int rdi = rand() % coords.count;
	NSArray *coor = coords[rdi];
	return CLLocationCoordinate2DMake([coor.firstObject doubleValue], [coor.lastObject doubleValue]);
}


static void print_help(){
	PRINT("Usage: locsim <SUBCOMMAND> [LATITUDE] [LONGITUDE] [OPTIONS]\n"
			"if LATITUDE and LONGITUDE not specified, random values will be generated\n\n"
			"SUBCOMMAND:\n"
			"	start	start location simulation\n"
			"	stop	stop location simulation\n"
			"OPTIONS:\n"
			"	-x, --latitude <double>: latitude of geographical coordinate\n"
			"	-y, --longitude <double>: longitude of geographical coordinate\n"
			"	-a, --altitude <double>: location altitude\n"
			"	-h, --haccuracy <double>: radius of uncertainty for the geographical coordinate, measured in meters\n"
			"	-v, --vaccuracy <double>: accuracy of the altitude value, measured in meters\n"
			"	-s, --speed <double>: speed, or override average speed if -g specified, measured in m/s\n"
			"	    --saccuracy <double>: accuracy of the speed value, measured in m/s\n"
			"	-c, --course <double>: direction values measured in degrees\n"
			"	    --caccuracy <double>: accuracy of the course value, measured in degress\n"
			"	-t, --time <double>: epoch time to associate with the location\n"
			"	-f, --force: force stop simulation, requires root access\n"
			"	--help: show this help\n"
			"ADDITIONAL GPX OPTIONS:\n"
			"	-g, --gpx <file>: gpx file path\n"
			"	    --plist <file>: exported or valid plist file path\n"
			"	-l, --lifespan <double>: lifespan\n"
			"	-p, --type <int>: type\n"
			"	-d, --delivery <int>: location delivery behaviour\n"
			"	-r, --repeat <int>: location repeat behaviour\n"
			"	--export-plist <file>: export converted gpx file to plist\n"
			"	--export-only: export converted gpx file to plist without running simulation\n"
			);
	exit(-1);
}

int main(int argc, char *argv[], char *envp[]) {
	
	static struct option longopts[] = {
		{ "latitude", required_argument, 0, 'x' },
		{ "longitude", required_argument, 0, 'y' },
		{ "altitude", required_argument, 0, 'a' },
		{ "haccuracy", required_argument, 0, 'h' },
		{ "vaccuracy", required_argument, 0, 'v' },
		{ "time", required_argument, 0, 't' },
		{ "force", required_argument, 0, 'f' },
		{ "gpx", required_argument, 0, 'g' },
		{ "speed", required_argument, 0, 's' },
		{ "saccuracy", required_argument, 0, SPEED_ACCURACY_OPT },
		{ "course", required_argument, 0, 'c' },
		{ "caccuracy", required_argument, 0, COURSE_ACCURACY_OPT },
		{ "lifespan", required_argument, 0, 'l' },
		{ "type", required_argument, 0, 'p' },
		{ "delivery", required_argument, 0, 'd' },
		{ "repeat", required_argument, 0, 'r' },
		{ "plist", required_argument, 0, PLIST_OPT },
		{ "export-plist", required_argument, 0, EXPORT_PLIST_OPT },
		{ "export-only", no_argument, 0, EXPORT_PLIST_ONLY_OPT },
		{ "help", no_argument, 0, HELP_OPT},
		{ 0, 0, 0, 0 }
	};
	
	CLLocationCoordinate2D coor = rand_world_capital_coor();
	CLLocationDistance alt = 0.0;
	CLLocationAccuracy ha = 0.0;
	CLLocationAccuracy va = 0.0;
	NSDate *ts = [NSDate date];
	double s = -1.0;
	double c = -1.0;
	BOOL force = NO;
	
	//gpx
	NSString *gpx;
	double l = -1.0;
	double sa = -1.0;
	double ca = -1.0;
	int p = -1;
	int ldb = -1;
	int lrb = -1;
	NSString *plist;
	NSString *exportPlist;
	BOOL exportOnly = NO;
	
	int opt;
	while ((opt = getopt_long(argc, argv, "x:y:a:h:v:t:fg:s:l:p:d:r:c:", longopts, NULL)) != -1){
		switch (opt){
			case 'x':
				coor.latitude = [@(optarg) doubleValue];
				break;
			case 'y':
				coor.longitude = [@(optarg) doubleValue];
				break;
			case 'a':
				alt = [@(optarg) doubleValue];
				break;
			case 'h':
				ha = [@(optarg) doubleValue];
				break;
			case 'v':
				va = [@(optarg) doubleValue];
				break;
			case 't':
				ts = [NSDate dateWithTimeIntervalSince1970:[@(optarg) doubleValue]];
				break;
			case 'f':
				force = YES;
				break;
			case 'g':
				gpx = @(optarg);
				break;
			case 's':
				s = [@(optarg) doubleValue];
				break;
			case 'c':
				c = [@(optarg) doubleValue];
				break;
			case 'l':
				s = [@(optarg) doubleValue];
				break;
			case 'p':
				p = [@(optarg) intValue];
				break;
			case 'd':
				ldb = [@(optarg) intValue];
				break;
			case 'r':
				lrb = [@(optarg) intValue];
				break;
			case EXPORT_PLIST_OPT:
				exportPlist = @(optarg);
				break;
			case PLIST_OPT:
				plist = @(optarg);
				break;
			case EXPORT_PLIST_ONLY_OPT:
				exportOnly = YES;
				break;
			case SPEED_ACCURACY_OPT:
				sa = [@(optarg) doubleValue];
				if (@available(iOS 13.4, *)); else WARNING("WARNING: --saccuracy not available, flag ignored\n");
				break;
			case COURSE_ACCURACY_OPT:
				ca = [@(optarg) doubleValue];
				if (@available(iOS 13.4, *)); else WARNING("WARNING: --aaccuracy not available, flag ignored\n");
				break;
			default:
				print_help();
				break;
		}
	}
	
	argc -= optind;
	argv += optind;
	
	if (argc < 1) print_help();
	
	if (argc > 2){
		coor.latitude = [@(argv[1]) doubleValue];
		coor.longitude = [@(argv[2]) doubleValue];
	}
	
	if (strcasecmp(argv[0], "start") == 0){
		
		if (plist.length > 0){
			if (access(strdup(plist.UTF8String), F_OK) != 0){
				NSString *plistExt = [NSString stringWithFormat:@"%@.plist", plist];
				if (access(strdup(plistExt.UTF8String), F_OK) != 0){
					ERROR("ERROR: \"%s\" does not exist!\n", plist.UTF8String);
					return 2;
				}else{
					WARNING("WARNING: \"%s\" does not exist, instead uses \"%s\" as input\n", plist.UTF8String, plistExt.UTF8String);
					plist = plistExt;
				}
			}
			if (![plist.pathExtension isEqualToString:@"plist"]) {ERROR("ERROR: \"%s\" is not a plist file, file must end with .plist extension!\n", plist.UTF8String); return 3;}
			start_scenario_sim(plist);
		}else if (gpx.length > 0){
			if (access(strdup(gpx.UTF8String), F_OK) != 0) {ERROR("ERROR: \"%s\" does not exist!\n", gpx.UTF8String); return 2;}
			
			NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:gpx]];
			
			LSMGPXParserDelegate *gpxParserDelegate = [LSMGPXParserDelegate new];
			gpxParserDelegate.averageSpeed = s > 0 ? s : gpxParserDelegate.averageSpeed;
			gpxParserDelegate.hAccuracy = ha > 0 ? ha : gpxParserDelegate.hAccuracy;
			gpxParserDelegate.vAccuracy = va > 0 ? va : gpxParserDelegate.vAccuracy;
			gpxParserDelegate.lifeSpan = l > 0 ? l : gpxParserDelegate.lifeSpan;
			gpxParserDelegate.locationDeliveryBehavior =  ldb > 0 ? ldb : gpxParserDelegate.locationDeliveryBehavior;
			gpxParserDelegate.locationRepeatBehavior =  lrb > 0 ? lrb : gpxParserDelegate.locationRepeatBehavior;
			
			[xmlParser setDelegate:gpxParserDelegate];
			[xmlParser parse];
			
			NSString *output = [NSString stringWithFormat:@"%@%@.plist", TEMP_DIR, @(gpx.hash).stringValue];
			if (exportPlist.length > 0){
				if (access(strdup(dirname((char *)exportPlist.UTF8String)), W_OK) != 0) {ERROR("ERROR: \"%s\" not writable, check permissions!\n", exportPlist.UTF8String); return 2;}
				if (![exportPlist.pathExtension isEqualToString:@"plist"]) exportPlist = [NSString stringWithFormat:@"%@.plist", exportPlist];
				output = exportPlist;
			}
			[[gpxParserDelegate scenario] writeToFile:output atomically:NO];
			if (exportPlist.length > 0) {PRINT("Exported to \"%s\"\n", output.UTF8String);}
			if (!exportOnly) start_scenario_sim(output);
		}else{
			if (!CLLocationCoordinate2DIsValid(coor)) {ERROR("ERROR: Invalid coordinate!\n"); return 1;}
			s = s > 0 ? s : 0.0;
			CLLocation *loc;
			if (@available(iOS 13.4, *)){
				loc = [[CLLocation alloc] initWithCoordinate:coor altitude:alt horizontalAccuracy:ha verticalAccuracy:va course:c courseAccuracy:ca speed:s speedAccuracy:sa timestamp:ts];
			}else{
				loc = [[CLLocation alloc] initWithCoordinate:coor altitude:alt horizontalAccuracy:ha verticalAccuracy:va course:c speed:s timestamp:ts];
			}
			start_loc_sim(loc);
			PRINT("latitude: %f\nlongitude: %f\naltitude: %f\nhorizontal accuracy: %f\nvertical accuracy: %f\nspeed: %f\nspeed accuracy: %f\ncourse: %f\ncourse accuracy: %f\ntimestamp: %s\n", coor.latitude, coor.longitude, alt, ha, va, s, sa, c, ca, [NSDateFormatter localizedStringFromDate:ts dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterFullStyle].UTF8String);
		}
	}else if (strcasecmp(argv[0], "stop") == 0){
		if (force){
			if (getuid() == 0){
				pid_t pid;
				int status;
				const char *args[] = {"killall", "-9", "locationd", NULL};
				posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char * const *)args, NULL);
				waitpid(pid, &status, WEXITED);
			}else{
				WARNING("WARNING: -f, --force requires root access, flag ignored\n");
				stop_loc_sim();
			}
		}else{
			stop_loc_sim();
		}
	}else{
		print_help();
	}
	
	return 0;
}
