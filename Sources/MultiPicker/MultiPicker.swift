import SwiftUI
import Helpers
import Flow

#if os(macOS)
#error("macOS not currently supported")
#endif

/// A picker for selecting from multiple options.
///
/// A MultiPicker can be initialized with several configurations, depending on what kind of binding is passed into the initializer. It can be configured to select between...
/// - one of any number of mutually-exclusive options by passing in a binding to a non-optional value. This matches the behavior of ``SwiftUI.Picker``.
/// - one or zero of any number of mutually-exclusive options by passing in a binding to an optional value.
/// - one, zero, or many of any number of options by passing in a binding to a set of option values.
public struct MultiPicker<Label: View, SelectionValue: Hashable, Content: View>: View {

    private var selection: SelectionBinding<SelectionValue>
    @ViewBuilder private var content: () -> Content
    private var label: Label
    private var noneText = String(localized: "(None)")
    @Environment(\.mpPickerStyle) private var pickerStyle
    @Environment(\.selectionIndicatorPosition) private var selectionIndicatorPosition
    @Environment(\.choiceRepresentationStyle) private var choiceRepresentationStyle

    public var body: some View {
        switch pickerStyle {
        case .inline:
            MultiPickerSelectionList<SelectionValue, Content>(selection: selection, indicatorPosition: selectionIndicatorPosition, content: content)
        case .navigationLink:
            NavigationLink {
                MultiPickerSelectionList<SelectionValue, Content>(selection: selection, indicatorPosition: selectionIndicatorPosition, content: content)
                    .toolbar {
                        #if os(watchOS)
                        let toolbarPlacement: ToolbarItemPlacement = .primaryAction
                        #else
                        let toolbarPlacement: ToolbarItemPlacement = .principal
                        #endif
                        ToolbarItem(placement: toolbarPlacement) {
                            label
                                .backport.bold()
                        }
                    }
            } label: {
                LabeledContent {
                    selectedOptions()
                        .accessibilityHidden(true)
                } label: {
                    label
                }
            }
            .accessibilityValue(Text(text(forValue: selection)))
        }
    }

    @ViewBuilder
    func richSelectionRepresentation() -> some View {
        if selection.isNone {
            Text(noneText)
        } else {
            Flow(alignment: .topTrailing) {
                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                    ForEach(subviews: content()) { child in
                        selectedChild(child, tag: child.containerValues.mpTag.flatMap { $0 as? SelectionValue })
                    }
                } else {
                    content().childViews { children in
                        ForEach(children) { child in
                            selectedChild(child, tag: child[MPTag.self].flatMap { $0 as? SelectionValue })
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func selectedChild(_ child: some View, tag: SelectionValue?) -> some View {
        if let tag, selection.isSelected(tag) {
            child
        }
    }

    @ViewBuilder
    func selectedOptions() -> some View {
        Group {
            switch choiceRepresentationStyle {
            case .plainText:
                Text(text(forValue: selection))
            case .rich:
                richSelectionRepresentation()
            case let .custom(viewProvider):
                if let representation = viewProvider() {
                    AnyView(representation)
                } else {
                    richSelectionRepresentation()
                }
            }
        }
    }

    private func text(forValue: SelectionBinding<SelectionValue>) -> String {
        switch selection {
        case .single(let binding):
            String(describing: binding.wrappedValue)
        case .oneOrNone(let binding):
            "\(binding.wrappedValue.map { "\($0)" } ?? "\(noneText)")"
        case .multiple(let binding):
            binding.wrappedValue.map { String(describing: $0) }.formatted(.list(type: .and))
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

fileprivate enum SelectionBinding<SelectionValue: Hashable>: Equatable {
    case single(Binding<SelectionValue>)
    case oneOrNone(Binding<SelectionValue?>)
    case multiple(Binding<Set<SelectionValue>>)

    var isNone: Bool {
        switch self {
        case .oneOrNone(let binding) where binding.wrappedValue == nil:
            true
        case .multiple(let binding) where binding.wrappedValue.isEmpty:
            true
        default:
            false
        }
    }

    func isSelected(_ bound: SelectionValue) -> Bool {
        switch self {
        case let .single(binding):
            bound == binding.wrappedValue
        case let .oneOrNone(binding):
            bound == binding.wrappedValue
        case let .multiple(binding):
            binding.wrappedValue.contains(bound)
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
            if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                ForEach(subviews: content) { child in
                    let tag = child.containerValues.mpTag.flatMap {
                        $0 as? SelectionValue
                    }
                    rowView(for: child, tag: tag)
                }
            } else {
                content.childViews { children in
                    ForEach(children) { child in
                        let tag = child[MPTag.self].flatMap {
                            $0 as? SelectionValue
                        }
                        rowView(for: child, tag: tag)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(for child: some View, tag: SelectionValue?) -> some View {
        let paddedChild = child.padding(.vertical, 4)
        HStack(spacing: 4) {
            if selectionIndicatorPosition == .trailing {
                paddedChild
                    .padding(.horizontal)
                Spacer()
            }
            checkmark(tag: tag)
            if selectionIndicatorPosition == .leading {
                paddedChild
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

    @ViewBuilder private func checkmark(tag: SelectionValue?) -> some View {
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

// MARK: - Previews
#if DEBUG
struct MultiPicker_Previews: PreviewProvider {

    static var previews: some View {
        multiPickerListPreview()
            .previewDisplayName("List Style")

        multiPickerNavigationLinkPreview()
            .previewDisplayName("Navigation Link Style Plain Style Choice")

        multiPickerNavigationLinkRichChoicePreview()
            .previewDisplayName("Navigation Link Style Rich Style Choice")

        multiPickerNavigationLinkCustomChoicePreview()
            .previewDisplayName("Navigation Link Style Custom Style Choice")
    }

    static func multiPickerListPreview() -> some View {
        PreviewBindingHelper2(values: (["1", "2", "3"], Set(arrayLiteral: "1"))) { (choices: Binding<[String]>, multiSelection: Binding<Set<String>>) in

            Form {
                Section {
                    MultiPicker("Regular", selection: multiSelection) {
                        ForEach(choices.wrappedValue, id: \.self) {
                            Text("\($0)")
                                .mpTag($0)
                        }
                    }
                }
                Section {
                    MultiPickerSelectionList(selection: multiSelection, indicatorPosition: .trailing) {
                        ForEach(choices.wrappedValue, id: \.self) {
                            Text("\($0)")
                                .mpTag($0)
                        }
                    }
                }
                Section {
                    MultiPickerSelectionList(selection: multiSelection) {
                        ForEach(choices.wrappedValue, id: \.self) {
                            Text("\($0)")
                                .mpTag($0)
                        }
                    }.environment(\.layoutDirection, .rightToLeft)
                }
                Section {
                    MultiPickerSelectionList(selection: multiSelection, indicatorPosition: .trailing) {
                        ForEach(choices.wrappedValue, id: \.self) {
                            Text("\($0)")
                                .mpTag($0)
                        }
                    }.environment(\.layoutDirection, .rightToLeft)
                }
            }
        }
    }

    static func multiPickerNavigationLinkPreview() -> some View {
        NavigationStack {
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

    static func multiPickerNavigationLinkRichChoicePreview() -> some View {
        NavigationStack {
            PreviewBindingHelper4(
                values: (
                    [
                        Model(title: String(localized: "Red"), color: .red),
                        Model(title: String(localized: "Orange"), color: .orange),
                        Model(title: String(localized: "Yellow"), color: .yellow),
                        Model(title: String(localized: "Green"), color: .green),
                        Model(title: String(localized: "Blue"), color: .blue),
                        Model(title: String(localized: "Indigo"), color: .indigo),
                        Model(title: String(localized: "Violet"), color: .purple),
                    ],
                    Model(title: String(localized: "Red"), color: .red),
                    Optional(Model(title: String(localized: "Red"), color: .red)),
                    Set(arrayLiteral: Model(title: String(localized: "Red"), color: .red)) as Set<Model>
                )
            ) { (choices: Binding<[Model]>,
                 oneSelection: Binding<Model>,
                 oneOrNoneSelection: Binding<Model?>,
                 multiSelection: Binding<Set<Model>>) in
                Form {
                    Section("SwiftUI") {
                        Picker("Only One", selection: oneSelection) {
                            ForEach(choices.wrappedValue, id: \.self) {
                                ModelCell(model: $0)
                                    .tag($0)
                            }
                        }
                    }
                    .pickerStyle(.navigationLink)
                    #if !os(macOS)
                    //                .pickerStyle(.navigationLink)
                    #endif
                    Section("MultiPicker") {
                        MultiPicker("Only One", selection: oneSelection) {
                            ForEach(choices.wrappedValue, id: \.self) {
                                ModelCell(model: $0)
                                    .mpTag($0)
                            }
                        }
                        MultiPicker("Multi", selection: multiSelection as Binding<Set<Model>>) {
                            ForEach(choices.wrappedValue, id: \.self) {
                                ModelCell(model: $0)
                                    .mpTag($0)
                            }
                        }
                        MultiPicker("One or None", selection: oneOrNoneSelection) {
                            ForEach(choices.wrappedValue, id: \.self) {
                                ModelCell(model: $0)
                                    .mpTag($0)
                            }
                        }
                    }
                    .mpPickerStyle(.navigationLink)
                    .choiceRepresentationStyle(.rich)
                }
            }
        }
    }

    static func multiPickerNavigationLinkCustomChoicePreview() -> some View {
        NavigationStack {
            PreviewBindingHelper4(
                values: (
                    [
                        Model(title: String(localized: "Red"), color: .red),
                        Model(title: String(localized: "Orange"), color: .orange),
                        Model(title: String(localized: "Yellow"), color: .yellow),
                        Model(title: String(localized: "Green"), color: .green),
                        Model(title: String(localized: "Blue"), color: .blue),
                        Model(title: String(localized: "Indigo"), color: .indigo),
                        Model(title: String(localized: "Violet"), color: .purple),
                    ],
                    Model(title: String(localized: "Red"), color: .red),
                    Optional(Model(title: String(localized: "Red"), color: .red)),
                    Set(arrayLiteral: Model(title: String(localized: "Red"), color: .red)) as Set<Model>
                )
            ) { (choices: Binding<[Model]>,
                 oneSelection: Binding<Model>,
                 oneOrNoneSelection: Binding<Model?>,
                 multiSelection: Binding<Set<Model>>) in
                Form {
                    Section("SwiftUI") {
                        Picker("Only One", selection: oneSelection) {
                            ForEach(choices.wrappedValue, id: \.self) {
                                ModelCell(model: $0)
                                    .tag($0)
                            }
                        }
                    }
                    .pickerStyle(.navigationLink)
#if !os(macOS)
                    //                .pickerStyle(.navigationLink)
#endif
                    Section("MultiPicker") {
                        MultiPicker("Only One", selection: oneSelection) {
                            ForEach(choices.wrappedValue, id: \.self) {
                                ModelCell(model: $0)
                                    .mpTag($0)
                            }
                        }
                        MultiPicker("Multi", selection: multiSelection as Binding<Set<Model>>) {
                            ForEach(choices.wrappedValue, id: \.self) {
                                ModelCell(model: $0)
                                    .mpTag($0)
                            }
                        }
                        .choiceRepresentationStyle(.custom {
                            switch multiSelection.wrappedValue.count {
                            case 0: Text("0️⃣")
                            case 1: nil // We can return `nil` to use the default rich representation.
                            case 2...4:
                                HStack {
                                    ForEach(Array(multiSelection.wrappedValue)) { model in
                                        switch model.title {
                                        case "Red": Text("🍓")
                                        case "Orange": Text("🍊")
                                        case "Yellow": Text("🍋")
                                        case "Green": Text("🍐")
                                        case "Blue": Text("💙")
                                        case "Indigo": Text("🪻")
                                        case "Violet": Text("🍇")
                                        default: EmptyView()
                                        }
                                    }
                                }
                            case 5...:
                                Text("🌈")
                            default: nil
                            }
                        })
                        MultiPicker("One or None", selection: oneOrNoneSelection) {
                            ForEach(choices.wrappedValue, id: \.self) {
                                ModelCell(model: $0)
                                    .mpTag($0)
                            }
                        }
                    }
                    .mpPickerStyle(.navigationLink)
                    .choiceRepresentationStyle(.rich)
                }
            }
        }
    }
}
#endif
