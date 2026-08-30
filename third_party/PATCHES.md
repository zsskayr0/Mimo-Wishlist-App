# Vendored packages

## receive_sharing_intent-1.8.1

Vendored (not pulled straight from pub.dev) for two reasons:

1. **Pinned below 1.9.0 on purpose** — 1.9.0 hardcodes `compileSdk 37` in
   its own `android/build.gradle`, and this machine's SDK only has that
   platform installed as `android-37.0` (a newer, minor-versioned Android
   SDK release naming scheme), not the plain `android-37` AGP resolves a
   bare `compileSdk 37` to. Build fails looking for a target that isn't
   there under that name.
2. **`android/build.gradle` patched** — upstream 1.8.1 declares no
   `compileOptions`, so AGP falls back to its own default Java target
   (11) for that module while this project's centrally-managed Kotlin
   plugin compiles it to JVM 17, tripping Gradle's "Inconsistent JVM
   Target Compatibility Between Java and Kotlin Tasks" check. Patched to
   pin both to 17, matching `android/app/build.gradle.kts`.

`pubspec.yaml` points `receive_sharing_intent` at this local copy via
`dependency_overrides` instead of pub.dev. Revisit (drop the vendoring,
go back to a normal pub.dev dependency) once either issue is fixed
upstream or the SDK's `android-37` naming sorts itself out locally.
