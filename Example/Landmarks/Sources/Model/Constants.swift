/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Constant values that the app defines.
*/

import SwiftUI

/// Constant values that the app defines.
struct Constants {
    // MARK: App-wide constants
    
    static let cornerRadius: CGFloat = 15.0
    static let leadingContentInset: CGFloat = 26.0
    static let standardPadding: CGFloat = 14.0
    static let landmarkImagePadding: CGFloat = 14.0
    static let safeAreaPadding: CGFloat = 30.0
    static let titleTopPadding: CGFloat = 8.0
    static let titleBottomPadding: CGFloat = -4.0
        
    // MARK: Collection grid constants
    
    static let collectionGridSpacing: CGFloat = 14.0
    static var collectionGridWidth: CGFloat {
        return landmarkGridWidth
    }
    
    @MainActor static var collectionGridItemMinSize: CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 220.0
        } else {
            return 160.0
        }
            
        #else
        return 220.0
        #endif
    }
    static let collectionGridItemMaxSize: CGFloat = 290.0
    static let collectionGridItemCornerRadius: CGFloat = 8.0
    
    // MARK: Collection detail constants
    
    static let textEditorHeight: CGFloat = 88.0
    static let minimumLandmarkWidth: CGFloat = 120.0
    static let landmarkGridPadding: CGFloat = 8.0
    static var landmarkGridWidth: CGFloat {
        return minimumLandmarkWidth * 4.0 + (5 * landmarkGridPadding)
    }
    
    // MARK: Landmark grid constants
    
    static let landmarkGridSpacing: CGFloat = 14.0
    @MainActor static var landmarkGridItemMinSize: CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 240.0
        } else {
            return 160.0
        }
            
        #else
        return 240.0
        #endif
    }
    static let landmarkGridItemMaxSize: CGFloat = 320.0
    @MainActor static var landmarkGridItemEditingMinSize: CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 180.0
        } else {
            return 140.0
        }
            
        #else
        return 180.0
        #endif
    }
    static let landmarkGridItemEditingMaxSize: CGFloat = 240.0

    // MARK: Landmark detail constants
    
    static let mapAspectRatio: CGFloat = 1.2
    
    // MARK: Landmark featured item constants
    
    static let learnMorePadding: CGFloat = 6.0
    static let learnMoreBottomPadding: CGFloat = 40.0
    
    // MARK: Landmark list constants
    
    static let landmarkListItemAspectRatio: CGFloat = 1.4
    static let landmarkListPercentOfHeight: CGFloat = 0.2
    static let landmarkListMinimumHeight: CGFloat = 140.0

    // MARK: Landmark selection constants
    
    static let landmarkSelectionImageSize: CGSize = CGSize(width: 48.0, height: 48.0)
    static let landmarkSelectionImageCornerRadius: CGFloat = 8.0
    
    // MARK: Badge constants
    static let badgeSize: CGFloat = 52.0
    static let badgeGlassSpacing: CGFloat = 16.0
    static let badgeSpacing: CGFloat = 14.0
    static let badgeButtonTopSpacing: CGFloat = 20.0
    static let badgeShowHideButtonWidth: CGFloat = 24.0
    static let badgeShowHideButtonHeight: CGFloat = 32.0
    static let toggleButtonFontSize: CGFloat = 17.0
    static let hexagonSize: CGFloat = 48.0
    static let badgeImagePadding: CGFloat = 12.0
    static let badgeCornerRadius: CGFloat = 24.0
    static let badgeFrameWidth: CGFloat = 74.0
    static let badgeProgressViewWidth: CGFloat = 48.0

    // MARK: Earned Badge constants
    static let earnedBadgeSize: CGFloat = 60.0
    static let earnedHexagonSize: CGFloat = 56.0

    // MARK: Style
#if os(macOS)
    static let editingBackgroundStyle = WindowBackgroundShapeStyle.windowBackground
#else
    static let editingBackgroundStyle = Material.ultraThickMaterial
#endif
}
