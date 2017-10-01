//
//  AssistanceViewController.swift
//  Aid-AR
//
//  Created by Wilson Ding on 9/30/17.
//  Copyright © 2017 Wilson Ding. All rights reserved.
//

import UIKit
import Alamofire
import CoreLocation
import Mapbox
import PKHUD

class AssistanceViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var requestHelpButton: UIButton!
    
    @IBOutlet weak var mapView: UIView!
    
    @IBOutlet weak var overlayView: UIView!
    
    var compass : MBXRectangularMapView!
    
    var name : String = ""
    
    var currentlyRequestingAid = false
    
    var locationManager : CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        compass = MBXRectangularMapView(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: 359,
                                                  height: 473),
                                    styleURL: URL(string: "mapbox://styles/mapbox/dark-v9"))
        
        compass.isMapInteractive = false
        compass.tintColor = .black
        compass.delegate = self
        mapView.addSubview(compass)
        
        HUD.dimsBackground = false
        HUD.allowsInteraction = true
        
        overlayView.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if currentlyRequestingAid {
            if let givenName = nameTextField.text,
                givenName != "" {
                name = givenName
            } else {
                name = "Anonymous"
            }
            
            guard let location = locationManager.location else {
                print("Could not get location.")
                return
            }
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            Alamofire.request("https://mryktvov7a.execute-api.us-east-1.amazonaws.com/prod/users?username=\(name)&needsAid=false&latitude=\(latitude)&longitude=\(longitude)").responseJSON { response in
                if response.response?.statusCode != 200 {
                    print("Error: \(response.response!)")
                }
            }
        }
    }
    
    @IBAction func requestHelpButtonPressed(_ sender: Any) {
        currentlyRequestingAid = !currentlyRequestingAid
        
        if let givenName = nameTextField.text,
            givenName != "" {
            name = givenName
        } else {
            name = "Anonymous"
        }
        
        guard let location = locationManager.location else {
            print("Could not get location.")
            return
        }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        Alamofire.request("https://mryktvov7a.execute-api.us-east-1.amazonaws.com/prod/users?username=\(name)&needsAid=\(currentlyRequestingAid)&latitude=\(latitude)&longitude=\(longitude)").responseJSON { response in
            if response.response?.statusCode != 200 {
                print("Error: \(response.response!)")
            }
        }
        
        if currentlyRequestingAid {
            requestHelpButton.setTitle("You're in good hands.", for: .normal)
            overlayView.isHidden = false
            HUD.show(.progress)
        } else {
            requestHelpButton.setTitle("Request Help", for: .normal)
            HUD.show(.error)
            overlayView.isHidden = true
            HUD.hide(afterDelay: 2.0)
        }
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    @IBAction func dismissVC(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
