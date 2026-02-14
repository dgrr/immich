import Flutter
import Photos

class FileTrashPlugin: NSObject, FlutterPlugin {
  static let channelName = "file_trash"
  
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = FileTrashPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "moveToTrash":
      guard let args = call.arguments as? [String: Any],
            let assetIds = args["assetIds"] as? [String] else {
        result(FlutterError(code: "INVALID_ARGS", message: "assetIds required", details: nil))
        return
      }
      moveToTrash(assetIds: assetIds, result: result)
      
    case "restoreFromTrash":
      guard let args = call.arguments as? [String: Any],
            let mediaId = args["mediaId"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "mediaId required", details: nil))
        return
      }
      restoreFromTrash(assetId: mediaId, result: result)
      
    case "hasDeletePermission":
      result(PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized)
      
    case "requestDeletePermission":
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
        DispatchQueue.main.async {
          result(status == .authorized)
        }
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func moveToTrash(assetIds: [String], result: @escaping FlutterResult) {
    guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized else {
      result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access required", details: nil))
      return
    }
    
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
    guard fetchResult.count > 0 else {
      result(true)
      return
    }
    
    var assets: [PHAsset] = []
    fetchResult.enumerateObjects { asset, _, _ in
      assets.append(asset)
    }
    
    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
    }) { success, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "DELETE_FAILED", message: error.localizedDescription, details: nil))
        } else {
          result(success)
        }
      }
    }
  }
  
  private func restoreFromTrash(assetId: String, result: @escaping FlutterResult) {
    // iOS doesn't support programmatic restore from Recently Deleted
    result(FlutterError(code: "UNSUPPORTED", message: "iOS does not support restoring from trash programmatically", details: nil))
  }
}
