//
//  XLMapViewController.swift
//  DustBlue
//
//  Created by Mehmet on 2.08.2021.
//

import UIKit
import MapKit
class XLMapViewController: UIViewController {
    
    
    @IBOutlet weak var xlView: UIView!
    
    let mkMapView = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        xlView.layer.shadowColor = UIColor.darkGray.cgColor
        xlView.layer.shadowOffset = .zero
        xlView.layer.shadowRadius = 10
        xlView.layer.shadowOpacity = 0.2
        
        mkMapView.mapType = .hybrid
        
        mkMapView.frame = xlView.bounds
        xlView.addSubview(mkMapView)
        mkMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let xap = UITapGestureRecognizer(target: self, action: #selector(xlFuntion(tap:)))
        mkMapView.addGestureRecognizer(xap)

        // Do any additional setup after loading the view.
    }
    
    @objc func xlFuntion( tap : UITapGestureRecognizer) {
        
        let xlPoint = tap.location(in: xlView)
        let xcoordinate = mkMapView.convert(xlPoint, toCoordinateFrom: mkMapView)
        
        globalLocation = CLLocation(latitude: xcoordinate.latitude, longitude: xcoordinate.longitude)
        
        tabBarController?.selectedIndex = 0
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        xlView.layer.shadowPath = UIBezierPath(rect: xlView.bounds).cgPath
    }


}
