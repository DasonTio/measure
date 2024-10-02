//
//  ArContainer.swift
//  measure
//
//  Created by Dason Tiovino on 02/10/24.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

class ViewController: UIViewController,ARSessionDelegate{
    var modelEntities: [ModelEntity] = []
    var tapeEntity: ModelEntity? = nil;
    var distanceBetweenTwoPoints = 0;
    var lockDistanceThreshold:Float = 0.4;

    private var focusEntity: FocusEntity!
    private var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView = ARView(frame: view.bounds)
        arView.session.delegate = self
        view.addSubview(arView)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        
        focusEntity = FocusEntity(on: arView, style: .classic(color: .white))
        
        NotificationCenter.default.addObserver(forName: .placeModel, object: nil, queue: .main) { _ in
            self.placeModel(in: self.arView, focusEntity: self.focusEntity)
        }
        
    }
    
    /// Place Model and check if there is any object nearby to lock the position
    /// on that object position to make the mesh
    func placeModel(in arView: ARView, focusEntity: FocusEntity?) {
        guard let focusEntity = focusEntity else { return }
        var isLockedEntity:ModelEntity?
        
        for modelEntity in modelEntities {
            let modelPosition = modelEntity.position(relativeTo: nil)
            let distanceToModel = simd_distance(focusEntity.position, modelPosition)
            
            print(distanceToModel)
            if distanceToModel < lockDistanceThreshold {
                isLockedEntity = modelEntity
            }
        }
        
        do {
            let entity = try ModelEntity.loadModel(named: "Reticle")
            let focusTransform = focusEntity.transformMatrix(relativeTo: nil)
            self.modelEntities.append(entity)
            
            let anchorEntity = AnchorEntity(world: isLockedEntity?.transformMatrix(relativeTo: nil) ?? focusTransform )
            anchorEntity.addChild(modelEntities[self.modelEntities.count - 1])
            arView.scene.addAnchor(anchorEntity)
        } catch {
            print("Failed to load model: \(error)")
        }
        
        let modelsLength = self.modelEntities.count
        if(modelsLength >= 2){
            let positionA = modelEntities[modelsLength-2].position(relativeTo: nil)
            let positionB = modelEntities[modelsLength-1].position(relativeTo: nil)
            
            drawLine(from: positionA, to: positionB, distance: distance(positionA, positionB))
        }
        
        let modelsPoints = self.modelEntities.map{$0.position(relativeTo: nil)}
        print(modelsPoints)
        print(hasDuplicatePoints(in: modelsPoints))
        if(hasDuplicatePoints(in: modelsPoints)){
            
            let modelEntity = drawMesh(from: modelsPoints)
            let anchor = AnchorEntity(world: self.modelEntities.first!.position) // Place 1 meter in front of the camera
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
        }
        
    }
    
    /// Check For Duplicates
    func hasDuplicatePoints(in points: [SIMD3<Float>]) -> Bool {
        for i in 0..<points.count {
            print(points[i])
            for j in (i + 1)..<points.count {
                if points[i] == points[j] {
                    return true
                }
            }
        }
        return false
    }
    
    /// Draw Line using start & end position
    func drawLine(from start: SIMD3<Float>, to end: SIMD3<Float>, distance: Float) {
        let vector = end - start
        let length = simd_length(vector)
        
        let boxMesh = MeshResource.generateBox(size: [0.02, 0.02, length])
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let lineEntity = ModelEntity(mesh: boxMesh, materials: [material])
        
        lineEntity.position = (start + end) / 2.0
        
        lineEntity.look(at: end, from: lineEntity.position, relativeTo: nil)
        
        let distance = String(format: "%.2f m", distance)
        let textMesh = MeshResource.generateText(distance, extrusionDepth: 0.01, font: .systemFont(ofSize: 0.1), containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping)
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        textEntity.position = (start + end) / 2.0
        textEntity.position.y += 0.02
        
        
        let anchor = AnchorEntity()
        anchor.addChild(lineEntity)
        anchor.addChild(textEntity)
        arView.scene.addAnchor(anchor)
    }
    
    

    // MARK: Not Consistent
    /// Draw Mesh from all of the object position
    func drawMesh(from points: [SIMD3<Float>]) -> ModelEntity {
        var indices: [UInt32] = []
        for i in 1..<(points.count - 2) {
            indices.append(0)
            indices.append(UInt32(i))
            indices.append(UInt32(i + 1))
        }

        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = MeshBuffers.Positions(points)
        meshDescriptor.primitives = .triangles(indices)

        let mesh = try! MeshResource.generate(from: [meshDescriptor])
        let material = SimpleMaterial(color: .black, roughness: 0.5, isMetallic: false)

        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        return modelEntity
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ARViewContainer>) -> ViewController {
        let viewController = ViewController()
        return viewController
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
}
