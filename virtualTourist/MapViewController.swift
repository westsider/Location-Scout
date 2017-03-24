//
//  MapViewController.swift
//  virtualTourist
//
//  Created by Warren Hansen on 10/22/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.
//
//  Extra Features: I added a detail view which allows the user to see the image better. This changes the way deleting a photo works. The used must tap edit to delete an image.

//  Tablet Tour, Location Scout, version for Githiub initial commit

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var pins = [Pin]()
    var selectedPin: Pin? = nil
    
    // Flag for editing mode
    var editingPins = false
    
    // Core Data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    var savedRegionLoaded = false
    
    // MARK: - Retrieve Stored Pins
    func fetchAllPins() -> [Pin] {
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        
        // Execute the fetch request
        do {
            return try sharedContext.fetch(fetchRequest)
        } catch {
            print("error in fetch")
            return [Pin]()
        }
    }
    
    // MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Virtual Tourist"
        
        // add user annotation
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.longPress(getstureRecognizer:)))
        uilpgr.minimumPressDuration = 1
        mapView.addGestureRecognizer(uilpgr)
        
        // Set the map view delegate
        mapView.delegate = self
        deleteLabel.isHidden = true
        // load prior pins
        addSavedPinsToMap()
    }
    
    // MARK: - Load Map Region
    override func viewDidAppear(_ animated: Bool) {
        if !savedRegionLoaded {
            if let savedRegion = UserDefaults.standard.object(forKey: "savedMapRegion") as? [String: Double] {
                let center = CLLocationCoordinate2D(latitude: savedRegion["mapRegionCenterLat"]!, longitude: savedRegion["mapRegionCenterLon"]!)
                let span = MKCoordinateSpan(latitudeDelta: savedRegion["mapRegionSpanLatDelta"]!, longitudeDelta: savedRegion["mapRegionSpanLonDelta"]!)
                mapView.region = MKCoordinateRegion(center: center, span: span)
            }
            savedRegionLoaded = true
        }
    }
    
    // MARK: - Region Has Changes
    func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if (recognizer.state == UIGestureRecognizerState.began || recognizer.state == UIGestureRecognizerState.ended) {
                    return true
                }
            }
        }
        return false
    }
    
    // Mark: - Save Map Region
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //print("region did change to \(mapView.region.center)")
        
        if mapViewRegionDidChangeFromUserInteraction() {
            let regionToSave = [
                "mapRegionCenterLat": mapView.region.center.latitude,
                "mapRegionCenterLon": mapView.region.center.longitude,
                "mapRegionSpanLatDelta": mapView.region.span.latitudeDelta,
                "mapRegionSpanLonDelta": mapView.region.span.longitudeDelta
            ]
            UserDefaults.standard.set(regionToSave, forKey: "savedMapRegion")
        }
    }
    
    // MARK: - edit button
    @IBAction func editButtonClicked(_ sender: UIBarButtonItem) {
        if editingPins == false {
            editingPins = true
            deleteLabel.isHidden = false
            navigationItem.rightBarButtonItem?.title = "Done"
        }
        else if editingPins {
            navigationItem.rightBarButtonItem?.title = "Edit"
            editingPins = false
            deleteLabel.isHidden = true
        }
    }
    
    // MARK:  - Add saved pins to the mapView
    func addSavedPinsToMap() {
        
        pins = fetchAllPins()
        //print("\r\nPin count in core data is \(pins.count)")
        
        for pin in pins {
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = pin.pinTitle
            mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: - Set Pin Behavior
    // Reference: http://stackoverflow.com/questions/5182082/mkmapview-drop-a-pin-on-touch
    func longPress(getstureRecognizer: UIGestureRecognizer) {
        // If it's in editing mode, do nothing
        if (editingPins) {
            return
        } else {
            
            if getstureRecognizer.state != .began { return }
            
            let touchPoint = getstureRecognizer.location(in: self.mapView)
            let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchMapCoordinate
            
            let newPin = Pin(lat: annotation.coordinate.latitude, long: annotation.coordinate.longitude, context: sharedContext)
            
            // Saving to core data
            CoreDataStackManager.sharedInstance().saveContext()
            
            // Adding the newPin to the pins array
            pins.append(newPin)
            
            // Adding the newPin to the map
            mapView.addAnnotation(annotation)
            
            // MARK:  Downloading photos for new pin (only download it if it's a new pin)
            FlickrClient.sharedInstance().downloadPhotosForPin(newPin) { (success, error) in }
            
            // Find out the location name based on the coordinates
            let coordinates = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            
            let geoCoder = CLGeocoder()
            
            geoCoder.reverseGeocodeLocation(coordinates, completionHandler: { (placemark, error) -> Void in
                if error != nil {
                    print("Error: \(error!.localizedDescription)")
                    return
                }
                if placemark!.count > 0 {
                    let pm = placemark![0] as CLPlacemark
                    if (pm.locality != nil) && (pm.country != nil) {
                        // Assigning the city and country to the annotation's title
                        annotation.title = "\(pm.locality!), \(pm.country!)"
                    }
                } else {
                    print("Error with placemark")
                }
            })
            
        }
    }
    
    // Mark: - When a pin is tapped, it will transition to the Phone Album View Controller
    // Update the view for the annotation this allows you to intercept taps on the annotation's view (the pin).
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.canShowCallout = false
        
        return annotationView
    }
    
    // MARK: -  Selecting Pin Behavior
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        guard let annotation = view.annotation else { /* no annotation */ return }
        
        let title = annotation.title!
        
        selectedPin = nil
        
        for pin in pins {
            
            if annotation.coordinate.latitude == pin.latitude && annotation.coordinate.longitude == pin.longitude {
                
                selectedPin = pin
                
                if editingPins {
                    sharedContext.delete(selectedPin!)
                    
                    // Deleting selected pin on map
                    self.mapView.removeAnnotation(annotation)
                    
                    // Save the chanages to core data
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                } else {
                    
                    if title != nil {
                        pin.pinTitle = title!
                        
                    } else {
                        pin.pinTitle = "This pin has no name"
                    }
                    // Move to the Phone Album View Controller
                    self.performSegue(withIdentifier: "toThePhotos", sender: nil)
                }
            }
        }
    }
    
    // MARK: - Segue to Photos View Controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toThePhotos") {
            let viewController = segue.destination as! PhotoAlbumViewController
            viewController.pin = selectedPin
        }
    }
}
