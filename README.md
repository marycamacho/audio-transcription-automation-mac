# Audio Transcription Automation for macOS

A robust shell script to automate the local transcription of audio files on macOS using the powerful `whisper.cpp` engine.

Created with a little help from a general AI.

## Motivation

This script was designed for my private use on a local computer. I wanted to avoid using third-party transcription tools or services that require uploading my recordings to external servers. I believe we should not share data with AIs or for-profit businesses unless we explicitly want them to perform a task that is impossible to do locally. This script provides a powerful, private, and offline alternative.

## Features

* **Multi-Source Processing:** Automatically processes audio files from three distinct locations:
    1.  Named subfolders within a `new-zoom` directory.
    2.  Loose audio files dropped into a main `_recordings` folder.
    3.  The system's official macOS **Voice Memos** database.
* **Intelligent Naming:** Creates clean, sequentially numbered transcripts (e.g., `Meeting-Name-1.txt`, `Meeting-Name-2.txt`) for multi-part recordings from a single source folder.
* **Robust Error Handling:**
    * Skips corrupt, empty, or unreadable audio files and prints a clear error.
    * If a folder with multiple audio files is only partially processed, it leaves the original folder in place for manual review.
    * Correctly handles filenames that contain spaces or special characters.
* **Automated File Management:**
    * Saves `.txt` transcripts to a dedicated `transcripts` folder.
    * Moves successfully processed audio files and their parent folders to a `completed` folder to prevent re-transcription, preserving the original folder structure.

## Required Folder Structure

For the script to work, it assumes the following folder structure exists within your user's `Dropbox` directory. Additionally, it reads directly from the system's Voice Memos folder.

* **`~/Dropbox/_recordings/`**
    * `completed/`      <-- Processed original audio files & folders are moved here.
    * `new-zoom/`       <-- Drop named Zoom recording folders here for pre-processing.
    * `transcripts/`    <-- Final .txt transcripts are saved here.
    * *(Place other loose .m4a and .mp3 files here for processing)*
* **`~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/`**
    * *(This is the system location the script reads new Voice Memos from)*

## Requirements

* macOS (tested on an Apple Silicon Mac)
* [Homebrew](https://brew.sh/)
* [whisper.cpp](https://github.com/ggerganov/whisper.cpp)
* [ffmpeg](https://ffmpeg.org/)

## Setup & Installation

1.  **Install Homebrew:** If you don't already have it, open your terminal and run:
    ```bash
    /bin/bash -c "$(curl -fsSL [https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh](https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh))"
    ```

2.  **Install Dependencies:** Use Homebrew to install `whisper.cpp` and `ffmpeg`.
    ```bash
    brew install whisper-cpp ffmpeg
    ```

3.  **Grant Full Disk Access (CRITICAL for Voice Memos):** To allow the script to read the protected Voice Memos folder, you must grant Full Disk Access to your Terminal app.
    * Open **System Settings** > **Privacy & Security** > **Full Disk Access**.
    * Click the **+** button, navigate to `Applications/Utilities`, select **Terminal.app**, and click Open.
    * Ensure the switch next to Terminal is turned on.
    * **You must quit and restart your Terminal for this change to take effect.**

4.  **Download a Transcription Model:** The script is configured to use the `base.en` (English) model. You must download it once.
    ```bash
    # Create a place to store the models in your home directory
    mkdir -p ~/whisper-files/models

    # Download the model file
    curl -L -o ~/whisper-files/models/ggml-base.en.bin [https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin)
    ```

## Usage

1.  Save the `transcribe.sh` script from this repository into your user home directory (`~/`).
2.  Open your terminal and make the script executable with this one-time command:
    ```bash
    chmod +x ~/transcribe.sh
    ```
3.  Place your audio files in the appropriate folders (`_recordings`, `new-zoom`, or create a new Voice Memo).
4.  Run the script from your terminal:
    ```bash
    ~/transcribe.sh
    ```