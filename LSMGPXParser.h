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

@interface LSMGPXParser : NSObject <NSXMLParserDelegate>{
	NSMutableDictionary *_processingElement;
	NSDictionary *_lastProcessingElement;
	NSMutableArray *_processingTracks;
	NSMutableString *_parsedString;
	double _lastEpoch;
}
@property(nonatomic, strong) NSArray *tracks;
@property(nonatomic, assign) double hAccuracy;
@property(nonatomic, assign) double vAccuracy;
@property(nonatomic, assign) double lifeSpan;
@property(nonatomic, assign) int type;
@property(nonatomic, assign) double averageSpeed;
@property(nonatomic, assign) unsigned char locationDeliveryBehavior;
@property(nonatomic, assign) unsigned char locationRepeatBehavior;
-(NSArray <NSData *>*)encodedTracks;
-(NSDictionary *)scenario;
@end
