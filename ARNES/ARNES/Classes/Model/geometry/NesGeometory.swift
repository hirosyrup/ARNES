//
//  NesGeometory.swift
//  SceneKitTest
//
//  Created by 岩井 宏晃 on 2017/01/05.
//  Copyright © 2017年 koalab.com. All rights reserved.
//

import Foundation
import SceneKit

class NesGeometory {
    var showBg: Bool = true
    
    func createGeometory(_ buffer: UnsafeMutablePointer<UInt32>!, width: Int, height: Int) -> SCNGeometry {
        let xyScale: Float = 0.002
        let zScale: Float = 0.02
        let xBlockWidthCoef: Float = 1.3
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
        
        let bgWidth = Float(width) * xBlockWidthCoef * xyScale
        let bHeight = Float(height) * xyScale
        let halfWidth = bgWidth / 2.0
        if self.showBg {
            vertices += [
                SCNVector3(-halfWidth, 0.0, 0.0),
                SCNVector3(bgWidth - halfWidth, 0.0, 0.0),
                SCNVector3(-halfWidth, -bHeight, 0.0),
                SCNVector3(bgWidth - halfWidth, -bHeight, 0.0),
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
        }
        
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
                        
                        let xLeft = Float(xOffset) * xBlockWidthCoef * xyScale - halfWidth
                        let xRight = Float(xOffset + num) * xBlockWidthCoef * xyScale - halfWidth
                        let yTop = Float(i) * xyScale
                        let yBottom = Float(i + 1) * xyScale
                        
                        vertices += [
                            SCNVector3(xLeft, -yTop, zScale),
                            SCNVector3(xRight, -yTop, zScale),
                            SCNVector3(xLeft, -yBottom, zScale),
                            SCNVector3(xRight, -yBottom, zScale),
                            
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
        
        return SCNGeometry(sources: [vertexSource, colorSource], elements: [indexElement])
    }
    
    private func convertColor(color: UInt32) -> SCNVector3 {
        var red = CGFloat((color >> 16) & 0xff) / 255.0
        red = red * red
        var green = CGFloat((color >> 8) & 0xff) / 255.0
        green = green * green
        var blue = CGFloat(color & 0xff) / 255.0
        blue = blue * blue
        return SCNVector3(red, green, blue)
    }
}
