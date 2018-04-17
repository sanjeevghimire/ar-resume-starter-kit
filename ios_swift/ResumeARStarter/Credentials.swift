//
//  Credentials.swift
//  ResumeAR
//
//  Created by Sanjeev Ghimire on 11/1/17.
//  Copyright © 2017 Sanjeev Ghimire. All rights reserved.
//
import UIKit

public class Credentials {
    
    // Visual Recognition API details
    let VR_API_KEY: String!
    let VERSION: String!
    // Cloudant URL
    let CLOUDANT_URL: URL!
    
    init() {
        guard let path = Bundle.main.path(forResource: "BMSCredentials", ofType: "plist"),
            let credentials = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            print("Error while reading BMS credentials file.")
                return
        }
        
        guard let url = credentials["cloudantUrl"] as? String, !url.isEmpty, let cloudantURL = URL(string: url),
            let vrAPIKey = credentials["visualrecognitionApi_key"] as? String else {
                print("Error while reading BMS credentials .")
                return
        }
        
        self.CLOUDANT_URL = cloudantURL
        self.VR_API_KEY = vrAPIKey
        self.VERSION = "2017-12-07"
    }
}
