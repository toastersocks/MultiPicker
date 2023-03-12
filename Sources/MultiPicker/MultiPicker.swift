import SwiftUI
import Helpers


/// A picker for selecting from multiple options.
///
/// A MultiPicker can be initialized with several configurations, depending on what kind of binding is passed into the initializer. It can be configured to select between...
/// - one of any number of mutually-exclusive options by passing in a binding to a non-optional value.
/// - one or zero of any number of mutually-exclusive options by passing in a binding to an optional value.
/// - one, zero, or many of any number of options by passing in a binding to a set of option values.
public struct MultiPicker<Label: View, SelectionValue: Hashable & CustomStringConvertible, Content: View>: View {

    private var selection: SelectionBinding<SelectionValue>
    @ViewBuilder private var content: () -> Content
    private var label: Label
    @Environment(\.mpPickerStyle) var pickerStyle
    @Environment(\.selectionIndicatorPosition) var selectionIndicatorPosition

    public var body: some View {
        switch pickerStyle {
        case .inline:
            MultiPickerSelectionList<SelectionValue, Content>(selection: selection, indicatorPosition: selectionIndicatorPosition, content: content)
        case .navigationLink:
            NavigationLink {
                MultiPickerSelectionList<SelectionValue, Content>(selection: selection, indicatorPosition: selectionIndicatorPosition, content: content)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            label
                                .backport.bold()
                        }
                    }
            } label: {
                HStack {
                    label
                    Spacer()
                    Text(text(forValue: selection))
                        .accessibilityHidden(true)
                        .foregroundColor(.secondary)
                }
                .accessibilityValue(Text(text(forValue: selection)))
            }
        }
    }

    private func text(forValue: SelectionBinding<SelectionValue>) -> String {
        switch selection {
        case .single(let binding):
            return String(describing: binding.wrappedValue)
        case .oneOrNone(let binding):
            return "\(binding.wrappedValue.map { "\($0)" } ?? "(None)")"
        case .multiple(let binding):
            return binding.wrappedValue.map(String.init(describing:)).formatted(.list(type: .and))
        }
    }

    // NOTE: `@_disfavoredOverload` is used here because there's a bug (I think) in Swift's method overload resolution that causes this less specific `Binding<SelectionValue>` init to be favored over the more specific `Binding<Set<SelectionValue>>` variant. This does not happen when the overloads are non-init (`func`) methods.
    /// Creates a `MultiPicker` with a custom label for a single, mutually exclusive value.
    /// - Parameters:
    ///   - selection: A binding to a property that determines the currently selected option.
    ///   - content: Views representing the picker's options. Tag each view with the ``mpTag(_:)`` modifier passing in a unique hashable value that identifies that option.
    ///   - label: A view describing the option.
    @_disfavoredOverload
    public init(selection: Binding<SelectionValue>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = label()
    }

    /// Creates a `MultiPicker` with a custom label for a single, mutually exclusive, optional value.
    /// - Parameters:
    ///   - selection: A binding to a property that determines the currently selected option. No value is selected if the selection value is `nil`.
    ///   - content: Views representing the picker's options. Tag each view with the ``mpTag(_:)`` modifier passing in a unique hashable value that identifies that option.
    ///   - label: A view describing the option.
    public init(selection: Binding<SelectionValue?>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = label()
    }

    /// Creates a `MultiPicker` with a custom label for multiple, mutually inclusive options. One, multiple or zero options can be selected at once.
    /// - Parameters:
    ///   - selection: A binding to a property that determines the currently selected option(s).
    ///   - content: Views representing the picker's options. Tag each view with the ``mpTag(_:)`` modifier passing in a unique hashable value that identifies that option.
    ///   - label: A view describing the option.
    public init(selection: Binding<Set<SelectionValue>>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = label()
    }

    // NOTE: `@_disfavoredOverload` is used here because there's a bug(?)(I can't find the Swift forum post to link to) where the `ExpressibleBy...` protocol variants are erroneously preferred by the compiler over the concrete types (`LocalizedStringKey` in this case). Also using a dummy argument to **further** reduce the "favorability"/specificity of the method so that it has lower priority than both the `Binding<Set<SelectionValue>>` and `LocalizedStringKey` variants.
    /// Creates a `MultiPicker` for a single, mutually exclusive value. The picker's label is created from a string.
    /// >  Note: The `Void` `noOP` parameter is a dummy parameter that ensures the proper overloaded initializer is called. Do not use or include this parameter when calling this initializer. It does nothing.
    /// - Parameters:
    ///   - title: A string describing the picker's purpose.
    ///   - selection: A binding to a property that determines the currently selected option.
    ///   - content: Views representing the picker's options. Tag each view with the ``mpTag(_:)`` modifier passing in a unique hashable value that identifies that option.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, _ noOp: Void = Void(), selection: Binding<SelectionValue>, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = Text(title)
    }

    // NOTE: `@_disfavoredOverload` is used here because there's a bug(?)(I can't find the Swift forum post to link to) where the `ExpressibleBy...` protocol variants are erroneously preferred by the compiler over the concrete types (`LocalizedStringKey` in this case)
    /// Creates a `MultiPicker` for a single, mutually exclusive optional value. The picker's label is created from a string.
    /// - Parameters:
    ///   - title: A string describing the picker's purpose.
    ///   - selection: A binding to a property that determines the currently selected option. No value is selected if the selection value is `nil`.
    ///   - content: Views representing the picker's options. Tag each view with the ``mpTag(_:)`` modifier passing in a unique hashable value that identifies that option.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, selection: Binding<SelectionValue?>, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = Text(title)
    }

    // @_disfavoredOverload is used here because there's a bug(?)(I can't find the Swift forum post to link to) where the `ExpressibleBy...` protocol variants are erroneously preferred by the compiler over the concrete types (`LocalizedStringKey` in this case)
    /// Creates a `MultiPicker` for multiple, mutually inclusive options. One, multiple or zero options can be selected at once. The picker's label is created from a string.
    /// - Parameters:
    ///   - title: A string describing the picker's purpose.
    ///   - selection: A binding to a property that determines the currently selected option(s).
    ///   - content: Views representing the picker's options. Tag each view with the ``mpTag(_:)`` modifier passing in a unique hashable value that identifies that option.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, selection: Binding<Set<SelectionValue>>, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = Text(title)
    }

    // NOTE: Using a dummy parameter here to reduce the "specificity" of this init because there's a bug (I think) in Swift's method overload resolution that causes this less specific `Binding<SelectionValue>` init to be favored over the more specific `Binding<Set<SelectionValue>>` variant. This does not happen when the overloads are non-init (`func`) methods. Using a dummy argument instead of `@_disfavoredOverload` here because using `@_disfavoredOverload` causes the `init<S>(_ title:,selection:)` overload to be called instead.
    /// Creates a `MultiPicker` for a single, mutually exclusive value. The picker's label is created from a string.
    /// >  Note: The `Void` `noOP` parameter is a dummy parameter that ensures the proper overloaded initializer is called. Do not use or include this parameter when calling this initializer. It does nothing.
    /// - Parameters:
    ///   - titleKey: A localized string key describing the picker's purpose.
    ///   - selection: A binding to a property that determines the currently selected option.
    ///   - content: Views representing the picker's options. Tag each view with the ``mpTag(_:)`` modifier passing in a unique hashable value that identifies that option.
    public init(_ titleKey: LocalizedStringKey, selection: Binding<SelectionValue>, noOp: Void = Void(), @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = Text(titleKey)
    }

    /// Creates a `MultiPicker` for a single, mutually exclusive optional value. The picker's label is created from a string.
    /// - Parameters:
    ///   - titleKey: A localized string key describing the picker's purpose.
    ///   - selection: A binding to a property that determines the currently selected option. No value is selected if the selection value is `nil`.
    ///   - content: Views representing the picker's options. Tag each view with the ``mpTag(_:)`` modifier passing in a unique hashable value that identifies that option.
    public init(_ titleKey: LocalizedStringKey, selection: Binding<SelectionValue?>, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = Text(titleKey)
    }

    /// Creates a `MultiPicker` for multiple, mutually inclusive options. One, multiple or zero options can be selected at once. The picker's label is created from a string.
    /// - Parameters:
    ///   - titleKey: A localized string key describing the picker's purpose.
    ///   - selection: A binding to a property that determines the currently selected option(s).
    ///   - content: Views representing the picker's options. Tag each view with the ``mpTag(_:)`` modifier passing in a unique hashable value that identifies that option.
    public init(_ titleKey: LocalizedStringKey, selection: Binding<Set<SelectionValue>>, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = Text(titleKey)
    }
}

fileprivate enum SelectionBinding<SelectionValue: Hashable> {
    case single(Binding<SelectionValue>)
    case oneOrNone(Binding<SelectionValue?>)
    case multiple(Binding<Set<SelectionValue>>)

    func isSelected(_ bound: SelectionValue) -> Bool {
        switch self {
        case let .single(binding):
            return bound == binding.wrappedValue
        case let .oneOrNone(binding):
            return bound == binding.wrappedValue
        case let .multiple(binding):
            return binding.wrappedValue.contains(bound)
        }
    }

    func select(_ bound: SelectionValue) {
        switch self {
        case let .single(binding):
            guard isSelected(bound) == false else { return }

            binding.wrappedValue = bound
        case let .oneOrNone(binding):
            binding.wrappedValue = isSelected(bound) ? nil : bound
        case let .multiple(binding):
            if isSelected(bound) {
                binding.wrappedValue.remove(bound)
            } else {
                binding.wrappedValue.insert(bound)
            }
        }
    }
}


/// This is used internally for the option picker view.
fileprivate struct MultiPickerSelectionList<SelectionValue: Hashable, Content: View>: View {
    private var selection: SelectionBinding<SelectionValue>
    @ViewBuilder private var content: Content
    @State private var selectionIndicatorPosition: SelectionIndicatorPosition

    var body: some View {
        List {
            content.childViews { children in
                ForEach(children) { child in
                    let tag = child[MPTag.self].flatMap {
                        $0 as? SelectionValue
                    }
                    HStack(spacing: 4) {
                        if selectionIndicatorPosition == .trailing {
                            child
                                .padding(.horizontal)
                            Spacer()
                        }
                        Image(systemName: "checkmark")
                            .resizable()
                            .fixedSize()
                            .font(.body)
                            .backport.fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .foregroundColor(.accentColor)
                            .opacity(tag.map { selection.isSelected($0) ? 1 : 0 } ?? 0)
                            .accessibility(hidden: true)
                            .padding(.trailing, selectionIndicatorPosition == .trailing ? nil : 0)
                        if selectionIndicatorPosition == .leading {
                            child
                            Spacer()
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
                    .contentShape(Rectangle())
                    .accessibilityAddTraits(.isButton)
                    .accessibilityValue(
                        tag.map {
                            Text(selection.isSelected($0) ? "Selected" : "")
                        } ?? Text("")
                    )
                    .onTapGesture {
                        tag.map { selection.select($0) }
                    }
                }
            }
        }
    }

    fileprivate init(selection: Binding<SelectionValue?>, indicatorPosition: SelectionIndicatorPosition = .trailing, @ViewBuilder content: () -> Content) {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    @_disfavoredOverload
    fileprivate init(selection: Binding<SelectionValue>, indicatorPosition: SelectionIndicatorPosition = .trailing, @ViewBuilder content: () -> Content) {
        self.selection = SelectionBinding.single(selection)
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    fileprivate init(selection: Binding<Set<SelectionValue>>, indicatorPosition: SelectionIndicatorPosition = .trailing, @ViewBuilder content: () -> Content) {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    fileprivate init(selection: SelectionBinding<SelectionValue>, indicatorPosition: SelectionIndicatorPosition = .trailing, @ViewBuilder content: () -> Content) {
        self.selection = selection
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }
}

struct Tag<V: Hashable>: _ViewTraitKey {
    static var defaultValue: V? { nil }
}

struct MultiPickerStyleEnvironmentKey: EnvironmentKey {
    static var defaultValue: MultiPickerStyle = .inline
}

extension EnvironmentValues {
    public var mpPickerStyle: MultiPickerStyle {
        get { self[MultiPickerStyleEnvironmentKey.self] }
        set { self[MultiPickerStyleEnvironmentKey.self] = newValue }
    }
}

extension View {

    /// Sets the style of ``MultiPicker``s in the view.
    /// - Parameter style: The desired style. Currently only inline and navigationLink are supported.
    /// - Returns: A view with the multi picker style set.
    public func mpPickerStyle(_ style: MultiPickerStyle) -> some View {
        environment(\.mpPickerStyle, style)
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

extension View {

    /// Sets the selection indicator position for the view.
    /// - Parameter position: Sets the selection indicator to be either leading or trailing.
    /// - Returns: A view with the selection indicator position set.
    public func selectionIndicatorPosition(_ position: SelectionIndicatorPosition) -> some View {
        environment(\.selectionIndicatorPosition, position)
    }
}


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

struct MPTag: _ViewTraitKey {
    static public var defaultValue: AnyHashable? = Int?.none
}

public extension View {
    /// Use this view modifier to tag the views representing the picker's options and associate them with the selection values they represent.
    /// - Parameter value: A `Hashable` value representing the option. Use this to associate a selection value with the view that represents it.
    /// - Returns: A view tagged with the supplied `value`
    func mpTag<Value: Hashable>(_ value: Value) -> some View {
        _trait(MPTag.self, value)
    }
}


struct MultiPicker_Previews: PreviewProvider {

    static var previews: some View {
        multiPickerListPreview()

        multiPickerPreview()
    }

    static func multiPickerListPreview() -> some View {
        PreviewBindingHelper2(values: (["1", "2", "3"], Set(arrayLiteral: "1"))) { (choices: Binding<[String]>, multiSelection: Binding<Set<String>>) in

            Form {
                MultiPicker("Regular", selection: multiSelection) {
                    ForEach(choices.wrappedValue, id: \.self) {
                        Text("\($0)")
                            .mpTag($0)
                    }
                }
                MultiPickerSelectionList(selection: multiSelection, indicatorPosition: .trailing) {
                    ForEach(choices.wrappedValue, id: \.self) {
                        Text("\($0)")
                            .mpTag($0)
                    }
                }
                MultiPickerSelectionList(selection: multiSelection) {
                    ForEach(choices.wrappedValue, id: \.self) {
                        Text("\($0)")
                            .mpTag($0)
                    }
                }.environment(\.layoutDirection, .rightToLeft)
                MultiPickerSelectionList(selection: multiSelection, indicatorPosition: .trailing) {
                    ForEach(choices.wrappedValue, id: \.self) {
                        Text("\($0)")
                            .mpTag($0)
                    }
                }.environment(\.layoutDirection, .rightToLeft)
            }
        }
    }

    static func multiPickerPreview() -> some View {
        PreviewBindingHelper4(values: (["1", "2", "3"], "1", Optional<String>("1"), Set(arrayLiteral: "1") as Set<String>)) { (choices: Binding<[String]>, oneSelection: Binding<String>, oneOrNoneSelection: Binding<String?>, multiSelection: Binding<Set<String>>) in
            Form {
                Section("SwiftUI") {
                    Picker("Only One", selection: oneSelection) {
                        ForEach(choices.wrappedValue, id: \.self) {
                            Text("\($0)")
                                .tag($0)
                        }
                    }
                }
                #if !os(macOS)
//                .pickerStyle(.navigationLink)
                #endif
                Section("MultiPicker") {
                    MultiPicker("Only One", selection: oneSelection) {
                        ForEach(choices.wrappedValue, id: \.self) {
                            Text("\($0)")
                                .mpTag($0)
                        }
                    }
                    MultiPicker("Multi", selection: multiSelection as Binding<Set<String>>) {
                        ForEach(choices.wrappedValue, id: \.self) {
                            Text("\($0)")
                                .mpTag($0)
                        }
                    }
                    MultiPicker("One or None", selection: oneOrNoneSelection) {
                        ForEach(choices.wrappedValue, id: \.self) {
                            Text("\($0)")
                                .mpTag($0)
                        }
                    }
                }
                .mpPickerStyle(.navigationLink)
            }
        }
    }
}
