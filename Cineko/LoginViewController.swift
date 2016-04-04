//
//  LoginViewController.swift
//  Cineko
//
//  Created by Jovit Royeca on 04/04/2016.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import UIKit

import JJJUtils
import MBProgressHUD

class LoginViewController: UIViewController {

    // MARK: Properties
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var webView: UIWebView!
    
    // MARL: Variables
    var authenticationURLString:String?
    var requestToken:String?
    var hasHUD = false
    
    // MARK: Actions
    @IBAction func doneAction(sender: UIBarButtonItem) {
        if let _ = TMDBManager.sharedInstance().keychain[Constants.TMDB.SessionIDKey] {
            if let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MainTabBarController") as? UITabBarController {
                presentViewController(controller, animated: true, completion: nil)
            }
            
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func cancelAction(sender: UIBarButtonItem) {
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        dismissViewControllerAnimated(true, completion:nil)
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.scrollView.bounces = false
        webView.delegate = self
        if let authenticationURLString  = authenticationURLString {
            if let authURL = NSURL(string: authenticationURLString) {
                requestToken = authURL.lastPathComponent
                webView.loadRequest(NSURLRequest(URL: authURL))
            }
        }
    }
    
    // MARK: Utility methods
    func requestSessionID() {
        if !hasHUD {
            MBProgressHUD.showHUDAddedTo(webView, animated: true)
            hasHUD = true
        }
        
        let success = { (results: AnyObject!) in
            if let dict = results as? [String: AnyObject] {
                if let sessionID = dict[Constants.TMDBRequestSessionID.SessionID] as? String {
                    
                    // lets store the sessionID in the Keychain
                    TMDBManager.sharedInstance().keychain[Constants.TMDB.SessionIDKey] = sessionID
                    
                    performUIUpdatesOnMain {
                        self.doneButton.enabled = true
                        self.cancelButton.enabled = false
                        MBProgressHUD.hideHUDForView(self.webView, animated: true)
                        self.hasHUD = false
                    }
                }
            }
        }
        
        let failure = { (error: NSError?) in
            performUIUpdatesOnMain {
                MBProgressHUD.hideHUDForView(self.webView, animated: true)
                self.hasHUD = false
                JJJUtil.alertWithTitle("Error", andMessage:"\(error!.userInfo[NSLocalizedDescriptionKey]!)")
                
            }
        }
        
        if let requestToken = requestToken {
            TMDBManager.sharedInstance().requestSessionID(requestToken, success: success, failure: failure);
        }
    }
}

// MARK: UIWebViewDelegate
extension LoginViewController: UIWebViewDelegate {
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if !hasHUD {
            MBProgressHUD.showHUDAddedTo(webView, animated: true)
            hasHUD = true
        }
        return true
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        MBProgressHUD.hideHUDForView(webView, animated: true)
        hasHUD = false
        
        if let request = webView.request {
            if let url = request.URL {
                if let lastPath = url.lastPathComponent {
                    if lastPath == requestToken {
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        
                    } else if lastPath == "deny" {
                        // remove the request token from the keychain and NSUserDefaults
                        TMDBManager.sharedInstance().keychain[Constants.TMDB.RequestTokenKey] = nil
                        NSUserDefaults.standardUserDefaults().removeObjectForKey(Constants.TMDB.RequestTokenDate)
                        
                        doneButton.enabled = true
                        cancelButton.enabled = false
                        
                    } else if lastPath == "allow" {
                        requestSessionID()
                        
                    }  else if lastPath == "signup" {
                        
                    }
                }
            }
        }
    }
}
