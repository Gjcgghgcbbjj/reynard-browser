import Foundation

public enum AddressBarContentKind: Equatable, Sendable {
    case placeholder
    case page
    case typedText
}

public enum AddressBarLeadingButtonState: Equatable, Sendable {
    case hidden
    case search
    case menu
    case loading
}

public enum AddressBarTrailingButtonState: Equatable, Sendable {
    case hidden
    case reload
    case stop
}

public struct AddressBarPresentationModel: Equatable, Sendable {
    public let content: AddressBarContentKind
    public let leadingButton: AddressBarLeadingButtonState
    public let trailingButton: AddressBarTrailingButtonState

    public init(
        content: AddressBarContentKind,
        leadingButton: AddressBarLeadingButtonState,
        trailingButton: AddressBarTrailingButtonState
    ) {
        self.content = content
        self.leadingButton = leadingButton
        self.trailingButton = trailingButton
    }
}

public enum AddressBarPresentationPolicy {
    public static func resolve(
        editing: Bool,
        hasTypedText: Bool,
        hasPageContent: Bool,
        isLoading: Bool,
        isPhoneBottomChrome: Bool,
        canShowMenu: Bool
    ) -> AddressBarPresentationModel {
        let content: AddressBarContentKind
        if editing {
            content = hasTypedText ? .typedText : .placeholder
        } else {
            content = hasPageContent ? .page : .placeholder
        }

        guard !editing else {
            return AddressBarPresentationModel(
                content: content,
                leadingButton: .hidden,
                trailingButton: .hidden
            )
        }

        let leadingButton: AddressBarLeadingButtonState
        if isLoading {
            leadingButton = .loading
        } else if content == .placeholder && isPhoneBottomChrome {
            leadingButton = .search
        } else if content == .page && canShowMenu {
            leadingButton = .menu
        } else {
            leadingButton = .hidden
        }

        let trailingButton: AddressBarTrailingButtonState
        if isLoading {
            trailingButton = .stop
        } else if content == .page {
            trailingButton = .reload
        } else {
            trailingButton = .hidden
        }

        return AddressBarPresentationModel(
            content: content,
            leadingButton: leadingButton,
            trailingButton: trailingButton
        )
    }
}
