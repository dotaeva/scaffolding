//
//  View+FlowCoordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI

@MainActor
extension View {
    func applySheets<ModalContent: View>(
        from coordinator: any FlowCoordinatable,
        modalContent: @escaping (Destination) -> ModalContent
    ) -> some View {
        let sheetDestinations = coordinator.modalDestinations(for: .sheet)
        
        return self.sheet(
            item: Binding<Destination?>(
                get: {
                    sheetDestinations.first
                },
                set: { newValue in
                    if newValue == nil, let currentSheet = sheetDestinations.first {
                        // removeModalDestination invokes the destination's
                        // resolution (continuation + onDismiss) exactly once.
                        coordinator.removeModalDestination(withId: currentSheet.id, type: .sheet)
                    }
                }
            )
        ) { destination in
            modalContent(destination)
                .id(destination.id)
                .applySheetConfiguration(destination.modalConfiguration)
        }
    }

    func applyFullScreenCovers<ModalContent: View>(
        from coordinator: any FlowCoordinatable,
        modalContent: @escaping (Destination) -> ModalContent
    ) -> some View {
#if os(macOS)
        return self
#else
        
        let coverDestinations = coordinator.modalDestinations(for: .fullScreenCover)
        
        return self.fullScreenCover(
            item: Binding<Destination?>(
                get: {
                    coverDestinations.first
                },
                set: { newValue in
                    if newValue == nil, let currentCover = coverDestinations.first {
                        // removeModalDestination invokes the destination's
                        // resolution (continuation + onDismiss) exactly once.
                        coordinator.removeModalDestination(withId: currentCover.id, type: .fullScreenCover)
                    }
                }
            )
        ) { destination in
            modalContent(destination)
                .id(destination.id)
        }
#endif
    }
}
