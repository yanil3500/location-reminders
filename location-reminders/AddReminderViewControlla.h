//
//  AddReminderViewControlla.h
//  location-reminders
//
//  Created by Elyanil Liranzo Castro on 5/2/17.
//  Copyright © 2017 Elyanil Liranzo Castro. All rights reserved.
//

#import <UIKit/UIKit.h>

@import MapKit;

typedef void(^NewReminderCreatedCompletionHandler)(MKCircle *);


@interface AddReminderViewControlla : UIViewController

@property(strong, nonatomic) NSString *annotationTitle;
@property(nonatomic) CLLocationCoordinate2D coordinate;

@property(strong, nonatomic) NewReminderCreatedCompletionHandler completion;

@end
