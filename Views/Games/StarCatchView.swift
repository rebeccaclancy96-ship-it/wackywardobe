import SwiftUI

struct StarCatchView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model = StarCatchViewModel()

    var body: some View {
        ZStack {
            SceneBackground(scene: .space)
            playfield
            FullScreenLayout { reserved in
                VStack {
                    hud.clearOfReservedRegions(reserved)
                    Spacer()
                    if model.phase == .ready { startPanel.clearOfReservedRegions(reserved) }
                }
                .padding(16)
            }
            if model.phase == .done {
                RewardCard(
                    title: model.score > 0 ? "Super catch!" : "Nice try!",
                    detail: model.score > 0 ? "Look at all those stars!" : "Tap the stars to catch them",
                    coins: model.score,
                    onAgain: { model.start() },
                    onDone: { dismiss() }
                )
            }
        }
        .navigationBarBackButtonHidden(model.phase == .playing)
        .toolbar(model.phase == .playing ? .hidden : .visible, for: .navigationBar)
        .onChange(of: model.phase) { _, phase in
            if phase == .done {
                store.earn(model.score, from: "star catch")
                store.recordStarCatch(score: model.score)
            }
        }
        .onDisappear { model.stop() }
    }

    private var playfield: some View {
        GeometryReader { geo in
            TimelineView(.animation(paused: model.phase != .playing)) { context in
                ZStack {
                    ForEach(model.fallers) { faller in
                        let point = CGPoint(x: faller.x * geo.size.width, y: model.y(for: faller, at: context.date))
                        FallerView(kind: faller.kind)
                            .rotationEffect(.degrees(faller.spin * context.date.timeIntervalSince(faller.born)))
                            .frame(width: faller.kind.size + 24, height: faller.kind.size + 24)
                            .contentShape(Circle())
                            .position(point)
                            .onTapGesture { model.catchFaller(faller, at: point) }
                    }
                    ForEach(model.pops) { pop in
                        PopLabel(value: pop.value).position(pop.point)
                    }
                }
            }
            .onAppear { model.areaHeight = geo.size.height }
        }
        .ignoresSafeArea()
    }

    private var hud: some View {
        HStack {
            Label("\(model.timeLeft)s", systemImage: "timer")
                .font(.wacky(22))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.18), in: Capsule())
                .contentTransition(.numericText(countsDown: true))
            Spacer()
            HStack(spacing: 6) {
                CoinIcon(size: 28)
                Text("\(model.score)").font(.wacky(24)).foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(model.score)))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.white.opacity(0.18), in: Capsule())
        }
        .opacity(model.phase == .ready ? 0 : 1)
        .animation(.snappy, value: model.score)
        .animation(.snappy, value: model.timeLeft)
    }

    private var startPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                legend(.star, "1")
                legend(.coin, "2")
                legend(.rainbow, "5")
            }
            Text("Tap the stars before they fall!")
                .font(.wacky(20))
                .foregroundStyle(.white)
            Button {
                Haptics.bump()
                model.start()
            } label: {
                Text("Start!").frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(face: Palette.sun, base: Palette.sunDeep))
            .accessibilityIdentifier("starcatch-start")
        }
        .padding(22)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func legend(_ kind: StarCatchViewModel.Kind, _ value: String) -> some View {
        VStack(spacing: 4) {
            FallerView(kind: kind).frame(width: 46, height: 46)
            Text("+\(value)").font(.wacky(16)).foregroundStyle(Palette.sun)
        }
    }
}

private struct FallerView: View {
    let kind: StarCatchViewModel.Kind
    var body: some View {
        switch kind {
        case .star:
            Image(systemName: "star.fill")
                .resizable().scaledToFit()
                .foregroundStyle(Palette.sun.gradient)
                .shadow(color: Palette.sun.opacity(0.8), radius: 10)
                .padding(10)
        case .coin:
            CoinIcon(size: kind.size).shadow(color: Palette.sun.opacity(0.6), radius: 8)
        case .rainbow:
            Image(systemName: "star.fill")
                .resizable().scaledToFit()
                .foregroundStyle(AngularGradient(colors: Palette.rainbow + [Palette.rainbow[0]], center: .center))
                .shadow(color: .white.opacity(0.9), radius: 12)
                .padding(8)
        }
    }
}

private struct PopLabel: View {
    let value: Int
    @State private var rise = false
    var body: some View {
        Text("+\(value)")
            .font(.wacky(30, .black))
            .foregroundStyle(Palette.sun)
            .shadow(color: .black.opacity(0.4), radius: 0, y: 2)
            .offset(y: rise ? -60 : 0)
            .opacity(rise ? 0 : 1)
            .scaleEffect(rise ? 1.3 : 0.8)
            .onAppear { withAnimation(.easeOut(duration: 0.7)) { rise = true } }
            .allowsHitTesting(false)
    }
}
