import SwiftUI

struct BuddyTimeView: View {
    let store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var forPet = false
    @State private var action: CareAction?
    @State private var progress = 0
    @State private var reaction = "Tap to walk · Drag to play!"
    @State private var celebrating = false
    @State private var busy = false
    @State private var snack = "Apple slices"

    private var buddyName: String {
        forPet ? (store.petName.isEmpty ? (store.pet?.name ?? "Pet") : store.petName) : (store.playerName.isEmpty ? "Your buddy" : store.playerName)
    }
    private var instruction: String {
        switch action {
        case .snack: "Drag the snack to your buddy's face."
        case .drink: "Bring the water to your buddy's face."
        case .brush: "Brush back and forth across your buddy."
        case .wash: "Rub your buddy to make bubbly sparkles!"
        case nil: "Tap to walk · Drag to play!"
        }
    }
    private var actionTitle: String {
        switch action {
        case .brush: "Brush gently"
        case .wash: "Make bubbles"
        case .snack: "Give a bite"
        case .drink: "Give a sip"
        case nil: "Let's dance!"
        }
    }
    private var selectedEmoji: String {
        switch action {
        case .snack: "🍎"
        case .drink: "💧"
        case .brush: "🪮"
        case .wash: "🧽"
        case nil: "👋"
        }
    }

    var body: some View {
        ZStack {
            BuddyPlayground(store: store, forPet: forPet, action: action, snack: snack,
                            progress: progress, celebrating: celebrating, onCare: interact,
                            onPlay: { reaction = $0; Haptics.tap() })
                .ignoresSafeArea()
            FullScreenLayout { reserved in
                VStack(spacing: 12) {
                    header.clearOfReservedRegions(reserved)
                    HStack(spacing: 12) {
                        buddyChip(pet: false)
                        buddyChip(pet: true)
                    }.clearOfReservedRegions(reserved)
                    Text(reaction).font(.wacky(16)).multilineTextAlignment(.center)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())
                        .accessibilityIdentifier("care-reaction")
                        .clearOfReservedRegions(reserved)
                    Spacer(minLength: 0)
                    controls.clearOfReservedRegions(reserved)
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
            }
        }
        .foregroundStyle(Palette.ink)
        .task(id: celebrating) {
            guard celebrating else { return }
            do { try await Task.sleep(for: .milliseconds(1400)) } catch { return }
            withAnimation { celebrating = false; busy = false }
        }
        .onAppear { print("[BuddyPlay] fullscreen kid=\(store.kidImage) pet=\(store.petImage ?? "none") costume=\(store.costume.id)") }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Buddy Time").font(.wacky(27, .black))
                Text("\(store.careProgress.total) happy moments").font(.wacky(12))
                    .accessibilityIdentifier("care-total")
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 18, weight: .bold))
                    .frame(width: 48, height: 48).background(.regularMaterial, in: Circle())
            }.buttonStyle(SquishButtonStyle()).accessibilityLabel("Close Buddy Time")
                .accessibilityIdentifier("close-buddy-time")
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if action == .snack {
                HStack(spacing: 12) {
                    ForEach(forPet ? ["Pet treats", "Pet dinner"] : ["Apple slices", "Sandwich"], id: \.self) { food in
                        Button { snack = food; Haptics.tap() } label: {
                            Text(food == "Pet treats" ? "🦴" : (food == "Pet dinner" ? "🥣" : (food == "Sandwich" ? "🥪" : "🍎")))
                                .font(.system(size: 27)).frame(width: 54, height: 48)
                                .background(snack == food ? Palette.sun : .white.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
                        }.accessibilityLabel(food).accessibilityAddTraits(snack == food ? .isSelected : [])
                            .accessibilityIdentifier("care-snack-\(food == "Sandwich" || food == "Pet dinner" ? "second" : "first")")
                    }
                }.padding(6).background(.regularMaterial, in: Capsule())
            }
            HStack(spacing: 6) {
                Text(selectedEmoji).font(.system(size: 21))
                Text(action == nil ? "Play time" : actionTitle).font(.wacky(17))
                if action != nil {
                    ForEach(0..<3) { index in
                        Image(systemName: index < progress ? "heart.fill" : "heart")
                            .font(.system(size: 13)).foregroundStyle(Palette.bubblegum)
                    }
                }
            }
            Text(instruction).font(.wacky(12)).multilineTextAlignment(.center)
            HStack(spacing: 8) {
                toolButton(emoji: "👋", title: "Play", tool: nil, id: "play")
                toolButton(emoji: "🍎", title: "Feed", tool: .snack, id: "snack")
                toolButton(emoji: "💧", title: "Water", tool: .drink, id: "drink")
                toolButton(emoji: "🪮", title: "Brush", tool: .brush, id: "brush")
                toolButton(emoji: "🧽", title: "Wash", tool: .wash, id: "wash")
            }
            Button { interact() } label: {
                Label(actionTitle, systemImage: action?.symbol ?? "music.note")
                    .font(.wacky(16)).frame(maxWidth: .infinity).frame(minHeight: 44)
                    .background(Palette.bubblegum.opacity(0.18), in: Capsule())
            }.buttonStyle(SquishButtonStyle()).disabled(busy).accessibilityIdentifier("care-help-action")
        }
        .padding(14).frame(maxWidth: 440)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.8), lineWidth: 1))
    }

    private func toolButton(emoji: String, title: String, tool: CareAction?, id: String) -> some View {
        let selected = action == tool
        return Button {
            action = tool
            resetActivity()
            Haptics.tap()
        } label: {
            Text(emoji).font(.system(size: 32))
                .frame(maxWidth: .infinity).frame(height: 58)
                .background(selected ? Palette.sun : .white.opacity(0.7), in: RoundedRectangle(cornerRadius: 19))
                .overlay(RoundedRectangle(cornerRadius: 19).stroke(selected ? Palette.sunDeep : .clear, lineWidth: 3))
                .offset(y: selected ? -4 : 0)
        }.buttonStyle(SquishButtonStyle()).disabled(busy)
            .accessibilityLabel(title).accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("care-tool-\(id)")
    }

    private func buddyChip(pet: Bool) -> some View {
        Button {
            forPet = pet
            snack = pet ? "Pet treats" : "Apple slices"
            resetActivity()
        } label: {
            HStack(spacing: 6) {
                Text(pet ? "🐾" : "😊").font(.system(size: 22))
                Text(pet ? (store.petName.isEmpty ? "My pet" : store.petName) : (store.playerName.isEmpty ? "My buddy" : store.playerName))
                    .font(.wacky(15)).lineLimit(1).minimumScaleFactor(0.6)
            }.padding(.horizontal, 16).frame(minHeight: 46)
                .background(forPet == pet ? Palette.sun : .white.opacity(0.8), in: Capsule())
                .overlay(Capsule().stroke(forPet == pet ? Palette.sunDeep : .clear, lineWidth: 2))
        }.buttonStyle(SquishButtonStyle()).disabled(busy)
            .accessibilityLabel(pet ? "Select my pet" : "Select my character")
            .accessibilityAddTraits(forPet == pet ? .isSelected : [])
            .accessibilityIdentifier(pet ? "care-select-pet" : "care-select-kid")
    }

    private func resetActivity() {
        progress = 0
        reaction = instruction
    }

    private func interact() {
        guard !busy else { return }
        Haptics.tap()
        guard let action else {
            reaction = "Happy dance! Looking fabulous, \(buddyName)!"
            busy = true
            celebrating = true
            print("[BuddyPlay] dance pet=\(forPet)")
            return
        }
        progress += 1
        if progress < 3 {
            if action == .brush { reaction = "Lovely gentle brushing!" }
            else if action == .wash { reaction = "Pop, pop, bubbly fun!" }
            else { reaction = "Yum! \(3 - progress) more little \(action == .snack ? "bites of \(snack.lowercased())" : "sips")." }
        } else {
            store.care(action, forPet: forPet)
            reaction = action == .brush ? "Soft, tidy and fabulous!" : (action == .wash ? "Sparkly clean. Ta-da!" : "\(buddyName) says thank you!")
            progress = 0
            busy = true
            withAnimation { celebrating = true }
            Haptics.success()
        }
    }
}
