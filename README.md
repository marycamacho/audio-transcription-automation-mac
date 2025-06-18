# Audio Transcription Automation for macOS

A shell script to automate the local transcription of audio files on macOS using the powerful `whisper.cpp` engine.

Created with a little help from a general AI.

## Motivation

This script was designed for my private use on a local computer. I wanted to avoid using third-party transcription tools or services that require uploading my recordings to external servers. I believe we should not share data with AIs or for-profit businesses unless we explicitly want them to perform a task that is impossible to do locally. This script provides a powerful, private, and offline alternative.

## Features

* **Batch Processing:** Transcribes all `.m4a` and `.mp3` files found in a source folder.
* **Automated Workflow:**
    * Saves `.txt` transcripts to a dedicated `transcripts` folder.
    * Moves successfully processed audio files to a `completed` folder to prevent re-transcription.
* **Zoom Pre-processing:** Automatically finds specially-named Zoom recording folders, renames the audio file to match the folder's name, and prepares it for transcription.
* **Duplicate Handling:** If a file with the same name already exists, it adds the current date to the filename to prevent overwriting.

## Required Folder Structure

For the script to work, it assumes the following folder structure exists within your user's `Dropbox` directory:

* **`~/Dropbox/`**
    * **`_recordings/`**
        * `completed/`      <-- Processed original audio files are moved here.
        * `new-zoom/`       <-- Drop Zoom recording folders here for pre-processing.
        * `transcripts/`    <-- Final .txt transcripts are saved here.
        * *(Place other .m4a and .mp3 files here for processing)*

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

3.  **Download a Transcription Model:** The script is configured to use the `base.en` (English) model. You must download it once.
    ```bash
    # Create a place to store the models in your home directory
    mkdir -p ~/whisper-files/models

    # Download the model file
    curl -L -o ~/whisper-files/models/ggml-base.en.bin [https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin](https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin)
    ```

## Usage

1.  Save the script from this repository as `transcribe.sh` in your user home directory (`~/`).
2.  Open your terminal and make the script executable with this one-time command:
    ```bash
    chmod +x ~/transcribe.sh
    ```
3.  Place your audio files in the appropriate folders (`_recordings` or `_recordings/new-zoom`).
4.  Run the script from your terminal:
    ```bash
    ~/transcribe.sh
    ```
