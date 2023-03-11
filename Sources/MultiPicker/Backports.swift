//
//  Backports.swift
//  
//
//  Created by James Pamplona on 3/10/23.
//

import SwiftUI


extension Backport where Content: View {
    @ViewBuilder func bold(_ active: Bool = true) -> some View {
        if #available(iOS 16, *) {
            content.bold(active)
        } else {
            content.modifier(BoldViewModifier())
        }
    }
}

extension Backport where Content: View {
    @ViewBuilder func fontWeight(_ weight: Font.Weight) -> some View {
        if #available(iOS 16, *) {
            content.fontWeight(weight)
        } else {
            content.modifier(FontWeightModifier(weight))
        }
    }
}

fileprivate struct BoldViewModifier: ViewModifier {

    @Environment(\.font) private var font

    func body(content: Content) -> some View {
        content
            .font(font?.weight(.bold))
    }
}

fileprivate struct FontWeightModifier: ViewModifier {

    @Environment(\.font) private var font
    @State private var weight: Font.Weight

    func body(content: Content) -> some View {
        content
            .font(font?.weight(weight))
    }

    init(_ weight: Font.Weight) {
        self._weight = State(initialValue: weight)
    }
}



