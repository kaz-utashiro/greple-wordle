# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

App::Greple::wordle is a Perl module that implements a Wordle game as a greple module. It's a CPAN-distributed package that provides an interactive command-line Wordle implementation with regex-based correctness checking.

## Development Commands

### Setup and Dependencies
```bash
cpanm --installdeps .          # Install dependencies from cpanfile
```

### Building
```bash
perl Build.PL                  # Generate Build script
./Build                        # Build the distribution
```

### Testing
```bash
prove -lvr t                   # Run all tests (same as CI)
./Build test                   # Alternative test runner
minil test                     # Run full test suite (mirrors CI)
```

### Running Locally
```bash
perl -Ilib -S greple -Mwordle  # Run the game using local code
perl -Ilib -S greple -Mwordle --series=0 --index=0  # Test with specific answer
```

### Release Process
```bash
minil test                     # Verify all tests pass
# Update $VERSION in lib/App/Greple/wordle.pm
# Update Changes file
minil release                  # Tag and release
```

## Architecture

### Module Structure

The codebase follows a clear separation of concerns:

- **lib/App/Greple/wordle.pm**: Main entry point and CLI orchestration
  - Handles option parsing via Getopt::EX::Hashed
  - Dynamically loads dataset modules based on --data option
  - Manages interactive game loop and user input
  - Integrates with greple's pattern matching system
  - Implements command parsing (hint, uniq, filtering)

- **lib/App/Greple/wordle/game.pm**: Game state and logic
  - Tracks attempts and answer
  - Generates regex patterns for hints
  - Produces colored output (keymap, hints, result squares)
  - Uses Mo for minimal object system

- **lib/App/Greple/wordle/util.pm**: Shared utilities
  - Currently contains `uniqword()` for filtering unique-character words

- **lib/App/Greple/wordle/ORIGINAL.pm**: Original Wordle dataset
  - Exports `@WORDS` (all valid words) and `@HIDDEN` (answer list)
  - Contains classic Wordle word list from original game
  - Uses Data::Section::Simple for data storage

- **lib/App/Greple/wordle/NYT.pm**: New York Times Wordle dataset
  - Exports `@WORDS` (all valid words) and `@HIDDEN` (answer list)
  - Contains NYT Wordle word list (answers until the date in its comment;
    later answers are fetched at runtime by `fetch_answer`)
  - Uses Data::Section::Simple for data storage

- **lib/App/Greple/wordle/word_all.pm**: Legacy word dictionary (deprecated)
  - Kept for backward compatibility
  - Exports `@word_all` array and `%word_all` hash

- **lib/App/Greple/wordle/word_hidden.pm**: Legacy answer list (deprecated)
  - Kept for backward compatibility
  - Shuffled using series number as seed

### Integration with greple

The module leverages greple's pattern matching engine:
- Game colors (green/yellow/black) map to regex patterns passed to greple
- `--interactive` mode hooks into greple's processing pipeline via `--begin`, `--end`, `--epilogue`
- Uses greple's colormap system for terminal output
- Pattern generation in `patterns()` creates position-aware regex

### Option Handling

Uses Getopt::EX::Hashed for declarative option definitions:
- Options defined with `has` macro including specs, defaults, actions
- `--data` option selects dataset (default: ORIGINAL)
- Custom action for `--compat` that sets series to 0
- Supports environment variables (`WORDLE_ANSWER`, `WORDLE_INDEX`)
- Negative index values are relative to current day
- Dataset modules are dynamically loaded via `eval "use $pkg"`

### Color and Display

Three distinct color systems:
1. **Game colors**: Green (correct position), Yellow (wrong position), Black (not in word)
2. **Keymap display**: Shows tried letters with their status
3. **Result squares**: Unicode emoji squares for sharing results

## Key Technical Details

### Answer Selection
- Default index calculated from days since 2021-06-19
- Dataset selected via `--data` option (ORIGINAL or NYT)
- Series 0 matches original Wordle answers
- Non-zero series shuffles answers using seed for reproducibility
- Out-of-range index triggers random selection with warning
- Supports manual answer via `--answer` or `WORDLE_ANSWER` env var

### Command System
Commands can be chained with spaces:
- `hint` / `h`: Filter to possible words based on attempts
- `uniq` / `u`: Filter to words with unique characters
- `=chars`: Include only words containing all chars
- `!chars`: Exclude words containing any chars
- `!!`: Recall last command result
- Any regex: Custom filtering

### Hint Generation Algorithm (game.pm:_hint)
1. Tracks confirmed positions (green) and excluded chars per position
2. Builds lookahead assertions for required chars
3. Creates negative lookahead for excluded chars
4. Combines into single regex pattern for word filtering

## Technical Requirements

- **Perl version**: v5.18.2 minimum (declared in cpanfile)
- **Build system**: Module::Build::Tiny (via minil)
- **Key dependencies**:
  - App::Greple 8.58+
  - Getopt::EX 2.1.6+
  - Getopt::EX::Hashed 1.05+
  - Mo (minimal object system)
  - Data::Section::Simple (for dataset storage)
  - Date::Calc, Text::VisualWidth::PP

## Testing Notes

- CI tests against Perl 5.18, 5.28, 5.30, 5.36, 5.38, 5.40
- Test file naming: `NN_description.t` pattern in `t/` directory
- Currently only has compilation test (`00_compile.t`)
- Use `use lib 'lib';` in new tests to access in-tree modules

## Updating NYT Wordle Data

With `--data=NYT --compat`, an answer which is not in `NYT.pm` is fetched
at runtime by `App::Greple::wordle::NYT::fetch_answer`, so updating the data
is optional.  To add answers up to yesterday to the dataset:

```bash
tools/update-nyt               # append answers to lib/App/Greple/wordle/NYT.pm
git diff --stat                # only the HIDDEN section and the date comment change
prove -lr t
```

### Notes

- Answers come from `https://www.nytimes.com/svc/wordle/v2/YYYY-MM-DD.json`
  (fields `solution`, `print_date`, and `days_since_launch` for most dates).
  Requests are spaced 0.5 seconds apart.
- `NYT.pm` keeps data with Data::Section::Simple: `@@ WORDS` (valid guesses)
  and `@@ HIDDEN` (answers in chronological order; index = days since
  2021-06-19, #0 = cigar), 13 words per line with a trailing space.
- The script never fetches today's answer and does not print answers.  If a
  fetch fails, answers fetched so far are written; run it again to continue.
- Adding answers changes the shuffled answer order for series other than 0.
- Third-party answer lists (WordFinder, fiveforks.com, wordlehints.co.uk)
  contain answers NYT later replaced (e.g. #284 harry → stove) or other
  errors; use the NYT API as the reference.
- The valid word list came from https://github.com/alex1770/wordle
  (`wordlist_all`).  `tools/update-nyt` warns when an answer is not in
  `@@ WORDS`.
