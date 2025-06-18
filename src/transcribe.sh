#!/bin/bash

# --- 1. Define Folder Paths ---
# Using variables makes the script easier to read and modify.
HOME_DIR="$HOME"
DROPBOX_DIR="$HOME_DIR/Dropbox"
RECORDINGS_FOLDER="$DROPBOX_DIR/_recordings"
TRANSCRIPTS_FOLDER="$RECORDINGS_FOLDER/transcripts"
COMPLETED_FOLDER="$RECORDINGS_FOLDER/completed"
NEW_ZOOM_FOLDER="$RECORDINGS_FOLDER/new-zoom"
MODEL_PATH="$HOME_DIR/whisper-files/models/ggml-base.en.bin"

# ===================================================================
# == PART 1: PRE-PROCESSING FOR NEW ZOOM RECORDINGS
# ===================================================================

echo "--- Checking for new Zoom recordings to process... ---"

# Loop through each item in the 'new-zoom' folder
for ZOOM_SUBFOLDER in "$NEW_ZOOM_FOLDER"/*; do
    # Check if it's actually a directory
    if [ -d "$ZOOM_SUBFOLDER" ]; then
        
        FOLDER_NAME=$(basename "$ZOOM_SUBFOLDER")

        # Check if the folder name does NOT start with a number (e.g., a date)
        if [[ ! "$FOLDER_NAME" =~ ^[0-9] ]]; then
            echo "Found named folder to process: '$FOLDER_NAME'"

            # Now find the audio file inside this folder
            for AUDIO_FILE in "$ZOOM_SUBFOLDER"/*.m4a "$ZOOM_SUBFOLDER"/*.mp3; do
                if [ -f "$AUDIO_FILE" ]; then
                    
                    # Get the file's extension (m4a or mp3)
                    EXTENSION="${AUDIO_FILE##*.}"
                    
                    # Define the new name and destination for the audio file
                    NEW_FILENAME="$FOLDER_NAME.$EXTENSION"
                    DESTINATION_PATH="$RECORDINGS_FOLDER/$NEW_FILENAME"

                    # --- Duplicate Check ---
                    # If a file with this name already exists in _recordings...
                    if [ -f "$DESTINATION_PATH" ]; then
                        echo "  ! File '$NEW_FILENAME' already exists. Adding date stamp."
                        DATE_STAMP=$(date +"%Y-%m-%d")
                        # ...create a new name with a date stamp.
                        NEW_FILENAME="${FOLDER_NAME}_${DATE_STAMP}.${EXTENSION}"
                        DESTINATION_PATH="$RECORDINGS_FOLDER/$NEW_FILENAME"
                    fi
                    
                    echo "  > Renaming and moving '$BASENAME' to '$NEW_FILENAME' in _recordings."
                    mv "$AUDIO_FILE" "$DESTINATION_PATH"
                fi
            done

            # After moving the audio out, move the empty Zoom folder to 'completed'
            echo "  > Moving processed folder '$FOLDER_NAME' to completed."
            mv "$ZOOM_SUBFOLDER" "$COMPLETED_FOLDER/"

        fi
    fi
done

echo "--- Zoom processing complete. Starting main transcription batch. ---"


# ===================================================================
# == PART 2: MAIN TRANSCRIPTION PROCESS (Your existing script)
# ===================================================================

# Loop through each audio file in the main _recordings folder
for AUDIO_FILE in "$RECORDINGS_FOLDER"/*.m4a "$RECORDINGS_FOLDER"/*.mp3; do
  
  if [ -f "$AUDIO_FILE" ]; then

    echo "----------------------------------------------------"
    echo "Transcribing: ${AUDIO_FILE##*/}"

    BASENAME="${AUDIO_FILE##*/}"
    FILENAME_NO_EXT="${BASENAME%.*}"
    TEMP_WAV_FILE="$RECORDINGS_FOLDER/$FILENAME_NO_EXT.wav"

    # Convert, Transcribe, and Move chain
    echo "  --> Step A: Converting to compatible WAV format..."
    ffmpeg -i "$AUDIO_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$TEMP_WAV_FILE" -hide_banner -loglevel error && \
    
    echo "  --> Step B: Transcribing WAV..."
    whisper-cli -m "$MODEL_PATH" -f "$TEMP_WAV_FILE" -otxt -of "$TRANSCRIPTS_FOLDER/$FILENAME_NO_EXT" && \
    
    echo "  --> Step C: Moving original audio to 'completed'..."
    mv "$AUDIO_FILE" "$COMPLETED_FOLDER/"

    # Clean up the temporary WAV file
    echo "  --> Step D: Cleaning up temporary file..."
    rm "$TEMP_WAV_FILE"

  fi
done

echo "----------------------------------------------------"
echo "Batch process complete."