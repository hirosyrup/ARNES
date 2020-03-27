//
//  Emulator.swift
//  ARNES
//
//  Created by 岩井 宏晃 on 2020/03/26.
//  Copyright © 2020 koalab. All rights reserved.
//

import Foundation

protocol EmulatorDelegate: class {
    func updateBuffer(_ buffer: UnsafeMutablePointer<UInt32>!, width: Int, height: Int)
}

class Emulator: PVNESEmulatorCoreDelegate {
    weak var delegate: EmulatorDelegate?
    private var core: PVNESEmulatorCore
    private var audio: OEGameAudio!
    private let romName = ["demo"]
    private var currentRom = 0
    private(set) var update = false
    
    init() {
        core = PVNESEmulatorCore()
        setupCore()
        core.startEmulation()
        pause()
    }
    
    func start() {
        core.setPauseEmulation(false)
    }
    
    func pause() {
        core.setPauseEmulation(true)
    }
    
    func pushButton(buttonType: PVNESButton, forPlayer: Int) {
        core.push(buttonType, forPlayer: forPlayer)
    }
    
    func releaseButton(buttonType: PVNESButton, forPlayer: Int) {
        core.release(buttonType, forPlayer: forPlayer)
    }
    
    private func setCurrentRom() {
        if core.loadFile(atPath: Bundle.main.path(forResource: self.romName[self.currentRom], ofType: "nes")) == false {
            assertionFailure("load failed")
        }
    }
    
    private func setupCore() {
        core.updateInterval = 2
        let savePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        core.batterySavesPath = savePath[0]
        
        setCurrentRom()
        
        setupAudio()
        
        core.delegate = self
    }
    
    private func setupAudio() {
        audio = OEGameAudio(core: core)
        audio.volume = 1.0
        audio.outputDeviceID = 0
        audio.start()
    }
    
    private func updatedRom() {
        if audio != nil {
            audio.stop()
            audio = nil
        }
        core.delegate = nil
        core.setPauseEmulation(true)
        
        setCurrentRom()
        
        core.resetEmulation()
        core.setPauseEmulation(false)
        
        setupAudio()
        
        core.delegate = self
    }
    
    func updateBuffer(_ buffer: UnsafeMutablePointer<UInt32>!, width: Int, height: Int) {
        if update {
            updatedRom()
            update = false
            return
        }
        delegate?.updateBuffer(buffer, width: width, height: height)
    }
}
