//
//  ARViewController.swift
//  Aid-AR
//
//  Created by Wilson Ding on 9/30/17.
//  Copyright © 2017 Wilson Ding. All rights reserved.
//

import UIKit
import SceneKit
import ARCL
import CoreLocation
import Alamofire
import SwiftyJSON

class ARViewController: UIViewController, SceneLocationViewDelegate {
    
    @IBOutlet weak var arView: UIView!
    
    var sceneLocationView = SceneLocationView()

    var annotations : [LocationAnnotationNode] = []
    
    var reloadTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneLocationView.run()
        
        arView.addSubview(sceneLocationView)
        
        loadData()
        
        reloadTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(loadData), userInfo: nil, repeats: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = arView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        reloadTimer.invalidate()
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
                
                guard let image = self.createFinalImageWith(text: "\(username!)\n\(stringFormattedDistance)m") else {
                    print("Failed to add text to image")
                    return
                }
                
                let annotationNode = LocationAnnotationNode(location: location, image: image)
                
                self.annotations.append(annotationNode)
                
                self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
            }
        }
    }
    
    func createFinalImageWith(text: String) -> UIImage? {
        
        let image = UIImage(named: "pin")
        
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
