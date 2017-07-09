//
//  FormVC.swift
//  OAuthDemo
//
//  Created by Admin on 28/06/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

typealias Direction = Bool
let up: Direction = true
let down: Direction = false

class FormVC: UIViewController, Messaging, UITextFieldDelegate {

    // MARK: internal variables
    weak var coordinator: Coordinator?
    var consumerKeyFieldText: String? {
        get {
            return _consumerKeyFieldText
        }
        set {
            _consumerKeyFieldText = newValue
            consumerKeyField?.text = newValue
        }
    }
    
    var consumerSecretFieldText: String? {
        get {
            return _consumerSecretFieldText
        }
        set {
            _consumerSecretFieldText = newValue
            consumerSecretField?.text = newValue
        }
    }
    
    var requestURLFieldText: String? {
        get {
            return _requestURLFieldText
        }
        set {
            _requestURLFieldText = newValue
            requestURLField?.text = newValue
        }
    }
    
    var authorizationURLFieldText: String? {
        get {
            return _authorizationURLFieldText
        }
        set {
            _authorizationURLFieldText = newValue
            authorizationURLField?.text = newValue
        }
    }
    
    var accessURLFieldText: String? {
        get {
            return _accessURLFieldText
        }
        set {
            _accessURLFieldText = newValue
            accessURLField?.text = newValue
        }
    }
    
    // MARK: UIViewController life cycle
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
        
        consumerKeyField?.delegate = self
        consumerSecretField?.delegate = self
        requestURLField?.delegate = self
        authorizationURLField?.delegate = self
        accessURLField?.delegate = self
        
        allFields = [consumerKeyField!,
                     consumerSecretField!,
                     requestURLField!,
                     authorizationURLField!,
                     accessURLField!]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillShow),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillHide),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIKeyboardWillShow,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIKeyboardWillHide,
                                                  object: nil)
    }
    
    // MARK: private variables and IBOutlets
    private var messageView: MessageView!
    private var spinnerView: SpinnerView!
    
    private var _consumerKeyFieldText: String?
    private var _consumerSecretFieldText: String?
    private var _requestURLFieldText: String?
    private var _authorizationURLFieldText: String?
    private var _accessURLFieldText: String?
    
    @IBOutlet private weak var consumerKeyField: UITextField?
    @IBOutlet private weak var consumerSecretField: UITextField?
    @IBOutlet private weak var requestURLField: UITextField?
    @IBOutlet private weak var authorizationURLField: UITextField?
    @IBOutlet private weak var accessURLField: UITextField?
    
    private var allFields: Array<UITextField>?
    
    @IBOutlet private weak var topConstraint: NSLayoutConstraint?
    
    private var keyboardFrame: CGRect = CGRect(origin: CGPoint(x: 0, y: 0),
                                               size: CGSize(width:0, height: 0))
    private var keyboardAnimationDuration: Float = 0
    
    // MARK: keyboard callbacks
    @objc private func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo
        if let frameValue = userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            keyboardFrame = frameValue.cgRectValue
        }
        if let durationValue = userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
            keyboardAnimationDuration = durationValue.floatValue
        }
        animateView(up)
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        let userInfo = notification.userInfo
        if let durationValue = userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
            keyboardAnimationDuration = durationValue.floatValue
        }
        animateView(down)
    }
    
    // MARK: animation
    private func animateView(_ direction: Direction) {
        var targetConstant = CGFloat(0)
        if direction == up {
            targetConstant = CGFloat(-keyboardFrame.size.height/2.0)
        }
        UIView.animate(withDuration: TimeInterval(keyboardAnimationDuration), animations: {
            self.topConstraint?.constant = targetConstant
            self.view.layoutIfNeeded()
        })
    }
    
    // MARK: IBAction
    @IBAction private func startButtonTapped() {
        consumerKeyFieldText = consumerKeyField?.text
        consumerSecretFieldText = consumerSecretField?.text
        requestURLFieldText = requestURLField?.text
        authorizationURLFieldText = authorizationURLField?.text
        accessURLFieldText = accessURLField?.text
        
        var hasEmptyField = false
        
        for field in allFields! {
            let currentFieldIsEmpty = (field.text ?? "").isEmpty
            hasEmptyField = hasEmptyField || currentFieldIsEmpty
        }
        
        if (hasEmptyField) {
            messageView.appear(message: "all fields must be filled")
            self.view.endEditing(true)
        }
        else {
            coordinator?.onAuthorizationRequested()
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField == consumerKeyField) {
            consumerKeyFieldText = textField.text
        }
        else if (textField == consumerSecretField) {
            consumerSecretFieldText = textField.text
        }
        else if (textField == requestURLField) {
            requestURLFieldText = textField.text
        }
        else if (textField == authorizationURLField) {
            authorizationURLFieldText = textField.text
        }
        else if (textField == accessURLField) {
            accessURLFieldText = textField.text
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // MARK: Messaging
    func askToWait() {
        spinnerView.appear(message: "first token and token secret\nare requested...")
        self.view.endEditing(true)
    }

    func stopWaiting() {
         spinnerView.disappear()
    }
    
    func informOnFailure() {
        messageView.appear(message: "first request failed")
    }
}
