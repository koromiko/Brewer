//
//  ViewController.swift
//  brewer
//
//  Created by Neo on 25/02/2018.
//  Copyright © 2018 STH. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        #if PROD
            print("We brew beer in the Production")
        #elseif STG
            print("We brew beer in the Staging")
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

