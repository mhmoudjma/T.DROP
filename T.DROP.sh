#!/bin/bash

# ---[ one]---

destination="/root/Desktop/"
mkdir -p "$destination"
selected_files=()

while true; do
    clear
    echo "╔════════════════════════════════╗"
    echo "║     Transfer to Desktop        ║"
    echo "╠════════════════════════════════╣"
    echo "║ 1. Select file from current dir║"
    echo "║ 2. Show selected files         ║"
    echo "║ 3. Transfer selected files     ║"
    echo "║ 4. Clear file list             ║"
    echo "║ 5. Continue to Android transfer║"
    echo "╚════════════════════════════════╝"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1)
            echo ""
            echo "📂 Files in current directory:"
            files=(*)
            count=0
            for file in "${files[@]}"; do
                if [ -f "$file" ] || [ -d "$file" ]; then
                    count=$((count + 1))
                    echo "[$count] $file"
                fi
            done

            if [ $count -eq 0 ]; then
                echo "⚠️ No files or folders found!"
                sleep 2
                continue
            fi

            read -p "Enter the number of the item to select: " index
            if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 1 ] && [ "$index" -le "$count" ]; then
                file_to_add="${files[$((index - 1))]}"
                selected_files+=("$file_to_add")
                echo "✅ Added: $file_to_add"
            else
                echo "❌ Invalid selection."
            fi
            sleep 2
            ;;
        2)
            echo "📋 Selected files:"
            if [ ${#selected_files[@]} -eq 0 ]; then
                echo "No files selected."
            else
                for i in "${!selected_files[@]}"; do
                    echo "$((i+1)). ${selected_files[i]}"
                done
            fi
            read -p "Press Enter to continue..."
            ;;
        3)
            if [ ${#selected_files[@]} -eq 0 ]; then
                echo "⚠️ No files selected."
                sleep 2
                continue
            fi

            echo "🚀 Transferring files to $destination..."
            for file in "${selected_files[@]}"; do
                abs_file=$(realpath "$file")
                abs_dest=$(realpath "$destination")

                if [[ "$abs_file" == "$abs_dest" || "$abs_file" == "$abs_dest/"* ]]; then
                    echo "⚠️ Skipping '$file': cannot copy into its own directory."
                    continue
                fi

                cp -rv "$file" "$destination/$(basename "$file")"
            done
            echo "✅ Transfer completed."
            read -p "Press Enter to continue..."
            ;;
        4)
            selected_files=()
            echo "🧹 File list cleared."
            sleep 1
            ;;
        5)
            break
            ;;
        *)
            echo "❌ Invalid option. Please try again."
            sleep 1
            ;;
    esac
done

# ---[2]---

SOURCE="/root/Desktop"
DEST="/host-downloads"

if [ ! -d "$DEST" ]; then
    echo "❌ Android Download folder not found. Is storage mounted?"
    exit 1
fi

entries=()
mapfile -t entries < <(find "$SOURCE" -maxdepth 1 ! -name '.*' ! -path "$SOURCE" )

if [ ${#entries[@]} -eq 0 ]; then
    echo "⚠️ No visible files or folders in $SOURCE to transfer."
    exit 0
fi

echo "📂 Files and folders in $SOURCE:"
for i in "${!entries[@]}"; do
    name=$(basename "${entries[$i]}")
    if [ -d "${entries[$i]}" ]; then
        echo "[$((i+1))] 📁 $name"
    else
        echo "[$((i+1))] 📄 $name"
    fi
done

read -p "Enter item numbers to transfer (comma-separated or 'all'): " selection
selected=()

if [[ "$selection" == "all" ]]; then
    selected=("${entries[@]}")
else
    IFS=',' read -ra indexes <<< "$selection"
    for idx in "${indexes[@]}"; do
        if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#entries[@]}" ]; then
            selected+=("${entries[$((idx-1))]}")
        fi
    done
fi

echo ""
read -p "🗑️ Do you want to delete files after transfer? (y/n): " delete_after

echo "🚀 Transferring selected items to Android Download..."
for item in "${selected[@]}"; do
    name=$(basename "$item")
    cp -rv "$item" "$DEST/$name"
    if [[ "$delete_after" =~ ^[Yy]$ ]]; then
        rm -rf "$item"
    fi
done

echo ""
echo "✅ Transfer complete!"
[[ "$delete_after" =~ ^[Yy]$ ]] && echo "🧹 Source files deleted." || echo "📁 Source files kept."
