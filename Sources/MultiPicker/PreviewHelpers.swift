//
//  PreviewHelpers.swift
//  
//
//  Created by James Pamplona on 3/6/23.
//

#if DEBUG
import SwiftUI

struct PreviewBindingHelper3<Choice, A, B, C, Content: View>: View {
    @State var values: (A, B, C)
    @State var choices: [Choice]
    @ViewBuilder var content: ([Choice], Binding<A>, Binding<B>, Binding<C>) -> Content

    var body: some View {
        content(choices, $values.0.projectedValue, $values.1.projectedValue, $values.2.projectedValue)
    }

    init(choices: [Choice], values: (A, B, C), @ViewBuilder content: @escaping ([Choice], Binding<A>, Binding<B>, Binding<C>) -> Content) {
        _values = State(wrappedValue: values)
        _choices = State(wrappedValue: choices)
        self.content = content
    }
}

struct PreviewBindingHelper<Choice, A, Content: View>: View {
    @State private var value: A
    @State private var choices: [Choice]
    @ViewBuilder private var content: ([Choice], Binding<A>) -> Content

    var body: some View {
        content(choices, $value)
    }

    init(choices: [Choice], value: A, @ViewBuilder content: @escaping ([Choice], Binding<A>) -> Content) {
        _value = State(wrappedValue: value)
        _choices = State(wrappedValue: choices)
        self.content = content
    }
}

/*
extension PreviewBindingHelper {
    init<A>(_ values: Values, @ViewBuilder content: @escaping (Binding<A>) -> Content) where Bindings == (A) {
        _values = State(wrappedValue: values)
        self.content = content
    }
}

fileprivate func expand<A>(_ tuple: Binding<(A)>) -> (Binding<A>) {
    (tuple.projectedValue)
}

fileprivate func expand<A, B>(_ tuple: Binding<(A, B)>) -> (Binding<A>, Binding<B>) {
    (tuple.0.projectedValue, tuple.1.projectedValue)
}

fileprivate func expand<A, B, C>(_ tuple: Binding<(A, B, C)>) -> (Binding<A>, Binding<B>, Binding<C>) {
    (tuple.0.projectedValue, tuple.1.projectedValue, tuple.2.projectedValue)
}

fileprivate func expand<A, B, C, D>(_ tuple: Binding<(A, B, C, D)>) -> (Binding<A>, Binding<B>, Binding<C>, Binding<D>) {
    (tuple.0.projectedValue, tuple.1.projectedValue, tuple.2.projectedValue, tuple.3.projectedValue)
}

fileprivate func expand<A, B, C, D, E>(_ tuple: Binding<(A, B, C, D, E)>) -> (Binding<A>, Binding<B>, Binding<C>, Binding<D>, Binding<E>) {
    (tuple.0.projectedValue, tuple.1.projectedValue, tuple.2.projectedValue, tuple.3.projectedValue, tuple.4.projectedValue)
}
*/


#endif
