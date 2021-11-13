//
//  ViewController.swift
//  DustBlue
//
//  Created by Mehmet on 31.08.2021.
//

import UIKit
import CoreLocation

struct XLLocation : Codable, Hashable {
    let id = UUID()
    let x : String
    let y,z : Double
}

var globalLocation : CLLocation?

@propertyWrapper class XL {
    let ur = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("locations").appendingPathExtension("plist")
    
    let dec = PropertyListDecoder()
    let encod = PropertyListEncoder()
    var wrappedValue : [XLLocation] {
        get {
            if let data = try? Data(contentsOf: ur) {
                return try! dec.decode([XLLocation].self, from: data)
            }
            
            return []
        }
        set {
            let enData = try! encod.encode(newValue)
            try! enData.write(to: ur)
        }
    }
    
}
@available(iOS 15.0, *)
class ViewController: UIViewController, URLSessionDownloadDelegate, CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    
   
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied {
            self.threeInOne(from: CLLocation(latitude: 37.01, longitude: -122.02))
        }
    }
    
  
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard globalLocation == nil else { return }
        guard let location = locations.first else { return }
        threeInOne(from: location)
        manager.stopUpdatingLocation()
    }
    
    @XL var locations : [XLLocation]
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
    
    let manager = CLLocationManager()
    
    @IBOutlet weak var viewAqi: MainAqiView!
    
    @IBOutlet weak var pathConView: UIView!
    
    var xv : PathierView!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        manager.delegate = self
        manager.startUpdatingLocation()
        manager.requestWhenInUseAuthorization()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let globalLocation = globalLocation {
            if #available(iOS 15.0, *) {
                threeInOne(from: globalLocation)
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    @available(iOS 15.0, *)
    func threeInOne(from location  : CLLocation ) {
        barsaveButton.isEnabled  = true
        Task {
            do {
                let model = try await cook(for: location)
                print(model)
                let locationName = try  await self.showLocationText(from: location)
                DispatchQueue.main.async {
                    self.navigationItem.title = locationName
                    self.viewAqi.baqis = model.data.pollutants.pollutantNames
                }
            } catch let error {
                print(error)
            }
            
            
            do {
                let salaD = try await salad(for: location)
                
                print(salaD)
                
                DispatchQueue.main.async {
                    if self.xv == nil {
                        self.xv = PathierView(salad: salaD, frame: self.pathConView.bounds)
                        self.pathConView.addSubview(self.xv)
                    } else {
                        self.xv.removeFromSuperview()
                        self.xv =  PathierView(salad: salaD, frame: self.pathConView.bounds)
                        self.pathConView.addSubview(self.xv)
                        
                    }
                    
                    
                    
                   
                    
                    
                    
                }
            }
            
        
            
        }
    }
    
    
    @IBOutlet weak var barsaveButton: UIBarButtonItem!
    
    @IBAction func saveLocation(_ sender: UIBarButtonItem) {
        
        guard let customTypeSaveLocation = customTypeSaveLocation else {
            return
        }
        
        locations.append(customTypeSaveLocation)
        
        sender.isEnabled = false
        
    }
    
    var customTypeSaveLocation : XLLocation?
    
    @available(iOS 15.0.0, *)
    private func showLocationText(from location :  CLLocation ) async throws -> String {
        
        let (marks) = try await CLGeocoder().reverseGeocodeLocation(location)
        
        
        guard let mark = marks.first else {
            return "Unnamed Location"
        }
        
        guard let country = mark.country else {
            return "Unnamed Location"
        }
        
        guard let locality = mark.locality else {
            return country
        }
        let value = locality + " , " + country
        customTypeSaveLocation = XLLocation(x: value, y: location.coordinate.latitude, z: location.coordinate.longitude)
        return value
        
    }
    @available(iOS 15.0.0, *)
    
    func salad(for location : CLLocation) async throws -> Salad {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        guard let url = URL(string: "https://api.breezometer.com/air-quality/v2/forecast/hourly?lat=\(latitude)&lon=\(longitude)&key=e8c547bd8d204a98ac9288f41429ef42&hours=24") else {
            throw CustomError(message: "url error")
        }
        
        
        let (data, response) = try await URLSession.shared.data(from: url, delegate: nil)
        return try JSONDecoder().decode(Salad.self, from: data)
        
        
      
    }
    @available(iOS 15.0.0, *)
    func cook(for location : CLLocation ) async throws  -> AqiResponse {
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        guard let url = URL(string: "https://api.breezometer.com/air-quality/v2/current-conditions?lat=\(latitude)&lon=\(longitude)&key=e8c547bd8d204a98ac9288f41429ef42&features=breezometer_aqi,local_aqi,health_recommendations,sources_and_effects,pollutants_concentrations,pollutants_aqi_information") else {
            
            throw CustomError(message: "url error")
            }
        
        

            let (data, response) = try await URLSession.shared.data(from: url, delegate: self)
           
               
            return  try JSONDecoder().decode(AqiResponse.self, from: data)
 
    }

}


struct Salad  : Codable, Hashable {
    
    let data : [Day]
    
    func drawPath(in rect :  CGRect) -> UIBezierPath  {
        
        
        let aqis = data.compactMap({ Int($0.indexes.baqi.aqi_display)})
        
        let maxAqi = aqis.max() ?? 0
        let minAqi = aqis.min() ?? 0
        
        let diffAqi = maxAqi - minAqi
        print(diffAqi)
        let heightRatio =   rect.height /  CGFloat(diffAqi)
        let widthRatio =   rect.width  / CGFloat(aqis.count)
        
        var pointers = [CGPoint]()
        
        for i in aqis.indices {
            let y = rect.height - (heightRatio * (CGFloat(aqis[i]) - CGFloat(minAqi) ))
            let x = widthRatio * CGFloat(i)
            
            let poi = CGPoint(x: x, y: y)
            pointers.append(poi)
        }
        
        let bezierPath = UIBezierPath()
        
        for i in pointers {
            if i == pointers.first {
                bezierPath.move(to: i)
            } else  {
                bezierPath.addLine(to: i)
            }
        }
        
        return bezierPath
    }
    
    
}
struct Day : Codable, Hashable {
    let id = UUID()
    let datetime : String
    let indexes : Indexes
}
@available(iOS 13.0, *)
var dataSource : UICollectionViewDiffableDataSource<Int,Pollutant>!

@IBDesignable
class MainAqiView : UIView {
    
    var baqis : [Pollutant] = [] {
        didSet {
            if #available(iOS 13.0, *) {
                updateSnap()
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    var collectionView : UICollectionView!
    
   
    
    let gradientLayer = CAGradientLayer()
    let secondGradientLayer = CAGradientLayer()
    
    let colorOne = UIColor(red: 214/255, green: 243/255, blue: 237/255, alpha: 1)
    
    let colorTwo = UIColor(red: 190/255, green: 234/255, blue: 235/255, alpha: 1)
    
    let colorThree = UIColor(red: 200/255, green: 227/255, blue: 245/255, alpha: 1)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpAqiView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpAqiView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        secondGradientLayer.frame = bounds
    }
    
    override  func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setUpAqiView()
    }
    
    func setUpAqiView() {
        
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor, colorThree.cgColor]
        
        if #available(iOS 13.0, *) {
            secondGradientLayer.colors = [UIColor.systemGray6.withAlphaComponent(0.3).cgColor, UIColor.systemGray6.cgColor]
        } else {
            // Fallback on earlier versions
        }
        
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        secondGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.75)
        secondGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        
        layer.addSublayer(gradientLayer)
        layer.addSublayer(secondGradientLayer)
        if #available(iOS 13.0, *) {
            collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewLayout)
            addSubview(collectionView)
           
            collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            collectionView.backgroundColor = .clear
        } else {
            // Fallback on earlier versions
        }
       
        
        if #available(iOS 13.0, *) {
            dataSource = UICollectionViewDiffableDataSource<Int,Pollutant>(collectionView: collectionView, cellProvider: { collectionView, indexPath, matter in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
                
                cell.singleAqiView.indexLabel.text = matter.aqi_information.baqi.aqi_display
                cell.singleAqiView.aqiStatusLabel.text = matter.aqi_information.baqi.category
                cell.singleAqiView.recomLabel.text  =  matter.full_name
                cell.singleAqiView.symbolLabel.text = matter.display_name
                return cell
            })
        } else {
            // Fallback on earlier versions
        }
        
     
        
    }
    
    @available(iOS 13.0, *)
    func updateSnap() {
        var snap = NSDiffableDataSourceSnapshot<Int,Pollutant>()
        snap.appendSections([0])
        snap.appendItems(self.baqis, toSection: 0)
        
        dataSource.apply(snap)
    }
    @available(iOS 13.0, *)
    
    var collectionViewLayout : UICollectionViewCompositionalLayout {
        
        
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.75), heightDimension: .fractionalHeight(0.75))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        return UICollectionViewCompositionalLayout(section: section)
    }
    
}


class SingleAqiView : UIView {
    
    let stackView = UIStackView()
    
    let indexLabel = UILabel()
    let aqiStatusLabel = UILabel()
    let recomLabel = UILabel()
    
    let symbolLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        
        print("okay")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
        symbolLabel.font =  UIFont.systemFont(ofSize: frame.width / 10,weight: .thin)
    }
    func commonInit() {
        layer.shadowColor = UIColor.darkText.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.2
        backgroundColor = .white
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 50).isActive = true
        stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        
        
        symbolLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbolLabel)
        symbolLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        symbolLabel.topAnchor.constraint(equalTo: stackView.topAnchor, constant: 16).isActive = true
        
        
        symbolLabel.textColor = .systemGreen
        
        
        stackView.distribution = .fillProportionally
        
        stackView.axis = .vertical
        stackView.addArrangedSubview(indexLabel)
        
        indexLabel.font = UIFont.systemFont(ofSize: 80,weight: .thin)
        indexLabel.text = "37"
        
        stackView.addArrangedSubview(aqiStatusLabel)
        
        aqiStatusLabel.font = UIFont.systemFont(ofSize: 16)
        aqiStatusLabel.text = "GOOD AQI"
        aqiStatusLabel.textColor = UIColor.systemGreen
        
        stackView.addArrangedSubview(recomLabel)
        if #available(iOS 13.0, *) {
            recomLabel.textColor = .secondaryLabel
        } else {
            // Fallback on earlier versions
        }
        recomLabel.text = "Enjoy your usual outdoor activities"
        recomLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
       
        
        
    }
    
    
    
    
}


class CollectionViewCell : UICollectionViewCell {
    
    let singleAqiView = SingleAqiView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        cellInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    
    func cellInit() {
        singleAqiView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(singleAqiView)
        
        singleAqiView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        singleAqiView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        singleAqiView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -70).isActive = true
        singleAqiView.widthAnchor.constraint(equalTo: singleAqiView.heightAnchor).isActive = true
    }
    
    
}


struct AqiResponse : Codable {
    let data : AqiData
}


struct AqiData : Codable {
    let indexes : Indexes
    let pollutants : Pollutans
}

struct Pollutans : Codable {
    let co, c6h6, ox, o3, nh3, nmhc, no, nox, no2, pm25, pm10, so2, trs : Pollutant?
    
    
   private var baqis : [BreezoData?] {
        return [co?.aqi_information.baqi, c6h6?.aqi_information.baqi, ox?.aqi_information.baqi, o3?.aqi_information.baqi, nh3?.aqi_information.baqi, nmhc?.aqi_information.baqi, no?.aqi_information.baqi, nox?.aqi_information.baqi, no2?.aqi_information.baqi, pm25?.aqi_information.baqi, pm10?.aqi_information.baqi, so2?.aqi_information.baqi, trs?.aqi_information.baqi]
        
        
    }
    
    var pollutantArray : [BreezoData] {
        baqis.compactMap({ $0})
    }
    
    
    var pollutantNames : [Pollutant] {
        return [co, c6h6, ox, o3, nh3, nmhc, no, nox, no2, pm25, pm10, so2, trs ].compactMap({$0})
    }
}




struct Pollutant : Codable, Hashable {
    let id = UUID()
    let display_name, full_name : String
    let aqi_information : AqiInformation
}

struct Indexes : Codable, Hashable {
    let baqi : BreezoData
}

struct AqiInformation : Codable, Hashable {
    let baqi : BreezoData
}
      
struct  BreezoData : Codable, Hashable{
    let id = UUID()
    let display_name : String
    let aqi_display : String
    let color : String
    let category : String
    let dominant_pollutant : String?
}


struct CustomError : Error {
    let message : String
}



class PathierView : UIView {
    
    var salad : Salad
    
    
    let lineLayer = CAShapeLayer()
    
    let horStackView = UIStackView()
    let minLabel = UILabel()
    let maxLabel = UILabel()
    
    
    init(salad : Salad,frame: CGRect) {
        self.salad = salad
        super.init(frame: frame)
        
        lineLayer.lineCap  = .round
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = UIColor.systemOrange.cgColor
        lineLayer.lineWidth = 2
        
        layer.addSublayer(lineLayer)
        
        
        horStackView.translatesAutoresizingMaskIntoConstraints = false
        horStackView.axis = .horizontal
        addSubview(horStackView)
        horStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        horStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: -16).isActive = true
        horStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: 16).isActive = true
        horStackView.distribution = .fillEqually
        horStackView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        horStackView.clipsToBounds = false
        horStackView.alignment = .center
        for i in salad.data {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .caption1)
            if #available(iOS 13.0, *) {
                label.textColor = .secondaryLabel
            } else {
                // Fallback on earlier versions
            }
            label.clipsToBounds = false
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            
            let date = formatter.date(from: i.datetime)
            formatter.dateFormat = "HH"
            label.text = formatter.string(from: date ?? Date())
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.2
            label.transform = CGAffineTransform(rotationAngle: .pi / 2)
            
            horStackView.addArrangedSubview(label)
            
            
            
            addSubview(minLabel)
            addSubview(maxLabel)
            minLabel.text = "AQI \(salad.data.compactMap({Int($0.indexes.baqi.aqi_display)}).min() ?? 0)"
            maxLabel.text = "AQI \(salad.data.compactMap({Int($0.indexes.baqi.aqi_display)}).max() ?? 0)"
            
            if #available(iOS 11.0, *) {
                minLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
            } else {
                // Fallback on earlier versions
            }
            maxLabel.font = minLabel.font
            
            minLabel.textColor = .systemPink
            maxLabel.textColor = .systemGreen
            maxLabel.minimumScaleFactor = 0.2
            maxLabel.adjustsFontSizeToFitWidth = true
            minLabel.adjustsFontSizeToFitWidth = true
            minLabel.minimumScaleFactor = 0.2
            
        }
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        lineLayer.path = salad.drawPath(in: bounds).cgPath
        
        print(lineLayer.path)
        
        maxLabel.frame = CGRect(origin: CGPoint(x: frame.width - 50, y: 0), size: CGSize(width: 50, height: 50))
        
        minLabel.frame = CGRect(origin: CGPoint(x: 0, y: frame.height - 50), size: CGSize(width: 50, height: 50))
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    
    
    
}
