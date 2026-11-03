#!/usr/bin/env python3
"""Generates Skyday.xcodeproj (Xcode 16 format, objectVersion 77, synchronized folders).

Why a generator: the project was authored on Linux without Xcode. Generating the pbxproj
from one declarative description keeps object IDs consistent and makes the file easy to
regenerate after changing bundle IDs, the team, or the deployment target.

Usage:  python3 Tools/generate_xcodeproj.py [--team ABCDE12345] [--bundle-prefix com.example]
Files are picked up automatically from the Skyday/, SkydayWidget/ and SkydayUITests/
folders (synchronized groups), so adding Swift files never requires editing the project.
"""
import argparse
import hashlib
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

parser = argparse.ArgumentParser()
parser.add_argument("--team", default="", help="Apple Developer Team ID (leave empty to pick in Xcode)")
parser.add_argument("--bundle-prefix", default="com.skyday", help="Reverse-DNS prefix for bundle IDs")
parser.add_argument("--deployment-target", default="17.0")
args = parser.parse_args()

APP_ID = f"{args.bundle_prefix}.app"
WIDGET_ID = f"{APP_ID}.widget"
UITEST_ID = f"{APP_ID}.uitests"


def oid(name: str) -> str:
    """Deterministic 24-hex-digit object ID."""
    return hashlib.sha1(("skyday:" + name).encode()).hexdigest()[:24].upper()


def q(value) -> str:
    s = str(value)
    if re.fullmatch(r"[A-Za-z0-9_./]+", s) and s != "":
        return s
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def settings_block(d: dict, indent: str) -> str:
    lines = []
    for k in sorted(d):
        v = d[k]
        if isinstance(v, list):
            inner = "".join(f"{indent}\t\t{q(x)},\n" for x in v)
            lines.append(f"{indent}\t{k} = (\n{inner}{indent}\t);\n")
        else:
            lines.append(f"{indent}\t{k} = {q(v)};\n")
    return "".join(lines)


# IDs
PROJECT = oid("project")
MAIN_GROUP = oid("group.main")
PRODUCTS_GROUP = oid("group.products")
SYNC_APP = oid("sync.Skyday")
SYNC_WIDGET = oid("sync.SkydayWidget")
SYNC_UITESTS = oid("sync.SkydayUITests")
EXC_APP = oid("exc.Skyday")
EXC_WIDGET = oid("exc.SkydayWidget")
PRODUCT_APP = oid("product.app")
PRODUCT_WIDGET = oid("product.appex")
PRODUCT_UITESTS = oid("product.xctest")
T_APP = oid("target.app")
T_WIDGET = oid("target.widget")
T_UITESTS = oid("target.uitests")
LOCAL_PKG = oid("pkg.local.SkydayKit")
PKGDEP_APP = oid("pkgdep.app")
PKGDEP_WIDGET = oid("pkgdep.widget")
BF_KIT_APP = oid("bf.kit.app")
BF_KIT_WIDGET = oid("bf.kit.widget")
BF_EMBED_APPEX = oid("bf.embed.appex")
PROXY_WIDGET = oid("proxy.widget")
PROXY_APP = oid("proxy.app")
DEP_WIDGET = oid("dep.widget")
DEP_APP = oid("dep.app")
PH = {t: {p: oid(f"phase.{t}.{p}") for p in ("sources", "frameworks", "resources")} for t in ("app", "widget", "uitests")}
EMBED_PHASE = oid("phase.app.embed")
CFG = {name: {c: oid(f"cfg.{name}.{c}") for c in ("Debug", "Release")} for name in ("project", "app", "widget", "uitests")}
CFGLIST = {name: oid(f"cfglist.{name}") for name in ("project", "app", "widget", "uitests")}

common_project = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
    "COPY_PHASE_STRIP": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": args.deployment_target,
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "MTL_FAST_MATH": "YES",
    "SDKROOT": "iphoneos",
    "SWIFT_VERSION": "5.0",
}
project_debug = dict(common_project, **{
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
})
project_release = dict(common_project, **{
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": "NO",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "VALIDATE_PRODUCT": "YES",
})

app = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_ENTITLEMENTS": "Skyday/Skyday.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": args.team,
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": "Skyday/Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Skyday",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.productivity",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": APP_ID,
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
    "SUPPORTS_MACCATALYST": "NO",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "1",
}
widget = {
    "CODE_SIGN_ENTITLEMENTS": "SkydayWidget/SkydayWidget.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": args.team,
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": "SkydayWidget/Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Skyday",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": WIDGET_ID,
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SKIP_INSTALL": "YES",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "TARGETED_DEVICE_FAMILY": "1",
}
uitests = {
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": args.team,
    "GENERATE_INFOPLIST_FILE": "YES",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": UITEST_ID,
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
    "SWIFT_EMIT_LOC_STRINGS": "NO",
    "TARGETED_DEVICE_FAMILY": "1",
    "TEST_TARGET_NAME": "Skyday",
}

configs = {
    "project": (project_debug, project_release),
    "app": (app, app),
    "widget": (widget, widget),
    "uitests": (uitests, uitests),
}

out = []
w = out.append
w("// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 77;\n\tobjects = {\n\n")

w("/* Begin PBXBuildFile section */\n")
w(f"\t\t{BF_KIT_APP} /* SkydayKit in Frameworks */ = {{isa = PBXBuildFile; productRef = {PKGDEP_APP} /* SkydayKit */; }};\n")
w(f"\t\t{BF_KIT_WIDGET} /* SkydayKit in Frameworks */ = {{isa = PBXBuildFile; productRef = {PKGDEP_WIDGET} /* SkydayKit */; }};\n")
w(f"\t\t{BF_EMBED_APPEX} /* SkydayWidgetExtension.appex in Embed Foundation Extensions */ = {{isa = PBXBuildFile; fileRef = {PRODUCT_WIDGET} /* SkydayWidgetExtension.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};\n")
w("/* End PBXBuildFile section */\n\n")

w("/* Begin PBXContainerItemProxy section */\n")
w(f"\t\t{PROXY_WIDGET} /* PBXContainerItemProxy */ = {{\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = {PROJECT} /* Project object */;\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = {T_WIDGET};\n\t\t\tremoteInfo = SkydayWidgetExtension;\n\t\t}};\n")
w(f"\t\t{PROXY_APP} /* PBXContainerItemProxy */ = {{\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = {PROJECT} /* Project object */;\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = {T_APP};\n\t\t\tremoteInfo = Skyday;\n\t\t}};\n")
w("/* End PBXContainerItemProxy section */\n\n")

w("/* Begin PBXCopyFilesBuildPhase section */\n")
w(f"\t\t{EMBED_PHASE} /* Embed Foundation Extensions */ = {{\n\t\t\tisa = PBXCopyFilesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tdstPath = \"\";\n\t\t\tdstSubfolderSpec = 13;\n\t\t\tfiles = (\n\t\t\t\t{BF_EMBED_APPEX} /* SkydayWidgetExtension.appex in Embed Foundation Extensions */,\n\t\t\t);\n\t\t\tname = \"Embed Foundation Extensions\";\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n")
w("/* End PBXCopyFilesBuildPhase section */\n\n")

w("/* Begin PBXFileReference section */\n")
w(f"\t\t{PRODUCT_APP} /* Skyday.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Skyday.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n")
w(f"\t\t{PRODUCT_WIDGET} /* SkydayWidgetExtension.appex */ = {{isa = PBXFileReference; explicitFileType = \"wrapper.app-extension\"; includeInIndex = 0; path = SkydayWidgetExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};\n")
w(f"\t\t{PRODUCT_UITESTS} /* SkydayUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = SkydayUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};\n")
w("/* End PBXFileReference section */\n\n")

w("/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */\n")
w(f"\t\t{EXC_APP} /* Exceptions for \"Skyday\" folder in \"Skyday\" target */ = {{\n\t\t\tisa = PBXFileSystemSynchronizedBuildFileExceptionSet;\n\t\t\tmembershipExceptions = (\n\t\t\t\tInfo.plist,\n\t\t\t\tSkyday.entitlements,\n\t\t\t);\n\t\t\ttarget = {T_APP} /* Skyday */;\n\t\t}};\n")
w(f"\t\t{EXC_WIDGET} /* Exceptions for \"SkydayWidget\" folder in \"SkydayWidgetExtension\" target */ = {{\n\t\t\tisa = PBXFileSystemSynchronizedBuildFileExceptionSet;\n\t\t\tmembershipExceptions = (\n\t\t\t\tInfo.plist,\n\t\t\t\tSkydayWidget.entitlements,\n\t\t\t);\n\t\t\ttarget = {T_WIDGET} /* SkydayWidgetExtension */;\n\t\t}};\n")
w("/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */\n\n")

w("/* Begin PBXFileSystemSynchronizedRootGroup section */\n")
w(f"\t\t{SYNC_APP} /* Skyday */ = {{\n\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n\t\t\texceptions = (\n\t\t\t\t{EXC_APP} /* Exceptions for \"Skyday\" folder in \"Skyday\" target */,\n\t\t\t);\n\t\t\tpath = Skyday;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
w(f"\t\t{SYNC_UITESTS} /* SkydayUITests */ = {{\n\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n\t\t\tpath = SkydayUITests;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
w(f"\t\t{SYNC_WIDGET} /* SkydayWidget */ = {{\n\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n\t\t\texceptions = (\n\t\t\t\t{EXC_WIDGET} /* Exceptions for \"SkydayWidget\" folder in \"SkydayWidgetExtension\" target */,\n\t\t\t);\n\t\t\tpath = SkydayWidget;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
w("/* End PBXFileSystemSynchronizedRootGroup section */\n\n")

w("/* Begin PBXFrameworksBuildPhase section */\n")
for t, files in (("app", [f"{BF_KIT_APP} /* SkydayKit in Frameworks */"]), ("widget", [f"{BF_KIT_WIDGET} /* SkydayKit in Frameworks */"]), ("uitests", [])):
    inner = "".join(f"\t\t\t\t{f},\n" for f in files)
    w(f"\t\t{PH[t]['frameworks']} /* Frameworks */ = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n{inner}\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n")
w("/* End PBXFrameworksBuildPhase section */\n\n")

w("/* Begin PBXGroup section */\n")
w(f"\t\t{MAIN_GROUP} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{SYNC_APP} /* Skyday */,\n\t\t\t\t{SYNC_WIDGET} /* SkydayWidget */,\n\t\t\t\t{SYNC_UITESTS} /* SkydayUITests */,\n\t\t\t\t{PRODUCTS_GROUP} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
w(f"\t\t{PRODUCTS_GROUP} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{PRODUCT_APP} /* Skyday.app */,\n\t\t\t\t{PRODUCT_WIDGET} /* SkydayWidgetExtension.appex */,\n\t\t\t\t{PRODUCT_UITESTS} /* SkydayUITests.xctest */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
w("/* End PBXGroup section */\n\n")


def target(tid, name, key, sync, product, product_type, deps, pkgdeps, phases):
    deps_s = "".join(f"\t\t\t\t{d} /* PBXTargetDependency */,\n" for d in deps)
    pk_s = "".join(f"\t\t\t\t{p} /* SkydayKit */,\n" for p in pkgdeps)
    ph_s = "".join(f"\t\t\t\t{p},\n" for p in phases)
    pkg_block = f"\t\t\tpackageProductDependencies = (\n{pk_s}\t\t\t);\n" if pkgdeps else ""
    return (f"\t\t{tid} /* {name} */ = {{\n\t\t\tisa = PBXNativeTarget;\n"
            f"\t\t\tbuildConfigurationList = {CFGLIST[key]} /* Build configuration list for PBXNativeTarget \"{name}\" */;\n"
            f"\t\t\tbuildPhases = (\n{ph_s}\t\t\t);\n\t\t\tbuildRules = (\n\t\t\t);\n"
            f"\t\t\tdependencies = (\n{deps_s}\t\t\t);\n"
            f"\t\t\tfileSystemSynchronizedGroups = (\n\t\t\t\t{sync} /* {name if key != 'widget' else 'SkydayWidget'} */,\n\t\t\t);\n"
            f"\t\t\tname = {name};\n{pkg_block}\t\t\tproductName = {name};\n"
            f"\t\t\tproductReference = {product};\n\t\t\tproductType = \"{product_type}\";\n\t\t}};\n")


w("/* Begin PBXNativeTarget section */\n")
w(target(T_APP, "Skyday", "app", SYNC_APP, PRODUCT_APP, "com.apple.product-type.application", [DEP_WIDGET], [PKGDEP_APP],
         [f"{PH['app']['sources']} /* Sources */", f"{PH['app']['frameworks']} /* Frameworks */",
          f"{PH['app']['resources']} /* Resources */", f"{EMBED_PHASE} /* Embed Foundation Extensions */"]))
w(target(T_UITESTS, "SkydayUITests", "uitests", SYNC_UITESTS, PRODUCT_UITESTS, "com.apple.product-type.bundle.ui-testing", [DEP_APP], [],
         [f"{PH['uitests']['sources']} /* Sources */", f"{PH['uitests']['frameworks']} /* Frameworks */", f"{PH['uitests']['resources']} /* Resources */"]))
w(target(T_WIDGET, "SkydayWidgetExtension", "widget", SYNC_WIDGET, PRODUCT_WIDGET, "com.apple.product-type.app-extension", [], [PKGDEP_WIDGET],
         [f"{PH['widget']['sources']} /* Sources */", f"{PH['widget']['frameworks']} /* Frameworks */", f"{PH['widget']['resources']} /* Resources */"]))
w("/* End PBXNativeTarget section */\n\n")

w("/* Begin PBXProject section */\n")
w(f"\t\t{PROJECT} /* Project object */ = {{\n\t\t\tisa = PBXProject;\n\t\t\tattributes = {{\n\t\t\t\tBuildIndependentTargetsInParallel = 1;\n"
  f"\t\t\t\tLastSwiftUpdateCheck = 1600;\n\t\t\t\tLastUpgradeCheck = 1600;\n\t\t\t\tTargetAttributes = {{\n"
  f"\t\t\t\t\t{T_APP} = {{\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t}};\n"
  f"\t\t\t\t\t{T_UITESTS} = {{\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t\tTestTargetID = {T_APP};\n\t\t\t\t\t}};\n"
  f"\t\t\t\t\t{T_WIDGET} = {{\n\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t}};\n\t\t\t\t}};\n\t\t\t}};\n"
  f"\t\t\tbuildConfigurationList = {CFGLIST['project']} /* Build configuration list for PBXProject \"Skyday\" */;\n"
  f"\t\t\tdevelopmentRegion = en;\n\t\t\thasScannedForEncodings = 0;\n\t\t\tknownRegions = (\n\t\t\t\ten,\n\t\t\t\tBase,\n\t\t\t);\n"
  f"\t\t\tmainGroup = {MAIN_GROUP};\n\t\t\tminimizedProjectReferenceProxies = 1;\n"
  f"\t\t\tpackageReferences = (\n\t\t\t\t{LOCAL_PKG} /* XCLocalSwiftPackageReference \"Packages/SkydayKit\" */,\n\t\t\t);\n"
  f"\t\t\tpreferredProjectObjectVersion = 77;\n\t\t\tproductRefGroup = {PRODUCTS_GROUP} /* Products */;\n"
  f"\t\t\tprojectDirPath = \"\";\n\t\t\tprojectRoot = \"\";\n\t\t\ttargets = (\n\t\t\t\t{T_APP} /* Skyday */,\n"
  f"\t\t\t\t{T_WIDGET} /* SkydayWidgetExtension */,\n\t\t\t\t{T_UITESTS} /* SkydayUITests */,\n\t\t\t);\n\t\t}};\n")
w("/* End PBXProject section */\n\n")

for section, kind in (("PBXResourcesBuildPhase", "resources"), ("PBXSourcesBuildPhase", "sources")):
    w(f"/* Begin {section} section */\n")
    label = "Resources" if kind == "resources" else "Sources"
    for t in ("app", "uitests", "widget"):
        w(f"\t\t{PH[t][kind]} /* {label} */ = {{\n\t\t\tisa = {section};\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n")
    w(f"/* End {section} section */\n\n")

w("/* Begin PBXTargetDependency section */\n")
w(f"\t\t{DEP_WIDGET} /* PBXTargetDependency */ = {{\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = {T_WIDGET} /* SkydayWidgetExtension */;\n\t\t\ttargetProxy = {PROXY_WIDGET} /* PBXContainerItemProxy */;\n\t\t}};\n")
w(f"\t\t{DEP_APP} /* PBXTargetDependency */ = {{\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = {T_APP} /* Skyday */;\n\t\t\ttargetProxy = {PROXY_APP} /* PBXContainerItemProxy */;\n\t\t}};\n")
w("/* End PBXTargetDependency section */\n\n")

w("/* Begin XCBuildConfiguration section */\n")
for key, (dbg, rel) in configs.items():
    for cname, s in (("Debug", dbg), ("Release", rel)):
        w(f"\t\t{CFG[key][cname]} /* {cname} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{settings_block(s, chr(9) * 3)}\t\t\t}};\n\t\t\tname = {cname};\n\t\t}};\n")
w("/* End XCBuildConfiguration section */\n\n")

w("/* Begin XCConfigurationList section */\n")
labels = {"project": 'PBXProject "Skyday"', "app": 'PBXNativeTarget "Skyday"', "widget": 'PBXNativeTarget "SkydayWidgetExtension"', "uitests": 'PBXNativeTarget "SkydayUITests"'}
for key in ("project", "app", "uitests", "widget"):
    w(f"\t\t{CFGLIST[key]} /* Build configuration list for {labels[key]} */ = {{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n"
      f"\t\t\t\t{CFG[key]['Debug']} /* Debug */,\n\t\t\t\t{CFG[key]['Release']} /* Release */,\n\t\t\t);\n"
      f"\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n")
w("/* End XCConfigurationList section */\n\n")

w("/* Begin XCLocalSwiftPackageReference section */\n")
w(f"\t\t{LOCAL_PKG} /* XCLocalSwiftPackageReference \"Packages/SkydayKit\" */ = {{\n\t\t\tisa = XCLocalSwiftPackageReference;\n\t\t\trelativePath = Packages/SkydayKit;\n\t\t}};\n")
w("/* End XCLocalSwiftPackageReference section */\n\n")

w("/* Begin XCSwiftPackageProductDependency section */\n")
for pid in (PKGDEP_APP, PKGDEP_WIDGET):
    w(f"\t\t{pid} /* SkydayKit */ = {{\n\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tproductName = SkydayKit;\n\t\t}};\n")
w("/* End XCSwiftPackageProductDependency section */\n")

w(f"\t}};\n\trootObject = {PROJECT} /* Project object */;\n}}\n")

proj_dir = os.path.join(ROOT, "Skyday.xcodeproj")
os.makedirs(os.path.join(proj_dir, "xcshareddata", "xcschemes"), exist_ok=True)
with open(os.path.join(proj_dir, "project.pbxproj"), "w") as f:
    f.write("".join(out))

# Shared scheme: builds the app (and embedded widget); tests run SkydayKit unit tests + UI tests.
def ref(blueprint, buildable, name, container="container:Skyday.xcodeproj"):
    return (f'            <BuildableReference\n               BuildableIdentifier = "primary"\n               BlueprintIdentifier = "{blueprint}"\n'
            f'               BuildableName = "{buildable}"\n               BlueprintName = "{name}"\n               ReferencedContainer = "{container}">\n            </BuildableReference>\n')

app_ref = ref(T_APP, "Skyday.app", "Skyday")
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
{app_ref}         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
{ref("SkydayKitTests", "SkydayKitTests", "SkydayKitTests", "container:Packages/SkydayKit")}         </TestableReference>
         <TestableReference
            skipped = "NO">
{ref(T_UITESTS, "SkydayUITests.xctest", "SkydayUITests")}         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
{app_ref}      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
{app_ref}      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''
with open(os.path.join(proj_dir, "xcshareddata", "xcschemes", "Skyday.xcscheme"), "w") as f:
    f.write(scheme)

# Keep entitlements' App Group in sync with the bundle prefix.
group = f"group.{APP_ID}"
for path in ("Skyday/Skyday.entitlements", "SkydayWidget/SkydayWidget.entitlements"):
    full = os.path.join(ROOT, path)
    text = open(full).read()
    text = re.sub(r"<string>group\.[^<]+</string>", f"<string>{group}</string>", text)
    open(full, "w").write(text)
support = os.path.join(ROOT, "Packages/SkydayKit/Sources/SkydayKit/Support/Support.swift")
text = open(support).read()
text = re.sub(r'public static let appGroup = "[^"]+"', f'public static let appGroup = "{group}"', text)
open(support, "w").write(text)

print(f"Wrote Skyday.xcodeproj (bundle {APP_ID}, app group {group}, team '{args.team or 'unset'}')")
