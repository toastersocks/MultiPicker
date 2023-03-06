//
//  Helpers.swift
//  
//
//  Created by James Pamplona on 3/3/23.
//

import SwiftUI


struct VariadicAdapter<Adapted: View>: _VariadicView_MultiViewRoot {
    var content: (_VariadicView.Children) -> Adapted

    func body(children: _VariadicView.Children) -> some View {
        content(children)
    }
}

extension View {
    func childViews<ChildList: View>(@ViewBuilder children: @escaping (_VariadicView.Children) -> ChildList) -> some View {
        _VariadicView.Tree(VariadicAdapter(content: children), content: { self })
    }
}

public struct MPTag: _ViewTraitKey {
    static public var defaultValue: AnyHashable? = Int?.none
}

public extension View {
    func mpTag<Value: Hashable>(_ value: Value) -> some View {
        _trait(MPTag.self, value)
    }
}
