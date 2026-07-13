import Foundation

enum LightVitals {
    static let appCode = "6783971472"
    static let leadKey = "BNn356ZHQoHFLk5W2ubkV8"
    static let suiteMonitor = "group.lightnest.monitor"
    static let cookieMonitor = "lightnest_monitor"
    static let stationEndpoint = "https://lightnesst.com/config.php"
    static let logMark = "[LightNest]"

    static let stripFile = "ln_chart_log.json"
    static let monitorVault = "LightMonitor"
}

enum LightKey {
    static let feedURL = "ln_feed_url"
    static let feedMode = "ln_feed_mode"
    static let primed = "ln_primed"

    static let consentPaced = "ln_consent_paced"
    static let consentFlat = "ln_consent_flat"
    static let consentTapAt = "ln_consent_tap_at"

    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}

extension Notification.Name {
    static let pulseArrived = Notification.Name("ConversionDataReceived")
    static let tracesArrived = Notification.Name("deeplink_values")
    static let scopeReload = Notification.Name("LoadTempURL")
}

struct StripLog: Codable {
    let pulse: [String: String]
    let traces: [String: String]
    let feedURL: String?
    let feedMode: String?
    let resting: Bool
    let consentPaced: Bool
    let consentFlat: Bool
    let consentTapAt: Date?
}

struct Strip {
    var pulse: [String: String] = [:]
    var traces: [String: String] = [:]
    var feedURL: String? = nil
    var feedMode: String? = nil
    var resting: Bool = true
    var charted: Bool = false
    var amplified: Bool = false
    var consentPaced: Bool = false
    var consentFlat: Bool = false
    var consentTapAt: Date? = nil

    var pulsePresent: Bool { !pulse.isEmpty }
    var organicArrhythmia: Bool { pulse["af_status"] == "Organic" }

    var consentRipe: Bool {
        guard !consentPaced && !consentFlat else { return false }
        if let date = consentTapAt {
            return Date().timeIntervalSince(date) / 86400 >= 3
        }
        return true
    }

    static func chart(from log: StripLog) -> Strip {
        var s = Strip()
        s.pulse = log.pulse
        s.traces = log.traces
        s.feedURL = log.feedURL
        s.feedMode = log.feedMode
        s.resting = log.resting
        s.consentPaced = log.consentPaced
        s.consentFlat = log.consentFlat
        s.consentTapAt = log.consentTapAt
        return s
    }

    func log() -> StripLog {
        StripLog(
            pulse: pulse,
            traces: traces,
            feedURL: feedURL,
            feedMode: feedMode,
            resting: resting,
            consentPaced: consentPaced,
            consentFlat: consentFlat,
            consentTapAt: consentTapAt
        )
    }
}

enum Reading: Equatable {
    case tracing
    case promptConsent
    case goLive
    case flatline
}
