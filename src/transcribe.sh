#!/bin/bash

# --- 1. Define Folder Paths ---
HOME_DIR="$HOME"
DROPBOX_DIR="$HOME_DIR/Dropbox"
RECORDINGS_FOLDER="$DROPBOX_DIR/_recordings"
TRANSCRIPTS_FOLDER="$RECORDINGS_FOLDER/transcripts"
COMPLETED_FOLDER="$RECORDINGS_FOLDER/completed"
NEW_ZOOM_FOLDER="$RECORDINGS_FOLDER/new-zoom"
MODEL_PATH="$HOME_DIR/whisper-files/models/ggml-base.en.bin"


# ===================================================================
# == PART 1: PROCESS NEW ZOOM RECORDINGS (FINAL VERSION)
# ===================================================================
echo "--- Checking for new Zoom recordings to process... ---"

# Loop through each item in the 'new-zoom' folder
for ZOOM_SUBFOLDER in "$NEW_ZOOM_FOLDER"/*; do
    # Check if it's actually a directory
    if [ -d "$ZOOM_SUBFOLDER" ]; then
        
        FOLDER_NAME=$(basename "$ZOOM_SUBFOLDER")

        # Check if the folder name does NOT start with a number
        if [[ ! "$FOLDER_NAME" =~ ^[0-9] ]]; then
            echo "----------------------------------------------------"
            echo "Found named folder to process: '$FOLDER_NAME'"

            VALID_FILES=($(find "$ZOOM_SUBFOLDER" -maxdepth 1 \( -name "*.m4a" -o -name "*.mp3" \) -size +0c))
            EXPECTED_COUNT=${#VALID_FILES[@]}
            SUCCESS_COUNT=0

            if [ "$EXPECTED_COUNT" -gt 0 ]; then
                echo "  Found $EXPECTED_COUNT audio file(s) to process."

                PART_COUNT=1

                # Loop through only the valid audio files
                for AUDIO_FILE in "${VALID_FILES[@]}"; do
                    BASENAME="${AUDIO_FILE##*/}"
                    UNIQUE_FILENAME_BASE="${FOLDER_NAME}-${PART_COUNT}"
                    TEMP_WAV_FILE="$RECORDINGS_FOLDER/$UNIQUE_FILENAME_BASE-$(date +%s).wav"

                    echo "  --> Processing: $BASENAME"
                    echo "    > Step A: Converting to compatible WAV format..."
                    if ffmpeg -i "$AUDIO_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$TEMP_WAV_FILE" -hide_banner -loglevel error; then
                        
                        echo "    > Step B: Transcribing WAV..."
                        if whisper-cli -m "$MODEL_PATH" -f "$TEMP_WAV_FILE" -otxt -of "$TRANSCRIPTS_FOLDER/$UNIQUE_FILENAME_BASE"; then
                            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                            echo "    > SUCCESS: Transcription complete for '$BASENAME'."
                        else
                            echo "    !!! ERROR: Transcription failed for '$BASENAME'. !!!"
                        fi

                        rm "$TEMP_WAV_FILE"
                    else
                        echo "    !!! ERROR: Failed to convert '$BASENAME'. It may be corrupt. !!!"
                    fi

                    PART_COUNT=$((PART_COUNT + 1))
                done
            else
                echo "  ! No valid (non-empty) audio files found in '$FOLDER_NAME'. Skipping."
            fi

            # Final check for completeness
            if [ "$EXPECTED_COUNT" -gt 0 ] && [ "$EXPECTED_COUNT" -eq "$SUCCESS_COUNT" ]; then
                echo "  > All $SUCCESS_COUNT audio file(s) processed successfully. Moving original Zoom folder to completed."
                mv "$ZOOM_SUBFOLDER" "$COMPLETED_FOLDER/"
            elif [ "$EXPECTED_COUNT" -gt 0 ]; then
                echo "  !!! WARNING: Processed only $SUCCESS_COUNT out of $EXPECTED_COUNT expected audio files for '$FOLDER_NAME'."
                echo "  !!! Leaving original folder in 'new-zoom' for manual review. !!!"
            fi
        fi
    fi
done
echo "--- Zoom processing complete. Starting main transcription batch for loose files. ---"


# ===================================================================
# == PART 2: PROCESS LOOSE FILES IN _RECORDINGS
# ===================================================================
for AUDIO_FILE in "$RECORDINGS_FOLDER"/*.m4a "$RECORDINGS_FOLDER"/*.mp3; do
  if [ -f "$AUDIO_FILE" ]; then
    echo "----------------------------------------------------"
    echo "Transcribing loose file: ${AUDIO_FILE##*/}"

    BASENAME="${AUDIO_FILE##*/}"
    FILENAME_NO_EXT="${BASENAME%.*}"
    TEMP_WAV_FILE="$RECORDINGS_FOLDER/$FILENAME_NO_EXT.wav"

    echo "  --> Step A: Converting to compatible WAV format..."
    if ffmpeg -i "$AUDIO_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$TEMP_WAV_FILE" -hide_banner -loglevel error; then
        echo "  --> Step B: Transcribing WAV..."
        if whisper-cli -m "$MODEL_PATH" -f "$TEMP_WAV_FILE" -otxt -of "$TRANSCRIPTS_FOLDER/$FILENAME_NO_EXT"; then
            echo "  --> SUCCESS: Transcription complete."
            echo "  --> Step C: Moving original audio to 'completed'..."
            mv "$AUDIO_FILE" "$COMPLETED_FOLDER/"
        else
            echo "  !!! ERROR: Transcription failed for '$BASENAME'. Original file will not be moved. !!!"
        fi
        echo "  --> Step D: Cleaning up temporary file..."
        rm "$TEMP_WAV_FILE"
    else
        echo "  !!! ERROR: Failed to convert '$BASENAME'. Skipping this file. It may be corrupt or empty. !!!"
    fi
  fi
done
echo "----------------------------------------------------"
echo "Batch process complete."