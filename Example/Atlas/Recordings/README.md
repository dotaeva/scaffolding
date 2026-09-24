# Atlas recordings

Captured from the Atlas app on **iPhone 17 Simulator, iOS 26.4**, on
September 23, 2026, using Xcode 27.0. Portrait, light appearance, standard text
size, 402 × 874 points / 1206 × 2622 pixels. Both scenarios were verified by
UI tests using accessibility identifiers and before/after screenshots.

The committed clips trim only leading/trailing idle time. They preserve the
original playback speed and all intervening navigation. GIFs are 420 pixels
wide at 12 fps; MP4s are 600 pixels wide at 30 fps, with no audio. Posters are
frames from the same recordings.

## Watch or inspect a still

| Recording | Shows | Formats |
|---|---|---|
| Tab history · 16 seconds | A pushed Places feature shares Discover's stack; returning from Saved preserves Field notes | [GIF](../../../Sources/Scaffolding/Scaffolding.docc/Resources/atlas-tab-history.gif) · [MP4](../../../Sources/Scaffolding/Scaffolding.docc/Resources/atlas-tab-history.mp4) · [Still](../../../Sources/Scaffolding/Scaffolding.docc/Resources/atlas-tab-history-poster.png) |
| Planner result · 18 seconds | A sheet owns its review push, returns a `TripPlan`, and the caller opens the saved journey | [GIF](../../../Sources/Scaffolding/Scaffolding.docc/Resources/atlas-planner-result.gif) · [MP4](../../../Sources/Scaffolding/Scaffolding.docc/Resources/atlas-planner-result.mp4) · [Still](../../../Sources/Scaffolding/Scaffolding.docc/Resources/atlas-planner-result-poster.png) |

DocC's [Tab Bars](../../../Sources/Scaffolding/Scaffolding.docc/Articles/TabBars.md) and
[Modals and Results](../../../Sources/Scaffolding/Scaffolding.docc/Articles/ModalsAndResults.md) guides
use video controls and written walkthroughs. The READMEs use GIFs and select
a still image when the viewer requests reduced motion.

## Record again

Build and run [Atlas](../README.md#run) on an iPhone simulator. Use an isolated
simulator, and substitute its UDID below. The launch argument resets Atlas's
separate UI-test collection and window checkpoint; it does not reset the normal
app collection.

```sh
ATLAS_RECORDING_DEVICE='<simulator UDID>'
xcrun simctl ui "$ATLAS_RECORDING_DEVICE" appearance light
xcrun simctl status_bar "$ATLAS_RECORDING_DEVICE" override \
  --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --batteryState charged --batteryLevel 100
xcrun simctl launch "$ATLAS_RECORDING_DEVICE" com.scaffolding.Atlas --atlas-fresh-session
```

Tap **Start exploring**. To capture tab history, begin recording on Discover:

```sh
xcrun simctl io "$ATLAS_RECORDING_DEVICE" recordVideo \
  --codec=h264 --mask=black /tmp/atlas-tabs.mp4
```

1. Open **The Dolomites** (`place.dolomites`).
2. Tap **Read the field notes** (`place.highlights`).
3. Select **Saved** (`tab.saved`).
4. Select **Discover** (`tab.discover`); verify Field notes is still shown.

Stop with **Control-C** to finalize the recording. For the Planner clip, begin
at The Dolomites overview and record to `/tmp/atlas-planner.mp4`:

1. Tap **Plan a journey** (`place.plan`).
2. Keep the default three days and unhurried pace; tap **Review journey** (`planner.review`).
3. Tap **Save journey** (`planner.finish`); verify the sheet closes and the saved message appears.
4. Tap **View journey** (`notice.action`); verify the saved journey has three days.

Leave each stable screen visible briefly so readers can follow the transition.
Clear the override after recording:

```sh
xcrun simctl status_bar "$ATLAS_RECORDING_DEVICE" clear
```

## Encode for documentation

Trim each capture without changing its speed, then write three files with the
same base name — `atlas-tab-history` or `atlas-planner-result` — into the DocC
Resources directory, shared by all documentation surfaces:

| File | Format |
|---|---|
| `<name>.mp4` | H.264, 30 fps, 600 px wide, for DocC's controlled player |
| `<name>.gif` | 12 fps, 420 px wide, for the READMEs |
| `<name>-poster.png` | One representative frame, 600 px wide |

The current clips start one second into each capture and run 16 and 18 seconds.
Keep full-resolution raw captures outside the repository.

Check the whole animation, final state, poster, text legibility, and payload size
before updating the assets. Rebuild DocC to verify
resource references. Update the device/OS and durations here and in the captions
when replacing a clip.
