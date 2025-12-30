import SwiftUI

struct MomentsView: View {
    var body: some View {
        NavigationStack {
            Content()
                .navigationTitle("Moments")
        }
    }

    @ViewBuilder
    private func Content() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 48))
                .foregroundStyle(.pink)
            Text("Your moments will appear here.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MomentsView()
}
