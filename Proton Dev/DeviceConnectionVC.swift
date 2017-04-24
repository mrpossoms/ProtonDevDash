//
//  DeviceConnectionVC.swift
//  Proton Dev
//
//  Created by Kirk Roerig on 4/24/17.
//  Copyright © 2017 Kirk Roerig. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class DeviceConnectionVC: UIViewController, ProtonDeviceDelegate {
    var protonDev : ProtonDevice?;
    
    @IBOutlet weak var statusLabel: UILabel!
    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        protonDev = ProtonDevice.SharedInstance;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        protonDev?.delegate = self;
        protonDev?.startScan();
        statusLabel.text = "Searching...";
    }
    
    func discovered(proton: CBPeripheral) {
        statusLabel.text = "Connecting...";
        protonDev?.connect(toProton: proton);
    }
    
    func disconnected(error: Error?) { }
    
    func connected(toProton: CBPeripheral, withError: Error?) {
        if withError == nil {
            statusLabel.text = "Connected";
            
            self.performSegue(withIdentifier: "ProtonDash", sender: self);
        }
        else {
            statusLabel.text = "Connection failed...";
        }
    }
    
    func accelerationEvent(acceleration: Vec3) {
        print(acceleration);
    }
    
}
