//
//  ScannerBrowser.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//  Copyright © 2017 Scott J. Kleper. All rights reserved.
//

import Foundation
import ImageCaptureCore

protocol ScannerBrowserDelegate: class {
    func scannerBrowser(_ scannerBrowser: ScannerBrowser, didFinishBrowsingWithScanner scanner: ICScannerDevice?)
}

class ScannerBrowser: NSObject, ICDeviceBrowserDelegate {
    let deviceBrowser = ICDeviceBrowser()
    var selectedScanner: ICScannerDevice?
    var scanners = [ICScannerDevice]()
    let configuration: ScanConfiguration
    
    weak var delegate: ScannerBrowserDelegate?
    
    init(configuration: ScanConfiguration) {
        self.configuration = configuration
        
        super.init()
        
        deviceBrowser.delegate = self
        let mask = ICDeviceTypeMask(rawValue:
            ICDeviceTypeMask.scanner.rawValue |
                ICDeviceLocationTypeMask.local.rawValue |
                ICDeviceLocationTypeMask.bonjour.rawValue |
                ICDeviceLocationTypeMask.shared.rawValue)
        deviceBrowser.browsedDeviceTypeMask = mask!
    }
    
    func browse() {
        print("Starting")
        deviceBrowser.start()
    }
    
    func stopBrowsing() {
        guard deviceBrowser.isBrowsing else { return }
        
        deviceBrowser.stop()
        
        delegate?.scannerBrowser(self, didFinishBrowsingWithScanner: selectedScanner)
    }
    
    func deviceMatchesSpecified(device: ICScannerDevice) -> Bool {
        // If no name was specified, this is perforce an exact match
        guard let desiredName = configuration.config[ScanlineConfigOptionName] as? String else { return true }
        guard let deviceName = device.name else { return false }
        
        // "Fuzzy" match -- case-free compare of prefix
        if configuration.config[ScanlineConfigOptionExactName] == nil &&
            deviceName.lowercased().starts(with: desiredName.lowercased()) {
            return true
        }
        
        if desiredName == deviceName {
            return true
        }
        
        return false
    }
    
    func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        print("didAdd \(device.name ?? "nil"), moreComing: \(moreComing)")
        
        guard let scannerDevice = device as? ICScannerDevice else { return }
        scanners.append(scannerDevice)
        
        if deviceMatchesSpecified(device: scannerDevice) {
            selectedScanner = scannerDevice
            stopBrowsing()
        }
    }
    
    func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
    }
}

