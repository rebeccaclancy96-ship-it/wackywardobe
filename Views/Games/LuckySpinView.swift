import SwiftUI

struct LuckySpinView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model = LuckySpinViewModel()

    var body: some View {
        ZStack {
            SceneBackground(scene: .jungle)
            VStack(spacing: 28) {
                Text("Lucky Spin")
                    .font(.wacky(40, .black))
                    .foregroundStyle(.white)
                    .shadow(color: Palette.ink.opacity(0.45), radius: 0, y: 3)
                wheel
                spinButton
            }
            .padding(.horizontal, 24)
            if let prize = model.wonPrize {
                RewardCard(title: "Woo-hoo!", detail: "The wheel gave you a prize", coins: prize, onAgain: nil) { dismiss() }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var wheel: some View {
        ZStack(alignment: .top) {
            ZStack {
                ForEach(Array(LuckySpinViewModel.prizes.enumerated()), id: \.offset) { index, prize in
                    WheelSlice(index: index, count: LuckySpinViewModel.prizes.count)
                        .fill(LuckySpinViewModel.colors[index].gradient)
                    WheelSlice(index: index, count: LuckySpinViewModel.prizes.count)
                        .stroke(.white, lineWidth: 4)
                    GeometryReader { geo in
                        let angle = Angle.degrees(Double(index) * model.sliceAngle + model.sliceAngle / 2)
                        HStack(spacing: 2) {
                            Text("\(prize)").font(.wacky(prize >= 50 ? 30 : 26, .black)).foregroundStyle(.white)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 0, y: 2)
                        .rotationEffect(angle)
                        .position(x: geo.size.width / 2 + sin(angle.radians) * geo.size.width * 0.33,
                                  y: geo.size.height / 2 - cos(angle.radians) * geo.size.height * 0.33)
                    }
                }
                Circle().fill(.white).frame(width: 64, height: 64)
                CoinIcon(size: 50)
            }
            .aspectRatio(1, contentMode: .fit)
            .rotationEffect(.degrees(model.rotation))
            .padding(10)
            .background(Circle().fill(Palette.sun))
            .overlay(Circle().stroke(Palette.sunDeep, lineWidth: 6))
            .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 46))
                .foregroundStyle(Palette.bubblegum)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                .offset(y: -22)
        }
    }

    @ViewBuilder private var spinButton: some View {
        if let next = store.nextSpinDate, model.wonPrize == nil, !model.spinning {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: 6) {
                    Text("Next spin in").font(.wacky(18)).foregroundStyle(.white)
                    Text(countdown(to: next, now: context.date))
                        .font(.wacky(36, .black))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 14)
                .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        } else {
            Button {
                model.spin { prize in
                    store.earn(prize, from: "lucky spin")
                }
                store.recordSpin()
            } label: {
                Text(model.spinning ? "Spinning…" : "SPIN!").frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(face: Palette.bubblegum, base: Color(red: 0.78, green: 0.18, blue: 0.42)))
            .disabled(model.spinning)
            .accessibilityIdentifier("spin-button")
        }
    }

    private func countdown(to date: Date, now: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(now)))
        return String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
}

private struct WheelSlice: Shape {
    let index: Int
    let count: Int
    func path(in rect: CGRect) -> Path {
        let slice = 360 / Double(count)
        let start = Angle.degrees(Double(index) * slice - 90)
        let end = Angle.degrees(Double(index + 1) * slice - 90)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: min(rect.width, rect.height) / 2, startAngle: start, endAngle: end, clockwise: false)
        path.closeSubpath()
        return path
    }
}
