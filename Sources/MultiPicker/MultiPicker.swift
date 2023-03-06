import SwiftUI


public struct MultiPicker<Bindee: Hashable, Content: View, LabelContent: View>: View {

    private var selection: SelectionBinding<Bindee>
    @ViewBuilder private var content: () -> Content
    private var label: LabelContent
    @State private var value: String = ""

    public var body: some View {
        NavigationLink {
            MultiPickerSelectionList<Bindee, Content>(selection: selection, content: content)
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

    private func text(forValue: SelectionBinding<Bindee>) -> String {
        switch selection {
        case .single(let bindee):
            return String(describing: bindee.wrappedValue)
        case .oneOrNone(let bindee):
            return "\(bindee.wrappedValue.map { "\($0)" } ?? "(None)")"
        case .multiple(let bindee):
            return bindee.wrappedValue.map(String.init(describing:)).formatted(.list(type: .and))
        }
    }

    public init(selection: Binding<Bindee?>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> LabelContent) {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = label()
    }

    @_disfavoredOverload
    public init(selection: Binding<Bindee>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> LabelContent) {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = label()
    }

    public init(selection: Binding<Set<Bindee>>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> LabelContent) {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = label()
    }

    public init<S: StringProtocol>(_ title: S, selection: Binding<Bindee?>, @ViewBuilder content: @escaping () -> Content) where LabelContent == Text {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content
        self.label = Text(title)
    }

    @_disfavoredOverload
    public init<S: StringProtocol>(_ title: S, selection: Binding<Bindee>, @ViewBuilder content: @escaping () -> Content) where LabelContent == Text {
        self.selection = SelectionBinding.single(selection)
        self.content = content
        self.label = Text(title)
    }

    public init<S: StringProtocol>(_ title: S, selection: Binding<Set<Bindee>>, @ViewBuilder content: @escaping () -> Content) where LabelContent == Text {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content
        self.label = Text(title)
    }
}

fileprivate enum SelectionBinding<Bindee: Hashable> {
    case single(Binding<Bindee>)
    case oneOrNone(Binding<Bindee?>)
    case multiple(Binding<Set<Bindee>>)

    func isSelected(_ bindee: Bindee) -> Bool {
        switch self {
        case let .single(binding):
            return bindee == binding.wrappedValue
        case let .oneOrNone(binding):
            return bindee == binding.wrappedValue
        case let .multiple(binding):
            return binding.wrappedValue.contains(bindee)
        }
    }

    func select(_ bindee: Bindee) {
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


public struct MultiPickerSelectionList<Bindee: Hashable, Content: View>: View {
    private var selection: SelectionBinding<Bindee>
    @ViewBuilder private var content: Content
    @State private var selectionIndicatorPosition: SelectionIndicatorPosition

    public var body: some View {
        List {
            content.childViews { children in
                ForEach(children) { child in
                    let tag = child[MPTag.self].flatMap {
                        $0 as? Bindee
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

    public init(selection: Binding<Bindee?>, indicatorPosition: SelectionIndicatorPosition = .leading, @ViewBuilder content: () -> Content) {
        self.selection = SelectionBinding.oneOrNone(selection)
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    @_disfavoredOverload
    public init(selection: Binding<Bindee>, indicatorPosition: SelectionIndicatorPosition = .leading, @ViewBuilder content: () -> Content) {
        self.selection = SelectionBinding.single(selection)
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    public init(selection: Binding<Set<Bindee>>, indicatorPosition: SelectionIndicatorPosition = .leading, @ViewBuilder content: () -> Content) {
        self.selection = SelectionBinding.multiple(selection)
        self.content = content()
        self._selectionIndicatorPosition = State(initialValue: indicatorPosition)
    }

    fileprivate init(selection: SelectionBinding<Bindee>, indicatorPosition: SelectionIndicatorPosition = .leading, @ViewBuilder content: () -> Content) {
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
    struct TestView: View {
        @State var oneSelection: String = "1"
        @State var multiSelection: Set<String> = ["1"]
        @State var oneOrNoneSelection: String? = "1"
        var choices = [
            "0",
            "1",
            "2",
            "3",
        ]

        var body: some View {
            NavigationStack {
                    VStack {
                        MultiPickerSelectionList(selection: $multiSelection) {
                            ForEach(choices, id: \.self) {
                                Text("\($0)")
                                    .mpTag($0)
                            }
                        }
                        MultiPickerSelectionList(selection: $multiSelection, indicatorPosition: .trailing) {
                            ForEach(choices, id: \.self) {
                                Text("\($0)")
                                    .mpTag($0)
                            }
                        }
                        MultiPickerSelectionList(selection: $multiSelection) {
                            ForEach(choices, id: \.self) {
                                Text("\($0)")
                                    .mpTag($0)
                            }
                        }.environment(\.layoutDirection, .rightToLeft)
                        MultiPickerSelectionList(selection: $multiSelection, indicatorPosition: .trailing) {
                            ForEach(choices, id: \.self) {
                                Text("\($0)")
                                    .mpTag($0)
                            }
                        }.environment(\.layoutDirection, .rightToLeft)
                    Form {
                        Section("SwiftUI") {
                            Picker("Only One", selection: $oneSelection) {
                                ForEach(choices, id: \.self) {
                                    Text("\($0)")
                                        .tag($0)
                                }
                            }
                            Picker("Multi", selection: $multiSelection) {
                                ForEach(choices, id: \.self) {
                                    Text("\($0)")
                                        .tag($0)
                                }
                            }
                            Picker("One or None", selection: $oneOrNoneSelection) {
                                ForEach(choices, id: \.self) {
                                    Text("\($0)")
                                        .tag($0)
                                }
                            }
                        }
                        .pickerStyle(.navigationLink)
                        Section("MultiPicker") {
                            MultiPicker("Only One", selection: $oneSelection) {
                                ForEach(choices, id: \.self) {
                                    Text("\($0)")
                                        .mpTag($0)
                                }
                            }
                            MultiPicker("Multi", selection: $multiSelection) {
                                ForEach(choices, id: \.self) {
                                    Text("\($0)")
                                        .mpTag($0)
                                }
                            }
                            MultiPicker("One or None", selection: $oneOrNoneSelection) {
                                ForEach(choices, id: \.self) {
                                    Text("\($0)")
                                        .mpTag($0)
                                }
                            }
                        }
                    }
                    Text("\(multiSelection.sorted().formatted(.list(type: .and)))")
                }
            }
        }
    }
    static var previews: some View {
        TestView()
    }
}
