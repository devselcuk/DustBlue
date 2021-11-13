//
//  LocationsViewController.swift
//  DustBlue
//
//  Created by Mehmet on 2.08.2021.
//

import UIKit
import CoreLocation

@available(iOS 13.0, *)
class LocationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.accessoryType = .disclosureIndicator
        if #available(iOS 14.0, *) {
            var cellConfig = cell.defaultContentConfiguration()
            cellConfig.text = locations[indexPath.row].x
            
            cellConfig.secondaryText = "\(locations[indexPath.row].y)\n\(locations[indexPath.row].z)"
            cellConfig.secondaryTextProperties.numberOfLines = 2
            
            cell.contentConfiguration = cellConfig
        } else {
            // Fallback on earlier versions
        }
        
        
        return cell
    }
    
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let xl = locations[indexPath.row]
        globalLocation = CLLocation(latitude: xl.y, longitude: xl.z)
        tabBarController?.selectedIndex = 0
    }
    
    
    @XL var locations : [XLLocation]
    
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        // Do any additional setup after loading the view.
    }
    
    
    
    


}




 
