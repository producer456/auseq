import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()
    @State private var showingConfig = false
    @State private var showingTracks = false
    @State private var mainMode: MainMode = .params
    @Environment(\.horizontalSizeClass) private var hSize

    enum MainMode: String, CaseIterable { case params = "PARAMS", arrange = "ARRANGE" }
    private var isPhone: Bool { hSize == .compact }

    var body: some View {
        Group {
            if isPhone { phoneBody } else { padBody }
        }
        .tint(Theme.orange)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingConfig) {
            ConfigurationView(model: model)
        }
        .sheet(isPresented: $showingTracks) {
            NavigationStack {
                TrackListView(model: model)
                    .navigationTitle("Tracks")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showingTracks = false } } }
            }
        }
    }

    /// iPad — track list as a fixed sidebar between wood cheeks.
    private var padBody: some View {
        ZStack {
            BrushedAluminum()
            HStack(spacing: 0) {
                WoodPanel().frame(width: 16).ignoresSafeArea()
                TrackListView(model: model)
                    .frame(width: 340)
                    .background(Theme.rail)
                Rectangle().fill(Theme.gold.opacity(0.5)).frame(width: 1)
                mainArea
                WoodPanel().frame(width: 16).ignoresSafeArea()
            }
        }
    }

    /// Phone — single column; tracks open in a drawer from the top bar.
    private var phoneBody: some View {
        ZStack {
            BrushedAluminum()
            mainArea
        }
    }

    private var mainArea: some View {
        VStack(spacing: 0) {
            topBar
            GoldHairline()
            TransportBar(seq: model.sequencer,
                         onQuantizeSelected: { model.quantizeSelected() },
                         onQuantizeAll: { model.quantizeAll() })
            GoldHairline()
            modePicker
            if mainMode == .arrange {
                ArrangeView(model: model, seq: model.sequencer)
            } else {
                if let track = model.selectedTrack, track.hasInstrument, let au = model.selectedAU {
                    ParameterListView(au: au, model: model)
                        .id(track.id)   // rebuild when the selected track changes
                } else {
                    Spacer()
                    status
                    Spacer()
                }
                if model.selectedTrack != nil {
                    ClipView(seq: model.sequencer, trackID: model.selectedTrackID)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 6)
                }
            }
            PianoKeyboardView(model: model)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
        }
    }

    private var modePicker: some View {
        Picker("", selection: $mainMode) {
            ForEach(MainMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12).padding(.vertical, 6)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if isPhone {
                Button { showingTracks = true } label: {
                    Image(systemName: "list.bullet").font(.title3).foregroundStyle(Theme.orange)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("AUSEQ")
                    .font(Theme.mono(isPhone ? 18 : 26, .heavy))
                    .tracking(2)
                    .foregroundStyle(Theme.etched)
                if !isPhone { Text(midiSummary).etchedLabel(9, soft: true, weight: .medium) }
            }
            Button { showingConfig = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3).foregroundStyle(Theme.orange)
            }
            Spacer()
            if let track = model.selectedTrack {
                HStack(spacing: 8) {
                    AmberLED(on: track.hasInstrument)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(track.name).font(.headline).foregroundStyle(track.color)
                        Text(track.instrumentName).etchedLabel(9, soft: true, weight: .medium).lineLimit(1)
                    }
                }
            }
        }
        .padding(.horizontal, isPhone ? 12 : 16).padding(.vertical, isPhone ? 8 : 16)
    }

    private var midiSummary: String {
        let n = model.midi.sourceNames.count
        if n == 0 { return "No MIDI inputs — connect the KeyLab" }
        return "MIDI in: " + model.midi.sourceNames.joined(separator: ", ")
    }

    @ViewBuilder
    private var status: some View {
        if let err = model.audio.lastError {
            Text(err).font(.footnote).foregroundStyle(.red)
                .multilineTextAlignment(.center).padding()
        } else if let track = model.selectedTrack, !track.hasInstrument {
            VStack(spacing: 18) {
                PerforatedGrille()
                    .frame(width: 160, height: 90)
                    .mask(RoundedRectangle(cornerRadius: 8))
                Text("Tap the keyboard icon on \(track.name) to load an AUv3 instrument, then play the keys or the KeyLab.")
                    .etchedLabel(11, soft: true, weight: .medium)
                    .tracking(0.5)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 40)
            }
        } else if let track = model.selectedTrack {
            Text("Playing \(track.instrumentName) on \(track.name)")
                .etchedLabel(12, weight: .semibold)
                .foregroundStyle(Theme.orange)
        }
    }
}

#Preview {
    ContentView()
}
