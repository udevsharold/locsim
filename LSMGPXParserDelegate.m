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

#import <CoreLocation/CoreLocation.h>
#import "LSMGPXParserDelegate.h"
#import "macros.h"

@implementation LSMGPXParserDelegate

-(instancetype)init{
	if (self = [super init]){
		self.hAccuracy = 0.0;
		self.vAccuracy = 0.0;
		self.lifeSpan = 30.0;
		self.type = 1;
		self.averageSpeed = 0.0;
		self.locationDeliveryBehavior = 2;
		self.locationRepeatBehavior = 0;
	}
	return self;
}

-(void)parserDidStartDocument:(NSXMLParser *)parser{
	_processingElement = [NSMutableDictionary dictionary];
	_processingTracks = [NSMutableArray array];
	_parsedString = [NSMutableString string];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
	if ([elementName isEqualToString:@"trkpt"]){
		_processingElement = [NSMutableDictionary dictionary];
		_processingElement[@"lat"] = attributeDict[@"lat"];
		_processingElement[@"lon"] = attributeDict[@"lon"];
	}else if ([elementName isEqualToString:@"ele"]){
		_parsedString = [NSMutableString string];
	}else if ([elementName isEqualToString:@"time"]){
		_parsedString = [NSMutableString string];
	}
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	if(_parsedString){
		[_parsedString appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
	if ([elementName isEqualToString:@"trkpt"]){
		if (!_processingElement[@"time"] || self.averageSpeed > 0){
			if (_lastEpoch > 0){
				double lat = [_processingElement[@"lat"] doubleValue];
				double lon = [_processingElement[@"lon"] doubleValue];
				CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
				
				double prevLat = [_lastProcessingElement[@"lat"] doubleValue];
				double prevLon = [_lastProcessingElement[@"lon"] doubleValue];
				CLLocation *prevLoc = [[CLLocation alloc] initWithLatitude:prevLat longitude:prevLon];
				CLLocationDistance prevDistance = [loc distanceFromLocation:prevLoc];
				_lastEpoch = _lastEpoch + (prevDistance / self.averageSpeed);
			}else{
				_lastEpoch = [NSDate date].timeIntervalSince1970;
			}
			_processingElement[@"time"] = @(_lastEpoch).stringValue;
		}
		[_processingTracks addObject:_processingElement];
		_lastProcessingElement = _processingElement.copy;
	}else if ([elementName isEqualToString:@"ele"]){
		_processingElement[@"ele"] = _parsedString;
	}else if ([elementName isEqualToString:@"time"]){
		_lastEpoch = [[NSISO8601DateFormatter new] dateFromString:_parsedString].timeIntervalSince1970;
		_processingElement[@"time"] = @(_lastEpoch).stringValue;
	}
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{
	self.tracks = _processingTracks.copy;
}

#define DEG2RAD(x) (x * M_PI / 180.0)
#define RAD2DEG(x) (x * 180.0 / M_PI)

-(NSArray <NSData *>*)encodedTracks{
	NSMutableArray *encodedTracks = [NSMutableArray array];
	NSString *archivedCLLocBase = ENCODED_CLLOCATION_BASE;
	NSUInteger totalTracksCount = self.tracks.count;
	
	double lastCourse = 0.0;
	
	for (int i = 0; i < totalTracksCount; i++){
		
		double speed = 0.0;
		double course = 0.0;
		
		NSDictionary *track = self.tracks[i];
		double lat = [track[@"lat"] doubleValue];
		double lon = [track[@"lon"] doubleValue];
		double time = [track[@"time"] ?: 0 doubleValue];
		
		CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
		
		
		double prevSpeed = 0.0;
		double nextSpeed = 0.0;
		int avg = 0;
		
		if (i > 0){
			NSDictionary *prevTrack = self.tracks[i - 1];
			double prevLat = [prevTrack[@"lat"] doubleValue];
			double prevLon = [prevTrack[@"lon"] doubleValue];
			double prevTime = [prevTrack[@"time"] ?: 0 doubleValue];
			
			CLLocation *prevLoc = [[CLLocation alloc] initWithLatitude:prevLat longitude:prevLon];
			CLLocationDistance prevDistance = [loc distanceFromLocation:prevLoc];
			prevSpeed = prevDistance / (time - prevTime);
			avg++;
		}
		
		if (i < totalTracksCount - 1){
			NSDictionary *nextTrack = self.tracks[i + 1];
			double nextLat = [nextTrack[@"lat"] doubleValue];
			double nextLon = [nextTrack[@"lon"] doubleValue];
			double nextTime = [nextTrack[@"time"] ?: 0 doubleValue];
			
			CLLocation *nextLoc = [[CLLocation alloc] initWithLatitude:nextLat longitude:nextLon];
			CLLocationDistance nextDistance = [loc distanceFromLocation:nextLoc];
			nextSpeed = nextDistance / (nextTime - time);
			avg++;
			
			double y = (sin(DEG2RAD(nextLon) - DEG2RAD(lon))) * cos(DEG2RAD(nextLat));
			double x = (cos(DEG2RAD(lat)) * sin(DEG2RAD(nextLat))) - (sin(DEG2RAD(lat)) * cos(DEG2RAD(nextLat)) * cos(DEG2RAD(nextLon) - DEG2RAD(lon)));
			course = fmod(RAD2DEG(atan2(y, x)) + 360, 360.0);
			lastCourse = course;
		}
		
		speed = self.averageSpeed > 0 ? self.averageSpeed : (prevSpeed + nextSpeed) / (double)avg;
		
		if (i == totalTracksCount - 1){
			course = lastCourse;
		}
		
		//+[NSKeyedArchiver archivedDataWithRootObject:requiringSecureCoding:error:] of CLLocation doesn't seems to work
		//Reference: https://bottleofcode.com/posts/custom-gps-data-in-the-ios-simulator/
		NSString *archivedLoc = archivedCLLocBase.copy;
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"ALTPLACE" withString:(track[@"ele"] ?: @"0")];
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"LATPLACE" withString:track[@"lat"]];
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"LONGPLACE" withString:track[@"lon"]];
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"COURSEPLACE" withString:@(course).stringValue];
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"HORZACPLACE" withString:@(self.hAccuracy).stringValue];
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"LIFESPAPLACE" withString:@(self.lifeSpan).stringValue];
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"SPEEDPLACE" withString:@(speed).stringValue];
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"TIMESTAMPPLACE" withString:track[@"time"]];
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"TYPEPLACE" withString:@(self.type).stringValue];
		archivedLoc = [archivedLoc stringByReplacingOccurrencesOfString:@"VERTACPLACE" withString:@(self.vAccuracy).stringValue];
		NSData *data = [archivedLoc dataUsingEncoding:NSUTF8StringEncoding];
		[encodedTracks addObject:data];
	}
	return encodedTracks.copy;
}

-(NSDictionary *)scenario{
	return @{
		@"Locations":[self encodedTracks],
		@"Options":@{
				@"LocationDeliveryBehavior":@(self.locationDeliveryBehavior),
				@"LocationRepeatBehavior":@(self.locationRepeatBehavior)
		}
	};
}

@end
