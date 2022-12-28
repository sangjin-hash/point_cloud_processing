//
//  SCNFile.swift
//  Creadto
//
//  Created by 이상진 on 2022/12/26.
//

import Foundation
import SceneKit

final class SCNFile {
    static func buildNode(points: [PointCloudVertex]) -> SCNNode {
        let vertexData = NSData(
            bytes: points,
            length: MemoryLayout<PointCloudVertex>.size * points.count
        )
        let positionSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let colorSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.color,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: MemoryLayout<Float>.size * 3,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let elements = SCNGeometryElement(
            data: nil,
            primitiveType: .point,
            primitiveCount: points.count,
            bytesPerIndex: MemoryLayout<Int>.size
        )
        
        elements.maximumPointScreenSpaceRadius = 2.0
        elements.minimumPointScreenSpaceRadius = 2.0
        elements.pointSize = 2.0
        
        let pointsGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [elements])
        pointsGeometry.firstMaterial?.lightingModel = SCNMaterial.LightingModel.constant
        return SCNNode(geometry: pointsGeometry)
    }
}
