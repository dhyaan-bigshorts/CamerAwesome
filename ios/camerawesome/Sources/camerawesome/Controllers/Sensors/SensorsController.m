//
//  SensorsController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 28/03/2023.
//

#import "SensorsController.h"
#import "Pigeon.h"

@implementation SensorsController

+ (NSArray *)getSensors:(AVCaptureDevicePosition)position {
  NSMutableArray *sensors = [NSMutableArray new];
  
  // Make sure we're properly specifying all camera types
  NSArray *sensorsType = @[
    AVCaptureDeviceTypeBuiltInWideAngleCamera, 
    AVCaptureDeviceTypeBuiltInTelephotoCamera, 
    AVCaptureDeviceTypeBuiltInUltraWideCamera, 
    AVCaptureDeviceTypeBuiltInTrueDepthCamera,
    AVCaptureDeviceTypeBuiltInDualCamera,
    AVCaptureDeviceTypeBuiltInDualWideCamera,
    AVCaptureDeviceTypeBuiltInTripleCamera
  ];
  
  // Use explicit position instead of unspecified
  AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                       discoverySessionWithDeviceTypes:sensorsType
                                                       mediaType:AVMediaTypeVideo
                                                       position:position];
  
  // Add debugging log to see all devices found
  NSLog(@"Searching for camera sensors at position: %@", position == AVCaptureDevicePositionBack ? @"back" : @"front");
  
  for (AVCaptureDevice *device in discoverySession.devices) {
    PigeonSensorType type;
    if (device.deviceType == AVCaptureDeviceTypeBuiltInTelephotoCamera) {
      type = PigeonSensorTypeTelephoto;
      NSLog(@"Found telephoto camera: %@", device.localizedName);
    } else if (device.deviceType == AVCaptureDeviceTypeBuiltInUltraWideCamera) {
      type = PigeonSensorTypeUltraWideAngle;
      NSLog(@"Found ultra-wide camera: %@", device.localizedName);
    } else if (device.deviceType == AVCaptureDeviceTypeBuiltInTrueDepthCamera) {
      type = PigeonSensorTypeTrueDepth;
      NSLog(@"Found true depth camera: %@", device.localizedName);
    } else if (device.deviceType == AVCaptureDeviceTypeBuiltInWideAngleCamera) {
      type = PigeonSensorTypeWideAngle;
      NSLog(@"Found wide-angle camera: %@", device.localizedName);
    } else {
      type = PigeonSensorTypeUnknown;
      NSLog(@"Found unknown camera type: %@ - %@", device.deviceType, device.localizedName);
    }
    
    PigeonSensorTypeDevice *sensorType = [PigeonSensorTypeDevice makeWithSensorType:type 
                                                                              name:device.localizedName 
                                                                              iso:[NSNumber numberWithFloat:device.ISO] 
                                                                  flashAvailable:[NSNumber numberWithBool:device.flashAvailable] 
                                                                             uid:device.uniqueID];
    
    // Check if the device position matches what we're looking for
    if (device.position == position) {
      [sensors addObject:sensorType];
    } else {
      NSLog(@"Skipping camera because position doesn't match: %@", device.localizedName);
    }
  }
  
  // Log the results
  NSLog(@"Found %lu sensors for position %@", (unsigned long)[sensors count], 
        position == AVCaptureDevicePositionBack ? @"back" : @"front");
  
  // Check specifically for ultra-wide
  BOOL hasUltraWide = NO;
  for (PigeonSensorTypeDevice *sensor in sensors) {
    if (sensor.sensorType == PigeonSensorTypeUltraWideAngle) {
      hasUltraWide = YES;
      break;
    }
  }
  NSLog(@"Ultra-wide camera available: %@", hasUltraWide ? @"true" : @"false");
  
  return sensors;
}
@end
