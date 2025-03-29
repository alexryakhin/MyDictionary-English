import SwiftUI

public struct SearchInputView: View {

    @Binding private var text: String
    @Binding private var state: InputState
    @Binding private var isFocused: Bool
    @FocusState private var focusState: Bool

    private let placeholder: String
    private let textContentType: NSTextContentType?
    private let onSubmit: (() -> Void)?

    public init(
        text: Binding<String>,
        state: Binding<InputState> = .constant(.pending),
        isFocused: Binding<Bool> = .constant(false),
        placeholder: String = "Search",
        textContentType: NSTextContentType? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self._state = state
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.textContentType = textContentType
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: 0) {

            HStack {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20.5, height: 18.5)
                    .foregroundColor(.secondaryLabelColor)

                TextField(text: $text, axis: .vertical) {
                    Text(placeholder)
                        .foregroundColor(.secondaryLabelColor)
                }
                .submitLabel(.search)
                .textContentType(textContentType)
                .focused($focusState, equals: true)
                .onSubmit {
                    onSubmit?()
                }
                .onChange(of: focusState) { newValue in
                    isFocused = focusState
                }

                if text.isNotEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "multiply.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.secondaryLabelColor)
                    }
                }
            }
            .frame(height: 36)
            .padding(.horizontal, 6)
            .backgroundMaterial(.regular)
            .clipShape(Capsule())

            if focusState {
                Button("Cancel") {
                    // cancel
                    focusState = false
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.default)
    }
}

#Preview {
    SearchInputView(text: .constant(.empty), placeholder: "Search something")
}
