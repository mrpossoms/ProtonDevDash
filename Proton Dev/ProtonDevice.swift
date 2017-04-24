//
//  ProtonDevice.swift
//  Proton Dev
//
//  Created by Kirk Roerig on 4/21/17.
//  Copyright © 2017 Kirk Roerig. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Vec3 {
    var x, y, z: Float;
};

let G : Float  = 9.8; // m/s^2

let CSCS_UUID = CBUUID(string: "1816"); // cycling speed and cadance service
let CSCS_BREAK_CHAR_UUID = CBUUID(string: "2A5B");

let BAS_UUID  = CBUUID(string: "180F"); // battery charge service
let BAS_CHARGE_CHAR_UUID = CBUUID(string: "2A19");

let DIS_UUID  = CBUUID(string: "180A"); // Device information service
let DIS_MANU_NAME_CHAR_UUID = CBUUID(string: "2A29");

let CMDS_UUID = CBUUID(string: "1803"); // Command service
let CMDS_CMD_CHAR_UUID = CBUUID(string: "2345")

let SVC_UUIDS = [ CSCS_UUID, BAS_UUID, DIS_UUID, CMDS_UUID ];
let SVC_CHAR_MAP = [
    CSCS_UUID: [CSCS_BREAK_CHAR_UUID],
    BAS_UUID: [BAS_CHARGE_CHAR_UUID],
    DIS_UUID: [DIS_MANU_NAME_CHAR_UUID],
    CMDS_UUID: [CMDS_CMD_CHAR_UUID]
];

protocol ProtonDeviceDelegate {
    func discovered(proton: CBPeripheral);
    func connected(toProton: CBPeripheral, withError: Error?);
    func disconnected(error: Error?);
    func accelerationEvent(acceleration: Vec3);
}

class ProtonDevice: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var cenMan: CBCentralManager?;
    var delegate : ProtonDeviceDelegate?;
    var discoveredProtons : [CBPeripheral]?;
    var myProton : CBPeripheral?;
    var cscsChar : CBCharacteristic?;
    var cmdsChar : CBCharacteristic?;
    var interogatedServices = 0;
    
    override init() {
        super.init()
        cenMan = CBCentralManager(delegate: self, queue: nil);
    }
    
    init(delegate : ProtonDeviceDelegate) {
        super.init()
        self.delegate = delegate;
    }
    
    public func startScan() {
        cenMan?.scanForPeripherals(withServices: SVC_UUIDS, options: nil);
        
    }
    
    public func connect(toProton proton: CBPeripheral)
    {
        myProton = proton;
        myProton?.delegate = self;
        cenMan?.stopScan();
        cenMan?.connect(myProton!, options: nil);
    }
    
    public func disconnect()
    {
        if myProton != nil {
            cenMan?.cancelPeripheralConnection(myProton!);
        }
        
        discoveredProtons?.removeAll();
        myProton = nil;
        interogatedServices = 0;
    }
    
    public func sendCommand(cmdByte: UInt8)
    {
        myProton?.writeValue(Data(bytes: [cmdByte]), for: cmdsChar!, type: CBCharacteristicWriteType.withResponse);
    }
    
    
//    ___      _               _         __  __     _   _            _
//   |   \ ___| |___ __ _ __ _| |_ ___  |  \/  |___| |_| |_  ___  __| |___
//   | |) / -_) / -_) _` / _` |  _/ -_) | |\/| / -_)  _| ' \/ _ \/ _` (_-<
//   |___/\___|_\___\__, \__,_|\__\___| |_|  |_\___|\__|_||_\___/\__,_/__/
//                  |___/
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .poweredOn:
            cenMan?.scanForPeripherals(withServices: SVC_UUIDS, options: nil);
            break;
        default:
            print("Unhandled");
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "Proton" {
            discoveredProtons?.append(peripheral);
            delegate?.discovered(proton: peripheral);
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(SVC_UUIDS);
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        disconnect(); // cleanup
        delegate?.disconnected(error: error);
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.disconnected(error: error);
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            myProton!.discoverCharacteristics(SVC_CHAR_MAP[service.uuid], for: service);
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            delegate?.connected(toProton: myProton!, withError: error);
            return;
        }
        
        interogatedServices += 1;
        
        switch service.uuid {
        case CSCS_UUID:
            cscsChar = service.characteristics?.first;
            myProton?.setNotifyValue(true, for: cscsChar!);
        case CMDS_UUID:
            cmdsChar = service.characteristics?.first;
        default:
            print("Unhandled"); // NOOP
        }
        
        if interogatedServices == myProton?.services?.count {
            delegate?.connected(toProton: myProton!, withError: error);
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {

    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case CSCS_BREAK_CHAR_UUID:
            let INT_G : Float = 16.0;
            var vec : [Int16] = [0,0,0];

            _ = vec.withUnsafeMutableBufferPointer({ (ptr: inout UnsafeMutableBufferPointer<Int16>) in
                characteristic.value?.copyBytes(to: ptr);
            });            
            
            delegate?.accelerationEvent(acceleration: Vec3(
                x: Float(vec[0]) * G / INT_G,
                y: Float(vec[1]) * G / INT_G,
                z: Float(vec[2]) * G / INT_G
            ));
            
        default:
            print("Unhandled"); // NOOP
        }
    }
    
    static let SharedInstance = ProtonDevice();
}
