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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneLocationView.run()
        
        arView.addSubview(sceneLocationView)
        
        Alamofire.request("https://mryktvov7a.execute-api.us-east-1.amazonaws.com/prod/users?getaids=true").responseJSON { response in
            
            guard let jsonData = response.result.value else {
                print("JSON parse failed")
                return
            }

            let json = JSON(jsonData)
            
            for (_,user):(String, JSON) in json {
                let latitude = user["latitude"].double
                let longitude = user["longitude"].double
                let username = user["username"].string
                
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude!), longitude: CLLocationDegrees(longitude!))
                let location = CLLocation(coordinate: coordinate, altitude: 300)
                let image = UIImage(named: "pin")!
                
                let annotationNode = LocationAnnotationNode(location: location, image: image)
                
                self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = arView.bounds
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
