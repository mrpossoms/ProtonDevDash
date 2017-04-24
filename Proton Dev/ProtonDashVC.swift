//
//  ProtonDashVC.swift
//  Proton Dev
//
//  Created by Kirk Roerig on 4/24/17.
//  Copyright © 2017 Kirk Roerig. All rights reserved.
//

import CoreBluetooth
import Foundation
import UIKit
import Charts

class ProtonDashVC: UIViewController, ProtonDeviceDelegate, ChartViewDelegate {
    
    @IBOutlet weak var accChart: LineChartView!
    var accXData = ChartDataSet();
    var accYData = ChartDataSet();
    var accZData = ChartDataSet();
    var xAxis = 0;
    
    override func viewWillAppear(_ animated: Bool) {
        ProtonDevice.SharedInstance.delegate = self;
        accXData.clear();
        accYData.clear();
        accZData.clear();
        accChart.data = ChartData(dataSets: [accXData, accYData, accZData]);
    }
    
    @IBAction func setModeNormal(_ sender: Any) {
        ProtonDevice.SharedInstance.sendCommand(cmdByte: 0);
    }
    
    @IBAction func setModePoll(_ sender: Any) {
        ProtonDevice.SharedInstance.sendCommand(cmdByte: 1);
    }
 
    func discovered(proton: CBPeripheral) { }
    func connected(toProton: CBPeripheral, withError: Error?) { }
    
    func accelerationEvent(acceleration: Vec3) {
        print(acceleration.x, acceleration.y, acceleration.z);
        _ = accXData.addEntry(ChartDataEntry(x: Double(xAxis), y: Double(acceleration.x)));
        _ = accYData.addEntry(ChartDataEntry(x: Double(xAxis), y: Double(acceleration.y)));
        _ = accZData.addEntry(ChartDataEntry(x: Double(xAxis), y: Double(acceleration.z)));
        
        xAxis += 1;
    }
    
}
