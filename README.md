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
make DEBUG=0 SIDELOADED=1
mkdir out
cp -r .theos/obj/com.ps.youpip.bundle/ .theos/obj/YouPiP.dylib out/
rm out/com.ps.youpip.bundle/YouPiP.plist
```