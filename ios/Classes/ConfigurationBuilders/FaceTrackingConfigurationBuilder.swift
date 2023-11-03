import Foundation
import ARKit

#if !DISABLE_TRUEDEPTH_API
func createFaceTrackingConfiguration(_ arguments: Dictionary<String, Any>) -> ARFaceTrackingConfiguration? {
    if(ARFaceTrackingConfiguration.isSupported) {
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = false  // Set light estimation to false explicitly
        if #available(iOS 14.5, *) {
            for videoFormat in ARFaceTrackingConfiguration.supportedVideoFormats {
                if videoFormat.captureDeviceType == .builtInUltraWideCamera {
                    config.videoFormat = videoFormat
                    break
                }
            }
        }
        return config
    }
    return nil
}
#endif
