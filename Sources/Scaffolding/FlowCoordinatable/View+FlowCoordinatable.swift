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
#if os(macOS)
        // macOS has no full-screen cover — fold covers into the sheet
        // presentation so present(_:as: .fullScreenCover) still shows
        // (and can be dismissed) instead of silently never appearing.
        let sheetDestinations = coordinator.modalDestinations(for: .sheet)
            + coordinator.modalDestinations(for: .fullScreenCover)
#else
        let sheetDestinations = coordinator.modalDestinations(for: .sheet)
#endif

        return self.sheet(
            item: Binding<Destination?>(
                get: {
                    sheetDestinations.first
                },
                set: { newValue in
                    if newValue == nil, let currentSheet = sheetDestinations.first {
                        // removeModalDestination invokes the destination's
                        // resolution (continuation + onDismiss) exactly once.
                        coordinator.removeModalDestination(
                            withId: currentSheet.id,
                            type: currentSheet.pushType ?? .sheet
                        )
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
