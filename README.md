# Chronological photo sync for Android

If you want to keep the sort order of your photos after moving to a new phone, you can use this tool. 
Smart Switch or Cloud Transfers do not manage to transfer the pictures chronologically, so that the sorting on the new phone after the move is messed up.

:sparkles: With ```adb-photoSync```, all images are transferred chronologically so that even the “Recent” album displays all images correctly.

## Prerequisites:
Basic knowledge of Android, adb, and terminal operations is required.

- Install [adb](https://developer.android.com/tools/adb) and ensure it's executable
    - Automatic installation using Homebrew: ```brew install android-platform-tools```
- Enable [Developer Mode](https://developer.android.com/studio/debug/dev-options#enable) and activate USB debugging
- If you have a Samsung device: Disable Auto Blocker ("Automatische Sperre") for the duration of the transfer.
    - :warning: Otherwise adb can't access your file system properly.
    - I recommend turning it back on after the process is complete.
- (optional) Add the photoSync executable to your ```$PATH``` to access it from anywhere.

## Usage

- Connect your phone to your Mac
    - Wireless connection might also be possible but this is not tested and will be much slower.
- The tool provides 3 functionalities:
    - ```photoSync pull``` to transfer photos from your phone to your computer.
    - ```photoSync push``` to transfer photos from your computer to your phone
    - ```photoSync fix-timestamps``` to fix creation and modify timestamp of your images based on their filename (Default on any Samsung device: _yyyyMMdd_HHmmss.jpg_)
- The tool ensures that your phone stays awake during transfer to prevent interruptions. 
    - :warning: Please don't lock it manually during the process, otherwise it might fail.


:warning: Test the transfer with a small amount of photos before transferring all of them.
Use the ```-dry-run``` flag to see which images the tool would transfer:

```sh

photoSync pull -dry-run /sdcard/DCIM ~/Pictures

photoSync push -dry-run ~/Pictures /sdcard/DCIM

```

The tool handles ```.jpg```, ```.mp4```, and ```.gif``` files. If you need support for other file types, you have to update the ```find type``` options manually.

:warning: Some commands (especially the ```find``` command options) only work on macOS. Linux and Windows are not tested and might need additional adjustments.


 :warning: Please note: The ```pull``` command skips photos that have already been transferred to your computer. The ```push``` command does not do this, as the tool is currently designed to transfer your photos to a new phone only.

## Benchmark:
Tested on Samsung Galaxy S21, S25 and MacBook Pro (M1)

- Pushing 11,000 photos (~60 GB) took about 20 minutes on the S25 and 45 minutes on the S21.
- Pulling photos from your phone to your computer is much faster.
- Fixing the timestamps is done in minutes.
