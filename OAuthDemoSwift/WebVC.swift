//
//  WebVC.swift
//  OAuthDemo
//
//  Created by Admin on 28/06/2017.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

class WebVC: UIViewController {
    weak var coordinator: Coordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .done,
                                         target: self,
                                         action: #selector(self.doneButtonTapped))
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }
    
    @IBOutlet weak var webView: UIWebView?
    
    func open(url: URL) {
        let request = URLRequest(url: url)
        webView?.loadRequest(request)
    }
    
    @objc private func doneButtonTapped() {
        coordinator?.onAuthorizationEnded()
    }
}
