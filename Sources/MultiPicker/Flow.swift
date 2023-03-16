//
//  Flow.swift
//  
//
//  Created by James Pamplona on 3/13/23.
//

import SwiftUI
import Helpers


internal struct Flow<Content: View>: View {
    private var content: () -> Content
    @State private var cellSizes: [CGSize] = []
    @State private var containerSize: CGSize = .zero
    @State private var idealWidth: Double = 0

    var body: some View {
        let cellPositions = layoutCells(ofSizes: cellSizes, inContainerSize: containerSize).positions

        VStack(spacing: 0) {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ContainerSizeKey.self, value: proxy.size)
            }
            .onPreferenceChange(ContainerSizeKey.self) {
                containerSize = $0
            }
            .frame(height: 0)
        }
        ZStack(alignment: .topLeading) {

            content().childViews { children in
                ForEach(identifyChildren(children), id: \.id) { child, index, _ in
                    child
                        .fixedSize()
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: CellSizesKey.self, value: [proxy.size])
                        })
                        .alignmentGuide(.leading) { _ in
                            guard cellPositions.isEmpty == false,
                                  index < cellPositions.count else { return 0 }

                            return -cellPositions[index].x
                        }
                        .alignmentGuide(.top) { _ in
                            guard cellPositions.isEmpty == false,
                                  index < cellPositions.count else { return 0 }

                            return -cellPositions[index].y
                        }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
        .onPreferenceChange(CellSizesKey.self) {
            self.cellSizes = $0
        }
    }

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    func identifyChildren(_ children: _VariadicView.Children) -> [(child: _VariadicView.Children.Element, index: Int, id: UUID)] {
        var result: [(child: _VariadicView.Children.Element, index: Int, id: UUID)] = []
        for (index, child) in children.enumerated() {
            result.append((child, index, UUID()))
        }

        return result
    }

    func layoutCells(ofSizes sizes: [CGSize], withSpacing spacing: Double = 8, inContainerSize containerSize: CGSize) -> (positions: [CGPoint], idealWidth: Double) {
        var currentPoint: CGPoint = .zero
        var result: [CGPoint] = []
        var rowHeight = 0.0
        var longestWidth = 0.0
        for size in sizes {
            if currentPoint.x + size.width > containerSize.width {
                currentPoint.x = 0
                currentPoint.y += rowHeight + spacing
            }
            result.append(currentPoint)
            currentPoint.x += size.width + spacing
            longestWidth = max(longestWidth, currentPoint.x)
            rowHeight = max(rowHeight, size.height)
        }

        return (result, longestWidth)
    }
}

struct CellSizesKey: PreferenceKey {
    static var defaultValue: [CGSize] = []
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}

struct ContainerSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var items = [
        Model(title: String(localized: "Red"), color: .red),
        Model(title: String(localized: "Orange"), color: .orange),
        Model(title: String(localized: "Yellow"), color: .yellow),
        Model(title: String(localized: "Green"), color: .green),
        Model(title: String(localized: "Blue"), color: .blue),
        Model(title: String(localized: "Indigo"), color: .indigo),
        Model(title: String(localized: "Violet"), color: .purple),
    ]
    static var previews: some View {
        ZStack {
            Flow {
                ForEach(Self.items) {
                    ModelCell(model: $0)
                }
            }
        }
    }
}
