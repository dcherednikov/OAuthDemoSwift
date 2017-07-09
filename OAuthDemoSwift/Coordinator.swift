//
//  Coordinator.swift
//  OAuthDemo
//
//  Created by Admin on 28/06/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import Foundation
import UIKit


let keyConsumerKey = "Consumer Key"
let keyConsumerSecret = "Consumer Secret"
let keyRequestURL = "Request URL"
let keyAuthorizationURL = "Authorization URL"
let keyAccessURL = "Access URL"


class Coordinator: OAuthManagerDelegate {
    // MARK: initializer
    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        
        formVC = Bundle.main.loadNibNamed("FormVC", owner: nil, options: nil)!.first as! FormVC
        webVC = Bundle.main.loadNibNamed("WebVC", owner: nil, options: nil)!.first as! WebVC
        resultVC = Bundle.main.loadNibNamed("ResultVC", owner: nil, options: nil)!.first as! ResultVC
        verifierVC = Bundle.main.loadNibNamed("VerifierVC", owner: nil, options: nil)!.first as! VerifierVC

        authorizationManager = OAuthManager()
        authorizationManager.delegate = self
        
        formVC.coordinator = self
        webVC.coordinator = self
        resultVC.coordinator = self
        verifierVC.coordinator = self
        
        setupAuthorizationManager()
    }
    
    // MARK: internal methods
    func startFromRoot() {
        if navigationController.topViewController == nil {
            navigationController.pushViewController(formVC, animated: false)
        }
        else {
            navigationController.popToRootViewController(animated: true)
        }
        
        fillForm()
    }
    
    func onAuthorizationRequested() {
        saveFields()
        formVC.askToWait()
        
        waitingTimer = Timer.scheduledTimer(withTimeInterval: 3,
                                            repeats: false,
                                            block: {[weak self] (Timer) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.waitingTimerFiredOnFirstRequest()
        })

        authorizationManager.requestFirstPair()
    }
    
    func onAuthorizationEnded() {
        presentVerifierVC()
    }
    
    func onVerifierInfoProvided(verifier: String?) {

        presentResultVC()
        resultVC.askToWait()
        
        waitingTimer = Timer.scheduledTimer(withTimeInterval: 3,
                                            repeats: false,
                                            block: {[weak self] (Timer) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.waitingTimerFiredOnSecondRequest()
        })
        if let unwrappedVerifier = verifier {
            authorizationManager.requestAccessPair(verifier: unwrappedVerifier)
        }
        else {
            authorizationManager.requestAccessPair()
        }
    }
    
    // MARK: private variables
    private var navigationController: UINavigationController
    private var formVC: FormVC
    private var webVC: WebVC
    private var resultVC: ResultVC
    private var verifierVC: VerifierVC
    
    private var authorizationManager: OAuthManager
    
    private var waitingTimer: Timer?
    
    // MARK: form handling
    private func setupAuthorizationManager() {
        authorizationManager.consumerKey = UserDefaults.standard.value(forKey: keyConsumerKey) as? String
        authorizationManager.consumerSecret = UserDefaults.standard.value(forKey: keyConsumerSecret) as? String
        authorizationManager.requestURL = UserDefaults.standard.value(forKey: keyRequestURL) as? String
        authorizationManager.authorizationURL = UserDefaults.standard.value(forKey: keyAuthorizationURL) as? String
        authorizationManager.accessURL = UserDefaults.standard.value(forKey: keyAccessURL) as? String
    }
    
    private func fillForm() {
        formVC.consumerKeyFieldText = authorizationManager.consumerKey
        formVC.consumerSecretFieldText = authorizationManager.consumerSecret
        formVC.requestURLFieldText = authorizationManager.requestURL
        formVC.authorizationURLFieldText = authorizationManager.authorizationURL
        formVC.accessURLFieldText = authorizationManager.accessURL
    }
    
    private func saveFields() {
        authorizationManager.consumerKey = formVC.consumerKeyFieldText
        authorizationManager.consumerSecret = formVC.consumerSecretFieldText
        authorizationManager.requestURL = formVC.requestURLFieldText
        authorizationManager.authorizationURL = formVC.authorizationURLFieldText
        authorizationManager.accessURL = formVC.accessURLFieldText
        
        UserDefaults.standard.set(formVC.consumerKeyFieldText, forKey: keyConsumerKey)
        UserDefaults.standard.set(formVC.consumerSecretFieldText, forKey: keyConsumerSecret)
        UserDefaults.standard.set(formVC.requestURLFieldText, forKey: keyRequestURL)
        UserDefaults.standard.set(formVC.authorizationURLFieldText, forKey: keyAuthorizationURL)
        UserDefaults.standard.set(formVC.accessURLFieldText, forKey: keyAccessURL)
    }
    
    // MARK: timer handling
    private func waitingTimerFiredOnFirstRequest() {
        if authorizationManager.status == .firstRequestSucceeded {
            formVC.stopWaiting()
            presentWebVC()
        }
        else if authorizationManager.status == .firstRequestFailed {
            formVC.stopWaiting()
            formVC.informOnFailure()
        }
        waitingTimer = nil
    }
    
    private func waitingTimerFiredOnSecondRequest() {
        
        if authorizationManager.status == .secondRequestSucceeded {
            resultVC.stopWaiting()
            resultVC.accessToken = authorizationManager.accessToken
            resultVC.accessTokenSecret = authorizationManager.accessTokenSecret
        }
        else if authorizationManager.status == .secondRequestFailed {
            resultVC.stopWaiting()
            resultVC.informOnFailure()
        }
        waitingTimer = nil;
    }
    
    // MARK: VC presentation
    private func presentWebVC() {
        navigationController.pushViewController(webVC, animated: true)
        let url = URL(string: authorizationManager.tokenizedAuthorizationURL!)
        webVC.open(url: url!)
    }
    
    private func presentResultVC() {
        navigationController.pushViewController(resultVC, animated: true)
    }
    
    private func presentVerifierVC() {
        navigationController.pushViewController(verifierVC, animated: true)
    }
    
    // MARK: OAuthManagerDelegate
    func firstRequestSucceeded() {
        if waitingTimer != nil {
            return
        }
        
        performOnUIThread {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.formVC.stopWaiting()
            strongSelf.presentWebVC()
        }
    }
    
    func firstRequestFailed() {
        if waitingTimer != nil {
            return
        }
        
        performOnUIThread {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.formVC.stopWaiting()
            strongSelf.formVC.informOnFailure()
        }
    }
    
    func secondRequestSucceeded() {
        if waitingTimer != nil {
            return
        }
        
        performOnUIThread {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.resultVC.stopWaiting()
            strongSelf.resultVC.accessToken = strongSelf.authorizationManager.accessToken
            strongSelf.resultVC.accessTokenSecret = strongSelf.authorizationManager.accessTokenSecret
        }
    }
    
    func secondRequestFailed() {
        if waitingTimer != nil {
            return
        }
        
        performOnUIThread {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.resultVC.stopWaiting()
            strongSelf.resultVC.informOnFailure()
        }
    }
    
    // MARK: UI thread utility method
    private func performOnUIThread(_ closure: @escaping (Void) -> Void) {
        if Thread.current.isMainThread {
            closure()
        }
        else {
            DispatchQueue.main.async(execute: closure)
        }
    }
    
}
