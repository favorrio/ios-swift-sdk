//
//  FavorrAdView.swift
//  example_app1
//
//  Created by 大橋 功 on 10/4/16.
//  Copyright © 2016 Livebuzz, Inc. All rights reserved.
//

import Foundation
import UIKit
import AdSupport
import StoreKit

public protocol FavorrAdViewDelegate: class {
    func FavorrAdViewDelegateDidReceiveAd(parameters:[String:Any]?)
    func FavorrAdViewDelegateDidReceiveError(error:Error?, view:FavorrAdView?)
}

public class FavorrAdView: UIView, SKStoreProductViewControllerDelegate {
    
    // Errors
    enum requestAdError: Error {
        case serverError
        case jsonError
        case noAdsAvailable
        case networkError
        case apiKeyError
    }
    
    // color
    public enum FavorrImageColorType {
        case white
        case black
        case orange
        case green
    }
    
    public weak var delegate:FavorrAdViewDelegate?
    
    public var unitId: String?
    public var rootViewController: UIViewController?
    
    var app_icon:UIImageView?
    var install_icon:UIImageView?
    var title_label:UILabel?
    var price_label:UILabel?
    var star_icon_1:UIImageView?
    var star_icon_2:UIImageView?
    var star_icon_3:UIImageView?
    var star_icon_4:UIImageView?
    var star_icon_5:UIImageView?
    var review_count_label:UILabel?
    
    var activityIndicator:UIActivityIndicatorView?
    
    var trackId = 0
    var banner_log_id:String?
    
    var storeViewController:SKStoreProductViewController?
    var storeReadyFlg = false
    
    var favorrTextColor:UIColor = UIColor.black
    var installButtonColorType = FavorrImageColorType.green
    var starColorType = FavorrImageColorType.black
    
    var banner_params:[String : Any]!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        // setup banner
        self.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        self.isHidden = true
        
        // add app icon
        app_icon = UIImageView(frame: CGRect(x: 10, y: 10, width:38, height: 38))
        self.addSubview(app_icon!)
        app_icon?.layer.cornerRadius = 8.0
        app_icon?.clipsToBounds = true
        app_icon?.isHidden = true
        
        // add install button
        let install_icon_x = frame.size.width - 10 - 76
        install_icon = UIImageView(frame: CGRect(x: install_icon_x, y: 12, width: 76, height: 34))
        install_icon?.isHidden = true
        self.addSubview(install_icon!)
        
        // add title label
        let title_label_w =  self.frame.size.width - 154; // - 10 - 38 - 10 - 10 - 76 - 10
        let title_label_x = 10 + (app_icon?.frame.size.width)! + 10
        title_label = UILabel(frame: CGRect(x: title_label_x, y: 12, width: title_label_w, height: 16))
        title_label?.font = UIFont(name: "AvenirNext-DemiBold", size: 12)
        title_label?.isHidden = true
        self.addSubview(title_label!)
        
        // add price label
        let price_label_y = (title_label?.frame.origin.y)! + (title_label?.frame.size.height)! + 2
        let price_label_x = title_label?.frame.origin.x
        price_label = UILabel(frame: CGRect(x: price_label_x!, y: price_label_y, width: 32, height: 16))
        price_label?.font = UIFont(name: "AvenirNext-Regular", size: 12)
        price_label?.isHidden = true
        self.addSubview(price_label!)
        
        // stars 1
        let star_icon_1_x = (price_label?.frame.origin.x)! + (price_label?.frame.size.width)!
        let star_icon_1_y = (price_label?.frame.origin.y)! + 2
        star_icon_1 = UIImageView(frame: CGRect(x: star_icon_1_x , y: star_icon_1_y, width: 11, height: 10.47))
        star_icon_1?.isHidden = true
        self.addSubview(star_icon_1!)
        
        // stars 2
        let star_icon_2_x = (star_icon_1?.frame.origin.x)! + (star_icon_1?.frame.size.width)!
        let star_icon_2_y = star_icon_1?.frame.origin.y
        star_icon_2 = UIImageView(frame: CGRect(x: star_icon_2_x , y: star_icon_2_y!, width: 11, height: 10.47))
        star_icon_2?.isHidden = true
        self.addSubview(star_icon_2!)
        
        // stars 3
        let star_icon_3_x = (star_icon_2?.frame.origin.x)! + (star_icon_2?.frame.size.width)!
        let star_icon_3_y = star_icon_2?.frame.origin.y
        star_icon_3 = UIImageView(frame: CGRect(x: star_icon_3_x , y: star_icon_3_y!, width: 11, height: 10.47))
        star_icon_3?.isHidden = true
        self.addSubview(star_icon_3!)
        
        // stars 4
        let star_icon_4_x = (star_icon_3?.frame.origin.x)! + (star_icon_3?.frame.size.width)!
        let star_icon_4_y = star_icon_3?.frame.origin.y
        star_icon_4 = UIImageView(frame: CGRect(x: star_icon_4_x , y: star_icon_4_y!, width: 11, height: 10.47))
        star_icon_4?.isHidden = true
        self.addSubview(star_icon_4!)
        
        // stars 5
        let star_icon_5_x = (star_icon_4?.frame.origin.x)! + (star_icon_4?.frame.size.width)!
        let star_icon_5_y = star_icon_4?.frame.origin.y
        star_icon_5 = UIImageView(frame: CGRect(x: star_icon_5_x , y: star_icon_5_y!, width: 11, height: 10.47))
        star_icon_5?.isHidden = true
        self.addSubview(star_icon_5!)
        
        // add review count label
        let review_count_label_x = (star_icon_5?.frame.origin.x)! + (star_icon_5?.frame.size.width)!
        let review_count_label_y = price_label?.frame.origin.y
        review_count_label = UILabel(frame: CGRect(x: review_count_label_x, y: review_count_label_y!, width: 32, height: 16))
        review_count_label?.font = UIFont(name: "AvenirNext-Regular", size: 11)
        review_count_label?.isHidden = true
        self.addSubview(review_count_label!)
        
        // activity indicator
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        let activityRect = CGRect(x: ( self.frame.size.width - (activityIndicator?.frame.size.width)! ) / 2,
                                  y: ( self.frame.size.height - (activityIndicator?.frame.size.height)! ) / 2,
                                  width:(activityIndicator?.frame.size.width)!,
                                  height:(activityIndicator?.frame.size.height)! )
        
        
        activityIndicator?.frame = activityRect
        activityIndicator?.isHidden = true
        self.addSubview(activityIndicator!)

        // make it touchable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapBanner(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // request Ad
    public func requestAd(){
        // get data from favorr rest api
        
        if Favorr.sharedInstance.apiKey == nil {
            self.delegate?.FavorrAdViewDelegateDidReceiveError(error: requestAdError.apiKeyError, view: self)
            return
        }
        
        // hide components
        app_icon?.isHidden = true
        install_icon?.isHidden = true
        title_label?.isHidden = true
        price_label?.isHidden = true
        star_icon_1?.isHidden = true
        star_icon_2?.isHidden = true
        star_icon_3?.isHidden = true
        star_icon_4?.isHidden = true
        star_icon_5?.isHidden = true
        review_count_label?.isHidden = true
        
        // init store ready flg
        self.storeReadyFlg = false
        
        // show indicator
        self.isHidden = false
        DispatchQueue.main.async {
            self.activityIndicator?.startAnimating()
            self.activityIndicator?.isHidden = false
        }

        // prepare parameters
        var params = [String : String]()
        
        if let apiKey = Favorr.sharedInstance.apiKey {
            params["apiKey"] = apiKey
        }
        
        if let unitId = self.unitId {
            params["unitId"] = unitId
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
        
        var request = URLRequest(url: URL(string: "https://cp1.favorr.io/request_ad")!)
        request.httpMethod = "POST"

        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            
            // kick delegate method
            // as error
            self.delegate?.FavorrAdViewDelegateDidReceiveError(error: requestAdError.jsonError, view: self)
            
            return;
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // stop indicator
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.isHidden = true
            }
            
            if error != nil {
                // show error
                // print(error!.localizedDescription)
                
                // kick delegate method
                // as error
                self.delegate?.FavorrAdViewDelegateDidReceiveError(error: requestAdError.networkError, view: self)
                
                // make session speed slow
                Favorr.sharedInstance.slowSession()
                
                return
            }
            
            do {
                
                if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]
                {
                    
                    print("json:\(json)")
                    
                    
                    if let result_code = json["result_code"] as? String {
                        if result_code != "success" {
                            // print("server return error")
                            
                            // kick delegate method
                            // as error
                            self.delegate?.FavorrAdViewDelegateDidReceiveError(error: requestAdError.serverError, view: self)
                            
                            // make session speed slow
                            Favorr.sharedInstance.slowSession()
                            
                            return;
                        }
                    }
                    
                    // success
                    if let ad_info = json["ad_info"] {
                        
                        // draw banner
                        self.banner_params = ad_info as! [String : Any]
                        // self.drawAd(params: ad_info as! [String : Any])
                        self.drawAd()
                        
                    } else {
                        
                        // kick delegate method
                        // as error
                        self.delegate?.FavorrAdViewDelegateDidReceiveError(error: requestAdError.noAdsAvailable, view: self)
                        
                    }

                } else {

                    // kick delegate method
                    // as error
                    self.delegate?.FavorrAdViewDelegateDidReceiveError(error: requestAdError.jsonError, view: self)
                }
            } catch {
                
                // kick delegate method
                // as error
                self.delegate?.FavorrAdViewDelegateDidReceiveError(error: requestAdError.jsonError, view: self)
            }
        }
        task.resume()
    }
    
    // draw ad
    // func drawAd(params:[String: Any]){
    func drawAd(){
        
        if let params = self.banner_params {
            
            // set banner_log_id
            if let val = params["banner_log_id"] as? String {
                self.banner_log_id = val
            }
            
            // framework bundle
            let frameWorkBundle = Bundle(for: Favorr.self)
            
            // install icon
            
            // stars
            var install_icon_image = "install_icon"
            if installButtonColorType == .white {
                install_icon_image = "install_icon_white"
            } else if installButtonColorType == .black {
                install_icon_image = "install_icon_black"
            } else if installButtonColorType == .green {
                install_icon_image = "install_icon"
            } else if installButtonColorType == .orange {
                install_icon_image = "install_icon_orange"
            }
            
            DispatchQueue.main.async {
                self.install_icon?.image = UIImage(named: install_icon_image, in: frameWorkBundle, compatibleWith: nil)
                self.install_icon?.isHidden = false
            }
            
            // add title label
            if let val = params["title"] as? String {
                DispatchQueue.main.async {
                    self.title_label?.text = val
                    self.title_label?.isHidden = false
                    self.title_label?.textColor = self.favorrTextColor
                }
            }
            
            // add price label
            if let val = params["price"] as? String {
                DispatchQueue.main.async {
                    self.price_label?.text = val
                    self.price_label?.isHidden = false
                    self.price_label?.textColor = self.favorrTextColor
                }
            }
            
            
            // stars
            var star_empty_icon = "star_empty_icon"
            var star_half_icon = "star_half_icon"
            var star_full_icon = "star_full_icon"
            if starColorType == .white {
                star_empty_icon = "star_empty_icon_white"
                star_half_icon = "star_half_icon_white"
                star_full_icon = "star_full_icon_white"
            } else if starColorType == .black {
                star_empty_icon = "star_empty_icon"
                star_half_icon = "star_half_icon"
                star_full_icon = "star_full_icon"
            } else if starColorType == .orange {
                star_empty_icon = "star_empty_icon_orange"
                star_half_icon = "star_half_icon_orange"
                star_full_icon = "star_full_icon_orange"
            } else if starColorType == .green {
                star_empty_icon = "star_empty_icon_green"
                star_half_icon = "star_half_icon_green"
                star_full_icon = "star_full_icon_green"
            }
            
            // stars 1
            if let val = params["averageUserRatingForCurrentVersion"] as? Float {
                if val < 0.5 {
                    DispatchQueue.main.async {
                        
                        self.star_icon_1?.image = UIImage(named: star_empty_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_1?.isHidden = false
                    }
                } else if val < 1.0 {
                    DispatchQueue.main.async {
                        self.star_icon_1?.image = UIImage(named: star_half_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_1?.isHidden = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.star_icon_1?.image = UIImage(named: star_full_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_1?.isHidden = false
                    }
                }
            }
            
            // stars 2
            if let val = params["averageUserRatingForCurrentVersion"] as? Float {
                if val < 1.5 {
                    DispatchQueue.main.async {
                        self.star_icon_2?.image = UIImage(named: star_empty_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_2?.isHidden = false
                    }
                } else if val < 2.0 {
                    DispatchQueue.main.async {
                        self.star_icon_2?.image = UIImage(named: star_half_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_2?.isHidden = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.star_icon_2?.image = UIImage(named: star_full_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_2?.isHidden = false
                    }
                }
            }
            
            // stars 3
            if let val = params["averageUserRatingForCurrentVersion"] as? Float {
                if val < 2.5 {
                    DispatchQueue.main.async {
                        self.star_icon_3?.image = UIImage(named: star_empty_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_3?.isHidden = false
                    }
                } else if val < 3.0 {
                    DispatchQueue.main.async {
                        self.star_icon_3?.image = UIImage(named: star_half_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_3?.isHidden = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.star_icon_3?.image = UIImage(named: star_full_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_3?.isHidden = false
                    }
                }
            }
            
            // stars 4
            if let val = params["averageUserRatingForCurrentVersion"] as? Float {
                if val < 3.5 {
                    DispatchQueue.main.async {
                        self.star_icon_4?.image = UIImage(named: star_empty_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_4?.isHidden = false
                    }
                } else if val < 4.0 {
                    DispatchQueue.main.async {
                        self.star_icon_4?.image = UIImage(named: star_half_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_4?.isHidden = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.star_icon_4?.image = UIImage(named: star_full_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_4?.isHidden = false
                    }
                }
            }
            
            // stars 5
            if let val = params["averageUserRatingForCurrentVersion"] as? Float {
                if val < 4.5 {
                    DispatchQueue.main.async {
                        self.star_icon_5?.image = UIImage(named: star_empty_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_5?.isHidden = false
                    }
                } else if val < 5.0 {
                    DispatchQueue.main.async {
                        self.star_icon_5?.image = UIImage(named: star_half_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_5?.isHidden = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.star_icon_5?.image = UIImage(named: star_full_icon, in: frameWorkBundle, compatibleWith: nil)
                        self.star_icon_5?.isHidden = false
                    }
                }
            }
            
            // add review count label
            if let val = params["userRatingCountForCurrentVersion"] as? Int {
                let str = String(val)
                DispatchQueue.main.async {
                    self.review_count_label?.text = "("+str+")"
                    self.review_count_label?.isHidden = false
                    self.review_count_label?.textColor = self.favorrTextColor
                    
                }
            }
            
            // start downloading icon
            if let val = params["icon"] as? String {
                download_icon(icon_url: val)
            }
            
            // send log
            if let trackId = params["trackId"] as? Int {
                self.trackId = trackId
                Favorr.sharedInstance.send_log(trackId: trackId, unitId: self.unitId, banner_log_id: self.banner_log_id, action: "show")
                
                // prepare store
                storeViewController = SKStoreProductViewController()
                storeViewController?.delegate = self
                
                // load product here
                let parameters = [ SKStoreProductParameterITunesItemIdentifier : trackId]
                self.storeViewController?.loadProduct(withParameters: parameters) { (flg, error) in
                    if flg == true {
                        self.storeReadyFlg = true
                    }
                }
            }
            
            // kick delegate method
            // as successful
            self.delegate?.FavorrAdViewDelegateDidReceiveAd(parameters: params)
        }

    }
    
    // download icon
    func download_icon(icon_url:String){
        
        let url = URL(string: icon_url)
        let request = URLRequest(url: url!)
        let task = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            if error != nil {
//                print("some error!")
            } else {
                if let bach = UIImage(data: data!) {
                    DispatchQueue.main.async {
                        // update some UI
                        self.app_icon?.image = bach
                        self.app_icon?.isHidden = false
                    }
                }
            }
        })
        task.resume()
    }
    
    
    // banner was tapped
    func tapBanner(_ sender: UITapGestureRecognizer) {
//        print("tapBanner, trackId:\(self.trackId)")
        
        if self.trackId == 0 {
//            print("asdfasdfsa trackId is 0")
            return
        }
        
        if let banner_log_id = self.banner_log_id {
            
            if self.storeReadyFlg == true {
                
                self.rootViewController?.present(self.storeViewController!, animated: true, completion: {
                    
                    // visit log
                    Favorr.sharedInstance.send_log(trackId: self.trackId, unitId: self.unitId, banner_log_id: banner_log_id, action: "click")
                })
            }
        } else {
            // print("something must be wrong 1")
        }
    }
    
    // delegate method
    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
//        print("productViewControllerDidFinish")
        viewController.dismiss(animated: true) {
//            print("SKStoreProductViewController dismissed")
            
            self.storeReadyFlg = false
            if self.trackId == 0 {
                self.requestAd()
                return
            }
            
            // prepare store again
            self.storeViewController = SKStoreProductViewController()
            self.storeViewController?.delegate = self
            
            // load product here
            let parameters = [ SKStoreProductParameterITunesItemIdentifier : self.trackId]
            self.storeViewController?.loadProduct(withParameters: parameters) { (flg, error) in
//                print("storeViewController, flg:\(flg), error:\(error)")
                if flg == true {
//                    print("showAppstore 2")
                    self.storeReadyFlg = true
                } else {
//                    print("error: \(error)")
                }
            }
        }
    }

    // change textcolor
    public func updateTextColor(color:UIColor){
        self.favorrTextColor = color
        self.drawAd()
    }
    
    
    // change star color
    public func updateStarColor(type:FavorrImageColorType) {
        self.starColorType = type
        self.drawAd()
    }

    // change install button color
    public func updateInstallButtonColor(type:FavorrImageColorType) {
        self.installButtonColorType = type
        self.drawAd()
    }
    
}
