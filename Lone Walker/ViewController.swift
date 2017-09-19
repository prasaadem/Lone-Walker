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
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate,UISearchBarDelegate,MKMapViewDelegate,CLLocationManagerDelegate{
    
    @IBOutlet weak var mapKitView: MKMapView!
    let locationManager = CLLocationManager()
    var sourceLocation = CLLocationCoordinate2D()
    var destinationLocation = CLLocationCoordinate2D()
    var steps:Array = [RouteStep]()
    
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "13578c20440b1497bdc6ac12bb841315"
    
    let weatherDataModel = WeatherDataModel()
    
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
        addBottomSheetView()
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
    
    func getDirections(){
        
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
                let midPoint:CLLocationCoordinate2D = MKCoordinateForMapPoint(step.polyline.points()[step.polyline.pointCount/2])
                
                let params : [String:String] = ["lat" : String(midPoint.latitude),"lon" : String(midPoint.longitude),"appid" : self.APP_ID]
                
                Alamofire.request(self.WEATHER_URL, method: .get, parameters: params).responseJSON{
                    response in
                    if response.result.isSuccess{
                        let json : JSON = JSON(response.result.value!)
                        if let tempResult = json["main"]["temp"].double{
                            let data = WeatherDataModel()
                            data.temperature = Int(tempResult - 273.15)
                            data.city = json["name"].stringValue
                            data.condition = json["weather"][0]["id"].intValue
                            data.weatherIconName = data .updateWeatherIcon(condition: data.condition)
                            let routeStep = RouteStep()
                            routeStep.distance = step.distance
                            routeStep.instructions = step.instructions
                            routeStep.notice = step.notice
                            routeStep.transportType = step.transportType
                            routeStep.polyline = step.polyline
                            routeStep.weatherDataModel = data
                            print("\(data.temperature)")
                            childViewController.routeSteps.append(routeStep)
                            childViewController.tableView .reloadData()
                        }
                    }else{
                        print("Error \(String(describing: response.result.error))")
                    }
                }
            }
//            childViewController.tableView .isHidden = false
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
        
                self.destinationLocation = CLLocationCoordinate2DMake(latitude!, longitude!)
                
                let params : [String:String] = ["lat" : String(self.destinationLocation.latitude),"lon" : String(self.destinationLocation.longitude),"appid" : self.APP_ID]
                
                self.getWeatherData(url: self.WEATHER_URL, parameters: params)
                
                self.getDirections()
                
                let span = MKCoordinateSpanMake(0.1, 0.1)
                
                let region = MKCoordinateRegionMake(self.destinationLocation, span)
                self.mapKitView.setRegion(region, animated: true)
                let childViewController:ScrollableBottomSheetViewController = self.childViewControllers[0] as! ScrollableBottomSheetViewController
                childViewController.placeName.text = response?.mapItems[0].name
                childViewController.placemark.text = "Minneapolis, Minneapolis, MN, United States"
            
            }
        }
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    //Write the getWeatherData method here:
    
    func getWeatherData(url:String, parameters: [String:String]){
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON{
            response in
            if response.result.isSuccess{
                let weatherJSON : JSON = JSON(response.result.value!)
                self.updateWeatherData(json: weatherJSON)
            }else{
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    
    //MARK: - JSON Parsing
    /***************************************************************/
    
    
    //Write the updateWeatherData method here:
    
    func updateWeatherData(json:JSON){
        if let tempResult = json["main"]["temp"].double{
            weatherDataModel.temperature = Int(tempResult - 273.15)
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel .updateWeatherIcon(condition: weatherDataModel.condition)
            updateUIWithWeatherData()
        }
    }
    
    //MARK: - UI Updates
    /***************************************************************/
    
    //Write the updateUIWithWeatherData method here:
    func updateUIWithWeatherData(){
        let childViewController:ScrollableBottomSheetViewController = self.childViewControllers[0] as! ScrollableBottomSheetViewController
        
        childViewController.placeName.text = weatherDataModel.city
        childViewController.temperatureLabel.text = "\(weatherDataModel.temperature)°C"
        childViewController.weatherImageView.image = UIImage(named: weatherDataModel.weatherIconName)
        childViewController.placemark.text = weatherDataModel.weatherIconName
    }
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocation = locations[locations.count - 1]
        if location.horizontalAccuracy > 0{
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
        }
        let params : [String:String] = ["lat" : String(location.coordinate.latitude),"lon" : String(location.coordinate.longitude),"appid" : APP_ID]
        
        getWeatherData(url: WEATHER_URL, parameters: params)
    }
    
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

