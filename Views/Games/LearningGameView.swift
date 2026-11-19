import SwiftUI

struct LearningGameView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: LearningGameViewModel

    init(kind: LearningGameKind) {
        _model = State(initialValue: LearningGameViewModel(kind: kind))
    }

    private let tileColors: [Color] = [Color(red: 0.60, green: 0.32, blue: 0.83), Color(red: 0.0, green: 0.47, blue: 0.65), Color(red: 0.82, green: 0.23, blue: 0.42)]
    private var accent: Color { model.kind == .alphabet ? tileColors[2] : tileColors[1] }
    private var letterMatch: Bool { model.kind == .alphabet && model.question.display.count == 1 }
    private var shortPrompt: String {
        if model.kind == .alphabet { return letterMatch ? "Find my little letter!" : "What letter comes first?" }
        if model.question.operation == "−" { return "How many are left?" }
        return model.question.operation == nil ? "Let's count the stars!" : "Let's add them together!"
    }
    private var picture: String {
        let pictures = ["Apple": "🍎", "Ball": "⚽️", "Cat": "🐱", "Dog": "🐶", "Egg": "🥚", "Fish": "🐠", "Goat": "🐐", "Hat": "🎩",
                        "Igloo": "🧊", "Jam": "🫙", "Kite": "🪁", "Lion": "🦁", "Moon": "🌙", "Nest": "🪺", "Owl": "🦉", "Pig": "🐷",
                        "Queen": "👑", "Rain": "🌧️", "Sun": "☀️", "Tree": "🌳", "Umbrella": "☂️", "Van": "🚐", "Web": "🕸️", "Xylophone": "🎵", "Yo-yo": "🪀", "Zebra": "🦓"]
        return pictures[model.question.display] ?? "🌈"
    }

    var body: some View {
        ZStack {
            learningBackground
            ScrollView {
                VStack(spacing: 16) {
                    progressTrail
                    questionCard
                    Text(model.solved ? "You found it! Hooray!" : "Tap your answer")
                        .font(.wacky(18, .black)).foregroundStyle(accent)
                    answerTiles
                    cheerleader
                    Label("No rush. We can try again!", systemImage: "heart.fill")
                        .font(.wacky(12)).foregroundStyle(Palette.ink.opacity(0.65))
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
                .frame(maxWidth: 520).frame(maxWidth: .infinity)
            }
            .allowsHitTesting(!model.done)
            if model.done {
                RewardCard(title: "Super learner!", detail: "Five little steps. A big well done!", coins: model.reward,
                           onAgain: { model.newGame() }, onDone: { dismiss() })
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.solved && !model.done {
                Button { model.next() } label: {
                    Label(model.index == 4 ? "Finish & win 20 coins" : "Next question", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(face: Palette.dino, base: Palette.dinoDeep))
                .accessibilityIdentifier("learning-next")
                .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 8)
                .frame(maxWidth: 520).frame(maxWidth: .infinity).background(.regularMaterial)
            }
        }
        .foregroundStyle(Palette.ink)
        .navigationTitle(model.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { model.stopSpeaking() }
        .onChange(of: model.done) { _, done in
            if done, let coins = model.claimReward() { store.earn(coins, from: "learning-\(model.kind)") }
        }
    }

    private var learningBackground: some View {
        ZStack {
            LinearGradient(colors: model.kind == .alphabet
                           ? [Color(red: 1, green: 0.90, blue: 0.93), Palette.cream, Color(red: 0.90, green: 0.85, blue: 1)]
                           : [Color(red: 0.79, green: 0.95, blue: 1), Palette.cream, Color(red: 0.86, green: 0.97, blue: 0.83)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            GeometryReader { geo in
                ForEach(0..<9) { index in
                    Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "cloud.fill")
                        .font(.system(size: index.isMultiple(of: 2) ? 24 : 60))
                        .foregroundStyle(.white.opacity(0.6))
                        .rotationEffect(.degrees(Double(index * 13)))
                        .position(x: geo.size.width * (index.isMultiple(of: 2) ? 0.07 : 0.94), y: CGFloat(index + 1) * 105)
                }
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }

    private var progressTrail: some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                ForEach(0..<5) { step in
                    let filled = step < model.index || (step == model.index && model.solved)
                    Image(systemName: filled ? "star.fill" : "star")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(filled ? Palette.sunDeep : accent.opacity(0.35))
                        .scaleEffect(filled ? 1.08 : 1)
                }
            }.accessibilityElement(children: .ignore)
                .accessibilityLabel("\(model.index + (model.solved ? 1 : 0)) of 5 questions solved")
            Spacer(minLength: 4)
            Text("\(model.index + 1) of 5").font(.wacky(14)).accessibilityIdentifier("learning-progress")
            Label("20", systemImage: "star.circle.fill").font(.wacky(14)).foregroundStyle(Palette.sunDeep)
                .padding(8).background(.white.opacity(0.85), in: Capsule()).accessibilityLabel("Earn 20 coins this round")
        }
    }

    private var questionCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                Text(shortPrompt).font(.wacky(22, .black)).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                Button { model.readAloud() } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "speaker.wave.2.fill").font(.title3)
                        Text("Listen").font(.wacky(11))
                    }.frame(width: 60, height: 56).background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                }
                .tint(accent).accessibilityLabel("Hear the question").accessibilityIdentifier("learning-hear")
            }
            if model.kind == .alphabet {
                HStack(spacing: 18) {
                    if letterMatch {
                        VStack(spacing: 0) {
                            Text(model.question.display).font(.system(size: 88, weight: .black, design: .rounded))
                                .foregroundStyle(accent).accessibilityIdentifier("learning-question")
                            HStack(spacing: 16) {
                                Circle().frame(width: 7, height: 7)
                                Circle().frame(width: 7, height: 7)
                            }.foregroundStyle(Palette.ink)
                            Text("⌣").font(.system(size: 30, weight: .bold)).offset(y: -7)
                        }
                        .frame(width: 145, height: 150).background(Palette.sun.opacity(0.25), in: RoundedRectangle(cornerRadius: 30))
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.right").font(.title2.bold())
                            Text("a b c").font(.wacky(25, .black))
                            Text("Little letters").font(.wacky(12))
                        }.foregroundStyle(accent).accessibilityHidden(true)
                    } else {
                        Text(picture).font(.system(size: 78)).frame(width: 120, height: 130)
                            .background(Palette.sun.opacity(0.18), in: RoundedRectangle(cornerRadius: 28)).accessibilityHidden(true)
                        Text(model.question.display).font(.system(size: 35, weight: .black, design: .rounded))
                            .minimumScaleFactor(0.55).lineLimit(1).foregroundStyle(accent)
                            .accessibilityIdentifier("learning-question")
                    }
                }.frame(maxWidth: .infinity).padding(.vertical, 5)
            } else {
                if model.question.operation != nil {
                    Text(model.question.display).font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(accent).accessibilityIdentifier("learning-question")
                } else {
                    Text("Count the stars").font(.wacky(17)).foregroundStyle(accent).accessibilityIdentifier("learning-question")
                }
                countingStars
            }
        }
        .padding(18).frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(accent.opacity(0.18), lineWidth: 3))
        .shadow(color: accent.opacity(0.10), radius: 0, y: 6)
    }

    private var answerTiles: some View {
        HStack(spacing: 12) {
            ForEach(Array(model.question.choices.enumerated()), id: \.element) { index, answer in
                let correct = model.solved && answer == model.question.answer
                let tried = model.tried.contains(answer)
                Button { model.choose(answer) } label: {
                    VStack(spacing: 2) {
                        Text(answer).font(.system(size: 45, weight: .black, design: .rounded)).minimumScaleFactor(0.7)
                        Image(systemName: correct ? "checkmark.circle.fill" : (tried ? "arrow.clockwise" : "hand.tap.fill"))
                            .font(.system(size: 15, weight: .bold))
                    }.frame(maxWidth: .infinity).frame(minHeight: 82)
                }
                .buttonStyle(ChunkyButtonStyle(face: correct ? Palette.dinoDeep : tileColors[index], base: tileColors[index].opacity(0.7)))
                .opacity(tried ? 0.45 : 1)
                .scaleEffect(correct && !reduceMotion ? 1.04 : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.55), value: correct)
                .disabled(model.solved || tried)
                .accessibilityLabel("Answer \(answer)\(correct ? ", correct" : "")")
                .accessibilityIdentifier("learning-answer-\(answer)")
            }
        }
    }

    private var cheerleader: some View {
        HStack(spacing: 10) {
            if let pet = store.petImage {
                Image(pet).resizable().scaledToFit().frame(width: 67, height: 76)
                    .rotationEffect(.degrees(model.solved && !reduceMotion ? -8 : 0))
                    .animation(.spring(response: 0.35, dampingFraction: 0.55), value: model.solved)
                    .accessibilityHidden(true)
            }
            Text(model.solved ? model.feedback : (model.tried.isEmpty ? "You can do it! Pick one below the picture." : "Nice try! Let's pick another one."))
                .font(.wacky(16)).multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("learning-feedback")
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 24))
    }

    private var countingStars: some View {
        VStack(spacing: 8) {
            if model.question.operation == "−" {
                let total = model.question.groups[0]
                let removed = model.question.groups[1]
                starGroup(total, crossedFrom: total - removed)
                Text("Count the bright stars. Crossed-out stars go away!")
                    .font(.wacky(12)).multilineTextAlignment(.center)
            } else {
                ForEach(Array(model.question.groups.enumerated()), id: \.offset) { index, count in
                    if index > 0 { Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(accent).accessibilityHidden(true) }
                    starGroup(count)
                }
            }
        }.padding(12).frame(maxWidth: .infinity)
            .background(Color(red: 1, green: 0.97, blue: 0.84), in: RoundedRectangle(cornerRadius: 23))
    }

    private func starGroup(_ count: Int, crossedFrom: Int? = nil) -> some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                let removed = index >= (crossedFrom ?? count)
                ZStack {
                    Image(systemName: "star.fill").font(.system(size: 36))
                        .foregroundStyle(removed ? Color.gray.opacity(0.25) : Palette.sun)
                        .shadow(color: removed ? .clear : Palette.sunDeep.opacity(0.5), radius: 0, y: 2)
                    if removed {
                        Image(systemName: "xmark").font(.system(size: 23, weight: .bold)).foregroundStyle(Palette.ink.opacity(0.65))
                    } else {
                        HStack(spacing: 5) {
                            Circle().frame(width: 3, height: 4)
                            Circle().frame(width: 3, height: 4)
                        }.foregroundStyle(Palette.ink).offset(y: -1)
                        Text("⌣").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink).offset(y: 5)
                    }
                }.frame(width: 39, height: 42)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(crossedFrom == nil ? "\(count) stars" : "\(count) stars with \(count - (crossedFrom ?? count)) crossed out")
    }
}
