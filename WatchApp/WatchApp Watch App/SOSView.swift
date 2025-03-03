import SwiftUI
import CoreLocation
import Combine
import WatchKit
import AVFoundation

struct SOSView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isSOSActive = false
    @State private var sosMessage = "Press the button to send an SOS alert."
    @State private var currentLocation: CLLocationCoordinate2D?
    @State private var locationError: Error?
    @State private var lastTapTime: Date? = nil
    @State private var sosTimer: Timer?
    @State private var countdown = 5
    @State private var isCountdownActive = false
    @State private var isFallDetected = false
    @State private var isTamperDetected = false
    @State private var isPanicMode = false
    @State private var isSpeedAlertActive = false
    @State private var isSafeAlertActive = false
    @State private var checkInTime: Date? = nil
    @State private var checkOutTime: Date? = nil
    @State private var isTrackingLocation = false
    @State private var trackedPath: [CLLocationCoordinate2D] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioEngine: AVAudioEngine?
    
    let emergencyContacts = ["+91 7020685633"] // Example contacts
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("SOS Alert System")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                    .foregroundColor(.red)
                
                VStack {
                    Text("Current Location")
                        .font(.headline)
                    Text(formatLocation())
                        .font(.subheadline)
                        .foregroundColor(currentLocation != nil ? .green : .red)
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
                
                Button(action: {
                    if isCountdownActive {
                        cancelSOS()
                    } else {
                        initiateTimedSOS()
                    }
                }) {
                    Text(isCountdownActive ? "Cancel SOS (\(countdown))" : "Send SOS")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isCountdownActive ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                .onTapGesture {
                    handleDoubleTap()
                }
                
                Button(action: {
                    if isPanicMode {
                        stopPanicMode()
                    } else {
                        triggerPanicMode()
                    }
                }) {
                    Text(isPanicMode ? "Stop Panic Mode" : "Activate Panic Mode")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPanicMode ? Color.red : Color.orange)
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: {
                    toggleLiveTracking()
                }) {
                    Text(isTrackingLocation ? "Stop Live Tracking" : "Start Live Tracking")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isTrackingLocation ? Color.red : Color.green)
                        .cornerRadius(10)
                }
                .padding()
                
                if isTrackingLocation {
                    Text("📍 Tracking Location...")
                        .foregroundColor(.green)
                        .bold()
                }
                
                if !trackedPath.isEmpty {
                    Text("Final Coordinates: \(formatCoordinates(trackedPath.last))")
                        .foregroundColor(.blue)
                }
                
                Text(sosMessage)
                    .font(.subheadline)
                    .foregroundColor(isSOSActive ? .red : .blue)
                    .padding()
                
                if isFallDetected {
                    Text("🚨 Fall Detected! SOS Sent!")
                        .foregroundColor(.red)
                        .bold()
                }
                
                if isTamperDetected {
                    Text("⚠️ Tampering Detected!")
                        .foregroundColor(.orange)
                        .bold()
                }
                
                if isSpeedAlertActive {
                    Text("⚠️ Speed Alert Triggered")
                        .foregroundColor(.yellow)
                        .bold()
                }
                
                if isSafeAlertActive {
                    Text("✅ Safe Alert Active")
                        .foregroundColor(.green)
                        .bold()
                }
                
                if let checkIn = checkInTime {
                    Text("Checked In: \(checkIn, style: .time)")
                }
                
                if let checkOut = checkOutTime {
                    Text("Checked Out: \(checkOut, style: .time)")
                }
            }
        }
        .onAppear {
                    setupLocationTracking()
                    setupAudioSession()
                    preloadSiren() // New function to preload siren
                }
            }
    
    private func setupLocationTracking() {
        locationManager.requestLocationPermission()
        locationManager.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { self.currentLocation = $0 }
            .store(in: &locationManager.cancellables)
        
        locationManager.$locationError
            .receive(on: DispatchQueue.main)
            .sink { self.locationError = $0 }
            .store(in: &locationManager.cancellables)
        
        locationManager.startLocationTracking()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func formatLocation() -> String {
        guard let location = currentLocation else { return "Location Unavailable" }
        return String(format: "Lat: %.6f, Lon: %.6f", location.latitude, location.longitude)
    }
    
    private func formatCoordinates(_ location: CLLocationCoordinate2D?) -> String {
        guard let location = location else { return "N/A" }
        return String(format: "Lat: %.6f, Lon: %.6f", location.latitude, location.longitude)
    }
    
    private func initiateTimedSOS() {
        guard currentLocation != nil else {
            sosMessage = "⚠️ Cannot send SOS. Location unavailable."
            return
        }
        countdown = 5
        isCountdownActive = true
        sosMessage = "SOS will be sent in \(countdown) seconds..."
        sosTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
                sosMessage = "SOS will be sent in \(countdown) seconds..."
            } else {
                timer.invalidate()
                isCountdownActive = false
                triggerSOSAlert()
            }
        }
    }
    
    private func cancelSOS() {
        sosTimer?.invalidate()
        isCountdownActive = false
        sosMessage = "SOS cancelled."
    }
    
    private func handleDoubleTap() {
        let currentTime = Date()
        if let lastTap = lastTapTime, currentTime.timeIntervalSince(lastTap) < 0.3 {
            startSOS()
        }
        lastTapTime = currentTime
    }
    
    private func startSOS() {
        sosMessage = "⚠️ SOS Activated: Double-Tap Detected"
        isSOSActive = true
        triggerSOSAlert()
    }
    
    private func triggerSOSAlert() {
        guard let location = currentLocation else {
            sosMessage = "⚠️ Cannot send SOS. Location unavailable."
            isSOSActive = false
            return
        }
        print("SOS Triggered at \(location.latitude), \(location.longitude)")
        WKInterfaceDevice.current().play(.notification)
        sendSOSAlertToEmergencyContacts(location: location)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSOSActive = false
        }
    }
    
    private func sendSOSAlertToEmergencyContacts(location: CLLocationCoordinate2D) {
        for contact in emergencyContacts {
            print("Sending SOS alert to \(contact) with Location: \(location.latitude), \(location.longitude)")
        }
    }
    
    private func triggerPanicMode() {
        isPanicMode = true
        sosMessage = "🚨 Panic Mode Activated! Loud siren enabled."
        
        guard let sirenURL = Bundle.main.url(forResource: "siren", withExtension: "wav") else {
            print("Could not find siren audio file")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: sirenURL)
            audioPlayer?.numberOfLoops = -1  // Infinite loop
            audioPlayer?.volume = 1.0        // Maximum volume
            audioPlayer?.play()
        } catch {
            print("Could not create audio player: \(error)")
        }
        
        WKInterfaceDevice.current().play(.failure)
    }
    
    private func stopPanicMode() {
        isPanicMode = false
        audioEngine?.stop()
        audioEngine = nil
        sosMessage = "Panic Mode Deactivated"
    }
    
    private func toggleLiveTracking() {
        if isTrackingLocation {
            isTrackingLocation = false
            sosMessage = "Live tracking stopped."
        } else {
            isTrackingLocation = true
            sosMessage = "Live tracking started."
            trackedPath.removeAll()
            trackLocationUpdates()
        }
    }
    
    private func trackLocationUpdates() {
        locationManager.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { location in
                if let location = location {
                    trackedPath.append(location)
                }
            }
            .store(in: &locationManager.cancellables)
    }
    
    private func preloadSiren() {
            if let sirenPath = Bundle.main.path(forResource: "siren", ofType: "mp3") {
                let sirenUrl = URL(fileURLWithPath: sirenPath)
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: sirenUrl)
                    audioPlayer?.prepareToPlay()
                    print("Siren audio preloaded successfully")
                } catch {
                    print("Failed to preload siren: \(error)")
                }
            } else {
                print("Siren file not found in bundle")
            }
        }
}
