import Foundation
import Observation
import AVFoundation

enum LearningGameKind {
    case alphabet, numbers
    var title: String { self == .alphabet ? "Alphabet Adventure" : "Number Buddies" }
}

@MainActor
@Observable
final class LearningGameViewModel {
    struct Question {
        let prompt: String
        let display: String
        let answer: String
        let choices: [String]
        let explanation: String
        let groups: [Int]
        let operation: String?
    }
    let kind: LearningGameKind
    private(set) var questions: [Question] = []
    private(set) var index = 0
    private(set) var solved = false
    private(set) var done = false
    private(set) var credited = false
    private(set) var feedback = "Take your time. Let's learn together!"
    private(set) var tried: Set<String> = []
    private let speaker = AVSpeechSynthesizer()
    var question: Question { questions[index] }
    let reward = 20

    init(kind: LearningGameKind) {
        self.kind = kind
        newGame()
    }

    func newGame() {
        stopSpeaking()
        index = 0
        solved = false
        done = false
        credited = false
        tried = []
        feedback = "Take your time. Let's learn together!"
        if kind == .alphabet {
            let words = [
                "Apple", "Ball", "Cat", "Dog", "Egg", "Fish", "Goat", "Hat", "Igloo", "Jam", "Kite", "Lion", "Moon",
                "Nest", "Owl", "Pig", "Queen", "Rain", "Sun", "Tree", "Umbrella", "Van", "Web", "Xylophone", "Yo-yo", "Zebra"
            ]
            questions = words.shuffled().prefix(5).enumerated().map { offset, word in
                let letter = String(word.prefix(1))
                let lower = offset.isMultiple(of: 2)
                let answer = lower ? letter.lowercased() : letter
                let pool = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { lower ? String($0).lowercased() : String($0) }
                let choices = ([answer] + pool.filter { $0 != answer }.shuffled().prefix(2)).shuffled()
                return Question(
                    prompt: lower ? "Find the little letter that matches!" : "Which letter starts this word?",
                    display: lower ? letter : word, answer: answer, choices: choices,
                    explanation: lower ? "\(letter) and \(answer) are the same letter!" : "\(word) starts with \(letter)!",
                    groups: [], operation: nil
                )
            }
        } else {
            questions = (0..<5).map { offset in
                let a = Int.random(in: 1...5)
                let b = Int.random(in: 1...5)
                let counting = offset == 0 || offset == 3
                let subtract = offset == 2 || offset == 4
                let large = max(a, b), small = min(a, b)
                let result = counting ? a : (subtract ? large - small : a + b)
                let answer = String(result)
                let choices = ([answer] + (0...10).filter { $0 != result }.shuffled().prefix(2).map(String.init)).shuffled()
                return Question(
                    prompt: counting ? "How many pets are here? Tap each pet to count it."
                        : (subtract ? "The faded pets went for a nap. How many bright pets are left?" : "Put the pets together. How many pets altogether?"),
                    display: counting ? "Count the pets" : (subtract ? "\(large) − \(small) = ?" : "\(a) + \(b) = ?"),
                    answer: answer, choices: choices,
                    explanation: counting ? (a == 1 ? "There is 1 pet!" : "There are \(a) pets!")
                        : (subtract ? "\(large) take away \(small) is \(result)!" : "\(a) plus \(b) is \(result)!"),
                    groups: counting ? [a] : (subtract ? [large, small] : [a, b]), operation: counting ? nil : (subtract ? "−" : "+")
                )
            }
        }
        print("[LearningGame] started \(kind.title)")
    }

    func choose(_ answer: String) {
        guard !done, !solved, !tried.contains(answer) else { return }
        if answer == question.answer {
            solved = true
            feedback = "Wonderful! \(question.explanation)"
            Haptics.success()
            print("[LearningGame] \(kind.title) question \(index + 1) solved")
        } else {
            tried.insert(answer)
            feedback = "Good try! Try another answer. You've got this!"
            Haptics.tap()
        }
    }

    func next() {
        guard solved, !done else { return }
        stopSpeaking()
        if index == questions.count - 1 {
            done = true
            print("[LearningGame] completed \(kind.title), reward=\(reward)")
        } else {
            index += 1
            solved = false
            tried = []
            feedback = "Take your time. Let's learn together!"
        }
    }

    func claimReward() -> Int? {
        guard done, !credited else { return nil }
        credited = true
        return reward
    }

    func readAloud() {
        stopSpeaking()
        let text = solved ? feedback : "\(question.prompt) \(question.display). \(question.operation == nil && kind == .numbers ? "" : "Choices: " + question.choices.joined(separator: ", "))"
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        speaker.speak(utterance)
    }

    func stopSpeaking() { speaker.stopSpeaking(at: .immediate) }
}
