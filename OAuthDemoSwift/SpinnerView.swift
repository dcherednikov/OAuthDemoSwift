//
//  SpinnerView.swift
//  OAuthDemo
//
//  Created by Admin on 30/06/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class SpinnerView: UIView {
    weak var containerView: UIView?
    
    func appear(message: String) {
        messageLabel?.text = message
        self.frame = containerView!.bounds
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        spinner?.startAnimating()
        containerView?.addSubview(self)
    }
    
    func disappear() {
        spinner?.stopAnimating()
        self.removeFromSuperview()
    }
    
    @IBOutlet private weak var spinner: UIActivityIndicatorView?
    @IBOutlet private weak var messageLabel: UILabel?
}
