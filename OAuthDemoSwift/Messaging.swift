//
//  Messaging.swift
//  OAuthDemo
//
//  Created by Admin on 30/06/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import Foundation

protocol Messaging {
    func askToWait()
    func stopWaiting()
    func informOnFailure()
}

