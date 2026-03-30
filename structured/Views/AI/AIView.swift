import SwiftUI

struct AIView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(.systemGray4))
                Text("AI Planning")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Coming soon.")
                    .font(.subheadline)
                    .foregroundStyle(Color(.systemGray3))
                Spacer()
            }
            .navigationTitle("AI")
        }
    }
}
