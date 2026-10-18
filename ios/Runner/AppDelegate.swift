@preconcurrency import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, @preconcurrency FlutterImplicitEngineDelegate {
  private var intelligence: FieldbookIntelligence?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    intelligence = FieldbookIntelligence(messenger: engineBridge.applicationRegistrar.messenger())
  }
}
