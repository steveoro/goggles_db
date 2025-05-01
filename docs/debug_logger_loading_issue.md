# Debugging ActiveSupport Logger Loading Issue in GogglesDB

This document details the debugging process for an `uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger` error encountered in the `goggles_db` Rails Engine project (and previously in `goggles_admin2`).

## Problem Description

When using `activesupport` version `6.1.7.10` (often pulled in by a `bundle update` or standard Rails dependency `~> 6.1.7`), running standard Rails commands like `rails console`, `rails db:migrate`, or other tasks fails with the following error:

```
/path/to/gems/activesupport-6.1.7.10/lib/active_support/logger_thread_safe_level.rb:16:in `<module:LoggerThreadSafeLevel>': uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger (NameError)

    Logger::Severity.constants.each do |severity|
    ^^^^^^
```

This indicates that the standard Ruby `Logger` constant (specifically `Logger::Severity`) is not defined or accessible when the `logger_thread_safe_level.rb` file is loaded by ActiveSupport.

## Environment

*   Ruby: 3.1.4
*   Rails: ~> 6.1.7
*   ActiveSupport (Problematic): 6.1.7.10
*   ActiveSupport (Working): 6.1.7.8
*   Project: `goggles_db` (Rails Engine, also seen in `goggles_admin2` which depends on `goggles_db`)

## Debugging Steps & Findings

1.  **Identify ActiveSupport Version**: Confirmed via `Gemfile.lock` and error message that `activesupport 6.1.7.10` was being used.
2.  **Analyze Error Location**: The error occurs at line 15 in `activesupport-6.1.7.10/lib/active_support/logger_thread_safe_level.rb`, where `Logger::Severity.constants` is accessed.
3.  **Hypothesis: Load Order Issue**: The core issue seems to be that the standard `logger` library isn't loaded before ActiveSupport tries to use its constants.
4.  **Attempt 1: Explicit `require 'active_support/railtie'`**: Added `require 'active_support/railtie'` to `spec/dummy/config/application.rb`. **Result: Failed.** Error persisted.
5.  **Attempt 2: Disable Spring**: Ran commands with `DISABLE_SPRING=1`. **Result: Failed.** Error persisted, indicating Spring preloading wasn't the primary cause.
6.  **Attempt 3: Explicit `require 'logger'`**: Added `require 'logger'` at the top of `spec/dummy/config/boot.rb` (before Bundler setup). **Result: Failed.** Error persisted.
7.  **Attempt 4: Pin ActiveSupport Version**: Added `gem 'activesupport', '6.1.7.8'` to the main `goggles_db/Gemfile` and ran `bundle install`. **Result: Success!** The error disappeared, and Rails commands executed correctly.

## Conclusion & Workaround (Locally Patched)

**CRITICAL UPDATE:** The success of pinning to `6.1.7.8` is *only* due to a **manual monkey-patch applied locally** to the installed gem source (`.../gems/activesupport-6.1.7.8/lib/active_support/logger.rb`). In this patch, the line `require "logger"` was moved from its original position (around line 5) to the top of the file (line 3).

This patch forces the standard Ruby logger to load before ActiveSupport attempts to use its constants, thus circumventing the error **locally**.

**Implications:**

*   **Temporary Fix:** This is NOT a real solution. Any `bundle install` on a clean environment (like CI, a new machine, or even after `gem pristine activesupport`) will revert the patch, and the error will return.
*   **CI Failures:** This explains why builds fail on CircleCI during migration steps – the CI environment uses the original, unpatched gem.
*   **Root Cause:** The underlying issue is a regression or load-order conflict introduced between `activesupport` versions `6.1.7.8` (unpatched) and `6.1.7.10`, particularly problematic within the context of this Rails Engine (`goggles_db`) and its dependent applications (`goggles_admin2`).

**The current effective *local* workaround is:**

1.  Pin `activesupport` to version `6.1.7.8` in the `Gemfile`:
    ```ruby
    # Gemfile
    gem 'activesupport', '6.1.7.8'
    ```
2.  Run `bundle install`.
3.  **Manually edit** the installed gem file `.../gems/activesupport-6.1.7.8/lib/active_support/logger.rb` and move `require "logger"` to the top (below `frozen_string_literal`).

This resolves the immediate issue *locally* but is unsustainable. Future investigation must address the root cause:

*   Comparing the changes between `activesupport` 6.1.7.8 and 6.1.7.10, focusing on logger-related files and initialization.
*   **Strongly consider accelerating the upgrade to Rails 7/8.** This is likely the most robust solution, potentially resolving this underlying load order sensitivity (as planned for other reasons - see Memory `f7ed1f05-ef59-491f-9596-0a7d6e952a2c`).
*   Examining if any other gems specifically conflict with `activesupport 6.1.7.10`'s loading process within an engine.
