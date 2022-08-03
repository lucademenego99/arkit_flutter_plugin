import Foundation
import ARKit

class FlutterArkitView: NSObject, FlutterPlatformView {
    let sceneView: ARSCNView
    let channel: FlutterMethodChannel
    
    var forceTapOnCenter: Bool = false
    var configuration: ARConfiguration? = nil
    
    init(withFrame frame: CGRect, viewIdentifier viewId: Int64, messenger msg: FlutterBinaryMessenger) {
        self.sceneView = ARSCNView(frame: frame)
        self.sceneView.preferredFramesPerSecond = 30    // Limit FPS to 30: there are heat problems with 60
        self.channel = FlutterMethodChannel(name: "arkit_\(viewId)", binaryMessenger: msg)
        
        super.init()
        
        self.sceneView.delegate = self
        self.channel.setMethodCallHandler(self.onMethodCalled)
    }
    
    func view() -> UIView { return sceneView }
    
    func onMethodCalled(_ call :FlutterMethodCall, _ result:FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, Any>
        
        if configuration == nil && call.method != "init" {
            logPluginError("plugin is not initialized properly", toChannel: channel)
            result(nil)
            return
        }
        
        switch call.method {
        case "init":
            initalize(arguments!, result)
            result(nil)
            break
        case "addARKitNode":
            onAddNode(arguments!)
            result(nil)
            break
        case "onUpdateNode":
            onUpdateNode(arguments!)
            result(nil)
            break
        case "removeARKitNode":
            onRemoveNode(arguments!)
            result(nil)
            break
        case "removeARKitAnchor":
            onRemoveAnchor(arguments!)
            result(nil)
            break
        case "getNodeBoundingBox":
            onGetNodeBoundingBox(arguments!, result)
            break
        case "transformationChanged":
            onTransformChanged(arguments!)
            result(nil)
            break
        case "isHiddenChanged":
            onIsHiddenChanged(arguments!)
            result(nil)
            break
        case "updateSingleProperty":
            onUpdateSingleProperty(arguments!)
            result(nil)
            break
        case "updateMaterials":
            onUpdateMaterials(arguments!)
            result(nil)
            break
        case "performHitTest":
            onPerformHitTest(arguments!, result)
            break
        case "updateFaceGeometry":
            onUpdateFaceGeometry(arguments!, result)
            break
        case "getLightEstimate":
            onGetLightEstimate(result)
            result(nil)
            break
        case "projectPoint":
            onProjectPoint(arguments!, result)
            break
        case "cameraProjectionMatrix":
            onCameraProjectionMatrix(result)
            break
        case "pointOfViewTransform":
            onPointOfViewTransform(result)
            break
        case "playAnimation":
            onPlayAnimation(arguments!)
            result(nil)
            break
        case "stopAnimation":
            onStopAnimation(arguments!)
            result(nil)
            break
        case "dispose":
            onDispose(result)
            result(nil)
            break
        case "cameraEulerAngles":
            onCameraEulerAngles(result)
            break
        case "snapshot":
            onGetSnapshot(result)
            break
        case "getViewportSize":
            onGetViewportSize(result)
            break
        case "getCameraFOV":
            // FOV calculated based on the section "Projection Matrix with Viewport" available at
            // https://stackoverflow.com/questions/47536580/get-camera-field-of-view-in-ios-11-arkit
            let imageResolution = self.sceneView.session.currentFrame!.camera.imageResolution
            let viewSize = self.sceneView.bounds.size
            let projection = self.sceneView.session.currentFrame!.camera.projectionMatrix(for: .portrait, viewportSize: viewSize, zNear: 1, zFar: 1000)
            let yScale = projection[1,1] // = 1/tan(fovy/2)
            result(2 * atan(1/yScale) * 180/Float.pi)
            break;
        case "getCameraRealFOV":
            // FOV calculated based on the section "Projection Matrix" available at
            // https://stackoverflow.com/questions/47536580/get-camera-field-of-view-in-ios-11-arkit
            let projection = self.sceneView.session.currentFrame!.camera.projectionMatrix
            let yScale = projection[1,1] // = 1/tan(fovy/2)
            result(2 * atan(1/yScale) * 180/Float.pi)
            break;
        case "getCameraRealHorizontalFOV":
            // FOV calculated based on the section "Projection Matrix" available at
            // https://stackoverflow.com/questions/47536580/get-camera-field-of-view-in-ios-11-arkit
            let imageResolution = self.sceneView.session.currentFrame!.camera.imageResolution
            let projection = self.sceneView.session.currentFrame!.camera.projectionMatrix
            let yScale = projection[1,1] // = 1/tan(fovy/2)
            result((2 * atan(1/yScale) * 180/Float.pi) * (Float(imageResolution.width / imageResolution.height)))
            break;
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func onDispose(_ result:FlutterResult) {
        sceneView.session.pause()
        self.channel.setMethodCallHandler(nil)
        result(nil)
    }
}
