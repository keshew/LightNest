import Foundation
import AppsFlyerLib
import Combine
import UIKit
import UserNotifications

protocol Pager {
    func page() async -> Bool
    func armPager()
}

final class WardPager: Pager {

    func page() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let buzzer = OneBuzzer()
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                    print("\(LightVitals.logMark) consent: permission error=\(error)")
                }
                DispatchQueue.main.async {
                    guard buzzer.ring() else { return }
                    print("\(LightVitals.logMark) consent: system permission granted=\(granted)")
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func armPager() {
        DispatchQueue.main.async {
            print("\(LightVitals.logMark) push: register after consent")
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class OneBuzzer {
    private var rang = false
    private let lock = NSLock()

    func ring() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !rang else { return false }
        rang = true
        return true
    }
}

final class Ward {
    let records: Records
    let lead: Lead
    let telemeter: Telemeter
    let pager: Pager

    init(records: Records, lead: Lead, telemeter: Telemeter, pager: Pager) {
        self.records = records
        self.lead = lead
        self.telemeter = telemeter
        self.pager = pager
    }

    static func staffedWard() -> Ward {
        Ward(
            records: WardRecords(),
            lead: SensorLead(),
            telemeter: WardTelemeter(),
            pager: WardPager()
        )
    }
}

@MainActor
final class Admitting {

    static let shared = Admitting()

    private var beds: [String: Any] = [:]

    private init() {}

    func bed<T>(_ instance: T, as type: T.Type) {
        beds[String(describing: type)] = instance
    }

    func admit<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        if let instance = beds[key] as? T {
            return instance
        }
        let built = intake(type)
        beds[key] = built
        return built
    }

    private func intake<T>(_ type: T.Type) -> T {
        switch String(describing: type) {
        case String(describing: Ward.self):
            return Ward.staffedWard() as! T
        case String(describing: Cardiograph.self):
            return Cardiograph(ward: admit(Ward.self)) as! T
        default:
            fatalError("Admitting: no builder for \(type)")
        }
    }
}

@MainActor
final class TraceBuilder {

    private(set) var strip: Strip
    private(set) var reading: Reading?
    private(set) var settled = false

    private let ward: Ward

    init(strip: Strip, ward: Ward) {
        self.strip = strip
        self.ward = ward
    }

    var signalLive: Bool { strip.pulsePresent }

    func spliceSpike() {
        let temp = UserDefaults.standard.string(forKey: LightKey.pushURL)
        print("\(LightVitals.logMark) trace: spliceSpike temp=\(temp ?? "nil")")
        guard let pushURL = temp, !pushURL.isEmpty else {
            return
        }
        chartFeed(pushURL)
    }

    func amplify() async {
        guard strip.organicArrhythmia, strip.resting, !strip.amplified else {
            print("\(LightVitals.logMark) trace: amplify skipped organic=\(strip.organicArrhythmia) resting=\(strip.resting) amplified=\(strip.amplified)")
            return
        }

        strip.amplified = true
        ward.records.file(strip.log())

        print("\(LightVitals.logMark) trace: amplify wait 5s before AppsFlyer pickup")
        try? await Task.sleep(nanoseconds: 5_000_000_000)

        guard !settled else {
            print("\(LightVitals.logMark) trace: amplify aborted because settled=true")
            return
        }

        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        print("\(LightVitals.logMark) trace: amplify pickup devicePrefix=\(String(deviceID.prefix(10)))")
        do {
            var picked = try await ward.lead.pickup(deviceID: deviceID)
            for (k, v) in strip.traces {
                if picked[k] == nil { picked[k] = v }
            }
            strip.pulse = picked.mapValues { "\($0)" }
            print("\(LightVitals.logMark) trace: amplify picked keys=\(strip.pulse.keys.sorted()) status=\(strip.pulse["af_status"] ?? "nil")")
            ward.records.file(strip.log())
        } catch {
            print("\(LightVitals.logMark) trace: amplify pickup soft fail=\(error)")
        }
    }

    func sweep() async {
        guard strip.pulsePresent else {
            print("\(LightVitals.logMark) trace: sweep no pulse -> tracing")
            halt(.tracing)
            return
        }

        let vitals = strip.pulse.mapValues { $0 as Any }
        do {
            let url = try await ward.telemeter.relay(vitals: vitals)
            print("\(LightVitals.logMark) trace: sweep got url=\(url)")
            chartFeed(url)
        } catch {
            print("\(LightVitals.logMark) trace: sweep failed -> flatline error=\(error)")
            halt(.flatline)
        }
    }

    func readout() -> Reading? {
        reading
    }

    private func chartFeed(_ url: String) {
        let needsConsent = strip.consentRipe
        print("\(LightVitals.logMark) trace: chartFeed url=\(url) needsConsent=\(needsConsent)")

        strip.feedURL = url
        strip.feedMode = "Active"
        strip.resting = false
        strip.charted = true

        ward.records.file(strip.log())
        ward.records.markFeed(url: url, mode: "Active")
        ward.records.raisePrimedFlag()
        UserDefaults.standard.removeObject(forKey: LightKey.pushURL)

        reading = needsConsent ? .promptConsent : .goLive
        settled = true
    }

    private func halt(_ reading: Reading) {
        print("\(LightVitals.logMark) trace: halt reading=\(reading)")
        self.reading = reading
        self.settled = true
    }
}

@MainActor
final class Cardiograph {

    private var strip = Strip()
    private var admitted = false
    private var sealed = false
    private var conducting = false

    private let ward: Ward

    private let readingSubject = PassthroughSubject<Reading, Never>()
    var readingPublisher: AnyPublisher<Reading, Never> {
        readingSubject.eraseToAnyPublisher()
    }

    private var consentTask: Task<Void, Never>?

    init(ward: Ward) {
        self.ward = ward
    }

    private func ensureAdmitted() {
        guard !admitted else { return }
        strip = Strip.chart(from: ward.records.pull())
        print("\(LightVitals.logMark) state: admitted resting=\(strip.resting) pulseKeys=\(strip.pulse.keys.sorted()) feedURL=\(strip.feedURL ?? "nil") consentPaced=\(strip.consentPaced) consentFlat=\(strip.consentFlat)")
        admitted = true
    }

    private func sealOnce() -> Bool {
        guard !sealed else { return false }
        sealed = true
        return true
    }

    func warmUp() {
        print("\(LightVitals.logMark) cardiograph: warmUp")
        ensureAdmitted()
    }

    func chartPulse(_ raw: [String: Any]) {
        ensureAdmitted()
        strip.pulse = raw.mapValues { "\($0)" }
        print("\(LightVitals.logMark) cardiograph: chartPulse keys=\(strip.pulse.keys.sorted()) status=\(strip.pulse["af_status"] ?? "nil")")
        ward.records.file(strip.log())
    }

    func chartTraces(_ raw: [String: Any]) {
        ensureAdmitted()
        strip.traces = raw.mapValues { "\($0)" }
        print("\(LightVitals.logMark) cardiograph: chartTraces keys=\(strip.traces.keys.sorted())")
        ward.records.file(strip.log())
    }

    func conduct() async {
        ensureAdmitted()
        guard !sealed, !conducting else {
            print("\(LightVitals.logMark) cardiograph: conduct skipped sealed=\(sealed) conducting=\(conducting)")
            return
        }
        print("\(LightVitals.logMark) cardiograph: conduct start pulsePresent=\(strip.pulsePresent) resting=\(strip.resting)")
        conducting = true
        defer { conducting = false }

        let builder = TraceBuilder(strip: strip, ward: ward)

        builder.spliceSpike()
        if let reading = builder.readout() {
            finish(builder, reading)
            return
        }

        guard builder.signalLive else {
            print("\(LightVitals.logMark) cardiograph: no signalLive -> tracing")
            finish(builder, .tracing)
            return
        }

        await builder.amplify()
        if let reading = builder.readout() {
            finish(builder, reading)
            return
        }

        await builder.sweep()
        finish(builder, builder.readout() ?? .flatline)
    }

    private func finish(_ builder: TraceBuilder, _ reading: Reading) {
        strip = builder.strip
        print("\(LightVitals.logMark) cardiograph: finish reading=\(reading) sealed=\(sealed) feedURL=\(strip.feedURL ?? "nil")")

        if case .tracing = reading {
            readingSubject.send(.tracing)
            return
        }

        if sealOnce() {
            readingSubject.send(reading)
        }
    }

    func pace(then ack: @escaping () -> Void) {
        ensureAdmitted()
        consentTask = Task { [weak self] in
            guard let self = self else { return }

            print("\(LightVitals.logMark) consent: request started")
            let granted = await self.ward.pager.page()

            self.strip.consentPaced = granted
            self.strip.consentFlat = !granted
            self.strip.consentTapAt = Date()
            self.ward.records.file(self.strip.log())

            if granted {
                self.ward.pager.armPager()
            }

            print("\(LightVitals.logMark) consent: accepted -> goLive")
            self.readingSubject.send(.goLive)
            ack()
        }
    }

    func skip() {
        ensureAdmitted()
        strip.consentTapAt = Date()
        ward.records.file(strip.log())
        print("\(LightVitals.logMark) consent: skipped -> goLive")
        readingSubject.send(.goLive)
    }

    func reportFlatline() -> Bool {
        let result = sealOnce()
        print("\(LightVitals.logMark) deadline: reportFlatline seal=\(result)")
        return result
    }
}

@MainActor
final class Bedside: ObservableObject {

    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }

    @Published var navigateToScope = false {
        didSet {
            if navigateToScope {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }

    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false

    private let cardiograph: Cardiograph
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?

    private var uiLocked: Bool = false

    init() {
        self.cardiograph = Admitting.shared.admit(Cardiograph.self)
        bindReadings()
    }

    deinit {
        deadlineTask?.cancel()
    }

    private func bindReadings() {
        cardiograph.readingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reading in
                self?.handleReading(reading)
            }
            .store(in: &cancellables)
    }

    func ignite() {
        print("\(LightVitals.logMark) ui: ignite")
        cardiograph.warmUp()
        armDeadline()
    }

    func ingestPulse(_ data: [String: Any]) {
        print("\(LightVitals.logMark) ui: ingestPulse keys=\(data.keys.sorted())")
        Task {
            cardiograph.chartPulse(data)
            await cardiograph.conduct()
        }
    }

    func ingestTraces(_ data: [String: Any]) {
        print("\(LightVitals.logMark) ui: ingestTraces keys=\(data.keys.sorted())")
        cardiograph.chartTraces(data)
    }

    func acceptConsent() {
        cardiograph.pace {
            self.showPermissionPrompt = false
        }
    }

    func skipConsent() {
        showPermissionPrompt = false
        cardiograph.skip()
    }

    func networkConnectivityChanged(_ connected: Bool) {
        print("\(LightVitals.logMark) network: connected=\(connected)")
        if !connected {
            showOfflineView = true
        }
    }

    private func handleReading(_ reading: Reading) {
        print("\(LightVitals.logMark) ui: handleReading=\(reading) locked=\(uiLocked)")
        guard !uiLocked else { return }

        switch reading {
        case .tracing:
            break
        case .promptConsent:
            print("\(LightVitals.logMark) ui: route promptConsent")
            showPermissionPrompt = true
        case .goLive:
            print("\(LightVitals.logMark) ui: route scope")
            navigateToScope = true
        case .flatline:
            print("\(LightVitals.logMark) ui: route native flatline")
            navigateToMain = true
        }
    }

    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            print("\(LightVitals.logMark) deadline: armed 30s")
            try? await Task.sleep(nanoseconds: 30_000_000_000)

            guard let self = self else { return }

            if self.cardiograph.reportFlatline() {
                self.handleReading(.flatline)
            }
        }
    }
}
