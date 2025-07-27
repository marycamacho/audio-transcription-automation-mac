#!/usr/bin/env bash

# --- 1. Define Folder Paths ---
HOME_DIR="$HOME"
DROPBOX_DIR="$HOME_DIR/Dropbox"
RECORDINGS_FOLDER="$DROPBOX_DIR/_recordings"
TRANSCRIPTS_FOLDER="$RECORDINGS_FOLDER/transcripts"
COMPLETED_FOLDER="$RECORDINGS_FOLDER/completed"
NEW_ZOOM_FOLDER="$RECORDINGS_FOLDER/new-zoom"
VOICE_MEMOS_FOLDER="$HOME_DIR/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings"
MODEL_PATH="$HOME_DIR/whisper-files/models/ggml-base.en.bin"


# ===================================================================
# == PART 1: PROCESS NEW ZOOM RECORDINGS (FINAL VERSION)
# ===================================================================
echo "--- Checking for new Zoom recordings to process... ---"

# Use find and a while loop to correctly handle folder names with spaces
find "$NEW_ZOOM_FOLDER" -maxdepth 1 -mindepth 1 -type d | while read -r ZOOM_SUBFOLDER; do
    
    FOLDER_NAME=$(basename "$ZOOM_SUBFOLDER")

    # Check if the folder name does NOT start with a number
    if [[ ! "$FOLDER_NAME" =~ ^[0-9] ]]; then
        echo "----------------------------------------------------"
        echo "Found named folder to process: '$FOLDER_NAME'"

        # Use a compatible 'while read' loop to build the file list safely, handling all special characters
        VALID_FILES=()
        while IFS= read -r -d '' file; do
            VALID_FILES+=("$file")
        done < <(find "$ZOOM_SUBFOLDER" -type f \( -name "*.m4a" -o -name "*.mp3" \) -size +0c -print0)
        
        EXPECTED_COUNT=${#VALID_FILES[@]}
        SUCCESS_COUNT=0

        if [ "$EXPECTED_COUNT" -gt 0 ]; then
            echo "  Found $EXPECTED_COUNT audio file(s) to process."

            PART_COUNT=1
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
                        # CORRECT LOGIC: We do NOT move the individual audio file here.
                        # It stays in its folder, waiting for the parent folder to be moved.
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
done
echo "--- Zoom processing complete. ---"


# ===================================================================
# == PART 2: PROCESS LOOSE FILES IN _RECORDINGS
# ===================================================================
echo "--- Checking for loose files in _recordings... ---"
find "$RECORDINGS_FOLDER" -maxdepth 1 \( -name "*.m4a" -o -name "*.mp3" \) -type f -print0 | while read -r -d $'\0' AUDIO_FILE; do
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
done
echo "--- Loose file processing complete. ---"


# ===================================================================
# == PART 3: PROCESS NEW VOICE MEMOS
# ===================================================================
echo "--- Checking for new Voice Memos... ---"
if [ ! -d "$VOICE_MEMOS_FOLDER" ]; then
    echo "!!! ERROR: Voice Memos directory not found at '$VOICE_MEMOS_FOLDER'. Skipping this step. !!!"
else
    find "$VOICE_MEMOS_FOLDER" -maxdepth 1 -name "*.m4a" -size +0c -print0 | while read -r -d $'\0' AUDIO_FILE; do
        echo "----------------------------------------------------"
        echo "Transcribing Voice Memo: ${AUDIO_FILE##*/}"
        BASENAME="${AUDIO_FILE##*/}"
        TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
        NEW_TRANSCRIPT_NAME="mary-voice-note-${TIMESTAMP}"
        TEMP_WAV_FILE="$RECORDINGS_FOLDER/$NEW_TRANSCRIPT_NAME.wav"
        echo "  --> Step A: Converting to compatible WAV format..."
        if ffmpeg -i "$AUDIO_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$TEMP_WAV_FILE" -hide_banner -loglevel error; then
            echo "  --> Step B: Transcribing WAV..."
            if whisper-cli -m "$MODEL_PATH" -f "$TEMP_WAV_FILE" -otxt -of "$TRANSCRIPTS_FOLDER/$NEW_TRANSCRIPT_NAME"; then
                echo "  --> SUCCESS: Transcription complete. Transcript saved as '$NEW_TRANSCRIPT_NAME.txt'"
                echo "  --> Step C: Moving original Voice Memo to 'completed'..."
                mv "$AUDIO_FILE" "$COMPLETED_FOLDER/voice-memo-${TIMESTAMP}.m4a"
            else
                echo "  !!! ERROR: Transcription failed for '$BASENAME'. Original file will not be moved. !!!"
            fi
            echo "  --> Step D: Cleaning up temporary file..."
            rm "$TEMP_WAV_FILE"
        else
            echo "  !!! ERROR: Failed to convert '$BASENAME'. Skipping this file. It may be corrupt or empty. !!!"
        fi
    done
fi
echo "--- Voice Memo processing complete. ---"


# ===================================================================

echo ""
echo "Batch process finished."