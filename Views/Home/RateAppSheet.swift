import StoreKit
import SwiftUI

/// Reviews and the external App Store link are only available after a fresh parent check.
struct RateAppSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var first = Int.random(in: 12...19)
    @State private var second = Int.random(in: 6...9)
    @State private var answer = ""
    @State private var approved = false
    @State private var incorrect = false
    @State private var requested = false

    var body: some View {
        NavigationStack {
            Form {
                if approved {
                    Section {
                        Label("Share your experience", systemImage: "star.bubble")
                            .font(.headline)
                        Text("Your honest feedback helps us improve Wacky Wardrobe. Rating is optional and never changes your coins or rewards.")
                        Button("Rate Wacky Wardrobe") {
                            requested = true
                            print("[Reviews] Parent requested Apple's review prompt")
                            requestReview()
                        }
                        .disabled(requested)
                        .accessibilityIdentifier("request-app-review")
                        if requested {
                            Text("Thank you! Apple decides whether to show the rating window. If it doesn't appear, you can write a review on the App Store below.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Link("Write a review on the App Store", destination: URL(string: "https://apps.apple.com/app/id6835691626?action=write-review")!)
                            .accessibilityIdentifier("write-app-store-review")
                    }
                } else {
                    Section {
                        Label("Please ask a grown-up", systemImage: "lock.shield")
                            .font(.headline)
                        Text("A grown-up needs to complete this check before rating the app or opening the App Store.")
                        Text("What is \(first) + \(second)?")
                            .accessibilityIdentifier("review-parent-question")
                        TextField("Answer", text: $answer)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("review-parent-answer")
                        if incorrect {
                            Text("That's not quite right. Please ask a grown-up for help.")
                                .foregroundStyle(.red)
                        }
                        Button("Continue") {
                            if Int(answer.trimmingCharacters(in: .whitespacesAndNewlines)) == first + second {
                                approved = true
                                incorrect = false
                                print("[Reviews] Parent check completed")
                            } else {
                                incorrect = true
                                answer = ""
                            }
                        }
                        .accessibilityIdentifier("review-parent-continue")
                    }
                }
            }
            .font(.system(.body, design: .rounded))
            .navigationTitle("For Grown-ups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("close-app-review")
                }
            }
        }
    }
}
