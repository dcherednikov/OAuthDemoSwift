//
//  MessageView.swift
//  OAuthDemo
//
//  Created by Admin on 30/06/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class MessageView : UIView {
    weak var containerView: UIView!
    func appear(message: String!) {
        messageLabel?.text = message
        self.frame = containerView.bounds
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(self)
    }
    
    @IBOutlet private weak var messageLabel: UILabel?
    
    @IBAction private func OKButtonTapped() {
        self.removeFromSuperview()
    }
}
