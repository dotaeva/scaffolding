//
//  View+Coordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 23.09.2025.
//

import SwiftUI

@MainActor
extension View {
    /// Applies presenter-side sheet configuration to presented content.
    @ViewBuilder
    func applySheetConfiguration(_ configuration: SheetConfiguration?) -> some View {
        if let configuration {
            let base = self
                .presentationDragIndicator(configuration.dragIndicator)
                .interactiveDismissDisabled(configuration.interactiveDismissDisabled)
            if configuration.detents.isEmpty {
                base
            } else {
                base.presentationDetents(configuration.detents)
            }
        } else {
            self
        }
    }
}

@MainActor
extension View {
    /// Applies a sheet + full-screen cover to a host coordinator that
    /// stores its modals in an array. Dismissal removes the matching
    /// destination and resolves its lifecycle callback.
    ///
    /// macOS has no full-screen cover, so covers are folded into the
    /// sheet presentation there — a `present(_:as: .fullScreenCover)`
    /// shows (and dismisses) as a sheet instead of silently never
    /// appearing.
    func applyContainerModals<ModalContent: View>(
        sheets sheetDestinations: [Destination],
        fullScreenCovers coverDestinations: [Destination],
        onDismissSheet: @escaping (UUID) -> Void,
        onDismissFullScreenCover: @escaping (UUID) -> Void,
        modalContent: @escaping (Destination) -> ModalContent
    ) -> some View {
#if os(macOS)
        let effectiveSheets = sheetDestinations + coverDestinations
#else
        let effectiveSheets = sheetDestinations
#endif

        let withSheet = self.sheet(
            item: Binding<Destination?>(
                get: { effectiveSheets.first },
                set: { newValue in
                    if newValue == nil, let current = effectiveSheets.first {
                        if current.pushType == .fullScreenCover {
                            onDismissFullScreenCover(current.id)
                        } else {
                            onDismissSheet(current.id)
                        }
                    }
                }
            )
        ) { destination in
            modalContent(destination)
                .id(destination.id)
                .applySheetConfiguration(destination.modalConfiguration)
        }

#if os(macOS)
        return withSheet
#else
        return withSheet.fullScreenCover(
            item: Binding<Destination?>(
                get: { coverDestinations.first },
                set: { newValue in
                    if newValue == nil, let current = coverDestinations.first {
                        onDismissFullScreenCover(current.id)
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

@MainActor
public extension View {
    func environmentCoordinatable(_ object: Any) -> AnyView {
        let mirror = Mirror(reflecting: object)

        guard mirror.displayStyle == .class else {
            return AnyView(self)
        }

        let observableObject = object as AnyObject

        if let observable = observableObject as? (any AnyObject & Observable) {
            var coordinators: [any AnyObject & Observable] = []

            // Self injects only if it opts in. Coordinators that opt out
            // are still walked for their parents — opt-out hides only
            // the coordinator itself from descendant environments.
            if let coordinatable = observable as? any Coordinatable {
                if coordinatable._injectsCoordinator {
                    coordinators.append(observable)
                }
                var currentParent = coordinatable.parent
                while let parent = currentParent {
                    if let parentObservable = parent as? (any AnyObject & Observable),
                       parent._injectsCoordinator {
                        coordinators.append(parentObservable)
                    }
                    currentParent = parent.parent
                }
            } else {
                coordinators.append(observable)
            }

            var result: any View = self
            for coordinator in coordinators {
                result = result.environment(coordinator)
            }

            return AnyView(result)
        }

        return AnyView(self)
    }
}
