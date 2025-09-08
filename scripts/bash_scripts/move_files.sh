
DEST_FOLDER="json_and_csv"

print_step() {
    echo -e "\n\033[1;34m=== $1 ===\033[0m" >&2
}

print_success() {
    echo -e "\033[1;32m✓ $1\033[0m" >&2
}

print_error() {
    echo -e "\033[1;31m✗ $1\033[0m" >&2
}

print_info() {
    echo -e "\033[1;33m→ $1\033[0m" >&2
}

print_warning() {
    echo -e "\033[1;33m⚠ $1\033[0m" >&2
}



create_folder() {
    local dir_name="$1"  
    echo "DEBUG: dir_name received = '$dir_name'" >&2
    echo "DEBUG: Length of dir_name = ${#dir_name}" >&2
    
    if [ -z "$dir_name" ]; then
        print_error "Error: No directory name provided"
        exit 1
    fi
    
    
    if [ -z "$dir_name" ]; then
        print_error "Error: No directory name provided"
        exit 1
    fi
    
    print_step "Creating directory '$dir_name'"
    
    if [ ! -d "$dir_name" ]; then
        mkdir -p "$dir_name"
        print_success "Created '$dir_name' directory."
    else
        print_info "'$dir_name' directory already exists."
    fi
}

move_files() {
    echo "DEBUG: DEST_FOLDER at start of move_files = '$DEST_FOLDER'" >&2
    DEST_FOLDER=${DEST_FOLDER//\"/}
    echo "DEBUG: DEST_FOLDER after quote removal = '$DEST_FOLDER'" >&2
    create_folder "$DEST_FOLDER"
    

    local file_type="$1"
    local pattern="$2"
    local count=0
    local moved=0
    local failed=0
    
    print_info "Processing $file_type files..."
    
    
    while IFS= read -r -d '' file; do
        ((count++))
        
        filename=$(basename "$file")
        destination="$DEST_FOLDER/$filename"
        
        if [ -f "$destination" ]; then
            print_warning "File already exists in destination: $filename"
            read -p "Overwrite? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Skipped: $filename"
                continue
            fi
        fi
        
        if mv "$file" "$destination"; then
            print_success "Moved: $filename"
            ((moved++))
        else
            print_error "Failed to move: $filename"
            ((failed++))
        fi
        
    done < <(find . -maxdepth 1 -type f -iname "$pattern" -print0 2>/dev/null)
    
    if [ $count -eq 0 ]; then
        print_info "No $file_type files found in current directory"
    else
        print_info "$file_type Summary: Found=$count, Moved=$moved, Failed=$failed"
    fi
    
    return $moved
}

show_summary() {
    local csv_moved=$1
    local json_moved=$2
    local total_moved=$((csv_moved + json_moved))
    
    echo
    print_info "OPERATION SUMMARY"
    echo "Destination folder: $DEST_FOLDER" >&2
    echo "CSV files moved: $csv_moved" >&2
    echo "JSON files moved: $json_moved" >&2
    echo "Total files moved: $total_moved" >&2
    
    if [ $total_moved -gt 0 ]; then
        print_success "File move operation completed successfully!"
    else
        print_warning "No files were moved"
    fi

}


# exe
main() {
    echo
    print_step "Moving CSV and JSON files"
    move_files "CSV" "*.csv"
    csv_moved=$?
     
    move_files "JSON" "*.json"
    json_moved=$?
    show_summary $csv_moved $json_moved 
    
    print_step "SCRIPT COMPLETED"
}

main "$@"