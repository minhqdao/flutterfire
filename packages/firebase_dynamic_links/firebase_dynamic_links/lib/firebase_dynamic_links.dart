// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library firebase_dynamic_links;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links_platform_interface/firebase_dynamic_links_platform_interface.dart';
export 'package:firebase_dynamic_links_platform_interface/firebase_dynamic_links_platform_interface.dart'
    show
        AndroidParameters,
        DynamicLinkParameters,
        DynamicLinkParametersOptions,
        FirebaseDynamicLinksPlatform,
        GoogleAnalyticsParameters,
        IosParameters,
        ITunesConnectAnalyticsParameters,
        NavigationInfoParameters,
        PendingDynamicLinkData,
        PendingDynamicLinkDataAndroid,
        PendingDynamicLinkDataIOS,
        ShortDynamicLink,
        ShortDynamicLinkPathLength,
        SocialMetaTagParameters;
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

part 'src/firebase_dynamic_links.dart';