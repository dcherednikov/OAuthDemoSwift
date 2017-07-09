//
//  VerifierVC.swift
//  OAuthDemoSwift
//
//  Created by Admin on 08/07/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class VerifierVC: UIViewController, UITextFieldDelegate {
    weak var coordinator: Coordinator?
    
    override func viewDidLoad() {
        verifierTextField?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }
    
    @IBOutlet weak var verifierTextField: UITextField?
    
    @IBAction private func verifierProvidedButtonPressed() {
        if (verifierTextField?.text ?? "").isEmpty {
            coordinator?.onVerifierInfoProvided(verifier: nil)
        }
        else {
            coordinator?.onVerifierInfoProvided(verifier: verifierTextField?.text)
        }
    }
    
    @IBAction private func verifierNotProvidedButtonPressed() {
        coordinator?.onVerifierInfoProvided(verifier: nil)
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        verifierProvidedButtonPressed()
        return true
    }
}
