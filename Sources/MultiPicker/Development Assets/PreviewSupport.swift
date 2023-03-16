//
//  PreviewSupport.swift
//  
//
//  Created by James Pamplona on 3/13/23.
//

import SwiftUI


#if DEBUG
struct Model: Hashable {
    let title: String
    let color: Color
}

extension Model: Identifiable {
    var id: String {
        title
    }
}

extension Model: CustomStringConvertible {
    var description: String {
        title
    }
}

struct ModelCell: View {
    let model: Model
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 3)
            //            model.color
                .fill(model.color)
            //            Image(systemName: "square.fill")
            //                .foregroundColor(model.color)
                .aspectRatio(1, contentMode: .fill)

                .fixedSize(horizontal: true, vertical: false)
                .padding(.vertical, 6)
            Text(model.title)
        }
    }
}
#endif
