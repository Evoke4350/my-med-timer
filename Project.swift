import ProjectDescription

let project = Project(
    name: "MyMedTimer",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "H82APH3TK5",
            "CURRENT_PROJECT_VERSION": "4",
            "MARKETING_VERSION": "1.1.0",
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
            ]),
            sources: ["MyMedTimer/**"],
            resources: ["MyMedTimer/Assets.xcassets"],
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
