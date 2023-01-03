import Foundation
import ARKit

#if !DISABLE_TRUEDEPTH_API
func createFaceTrackingConfiguration(_ arguments: Dictionary<String, Any>) -> ARFaceTrackingConfiguration? {
    if(ARFaceTrackingConfiguration.isSupported) {
        let config = ARFaceTrackingConfiguration()
        if #available(iOS 15.4, *) {
            for videoFormat in ARFaceTrackingConfiguration.supportedVideoFormats {
                if videoFormat.captureDeviceType == .builtInLiDARDepthCamera {
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
