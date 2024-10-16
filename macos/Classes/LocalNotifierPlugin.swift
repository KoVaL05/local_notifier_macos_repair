import Cocoa
import FlutterMacOS
import UserNotifications

public class LocalNotifierPlugin: NSObject, FlutterPlugin {
    var registrar: FlutterPluginRegistrar!
    var channel: FlutterMethodChannel!

    var notificationDict: [String: UNNotificationRequest] = [:]

    public override init() {
        super.init()
        requestNotificationPermissions()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "local_notifier", binaryMessenger: registrar.messenger)
        let instance = LocalNotifierPlugin()
        instance.registrar = registrar
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "notify":
            notify(call, result: result)
        case "close":
            close(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request authorization: \(error)")
            }
        }
    }

    public func notify(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let identifier = args["identifier"] as? String,
            let title = args["title"] as? String,
            let body = args["body"] as? String
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS", message: "Invalid arguments for notification",
                    details: nil))
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        if let actions = args["actions"] as? [[String: Any]], let action = actions.first,
            let actionText = action["text"] as? String
        {
            let notificationAction = UNNotificationAction(
                identifier: actionText, title: actionText, options: [])
            let category = UNNotificationCategory(
                identifier: "customCategory", actions: [notificationAction], intentIdentifiers: [],
                options: [])
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = "customCategory"
        }

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
                result(false)
                return
            }
            self.notificationDict[identifier] = request
            result(true)
        }
    }

    public func close(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let identifier = args["identifier"] as? String
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid arguments for closing notification", details: nil))
            return
        }

        notificationDict[identifier] = nil
        result(true)
    }
}
