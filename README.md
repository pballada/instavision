# InstaVision

[![CI](https://github.com/pballada/instavision/actions/workflows/ci.yml/badge.svg)](https://github.com/pballada/instavision/actions/workflows/ci.yml)

A native Instagram viewer for **Apple Vision Pro**, built around **Reels**, with SwiftUI, AVFoundation and RealityKit.

![The Reels tab in the visionOS Simulator](docs/reels.jpg)

> Not affiliated with, endorsed by, or sponsored by Instagram or Meta.

## Reels

- **Reels first**: the app opens on a grid of your Reels as 9:16 covers with captions and like counts. Posts are one tab away
- **Vertical player window**: swipe up and down through Reels in a 9:16 window. The visible Reel autoplays and loops, a tap pauses it, and an ornament holds likes, comments, mute and **Open on Instagram**
- **Instant swipes**: the next and previous Reels are buffered ahead of time, and loops are gapless (`AVPlayerLooper`)
- **Reels Theater**: an immersive space that plays Reels on a 3.2 m tall vertical screen with your room dimmed and floating controls
- Reels are detected with the Graph API's `media_product_type`, and the app keeps paging until it has enough Reels to fill the screen, even on accounts that mostly post photos

![The vertical Reels player with its control ornament](docs/reels-player.jpg)

## Everything else

- **Feed grid** with profile header, infinite scroll, pull to refresh and gaze hover effects
- **Posts in their own windows**: open as many as you like and arrange them around the room
- **Carousel albums** with paging, and **video** playback with AVKit
- **Gallery Wall**: an immersive space that hangs your 16 latest posts on a curved wall around you. Look and pinch to open one
- **Demo mode** to try everything without an account
- Token stored in the **Keychain** and **refreshed automatically** before it expires
- Memory and disk **image cache** that survives Instagram's rotating CDN URLs

## Requirements

- Xcode 16 or later with the visionOS SDK
- visionOS 2.0 or later (device or Simulator)
- For live data: an Instagram **professional** account (Business or Creator)

## Getting started

```sh
git clone https://github.com/pballada/instavision.git
open instavision/InstaVision.xcodeproj
```

Choose the **InstaVision** scheme and an Apple Vision Pro destination, then run. Tap **Try the Demo** to explore with sample data. Launch arguments for screenshots and testing:

| Argument | Effect |
| --- | --- |
| `--demo` | Start in demo mode, skipping the welcome screen |
| `--open-reels` | Open the Reels player on the first Reel once it loads |

### Using your own account

InstaVision uses the [Instagram API with Instagram Login](https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login).

1. Create an app at [developers.facebook.com](https://developers.facebook.com/apps) and add the **Instagram** product.
2. Under **API setup with Instagram login**, add your Instagram account as a tester and accept the invite in Instagram.
3. Click **Generate token** next to your account and copy the long-lived token.
4. Paste the token on InstaVision's welcome screen.

The token is kept in the Keychain and refreshed once a day while you use the app, so it won't hit its 60-day expiry as long as you open the app now and then.

## Project layout

| Path | What's there |
| --- | --- |
| `InstaVision/` | The visionOS app: scenes, views and `AppSession` |
| `InstaVision/Immersive/` | RealityKit gallery wall |
| `Packages/InstaVisionKit/` | Models, Graph API client, Keychain store, token refresh, feed store, image cache, layout math |

Everything that doesn't need UIKit or RealityKit lives in `InstaVisionKit` and is tested on macOS:

```sh
cd Packages/InstaVisionKit && swift test
```

## License

[MIT](LICENSE)
