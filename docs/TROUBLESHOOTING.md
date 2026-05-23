# WatchPod Troubleshooting

> Pattern-recognition guide. Symptom → Root cause → Fix.

## PATTERN: Build fails with SSL/network error

```
Symptom: SSLHandshakeException / Connection refused / SocketException
ROOT CAUSE (90%): Clash (mihomo) proxy is dead
  → Check: systemctl --user is-active mihomo
  → Fix: systemctl --user start mihomo
  → Verify: curl -sI -x http://127.0.0.1:7890 https://google.com

If proxy is alive:
  → Check NO_PROXY: storage.googleapis.com,download.flutter.io in ~/.bashrc_flutter
  → Check Clash rules: DOMAIN-SUFFIX,storage.googleapis.com,DIRECT
```

## PATTERN: APK runs but can't make network requests

```
Symptom: DioException [connection error] / Failed host lookup
Root cause: Release APK missing INTERNET permission
  → Manifests comparison:
    debug/AndroidManifest.xml ✅, profile/AndroidManifest.xml ✅
    main/AndroidManifest.xml ❌ (release build only reads this)
  → Fix: Add <uses-permission android:name="android.permission.INTERNET"/>
    to android/app/src/main/AndroidManifest.xml
```

## PATTERN: RSS subscription fails

| Error pattern | Cause | Check |
|--------------|-------|-------|
| `XmlParseException: Expected a single root element` | URL returns HTML, not XML | `curl $url \| head -c 200` |
| `DioException [bad response]: 404` | RSS URL expired | Pre-build check script |
| `SocketException: Failed host lookup` | Domain dead / DNS failure | `nslookup $domain` |

Pre-build check tests all 5 preset feeds: `bash tools/pre_build_check.sh`

## PATTERN: Build killed mid-way

```
Symptom: Process disappears, no error message
Root cause: `pkill -9 -f GradleDaemon` pattern too broad → kills mihomo + Gateway
Fix: Never use `pkill -9 -f GradleDaemon`. Use Hermes `notify_on_complete=true`.
```

## PATTERN: Gradle OOM / Gateway shutdown

```
Symptom: Gateway shutting down message → build fails → Clash dies
Root cause: Gradle Xmx too high (was 8G, now 2G) → 4GB system OOM → systemd kills Gateway
Fix: Keep org.gradle.jvmargs=-Xmx2G in android/gradle.properties
Check: grep -i xmx android/gradle.properties → should show -Xmx2G
```

## PATTERN: Data loss / empty subscriptions

```
Symptom: App shows "No subscriptions" when there should be data
Root cause: StorageService silently returns [] on JSON parse failure
  → Check: ls -la ~/watchpod-data/subscriptions.json
  → Validate JSON: dart -e "import 'dart:convert'; import 'dart:io';
    print(jsonDecode(File('~/watchpod-data/subscriptions.json').readAsStringSync()) is List);"
  → This is known tech debt: no schema migration. Field additions break old JSON.
```

## PATTERN: After v1.1 update, tags missing

```
Cause: Tags are set at subscription time (not retroactive).
Previous subscriptions have no tags. Must re-add or implement post-hoc tag editing.
```
