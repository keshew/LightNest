import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class LightNestAppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var switchboard = Switchboard(host: self)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("\(LightVitals.logMark) launch: didFinishLaunching")
        switchboard.dispatch(.wake)

        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            print("\(LightVitals.logMark) launch: remote payload keys=\(remote.keys.map { String(describing: $0) })")
            switchboard.dispatch(.page(remote))
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("\(LightVitals.logMark) push: APNS token received bytes=\(deviceToken.count)")
        switchboard.dispatch(.enrol(deviceToken))
    }

    @objc private func onActivation() {
        print("\(LightVitals.logMark) lifecycle: didBecomeActive")
        switchboard.dispatch(.beat)
    }
}

extension LightNestAppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        print("\(LightVitals.logMark) push: FCM delegate token prefix=\(String((fcmToken ?? "nil").prefix(12)))")
        messaging.token { [weak self] token, err in
            if let err {
                print("\(LightVitals.logMark) push: FCM token read error=\(err)")
                return
            }
            guard let token else {
                print("\(LightVitals.logMark) push: FCM token nil")
                return
            }
            print("\(LightVitals.logMark) push: FCM token received prefix=\(String(token.prefix(12)))")
            self?.switchboard.dispatch(.token(token))
        }
    }
}

extension LightNestAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("\(LightVitals.logMark) push: willPresent keys=\(notification.request.content.userInfo.keys.map { String(describing: $0) })")
        switchboard.dispatch(.page(notification.request.content.userInfo))
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("\(LightVitals.logMark) push: didReceive response keys=\(response.notification.request.content.userInfo.keys.map { String(describing: $0) })")
        switchboard.dispatch(.page(response.notification.request.content.userInfo))
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("\(LightVitals.logMark) push: background payload keys=\(userInfo.keys.map { String(describing: $0) })")
        switchboard.dispatch(.page(userInfo))
        completionHandler(.newData)
    }
}

extension LightNestAppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        print("\(LightVitals.logMark) appsflyer: conversion success keys=\(data.keys.map { String(describing: $0) }) status=\(String(describing: data["af_status"]))")
        switchboard.dispatch(.pulse(data))
    }

    func onConversionDataFail(_ error: Error) {
        print("\(LightVitals.logMark) appsflyer: conversion fail=\(error.localizedDescription)")
        switchboard.dispatch(.pulse([
            "error": true,
            "error_desc": error.localizedDescription
        ]))
    }

    func didResolveDeepLink(_ result: DeepLinkResult) {
        print("\(LightVitals.logMark) appsflyer: deeplink status=\(String(describing: result.status))")
        guard case .found = result.status, let link = result.deepLink else { return }
        print("\(LightVitals.logMark) appsflyer: deeplink found keys=\(link.clickEvent.keys.map { String(describing: $0) })")
        switchboard.dispatch(.traces(link.clickEvent))
    }
}

enum BoardSignal {
    case wake
    case beat
    case enrol(Data)
    case token(String)
    case pulse([AnyHashable: Any])
    case traces([AnyHashable: Any])
    case page([AnyHashable: Any])
}

final class Switchboard {

    private weak var host: LightNestAppDelegate?
    private let splice = Splice()
    private let intake = Intake()

    init(host: LightNestAppDelegate) {
        self.host = host
    }

    func dispatch(_ signal: BoardSignal) {
        switch signal {
        case .wake:
            bringUp()
        case .beat:
            quicken()
        case .enrol(let token):
            print("\(LightVitals.logMark) push: assign APNS token to Firebase")
            Messaging.messaging().apnsToken = token
        case .token(let token):
            print("\(LightVitals.logMark) push: persist FCM token")
            UserDefaults.standard.set(token, forKey: LightKey.fcm)
            UserDefaults.standard.set(token, forKey: LightKey.push)
            UserDefaults(suiteName: LightVitals.suiteMonitor)?.set(token, forKey: "shared_fcm")
        case .pulse(let data):
            splice.takePulse(data)
        case .traces(let data):
            splice.takeTraces(data)
        case .page(let payload):
            intake.absorb(payload)
        }
    }

    private func bringUp() {
        print("\(LightVitals.logMark) init: Firebase configure")
        FirebaseApp.configure()

        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = LightVitals.leadKey
        print("\(LightVitals.logMark) init: AppsFlyer appId=\(LightVitals.appCode) keyPrefix=\(String(LightVitals.leadKey.prefix(6)))")
        sdk.appleAppID = LightVitals.appCode
        sdk.delegate = host
        sdk.deepLinkDelegate = host
        sdk.isDebug = false

        Messaging.messaging().delegate = host
        UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = host
        print("\(LightVitals.logMark) init: delegates registered")
    }

    private func quicken() {
        if #available(iOS 14, *) {
            print("\(LightVitals.logMark) att: request tracking authorization")
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    print("\(LightVitals.logMark) att: status=\(status.rawValue), starting AppsFlyer")
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            print("\(LightVitals.logMark) att: pre-iOS14 start AppsFlyer")
            AppsFlyerLib.shared().start()
        }
    }
}

final class Splice {

    private var pulseBuffer: [AnyHashable: Any] = [:]
    private var traceBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: DispatchSourceTimer?

    func takePulse(_ data: [AnyHashable: Any]) {
        print("\(LightVitals.logMark) splice: pulse buffered keys=\(data.keys.map { String(describing: $0) })")
        pulseBuffer = data
        armFuse()
        if !traceBuffer.isEmpty { weld() }
    }

    func takeTraces(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: LightKey.primed) else {
            print("\(LightVitals.logMark) splice: traces ignored because primed=true")
            return
        }
        print("\(LightVitals.logMark) splice: traces buffered keys=\(data.keys.map { String(describing: $0) })")
        traceBuffer = data
        NotificationCenter.default.post(
            name: .tracesArrived,
            object: nil,
            userInfo: ["deeplinksData": data]
        )
        fuseTimer?.cancel()
        if !pulseBuffer.isEmpty { weld() }
    }

    private func armFuse() {
        fuseTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2.5)
        timer.setEventHandler { [weak self] in self?.weld() }
        fuseTimer = timer
        timer.resume()
        print("\(LightVitals.logMark) splice: fuse armed 2.5s")
    }

    private func weld() {
        fuseTimer?.cancel()
        fuseTimer = nil

        print("\(LightVitals.logMark) splice: weld pulseKeys=\(pulseBuffer.keys.map { String(describing: $0) }) traceKeys=\(traceBuffer.keys.map { String(describing: $0) })")
        var merged = pulseBuffer
        for (k, v) in traceBuffer {
            let tag = "deep_\(k)"
            if merged[tag] == nil { merged[tag] = v }
        }

        NotificationCenter.default.post(
            name: .pulseArrived,
            object: nil,
            userInfo: ["conversionData": merged]
        )
    }
}

final class Intake {

    func absorb(_ payload: [AnyHashable: Any]) {
        print("\(LightVitals.logMark) push: sniff payload keys=\(payload.keys.map { String(describing: $0) })")
        guard let url = sniff(payload) else {
            print("\(LightVitals.logMark) push: no url in payload")
            return
        }
        print("\(LightVitals.logMark) push: temp url=\(url)")
        UserDefaults.standard.set(url, forKey: LightKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NotificationCenter.default.post(
                name: .scopeReload,
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }

    private func sniff(_ payload: [AnyHashable: Any]) -> String? {
        func dig(_ node: [AnyHashable: Any], _ keys: ArraySlice<String>) -> String? {
            guard let head = keys.first else { return nil }
            if keys.count == 1 { return node[head] as? String }
            guard let child = node[head] as? [AnyHashable: Any] else { return nil }
            return dig(child, keys.dropFirst())
        }

        let trails: [[String]] = [["url"], ["data", "url"], ["aps", "data", "url"], ["custom", "url"]]
        return trails.compactMap { dig(payload, $0[...]) }.first
    }
}
