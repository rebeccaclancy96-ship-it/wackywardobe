import SwiftUI

struct WardrobePanel: View {
    let model: HomeViewModel
    let store: GameStore

    var body: some View {
        VStack(spacing: 12) {
            categoryTabs
            if model.category == .pets {
                Label("Special friends · Unicorn & Turtle", systemImage: "sparkles")
                    .font(.wacky(13)).foregroundStyle(Palette.skyDeep)
                    .accessibilityIdentifier("special-pets-heading")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(model.items(in: model.category).filter { item in
                        if case .costume(let costume) = item { return !costume.isShiny || store.owns(costume: costume.id) }
                        return true
                    }) { item in
                        ItemCard(
                            item: item,
                            store: store,
                            isOwned: model.isOwned(item, store: store),
                            isWorn: model.isWorn(item, store: store)
                        ) { model.tap(item, store: store) }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
            }
            .frame(height: 150)
            .id(model.category)
        }
        .padding(.top, 14)
        .padding(.bottom, 6)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous)
                        .fill(Palette.cream.opacity(0.75))
                )
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.15), radius: 14, y: -4)
        }
    }

    private var categoryTabs: some View {
        HStack(spacing: 8) {
            ForEach(WardrobeCategory.allCases) { category in
                let selected = model.category == category
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { model.category = category }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: category.symbol).font(.system(size: 18, weight: .bold))
                        Text(category.title).font(.wacky(12)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selected ? .white : category.tint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selected ? AnyShapeStyle(category.tint.gradient) : AnyShapeStyle(.white))
                    )
                }
                .buttonStyle(SquishButtonStyle())
                .accessibilityIdentifier("tab-\(category.rawValue)")
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ItemCard: View {
    let item: WardrobeItem
    let store: GameStore
    let isOwned: Bool
    let isWorn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ItemPreview(item: item, store: store)
                    .frame(width: 96, height: 100)
                    .saturation(isOwned ? 1 : 0.85)
                Text(item.name)
                    .font(.wacky(14))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(8)
            .frame(width: 112)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isWorn ? Palette.sun : .clear, lineWidth: 5)
            )
            .overlay(alignment: .topLeading) {
                if case .pet(let pet) = item, pet.isSpecialEdition {
                    Text("SPECIAL")
                        .font(.wacky(8, .black)).foregroundStyle(Palette.ink)
                        .padding(5).background(Palette.sun, in: Capsule()).offset(x: -3, y: -5)
                }
            }
            .overlay(alignment: .topTrailing) { badge.offset(x: 6, y: -6) }
            .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel(isOwned ? item.name : "\(item.name), costs \(item.price) coins")
        .accessibilityIdentifier("item-\(item.id)")
    }

    @ViewBuilder private var badge: some View {
        if isWorn {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 26, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Palette.dino)
        } else if !isOwned {
            PriceTag(price: item.price)
                .overlay(Capsule().stroke(Palette.sun, lineWidth: 2))
        }
    }
}

struct ItemPreview: View {
    let item: WardrobeItem
    let store: GameStore

    var body: some View {
        switch item {
        case .costume(let c):
            Image(c.imageName(for: store.kidType)).resizable().scaledToFit()
                .modifier(ShinyOutfitFinish(edition: c.isShiny ? c.id : nil))
        case .pet(let p):
            Image(p.imageName(outfit: "plain")).resizable().scaledToFit()
        case .petOutfit(let o):
            if let pet = store.pet {
                Image(pet.imageName(outfit: o.id)).resizable().scaledToFit()
            }
        case .scene(let s):
            // Draw the scene at phone size, then shrink it so the decorations keep their proportions.
            GeometryReader { geo in
                let scale: CGFloat = 0.3
                SceneBackground(scene: s)
                    .frame(width: geo.size.width / scale, height: geo.size.height / scale)
                    .scaleEffect(scale)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .allowsHitTesting(false)
        }
    }
}
