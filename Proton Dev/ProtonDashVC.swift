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
import CoreLocation

class ProtonDashVC: UIViewController, ProtonDeviceDelegate, ChartViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var accChart: LineChartView!
    var locMan : CLLocationManager?;
    var accXData = LineChartDataSet(values: nil, label: "X (m/s^2)");
    var accYData = LineChartDataSet(values: nil, label: "Y (m/s^2)");
    var accZData = LineChartDataSet(values: nil, label: "Z (m/s^2)");
    var speedData = LineChartDataSet(values: nil, label: "V (m/s)");
    var accData   = LineChartDataSet(values: nil, label: "∆V (m/s^2)");
    var startTime = Date();
    
     required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        
        locMan = CLLocationManager();
        locMan?.delegate = self;
        locMan?.allowsBackgroundLocationUpdates = true;
        locMan?.desiredAccuracy = 1;
        locMan?.requestAlwaysAuthorization();
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        ProtonDevice.SharedInstance.delegate = self;
        
        accXData.setColor(NSUIColor.red);
        accXData.drawCirclesEnabled = false;
        accYData.setColor(NSUIColor.green);
        accYData.drawCirclesEnabled = false;
        accZData.setColor(NSUIColor.blue);
        accZData.drawCirclesEnabled = false;
        speedData.drawCirclesEnabled = false;
        speedData.setColor(NSUIColor.magenta);
        accData.drawCirclesEnabled = false;
        accData.setColor(NSUIColor.purple);
        
        accXData.clear();
        accYData.clear();
        accZData.clear();
        
        startTime = Date();
    }
    
    
    @IBAction func setModeNormal(_ sender: Any) {
        ProtonDevice.SharedInstance.sendCommand(cmdByte: 0);
        locMan?.stopUpdatingLocation();
        
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let paths = [dir.appendingPathComponent("acc_log"), dir.appendingPathComponent("gps_log")];
            
            for path in paths {
                do {
                    let data = try Data(contentsOf: path);
                    let request = NSMutableURLRequest(url: URL(string: "http://protean.io:3000")!);
                    
                    request.httpMethod = "POST";
                    request.setValue("Keep-Alive", forHTTPHeaderField: "Connection");
                    
                    let session = URLSession(configuration: URLSessionConfiguration.default);
                    session.uploadTask(with: request as URLRequest, from: data as Data);
                    
                }
                catch {}
            }
        }
    }
    
    
    @IBAction func setModePoll(_ sender: Any) {
        ProtonDevice.SharedInstance.sendCommand(cmdByte: 1);
        locMan?.startUpdatingLocation();
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

            let paths = [dir.appendingPathComponent("acc_log"), dir.appendingPathComponent("gps_log")];
            
            for path in paths {
                do {
                    try FileManager.default.removeItem(at: path);
                }
                catch {}
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        ProtonDevice.SharedInstance.disconnect();
        locMan?.stopUpdatingLocation();
    }
    
    
    //    ___         _              ___            ___  _      _
    //   | _ \_ _ ___| |_ ___ _ _   |   \ _____ __ |   \| |__ _| |_
    //   |  _/ '_/ _ \  _/ _ \ ' \  | |) / -_) V / | |) | / _` |  _|_
    //   |_| |_| \___/\__\___/_||_| |___/\___|\_/  |___/|_\__, |\__(_)
    //                                                    |___/
    func discovered(proton: CBPeripheral) { }
    func connected(toProton: CBPeripheral, withError: Error?) { }
    func disconnected(error: Error?) {
        if error != nil {
            // TODO: Show alert
        }
        self.dismiss(animated: true) { };
    }
    
    
    func accelerationEvent(acceleration: Vec3) {
        let interval = NSDate().timeIntervalSince(startTime);
        _ = accXData.addEntry(ChartDataEntry(x: Double(interval), y: Double(acceleration.x)));
        _ = accYData.addEntry(ChartDataEntry(x: Double(interval), y: Double(acceleration.y)));
        _ = accZData.addEntry(ChartDataEntry(x: Double(interval), y: Double(acceleration.z)));
        
        if accXData.entryCount > 250 {
            _ = accXData.removeFirst();
        }

        if accYData.entryCount > 250 {
            _ = accYData.removeFirst();
        }
        
        if accZData.entryCount > 250 {
            _ = accZData.removeFirst();
            
            while speedData.entryCount > 0 && speedData.entryForIndex(0)!.x < accXData.entryForIndex(0)!.x {
                _ = speedData.removeFirst();
                _ = accData.removeFirst();
            }
            
        }
        
        if accXData.entryCount > 0 && accData.entryCount > 0 {
            accChart.data = LineChartData(dataSets: [accXData, accYData, accZData, speedData, accData]);
        }
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let path = dir.appendingPathComponent("acc_log")
            
            //writing
            do {
                let row = String(format: "%f, %f, %f, %f,\n",
                                 interval,
                                 acceleration.x, acceleration.y, acceleration.z
                );
                try row.write(to: path, atomically: false, encoding: String.Encoding.utf8);
            }
            catch { print("Failed writing"); }
        }
    }
    
    //    _                 _   _          __  __               ___  _      _
    //   | |   ___  __ __ _| |_(_)___ _ _ |  \/  |__ _ _ _     |   \| |__ _| |_
    //   | |__/ _ \/ _/ _` |  _| / _ \ ' \| |\/| / _` | ' \ _  | |) | / _` |  _|_
    //   |____\___/\__\__,_|\__|_\___/_||_|_|  |_\__,_|_||_(_) |___/|_\__, |\__(_)
    //                                                                |___/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let interval = NSDate().timeIntervalSince(startTime);
        for location in locations {
            _ = speedData.addEntry(ChartDataEntry(x: Double(interval), y: location.speed));
        }
        
        let speedDataLen = speedData.entryCount;
        if speedDataLen > 1 {
            let lastSpeed = speedData.entryForIndex(speedDataLen - 2)!.y;
            let speed = speedData.entryForIndex(speedDataLen - 1)!.y;
            let acc = speed - lastSpeed;
            _ = accData.addEntry(ChartDataEntry(x: interval, y: acc));
            
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                let path = dir.appendingPathComponent("gps_log")
                
                //writing
                do {
                    let row = String(format: "%f, %f, %f,\n",
                                     interval, speed, acc
                    );
                    try row.write(to: path, atomically: false, encoding: String.Encoding.utf8)
                }
                catch {/* error handling here */}
            }
        }
    }
}
