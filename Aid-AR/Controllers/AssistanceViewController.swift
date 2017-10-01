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

class AssistanceViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var requestHelpButton: UIButton!
    
    var name : String = ""
    
    var locationManager : CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func requestHelpButtonPressed(_ sender: Any) {
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
        
        Alamofire.request("https://mryktvov7a.execute-api.us-east-1.amazonaws.com/prod/users?username=\(name)&needsAid=true&latitude=\(latitude)&longitude=\(longitude)").responseJSON { response in
            print(response.response!)
        }
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
