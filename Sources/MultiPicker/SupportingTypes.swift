//
//  SupportingTypes.swift
//  
//
//  Created by James Pamplona on 3/12/23.
//

import SwiftUI


// MARK: - Public API
/// Represents the position of the selection indicator (usually a checkmark on iOS).
public enum SelectionIndicatorPosition {
    /// The selection indicator appears before the option view. This can be either the left or right depending on the current user's locale.
    case leading
    /// The selection indicator appears after the option view. This can be either the left or right depending on the current user's locale.
    case trailing
}

/// The style of the `MultiPicker`. Currently only navigation link style and inline list style are supported.
public enum MultiPickerStyle {
    /// The picker displays as a navigation link that pushes a list style picker view.
    case navigationLink
    /// The picker displays a list style picker view inline with other views.
    case inline
}

/// The display style of the chosen options. This only affects multi pickers with ``MultiPickerStyle/navigationLink`` style.
///
/// ``rich`` representation style might not look good depending on the complexity and/or size of the content views passed into multi picker. If you need to customize the ``plainText`` representation of your choices, conform your choice models to  ``CustomStringConvertible`` and return your text representation in the ``CustomStringConvertible.description`` property of the tags. If you need complete control over the representation of the set of selected choices, use ``custom(_:)`` to return a suitable view. Return `nil` to use the ``rich`` representation.
public enum ChoiceRepresentationStyle {
    /// The picker displays a plain text representation of the chosen choice(s). This is the default. To customize how the choices are represented, conform your type to `CustomStringConvertible`, and return the appropriate text representation from it's `description` property.
    case plainText
    
    /// The picker will display the view(s) of the selected choice(s).
    case rich
    
    /// Provides a custom representation for the selected choice(s).
    ///
    /// Use this style when you want complete control over how selections are displayed in the navigation link.
    /// The closure you provide should return either:
    /// - A view that will be used to represent the current selection state
    /// - Return `nil` to use the ``rich`` representation. This allows customization of only the specific cases needed, for instance the case where no options are selected could be customized, but all other cases could use the default ``rich`` representation.
    ///
    /// The closure is called whenever the selection changes, allowing you to provide different
    /// representations based on the current selection state.
    ///
    /// ## Example
    ///
    /// ```swift
    ///
    /// MultiPicker("Colors", selection: $selectedColors) {
    ///     // Picker content...
    /// }
    /// .choiceRepresentationStyle(.custom {
    ///     switch selectedColors.count {
    ///     case 0: Text("0️⃣")
    ///     case 1: nil // We can return `nil` to use the default rich representation.
    ///     case 2...4:
    ///         HStack {
    ///             ForEach(Array(selectedColors)) { color in
    ///                 switch color.title {
    ///                 case "Red": Text("🍓")
    ///                 case "Orange": Text("🍊")
    ///                 case "Yellow": Text("🍋")
    ///                 case "Green": Text("🍐")
    ///                 case "Blue": Text("💙")
    ///                 case "Indigo": Text("🪻")
    ///                 case "Violet": Text("🍇")
    ///                 default: EmptyView()
    ///                 }
    ///             }
    ///         }
    ///     case 5...:
    ///         Text("🌈")
    ///     default: nil
    ///     }
    /// })
    /// ```
    case custom(_ content: () -> (any View)?)
}

public extension View {
    /// Use this view modifier to tag the views representing the picker's options and associate them with the selection values they represent.
    /// - Parameter value: A `Hashable` value representing the option. Use this to associate a selection value with the view that represents it.
    /// - Returns: A view tagged with the supplied `value`
    func mpTag<Value: Hashable & Sendable>(_ value: Value) -> some View {
        _trait(MPTag.self, value)
    }
}

extension View {
    /// Sets the style of the ``MultiPicker``s chosen options in ``MultiPickerStyle/navigationLink`` style. This has no effect for ``MultiPickerStyle/inline`` style.
    /// - Parameter style: The desired style. ``ChoiceRepresentationStyle/plainText`` or ``ChoiceRepresentationStyle/rich``.
    /// - Returns: A view with the choice representation  style set.
    public func mpPickerStyle(_ style: MultiPickerStyle) -> some View {
        environment(\.mpPickerStyle, style)
    }
}

extension View {
    /// Sets the selection indicator position for the view.
    /// - Parameter position: Sets the selection indicator to be either leading or trailing.
    /// - Returns: A view with the selection indicator position set.
    public func selectionIndicatorPosition(_ position: SelectionIndicatorPosition) -> some View {
        environment(\.selectionIndicatorPosition, position)
    }
}

extension View {
    /// Sets the representation style for selections in ``MultiPicker`` controls.
    ///
    /// This modifier affects how selections are displayed in the navigation link label when using
    /// ``MultiPickerStyle/navigationLink`` style. It has no effect when using ``MultiPickerStyle/inline``.
    ///
    /// - Parameter style: The desired representation style:
    ///   - ``ChoiceRepresentationStyle/plainText``: Displays the text description of selected values
    ///   - ``ChoiceRepresentationStyle/rich``: Displays the actual views of selected values
    ///   - ``ChoiceRepresentationStyle/custom(_:)``: Provides complete control over selection representation
    ///
    /// - Returns: A view with the choice representation style set.
    ///
    /// ## Example
    ///
    /// ```swift
    /// Form {
    ///     // Basic plain text representation (default)
    ///     MultiPicker("Colors", selection: $selectedColors) { ... }
    ///         .mpPickerStyle(.navigationLink)
    ///
    ///     // Rich representation showing the actual selection views
    ///     MultiPicker("Colors", selection: $selectedColors) { ... }
    ///         .mpPickerStyle(.navigationLink)
    ///         .choiceRepresentationStyle(.rich)
    ///
    ///     // Custom representation
    ///     MultiPicker("Colors", selection: $selectedColors) { ... }
    ///         .mpPickerStyle(.navigationLink)
    /// .choiceRepresentationStyle(.custom {
    ///     switch selectedColors.count {
    ///     case 0: Text("0️⃣")
    ///     case 1: nil // We can return `nil` to use the default rich representation.
    ///     case 2...4:
    ///         HStack {
    ///             ForEach(Array(selectedColors)) { color in
    ///                 switch color.title {
    ///                 case "Red": Text("🍓")
    ///                 case "Orange": Text("🍊")
    ///                 case "Yellow": Text("🍋")
    ///                 case "Green": Text("🍐")
    ///                 case "Blue": Text("💙")
    ///                 case "Indigo": Text("🪻")
    ///                 case "Violet": Text("🍇")
    ///                 default: EmptyView()
    ///                 }
    ///             }
    ///         }
    ///     case 5...:
    ///         Text("🌈")
    ///     default: nil
    ///     }
    /// })
    /// ```
    public func choiceRepresentationStyle(_ style: ChoiceRepresentationStyle) -> some View {
        environment(\.choiceRepresentationStyle, style)
    }
}

// MARK: - Internal API
struct MPTag: _ViewTraitKey {
    static let defaultValue: (any Hashable & Sendable)? = Int?.none
}

extension EnvironmentValues {
    @Entry var mpPickerStyle: MultiPickerStyle = .inline
}

extension EnvironmentValues {
    @Entry var selectionIndicatorPosition: SelectionIndicatorPosition = .trailing
}

extension EnvironmentValues {
    @Entry var choiceRepresentationStyle: ChoiceRepresentationStyle = .plainText
}

extension Binding: @retroactive Equatable where Value: Equatable {
    public static func == (lhs: Binding<Value>, rhs: Binding<Value>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
