/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows extra information about a landmark in an inspector.
*/

import SwiftUI

/// A view that shows extra information about a landmark in an inspector.
struct LandmarkDetailInspectorView: View {
    @Environment(ModelData.self) var modelData
    
    let landmark: Landmark
    @State var selectedSegment: Segment = .metadataAndMap
    @Binding var inspectorIsPresented: Bool

    enum Segment {
        case metadataAndMap
        case activities
    }
    
    var body: some View {
        VStack {
            Picker("View Mode", selection: $selectedSegment) {
                Text("Map (Picker)", comment: "Picker element that lets people switch the content of the Inspector to 'map'.")
                    .tag(Segment.metadataAndMap)
                Text("Activities (Picker)", comment: "Picker element that lets people switch the content of the Inspector to 'activities'.")
                    .tag(Segment.activities)
            }
            .labelsHidden()
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedSegment == .metadataAndMap {
                LandmarkInspectorFormView(landmark: landmark)
            } else {
                LandmarkInspectorBadgeView(landmark: landmark)
            }
        }
        #if os(iOS)
        .toolbarVisibility(UIDevice.current.userInterfaceIdiom == .phone ? .visible : .hidden, for: .automatic)
        .toolbar {
            if UIDevice.current.userInterfaceIdiom == .phone {
                Button {
                    inspectorIsPresented.toggle()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }
        }
        #endif
    }
}

private struct LandmarkInspectorFormView: View {
    @Environment(ModelData.self) var modelData
    
    let landmark: Landmark

    var body: some View {
        Form {
            Section("Map") {
                LandmarkDetailMapView(landmark: landmark, landmarkMapItem: modelData.mapItemsByLandmarkId[landmark.id])
                .aspectRatio(Constants.mapAspectRatio, contentMode: .fit)
                .cornerRadius(Constants.cornerRadius)
            }
            Section("Metadata") {
                LabeledContent("Coordinates", value: landmark.formattedCoordinates)
                LabeledContent("Total Area", value: landmark.formattedTotalArea)
                LabeledContent("Elevation", value: landmark.formattedElevation)
                LabeledContent("Location", value: landmark.formattedLocation)
            }
            .multilineTextAlignment(.trailing)
        }
    }
}

private struct LandmarkInspectorBadgeView: View {
    let landmark: Landmark

    var body: some View {
        VStack {
            if let badge = landmark.badge,
               let activities = landmark.badgeProgress?.activities,
               let badgeProgress = landmark.badgeProgress {
                let columns = [GridItem(.flexible(), alignment: .leading), GridItem(.fixed(Constants.badgeProgressViewWidth))]
                Form {
                    Section() {
                        LazyVGrid(columns: columns, spacing: Constants.standardPadding) {
                            ForEach(activities, id: \.self) { activity in
                                Text(activity.description)
                                BadgeProgressView(activity: activity, badgeProgress: badgeProgress)
                            }
                        }
                    }
                    if badgeProgress.earned {
                        Section() {
                            VStack {
                                HStack {
                                    Spacer()
                                    EarnedBadgeView(badge: badge)
                                    Spacer()
                                }
                                Text("You earned the \(landmark.name) badge!", comment: "Text that indicates you earned a badge for a landmark.")
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
            } else {
                Spacer()
                Text("There isn’t a badge for this landmark.", comment: "Text that indicates the landmark doesn't have a badge.")
                Spacer()
            }
        }
    }
}

private struct EarnedBadgeView: View {
    var badge: Badge
    var body: some View {
        Image(systemName: badge.symbolName)
            .foregroundStyle(.white)
            .font(.system(size: badge.fontSize(forEarnedView: true)))
            .fontWeight(.medium)
            .frame(width: Constants.earnedBadgeSize, height: Constants.earnedBadgeSize)
            .background(content: {
                Image(systemName: "hexagon.fill")
                    .foregroundStyle(badge.badgeColor)
                    .font(.system(size: Constants.earnedHexagonSize))
                    .frame(width: Constants.earnedBadgeSize,
                           height: Constants.earnedBadgeSize)
            })
            .padding(Constants.badgeImagePadding)
    }
}

private struct BadgeProgressView: View {
    let activity: Activity
    var badgeProgress: BadgeProgress
    
    var body: some View {
        Group {
            if badgeProgress.isCompleted(activity) {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .indigo)
                    .font(.title)
            } else {
                Image(systemName: "circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.gray)
                    .font(.title)
            }
        }
        .onTapGesture {
            if badgeProgress.isCompleted(activity) {
                badgeProgress.remove(activity)
            } else {
                badgeProgress.add(activity)
            }
        }
    }
}

#Preview {
    @Previewable @State var modelData = ModelData()
    modelData.selectedLandmark = modelData.landmarksById[1016] ?? modelData.landmarks.first!

    return LandmarkDetailInspectorView(landmark: modelData.selectedLandmark!, inspectorIsPresented: .constant(true))
        .environment(modelData)
}
