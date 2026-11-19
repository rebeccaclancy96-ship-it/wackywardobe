import SwiftUI

/// A touch-to-count playground. The learning rules and wallet reward stay in the shared model.
struct NumberBuddiesView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = LearningGameViewModel(kind: .numbers)
    @State private var counted: [Int] = []
    @State private var celebrating = false

    private let colors: [Color] = [Color(red: 0.55, green: 0.22, blue: 0.85),
                                   Color(red: 0.0, green: 0.43, blue: 0.65),
                                   Color(red: 0.85, green: 0.12, blue: 0.39)]
    private var subtracting: Bool { model.question.operation == "−" }
    private var heading: String {
        model.question.operation == nil ? "How many pets are here?" : (subtracting ? "Bye-bye, little pets!" : "Bring the pets together!")
    }
    private var remaining: Int { subtracting ? model.question.groups[0] - model.question.groups[1] : model.question.groups.reduce(0, +) }

    var body: some View {
        ZStack {
            playgroundBackground
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                    adventureTrail.id("number-top")
                    HStack(spacing: 12) {
                        if let pet = store.petImage {
                            Image(pet).resizable().scaledToFit().frame(width: 60, height: 60)
                                .rotationEffect(.degrees(model.solved && !reduceMotion ? -10 : 0))
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.solved ? "You're a number superstar!" : "A little number adventure")
                                .font(.wacky(20, .black))
                            Text(model.solved ? "High five! You did it!" : "Touch, count, then choose!")
                                .font(.wacky(14)).foregroundStyle(colors[0])
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 26))
                    countingPlayground
                    HStack {
                        Text(model.solved ? "Hooray! That's right!" : "Which number is it?")
                            .font(.wacky(23, .black))
                        Spacer(minLength: 0)
                        Text(model.solved ? "🌈" : "👇").font(.system(size: 28)).accessibilityHidden(true)
                    }
                    answers
                    Text(model.solved ? model.feedback : (model.tried.isEmpty ? "Every little try helps your brain grow!" : "Good try! Count with me, then try another."))
                        .font(.wacky(16)).multilineTextAlignment(.center)
                        .padding(14).frame(maxWidth: .infinity)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 22))
                        .accessibilityIdentifier("learning-feedback")
                    Label("No timer. Just happy little steps.", systemImage: "heart.fill")
                        .font(.wacky(12)).foregroundStyle(colors[0])
                }
                .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 20)
                .frame(maxWidth: 540).frame(maxWidth: .infinity)
            }
                .onChange(of: model.index) { _, _ in proxy.scrollTo("number-top", anchor: .top) }
                .onChange(of: model.done) { _, done in if !done { proxy.scrollTo("number-top", anchor: .top) } }
            }
            .allowsHitTesting(!model.done)
            .accessibilityHidden(model.done)
            if celebrating && !reduceMotion { ConfettiView().accessibilityHidden(true) }
            if model.done {
                RewardCard(title: "Number superstar!", detail: "Five fun adventures. Look what you learned!", coins: model.reward,
                           onAgain: restart, onDone: { dismiss() })
            }
        }
        .foregroundStyle(Palette.ink)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.solved && !model.done {
                Button { model.next() } label: {
                    Label(model.index == 4 ? "Collect my 20 coins!" : "Let's go! Next adventure", systemImage: "arrow.right.circle.fill")
                        .font(.wacky(18)).frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(face: Palette.dino, base: Palette.dinoDeep))
                .accessibilityIdentifier("learning-next")
                .padding(.horizontal, 18).padding(.vertical, 10)
                .frame(maxWidth: 540).frame(maxWidth: .infinity).background(.regularMaterial)
            }
        }
        .navigationTitle("Number Buddies")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { model.stopSpeaking() }
        .onChange(of: model.index) { _, _ in counted = []; celebrating = false }
        .onChange(of: model.solved) { _, solved in celebrating = solved }
        .onChange(of: model.done) { _, done in
            if done, let coins = model.claimReward() { store.earn(coins, from: "learning-numbers") }
        }
        .task(id: celebrating) {
            guard celebrating else { return }
            do { try await Task.sleep(for: .milliseconds(1800)) } catch { return }
            celebrating = false
        }
    }

    private var playgroundBackground: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 0.77, green: 0.67, blue: 1), Color(red: 1, green: 0.82, blue: 0.91),
                                        Color(red: 1, green: 0.94, blue: 0.60)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(Color(red: 1, green: 0.84, blue: 0.24)).frame(width: 150, height: 150)
                    .position(x: geo.size.width - 5, y: 145)
                Ellipse().fill(Color(red: 0.47, green: 0.88, blue: 0.73)).frame(width: geo.size.width * 1.8, height: 300)
                    .position(x: geo.size.width * 0.3, y: geo.size.height)
                ForEach(0..<8) { index in
                    Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "cloud.fill")
                        .font(.system(size: index.isMultiple(of: 2) ? 28 : 70))
                        .foregroundStyle(.white.opacity(0.6))
                        .position(x: index.isMultiple(of: 2) ? 20 : geo.size.width - 20, y: CGFloat(index) * 120 + 50)
                }
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }

    private var adventureTrail: some View {
        HStack(spacing: 8) {
            HStack(spacing: 7) {
                ForEach(0..<5) { index in
                    let complete = index < model.index || (index == model.index && model.solved)
                    ZStack {
                        Circle().fill(complete ? Palette.sun : .white.opacity(0.85))
                        if complete {
                            Image(systemName: "star.fill").foregroundStyle(Color(red: 0.76, green: 0.34, blue: 0))
                        } else {
                            Text("\(index + 1)").foregroundStyle(colors[index % 3])
                        }
                    }.font(.wacky(15, .black)).frame(width: 32, height: 32)
                        .overlay(Circle().stroke(index == model.index ? colors[0] : .clear, lineWidth: 3))
                }
            }.accessibilityElement(children: .ignore)
                .accessibilityLabel("Adventure \(model.index + 1) of 5")
                .accessibilityIdentifier("learning-progress")
            Spacer(minLength: 0)
            Label("20", systemImage: "star.circle.fill")
                .font(.wacky(16)).foregroundStyle(colors[0]).padding(8)
                .background(.white, in: Capsule()).accessibilityLabel("Earn 20 coins this round")
        }
    }

    private var countingPlayground: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Text(heading).font(.wacky(25, .black)).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                Button { model.readAloud() } label: {
                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 23, weight: .bold))
                        .foregroundStyle(colors[0]).frame(width: 52, height: 52)
                        .background(colors[0].opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                }.accessibilityLabel("Hear the question").accessibilityIdentifier("learning-hear")
            }
            if let operation = model.question.operation {
                HStack(spacing: 9) {
                    numberBuddy(String(model.question.groups[0]), color: colors[0])
                    Text(operation).font(.wacky(28, .black)).foregroundStyle(colors[2])
                    numberBuddy(String(model.question.groups[1]), color: colors[1])
                    Text("=").font(.wacky(24, .black))
                    numberBuddy(model.solved ? model.question.answer : "?", color: colors[2])
                }
                .accessibilityElement(children: .ignore).accessibilityLabel(model.question.display)
                .accessibilityIdentifier("learning-question")
            } else {
                Text("Count every furry (or magical!) friend")
                    .font(.wacky(16, .bold)).foregroundStyle(colors[0]).multilineTextAlignment(.center)
                    .accessibilityLabel("Count the pets").accessibilityIdentifier("learning-question")
            }
            VStack(spacing: 10) {
                if subtracting {
                    petGroup(count: model.question.groups[0], offset: 0, crossedFrom: remaining)
                } else {
                    ForEach(Array(model.question.groups.enumerated()), id: \.offset) { index, count in
                        if index > 0 {
                            Text("+ put them together +").font(.wacky(13)).foregroundStyle(colors[0])
                        }
                        petGroup(count: count, offset: index == 0 ? 0 : model.question.groups[0], crossedFrom: nil)
                    }
                }
                Text(subtracting ? "Faded pets went for a nap. Count only the bright pets left!" : "Tap each pet once, then choose how many!")
                    .font(.wacky(13)).multilineTextAlignment(.center)
                Text(counted.isEmpty ? "Ready, steady… count!" : "\(counted.count) counted!\(counted.count == remaining ? " Great counting!" : "")")
                    .font(.wacky(16, .black)).foregroundStyle(colors[0])
                    .accessibilityIdentifier("number-count-status")
            }
            .padding(12).frame(maxWidth: .infinity)
            .background(Color(red: 1, green: 0.95, blue: 0.74), in: RoundedRectangle(cornerRadius: 24))
        }
        .padding(18).background(.white, in: RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(colors[0].opacity(0.25), lineWidth: 3))
    }

    private func numberBuddy(_ text: String, color: Color) -> some View {
        VStack(spacing: 0) {
            Text(text).font(.wacky(34, .black)).minimumScaleFactor(0.6).lineLimit(1)
            HStack(spacing: 9) {
                Circle().frame(width: 4, height: 5)
                Circle().frame(width: 4, height: 5)
            }
            Text("⌣").font(.system(size: 18, weight: .bold)).offset(y: -3)
        }
        .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 80)
        .background(color.gradient, in: RoundedRectangle(cornerRadius: 19))
        .rotationEffect(.degrees(text == "?" ? 5 : -3))
    }

    private func petGroup(count: Int, offset: Int, crossedFrom: Int?) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                let id = offset + index
                let pet = Catalog.pets[(id + model.index * 2) % Catalog.pets.count]
                let removed = index >= (crossedFrom ?? count)
                let tally = counted.firstIndex(of: id).map { $0 + 1 }
                Button {
                    guard !removed, !model.solved, !counted.contains(id) else { return }
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.65)) {
                        counted.append(id)
                    }
                    Haptics.tap()
                    print("[NumberBuddies] counted pet \(pet.id), tile=\(id), counted=\(counted.count)")
                } label: {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(removed ? Color.gray.opacity(0.1) : (tally != nil ? Palette.dino.opacity(0.22) : .white))
                        Image(pet.imageName(outfit: "plain")).resizable().scaledToFit()
                            .padding(5).opacity(removed ? 0.2 : 1)
                            .scaleEffect(tally != nil && !reduceMotion ? 1.06 : 1)
                        if removed {
                            Image(systemName: "moon.zzz.fill").font(.system(size: 17)).foregroundStyle(colors[0])
                                .padding(6).background(.white, in: Capsule()).padding(3)
                        } else if let tally {
                            Text("\(tally)").font(.wacky(18, .black)).foregroundStyle(.white)
                                .frame(width: 28, height: 28).background(colors[0], in: Circle()).padding(3)
                        }
                    }
                    .frame(height: 86)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(tally != nil ? Palette.dinoDeep : .clear, lineWidth: 2))
                }
                .buttonStyle(SquishButtonStyle()).disabled(removed || model.solved)
                .accessibilityLabel(removed ? "\(pet.name), went for a nap, not counted" : "\(pet.name)\(tally.map { ", counted \($0)" } ?? ", tap to count")")
                .accessibilityIdentifier("number-pet-\(id)")
            }
        }
    }

    private var answers: some View {
        HStack(spacing: 12) {
            ForEach(Array(model.question.choices.enumerated()), id: \.element) { index, answer in
                let correct = model.solved && answer == model.question.answer
                let tried = model.tried.contains(answer)
                Button { model.choose(answer) } label: {
                    VStack(spacing: 3) {
                        Text(answer).font(.wacky(46, .black))
                        Image(systemName: correct ? "checkmark.circle.fill" : (tried ? "arrow.clockwise" : "hand.tap.fill"))
                            .font(.system(size: 16, weight: .bold))
                    }.frame(maxWidth: .infinity).frame(minHeight: 85)
                }
                .buttonStyle(ChunkyButtonStyle(face: correct ? Palette.dinoDeep : colors[index], base: colors[index].opacity(0.75)))
                .opacity(tried ? 0.45 : 1).disabled(model.solved || tried)
                .accessibilityLabel("Answer \(answer)\(correct ? ", correct" : "")")
                .accessibilityIdentifier("learning-answer-\(answer)")
            }
        }
    }

    private func restart() {
        counted = []
        celebrating = false
        model.newGame()
    }
}
