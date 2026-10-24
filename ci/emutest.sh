#!/bin/bash
set -x
OUT=test-out; mkdir -p $OUT
PKG=tech.comma.box2
adb install -r Comma-box2.apk || exit 1
adb logcat -c
adb shell am start -W -n $PKG/.MainActivity
sleep 45
adb exec-out screencap -p > $OUT/shot1_launch.png
adb shell uiautomator dump /sdcard/ui.xml; adb pull /sdcard/ui.xml $OUT/ui1.xml
# rotate & back key robustness
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 1; sleep 5
adb shell settings put system user_rotation 0; sleep 8
adb exec-out screencap -p > $OUT/shot2_rotated.png
adb shell input keyevent 4; sleep 2
adb exec-out screencap -p > $OUT/shot3_back1.png
adb shell input keyevent 4; sleep 3
adb shell dumpsys activity activities | grep -E "mResumedActivity|topResumedActivity" > $OUT/after_back.txt
# relaunch (cookie / state persistence path)
adb shell am start -W -n $PKG/.MainActivity; sleep 20
adb exec-out screencap -p > $OUT/shot4_relaunch.png
adb shell uiautomator dump /sdcard/ui.xml; adb pull /sdcard/ui.xml $OUT/ui2.xml
adb logcat -d > $OUT/logcat.txt
grep -E "FATAL EXCEPTION|AndroidRuntime: Process: $PKG|ANR in $PKG" $OUT/logcat.txt > $OUT/crashes.txt
grep -iE "chromium.*(console|ERR_)|$PKG" $OUT/logcat.txt | tail -200 > $OUT/app_log.txt
if [ -s $OUT/crashes.txt ]; then echo CRASH; cat $OUT/crashes.txt; exit 1; fi
echo OK
exit 0
