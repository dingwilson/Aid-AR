//
//  ARViewController.swift
//  Aid-AR
//
//  Created by Wilson Ding on 9/30/17.
//  Copyright © 2017 Wilson Ding. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ARCL
import CoreLocation
import Alamofire
import SwiftyJSON
import Mapbox

class ARViewController: UIViewController, SceneLocationViewDelegate, MGLMapViewDelegate {
    
    @IBOutlet weak var arView: UIView!

    @IBOutlet weak var compassView: UIView!
    
    var compass : MBXCompassMapView!
    
    var sceneLocationView = SceneLocationView()

    var annotations : [LocationAnnotationNode] = []
    
    var reloadTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        compass = MBXCompassMapView(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: 150,
                                                  height: 150),
                                    styleURL: URL(string: "mapbox://styles/mapbox/light-v9"))
        
        compass.isMapInteractive = false
        compass.tintColor = .black
        compass.delegate = self
        compassView.addSubview(compass)
        
        sceneLocationView.run()
        
        arView.addSubview(sceneLocationView)
        
        loadHazards()
        
        loadData()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneLocationView.addGestureRecognizer(tapGesture)
        
        reloadTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(loadData), userInfo: nil, repeats: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = arView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneLocationView.pause()
        
        reloadTimer.invalidate()
    }
    
    func loadHazards() {
        Alamofire.request("https://54cd0148.ngrok.io").responseJSON { response in
            
            guard let jsonData = response.result.value else {
                print("JSON parse failed")
                return
            }
            
            let json = JSON(jsonData)
            
            for (_,hazard):(String, JSON) in json {
                let latitude = hazard["latitude"].double
                let longitude = hazard["longitude"].double
                let danger = hazard["danger"].string
                
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude!), longitude: CLLocationDegrees(longitude!))
                let location = CLLocation(coordinate: coordinate, altitude: 150)

                var image : UIImage
                
                print(danger!)
                
                switch (danger!) {
                case "electrical":  image = UIImage(named: "signElectrical")!
                                    break
                case "flood":       image = UIImage(named: "signFlood")!
                                    break
                case "fire" :       image = UIImage(named: "signFire")!
                                    break
                default:            return
                }
                
                let smallerImage = self.generateSmallerImage(image: image)
                
                let annotationNode = LocationAnnotationNode(location: location, image: smallerImage!)
                
                self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
            }
        }
    }
    
    @objc func loadData() {
        Alamofire.request("https://mryktvov7a.execute-api.us-east-1.amazonaws.com/prod/users?getaids=true").responseJSON { response in
            
            guard let jsonData = response.result.value else {
                print("JSON parse failed")
                return
            }
            
            for node : LocationAnnotationNode in self.annotations {
                self.sceneLocationView.removeLocationNode(locationNode: node)
            }
            
            let json = JSON(jsonData)
            
            for (_,user):(String, JSON) in json {
                let latitude = user["latitude"].double
                let longitude = user["longitude"].double
                let username = user["username"].string
                
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude!), longitude: CLLocationDegrees(longitude!))
                let location = CLLocation(coordinate: coordinate, altitude: 150)
                
                let distance = (self.sceneLocationView.currentLocation()?.distance(from: CLLocation(latitude: latitude!, longitude: longitude!)))!   // meters to miles
                
                let stringFormattedDistance = String(format: "%.01f", distance)
                
                guard let image = self.createFinalImageWith(text: "\(username!)\n\(stringFormattedDistance)m", image: "pin") else {
                    print("Failed to add text to image")
                    return
                }
                
                let annotationNode = LocationAnnotationNode(location: location, image: image)
                
                self.annotations.append(annotationNode)
                
                self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
            }
        }
        
        if let location = sceneLocationView.currentLocation() {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            Alamofire.request("https://mryktvov7a.execute-api.us-east-1.amazonaws.com/prod/users?username=Anonymous&needsAid=false&latitude=\(latitude)&longitude=\(longitude)").responseJSON { response in
                if response.response?.statusCode != 200 {
                    print("Error: \(response.response!)")
                }
            }
        } else {
            print("Could not get location")
        }
    }
    
    func generateSmallerImage(image: UIImage) -> UIImage? {
        let viewToRender = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        let imgView = UIImageView(frame: viewToRender.frame)
        
        imgView.image = image
        
        viewToRender.addSubview(imgView)
        
        UIGraphicsBeginImageContextWithOptions(viewToRender.frame.size, false, 0)
        viewToRender.layer.render(in: UIGraphicsGetCurrentContext()!)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    func createFinalImageWith(text: String, image: String) -> UIImage? {
        let image = UIImage(named: image)
        
        let viewToRender = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        
        let imgView = UIImageView(frame: viewToRender.frame)
        
        imgView.image = image
        
        viewToRender.addSubview(imgView)
        
        let textImgView = UIImageView(frame: viewToRender.frame)
        
        textImgView.image = imageFrom(text: text, size: viewToRender.frame.size)
        
        viewToRender.addSubview(textImgView)
        
        UIGraphicsBeginImageContextWithOptions(viewToRender.frame.size, false, 0)
        viewToRender.layer.render(in: UIGraphicsGetCurrentContext()!)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    func imageFrom(text: String , size:CGSize) -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs = [NSAttributedStringKey.font: UIFont(name: "HelveticaNeue", size: 18)!, NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.paragraphStyle: paragraphStyle]
            
            text.draw(with: CGRect(x: 0, y: 0, width: size.width, height: size.height), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            
        }
        return img
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        let scnView = self.sceneLocationView
        
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        
        if hitResults.count > 0 {
            let result = hitResults[0]
            
            let material = result.node.geometry!.firstMaterial!
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
            
            
        }
    }
    
    @IBAction func dismissVC(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - SceneLocationViewDelegat
    
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
        
    }
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        
    }
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
