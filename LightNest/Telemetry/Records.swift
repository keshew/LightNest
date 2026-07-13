import Foundation

protocol Records {
    func file(_ log: StripLog)
    func markFeed(url: String, mode: String)
    func raisePrimedFlag()
    func pull() -> StripLog
}

final class WardRecords: Records {

    private let fm = FileManager.default
    private let vaultDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.vaultDir = docs.appendingPathComponent(LightVitals.monitorVault, isDirectory: true)
        if !fm.fileExists(atPath: vaultDir.path) {
            try? fm.createDirectory(at: vaultDir, withIntermediateDirectories: true)
        }
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: LightVitals.suiteMonitor) ?? .standard
    }

    private var stripURL: URL {
        vaultDir.appendingPathComponent(LightVitals.stripFile)
    }

    func file(_ log: StripLog) {
        let noisy = NoisyLog(
            pulse: noiseMap(log.pulse),
            traces: noiseMap(log.traces),
            feedURL: log.feedURL,
            feedMode: log.feedMode,
            resting: log.resting,
            consentPaced: log.consentPaced,
            consentFlat: log.consentFlat,
            consentTapAt: log.consentTapAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970

        do {
            let data = try encoder.encode(noisy)
            try data.write(to: stripURL, options: .atomic)
        } catch {
            print("\(LightVitals.logMark) records: file failed=\(error)")
        }

        for store in [suiteStore, homeStore] {
            store.set(log.consentPaced, forKey: LightKey.consentPaced)
            store.set(log.consentFlat, forKey: LightKey.consentFlat)
            if let date = log.consentTapAt {
                store.set(date.timeIntervalSince1970, forKey: LightKey.consentTapAt)
            }
        }
    }

    func markFeed(url: String, mode: String) {
        print("\(LightVitals.logMark) records: markFeed mode=\(mode) url=\(url)")
        suiteStore.set(url, forKey: LightKey.feedURL)
        homeStore.set(url, forKey: LightKey.feedURL)
        suiteStore.set(mode, forKey: LightKey.feedMode)
    }

    func raisePrimedFlag() {
        print("\(LightVitals.logMark) records: primed=true")
        suiteStore.set(true, forKey: LightKey.primed)
        homeStore.set(true, forKey: LightKey.primed)
    }

    func pull() -> StripLog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        if fm.fileExists(atPath: stripURL.path),
           let data = try? Data(contentsOf: stripURL),
           let noisy = try? decoder.decode(NoisyLog.self, from: data) {
            let pulled = StripLog(
                pulse: cleanMap(noisy.pulse),
                traces: cleanMap(noisy.traces),
                feedURL: noisy.feedURL,
                feedMode: noisy.feedMode,
                resting: noisy.resting,
                consentPaced: noisy.consentPaced,
                consentFlat: noisy.consentFlat,
                consentTapAt: noisy.consentTapAt
            )
            print("\(LightVitals.logMark) records: pull file pulseKeys=\(pulled.pulse.keys.sorted()) feedURL=\(pulled.feedURL ?? "nil") resting=\(pulled.resting)")
            return pulled
        }

        let mirrored = pullFromMirror()
        print("\(LightVitals.logMark) records: pull mirror pulseKeys=\(mirrored.pulse.keys.sorted()) feedURL=\(mirrored.feedURL ?? "nil") resting=\(mirrored.resting)")
        return mirrored
    }

    private func pullFromMirror() -> StripLog {
        let feedURL = homeStore.string(forKey: LightKey.feedURL)
            ?? suiteStore.string(forKey: LightKey.feedURL)
        let feedMode = suiteStore.string(forKey: LightKey.feedMode)
        let primed = suiteStore.bool(forKey: LightKey.primed)

        let paced = suiteStore.bool(forKey: LightKey.consentPaced)
            || homeStore.bool(forKey: LightKey.consentPaced)
        let flat = suiteStore.bool(forKey: LightKey.consentFlat)
            || homeStore.bool(forKey: LightKey.consentFlat)
        let tapTs = suiteStore.double(forKey: LightKey.consentTapAt)
        let tapAt: Date? = tapTs > 0 ? Date(timeIntervalSince1970: tapTs) : nil

        return StripLog(
            pulse: [:],
            traces: [:],
            feedURL: feedURL,
            feedMode: feedMode,
            resting: !primed,
            consentPaced: paced,
            consentFlat: flat,
            consentTapAt: tapAt
        )
    }

    private func noiseMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = addNoise(pair.value) }
    }

    private func cleanMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = clean(pair.value) ?? pair.value }
    }

    private func addNoise(_ input: String) -> String {
        Data(input.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "%")
            .replacingOccurrences(of: "/", with: ".")
    }

    private func clean(_ input: String) -> String? {
        let restored = input
            .replacingOccurrences(of: "%", with: "+")
            .replacingOccurrences(of: ".", with: "/")
        guard let data = Data(base64Encoded: restored),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct NoisyLog: Codable {
    let pulse: [String: String]
    let traces: [String: String]
    let feedURL: String?
    let feedMode: String?
    let resting: Bool
    let consentPaced: Bool
    let consentFlat: Bool
    let consentTapAt: Date?
}
