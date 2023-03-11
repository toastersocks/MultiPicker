import SwiftUI


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

    public init(selection: Binding<SelectionValue?>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = label()
    }

    // NOTE: `@_disfavoredOverload` is used here because there's a bug (I think) in Swift's method overload resolution that causes this less specific `Binding<SelectionValue>` init to be favored over the more specific `Binding<Set<SelectionValue>>` variant. This does not happen when the overloads are non-init (`func`) methods.
    @_disfavoredOverload
    public init(selection: Binding<SelectionValue>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = label()
    }

    public init(selection: Binding<Set<SelectionValue>>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = label()
    }

    // NOTE: `@_disfavoredOverload` is used here because there's a bug(?)(I can't find the Swift forum post to link to) where the `ExpressibleBy...` protocol variants are erroneously preferred by the compiler over the concrete types (`LocalizedStringKey` in this case)
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, selection: Binding<SelectionValue?>, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = Text(title)
    }

    // `@_disfavoredOverload` is used here because there's a bug(?)(I can't find the Swift forum post to link to) where the `ExpressibleBy...` protocol variants are erroneously preferred by the compiler over the concrete types (`LocalizedStringKey` in this case). Also using a dummy argument to **further** reduce the "favorability"/specificity of the method so that it has lower priority than both the `Binding<Set<SelectionValue>>` and `LocalizedStringKey` variants.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, _ noOp: Void = Void(), selection: Binding<SelectionValue>, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = Text(title)
    }

    // @_disfavoredOverload is used here because there's a bug(?)(I can't find the Swift forum post to link to) where the `ExpressibleBy...` protocol variants are erroneously preferred by the compiler over the concrete types (`LocalizedStringKey` in this case)
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, selection: Binding<Set<SelectionValue>>, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = Text(title)
    }

    public init(_ titleKey: LocalizedStringKey, selection: Binding<SelectionValue?>, @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = Text(titleKey)
    }

    // NOTE: Using a dummy parameter here to reduce the "specificity" of this init because there's a bug (I think) in Swift's method overload resolution that causes this less specific `Binding<SelectionValue>` init to be favored over the more specific `Binding<Set<SelectionValue>>` variant. This does not happen when the overloads are non-init (`func`) methods. Using a dummy argument instead of `@_disfavoredOverload` here because using `@_disfavoredOverload` causes the `init<S>(_ title:,selection:)` overload to be called instead.
    public init(_ titleKey: LocalizedStringKey, selection: Binding<SelectionValue>, noOp: Void = Void(), @ViewBuilder content: @escaping () -> Content) where Label == Text {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = Text(titleKey)
    }

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
//                    let _ = print(tag as Any)
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

fileprivate struct Tag<V: Hashable>: _ViewTraitKey {
    static var defaultValue: V? { nil }
}

fileprivate struct MultiPickerStyleEnvironmentKey: EnvironmentKey {
    static var defaultValue: MultiPickerStyle = .inline
}

extension EnvironmentValues {
    public var mpPickerStyle: MultiPickerStyle {
        get { self[MultiPickerStyleEnvironmentKey.self] }
        set { self[MultiPickerStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    public func mpPickerStyle(_ style: MultiPickerStyle) -> some View {
        environment(\.mpPickerStyle, style)
    }
}

fileprivate struct SelectionIndicatorPositionEnvironmentKey: EnvironmentKey {
    static var defaultValue: SelectionIndicatorPosition = .trailing
}

extension EnvironmentValues {
    public var selectionIndicatorPosition: SelectionIndicatorPosition {
        get { self[SelectionIndicatorPositionEnvironmentKey.self] }
        set { self[SelectionIndicatorPositionEnvironmentKey.self] = newValue }
    }
}

extension View {
    public func selectionIndicatorPosition(_ position: SelectionIndicatorPosition) -> some View {
        environment(\.selectionIndicatorPosition, position)
    }
}

public enum SelectionIndicatorPosition {
    case leading
    case trailing
}

public enum MultiPickerStyle {
    case navigationLink
    case inline
}

struct MultiPicker_Previews: PreviewProvider {

    static var previews: some View {
        multiPickerListPreview()

        multiPickerPreview()
    }

    static func multiPickerListPreview() -> some View {
        PreviewBindingHelper(choices: ["1", "2", "3"], value: (Set(arrayLiteral: "1"))) { (choices: [String], multiSelection: Binding<Set<String>>) in

            Form {
                MultiPicker("Regular", selection: multiSelection) {
                    ForEach(choices, id: \.self) {
                        Text("\($0)")
                            .mpTag($0)
                    }
                }
                MultiPickerSelectionList(selection: multiSelection, indicatorPosition: .trailing) {
                    ForEach(choices, id: \.self) {
                        Text("\($0)")
                            .mpTag($0)
                    }
                }
                MultiPickerSelectionList(selection: multiSelection) {
                    ForEach(choices, id: \.self) {
                        Text("\($0)")
                            .mpTag($0)
                    }
                }.environment(\.layoutDirection, .rightToLeft)
                MultiPickerSelectionList(selection: multiSelection, indicatorPosition: .trailing) {
                    ForEach(choices, id: \.self) {
                        Text("\($0)")
                            .mpTag($0)
                    }
                }.environment(\.layoutDirection, .rightToLeft)
            }
        }
    }

    static func multiPickerPreview() -> some View {
        PreviewBindingHelper3(choices: ["1", "2", "3"], values: ("1", Optional<String>("1"), Set(arrayLiteral: "1") as Set<String>)) { (choices: [String], oneSelection: Binding<String>, oneOrNoneSelection: Binding<String?>, multiSelection: Binding<Set<String>>) in
            Form {
                Section("SwiftUI") {
                    Picker("Only One", selection: oneSelection) {
                        ForEach(choices, id: \.self) {
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
                        ForEach(choices, id: \.self) {
                            Text("\($0)")
                                .mpTag($0)
                        }
                    }
                    MultiPicker("Multi", selection: multiSelection as Binding<Set<String>>) {
                        ForEach(choices, id: \.self) {
                            Text("\($0)")
                                .mpTag($0)
                        }
                    }
                    MultiPicker("One or None", selection: oneOrNoneSelection) {
                        ForEach(choices, id: \.self) {
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

