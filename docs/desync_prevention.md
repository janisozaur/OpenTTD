# Desync Prevention Guide (Dos and Don'ts)

OpenTTD's multiplayer is based on a deterministic lockstep architecture. Every client must reach the exact same game state after executing the same set of commands. Any deviation, however small, will eventually lead to a desync.

## Random Number Generation (RNG)

### Dos
- Use `Random()` for anything that affects the game state (e.g., vehicle movement, industry production, map generation).
- Use `InteractiveRandom()` for things that are strictly local to a client (e.g., UI animations, choosing a random sound effect to play, initial viewport position).
- Use `Chance16()`, `RandomRange()`, etc., which are wrappers around the synced RNG when appropriate.

### Don'ts
- **Never** call `Random()` inside a block that is only executed on some clients. This includes:
    - Blocks guarded by `IsLocalCompany()`.
    - UI-related code.
    - Code that depends on `_settings_client`.
- **Never** use `Random()` in a statement with other `Random()` calls or functions that might call `Random()`. The order of evaluation of function parameters is undefined in C++.
    - Bad: `DoSomething(Random(), Random());`
    - Good: `uint32 r1 = Random(); uint32 r2 = Random(); DoSomething(r1, r2);`
- **Never** call `Random()` inside a `DEBUG()` statement or any code that can be compiled out or disabled via log levels.

## Containers and Iteration

### Dos
- Use `std::map`, `std::set`, or `std::vector` when you need to iterate over a collection of game-state objects.
- Use `std::flat_set` or `std::flat_map` for better performance with smaller collections while maintaining deterministic order.

### Don'ts
- **Never** iterate over `std::unordered_map` or `std::unordered_set` in code that affects the game state. The iteration order depends on hash values and bucket distribution, which can vary between platforms, compiler versions, and even different runs of the same binary.
    - If you must use these for performance, you **must not** let the iteration order affect the game state (e.g., don't use it to choose the "first" available industry).

## Floating Point Arithmetic

### Dos
- Use fixed-point arithmetic for game-state calculations. OpenTTD has several fixed-point types and constants (e.g., in `tgp.cpp`, `landscape.cpp`).
- If you must use floating point for non-critical things, ensure they don't leak into the game state.

### Don'ts
- **Avoid** `float` and `double` in game-state calculations. Different CPUs and compilers can produce slightly different results for floating point operations (especially transcendental functions like `sin`, `cos`, `pow`, and `sqrt`). These tiny differences will cause desyncs.

## Savegame and Game State

### Dos
- Ensure every variable that affects the game's progression is saved and loaded in the appropriate `ChunkHandler`.
- Use `AfterLoad` functions to correctly reconstruct any caches that are not stored in the savegame.
- Verify that `AfterLoad` logic is deterministic and doesn't depend on local client state.

### Don'ts
- **Don't** assume that because a variable is "only for drawing" it doesn't need to be synced. If that variable is later used in a calculation that affects the game state, it will cause a desync.

## Command Execution

### Dos
- Ensure commands are "pure" during their test-run (when `DoCommandFlag::Execute` is NOT set). They should only check for validity and calculate cost.
- Perform all state changes only when `DoCommandFlag::Execute` is set.

### Don'ts
- **Don't** modify global variables or pool items during the test-run of a command.
- **Don't** call `Random()` during the test-run of a command unless you are absolutely sure it's handled correctly by the command system (which generally isn't the case).
