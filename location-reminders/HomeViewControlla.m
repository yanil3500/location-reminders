//
//  ViewController.m
//  location-reminders
//
//  Created by Elyanil Liranzo Castro on 5/1/17.
//  Copyright © 2017 Elyanil Liranzo Castro. All rights reserved.
//

#import "HomeViewControlla.h"

#import "AddReminderViewControlla.h"

#import "LocationControllaDelegate.h"

#import "CustomMKPinAnnotationView.h"

#import "LocationControlla.h"

#import "Reminder.h"


@import Parse;
@import MapKit;
@import ParseUI;

@interface HomeViewControlla () <MKMapViewDelegate, LocationControllaDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>


@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSMutableArray *locationOverlays;
@property (weak, nonatomic) IBOutlet UISwitch *hideAndShowSwitch;

@end

@implementation HomeViewControlla
- (IBAction)dropPin:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [sender locationInView:self.mapView];
        
        CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        
        NSLog(@"The coordinate of tapped location: Lat:%f Lon: %f", coordinate.latitude, coordinate.longitude);
        
        [self setCustomAnnotationsWithTitle:@"Reminder" andLatitude:coordinate.latitude AndLongitude:coordinate.longitude];

    }
}
- (IBAction)hideAndShowReminders:(UISwitch *)sender {
    if([sender isOn]){
        [self.mapView addOverlays:self.locationOverlays];
        NSLog(@"ON Overlaycount: %lu",(unsigned long)[[[self mapView] overlays] count]);
    } else {
//        self.locationOverlays = [[self.mapView overlays] copy];
        [self.mapView removeOverlays:self.mapView.overlays];
        NSLog(@"OFF");
    }
}

- (IBAction)selectMapType:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex){
        case 0:
            [self changeMapView:MKMapTypeStandard];
            break;
        case 1:
            [self changeMapView:MKMapTypeHybrid];
            break;
        case 2:
            [self changeMapView:MKMapTypeSatellite];
            break;
        default:
            break;
    }
}

- (IBAction)segmentedControl:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex){
        case 0:
            [self setLocationWithLatitude:43.8791 AndLongitude:-103.4591];
            [self setCustomAnnotationsWithTitle:@"Mount Rushmore"
                                    andLatitude:43.8791
                                   AndLongitude:-103.4591];
            break;
        case 1:
            [self setLocationWithLatitude:34.0928 AndLongitude:-118.3287];
            [self setCustomAnnotationsWithTitle:@"Hollywood"
                                    andLatitude:34.0928
                                   AndLongitude:-118.3287];
            break;
        case 2:
            [self setLocationWithLatitude:48.8584 AndLongitude:2.2945];
            [self setCustomAnnotationsWithTitle:@"Eiffel Tower"
                                    andLatitude:48.8584
                                   AndLongitude:2.2945];
        default:
            break;
            
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationItem] setTitle:@"Reminders"];
    [[self mapView] setDelegate: self];
    
    [[self mapView] setShowsUserLocation:YES];
    self.locationOverlays = [[NSMutableArray alloc] init];
    [LocationControlla shared].delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reminderSavedToParse:) name:@"ReminderSavedToParse" object:nil];
    
    if (![PFUser currentUser]) {
        PFLogInViewController *loginViewControlla = [[PFLogInViewController alloc] init];
        [loginViewControlla setFields: PFLogInFieldsDefault | PFLogInFieldsFacebook];
        [loginViewControlla setDelegate:self];
        

        [[loginViewControlla signUpController] setDelegate:self];
        [self presentViewController:loginViewControlla animated:YES completion:nil];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if ([self locationOverlays].count == 0) {
        [self fetchReminders];
    }
    
}



-(void)reminderSavedToParse:(id)sender{
    NSLog(@"New reminder saved to Parse: %@",sender);
}

#pragma LocationControllaDelegate

-(void)locationControllaUpdatedLocation:(CLLocation *)location{
    [self setLocationWithLatitude:location.coordinate.latitude AndLongitude:location.coordinate.longitude];
    NSLog(@"locationController: lat: %2f lon: %2f",location.coordinate.latitude, location.coordinate.longitude);
}


#pragma MapKit helper methods
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [super prepareForSegue:segue sender:sender];
    if ([[segue identifier] isEqualToString:@"AddReminderViewControlla"] && [sender isKindOfClass:[MKAnnotationView class]]) {
        CustomMKPinAnnotationView *annotationView = (CustomMKPinAnnotationView *)sender;
        AddReminderViewControlla *destinationController = (AddReminderViewControlla *)segue.destinationViewController;
        [destinationController setCoordinate:annotationView.annotation.coordinate];
        [destinationController setAnnotationTitle:annotationView.annotation.title];
        
        [destinationController setTitle:@"New Location"];
        
        //create a weak connection
        //This is used only when refencing self in the completion block; Avoid retain cycle (circular reference)
        __weak typeof(self) bruce = self;
        destinationController.completion = ^(MKCircle *circle) {
            //Make the reference to the home vc strong for the scope of this block.
            __strong typeof(bruce) hulk = bruce;
            [[hulk mapView] removeAnnotation:annotationView.annotation];
//            [[hulk mapView] addOverlay:circle];
            [hulk.locationOverlays addObject:circle];
            [hulk hideAndShowReminders:hulk.hideAndShowSwitch];
            
        };
    }
}


#pragma override dealloc as part of NSNotificationCenter

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ReminderSavedToParse" object:nil];
}



-(void)setLocationWithLatitude:(CGFloat)latitude AndLongitude:(CGFloat)longitude{

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 500.00, 500.00);
    [[self mapView] setRegion:region animated:YES];
}

-(void)changeMapView:(MKMapType)mapType{
    [[self mapView]setMapType:mapType];
}


-(void)setCustomAnnotationsWithTitle:(NSString *)title andLatitude:(CGFloat)latitude AndLongitude:(CGFloat)longitude {
    
    CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(latitude, longitude);
    
    MKPointAnnotation *annotation;
    
    BOOL hasAnnotation = NO;
    for (MKPointAnnotation *a in self.mapView.annotations) {
        if ((a.coordinate.latitude == coordinates.latitude) && (a.coordinate.longitude == coordinates.longitude)) {
            annotation = a;
            hasAnnotation = YES;
        }
    }
    if (!hasAnnotation) {
        annotation = [[MKPointAnnotation alloc] init];
        [annotation setCoordinate: coordinates];
        [annotation setTitle: title];
        
        [[self mapView] addAnnotation:annotation];
    }
    [[self mapView] selectAnnotation:annotation animated:YES];
    
}


-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    NSLog(@"The callout button associated with %@", view.annotation.title);
    [self performSegueWithIdentifier:@"AddReminderViewControlla" sender:view];
}


-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    CustomMKPinAnnotationView *myAnnotationView = (CustomMKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];
    if (!myAnnotationView){
        //Random color generator
        myAnnotationView = [[CustomMKPinAnnotationView alloc] initWithTitle:annotation.title withAnnotation:annotation andTintColor:[UIColor colorWithHue:drand48() saturation:1.0 brightness:1.0 alpha:1.0]];
    }
    [myAnnotationView setAnimatesDrop:YES];
    return myAnnotationView;
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:overlay];
    
    [renderer setStrokeColor:[UIColor grayColor]];
    [renderer setFillColor:[UIColor colorWithHue:drand48() saturation:1.0 brightness:1.0 alpha:1.0]];
    [renderer setAlpha:0.5];
    return renderer;
}

#pragma PFLoginViewControllerDelegate

-(void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user{
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma PFSignUpViewControllerDelegate
-(void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user{
    [self dismissViewControllerAnimated:YES completion:nil];
}





#pragma PFFetchAllReminders
-(void)fetchReminders{
    PFQuery *remindersQuery = [PFQuery queryWithClassName:@"Reminder"];
    
    [remindersQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to get reminders: Error %@",error.localizedDescription);
        }
        for (Reminder *reminder in objects) {
            [self allRemindersToMap:reminder];
        }
    }];
    
}

-(void)allRemindersToMap:(Reminder *)reminder{
    BOOL hasAnnotation = NO;
    for (MKCircle *overlay in self.mapView.overlays) {
        if ((overlay.coordinate.latitude == reminder.location.latitude) && (overlay.coordinate.longitude == reminder.location.longitude)) {
            hasAnnotation = YES;
        }
    }
    if (!hasAnnotation) {
        CGFloat radius = [[reminder radius] floatValue];
        [[reminder location] latitude];
        CLLocationCoordinate2DMake([[reminder location] latitude], [[reminder location] longitude]);
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:CLLocationCoordinate2DMake([[reminder location] latitude], [[reminder location] longitude]) radius:radius];
        [self.locationOverlays addObject:circle];
        [self hideAndShowReminders:self.hideAndShowSwitch];
//        [[self mapView] addOverlay:circle];
    }
    
}
@end
