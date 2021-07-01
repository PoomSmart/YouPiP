# YouPiP

Enable native Picture-in-Picture feature for videos in YouTube app.

Activate PiP by playing the video and dismissing the app, or tapping PiP button in video control overlay.

## Building

### Normal

```
make package FINALPACKAGE=1
```

### Sideloaded

#### Normal

```
make SIDELOADED=1 && cp .theos/obj/YouPiP.dylib YouPiP.dylib
```

#### Without Sample Buffer Hack
```
make SIDELOADED=1 SAMPLE_BUFFER_HACK=0 && cp .theos/obj/YouPiP.dylib YouPiP.dylib
```