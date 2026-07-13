import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol Lead {
    func pickup(deviceID: String) async throws -> [String: Any]
}

final class SensorLead: Lead {

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func pickup(deviceID: String) async throws -> [String: Any] {
        var comps = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(LightVitals.appCode)")
        comps?.queryItems = [
            URLQueryItem(name: "devkey", value: LightVitals.leadKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]

        guard let url = comps?.url else {
            throw Arrhythmia.crossedLead(at: "lead.url")
        }

        print("\(LightVitals.logMark) lead: request install_data app=\(LightVitals.appCode) devicePrefix=\(String(deviceID.prefix(10)))")
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (bytes, response) = try await session.bytes(for: request)

        guard let http = response as? HTTPURLResponse else {
            print("\(LightVitals.logMark) lead: missing HTTP response")
            throw Arrhythmia.noPulse(stage: "lead.http")
        }
        print("\(LightVitals.logMark) lead: http=\(http.statusCode)")
        guard (200...299).contains(http.statusCode) else {
            throw Arrhythmia.noPulse(stage: "lead.http")
        }

        var buffer = Data()
        for try await chunk in bytes {
            buffer.append(chunk)
        }

        guard let json = try JSONSerialization.jsonObject(with: buffer) as? [String: Any] else {
            let text = String(data: buffer.prefix(500), encoding: .utf8) ?? "<non-utf8>"
            print("\(LightVitals.logMark) lead: json parse failed body=\(text)")
            throw Arrhythmia.garbledTrace(at: "lead.json")
        }

        print("\(LightVitals.logMark) lead: json keys=\(json.keys.sorted()) status=\(String(describing: json["af_status"]))")
        return json
    }
}

protocol Telemeter {
    func relay(vitals: [String: Any]) async throws -> String
}

final class WardTelemeter: Telemeter {

    private let session: URLSession
    private let baseGap: Double = 89.0
    private let ceiling: Int = 3
    private var agent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func relay(vitals: [String: Any]) async throws -> String {
        print("\(LightVitals.logMark) telemeter: relay start endpoint=\(LightVitals.stationEndpoint) vitalKeys=\(vitals.keys.sorted())")
        let request = try chartRequest(vitals)

        var wait = baseGap
        var tries = 0
        var last: Error? = nil

        while tries < ceiling {
            do {
                print("\(LightVitals.logMark) telemeter: attempt=\(tries + 1)")
                return try await sample(request)
            } catch let beat as Arrhythmia where beat.isSealed {
                print("\(LightVitals.logMark) telemeter: sealed failure=\(beat)")
                throw beat
            } catch let beat as Arrhythmia {
                if case .flutter(let cooldown) = beat {
                    print("\(LightVitals.logMark) telemeter: flutter cooldown=\(cooldown)")
                    try await rest(cooldown)
                    tries += 1
                    continue
                }
                print("\(LightVitals.logMark) telemeter: attempt failed arrhythmia=\(beat)")
                last = beat
                tries += 1
                if tries < ceiling {
                    print("\(LightVitals.logMark) telemeter: retry after=\(wait)")
                    try await rest(wait)
                    wait *= 2
                }
            } catch {
                print("\(LightVitals.logMark) telemeter: attempt failed error=\(error)")
                last = error
                tries += 1
                if tries < ceiling {
                    print("\(LightVitals.logMark) telemeter: retry after=\(wait)")
                    try await rest(wait)
                    wait *= 2
                }
            }
        }

        throw last ?? Arrhythmia.noPulse(stage: "telemeter.exhausted")
    }

    private func chartRequest(_ vitals: [String: Any]) throws -> URLRequest {
        guard let endpoint = URL(string: LightVitals.stationEndpoint) else {
            throw Arrhythmia.crossedLead(at: "telemeter.url")
        }

        var body: [String: Any] = vitals
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(LightVitals.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: LightKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        print("\(LightVitals.logMark) telemeter: body keys=\(body.keys.sorted()) pushPresent=\(body["push_token"] != nil) bundle=\(body["bundle_id"] ?? "")")
        return request
    }

    private func sample(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            print("\(LightVitals.logMark) telemeter: missing HTTP response")
            throw Arrhythmia.noPulse(stage: "telemeter.response")
        }
        let text = String(data: data.prefix(500), encoding: .utf8) ?? "<non-utf8>"
        print("\(LightVitals.logMark) telemeter: http=\(http.statusCode) body=\(text)")

        if http.statusCode == 404 {
            throw Arrhythmia.asystole(httpCode: 404)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Arrhythmia.garbledTrace(at: "telemeter.json")
        }

        guard let ok = json["ok"] as? Bool else {
            throw Arrhythmia.garbledTrace(at: "telemeter.missingOk")
        }

        guard ok else {
            throw Arrhythmia.stationDown(reason: "okFalse")
        }

        guard let url = json["url"] as? String, !url.isEmpty else {
            throw Arrhythmia.garbledTrace(at: "telemeter.missingURL")
        }

        print("\(LightVitals.logMark) telemeter: accepted url=\(url)")
        return url
    }

    private func rest(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

enum Arrhythmia: Error, CustomStringConvertible {
    case noSignal(at: String)
    case crossedLead(at: String)
    case noPulse(stage: String)
    case flutter(cooldown: TimeInterval)
    case asystole(httpCode: Int)
    case stationDown(reason: String)
    case garbledTrace(at: String)

    var description: String {
        switch self {
        case .noSignal(let at): return "noSignal(\(at))"
        case .crossedLead(let at): return "crossedLead(\(at))"
        case .noPulse(let stage): return "noPulse(\(stage))"
        case .flutter(let cd): return "flutter(cd=\(cd))"
        case .asystole(let code): return "asystole(\(code))"
        case .stationDown(let reason): return "stationDown(\(reason))"
        case .garbledTrace(let at): return "garbledTrace(\(at))"
        }
    }

    var isSealed: Bool {
        switch self {
        case .asystole, .stationDown: return true
        default: return false
        }
    }
}
