#!/bin/bash

set -e

VERSION="15_5"
OUTPUT="am2r_${VERSION}"
DATA_FOLDER="data"
DOWNLOADS_DIR="$HOME/storage/downloads"
HQ_MUSIC_URL="https://github.com/izzy2fancy/AM2R-Autopatcher-Android/releases/download/2.0/HDR_HQ_in-game_music.zip"

cleanup_directories() {
    local directories=("assets" "AM2RWrapper" "$DATA_FOLDER" "HDR_HQ_in-game_music")
    for dir in "${directories[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
        fi
    done
    rm -rf data.zip HDR_HQ_in-game_music.zip
}

cleanup_directories

echo "-------------------------------------------"
echo ""
echo "AM2R 1.5.5 Shell Autopatching Utility"
echo "Originally Scripted by Miepee and help from Lojemiru"
echo "Updated by izzy2fancy"
echo ""
echo "-------------------------------------------"

# Install dependencies
yes | pkg install termux-am zip unzip xdelta3
yes | termux-setup-storage

# Check and install apkmod if not installed
if ! [ -f /data/data/com.termux/files/usr/bin/apkmod ]; then
    wget https://raw.githubusercontent.com/Hax4us/Apkmod/master/setup.sh
    bash setup.sh
    rm -f setup.sh
fi

# Download Data Folder
wget -r -np -nH --cut-dirs=2 -R "index.html*" "https://github.com/izzy2fancy/AM2R-Autopatcher-Android/data"

# Check for AM2R_11.zip in downloads
if [ ! -f "$DOWNLOADS_DIR/AM2R_11.zip" ]; then
    echo -e "\033[0;31mAM2R_11 not found. Place AM2R_11.zip (case sensitive) into your Downloads folder and try again."
    echo -e "\033[1;37m"
    exit -1
fi

echo "AM2R_11.zip found! Extracting to ${OUTPUT}"
unzip -q "$DOWNLOADS_DIR/AM2R_11.zip" -d "$OUTPUT"

echo "Applying Android patch..."
xdelta3 -dfs "${OUTPUT}/data.win" "${DATA_FOLDER}/droid.xdelta" "${OUTPUT}/game.droid"

# Delete unnecessary files
rm "${OUTPUT}/D3DX9_43.dll" "${OUTPUT}/AM2R.exe" "${OUTPUT}/data.win" 

if [ -f "${DATA_FOLDER}/android/AM2R.ini" ]; then
    cp -p "${DATA_FOLDER}/android/AM2R.ini" "$OUTPUT/"
fi

# Music
cp "${DATA_FOLDER}/files_to_copy/"*.ogg "$OUTPUT/"

echo ""
echo -e "\033[0;32mInstall high quality in-game music? Increases filesize by 230 MB and may lag the game\!"
echo -e "\033[1;37m"
echo "[y/n]"

read -n1 INPUT
echo ""

if [ "$INPUT" = "y" ]; then
    echo "Downloading HQ music..."
    wget "$HQ_MUSIC_URL"
    yes | unzip HDR_HQ_in-game_music.zip -d ./
    echo "Copying HQ music..."
    cp -f HDR_HQ_in-game_music/*.ogg "$OUTPUT/"
    rm -rf HDR_HQ_in-game_music/
fi

echo "Updating lang folder..."
rm -R "${OUTPUT}/lang/"
cp -RTp "${DATA_FOLDER}/files_to_copy/lang/" "${OUTPUT}/lang/"

echo "Renaming music to lowercase..."
zip -0qr temp.zip "${OUTPUT}"/*.ogg
rm "${OUTPUT}"/*.ogg
unzip -qLL temp.zip
rm temp.zip

echo "Packaging APK..."
apkmod -d -i "${DATA_FOLDER}/android/AM2RWrapper.apk" -o AM2RWrapper
mv "$OUTPUT" assets
cp -Rp assets AM2RWrapper
sed -i "s/doNotCompress:/doNotCompress:\n- ogg/" AM2RWrapper/apktool.yml
if [ -f /usr/bin/aapt2 ]; then
    apkmod -r -i AM2RWrapper -o "AM2R-${VERSION}.apk"
else
    apkmod -a -r -i AM2RWrapper -o "AM2R-${VERSION}.apk"
fi
apkmod -s -i "AM2R-${VERSION}.apk" -o "AM2R-${VERSION}-signed.apk"

rm -R assets/ AM2RWrapper/ "$DATA_FOLDER" "AM2R-${VERSION}.apk"
mv "AM2R-${VERSION}-signed.apk" "$DOWNLOADS_DIR/AM2R-${VERSION}-signed.apk"

echo ""
echo -e "\033[0;32mThe operation was completed successfully and the APK can be found in your Downloads folder as \"AM2R-${VERSION}-signed.apk\"."
echo -e "\033[0;32mSee you next mission\!"
echo -e "\033[1;37m"
xdg-open "$DOWNLOADS_DIR/AM2R-${VERSION}-signed.apk"
