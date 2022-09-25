//
//  EstateDetails.swift
//  EstateAgentApp
//
//  Created by Hakan Baran on 22.09.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class EstateDetails: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var roomCountText: UITextField!
    @IBOutlet weak var priceText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedEstate = ""
    var selectedEstateID : UUID?
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    
    
    var annotationName = ""
    var annotationRoomCount = Int()
    var annotationPrice = Int()
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureLongRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseEstate(gestureLongRecognizer:)))
        
        gestureLongRecognizer.minimumPressDuration = 3
        
        mapView.addGestureRecognizer(gestureLongRecognizer)
        
        let closeKeyboard = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(closeKeyboard)
        
        if selectedEstate != "" {
            
            saveButton.isHidden = true
            
            //CoreData
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Estates")
            
            let idString = selectedEstateID?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        if let name = result.value(forKey: "name") as? String {
                            annotationName = name
                            
                            if let roomCount = result.value(forKey: "roomCount") as? Int {
                                annotationRoomCount = roomCount
                                
                                if let price = result.value(forKey: "price") as? Int {
                                    annotationPrice = price
                                    
                                    if let latitude = result.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = result.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationName
                                            annotation.subtitle = String(annotationPrice)
                                            
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            nameText.text = annotationName
                                            roomCountText.text = String(annotationRoomCount)
                                            priceText.text = String(annotationPrice)
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            
                                            mapView.setRegion(region, animated: true)
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }catch {
                print("Error 5")
            }
        } else {
            // Add New Data
        }
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc func chooseEstate(gestureLongRecognizer: UILongPressGestureRecognizer){
        
        if gestureLongRecognizer.state == .began {
            
            let touchedPoint = gestureLongRecognizer.location(in: mapView)
            let touchedCoordinates = mapView.convert(touchedPoint, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = priceText.text
            self.mapView.addAnnotation(annotation)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedEstate == "" {
        
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
        
        if pinView == nil {
            
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.blue
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedEstate != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, Error) in
                
                if let placemark = placemarks {
                    
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        
                        item.name = self.annotationName
                        
                        let lounchOption = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        
                        item.openInMaps(launchOptions: lounchOption)
                        
                    }
                }
            }
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        if nameText.text == "" {
            let nameAlert = UIAlertController(title: "Error", message: "Please Enter Name! ", preferredStyle: UIAlertController.Style.alert)
            
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            nameAlert.addAction(okButton)
            
            self.present(nameAlert, animated: true, completion: nil)
            
        }
        
        if roomCountText.text == "" {
            
            let roomAlert = UIAlertController(title: "Error", message: "Please Enter Room Count! ", preferredStyle: UIAlertController.Style.alert)
            
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            roomAlert.addAction(okButton)
            self.present(roomAlert, animated: true, completion: nil)
        }
        
        if priceText.text == "" {
            
            let priceAlert = UIAlertController(title: "Error", message: "Please Enter Price! ", preferredStyle: UIAlertController.Style.alert)
            
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            priceAlert.addAction(okButton)
            self.present(priceAlert, animated: true, completion: nil)
        }
        
        if chosenLatitude == 0 || chosenLongitude == 0 {
            
            let locationAlert = UIAlertController(title: "Error", message: "Please Enter Location! ", preferredStyle: UIAlertController.Style.alert)
            
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            locationAlert.addAction(okButton)
            self.present(locationAlert, animated: true, completion: nil)
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newEstate = NSEntityDescription.insertNewObject(forEntityName: "Estates", into: context)
        
        newEstate.setValue(nameText.text, forKey: "name")
        
        if let roomCount = Int(roomCountText.text!) {
            newEstate.setValue(roomCount, forKey: "roomCount")
        }
        if let price = Int(priceText.text!) {
            newEstate.setValue(price, forKey: "price")
        }
        newEstate.setValue(UUID(), forKey: "id")
        newEstate.setValue(chosenLatitude, forKey: "latitude")
        newEstate.setValue(chosenLongitude, forKey: "longitude")
        
        do {
            try context.save()
            print("Succes 1")
        } catch {
            print("Error 1")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newEstate"), object: nil)
        navigationController?.popViewController(animated: true)
        
        if selectedEstate == "" {
            
            let locationAlert = UIAlertController(title: "Error", message: "Please Enter Location! ", preferredStyle: UIAlertController.Style.alert)
            
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            locationAlert.addAction(okButton)
            
            self.present(locationAlert, animated: true, completion: nil)
            
        }
    }
}
