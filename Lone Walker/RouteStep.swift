//
//  RouteStep.swift
//  Lone Walker
//
//  Created by Aditya Emani on 9/18/17.
//  Copyright © 2017 Aditya Emani. All rights reserved.
//

import UIKit
import MapKit

class RouteStep: NSObject {
    var instructions: String
    var notice: String?
    var distance: CLLocationDistance
    var transportType: MKDirectionsTransportType
    
    override init(){
        instructions = ""
        notice = ""
        distance = 0.0
        transportType = MKDirectionsTransportType.automobile
    }
}
