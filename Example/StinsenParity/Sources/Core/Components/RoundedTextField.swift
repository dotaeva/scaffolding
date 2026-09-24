import SwiftUI

struct RoundedTextField: View {
    let placeholder: String
    let text: Binding<String>
    let secure: Bool

    init(_ placeholder: String, text: Binding<String>, secure: Bool = false) {
        self.placeholder = placeholder
        self.text = text
        self.secure = secure
    }

    var body: some View {
        Group {
            if secure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .textFieldStyle(.plain)
        .padding(14)
        // raisedBackground, not systemBackground: it is the one that stays
        // a step lighter than the grouped page in dark mode too, where
        // systemBackground is the same black and the field disappears.
        .background(Color.raisedBackground, in: .rect(cornerRadius: 10))
    }
}
