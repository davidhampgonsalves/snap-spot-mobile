//
//  ViewController.swift
//  snapspot
//
//  Created by david on 16/05/2015.
//  Copyright (c) 2015 davidhampgonsalves. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    var locationManager:CLLocationManager = CLLocationManager()
    var locationCount:Int = 0
    
    var currentTripUUID:String = ""
    var currentTripSecret:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func startSharingLocation() {
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = 10
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.activityType = CLActivityType.Fitness
        self.locationManager.requestAlwaysAuthorization()
        
        let manager = CLLocationManager()
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.requestAlwaysAuthorization()
        }
    }
    

    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            manager.requestAlwaysAuthorization()
            break
        case .AuthorizedAlways:
            println(".Authorized")
            self.locationManager.startUpdatingLocation()
            break
        case .AuthorizedWhenInUse, .Restricted, .Denied:
            let alertController = UIAlertController(
                title: "Background Location Access Disabled",
                message: "In order to share your location, please open this app's settings and set location access to 'Always'.",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
        default:
            println("Unhandled authorization status")
            break
            
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        for location in locations {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            statusLabel.text = "\(locationCount) locations, \(lat), \(lon)"
            locationCount += 1
            
            let url = NSURL(string: "http://192.241.229.86:9000/position/add/\(self.currentTripUUID)?secret=\(self.currentTripSecret)&lat=\(lat)&lon=\(lon)&order=\(locationCount)")
            let request = NSURLRequest(URL: url!)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
                let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [String:AnyObject]
                println("added location to trip \(self.currentTripUUID) \(self.currentTripSecret)")
            }
        }
    }

    @IBOutlet weak var endTripButton: UIButton!
    @IBOutlet weak var shareTripButton: UIButton!
    func startTrip(uuid: String) {
        let url = NSURL(string: "http://192.241.229.86:9000/trip/create/\(uuid)?duration=30")
        let request = NSURLRequest(URL: url!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [String:AnyObject]
            
            let secret = json?["secret"] as? String
            self.currentTripUUID = uuid
            self.currentTripSecret = secret!
            self.statusLabel.text = "Shared trip with secret \(secret)"
            println("got secret \(secret)")

            self.endTripButton.hidden = false
            self.shareTripButton.setTitle("Share again", forState: UIControlState.Normal)
        }
    }
    
    @IBAction func endTripPressed(sender: UIButton) {
        endTripButton.hidden = true
        self.shareTripButton.setTitle("Share location", forState: UIControlState.Normal)
        let url = NSURL(string: "http://192.241.229.86:9000/trip/update/\(self.currentTripUUID)?secret=\(self.currentTripSecret)&duration=0")
        let request = NSURLRequest(URL: url!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error)in
            let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [String:AnyObject]

            if let err = json?["error"] as? String {
                self.endTripButton.hidden = false
                self.shareTripButton.setTitle("Share again", forState: UIControlState.Normal)

                // Should create helper for this
                let alert = UIAlertController(title: "Error", message: err, preferredStyle: UIAlertControllerStyle.Alert)
                let alertAction = UIAlertAction(title: "OK!", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in }
                alert.addAction(alertAction)
                self.presentViewController(alert, animated: true) { () -> Void in }
            }
        }
        self.locationManager.stopUpdatingLocation()
    }
    
    @IBAction func startPressed(sender: UIButton) {
        let tripUUID:String = NSUUID().UUIDString
        let msg = "I've shared my location with you www.snapspot.ca/\(tripUUID)"
        let activityVC = UIActivityViewController(activityItems: [msg], applicationActivities: nil)
        self.presentViewController(activityVC, animated: true, completion: nil)
        activityVC.completionWithItemsHandler = {(activityType:String!, completed:Bool, items:[AnyObject]!, err:NSError!) in
            if !completed {
                self.statusLabel.text = "Trip not shared :("
                println("trip not shared")
                return
            }
            
            // create trip
            self.startTrip(tripUUID)
        }
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

