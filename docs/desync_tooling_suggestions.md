# Future Desync Tracing Tools and Improvements

Tracing desyncs in the field (on live servers or user machines) is challenging. Based on the analysis of OpenTTD's architecture, here are several suggestions for tools and system enhancements.

## 1. Automated Desync Report Collection

Currently, users must manually locate and attach `commands-out.log` and multiple `dmp_cmds_*.sav` files.

### Suggestion: Desync Report Bundler
Implement a feature in the game client that, upon a desync:
- Automatically bundles the relevant log file and the most recent desync savegames into a single compressed archive (e.g., `.zip` or `.tar.gz`).
- Provides a clear UI dialog to the user with a "Open Folder" or "Copy Path" button.

### Suggestion: Crash/Desync Uploader
Integrate an optional automated uploader (similar to modern crash reporters) that can send these bundles directly to a centralized server managed by the OpenTTD team (with user consent).

## 2. Server-Side Desync Detection Enhancements

### Suggestion: Continuous State Checksumming
Currently, OpenTTD uses the RNG state as a checksum. While effective, it can take a long time to diverge after a non-RNG-related state change.
- Periodically (e.g., every 100 ticks) calculate a more comprehensive (but still fast) hash of critical game state components (e.g., total company money, number of vehicles, industry production levels).
- Include this hash in the network packets.

## 3. Advanced Debugging Tools

### Suggestion: Headless State Comparator
A command-line tool that takes two savegames and performs a deep, property-by-property comparison, highlighting exactly which object and which field differ.
- This would be an improvement over the existing JSON-based comparison, as it could be specialized for the binary format and potentially much faster.

### Suggestion: Desync "Time-Travel" Replay UI
Enhance the replay functionality with a GUI that allows developers to:
- See the game state side-by-side with the replayed commands.
- "Step" through commands one by one.
- Inspect object properties in real-time during the replay.

## 4. Compile-Time and Runtime Guards

### Suggestion: Non-Deterministic Container Poisoning
In debug builds, implement a "poisoning" mechanism for `std::unordered_map` and `std::unordered_set` that randomizes the iteration order. This would help catch desyncs caused by non-deterministic iteration much earlier in development.

### Suggestion: Static Analysis for `Random()`
Add custom static analysis rules (e.g., for Clang-Tidy) that:
- Detect usage of `Random()` inside non-synced blocks (e.g., UI code).
- Warn when multiple `Random()` calls are used in the same statement.
