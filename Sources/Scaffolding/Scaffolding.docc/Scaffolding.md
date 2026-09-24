# ``Scaffolding``

Compose SwiftUI navigation across feature boundaries with observable
coordinators and routes generated from ordinary Swift functions.

@Metadata {
    @PageColor(blue)
}

## Overview

Coordinators own navigation; views request it. A feature exposes its
coordinator and keeps its screens internal, and a parent composes features
into stacks, tabs, app roots, or split columns. Scaffolding renders SwiftUI's
native containers, and every navigation decision is testable without a view.

Start with <doc:MeetScaffolding>, then read <doc:Essentials> — the model and
rules every other guide builds on.

## Topics

### Getting Started

- <doc:MeetScaffolding>
- <doc:Essentials>

### App Architecture

- <doc:ModularApps>
- <doc:MonolithicApps>

### Coordinator Guides

- <doc:Flows>
- <doc:RootSwitching>
- <doc:TabBars>
- <doc:SplitViews>

### Navigation Guides

- <doc:DefiningRoutes>
- <doc:ModalsAndResults>
- <doc:DeepLinking>

### Inspection, Persistence, and Testing

- <doc:Orientation>
- <doc:StateRestoration>
- <doc:TestingCoordinators>

### Migration

- <doc:NativeComparison>
- <doc:MigratingFromStinsen>

### Coordinator Protocols

- ``Coordinatable``
- ``FlowCoordinatable``
- ``RootCoordinatable``
- ``TabCoordinatable``
- ``SplitCoordinatable``

### Route Generation

- ``Scaffoldable(injectsCoordinator:codable:)``
- ``ScaffoldingIgnored()``
- ``Destinationable``
- ``DestinationMeta``

### Destinations and Presentation

- ``Destination``
- ``DestinationType``
- ``PresentationType``
- ``ModalPresentationType``
- ``RoutePolicy``

### Animation

- ``NavigationAnimation``
- ``withNavigationTransaction(animation:_:)``

### State Containers

- ``FlowStack``
- ``Root``
- ``TabItems``
- ``SplitColumns``
- ``SplitColumn``
- ``AnyFlowStack``
- ``AnyRoot``
- ``AnyTabItems``
- ``AnySplitColumns``
- ``CoordinatableData``

### Hierarchy Inspection

- ``HierarchyNode``
- ``HierarchyRole``

### State Restoration Types

- ``NavigationRestorationMode``
- ``NavigationStateError``
- ``NavigationStateNode``
- ``NavigationStateReport``
- ``NavigationStateIssue``
- ``NavigationStateCapture``

### Rendered Views

- ``CoordinatableView``
- ``FlowCoordinatableView``
- ``RootCoordinatableView``
- ``TabCoordinatableView``
- ``SplitCoordinatableView``

### Deprecated Compatibility

- ``SheetConfiguration``
