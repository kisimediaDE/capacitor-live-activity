# Changelog

## [7.0.1] - 2025-07-08

### Added

- **Dismissal Policy Support:** Added optional `dismissalDate` parameter to `endActivity` to set a specific dismissal time for Live Activities. ([#1](https://github.com/kisimediaDE/capacitor-live-activity/pull/1) by [marciopinho](https://github.com/marciopinho))

### Changed

- **Moved `GenericAttributes.swift`:** Relocated `GenericAttributes.swift` to `ios/Sources/LiveActivityPlugin/Shared` to fix `verify:ios` build errors and ensure SwiftPM compatibility.
- **Updated DevDependencies:** Upgraded various devDependencies in `package.json`, including:
  - `@capacitor/core` → ^7.4.1
  - `@capacitor/ios` → ^7.4.1
  - `prettier` → ^3.6.2
  - `prettier-plugin-java` → ^2.7.1
  - `rollup` → ^4.44.2

### Fixed

- **Build Verification:** Resolved missing type errors by ensuring `GenericAttributes` is in the build target scope for iOS plugin verification.

---

### Upgrade Notes

No breaking changes. Ensure you run:

```bash
npx cap sync
```

## [7.0.0] - 2025-06-10

Initial release with full iOS Live Activities support.
