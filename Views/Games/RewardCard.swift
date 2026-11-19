import SwiftUI

/// The "You won!" card shown at the end of a mini-game.
struct RewardCard: View {
    let title: String
    let detail: String
    let coins: Int
    let onAgain: (() -> Void)?
    let onDone: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            ConfettiView()
            VStack(spacing: 14) {
                Text(title)
                    .font(.wacky(34, .black))
                    .foregroundStyle(Palette.ink)
                Text(detail)
                    .font(.wacky(17, .semibold))
                    .foregroundStyle(Palette.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    CoinIcon(size: 52)
                    Text("+\(coins)")
                        .font(.wacky(54, .black))
                        .foregroundStyle(Palette.sunDeep)
                }
                .scaleEffect(appear ? 1 : 0.3)
                .padding(.vertical, 6)
                VStack(spacing: 14) {
                    Button(action: onDone) {
                        Text("Collect!").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ChunkyButtonStyle(face: Palette.dino, base: Palette.dinoDeep))
                    .accessibilityIdentifier("reward-collect")
                    if let onAgain {
                        Button(action: onAgain) {
                            Label("Play again", systemImage: "arrow.clockwise").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(face: Palette.sky, base: Palette.skyDeep))
                        .accessibilityIdentifier("reward-again")
                    }
                }
            }
            .padding(26)
            .background(Palette.cream, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
            .padding(28)
            .scaleEffect(appear ? 1 : 0.7)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appear = true }
        }
    }
}
