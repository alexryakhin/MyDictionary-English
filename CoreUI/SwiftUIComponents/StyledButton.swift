//
//  StyledButton.swift
//  Suint One
//
//  Created by Aleksandr Riakhin on 9/30/24.
//

import SwiftUI

struct StyledButton<Label: View>: View {

    private let style: ButtonStyleConfig
    private let label: Label
    private let onTap: () -> Void
    private let overrideHorPadding: CGFloat?
    private let overrideVerPadding: CGFloat?
    private let isLoading: Bool

    init(
        style: ButtonStyleConfig,
        isLoading: Bool = false,
        overrideHorPadding: CGFloat? = nil,
        overrideVerPadding: CGFloat? = nil,
        onTap: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.style = style
        self.isLoading = isLoading
        self.overrideHorPadding = overrideHorPadding
        self.overrideVerPadding = overrideVerPadding
        self.onTap = onTap
        self.label = label()
    }

    init(
        text: String,
        style: ButtonStyleConfig,
        isLoading: Bool = false,
        overrideHorPadding: CGFloat? = nil,
        overrideVerPadding: CGFloat? = nil,
        onTap: @escaping () -> Void
    ) where Label == Text {
        self.init(
            style: style,
            isLoading: isLoading,
            overrideHorPadding: overrideHorPadding,
            overrideVerPadding: overrideVerPadding,
            onTap: onTap,
            label: {
                Text(text)
            }
        )
    }

    init(
        stretchedText: String,
        style: ButtonStyleConfig,
        isLoading: Bool = false,
        overrideHorPadding: CGFloat? = nil,
        overrideVerPadding: CGFloat? = nil,
        onTap: @escaping () -> Void
    ) where Label == HStack<TupleView<(Spacer, Text, Spacer)>> {
        self.init(
            style: style,
            isLoading: isLoading,
            overrideHorPadding: overrideHorPadding,
            overrideVerPadding: overrideVerPadding,
            onTap: onTap,
            label: {
                HStack {
                    Spacer()
                    Text(stretchedText)
                    Spacer()
                }
            }
        )
    }

    var body: some View {
        Button {
            self.onTap()
        } label: {
            self.label
        }
        .buttonStyle(
            BaseButtonStyle(
                buttonStyleConfig: style,
                overrideHorPadding: overrideHorPadding,
                overrideVerPadding: overrideVerPadding,
                isLoading: isLoading
            )
        )
    }
}

#Preview("Stretched") {
    StyledButton(
        style: .primary,
        isLoading: false,
        onTap: {}
    ) {
        Text("Button")
            .frame(maxWidth: .infinity)
    }
}

#Preview("Pending") {
    StyledButton(
        style: .primary,
        isLoading: false,
        onTap: {}
    ) {
        Text("Button")
    }
}

#Preview("Loading") {
    StyledButton(
        style: .primary,
        isLoading: true,
        onTap: {}
    ) {
        Text("Button")
    }
}

#Preview("Disabled") {
    StyledButton(
        style: .primary,
        isLoading: false,
        onTap: {}
    ) {
        Text("Button")
    }
    .disabled(true)
}

#Preview("Secondary") {
    StyledButton(
        style: .secondary,
        isLoading: false,
        onTap: {}
    ) {
        Text("Button")
    }
}

#Preview("Primary Dark") {
    StyledButton(
        style: .dark,
        isLoading: false,
        onTap: {}
    ) {
        Text("Button")
    }
}

#Preview("Text") {
    StyledButton(
        style: .text,
        isLoading: false,
        onTap: {}
    ) {
        Text("Button")
    }
}

#Preview("Text + Icons") {
    StyledButton(
        style: .text,
        isLoading: false,
        onTap: {}
    ) {
        HStack(spacing: 8) {
            Image(systemName: "house")
                .frame(width: 18, height: 18)
            Text("Button")
        }
    }
}

#Preview("Override colors") {
    StyledButton(
        style: .text,
        isLoading: false,
        onTap: {}
    ) {
        HStack(spacing: 8) {
            Image(systemName: "house")
                .frame(width: 18, height: 18)
                .foregroundColor(.red)
            Text("Button")
                .foregroundColor(.red)
        }
    }
}

#Preview("Convenience text") {
    StyledButton(
        text: "Text",
        style: .primary,
        isLoading: false,
        onTap: {}
    )
}

#Preview("Convenience stretchedText") {
    StyledButton(
        stretchedText: "Text stretched",
        style: .primary,
        isLoading: false,
        onTap: {}
    )
}
