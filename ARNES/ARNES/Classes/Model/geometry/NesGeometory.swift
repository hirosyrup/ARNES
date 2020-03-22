//
//  NesGeometory.swift
//  SceneKitTest
//
//  Created by 岩井 宏晃 on 2017/01/05.
//  Copyright © 2017年 koalab.com. All rights reserved.
//

import Foundation
import SceneKit
import GameController

protocol NesGeometoryDelegate: class {
    func updateGeometory(geometory: SCNGeometry)
}

class NesGeometory: PVNESEmulatorCoreDelegate {
    
    weak var delegate: NesGeometoryDelegate?
    private var core: PVNESEmulatorCore
    private var audio: OEGameAudio!
    private var currentController: GCController?
    private let romName = ["demo"]
    private var currentRom = 0
    private(set) var isYPressed = false
    private(set) var update = false
    
    init() {
        core = PVNESEmulatorCore()
        setupCore()
        
        let displayLink = CADisplayLink(target: self, selector: #selector(updateController))
        displayLink.frameInterval = 1
        displayLink.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
        
        NotificationCenter.default.addObserver(self, selector: #selector(connectNotification), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnectNotification), name: .GCControllerDidDisconnect, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func start() {
        core.startEmulation()
    }
    
    func pause() {
        core.setPauseEmulation(true)
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
    
    @objc func updateController() {
        guard let pad = currentController?.extendedGamepad else {
            return
        }
        
        if pad.buttonY.isPressed {
            isYPressed = true
        } else {
            if isYPressed {
                currentRom += 1
                currentRom %= romName.count
                update = true
            }
            isYPressed = false
        }

        if pad.buttonX.isPressed {
            core.push(.B, forPlayer: 0)
        } else {
            core.release(.B, forPlayer: 0)
        }
        
        if pad.buttonA.isPressed {
            core.push(.A, forPlayer: 0)
        } else {
            core.release(.A, forPlayer: 0)
        }
        
        if pad.rightShoulder.isPressed {
            core.push(.start, forPlayer: 0)
        } else {
            core.release(.start, forPlayer: 0)
        }
        
        if pad.rightTrigger.isPressed {
            core.push(.select, forPlayer: 0)
        } else {
            core.release(.select, forPlayer: 0)
        }
        
        let xAxis = pad.dpad.xAxis.value
        let yAxis = pad.dpad.yAxis.value
        
        if xAxis > 0.5 || xAxis < -0.5 {
            if xAxis > 0.5 {
                core.push(.right, forPlayer: 0)
                core.release(.left, forPlayer: 0)
            } else {
                core.push(.left, forPlayer: 0)
                core.release(.right, forPlayer: 0)
            }
        } else {
            core.release(.left, forPlayer: 0)
            core.release(.right, forPlayer: 0)
        }
        
        if yAxis > 0.5 || yAxis < -0.5 {
            if yAxis > 0.5 {
                core.push(.up, forPlayer: 0)
                core.release(.down, forPlayer: 0)
            } else {
                core.push(.down, forPlayer: 0)
                core.release(.up, forPlayer: 0)
            }
        } else {
            core.release(.up, forPlayer: 0)
            core.release(.down, forPlayer: 0)
        }
    }
    
    @objc func connectNotification(notification: Notification) {
        let controllers = GCController.controllers()
        currentController = controllers.first
    }
    
    @objc func disconnectNotification(notification: Notification) {
        currentController = nil
    }
    
    func updateBuffer(_ buffer: UnsafeMutablePointer<UInt32>!, width: Int, height: Int) {
        if update {
            updatedRom()
            update = false
            return
        }
        DispatchQueue.main.async {
            var current: UInt32 = 0
            var next: UInt32 = 0
            var maxCount: UInt32 = 1
            var maxColor: UInt32 = 0
            let blockNum = 16
            let roop = (width / 16) * height
            var tmp = Dictionary<UInt32, UInt32>()
            for i in 0 ..< roop {
                for j in 1..<blockNum {
                    current = buffer[i * blockNum + (j-1)]
                    next = buffer[i * blockNum + j]
                    if current != next {
                        break
                    }
                    if let value = tmp[current] {
                        if value >= maxCount {
                            maxCount = value
                            maxColor = current
                        }
                        tmp[current] = value + 1
                    } else {
                        tmp[current] = 1
                    }
                }
            }
            
            var vertices = [SCNVector3]()
            var indices = [Int32]()
            var colors = [SCNVector3]()
            
            vertices += [
                SCNVector3(0.0, 0.0, 0.0),
                SCNVector3(332.8, 0.0, 0.0),
                SCNVector3(0.0, -240.0, 0.0),
                SCNVector3(332.8, -240.0, 0.0),
            ]
            
            indices += [
                // 手前
                0, 2, 1,
                1, 2, 3,
            ]
            
            let color = self.convertColor(color: maxColor)
            colors += [
                color,
                color,
                color,
                color,
            ]
            
            var currentColor: UInt32 = 0
            var colorTmp: UInt32 = 0
            var num = 0
            var xOffset = 0
            
            for i in 0 ..< height {
                colorTmp = 0
                num = 0
                xOffset = 0
                
                for j in 0 ..< width {
                    currentColor = buffer[i * width + j]
                    
                    if j == 0 {
                        colorTmp = currentColor
                        num += 1
                    } else {
                        if colorTmp == currentColor {
                            num += 1
                            if j < width - 1 {
                                continue;
                            }
                        }
                        
                        if colorTmp != maxColor {
                            let offset: Int32 = Int32(vertices.count)
                            let pos0: Int32 = 0 + offset
                            let pos1: Int32 = 1 + offset
                            let pos2: Int32 = 2 + offset
                            let pos3: Int32 = 3 + offset
                            let pos4: Int32 = 4 + offset
                            let pos5: Int32 = 5 + offset
                            let pos6: Int32 = 6 + offset
                            let pos7: Int32 = 7 + offset
                            indices += [
                                // 手前
                                pos0, pos2, pos1,
                                pos1, pos2, pos3,
                                
                                // 左
                                pos4, pos6, pos0,
                                pos0, pos6, pos2,
                                
                                // 右
                                pos5, pos1, pos3,
                                pos5, pos3, pos7,
                                
                                // 上
                                pos4, pos0, pos5,
                                pos5, pos0, pos1,
                                
                                // 下
                                pos6, pos7, pos2,
                                pos7, pos3, pos2,
                                
                                // 奥
                                pos4, pos6, pos5,
                                pos5, pos6, pos7,
                            ]
                            
                            let xLeft = Float(xOffset) * 1.3
                            let xRight = Float(xOffset + num) * 1.3
                            let yTop = Float(i)
                            let yBottom = Float(i + 1)
                            
                            vertices += [
                                SCNVector3(xLeft, -yTop, 1.3),
                                SCNVector3(xRight, -yTop, 1.3),
                                SCNVector3(xLeft, -yBottom, 1.3),
                                SCNVector3(xRight, -yBottom, 1.3),
                                
                                SCNVector3(xLeft, -yTop, 0.0),
                                SCNVector3(xRight, -yTop, 0.0),
                                SCNVector3(xLeft, -yBottom, 0.0),
                                SCNVector3(xRight, -yBottom, 0.0),
                            ]
                            
                            let color = self.convertColor(color: colorTmp)
                            colors += [
                                color,
                                color,
                                color,
                                color,
                                color,
                                color,
                                color,
                                color,
                            ]
                        }
                        
                        xOffset += num
                        colorTmp = currentColor
                        num = 1
                    }
                }
            }
            let vertexSource = SCNGeometrySource(vertices: vertices)
            let indexElement = SCNGeometryElement(indices: indices, primitiveType: .triangles)
            let colorData = Data(bytes: colors, count: MemoryLayout<SCNVector3>.size * colors.count)
            let colorSource = SCNGeometrySource(data: colorData, semantic: SCNGeometrySource.Semantic.color, vectorCount: colors.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<SCNVector3>.size)
            
            let geometory = SCNGeometry(sources: [vertexSource, colorSource], elements: [indexElement])
            self.delegate?.updateGeometory(geometory: geometory)
        }
    }
    
    func convertColor(color: UInt32) -> SCNVector3 {
        var red = CGFloat((color >> 16) & 0xff) / 255.0
        red = red * red
        var green = CGFloat((color >> 8) & 0xff) / 255.0
        green = green * green
        var blue = CGFloat(color & 0xff) / 255.0
        blue = blue * blue
        return SCNVector3(red, green, blue)
    }
    
//    func updateDispData(_ datasList: [[DispData]]!, dataNum: Int, maxColorRed: CGFloat, maxColorGreen: CGFloat, maxColorBlue: CGFloat) {
//        let verticesNum = dataNum * 8 + 4
//        let indicesNum = dataNum * 24 + 6
//        let colorsNum = dataNum * 8 + 4
//        var vertices = UnsafeMutablePointer<SCNVector3>.allocate(capacity: verticesNum)
//        var indices = UnsafeMutablePointer<Int32>.allocate(capacity: indicesNum)
//        var colors = UnsafeMutablePointer<SCNVector3>.allocate(capacity: colorsNum)
//        
//        vertices[0] = SCNVector3(0.0, 0.0, 0.0)
//        vertices += 1
//        vertices[0] = SCNVector3(256.0, 0.0, 0.0)
//        vertices += 1
//        vertices[0] = SCNVector3(0.0, -240.0, 0.0)
//        vertices += 1
//        vertices[0] = SCNVector3(256.0, -240.0, 0.0)
//        vertices += 1
//        
//        indices[0] = 0
//        indices += 1
//        indices[0] = 2
//        indices += 1
//        indices[0] = 1
//        indices += 1
//        indices[0] = 1
//        indices += 1
//        indices[0] = 2
//        indices += 1
//        indices[0] = 3
//        indices += 1
//        
//        let color = SCNVector3(maxColorRed, maxColorGreen, maxColorBlue)
//        colors[0] = color
//        colors += 1
//        colors[0] = color
//        colors += 1
//        colors[0] = color
//        colors += 1
//        colors[0] = color
//        colors += 1
//        
//        
//        let rowCount = datasList.count
//        var offsetCount = 0
//        for i in 0 ..< rowCount {
//            let datas = datasList[i]
//            let colCount = datas.count
//            var xOffset = 0
//            for j in 0 ..< colCount {
//                let data = datas[j]
//                
//                if data.isBg == false {
//                    
//                    let xLeft = Float(xOffset)
//                    let xRight = Float(xOffset + data.num)
//                    let yTop = Float(i)
//                    let yBottom = Float(i + 1)
//                    
//                    vertices[0] = SCNVector3(xLeft, -yTop, 1.0)
//                    vertices += 1
//                    vertices[0] = SCNVector3(xRight, -yTop, 1.0)
//                    vertices += 1
//                    vertices[0] = SCNVector3(xLeft, -yBottom, 1.0)
//                    vertices += 1
//                    vertices[0] = SCNVector3(xRight, -yBottom, 1.0)
//                    vertices += 1
//                    vertices[0] = SCNVector3(xLeft, -yTop, 0.0)
//                    vertices += 1
//                    vertices[0] = SCNVector3(xRight, -yTop, 0.0)
//                    vertices += 1
//                    vertices[0] = SCNVector3(xLeft, -yBottom, 0.0)
//                    vertices += 1
//                    vertices[0] = SCNVector3(xRight, -yBottom, 0.0)
//                    vertices += 1
//                    
//                    let offset: Int32 = Int32(offsetCount)
//                    offsetCount += 8
//                    let pos0: Int32 = 0 + offset
//                    let pos1: Int32 = 1 + offset
//                    let pos2: Int32 = 2 + offset
//                    let pos3: Int32 = 3 + offset
//                    let pos4: Int32 = 4 + offset
//                    let pos5: Int32 = 5 + offset
//                    let pos6: Int32 = 6 + offset
//                    let pos7: Int32 = 7 + offset
//                    
//                    indices[0] = pos0
//                    indices += 1
//                    indices[0] = pos2
//                    indices += 1
//                    indices[0] = pos1
//                    indices += 1
//                    indices[0] = pos1
//                    indices += 1
//                    indices[0] = pos2
//                    indices += 1
//                    indices[0] = pos3
//                    indices += 1
//                    
//                    indices[0] = pos4
//                    indices += 1
//                    indices[0] = pos5
//                    indices += 1
//                    indices[0] = pos7
//                    indices += 1
//                    indices[0] = pos4
//                    indices += 1
//                    indices[0] = pos7
//                    indices += 1
//                    indices[0] = pos6
//                    indices += 1
//                    
//                    indices[0] = pos4
//                    indices += 1
//                    indices[0] = pos6
//                    indices += 1
//                    indices[0] = pos0
//                    indices += 1
//                    indices[0] = pos0
//                    indices += 1
//                    indices[0] = pos6
//                    indices += 1
//                    indices[0] = pos2
//                    indices += 1
//                    
//                    indices[0] = pos5
//                    indices += 1
//                    indices[0] = pos1
//                    indices += 1
//                    indices[0] = pos3
//                    indices += 1
//                    indices[0] = pos5
//                    indices += 1
//                    indices[0] = pos3
//                    indices += 1
//                    indices[0] = pos7
//                    indices += 1
//                    
//                    indices[0] = pos4
//                    indices += 1
//                    indices[0] = pos0
//                    indices += 1
//                    indices[0] = pos5
//                    indices += 1
//                    indices[0] = pos5
//                    indices += 1
//                    indices[0] = pos0
//                    indices += 1
//                    indices[0] = pos1
//                    indices += 1
//                    
//                    indices[0] = pos6
//                    indices += 1
//                    indices[0] = pos7
//                    indices += 1
//                    indices[0] = pos2
//                    indices += 1
//                    indices[0] = pos7
//                    indices += 1
//                    indices[0] = pos3
//                    indices += 1
//                    indices[0] = pos2
//                    indices += 1
//                    
//                    let color = SCNVector3(data.red, data.green, data.blue)
//                    colors[0] = color
//                    colors += 1
//                    colors[0] = color
//                    colors += 1
//                    colors[0] = color
//                    colors += 1
//                    colors[0] = color
//                    colors += 1
//                    colors[0] = color
//                    colors += 1
//                    colors[0] = color
//                    colors += 1
//                    colors[0] = color
//                    colors += 1
//                    colors[0] = color
//                    colors += 1
//                }
//                
//                xOffset += data.num
//            }
//        }
//        vertices -= verticesNum
//        let vertexSource = SCNGeometrySource(vertices: vertices, count: verticesNum)
//        indices -= indicesNum
//        let indicesArray = Array(UnsafeBufferPointer(start: indices, count: indicesNum))
//        let indexElement = SCNGeometryElement(indices: indicesArray, primitiveType: .triangles)
//        colors -= colorsNum
//        let colorData = Data(bytes: colors, count: MemoryLayout<SCNVector3>.size * colorsNum)
//        let colorSource = SCNGeometrySource(data: colorData, semantic: SCNGeometrySource.Semantic.color, vectorCount: colorsNum, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<SCNVector3>.size)
//        
//        let geometory = SCNGeometry(sources: [vertexSource, colorSource], elements: [indexElement])
//        delegate?.updateGeometory(geometory: geometory)
//        vertices.deallocate(capacity: verticesNum)
//        indices.deallocate(capacity: indicesNum)
//        colors.deallocate(capacity: colorsNum)
//    }
}
