//
//  Favorr.swift
//  example_app1
//
//  Created by 大橋 功 on 10/6/16.
//  Copyright © 2016 Livebuzz, Inc. All rights reserved.
//

import Foundation
import UIKit
import AdSupport

public class Favorr: NSObject {

    //MARK: Local Variable
    public var apiKey: String?
    
    var uuid_string: String?
    var adid_string: String?
    var systemVersion: String?
    var modelName:String?
    var deviceName:String?
    var systemName:String?
    
    var pingTimer:Timer?
    
    var sessionId:String?
    
    //MARK: Shared Instance
    public static let sharedInstance : Favorr = {
        let instance = Favorr()
        return instance
    }()
    
    // Errors
    enum apiKeyError: Error {
        case apiKeyNotFound
        case jsonError
        case networkError
    }
    
    // Favorr as a session tracker
    // init with apiKey
    public func initWithApiKey(apiKey:String, completion:@escaping ((String?, Error?) -> Void)){
        
        if apiKey == "" {
            completion(nil, apiKeyError.apiKeyNotFound)
            return;
        }
        
        // API Key
        Favorr.sharedInstance.apiKey = apiKey
        
        // vendor id and ad id
        Favorr.sharedInstance.uuid_string = UIDevice.current.identifierForVendor!.uuidString
        Favorr.sharedInstance.adid_string = ASIdentifierManager().advertisingIdentifier!.uuidString
        Favorr.sharedInstance.systemVersion = UIDevice.current.systemVersion
        
        // modelName, deviceName, systemName
        Favorr.sharedInstance.modelName = UIDevice.current.modelName
        Favorr.sharedInstance.deviceName = UIDevice.current.name
        Favorr.sharedInstance.systemName = UIDevice.current.systemName
        
        
        // send 1st log
        updateSessionWithCompletion { (result_str, err) in
            if err != nil {
                completion(nil, err)
                return
            }
            
            completion("sucess", nil)
            
            // start session
            Favorr.sharedInstance.startSession(fromInit: true)
        }
        
        // applicationDidBecomeActive
        NotificationCenter.default.addObserver(Favorr.sharedInstance,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        
        // applicationWillResignActiv
        NotificationCenter.default.addObserver(Favorr.sharedInstance,
                                               selector: #selector(applicationWillResignActive),
                                               name: .UIApplicationWillResignActive,
                                               object: nil)
        
    }
    
    // set timer
    func startSession(fromInit:Bool){
        
        print("startSession")
        
        if Favorr.sharedInstance.pingTimer == nil {
            print("send first session update 1")
            // create timer
            createTimer(interval: 10)
            
            if fromInit != true{
                // send 1st log
                Favorr.sharedInstance.pingTimer?.fire()
            }
            
        } else if let pingTimer = Favorr.sharedInstance.pingTimer {
            
            if pingTimer.timeInterval == 10.0 {
                pingTimer.invalidate()
            }
            
            if pingTimer.isValid == false {
                // create timer
                createTimer(interval: 10)
                
                if fromInit != true{
                    // send 1st log
                    Favorr.sharedInstance.pingTimer?.fire()
                }
            }
        }
    }
    
    // create timer
    func createTimer(interval: TimeInterval){
        
        Favorr.sharedInstance.pingTimer = Timer.scheduledTimer(timeInterval: interval,
                                                               target: self,
                                                               selector: #selector(updateSession),
                                                               userInfo: nil,
                                                               repeats: true)
        
    }
    
    // stop timer
    func stopSession(){
        print("stopSession")
        if let pingTimer = Favorr.sharedInstance.pingTimer {
            pingTimer.invalidate()
        }
    }
    
    
    // network is not accessible
    func slowSession(){
        if let pingTimer = Favorr.sharedInstance.pingTimer {
            if pingTimer.timeInterval == 10.0 {
                // invalidate timer
                pingTimer.invalidate()
                // re-create timer
                createTimer(interval: 60)
            }
        }
    }
    
    // update session status with callback
    func updateSessionWithCompletion( completion:@escaping ((String?, Error?) -> Void)){
        print("update_session")
        
        // get data from favorr rest api
        
        // prepare parameters
        var params = [String : String]()
        
        if let apiKey = Favorr.sharedInstance.apiKey {
            params["apiKey"] = apiKey
        } else {
            completion(nil, apiKeyError.apiKeyNotFound)
            return;
        }
        
        if let uuid_string = Favorr.sharedInstance.uuid_string {
            params["uuid_string"] = uuid_string
        }
        
        if let adid_string = Favorr.sharedInstance.adid_string {
            params["adid_string"] = adid_string
        }
        
        if let systemVersion = Favorr.sharedInstance.systemVersion {
            params["systemVersion"] = systemVersion
        }
        if let modelName = Favorr.sharedInstance.modelName {
            params["modelName"] = modelName
        }
        if let deviceName = Favorr.sharedInstance.deviceName {
            params["deviceName"] = deviceName
        }
        if let systemName = Favorr.sharedInstance.systemName {
            params["systemName"] = systemName
        }
        
        // sessionId
        if let sessionId = Favorr.sharedInstance.sessionId {
            params["sessionId"] = sessionId
        }
        
        print("params:\(params)")
        
        var request = URLRequest(url: URL(string: "https://cp1.favorr.io/update_session")!)
        request.httpMethod = "POST"
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            print("Dim background error")
            completion(nil, apiKeyError.jsonError)
            return;
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                // show error
                print(error!.localizedDescription)
                completion(nil, apiKeyError.networkError)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]
                {
                    //Implement your logic
                    print(json)
                    if let sessionId = json["sessionId"] as? String {
                        Favorr.sharedInstance.sessionId = sessionId
                    }
                    
                }
            } catch {
                print("error in JSONSerialization 2 response:\(response), data:\(data)")
                
                // make session check speed slow
                Favorr.sharedInstance.slowSession()
                
                completion(nil, apiKeyError.jsonError)
                return;
            }
        }
        task.resume()
    }
    
    // update session status
    func updateSession(){
        print("update_session")
        
        // get data from favorr rest api
        
        // prepare parameters
        var params = [String : String]()
        
        if let apiKey = Favorr.sharedInstance.apiKey {
            params["apiKey"] = apiKey
        }
        
        if let uuid_string = Favorr.sharedInstance.uuid_string {
            params["uuid_string"] = uuid_string
        }
        
        if let adid_string = Favorr.sharedInstance.adid_string {
            params["adid_string"] = adid_string
        }
        
        if let systemVersion = Favorr.sharedInstance.systemVersion {
            params["systemVersion"] = systemVersion
        }
        if let modelName = Favorr.sharedInstance.modelName {
            params["modelName"] = modelName
        }
        if let deviceName = Favorr.sharedInstance.deviceName {
            params["deviceName"] = deviceName
        }
        if let systemName = Favorr.sharedInstance.systemName {
            params["systemName"] = systemName
        }
        
        print("params:\(params)")
        
        var request = URLRequest(url: URL(string: "https://cp1.favorr.io/update_session")!)
        request.httpMethod = "POST"
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            print("Dim background error")
            return;
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                // show error
                print(error!.localizedDescription)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]
                {
                    //Implement your logic
                    print(json)
                }
            } catch {
                
                // make session check speed slow
                Favorr.sharedInstance.slowSession()
                
                print("error in JSONSerialization 4")
            }
        }
        task.resume()
    }
    
    // Notifications
    
    // applicationDidBecomeActive
    func applicationDidBecomeActive(){
        print("applicationDidBecomeActive")
        // stat Session
        startSession(fromInit: false)
    }
    
    // applicationWillResignActive
    func applicationWillResignActive(){
        print("applicationWillResignActive")
        stopSession()
    }
    
    
    
    // Favorr as a ad network
    // init ad view
    public func initAdView( unitId:String, frame:CGRect) -> FavorrAdView {
        let adView = FavorrAdView(frame:frame)
        adView.unitId = unitId
        return adView
    }
    
    // send log show and click
    func send_log(trackId:Int, unitId:String?, banner_log_id:String?, action:String){
        print("update_session")
        
        // get data from favorr rest api
        
        // prepare parameters
        var params = [String : String]()
        
        if let apiKey = Favorr.sharedInstance.apiKey {
            params["apiKey"] = apiKey
        }
        
        // unitId and banner_log_id
        if let unitId = unitId {
            params["unitId"] = unitId
        }
        
        if let banner_log_id = banner_log_id {
            params["banner_log_id"] = banner_log_id
        }
        
        if let uuid_string = Favorr.sharedInstance.uuid_string {
            params["uuid_string"] = uuid_string
        }
        
        if let adid_string = Favorr.sharedInstance.adid_string {
            params["adid_string"] = adid_string
        }
        
        if let systemVersion = Favorr.sharedInstance.systemVersion {
            params["systemVersion"] = systemVersion
        }
        if let modelName = Favorr.sharedInstance.modelName {
            params["modelName"] = modelName
        }
        if let deviceName = Favorr.sharedInstance.deviceName {
            params["deviceName"] = deviceName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        }
        if let systemName = Favorr.sharedInstance.systemName {
            params["systemName"] = systemName
        }
        
        // sessionId
        if let sessionId = Favorr.sharedInstance.sessionId {
            params["sessionId"] = sessionId
        }
        
        // add trackId
        params["trackId"] = String(trackId)
        params["action"] = action
        
        print("params:\(params)")
        
        var request = URLRequest(url: URL(string: "https://cp1.favorr.io/banner_log")!)
        request.httpMethod = "POST"
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            print("Dim background error")
            return;
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                // show error
                print(error!.localizedDescription)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]
                {
                    //Implement your logic
                    print(json)
                }
            } catch {
                print("error in JSONSerialization 5")
            }
        }
        task.resume()
    }
}



// for convenience
public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}
