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
/// ``rich`` representation style might not look good depending on the complexity and/or size of the content views passed into multi picker. ``plainText`` style uses the `CustomStringConvertible.description` property of the tags to display the choice(s).
public enum ChoiceRepresentationStyle {
    /// The picker displays a text representation of the chosen choice(s). This is the default. The `CustomStringConvertible` representation of the options' tag is used.
    case plainText
    /// The picker will display the view(s) of the selected choice(s).
    case rich
}


public extension View {
    /// Use this view modifier to tag the views representing the picker's options and associate them with the selection values they represent.
    /// - Parameter value: A `Hashable` value representing the option. Use this to associate a selection value with the view that represents it.
    /// - Returns: A view tagged with the supplied `value`
    func mpTag<Value: Hashable>(_ value: Value) -> some View {
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
    /// Sets the style of ``MultiPicker``s in the view.
    /// - Parameter style: The desired style. Currently only inline and navigationLink are supported.
    /// - Returns: A view with the multi picker style set.
    public func choiceRepresentationStyle(_ style: ChoiceRepresentationStyle) -> some View {
        environment(\.choiceRepresentationStyle, style)
    }
}

// MARK: - Internal API
struct MPTag: _ViewTraitKey {
    static var defaultValue: AnyHashable? = Int?.none
}

struct MultiPickerStyleEnvironmentKey: EnvironmentKey {
    static var defaultValue: MultiPickerStyle = .inline
}

extension EnvironmentValues {
    var mpPickerStyle: MultiPickerStyle {
        get { self[MultiPickerStyleEnvironmentKey.self] }
        set { self[MultiPickerStyleEnvironmentKey.self] = newValue }
    }
}

struct SelectionIndicatorPositionEnvironmentKey: EnvironmentKey {
    static var defaultValue: SelectionIndicatorPosition = .trailing
}

extension EnvironmentValues {
    var selectionIndicatorPosition: SelectionIndicatorPosition {
        get { self[SelectionIndicatorPositionEnvironmentKey.self] }
        set { self[SelectionIndicatorPositionEnvironmentKey.self] = newValue }
    }
}

struct ChoiceRepresentationStyleEnvironmentKey: EnvironmentKey {
    static var defaultValue: ChoiceRepresentationStyle = .plainText
}

extension EnvironmentValues {
    var choiceRepresentationStyle: ChoiceRepresentationStyle {
        get { self[ChoiceRepresentationStyleEnvironmentKey.self] }
        set { self[ChoiceRepresentationStyleEnvironmentKey.self] = newValue }
    }
}

extension Binding: Equatable where Value: Equatable {
    public static func == (lhs: Binding<Value>, rhs: Binding<Value>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
