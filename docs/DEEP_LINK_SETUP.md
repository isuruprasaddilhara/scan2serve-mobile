# Deep Link Setup — scan2serve-1.web.app

## What was fixed

| # | Problem | Fix |
|---|---------|-----|
| 1 | `scan2serve-1.web.app` was not in `_allowedHosts()` | Added to the allow-list in `menu_deep_link.dart` |
| 2 | Root path `/` failed the `path.contains('menu')` guard | Path check now also accepts `/` and empty path |
| 3 | Flutter Web reads `window.location`, not `app_links` stream | Added `kIsWeb` branch that calls `Uri.base` directly |
| 4 | `main()` called deep-link setup after `runApp()` — too late for web | Web branch now runs `await startMenuDeepLinkListeners()` **before** `runApp()` |
| 5 | `AndroidManifest.xml` had no intent-filter for `scan2serve-1.web.app` | Added a new `<intent-filter android:autoVerify="true">` for that host |

## Required: assetlinks.json for Android App Links

For Android to open the APK automatically (instead of showing a chooser), you
must host a Digital Asset Links file at:

```
https://scan2serve-1.web.app/.well-known/assetlinks.json
```

Content (replace SHA-256 with your release keystore fingerprint):

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.scan2serve",
    "sha256_cert_fingerprints": [
      "AA:BB:CC:DD:..."
    ]
  }
}]
```

Get your SHA-256 fingerprint:
```
keytool -list -v -keystore your-release-key.jks
```

For Firebase Hosting, add a `rewrites` rule or place the file under `public/.well-known/assetlinks.json`.

## URL formats supported

| URL | Platform |
|-----|----------|
| `https://scan2serve-1.web.app/?table_no=2&token=…` | Web + Android APK |
| `https://scan2serve.online/menu?table_no=2&token=…` | Android APK |
| `scan2serve://menu?table_no=2&token=…` | Android APK (no verification needed) |
