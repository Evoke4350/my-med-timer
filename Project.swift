import ProjectDescription

let appGroup = "group.com.nateb.mymedtimer"

let project = Project(
    name: "MyMedTimer",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "H82APH3TK5",
            "CURRENT_PROJECT_VERSION": "8",
            "MARKETING_VERSION": "1.5.0",
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        .target(
            name: "MyMedTimer",
            destinations: .iOS,
            product: .app,
            bundleId: "com.nateb.mymedtimer",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UIBackgroundModes": .array([.string("fetch")]),
                "UILaunchScreen": .dictionary([:]),
                "NSSupportsLiveActivities": .boolean(true),
                "ITSAppUsesNonExemptEncryption": .boolean(false),
                "CFBundleShortVersionString": .string("$(MARKETING_VERSION)"),
                "CFBundleVersion": .string("$(CURRENT_PROJECT_VERSION)"),
            ]),
            sources: ["MyMedTimer/**", "Shared/**"],
            resources: ["MyMedTimer/Assets.xcassets"],
            entitlements: .file(path: "MyMedTimer.entitlements"),
            dependencies: [
                .target(name: "MyMedTimerWidgets"),
            ]
        ),
        .target(
            name: "MyMedTimerWidgets",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.nateb.mymedtimer.widgets",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": .dictionary([
                    "NSExtensionPointIdentifier": .string("com.apple.widgetkit-extension"),
                ]),
                "CFBundleDisplayName": .string("MyMedTimer Widgets"),
                "CFBundleShortVersionString": .string("$(MARKETING_VERSION)"),
                "CFBundleVersion": .string("$(CURRENT_PROJECT_VERSION)"),
            ]),
            sources: ["MyMedTimerWidgets/**", "Shared/**"],
            entitlements: .file(path: "MyMedTimerWidgets.entitlements"),
            dependencies: []
        ),
        .target(
            name: "MyMedTimerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.nateb.mymedtimer.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["MyMedTimerTests/**"],
            dependencies: [
                .target(name: "MyMedTimer"),
            ]
        ),
    ]
)
