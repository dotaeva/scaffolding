# Landmarks — a Scaffolding port of Apple's Liquid Glass sample

A port of Apple's [Landmarks: Building an app with Liquid Glass](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)
sample to **Scaffolding** coordinators. The data model, views, and Liquid
Glass styling are Apple's (see `LICENSE.txt`); the navigation layer is
rewritten:

| Apple's sample | This port |
|---|---|
| `LandmarksSplitView` — a `NavigationSplitView` whose sidebar *pushes* the selected page | `LandmarksSplitCoordinator` (a `SplitCoordinatable`) — sidebar selection replaces the detail column |
| `ModelData.path: NavigationPath` shared by every screen | Each page is a `FlowCoordinatable` owning its own stack |
| `path.didSet` dismissing the inspector on pop | `onDismiss` on the detail routes |
| `NavigationLink(value:)` + `navigationDestination(for:)` pairs | Routes on the coordinators; rows call `coordinator.showLandmark(_:)` |
| `modelData.path.append(newCollection)` | `CollectionsCoordinator.createCollection()` |

Everything else — the flexible headers, `backgroundExtensionEffect`,
toolbar spacers, the inspector, search, badges, the collection editor and
its native selection sheet — is unchanged.

## Photographs

Apple's sample-code license **excludes the photographs**, so they are not
in this repository. The app ships with generated placeholder art instead —
one deterministic landscape per landmark, so it looks coherent out of the
box.

To see it with the real photos, download Apple's sample and run:

```sh
Scripts/import-apple-assets.sh /path/to/LandmarksBuildingAnAppWithLiquidGlass
```

The import downscales as it copies (~17 MB instead of ~160 MB); pass
`--full-size` to keep the originals. **Do not commit the imported
catalog** — put the placeholders back first:

```sh
Scripts/generate-placeholder-assets.py
```

## Running

```sh
open Landmarks.xcodeproj
```

Requires the iOS 26 SDK (Xcode 26 or later). ⌘R runs the app — iPad and
**native macOS** (the target supports both platforms) show the split
view; iPhone shows the collapsed form.
