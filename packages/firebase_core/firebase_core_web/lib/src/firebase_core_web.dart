// ignore_for_file: unsafe_html
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_web;

/// Defines a Firebase service by name.
class FirebaseWebService {
  /// The name which matches the Firebase JS Web SDK postfix.
  String name;

  /// Creates a new [FirebaseWebService].
  FirebaseWebService(this.name);
}

/// The entry point for accessing Firebase.
///
/// You can get an instance by calling [FirebaseCore.instance].
class FirebaseCoreWeb extends FirebasePlatform {
  static Map<String, FirebaseWebService> _services = {};

  /// Internally registers a Firebase Service to be initialized.
  static void registerService(FirebaseWebService service) {
    _services.putIfAbsent(service.name, () => service);
  }

  /// Registers that [FirebaseCoreWeb] is the platform implementation.
  static void registerWith(Registrar registrar) {
    FirebasePlatform.instance = FirebaseCoreWeb();
  }

  bool get _isRequireJsDefined {
    return context['require'] != null;
  }

  String get _firebaseSDKVersion {
    return context['flutterfire_web_sdk_version'] ??
        supportedFirebaseJsSdkVersion;
  }

  Future<void> _injectSrcScript(String src) async {
    ScriptElement script = ScriptElement();
    script.type = 'text/javascript';
    script.src = src;
    script.async = true;
    assert(document.head != null);
    document.head!.append(script);
    await script.onLoad.first;
  }

  Future<void> _initializeCore() async {
    // If Firebase is already available, core has already been initialized
    // (or the user has added the scripts to their html file).
    if (context['firebase'] != null) {
      return;
    }

    String version = _firebaseSDKVersion;

    // This must be loaded first!
    await _injectSrcScript(
      'https://www.gstatic.com/firebasejs/$version/firebase-app.js',
    );

    await Future.wait(_services.values.map((service) {
      return _injectSrcScript(
        'https://www.gstatic.com/firebasejs/$version/firebase-${service.name}.js',
      );
    }));
  }

  /// In development (or manually added), requirejs is added to the window.
  ///
  /// The Firebase JS SDKs define their modules via requirejs (if it exists),
  /// otherwise they attach to the window. This code loads Firebase from
  /// requirejs manually attaches it to the window.
  Future<void> _initializeCoreRequireJs() async {
    // If Firebase is already available, core has already been initialized
    // (or the user has added the scripts to their html file).
    if (context['firebase'] != null) {
      return;
    }

    String version = _firebaseSDKVersion;

    // In dev, requirejs is loaded in
    JsObject require = JsObject.fromBrowserObject(context['require']);
    require.callMethod('config', [
      JsObject.jsify({
        'paths': {
          '@firebase/app':
              'https://www.gstatic.com/firebasejs/$version/firebase-app',
          '@firebase/analytics':
              'https://www.gstatic.com/firebasejs/$version/firebase-analytics',
          '@firebase/app-check':
              'https://www.gstatic.com/firebasejs/$version/firebase-app-check',
          '@firebase/auth':
              'https://www.gstatic.com/firebasejs/$version/firebase-auth',
          '@firebase/firestore':
              'https://www.gstatic.com/firebasejs/$version/firebase-firestore',
          '@firebase/functions':
              'https://www.gstatic.com/firebasejs/$version/firebase-functions',
          '@firebase/messaging':
              'https://www.gstatic.com/firebasejs/$version/firebase-messaging',
          '@firebase/storage':
              'https://www.gstatic.com/firebasejs/$version/firebase-storage',
          '@firebase/database':
              'https://www.gstatic.com/firebasejs/$version/firebase-database',
          '@firebase/remote-config':
              'https://www.gstatic.com/firebasejs/$version/firebase-remote-config',
          '@firebase/performance':
              'https://www.gstatic.com/firebasejs/$version/firebase-performance',
        },
      })
    ]);

    Completer completer = Completer();

    List<String> services = ['@firebase/app'];
    _services.values.forEach((service) {
      services.add('@firebase/${service.name}');
    });

    context.callMethod('require', [
      JsObject.jsify(services),
      (app) {
        context['firebase'] = app;
        completer.complete();
      }
    ]);

    await completer.future;
  }

  /// Returns all created [FirebaseAppPlatform] instances.
  @override
  List<FirebaseAppPlatform> get apps {
    return firebase.apps.map(_createFromJsApp).toList(growable: false);
  }

  /// Initializes a new [FirebaseAppPlatform] instance by [name] and [options] and returns
  /// the created app. This method should be called before any usage of FlutterFire plugins.
  ///
  /// The default app instance cannot be initialized here and should be created
  /// using the platform Firebase integration.
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    if (!_isRequireJsDefined) {
      await _initializeCore();
    } else {
      await _initializeCoreRequireJs();
    }

    try {
      firebase.SDK_VERSION;
    } catch (e) {
      if (e
          .toString()
          .contains("Cannot read property 'SDK_VERSION' of undefined")) {
        throw coreNotInitialized();
      }
    }

    assert(() {
      if (firebase.SDK_VERSION != supportedFirebaseJsSdkVersion) {
        // ignore: avoid_print
        print(
          '''
            WARNING: FlutterFire for Web is explicitly tested against Firebase JS SDK version "$supportedFirebaseJsSdkVersion"
            but your currently specifying "${firebase.SDK_VERSION}" by either the imported Firebase JS SDKs in your web/index.html
            file or by providing an override - this may lead to unexpected issues in your application. It is recommended that you change all of the versions of the
            Firebase JS SDK version "$supportedFirebaseJsSdkVersion":

            If you override the version manully:
              change:
                <script>window.flutterfire_web_sdk_version = '${firebase.SDK_VERSION}';</script>
              to:
                <script>window.flutterfire_web_sdk_version = '$supportedFirebaseJsSdkVersion';</script>

            If you import the Firebase scripts in index.html, instead allow FlutterFire to manage this for you by removing
            any Firebase scripts in your web/index.html file:
                e.g. remove: <script src="https://www.gstatic.com/firebasejs/${firebase.SDK_VERSION}/firebase-app.js"></script>
          ''',
        );
      }

      return true;
    }());

    // If there are no apps, and the user has not provided options,
    // then we need to throw an error. The user must do this in the index.html
    // file OR provide some options.
    if (firebase.apps.isEmpty && options == null) {
      throw coreNotInitialized();
    }

    firebase.App? app;

    if (name == null || name == defaultFirebaseAppName) {
      bool defaultAppExists = false;

      try {
        app = firebase.app();
        defaultAppExists = true;
      } catch (e) {
        // noop
      }

      if (defaultAppExists) {
        if (options != null) {
          // If there is a default app already and the user provided options do a soft
          // check to see if options are roughly identical (so we don't unnecessarily
          // throw on minor differences such as platform specific keys missing,
          // e.g. hot reloads/restarts).
          if (options.apiKey != app!.options.apiKey ||
              options.databaseURL != app.options.databaseURL ||
              options.storageBucket != app.options.storageBucket) {
            // Options are different; throw.
            throw duplicateApp(defaultFirebaseAppName);
          }
        }
      } else {
        assert(
          options != null,
          'FirebaseOptions cannot be null when creating the default app.',
        );

        // At this point, there is no default app so we need to create it with
        // the users options.
        app = firebase.initializeApp(
          apiKey: options!.apiKey,
          authDomain: options.authDomain,
          databaseURL: options.databaseURL,
          projectId: options.projectId,
          storageBucket: options.storageBucket,
          messagingSenderId: options.messagingSenderId,
          appId: options.appId,
          measurementId: options.measurementId,
        );
      }
    }

    // Ensure the user has provided options for secondary apps.
    if (name != null && name != defaultFirebaseAppName) {
      assert(
        options != null,
        'FirebaseOptions cannot be null when creating a secondary Firebase app.',
      );

      try {
        app = firebase.initializeApp(
          name: name,
          apiKey: options!.apiKey,
          authDomain: options.authDomain,
          databaseURL: options.databaseURL,
          projectId: options.projectId,
          storageBucket: options.storageBucket,
          messagingSenderId: options.messagingSenderId,
          appId: options.appId,
          measurementId: options.measurementId,
        );
      } catch (e) {
        if (_getJSErrorCode(e) == 'app/duplicate-app') {
          throw duplicateApp(name);
        }

        throw _catchJSError(e);
      }
    }

    return _createFromJsApp(app!);
  }

  /// Returns a [FirebaseAppPlatform] instance.
  ///
  /// If no name is provided, the default app instance is returned.
  /// Throws if the app does not exist.
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    firebase.App app;

    try {
      app = firebase.app(name);
    } catch (e) {
      if (e.toString().contains("Cannot read property 'app' of undefined")) {
        throw coreNotInitialized();
      }

      if (_getJSErrorCode(e) == 'app/no-app') {
        throw noAppExists(name);
      }

      throw _catchJSError(e);
    }

    return _createFromJsApp(app);
  }
}
