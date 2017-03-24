//
//  PhotosViewController.swift
//  virtualTourist
//
//  Created by Warren Hansen on 10/20/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.
    
//  layout fix on photos
//  only getting 1 photo
    
import UIKit
import MapKit
import CoreData
    
class PhotosViewController: UIViewController {
        
        @IBOutlet weak var mapView: MKMapView!
        @IBOutlet weak var collectionView: UICollectionView!
        @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
        //@IBOutlet weak var noImagesFoundLabel: UILabel!
        @IBOutlet weak var toolbar: UIToolbar!
        @IBOutlet weak var toolbarButton: UIBarButtonItem!
        
        @IBAction func toolbarButtonPressed(_ sender: AnyObject) {
            if selectedPhotos.isEmpty {
                deletePhotos()
                searchPhotos()
            } else {
                deleteSelectedPhotos()
            }
        }
        
        let flickrClientInstance = FlickrClient.sharedInstance
        let stack = CoreDataStack.sharedInstance
        
        var insertedIndexCache: [IndexPath]!
        var deletedIndexCache: [IndexPath]!
        
        var selectedPhotos = [IndexPath]() {
            didSet {
                toolbarButton.title = selectedPhotos.isEmpty ? "New Collection" : "Remove Selected Pictures"
            }
        }
        
        var pin: Pin!
        //var fetchedResultsController: NSFetchedResultsController
        var fetchedResultsController: NSFetchedResultsController<Photo>?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupMapView()
            configureFlowLayout(view.frame.size.width)
            
            if fetchPhotos().isEmpty {
                searchPhotos()
            } else {
    //toolbar.isHidden = false
            }
        }
        
        func setupMapView() {
            mapView.addAnnotation(pin)
            mapView.camera.centerCoordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
            mapView.camera.altitude = 50000
        }
        
        func configureFlowLayout(_ width: CGFloat) {
            collectionViewFlowLayout.minimumInteritemSpacing = 1
            collectionViewFlowLayout.minimumLineSpacing = 1
            collectionViewFlowLayout.itemSize = CGSize(width: (view.frame.size.width / 3) - 1, height: view.frame.size.width / 3)
        }
        
        func fetchPhotos() -> [Photo] {
            print("fetchPhotos Ran")
            var photos = [Photo]()
            
            let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
            fetchRequest.sortDescriptors = []
            fetchRequest.predicate = NSPredicate(format: "pin = %@", pin)
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController?.delegate = self
            
            do {
                try fetchedResultsController?.performFetch()
                if let results = (fetchedResultsController?.fetchedObjects) {
                    photos = results
                    print("Photos results number: \(photos.count)")
                }
            } catch {
                print("Error while trying to fetch photos.")
            }
            return photos
        }
        
        func searchPhotos() {
            print("serach photos ran")
            flickrClientInstance.searchPhotos("\(pin.latitude)", longitude: "\(pin.longitude)") { photoURLS, error in
                guard let photoURLS = photoURLS else {
                    return
                }
                self.savePhotos(photoURLS)
                print("Num photos \(photoURLS.count)")
            }
        }
        
        func savePhotos(_ photoURLS: [String]) {
            print("save photos ran")
            DispatchQueue.main.async {
                for photoURL in photoURLS {
                    let photo = Photo(imageURL: photoURL, context: self.stack.context)
                    photo.pin = self.pin
//self.toolbar.isHidden = false
                }
                self.stack.save()
            }
        }
        
        func deleteSelectedPhotos() {
            var photosToDelete = [Photo]()
            
            for indexPath in selectedPhotos {
                photosToDelete.append((fetchedResultsController?.object(at: indexPath))! as Photo)
            }
            
            for photo in photosToDelete {
                stack.context.delete(photo)
            }
            stack.save()
            
            selectedPhotos = []
        }
        
        func deletePhotos() {
            for photo in (fetchedResultsController?.fetchedObjects)! as [Photo] {
                stack.context.delete(photo)
            }
            stack.save()
        }
    }
    
    // MARK: MKMapViewDelegate
    extension PhotosViewController: MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let reuseId = "pin"
            
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            
            return pinView
        }
    }
    
    extension PhotosViewController: UICollectionViewDelegate {
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let cell = collectionView.cellForItem(at: indexPath) as! PhotoViewCell
            
            if let index = selectedPhotos.index(of: indexPath) {
                selectedPhotos.remove(at: index)
            } else {
                selectedPhotos.append(indexPath)
            }
            
            configureCellSection(cell, indexPath: indexPath)
            
        }
        
        func configureCellSection(_ cell: PhotoViewCell, indexPath: IndexPath) {
            if let _ = selectedPhotos.index(of: indexPath){
                cell.alpha = 0.5
            } else {
                cell.alpha = 1.0
            }
        }
    }
    
    // MARK: numberOfItemsInSection
    extension PhotosViewController: UICollectionViewDataSource {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return fetchedResultsController!.sections![section].numberOfObjects
        }
        
        // MARK: cellForItemAt
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
            let photo = (fetchedResultsController?.object(at: indexPath))! as Photo
            
            let image = UIImage(named: "placeholder")
            cell.activityIndicator.startAnimating()
            

            flickrClientInstance.downloadPhotofromURL(photo.imageURL!) { imageData, error in
                
                guard let imageData = imageData,  let downloadedImage = UIImage(data: imageData) else {
                    return
                }
            
    
        
                DispatchQueue.main.async {
                    photo.imageData = imageData
                    self.stack.save()
                    
                    if let updateCell = self.collectionView.cellForItem(at: indexPath) as? PhotoViewCell {
                        updateCell.imageView.image = downloadedImage
                        updateCell.activityIndicator.stopAnimating()
                        updateCell.activityIndicator.isHidden = true
                    }
                }
            }
            
            cell.imageView.image = image
            configureCellSection(cell, indexPath: indexPath)
            
            return cell
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    extension PhotosViewController: NSFetchedResultsControllerDelegate {
        
        func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            insertedIndexCache = [IndexPath]()
            deletedIndexCache = [IndexPath]()
            
        }
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            
            switch type {
            case .insert:
                insertedIndexCache.append(newIndexPath!)
            case .delete:
                deletedIndexCache.append(indexPath!)
            default:
                break
            }
        }
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: self.insertedIndexCache)
                self.collectionView.deleteItems(at: self.deletedIndexCache)
                
                }, completion: nil)
        }
}
