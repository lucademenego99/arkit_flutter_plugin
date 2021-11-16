import Foundation
import ARKit

#if !DISABLE_TRUEDEPTH_API
func createFaceTrackingConfiguration(_ arguments: Dictionary<String, Any>) -> ARFaceTrackingConfiguration? {
    if(ARFaceTrackingConfiguration.isSupported) {
        let config = ARFaceTrackingConfiguration()
        NSLog(@"Size of default arfacetrackingconf is %@",NSStringFromCGSize(config.videoFormat.imageResolution))
        for videoFormat in ARFaceTrackingConfiguration.supportedVideoFormats {
            NSLog(@"Another videoformat: %@",NSStringFromCGSize(videoFormat.imageResolution))
        }
        for videoFormat in ARFaceTrackingConfiguration.supportedVideoFormats {
            if videoFormat.captureDeviceType == .builtInTrueDepthCamera {
                config.videoFormat = videoFormat
                break
            }
        }
        return config
    }
    return nil
}
#endif
