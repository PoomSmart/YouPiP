# YouPiP

Enable native Picture-in-Picture feature for videos in YouTube app.

Activate PiP by playing the video and dismissing the app, or tapping PiP button in video control overlay.

## Building

### Normal

```
make package FINALPACKAGE=1
```

### Sideloaded

```
make SIDELOADED=1 && cp .theos/obj/YouPiP.dylib YouPiP.dylib
```
