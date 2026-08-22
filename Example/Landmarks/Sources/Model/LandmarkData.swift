/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The app's sample landmark data.
*/

import Foundation

extension Landmark {
    /// The app's sample landmark data.
    @MainActor static let exampleData = [
        Landmark(
            id: 1001,
            name: .LandmarkData.saharaDesertName,
            continent: "Africa",
            description: .LandmarkData.saharaDesertDescription,
            latitude: 23.900_13,
            longitude: 10.335_69,
            span: 40.0,
            placeID: "IC6C65CA81B4B2772",
            totalArea: .init(value: 9_200_200, unit: .squareKilometers),
            elevation: .fixed(.init(value: 300, unit: .meters)),
            location: .LandmarkData.saharaDesertLocation,
            badge: .saharaDesert,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1002,
            name: .LandmarkData.serengetiName,
            continent: "Africa",
            description: .LandmarkData.serengetiDescription,
            latitude: -2.454_69,
            longitude: 34.881_59,
            span: 10.0,
            placeID: "IB3A0184A4D301279",
            totalArea: .init(value: 14_763, unit: .squareKilometers),
            elevation: .fixed(.init(value: 920, unit: .meters)),
            location: .LandmarkData.serengetiLocation
        ),
        
        Landmark(
            id: 1003,
            name: .LandmarkData.deadvleiName,
            continent: "Africa",
            description: .LandmarkData.deadvleiDescription,
            latitude: -24.7629,
            longitude: 15.294_29,
            span: 10.0,
            placeID: "IBD2966F32E73D261",
            totalArea: nil,
            elevation: .fixed(.init(value: 550, unit: .meters)),
            location: .LandmarkData.deadvleiLocation
        ),
        
        Landmark(
            id: 1004,
            name: .LandmarkData.grandCanyonName,
            continent: "North America",
            description: .LandmarkData.grandCanyonDescription,
            latitude: 36.219_04,
            longitude: -113.160_96,
            span: 10.0,
            placeID: "I55488B3D1D9B2D4B",
            totalArea: nil,
            elevation: .closedRange(low: .init(value: 800, unit: .meters), high: .init(value: 2000, unit: .meters)),
            location: .LandmarkData.grandCanyonLocation
        ),
        
        Landmark(
            id: 1005,
            name: .LandmarkData.niagaraFallsName,
            continent: "North America",
            description: .LandmarkData.niagaraFallsDescription,
            latitude: 43.077_92,
            longitude: -79.074_01,
            span: 4.0,
            placeID: "I433E22BD30C61C40",
            totalArea: nil,
            elevation: .fixed(.init(value: 108, unit: .meters)),
            location: .LandmarkData.niagaraFallsLocation,
            badge: .niagaraFalls,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1006,
            name: .LandmarkData.joshuaTreeName,
            continent: "North America",
            description: .LandmarkData.joshuaTreeDescription,
            latitude: 33.887_52,
            longitude: -115.808_26,
            span: 10.0,
            placeID: "I34674B3D3B032AA2",
            totalArea: .init(value: 3218, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 160, unit: .meters), high: .init(value: 1800, unit: .meters)),
            location: .LandmarkData.joshuaTreeLocation
        ),
        
        Landmark(
            id: 1007,
            name: .LandmarkData.rockyMountainsName,
            continent: "North America",
            description: .LandmarkData.rockyMountainsDescription,
            latitude: 47.625_96,
            longitude: -112.998_72,
            span: 16.0,
            placeID: "IBD757C9B53C92D9E",
            totalArea: .init(value: 780_000, unit: .squareKilometers),
            elevation: .openRange(high: .init(value: 4400, unit: .meters)),
            location: .LandmarkData.rockyMountainsLocation,
            badge: .rockyMountains,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: false,
                .readDescription: false,
                .findNature: false,
                .drawSketch: false
            ])
        ),
        
        Landmark(
            id: 1008,
            name: .LandmarkData.monumentValleyName,
            continent: "North America",
            description: .LandmarkData.monumentValleyDescription,
            latitude: 36.874,
            longitude: -110.348,
            span: 10.0,
            placeID: "IAB1F0D2360FAAD29",
            totalArea: .init(value: 370, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 1500, unit: .meters), high: .init(value: 1800, unit: .meters)),
            location: .LandmarkData.monumentValleyLocation
        ),
        
        Landmark(
            id: 1009,
            name: .LandmarkData.muirWoodsName,
            continent: "North America",
            description: .LandmarkData.muirWoodsDescription,
            latitude: 37.8922,
            longitude: -122.574_82,
            span: 2.0,
            placeID: "I907589547EB05261",
            totalArea: .init(value: 2, unit: .squareKilometers),
            elevation: .fixed(.init(value: 166, unit: .meters)),
            location: .LandmarkData.muirWoodsLocation
        ),
        
        Landmark(
            id: 1010,
            name: .LandmarkData.amazonRainforestName,
            continent: "South America",
            description: .LandmarkData.amazonRainforestDescription,
            latitude: -3.508_79,
            longitude: -62.808_02,
            span: 30.0,
            placeID: "I76A1045FB9294971",
            totalArea: .init(value: 6_000_000, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 20, unit: .meters), high: .init(value: 60, unit: .meters)),
            location: .LandmarkData.amazonRainforestLocation,
            badge: .amazonRainforest,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: false,
                .readDescription: false,
                .findNature: false,
                .drawSketch: false
            ])
        ),
        
        Landmark(
            id: 1011,
            name: .LandmarkData.lençóisMaranhensesName,
            continent: "South America",
            description: .LandmarkData.lençóisMaranhensesDescription,
            latitude: -2.578_12,
            longitude: -43.033_45,
            span: 10.0,
            placeID: "I292A37DAC754D6A0",
            totalArea: .init(value: 1550, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 0, unit: .meters), high: .init(value: 40, unit: .meters)),
            location: .LandmarkData.lençóisMaranhensesLocation
        ),
        
        Landmark(
            id: 1012,
            name: .LandmarkData.uyuniSaltFlatName,
            continent: "South America",
            description: .LandmarkData.uyuniSaltFlatDescription,
            latitude: -20.133_78,
            longitude: -67.489_14,
            span: 10.0,
            placeID: "ID903C9A78EB0CAAD",
            totalArea: .init(value: 10_582, unit: .squareKilometers),
            elevation: .fixed(.init(value: 3663, unit: .meters)),
            location: .LandmarkData.uyuniSaltFlatLocation
        ),
        
        Landmark(
            id: 1014,
            name: .LandmarkData.whiteCliffsOfDoverName,
            continent: "Europe",
            description: .LandmarkData.whiteCliffsOfDoverDescription,
            latitude: 51.136_41,
            longitude: 1.363_51,
            span: 4.0,
            placeID: "I77B160572D5A2EB1",
            totalArea: nil,
            elevation: .closedRange(low: .init(value: 0, unit: .meters), high: .init(value: 110, unit: .meters)),
            location: .LandmarkData.whiteCliffsOfDoverLocation
        ),
        
        Landmark(
            id: 1015,
            name: .LandmarkData.alpsName,
            continent: "Europe",
            description: .LandmarkData.alpsDescription,
            latitude: 46.773_67,
            longitude: 10.547_73,
            span: 6.0,
            placeID: "IE380E71D265F97C0",
            totalArea: .init(value: 200_000, unit: .squareKilometers),
            elevation: .openRange(high: .init(value: 4800, unit: .meters)),
            location: .LandmarkData.alpsLocation
        ),
        
        Landmark(
            id: 1016,
            name: .LandmarkData.mountFujiName,
            continent: "Asia",
            description: .LandmarkData.mountFujiDescription,
            latitude: 35.360_72,
            longitude: 138.727_44,
            span: 10.0,
            placeID: "I2CC1DF519EDD7ACD",
            totalArea: .init(value: 207, unit: .squareKilometers),
            elevation: .fixed(.init(value: 3776, unit: .meters)),
            location: .LandmarkData.mountFujiLocation,
            badge: .mountFuji,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1017,
            name: .LandmarkData.wulingyuanName,
            continent: "Asia",
            description: .LandmarkData.wulingyuanDescription,
            latitude: 29.351_06,
            longitude: 110.452_42,
            span: 10.0,
            placeID: "I818C4BA5FE11BDD6",
            totalArea: .init(value: 264, unit: .squareKilometers),
            elevation: .fixed(.init(value: 1050, unit: .meters)),
            location: .LandmarkData.wulingyuanLocation
        ),
        
        Landmark(
            id: 1018,
            name: .LandmarkData.mountEverestName,
            continent: "Asia",
            description: .LandmarkData.mountEverestDescription,
            latitude: 27.988_16,
            longitude: 86.9251,
            span: 10.0,
            placeID: "IE16B9C217B9B0DC1",
            totalArea: nil,
            elevation: .fixed(.init(value: 8848, unit: .meters)),
            location: .LandmarkData.mountEverestLocation
        ),
        
        Landmark(
            id: 1019,
            name: .LandmarkData.greatBarrierReefName,
            continent: "Australia/Oceania",
            description: .LandmarkData.greatBarrierReefDescription,
            latitude: -16.7599,
            longitude: 145.978_42,
            span: 16.0,
            placeID: "IF436B51611F3F9D1",
            totalArea: .init(value: 344_400, unit: .squareKilometers),
            elevation: nil,
            location: .LandmarkData.greatBarrierReefLocation,
            badge: .greatBarrierReef,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1020,
            name: .LandmarkData.yellowstoneNationalParkName,
            continent: "North America",
            description: .LandmarkData.yellowstoneNationalParkDescription,
            latitude: 44.6,
            longitude: -110.5,
            span: 4.0,
            placeID: "ICE88191F5D7094D0",
            totalArea: .init(value: 8991, unit: .squareKilometers),
            elevation: .fixed(.init(value: 2470, unit: .meters)),
            location: .LandmarkData.yellowstoneNationalParkLocation
        ),
        
        Landmark(
            id: 1021,
            name: .LandmarkData.southShetlandIslandsName,
            continent: "Antarctica",
            description: .LandmarkData.southShetlandIslandsDescription,
            latitude: -61.794_36,
            longitude: -58.707_03,
            span: 20.0,
            placeID: "I1AAF5FE1DF954A59",
            totalArea: .init(value: 3687, unit: .squareKilometers),
            elevation: .closedRange(low: .init(value: 0, unit: .meters), high: .init(value: 2025, unit: .meters)),
            location: .LandmarkData.southShetlandIslandsLocation,
            badge: .southShetlandIslands,
            badgeProgress: BadgeProgress(progress: [
                .takePhoto: true,
                .readDescription: true,
                .findNature: true,
                .drawSketch: true
            ])
        ),
        
        Landmark(
            id: 1022,
            name: .LandmarkData.kirkjufellMountainName,
            continent: "Europe",
            description: .LandmarkData.kirkjufellMountainDescription,
            latitude: 64.941,
            longitude: -23.305,
            span: 2.0,
            placeID: "I4E9DB8B46491DC5E",
            totalArea: nil,
            elevation: .fixed(.init(value: 463, unit: .meters)),
            location: .LandmarkData.kirkjufellMountainLocation
        )
    ]
}
