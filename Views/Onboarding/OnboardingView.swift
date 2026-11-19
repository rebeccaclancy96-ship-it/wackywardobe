import SwiftUI

struct OnboardingView: View {
    @Environment(GameStore.self) private var store
    @State private var step = 0
    @State private var kid: KidType = .kid
    @State private var name = ""
    @State private var pet = "puppy"
    @State private var petName = ""

    var body: some View {
        ZStack {
            SceneBackground(scene: .rainbow)
            VStack(spacing: 0) {
                header
                Group {
                    if step == 0 {
                        KidPickerStep(selection: $kid, name: $name)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
                    } else {
                        PetPickerStep(kid: kid, selection: $pet, name: $petName)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
                    }
                }
                .frame(maxHeight: .infinity)
                footer
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("WACKY WARDROBE")
                .font(.wacky(15, .black))
                .tracking(2)
                .foregroundStyle(Palette.skyDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.white, in: Capsule())
            Text(step == 0 ? "Who are you?" : "Pick a pet buddy!")
                .font(.wacky(36, .black))
                .foregroundStyle(.white)
                .shadow(color: Palette.ink.opacity(0.55), radius: 0, x: 0, y: 3)
                .contentTransition(.opacity)
        }
        .padding(.top, 12)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step == 1 {
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = 0 }
                } label: {
                    Image(systemName: "arrow.left").font(.wacky(22))
                }
                .buttonStyle(ChunkyButtonStyle(face: Palette.sky, base: Palette.skyDeep))
                .accessibilityLabel("Back")
            }
            Button {
                Haptics.success()
                if step == 0 {
                    store.chooseKid(kid, name: name)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = 1 }
                } else {
                    store.adoptFirstPet(pet, name: petName)
                }
            } label: {
                Text(step == 0 ? "That's me!" : "Let's play!")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(face: Palette.dino, base: Palette.dinoDeep))
            .accessibilityIdentifier("onboarding-next")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

private struct KidPickerStep: View {
    @Binding var selection: KidType
    @Binding var name: String

    var body: some View {
        VStack(spacing: 18) {
            Image(Catalog.costumes[0].imageName(for: selection))
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity)
                .id(selection)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selection)
            HStack(spacing: 12) {
                ForEach(KidType.allCases) { type in
                    PickerChip(title: type.label, image: Catalog.costumes[0].imageName(for: type), isSelected: selection == type) {
                        Haptics.tap()
                        selection = type
                    }
                    .accessibilityIdentifier("kid-\(type.rawValue)")
                }
            }
            NameField(placeholder: "Your name (optional)", text: $name)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

private struct PetPickerStep: View {
    let kid: KidType
    @Binding var selection: String
    @Binding var name: String

    var body: some View {
        VStack(spacing: 18) {
            StageView(kidImage: Catalog.costumes[0].imageName(for: kid), petImage: Catalog.pet(selection).imageName(outfit: "plain"))
                .frame(maxHeight: .infinity)
            HStack(spacing: 10) {
                ForEach(Catalog.pets.filter { !$0.isSpecialEdition }) { pet in
                    PickerChip(title: pet.name, image: pet.imageName(outfit: "plain"), isSelected: selection == pet.id) {
                        Haptics.tap()
                        selection = pet.id
                    }
                    .accessibilityIdentifier("pet-\(pet.id)")
                }
            }
            NameField(placeholder: "Pet's name (optional)", text: $name)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct PickerChip: View {
    let title: String
    let image: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 62)
                Text(title)
                    .font(.wacky(14))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? Palette.sun : .clear, lineWidth: 5)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
            .scaleEffect(isSelected ? 1.06 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct NameField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.wacky(18, .bold))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .padding(.vertical, 14)
            .background(.white.opacity(0.92), in: Capsule())
            .accessibilityIdentifier("name-field")
            .onChange(of: text) { _, newValue in
                if newValue.count > 14 { text = String(newValue.prefix(14)) }
            }
    }
}
