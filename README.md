# Chronological photo sync for Android

## Prerequisites:

- Install [adb](https://developer.android.com/tools/adb) and ensure it's executable
    - Automatic installation using Homebrew: ```brew install android-platform-tools```
- Enable Developer Mode and activate USB debugging
- If you have a Samsung device: Disable Auto Blocker ("Automatische Sperre") for the duration of the transfer.
    - Otherwise adb can't access your file system properly.
- (optional) Add the photoSync executable to your ```$PATH``` to access it from anywhere.

## Usage

- Connect your phone to your Mac
    - Wireless connection might also be possible but this is not tested and will be much slower.
- The script provides 3 functionalities:
    - ```photoSync pull``` to transfer photos from your phone to your computer
    - ```photoSync push``` to transfer photos from your computer to your phone
    - ```photoSync fix-timestamps``` to fix creation and modify timestamp of your images based on their filename
- The script ensures that your phone stays awake during transfer to prevent interruptions.

:warning: Test the transfer with a small amount of photos before transferring all of them. 
Use the ```-dry-run``` flag to see which images the script would transfer.

:warning: Some commands (especially the ```find``` command options) only work on macOS. Linux and Windows is not tested and might need additional adjustments.

## Benchmark:
Tested with Samsung S21/S25 and Macbook Pro (M1)

- Pushing 11000 photos (approx. 60GB) took round about 45min.
- Pulling photos from your phone to your computer is much faster.
- Fixing the timestamps is done in minutes.
