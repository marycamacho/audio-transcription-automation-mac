#!/usr/bin/env bash

# --- 1. Define the Source and Destination Folders ---
VOICE_MEMOS_FOLDER="$HOME/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings"
DESTINATION_FOLDER="$HOME/Dropbox/_recordings"

echo "--- Starting Voice Memo Mover ---"

# --- 2. Check if the folders exist ---
if [ ! -d "$VOICE_MEMOS_FOLDER" ]; then
    echo "!!! ERROR: Voice Memos directory not found. Exiting. !!!"
    exit 1
fi

if [ ! -d "$DESTINATION_FOLDER" ]; then
    echo "!!! ERROR: Dropbox recordings directory not found at '$DESTINATION_FOLDER'. Please create it. Exiting. !!!"
    exit 1
fi

# --- 3. Find and move the files ---
echo "Searching for new Voice Memos to move to Dropbox..."

find "$VOICE_MEMOS_FOLDER" -maxdepth 1 -name "*.m4a" -size +0c -print0 | while read -r -d $'\0' AUDIO_FILE; do
    BASENAME="${AUDIO_FILE##*/}"
    echo "  > Moving: $BASENAME"
    mv "$AUDIO_FILE" "$DESTINATION_FOLDER/"
done

echo "--- Move process complete. ---"