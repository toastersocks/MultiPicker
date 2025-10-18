import Testing
import SwiftUI
@testable import MultiPicker

final class UncheckedSendable<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}

@Suite("SelectionBinding Tests")
struct MultiPickerTests {

    @Test("Single selection select")
    func singleSelectionSelect() {
        let value = UncheckedSendable("option1")
        let binding = Binding<String>(get: { value.value }, set: { value.value = $0 })
        let selection = SelectionBinding.single(binding)

        selection.select("option2")
        #expect(value.value == "option2")
    }

    @Test("Optional selection isNone")
    func optionalSelectionIsNone() {
        let bindingWithValue = Binding<String?>(get: { "option1" }, set: { _ in })
        let selectionWithValue = SelectionBinding.oneOrNone(bindingWithValue)
        #expect(!selectionWithValue.isNone)

        let bindingNil = Binding<String?>(get: { nil }, set: { _ in })
        let selectionNil = SelectionBinding.oneOrNone(bindingNil)
        #expect(selectionNil.isNone)
    }

    @Test("Optional selection toggle")
    func optionalSelectionToggle() {
        let value = UncheckedSendable<String?>("option1")
        let binding = Binding<String?>(get: { value.value }, set: { value.value = $0 })
        let selection = SelectionBinding.oneOrNone(binding)

        selection.select("option1")
        #expect(value.value == nil)

        selection.select("option1")
        #expect(value.value == "option1")

        selection.select("option2")
        #expect(value.value == "option2")
    }

    @Test("Multiple selection isNone")
    func multipleSelectionIsNone() {
        let bindingWithValues = Binding<Set<String>>(get: { ["option1"] }, set: { _ in })
        let selectionWithValues = SelectionBinding.multiple(bindingWithValues)
        #expect(!selectionWithValues.isNone)

        let bindingEmpty = Binding<Set<String>>(get: { [] }, set: { _ in })
        let selectionEmpty = SelectionBinding.multiple(bindingEmpty)
        #expect(selectionEmpty.isNone)
    }

    @Test("Multiple selection add and remove")
    func multipleSelectionAddRemove() {
        let value = UncheckedSendable<Set<String>>(["option1"])
        let binding = Binding<Set<String>>(get: { value.value }, set: { value.value = $0 })
        let selection = SelectionBinding.multiple(binding)

        selection.select("option2")
        #expect(value.value == ["option1", "option2"])

        selection.select("option1")
        #expect(value.value == ["option2"])

        selection.select("option2")
        #expect(value.value == [])

        selection.select("option3")
        #expect(value.value == ["option3"])
    }
}
