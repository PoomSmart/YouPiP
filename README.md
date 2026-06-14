# YouPiP

This tweak enables native Picture-in-Picture feature for videos in iOS YouTube app, including the dedicated PiP button if preferred.

You can activate PiP by playing the video and dismissing the app, or tapping PiP button in video tab bar or control overlay.

## Build it yourself

Use iOS 15+ SDK and latest THEOS.

Also clone [YTVideoOverlay](https://github.com/PoomSmart/YTVideoOverlay) and put it in the same directory as this project.

## Sideloading

Ensure that you inject YTVideoOverlay tweak alongside YouPiP, as YouPiP depends on YTVideoOverlay to work.

## No stream, tap to retry

On iOS 11 - 13, YouPiP forces Legacy PiP to work around PiP compatibility. It also forces the video player to be `AVPlayer`, which only supports HLS playlist. When YouTube server doesn't return HLS data, YouTube app fails to play the video and reports `No stream, tap to retry` error. The same will happen when you use AirPlay, as it uses `AVPlayer` as well.

This behavior is account-based. It can happen in one account but not the other.

It is recommended to use a dedicated iOS YouTube client that works without issues while still using `AVPlayer`, check out [YTLite (verback2308)](https://github.com/verback2308/YTLite).
