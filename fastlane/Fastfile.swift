// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

/* Configuration */
protocol Configuration {
    /// file name of the certificate
    var certificate: String { get }

    /// file name of the provisioning profile
    var provisioningProfile: String { get }

    /// configuration name in xcode project
    var buildConfiguration: String { get }

    /// the app id for this configuration
    var appIdentifier: String { get }

    /// export methods, such as "ad-doc" or "appstore"
    var exportMethod: String { get }
}

struct Staging: Configuration {
    var certificate = "ios_distribution"
    var provisioningProfile = "Brewer_Staging"
    var buildConfiguration = "Staging"
    var appIdentifier = "works.sth.brewer.staging"
    var exportMethod = "ad-hoc"
}

struct Production: Configuration {
    var certificate = "ios_distribution"
    var provisioningProfile = "Brewer_Production"
    var buildConfiguration = "Production"
    var appIdentifier = "works.sth.brewer.production"
    var exportMethod = "ad-hoc"
}

struct Release: Configuration {
    var certificate = "ios_distribution"
    var provisioningProfile = "Brewer_Release"
    var buildConfiguration = "Release"
    var appIdentifier = "works.sth.brewer"
    var exportMethod = "app-store"
}

enum ProjectSetting {
    static var workspace = "brewer.xcworkspace"
    static var project = "brewer.xcodeproj"
    static var scheme = "brewer"
    static var target = "brewer"
    static var productName = "brewer"
    static let devices: [String] = ["iPhone 8", "iPad Air"]

    static let codeSigningPath = environmentVariable(get: "CODESIGNING_PATH")
    static let keyChainDefaultPath = environmentVariable(get: "KEYCHAIN_DEFAULT_PATH")
    static let certificatePassword = environmentVariable(get: "CERTIFICATE_PASSWORD")
    static let sdk = "iphoneos11.2"
}

/* Lanes */
class Fastfile: LaneFile {
    var stubKeyChainPassword: String = "stub"

    var keyChainName: String {
        return "\(ProjectSetting.productName).keychain"
    }

    var keyChainDefaultFilePath: String {
        return "\(ProjectSetting.keyChainDefaultPath)/\(keyChainName)-db"
    }

    func beforeAll() {
        cocoapods()
    }

    func package(config: Configuration) {
        if FileManager.default.fileExists(atPath: keyChainDefaultFilePath) {
            deleteKeychain(name: keyChainName)
        }

        createKeychain(
            name: keyChainName,
            password: stubKeyChainPassword,
            defaultKeychain: false,
            unlock: true,
            timeout: 3600,
            lockWhenSleeps: true
        )

        importCertificate(
            keychainName: keyChainName,
            keychainPassword: stubKeyChainPassword,
            certificatePath: "\(ProjectSetting.codeSigningPath)/\(config.certificate).p12",
            certificatePassword: ProjectSetting.certificatePassword
        )

        updateProjectProvisioning(
            xcodeproj: ProjectSetting.project,
            profile: "\(ProjectSetting.codeSigningPath)/\(config.provisioningProfile).mobileprovision",
            targetFilter: "^\(ProjectSetting.target)$",
            buildConfiguration: config.buildConfiguration
        )

        runTests(workspace: ProjectSetting.workspace,
            devices: ProjectSetting.devices,
            scheme: ProjectSetting.scheme)

        buildApp(
            workspace: ProjectSetting.workspace,
            scheme: ProjectSetting.scheme,
            clean: true,
            outputDirectory: "./",
            outputName: "\(ProjectSetting.productName).ipa",
            configuration: config.buildConfiguration,
            silent: true,
            exportMethod: config.exportMethod,
            exportOptions: [
                "signingStyle": "manual",
                "provisioningProfiles": [config.appIdentifier: config.provisioningProfile] ],
            sdk: ProjectSetting.sdk

        )

        deleteKeychain(name: keyChainName)
    }

    func developerReleaseLane() {
        desc("Create a developer release")
        package(config: Staging())
        crashlytics(
            ipaPath: "./\(ProjectSetting.productName).ipa",
            apiToken: environmentVariable(get: "CRASHLYTICS_API_KEY"),
            buildSecret: environmentVariable(get: "CRASHLYTICS_BUILD_SECRET")
        )
    }

    func qaReleaseLane() {
        desc("Create a weekly release")
        package(config: Production())
        crashlytics(
            ipaPath: "./\(ProjectSetting.productName).ipa",
            apiToken: environmentVariable(get: "CRASHLYTICS_API_KEY"),
            buildSecret: environmentVariable(get: "CRASHLYTICS_BUILD_SECRET")
        )
    }

}
