//
//  ResultVC.swift
//  OAuthDemo
//
//  Created by Admin on 28/06/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class ResultVC: UIViewController, Messaging {
    weak var coordinator: Coordinator?
    var accessToken: String? {
        get {
           return _accessToken
        }
        set {
            _accessToken = newValue
            if (_accessToken ?? "").isEmpty {
                tokenLabel?.text = "no access token"
            }
            else {
                tokenLabel?.text = accessToken!
            }
        }
    }
    var accessTokenSecret: String? {
        get {
            return _accessTokenSecret
        }
        set {
            _accessTokenSecret = newValue
            if (_accessTokenSecret ?? "").isEmpty {
                tokenSecretLabel?.text = "no access token secret"
            }
            else {
                tokenSecretLabel?.text = _accessTokenSecret!
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        messageView = Bundle.main.loadNibNamed("MessageView",
                                               owner: nil,
                                               options: nil)!.first as! MessageView
        messageView.containerView = self.view
        
        spinnerView = Bundle.main.loadNibNamed("SpinnerView",
                                               owner: nil,
                                               options: nil)!.first as! SpinnerView
        spinnerView.containerView = self.view
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction private func tryAgainButtonPressed() {
        coordinator?.startFromRoot()
    }
    
    var messageView: MessageView!
    var spinnerView: SpinnerView!
    
    @IBOutlet private weak var tokenLabel: UILabel?
    @IBOutlet private weak var tokenSecretLabel: UILabel?
    
    private var _accessToken: String?
    private var _accessTokenSecret: String?
    
    func askToWait() {
        spinnerView.appear(message: "access token and token secret\nare requested...")
    }
    
    func stopWaiting() {
        spinnerView.disappear()
    }
    
    func informOnFailure() {
        messageView.appear(message: "second request failed")
        accessToken = nil
        accessTokenSecret = nil
    }
}
