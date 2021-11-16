// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_dynamic_links;

/// Firebase Dynamic Links API.
///
/// You can get an instance by calling [FirebaseDynamicLinks.instance].
class FirebaseDynamicLinks extends FirebasePluginPlatform {
  FirebaseDynamicLinks._({required this.app})
      : super(app.name, 'plugins.flutter.io/firebase_dynamic_links');

  static final Map<String, FirebaseDynamicLinks> _cachedInstances = {};

  /// Returns an instance using the default [FirebaseApp].
  static FirebaseDynamicLinks get instance {
    return FirebaseDynamicLinks.instanceFor(
      app: Firebase.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp].
  static FirebaseDynamicLinks instanceFor({required FirebaseApp app}) {
    if (_cachedInstances.containsKey(app.name)) {
      return _cachedInstances[app.name]!;
    }
    //TODO notify user or even throw error that default only for web and iOS??

    FirebaseDynamicLinks newInstance = FirebaseDynamicLinks._(app: app);
    _cachedInstances[app.name] = newInstance;

    return newInstance;
  }

  // Cached and lazily loaded instance of [FirebaseDynamicLinksPlatform] to avoid
  // creating a [MethodChannelFirebaseDynamicLinks] when not needed or creating an
  // instance with the default app before a user specifies an app.
  FirebaseDynamicLinksPlatform? _delegatePackingProperty;

  FirebaseDynamicLinksPlatform get _delegate {
    return _delegatePackingProperty ??=
        FirebaseDynamicLinksPlatform.instanceFor(app: app);
  }

  /// The [FirebaseApp] for this current [FirebaseDynamicLinks] instance.
  FirebaseApp app;

  /// Attempts to retrieve the dynamic link which launched the app.
  ///
  /// This method always returns a Future. That Future completes to null if
  /// there is no pending dynamic link or any call to this method after the
  /// the first attempt.
  Future<PendingDynamicLinkData?> getInitialLink() async {
    return _delegate.getInitialLink();
  }

  /// Determine if the app has a pending dynamic link and provide access to
  /// the dynamic link parameters. A pending dynamic link may have been
  /// previously captured when a user clicked on a dynamic link, or
  /// may be present in the dynamicLinkUri parameter. If both are present,
  /// the previously captured dynamic link will take precedence. The captured
  /// data will be removed after first access.
  Future<PendingDynamicLinkData?> getDynamicLink(Uri url) async {
    return _delegate.getDynamicLink(url);
  }

  /// Listen to a stream for the latest dynamic link events
  Stream<PendingDynamicLinkData?> onLink() {
    return _delegate.onLink();
  }

  Future<ShortDynamicLink> shortenUrl(Uri url,
      [DynamicLinkParametersOptions? options]) async {
    return _delegate.shortenUrl(url, options);
  }

  Future<Uri> buildUrl(DynamicLinkParameters parameters) async {
    return _delegate.buildUrl(parameters);
  }

  Future<ShortDynamicLink> buildShortLink(
      DynamicLinkParameters parameters) async {
    return _delegate.buildShortLink(parameters);
  }
}
