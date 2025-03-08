import SwiftUI

public struct SearchInputView: View {

    @Binding private var text: String
    @Binding private var state: InputState
    @Binding private var isFocused: Bool
    @FocusState private var focusState: Bool

    private let placeholder: String
    private let keyboardType: UIKeyboardType
    private let textContentType: UITextContentType?
    private let onSubmit: (() -> Void)?

    public init(
        text: Binding<String>,
        state: Binding<InputState> = .constant(.pending),
        isFocused: Binding<Bool> = .constant(false),
        placeholder: String = "Search",
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self._state = state
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.keyboardType = keyboardType
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
                    .foregroundColor(.secondaryLabel)

                TextField(text: $text) {
                    Text(placeholder)
                        .foregroundColor(.secondaryLabel)
                }
                .submitLabel(.search)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
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
                            .foregroundColor(.secondaryLabel)
                    }
                }
            }
            .frame(height: 36)
            .padding(.horizontal, 6)
            .backgroundColor(.tertiarySystemFill)
            .clipShape(Capsule())

            if focusState {
                StyledButton(text: "Cancel", style: .textMini) {
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
