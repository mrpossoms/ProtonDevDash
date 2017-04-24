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
    var accXData = LineChartDataSet(values: nil, label: "X (m/s^2)");
    var accYData = LineChartDataSet(values: nil, label: "Y (m/s^2)");
    var accZData = LineChartDataSet(values: nil, label: "Z (m/s^2)");
    var xAxis = 0;
    
    override func viewWillAppear(_ animated: Bool) {
        ProtonDevice.SharedInstance.delegate = self;
        
        accXData.setColor(NSUIColor.red);
        accXData.drawCirclesEnabled = false;
        accYData.setColor(NSUIColor.green);
        accYData.drawCirclesEnabled = false;
        accZData.setColor(NSUIColor.blue);
        accZData.drawCirclesEnabled = false;
        
        accXData.clear();
        accYData.clear();
        accZData.clear();
    }
    
    @IBAction func setModeNormal(_ sender: Any) {
        ProtonDevice.SharedInstance.sendCommand(cmdByte: 0);
    }
    
    @IBAction func setModePoll(_ sender: Any) {
        ProtonDevice.SharedInstance.sendCommand(cmdByte: 1);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(segue);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("Going away");
        ProtonDevice.SharedInstance.disconnect();
    }
    
    func discovered(proton: CBPeripheral) { }
    func connected(toProton: CBPeripheral, withError: Error?) { }
    func disconnected(error: Error?) {
        if error != nil {
            // TODO: Show alert
        }
        self.dismiss(animated: true) { };
    }
    
    func accelerationEvent(acceleration: Vec3) {
        print(acceleration.x, acceleration.y, acceleration.z);
        _ = accXData.addEntry(ChartDataEntry(x: Double(xAxis), y: Double(acceleration.x)));
        _ = accYData.addEntry(ChartDataEntry(x: Double(xAxis), y: Double(acceleration.y)));
        _ = accZData.addEntry(ChartDataEntry(x: Double(xAxis), y: Double(acceleration.z)));
        
        if accXData.entryCount > 250 {
            _ = accXData.removeFirst();
        }

        if accYData.entryCount > 250 {
            _ = accYData.removeFirst();
        }
        
        if accZData.entryCount > 250 {
            _ = accZData.removeFirst();
        }
        
        accChart.data = LineChartData(dataSets: [accXData, accYData, accZData]);
        
        xAxis += 1;
    }
    
}
