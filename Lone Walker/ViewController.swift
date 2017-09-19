//
//  ViewController.swift
//  Lone Walker
//
//  Created by Aditya Emani on 9/18/17.
//  Copyright © 2017 Aditya Emani. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation
import MapKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate,UISearchBarDelegate,MKMapViewDelegate,CLLocationManagerDelegate{
    
    
    @IBOutlet weak var mapKitView: MKMapView!
    let locationManager = CLLocationManager()
    var sourceLocation = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapKitView.delegate = self
        mapKitView.showsScale = true
        mapKitView.showsUserLocation = true
        mapKitView.showsPointsOfInterest = true
        
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }
        
        sourceLocation = (locationManager.location?.coordinate)!
//        let destinationLocation = CLLocationCoordinate2DMake(44.8024,-91.4693)
//        getDirections(destinationLocation: destinationLocation)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.addBottomSheetView()
    }
    
    func addBottomSheetView() {
        let bottomSheetVC = ScrollableBottomSheetViewController()
        
        self.addChildViewController(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParentViewController: self)
        
        let height = view.frame.height
        let width  = view.frame.width
        bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func getDirections(destinationLocation:CLLocationCoordinate2D){
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = sourceLocation
        self.mapKitView.addAnnotation(annotation)
        
        annotation.coordinate = destinationLocation
        self.mapKitView.addAnnotation(annotation)
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = sourceItem
        directionRequest.destination = destinationItem
        directionRequest.transportType = .automobile
        directionRequest.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, e) in
            guard let response = response else{
                if let error = e{
                    print(error)
                }
                return
            }
            
            let overlays = self.mapKitView.overlays
            self.mapKitView.removeOverlays(overlays)
            let route = response.routes[0]
            let childViewController:ScrollableBottomSheetViewController = self.childViewControllers[0] as! ScrollableBottomSheetViewController
            childViewController.routeSteps = [RouteStep]()
            for step in route.steps {
                let routeStep = RouteStep()
                routeStep.distance = step.distance
                routeStep.instructions = step.instructions
                routeStep.notice = step.notice
                routeStep.transportType = step.transportType
                childViewController.routeSteps.append(routeStep)
//                print(routeStep.notice)
            }
            childViewController.tableView .reloadData()
            self.mapKitView.add(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapKitView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        }
    }
    
    @IBAction func searchMap(_ sender: Any) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        self.view .addSubview(activityIndicator)
        
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, e) in
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            if response == nil{
                print("error!")
            }else{
                let annotations = self.mapKitView.annotations
                self.mapKitView.removeAnnotations(annotations)
                
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                let annotation = MKPointAnnotation()
                annotation.title = searchBar.text
                annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.mapKitView.addAnnotation(annotation)
                
                annotation.coordinate = self.sourceLocation
                self.mapKitView.addAnnotation(annotation)
        
                let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
                
                self.getDirections(destinationLocation: coordinate)
                
                let span = MKCoordinateSpanMake(0.1, 0.1)
                
                let region = MKCoordinateRegionMake(coordinate, span)
                self.mapKitView.setRegion(region, animated: true)
                let childViewController:ScrollableBottomSheetViewController = self.childViewControllers[0] as! ScrollableBottomSheetViewController
                childViewController.placeName.text = response?.mapItems[0].name
                childViewController.placemark.text = "Minneapolis, Minneapolis, MN, United States"
            
            }
        }
    }
}

