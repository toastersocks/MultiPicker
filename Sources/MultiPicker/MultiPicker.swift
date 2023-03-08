import SwiftUI


public struct MultiPicker<SelectionValue: Hashable, Content: View, LabelContent: View>: View {

    private var selection: SelectionBinding<SelectionValue>
    @ViewBuilder private var content: () -> Content
    private var label: LabelContent

    public var body: some View {
        NavigationLink {
            MultiPickerSelectionList<SelectionValue, Content>(selection: selection, content: content)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        label
                            .bold()
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

    private func text(forValue: SelectionBinding<SelectionValue>) -> String {
        switch selection {
        case .single(let bindee):
            return String(describing: bindee.wrappedValue)
        case .oneOrNone(let bindee):
            return "\(bindee.wrappedValue.map { "\($0)" } ?? "(None)")"
        case .multiple(let bindee):
            return bindee.wrappedValue.map(String.init(describing:)).formatted(.list(type: .and))
        }
    }

    public init(selection: Binding<SelectionValue?>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> LabelContent) {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = label()
    }

    // NOTE: `@_disfavoredOverload` is used here because there's a bug (I think) in Swift's method overload resolution that causes this less specific `Binding<SelectionValue>` init to be favored over the more specific `Binding<Set<SelectionValue>>` variant. This does not happen when the overloads are non-init (`func`) methods.
    @_disfavoredOverload
    public init(selection: Binding<SelectionValue>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> LabelContent) {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = label()
    }

    public init(selection: Binding<Set<SelectionValue>>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> LabelContent) {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = label()
    }

    // NOTE: `@_disfavoredOverload` is used here because there's a bug(?)(I can't find the Swift forum post to link to) where the `ExpressibleBy...` protocol variants are erroneously preferred by the compiler over the concrete types (`LocalizedStringKey` in this case)
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, selection: Binding<SelectionValue?>, @ViewBuilder content: @escaping () -> Content) where LabelContent == Text {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = Text(title)
    }

    // `@_disfavoredOverload` is used here because there's a bug(?)(I can't find the Swift forum post to link to) where the `ExpressibleBy...` protocol variants are erroneously preferred by the compiler over the concrete types (`LocalizedStringKey` in this case). Also using a dummy argument to **further** reduce the "favorability"/specificity of the method so that it has lower priority than both the `Binding<Set<SelectionValue>>` and `LocalizedStringKey` variants.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, _ noOp: Void = Void(), selection: Binding<SelectionValue>, @ViewBuilder content: @escaping () -> Content) where LabelContent == Text {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = Text(title)
    }

    // @_disfavoredOverload is used here because there's a bug(?)(I can't find the Swift forum post to link to) where the `ExpressibleBy...` protocol variants are erroneously preferred by the compiler over the concrete types (`LocalizedStringKey` in this case)
    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, selection: Binding<Set<SelectionValue>>, @ViewBuilder content: @escaping () -> Content) where LabelContent == Text {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = Text(title)
    }

    public init(_ titleKey: LocalizedStringKey, selection: Binding<SelectionValue?>, @ViewBuilder content: @escaping () -> Content) where LabelContent == Text {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = Text(titleKey)
    }

    // NOTE: Using a dummy parameter here to reduce the "specificity" of this init because there's a bug (I think) in Swift's method overload resolution that causes this less specific `Binding<SelectionValue>` init to be favored over the more specific `Binding<Set<SelectionValue>>` variant. This does not happen when the overloads are non-init (`func`) methods. Using a dummy argument instead of `@_disfavoredOverload` here because using `@_disfavoredOverload` causes the `init<S>(_ title:,selection:)` overload to be called instead.
    public init(_ titleKey: LocalizedStringKey, selection: Binding<SelectionValue>, noOp: Void = Void(), @ViewBuilder content: @escaping () -> Content) where LabelContent == Text {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = Text(titleKey)
    }

    public init(_ titleKey: LocalizedStringKey, selection: Binding<Set<SelectionValue>>, @ViewBuilder content: @escaping () -> Content) where LabelContent == Text {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = Text(titleKey)
    }
}

fileprivate enum SelectionBinding<SelectionValue: Hashable> {
    case single(Binding<SelectionValue>)
    case oneOrNone(Binding<SelectionValue?>)
    case multiple(Binding<Set<SelectionValue>>)

    func isSelected(_ bindee: SelectionValue) -> Bool {
        switch self {
        case let .single(binding):
            return bindee == binding.wrappedValue
        case let .oneOrNone(binding):
            return bindee == binding.wrappedValue
        case let .multiple(binding):
            return binding.wrappedValue.contains(bindee)
        }
    }

    func select(_ bindee: SelectionValue) {
        switch self {
        case let .single(binding):
            guard isSelected(bindee) == false else { return }

            binding.wrappedValue = bindee
        case let .oneOrNone(binding):
            binding.wrappedValue = isSelected(bindee) ? nil : bindee
        case let .multiple(binding):
            if isSelected(bindee) {
                binding.wrappedValue.remove(bindee)
            } else {
                binding.wrappedValue.insert(bindee)
            }
        }
    }
}


public struct MultiPickerSelectionList<SelectionValue: Hashable, Content: View>: View {
    private var selection: SelectionBinding<SelectionValue>
    @ViewBuilder private var content: Content
    @State private var selectionIndicatorPosition: SelectionIndicatorPosition

    public var body: some View {
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
                            .fontWeight(.semibold)
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

    public init(selection: Binding<SelectionValue?>, indicatorPosition: SelectionIndicatorPosition = .leading, @ViewBuilder content: () -> Content) {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    @_disfavoredOverload
    public init(selection: Binding<SelectionValue>, indicatorPosition: SelectionIndicatorPosition = .leading, @ViewBuilder content: () -> Content) {
        self.selection = SelectionBinding.single(selection)
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    public init(selection: Binding<Set<SelectionValue>>, indicatorPosition: SelectionIndicatorPosition = .leading, @ViewBuilder content: () -> Content) {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    fileprivate init(selection: SelectionBinding<SelectionValue>, indicatorPosition: SelectionIndicatorPosition = .leading, @ViewBuilder content: () -> Content) {
        self.selection = selection
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    public enum SelectionIndicatorPosition {
        case leading
        case trailing
    }
}

fileprivate struct Tag<V: Hashable>: _ViewTraitKey {
    static var defaultValue: V? { nil }
}


struct MultiPicker_Previews: PreviewProvider {

    static var previews: some View {
        multiPickerListPreview()

        multiPickerPreview()
    }

    static func multiPickerListPreview() -> some View {
        PreviewBindingHelper(choices: ["1", "2", "3"], value: (Set(arrayLiteral: "1"))) { (choices: [String], multiSelection: Binding<Set<String>>) in

            VStack {
                MultiPickerSelectionList(selection: multiSelection) {
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
                .pickerStyle(.navigationLink)
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
            }
        }
    }
}

