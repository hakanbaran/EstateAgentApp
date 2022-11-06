//
//  ViewController.swift
//  EstateAgentApp
//
//  Created by Hakan Baran on 22.09.2022.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        
    }


}

