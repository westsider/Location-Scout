//
//  PhotoAlbumViewCOntroller.swift
//  virtualTourist
//
//  Created by Warren Hansen on 10/27/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    var imageCache = NSCache<AnyObject, AnyObject>()
    var pin: Pin? = nil
    var isDeleting = false
    var editingFlag = false
    // Array of IndexPath - keeping track of index of selected cells
    var selectedIndexofCollectionViewCells = [IndexPath]()
    //  Core Data Convenience
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    // Fetched Results Controller
    var fetchedResultsController:NSFetchedResultsController<Photos>!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: - Life Cycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomButton.isHidden = false
        noImagesLabel.isHidden = true
        // Load the map
        mapView.delegate = self
        loadMapView()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Fetch Init
        let fetchRequest = NSFetchRequest<Photos>(entityName: "Photos")
        
        let NOC = sharedContext
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!) // crash here
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let frc = NSFetchedResultsController<Photos>(fetchRequest: fetchRequest, managedObjectContext: NOC, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController = frc
        // Perform the fetch
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("\(error)")
        }
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self
        
        // Subscirbe to notification so photos can be reloaded - catches the notification from FlickrConvenient
        NotificationCenter.default.addObserver(self, selector: #selector(PhotoAlbumViewController.photoReload(_:)), name: NSNotification.Name(rawValue: "downloadPhotoImage.done"), object: nil)
    }
    
    // MARK: - Inserting dispatch_async to ensure run in the main thread
    func photoReload(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.collectionView.reloadData()
            
            // If no photos remaining, show the 'New Collection' button
            let numberRemaining = FlickrClient.sharedInstance().numberOfPhotoDownloaded
            if numberRemaining <= 0 {
                self.bottomButton.isHidden = false
            }
        })
    }
    
    // MARK: - Re Fetch
    fileprivate func reFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("reFetch - \(error)")
        }
    }
    
    // MARK: - Delete Photo
    func deletePhoto(_ sender: UIButton){
        
        // I want to know if the cell is selected giving the indexPath
        let indexOfTheItem = sender.layer.value(forKey: "indexPath") as! IndexPath
        
        // Get the photo associated with the indexPath
        let photo = fetchedResultsController.object(at: indexOfTheItem)
        
        // When user deselected it, remove it from the selectedIndexofCollectionViewCells array
        if let index = selectedIndexofCollectionViewCells.index(of: indexOfTheItem){
            selectedIndexofCollectionViewCells.remove(at: index)
        }
        
        // Remove the photo
        sharedContext.delete(photo)
        
        // Save to core data
        CoreDataStackManager.sharedInstance().saveContext()
        
        // Update selected cell
        reFetch()
        collectionView.reloadData()
    }
    
    // MARK: - Reload Photos
    @IBAction func bottomButtonTapped(_ sender: UIButton) {
        
        // Hiding the button once it's tapped, because I want to finish either deleting or reloading first
        bottomButton.isHidden = true
        
        // If deleting flag is true, delete the photo
        if isDeleting == true
        {
            // Removing the photo that user selected one by one
            for indexPath in selectedIndexofCollectionViewCells {
                
                // Get photo associated with the indexPath.
                let photo = fetchedResultsController.object(at: indexPath)
                
                // Remove the photo
                sharedContext.delete(photo)
            }
            
            // Empty the array of indexPath after deletion
            selectedIndexofCollectionViewCells.removeAll()
            
            // Save the chanages to core data
            CoreDataStackManager.sharedInstance().saveContext()
            
            // Update cells
            reFetch()
            collectionView.reloadData()
            
            // Change the button to say 'New Collection' after deletion
            bottomButton.setTitle("New Collection", for: UIControlState())
            bottomButton.isHidden = false
            
            isDeleting = false
            
            // Else "New Collection" button is tapped
        } else {
            
            // 1. Empty the photo album from the previous set
            for photo in fetchedResultsController.fetchedObjects! {
                sharedContext.delete(photo)
            }
            
            // 2. Save the chanages to core data
            CoreDataStackManager.sharedInstance().saveContext()
            
            // 3. Download a new set of photos with the current pin
            FlickrClient.sharedInstance().downloadPhotosForPin(pin!, completionHandler: {
                success, error in
                
                if success {
                   // DispatchQueue.main.async(execute: {
                        CoreDataStackManager.sharedInstance().saveContext()
                        let numPhotos = FlickrClient.sharedInstance().numberOfPhotoDownloaded
                        print("\r\n Photos VC: Success In downloadphotosforpin Num Photos Downloaded: \(numPhotos) >>>>>>>>>>>>>>>> \r\n")
                   // })
                } else {
                    DispatchQueue.main.async(execute: {
                        print("error downloading a new set of photos")
                        self.bottomButton.isHidden = false
                    })
                }
                // Update cells
                DispatchQueue.main.async(execute: {
                    self.reFetch()
                    self.collectionView.reloadData()
                })
                
            })
        }
    }
    
    // MARK: - Load map view
    // I used this reference: http://studyswift.blogspot.com/2014/09/mkpointannotation-put-pin-on-map.html
    func loadMapView() {
        
        let point = MKPointAnnotation()
        
        point.coordinate = CLLocationCoordinate2DMake((pin?.latitude)!, (pin?.longitude)!)
        point.title = pin?.pinTitle
        mapView.addAnnotation(point)
        mapView.centerCoordinate = point.coordinate
        
        // Select the annotation so the title can be shown
        mapView.selectAnnotation(point, animated: true)
        
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: (pin?.latitude)!, longitude: (pin?.longitude)!), span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
    // MARK:  Edit Button
    @IBAction func editButtonTapped(_ sender: AnyObject) {
        
        let numPhotos = FlickrClient.sharedInstance().numberOfPhotoDownloaded
        print("\r\n Photos VC: Edit Button Num Photos Downloaded: \(numPhotos)")
        
        if editingFlag == false {
            editingFlag = true
            navigationItem.rightBarButtonItem?.title = "Done"
            bottomButton.setTitle("Tap photos to delete", for: UIControlState())
        }
            
        else if editingFlag {
            navigationItem.rightBarButtonItem?.title = "Edit"
            editingFlag = false
            bottomButton.isHidden = false
        }
        
    }
    
    // MARK: CollectionView Functions
    // Return the number of photos from fetchedResultsController
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        // If numberOfObjects is not zero, hide the noImagesLabel
        noImagesLabel.isHidden = sectionInfo.numberOfObjects != 0
        
        return sectionInfo.numberOfObjects
    }
    
    // MARK:  - Collection View Functions
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        
        //self.present(<#T##viewControllerToPresent: UIViewController##UIViewController#>, animated: true, completion: nil)
        
        if editingFlag == false{
            
            let myImageViewPage: ImageDetailView = self.storyboard?.instantiateViewController(withIdentifier: "ImageDetailView") as! ImageDetailView
            let photo = fetchedResultsController.object(at: indexPath)
            
            // Pass the selected image
            myImageViewPage.imageData = photo.imageData as! Data
            
            self.navigationController?.pushViewController(myImageViewPage, animated: true)
        }
            
        else if (editingFlag) {
            
            // Configure the UI of the collection item
            let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
            
            // When user deselect the cell, remove it from the selectedIndexofCollectionViewCells array
            if let index = selectedIndexofCollectionViewCells.index(of: indexPath){
                selectedIndexofCollectionViewCells.remove(at: index)
                cell.deleteButton.isHidden = true
            } else {
                // Else, add it to the selectedIndexofCollectionViewCells array
                selectedIndexofCollectionViewCells.append(indexPath)
                cell.deleteButton.isHidden = false
                bottomButton.setTitle("New Collection", for: UIControlState())
            }
            
            // If the selectedIndexofCollectionViewCells array is not empty, show the 'Delete # photo(s)' button
            if selectedIndexofCollectionViewCells.count > 0 {
                
                print("\r\n DidSlectItemAt: Delete array has \(selectedIndexofCollectionViewCells.count) photo(s).")
                if selectedIndexofCollectionViewCells.count == 1{
                    bottomButton.setTitle("Delete \(selectedIndexofCollectionViewCells.count) photo", for: UIControlState())
                } else {
                    bottomButton.setTitle("Delete \(selectedIndexofCollectionViewCells.count) photos", for: UIControlState())
                }
                isDeleting = true
            } else{
                bottomButton.setTitle("New Collection", for: UIControlState())
                isDeleting = false
            }
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.object(at: indexPath)

        cell.photoView.image = photo.image
        
        cell.deleteButton.isHidden = true
        
        cell.deleteButton.layer.setValue(indexPath, forKey: "indexPath")
        
        // Trigger the action 'deletePhoto' when the button is tapped
        cell.deleteButton.addTarget(self, action: #selector(PhotoAlbumViewController.deletePhoto(_:)), for: UIControlEvents.touchUpInside)
        
        return cell
    }
    
}
