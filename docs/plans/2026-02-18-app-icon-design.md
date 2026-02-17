# App Icon Design: Growth Coin

## Overview

Personal finance app icon featuring a coin with a growing leaf, symbolizing wealth growth.

## Design Spec

### Visual Elements
- **Background**: Linear gradient #8BC34A -> #2E7D32 (top-left to bottom-right)
- **Coin ring**: White circle outline, ~40px stroke, ~720px diameter, centered
- **$ symbol**: White, bold rounded font, centered within coin
- **Leaf**: White, single leaf growing from top-right of $ sign, minimal style

### Dimensions
- 1024x1024px single size (iOS standard)
- iOS auto-clips to superellipse corners

### Three Appearances (iOS 18+)
| Appearance | Background | Foreground |
|------------|-----------|------------|
| Light (default) | Green gradient #8BC34A -> #2E7D32 | White |
| Dark | Deep green #1B5E20 solid | Light green #8BC34A |
| Tinted | System-generated from Light version | Monochrome |

## Implementation Approach

Generate icon programmatically using a Swift script with Core Graphics:
1. Create a Swift command-line script to render the icon
2. Export 1024x1024 PNG for each appearance (light, dark)
3. Place PNGs in `AppIcon.appiconset/` and update `Contents.json`

## Brand Alignment
- Uses existing brand colors from `AppTheme.swift`
- Consistent with app's green theme identity
- Leaf element ties into "growth" narrative for personal finance
