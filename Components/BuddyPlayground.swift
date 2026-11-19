import SwiftUI

/// Animated, touch-driven play space using the player's actual saved character and pet art.
struct BuddyPlayground: View {
    let store: GameStore
    let forPet: Bool
    let action: CareAction?
    let snack: String
    let progress: Int
    let celebrating: Bool
    let onCare: () -> Void
    let onPlay: (String) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var kidX: CGFloat = 0.37
    @State private var petX: CGFloat = 0.77
    @State private var walking = false
    @State private var touching = false
    @State private var toolPoint: CGPoint?
    @State private var lastStroke: CGPoint?
    @State private var effectStart = Date.distantPast
    @State private var walkID = 0

    private var tool: String {
        switch action {
        case .snack: forPet ? (snack == "Pet dinner" ? "🥣" : "🦴") : (snack == "Sandwich" ? "🥪" : "🍎")
        case .drink: "💧"
        case .brush: "🪮"
        case .wash: "🧽"
        case nil: "👋"
        }
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let kid = buddyRect(pet: false, size: geo.size)
                let pet = buddyRect(pet: true, size: geo.size)
                let active = forPet ? pet : kid
                ZStack {
                    SceneBackground(scene: store.scene)
                    Ellipse().fill(.white.opacity(0.55))
                        .frame(width: geo.size.width * 0.94, height: 65)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.65)
                    sprite(image: store.kidImage, rect: kid, pet: false, time: time)
                    if let image = store.petImage { sprite(image: image, rect: pet, pet: true, time: time) }
                    if action != nil {
                        RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .frame(width: active.width + 14, height: active.height + 10)
                            .position(x: active.midX, y: active.midY)
                    }
                    effects(in: active, elapsed: context.date.timeIntervalSince(effectStart))
                    if let point = toolPoint {
                        Text(tool).font(.system(size: 44)).shadow(color: .black.opacity(0.15), radius: 5, y: 3)
                            .position(point)
                    }
                }
                .contentShape(Rectangle())
                .highPriorityGesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !celebrating else { return }
                        touching = true
                        if action == nil {
                            if value.translation.width.magnitude > 8 {
                                let x = min(0.82, max(0.18, value.location.x / geo.size.width))
                                if forPet { petX = x } else { kidX = x }
                                walking = true
                            }
                        } else {
                            toolPoint = value.location
                            guard active.insetBy(dx: -12, dy: -8).contains(value.location) else { lastStroke = nil; return }
                            if action == .brush || action == .wash {
                                if let last = lastStroke, hypot(value.location.x - last.x, value.location.y - last.y) >= 28 {
                                    registerCare()
                                    lastStroke = value.location
                                } else if lastStroke == nil { lastStroke = value.location }
                            }
                        }
                    }
                    .onEnded { value in
                        touching = false
                        toolPoint = nil
                        lastStroke = nil
                        guard !celebrating else { return }
                        if action == nil {
                            move(to: value.location.x / geo.size.width)
                            if hypot(value.translation.width, value.translation.height) < 10 {
                                effectStart = .now
                                onPlay(forPet ? "Hop, hop! Your pet is coming to play!" : "Here I come! Let's play together!")
                            } else { onPlay("Wheee! Moving together!") }
                        } else if action == .snack || action == .drink {
                            let face = CGRect(x: active.minX - 12, y: active.minY, width: active.width + 24, height: active.height * 0.65)
                            if face.contains(value.location) { registerCare() }
                        }
                    })
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(store.playerName.isEmpty ? "Your character" : store.playerName) and \(store.petName.isEmpty ? "your pet" : store.petName), wearing your saved outfits. "
                                    + (action == nil ? "Tap the floor to walk or drag to move. Use Dance below as an alternative." : "Use the tool on the selected buddy, or the action button below."))
                .accessibilityIdentifier("care-play-area")
            }
        }
        .task(id: walkID) {
            do { try await Task.sleep(for: .milliseconds(850)) } catch { return }
            walking = false
        }
        .task(id: action) {
            // Gentle wandering during free play. Care mode keeps the target still for small hands.
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(4)) } catch { return }
                guard action == nil, !touching, !celebrating, !reduceMotion else { continue }
                move(to: CGFloat.random(in: 0.24...0.76))
            }
        }
        .onChange(of: forPet) { _, _ in resetPositions() }
        .onChange(of: action) { _, _ in resetPositions() }
        .onChange(of: progress) { _, _ in effectStart = .now }
        .onChange(of: celebrating) { _, value in if value { effectStart = .now } }
    }

    private func buddyRect(pet: Bool, size: CGSize) -> CGRect {
        let scale = min(1.5, max(0.85, min(size.width / 360, size.height / 600)))
        let height: CGFloat = (pet ? (forPet ? 190 : 130) : (forPet ? 245 : 290)) * scale
        let width = height * (pet ? 1 : 0.67)
        return CGRect(x: size.width * (pet ? petX : kidX) - width / 2,
                      y: size.height * 0.67 - height, width: width, height: height)
    }

    private func sprite(image: String, rect: CGRect, pet: Bool, time: Double) -> some View {
        let selected = pet == forPet
        let moving = selected && (walking || celebrating) && !reduceMotion
        let bob = reduceMotion ? 0 : (moving ? abs(sin(time * 12)) * -12 : sin(time * 2.2 + (pet ? 1 : 0)) * 3)
        let tilt = reduceMotion ? 0 : sin(time * (moving ? 12 : 2)) * (moving ? 6 : 1.5)
        return Image(image).resizable().scaledToFit()
            .modifier(ShinyOutfitFinish(edition: !pet && store.costume.isShiny ? store.costume.id : nil))
            .frame(width: rect.width, height: rect.height)
            .rotationEffect(.degrees(tilt), anchor: .bottom)
            .scaleEffect(celebrating && selected ? 1.08 : 1, anchor: .bottom)
            .offset(y: bob)
            .position(x: rect.midX, y: rect.midY)
            .animation(.spring(response: 0.3, dampingFraction: 0.45), value: celebrating)
            .allowsHitTesting(false)
    }

    @ViewBuilder private func effects(in rect: CGRect, elapsed: Double) -> some View {
        if elapsed >= 0 && elapsed < 1.2 {
            let fraction = min(elapsed / 1.2, 1)
            ForEach(0..<6) { index in
                Image(systemName: action == .wash ? "bubble.fill" : (action == .brush ? "sparkles" : "heart.fill"))
                    .font(.system(size: action == .wash ? 24 : 18))
                    .foregroundStyle(action == .wash ? Palette.sky : Palette.bubblegum)
                    .opacity(1 - fraction)
                    .position(x: rect.midX + CGFloat(index - 3) * 19,
                              y: rect.minY + rect.height * 0.45 - (reduceMotion ? 0 : fraction * 85) + Double(index % 2) * 16)
            }
        }
    }

    private func registerCare() {
        effectStart = .now
        onCare()
    }

    private func move(to x: CGFloat) {
        let destination = min(0.78, max(0.22, x))
        walking = true
        walkID += 1
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.8)) {
            if forPet { petX = destination } else { kidX = destination }
        }
        print("[BuddyPlay] moving \(forPet ? "pet" : "kid") to \(destination)")
    }

    private func resetPositions() {
        toolPoint = nil
        lastStroke = nil
        touching = false
        walking = false
        kidX = forPet ? 0.25 : 0.38
        petX = forPet ? 0.70 : 0.78
    }
}
