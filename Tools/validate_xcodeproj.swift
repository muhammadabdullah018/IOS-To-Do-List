// Structural validator for Skyday.xcodeproj/project.pbxproj.
// Run: swift Tools/validate_xcodeproj.swift   (works on macOS and Linux)
// Checks: the file parses as an OpenStep plist; every referenced object ID exists; every
// object has a known isa; targets have configuration lists, phases and synchronized groups;
// the widget is embedded in the app; both targets link the local SkydayKit package.
import Foundation

let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Skyday.xcodeproj/project.pbxproj"
guard let raw = FileManager.default.contents(atPath: path) else { fatalError("Cannot read \(path)") }

var format = PropertyListSerialization.PropertyListFormat.openStep
guard let root = try PropertyListSerialization.propertyList(from: raw, options: [], format: &format) as? [String: Any],
      let objects = root["objects"] as? [String: [String: Any]],
      let rootObject = root["rootObject"] as? String else {
    fatalError("project.pbxproj is not a valid OpenStep property list")
}

var failures: [String] = []
func check(_ ok: Bool, _ message: String) { if !ok { failures.append(message) } }

let knownISA: Set<String> = [
    "PBXBuildFile", "PBXContainerItemProxy", "PBXCopyFilesBuildPhase", "PBXFileReference",
    "PBXFileSystemSynchronizedBuildFileExceptionSet", "PBXFileSystemSynchronizedRootGroup",
    "PBXFrameworksBuildPhase", "PBXGroup", "PBXNativeTarget", "PBXProject", "PBXResourcesBuildPhase",
    "PBXSourcesBuildPhase", "PBXTargetDependency", "XCBuildConfiguration", "XCConfigurationList",
    "XCLocalSwiftPackageReference", "XCSwiftPackageProductDependency"
]

let idPattern = try NSRegularExpression(pattern: "^[0-9A-F]{24}$")
func isID(_ s: String) -> Bool { idPattern.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil }

// Every 24-hex string value anywhere in an object must resolve.
func collectRefs(_ value: Any, into refs: inout [String]) {
    if let s = value as? String, isID(s) { refs.append(s) }
    else if let a = value as? [Any] { a.forEach { collectRefs($0, into: &refs) } }
    else if let d = value as? [String: Any] { d.forEach { collectRefs($0.value, into: &refs) } }
}

for (id, object) in objects {
    let isa = object["isa"] as? String ?? "?"
    check(knownISA.contains(isa), "\(id): unknown isa \(isa)")
    var refs: [String] = []
    collectRefs(object.filter { $0.key != "isa" && $0.key != "remoteGlobalIDString" }, into: &refs)
    for r in refs { check(objects[r] != nil, "\(id) (\(isa)) references missing object \(r)") }
    if let remote = object["remoteGlobalIDString"] as? String { check(objects[remote] != nil, "proxy \(id) points to missing target") }
}

check(objects[rootObject]?["isa"] as? String == "PBXProject", "rootObject is not a PBXProject")
let project = objects[rootObject] ?? [:]
let targetIDs = project["targets"] as? [String] ?? []
check(targetIDs.count == 3, "expected 3 targets, found \(targetIDs.count)")

var byName: [String: [String: Any]] = [:]
for tid in targetIDs {
    guard let t = objects[tid] else { continue }
    let name = t["name"] as? String ?? "?"
    byName[name] = t
    check(objects[t["buildConfigurationList"] as? String ?? ""] != nil, "\(name): missing configuration list")
    check(!(t["buildPhases"] as? [String] ?? []).isEmpty, "\(name): no build phases")
    check(!(t["fileSystemSynchronizedGroups"] as? [String] ?? []).isEmpty, "\(name): no synchronized source group")
    for g in t["fileSystemSynchronizedGroups"] as? [String] ?? [] {
        let folder = objects[g]?["path"] as? String ?? ""
        var isDir: ObjCBool = false
        check(FileManager.default.fileExists(atPath: folder, isDirectory: &isDir) && isDir.boolValue, "\(name): folder '\(folder)' missing on disk")
    }
}

for name in ["Skyday", "SkydayWidgetExtension", "SkydayUITests"] { check(byName[name] != nil, "missing target \(name)") }

// Package linkage
for name in ["Skyday", "SkydayWidgetExtension"] {
    let deps = byName[name]?["packageProductDependencies"] as? [String] ?? []
    check(deps.contains { objects[$0]?["productName"] as? String == "SkydayKit" }, "\(name) does not link SkydayKit")
}
let localPkg = (project["packageReferences"] as? [String] ?? []).compactMap { objects[$0]?["relativePath"] as? String }
check(localPkg == ["Packages/SkydayKit"], "local package reference missing")
check(FileManager.default.fileExists(atPath: "Packages/SkydayKit/Package.swift"), "Packages/SkydayKit/Package.swift missing")

// Widget embedding
let appPhases = (byName["Skyday"]?["buildPhases"] as? [String] ?? []).compactMap { objects[$0] }
let embed = appPhases.first { $0["isa"] as? String == "PBXCopyFilesBuildPhase" }
check(embed?["dstSubfolderSpec"] as? String == "13", "widget is not embedded as a Foundation extension")

// Build settings that must point at real files
for (id, object) in objects where object["isa"] as? String == "XCBuildConfiguration" {
    let s = object["buildSettings"] as? [String: Any] ?? [:]
    for key in ["CODE_SIGN_ENTITLEMENTS", "INFOPLIST_FILE"] {
        if let file = s[key] as? String { check(FileManager.default.fileExists(atPath: file), "\(id): \(key) = \(file) missing") }
    }
}

if failures.isEmpty {
    print("OK: \(objects.count) objects, \(targetIDs.count) targets, all references resolve.")
} else {
    failures.forEach { print("FAIL: \($0)") }
    exit(1)
}
