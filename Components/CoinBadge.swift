import SwiftUI

struct CoinIcon: View {
    var size: CGFloat = 26
    var body: some View {
        ZStack {
            Circle().fill(Palette.sunDeep)
            Circle().fill(Palette.sun.gradient).padding(size * 0.1)
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.45, weight: .black))
                .foregroundStyle(Palette.sunDeep)
        }
        .frame(width: size, height: size)
    }
}

struct CoinBadge: View {
    let coins: Int
    var body: some View {
        HStack(spacing: 8) {
            CoinIcon(size: 28)
            Text(coins, format: .number)
                .font(.wacky(22))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText(value: Double(coins)))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.leading, 6)
        .padding(.trailing, 16)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 2))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: coins)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(coins) coins")
        .accessibilityIdentifier("coin-badge")
    }
}

struct PriceTag: View {
    let price: Int
    var body: some View {
        HStack(spacing: 4) {
            CoinIcon(size: 16)
            Text("\(price)").font(.wacky(14)).foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Palette.cream, in: Capsule())
    }
}
