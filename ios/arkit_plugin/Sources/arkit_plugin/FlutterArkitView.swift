import ARKit
import Flutter
import Foundation
import UIKit

class FlutterArkitView: NSObject, FlutterPlatformView {
    let sceneView: ARSCNView
    let channel: FlutterMethodChannel

    var forceTapOnCenter: Bool = false
    var configuration: ARConfiguration? = nil
    var isDisposed: Bool = false
    var isPaused: Bool = false

    init(withFrame frame: CGRect, viewIdentifier viewId: Int64, messenger msg: FlutterBinaryMessenger) {
        sceneView = ARSCNView(frame: frame)
        sceneView.preferredFramesPerSecond = 30    // Limit FPS to 30: there are heat problems with 60
        channel = FlutterMethodChannel(name: "arkit_\(viewId)", binaryMessenger: msg)

        super.init()

        sceneView.delegate = self
        channel.setMethodCallHandler(onMethodCalled)
    }

    func view() -> UIView { return sceneView }

    func onMethodCalled(_ call: FlutterMethodCall, _ result: FlutterResult) {
        let arguments = call.arguments as? [String: Any]

        if configuration == nil && call.method != "init" {
            logPluginError("plugin is not initialized properly", toChannel: channel)
            result(nil)
            return
        }

        switch call.method {
        case "init":
            initalize(arguments!, result)
            result(nil)
        case "addARKitNode":
            onAddNode(arguments!)
            result(nil)
        case "onUpdateNode":
            onUpdateNode(arguments!)
            result(nil)
        case "removeARKitNode":
            onRemoveNode(arguments!)
            result(nil)
        case "removeARKitAnchor":
            onRemoveAnchor(arguments!)
            result(nil)
        case "addCoachingOverlay":
            if #available(iOS 13.0, *) {
                addCoachingOverlay(arguments!)
            }
            result(nil)
        case "removeCoachingOverlay":
            if #available(iOS 13.0, *) {
                removeCoachingOverlay()
            }
            result(nil)
        case "getNodeBoundingBox":
            onGetNodeBoundingBox(arguments!, result)
        case "transformationChanged":
            onTransformChanged(arguments!)
            result(nil)
        case "isHiddenChanged":
            onIsHiddenChanged(arguments!)
            result(nil)
        case "updateSingleProperty":
            onUpdateSingleProperty(arguments!)
            result(nil)
        case "updateMaterials":
            onUpdateMaterials(arguments!)
            result(nil)
        case "performHitTest":
            onPerformHitTest(arguments!, result)
        case "updateFaceGeometry":
            onUpdateFaceGeometry(arguments!)
            result(nil)
        case "getLightEstimate":
            onGetLightEstimate(result)
            result(nil)
        case "projectPoint":
            onProjectPoint(arguments!, result)
        case "cameraProjectionMatrix":
            onCameraProjectionMatrix(result)
        case "pointOfViewTransform":
            onPointOfViewTransform(result)
        case "playAnimation":
            onPlayAnimation(arguments!)
            result(nil)
        case "stopAnimation":
            onStopAnimation(arguments!)
            result(nil)
        case "dispose":
            onDispose(result)
            result(nil)
        case "cameraEulerAngles":
            onCameraEulerAngles(result)
            result(nil)
        case "cameraIntrinsics":
            onCameraIntrinsics(result)
        case "cameraImageResolution":
            onCameraImageResolution(result)
        case "snapshot":
            onGetSnapshot(result)
            break
        case "getViewportSize":
            onGetViewportSize(result)
            break
        case "getCameraFOV":
            // FOV calculated based on the section "Projection Matrix with Viewport" available at
            // https://stackoverflow.com/questions/47536580/get-camera-field-of-view-in-ios-11-arkit
            guard let currentFrame = self.sceneView.session.currentFrame else {
                result(nil)
                break
            }
            let viewSize = self.sceneView.bounds.size
            let orientation = self.sceneView.window?.windowScene?.interfaceOrientation ?? .portrait
            let projection = currentFrame.camera.projectionMatrix(for: orientation, viewportSize: viewSize, zNear: 1, zFar: 1000)
            let yScale = projection[1, 1] // = 1/tan(fovy/2)
            result(2 * atan(1 / yScale) * 180 / Float.pi)
            break
        case "getCameraRealFOV":
            // FOV calculated based on the section "Projection Matrix" available at
            // https://stackoverflow.com/questions/47536580/get-camera-field-of-view-in-ios-11-arkit
            guard let currentFrame = self.sceneView.session.currentFrame else {
                result(nil)
                break
            }
            let projection = currentFrame.camera.projectionMatrix
            let yScale = projection[1, 1] // = 1/tan(fovy/2)
            result(2 * atan(1 / yScale) * 180 / Float.pi)
            break
        case "getCameraRealHorizontalFOV":
            // FOV calculated based on the section "Projection Matrix" available at
            // https://stackoverflow.com/questions/47536580/get-camera-field-of-view-in-ios-11-arkit
            guard let currentFrame = self.sceneView.session.currentFrame else {
                result(nil)
                break
            }
            let imageResolution = currentFrame.camera.imageResolution
            let projection = currentFrame.camera.projectionMatrix
            let yScale = projection[1, 1] // = 1/tan(fovy/2)
            let aspectRatio = Float(imageResolution.width / imageResolution.height)
            result(2 * atan((1 / yScale) * aspectRatio) * 180 / Float.pi)
            break
        case "pause":
            isPaused = true
            sceneView.session.pause()
            result(nil)
            break
        case "resume":
            isPaused = false
            if !isDisposed, let arConfiguration = configuration {
                sceneView.session.run(arConfiguration)
            }
            result(nil)
        case "capturedImage":
            onCameraCapturedImage(result)
        case "snapshotWithDepthData":
            onGetSnapshotWithDepthData(result)
        case "cameraPosition":
            onGetCameraPosition(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func sendToFlutter(_ method: String, arguments: Any?) {
        DispatchQueue.main.async {
            self.channel.invokeMethod(method, arguments: arguments)
        }
    }

    func onDispose(_ result: FlutterResult) {
        isDisposed = true
        sceneView.session.pause()
        channel.setMethodCallHandler(nil)
        result(nil)
    }
}
