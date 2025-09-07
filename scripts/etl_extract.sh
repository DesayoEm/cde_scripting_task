if [ -f ".env" ]; then
    source .env
    echo "Loaded configuration from .env file"
else
    echo "ERROR: .env file not found!"
    exit 1
fi



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




create_folder() {
    local dir_name="$1"  
    
    
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


extract_data() {
    create_folder "$RAW_FOLDER"
    CSV_URL=$(echo "$CSV_URL" | tr -d '\r\n\t ' | tr -d '[:space:]')

    print_step "Starting CSV download from: $CSV_URL"  

    FILEPATH="${RAW_FOLDER}/${FILE_NAME}"

    if curl -L \
           --output "$FILEPATH" \
           --url "$CSV_URL" \
           --silent \
           --show-error \
           --fail \
           --max-time 300 \
           --retry 3 \
           --user-agent "Mozilla/5.0 (compatible)"; then
        print_success "Successfully downloaded CSV using curl."
    else
        local exit_code=$?
        print_error "Failed to download CSV using curl. Exit code: $exit_code"
        return 1
    fi

    if [ ! -f "$FILEPATH" ] || [ ! -s "$FILEPATH" ]; then
        print_error "Download failed - file missing or empty"
        return 1
    fi
    
    print_success "File verification completed successfully."
    print_success "File saved at: $FILEPATH"

    echo "$FILEPATH"
}


# transformation
transform_data() {
    local raw_filepath="$1"
    create_folder "$TRANSFORMED_FOLDER"

    print_step "TRANSFORM - Processing Data"
    
    if [ ! -f "$raw_filepath" ]; then
        print_error "Raw file not found: $raw_filepath"
        exit 1
    fi
    
    local transformed_filepath="${TRANSFORMED_FOLDER}/${TRANSFORMED_FILENAME}"
    
    print_info "Input file: $raw_filepath"
    print_info "Output file: $transformed_filepath"
    

    local header=$(head -n 1 "$raw_filepath")
    print_info "Original header: $header"
    
    awk -F',' '
    BEGIN {
        OFS=","
        # Initialize column indices
        year_col = -1
        value_col = -1
        units_col = -1
        variable_code_col = -1
    }
    NR==1 {
        # Process header - find column positions
        for(i=1; i<=NF; i++) {
            # Remove quotes and whitespace for comparison
            col = $i
            gsub(/^[ \t]*["'"'"']?|["'"'"']?[ \t]*$/, "", col)
            
            if(tolower(col) == "year") year_col = i
            else if(tolower(col) == "value") value_col = i
            else if(tolower(col) == "units") units_col = i
            else if(tolower(col) == "variable_code") variable_code_col = i
        }
        
        # Print new header
        print "year,Value,Units,variable_code"
    }
    NR>1 {
        # Process data rows
        if(year_col > 0 && value_col > 0 && units_col > 0 && variable_code_col > 0) {
            year_val = $year_col
            value_val = $value_col
            units_val = $units_col
            variable_code_val = $variable_code_col
            
            # Clean values (remove quotes and extra whitespace)
            gsub(/^[ \t]*["'"'"']?|["'"'"']?[ \t]*$/, "", year_val)
            gsub(/^[ \t]*["'"'"']?|["'"'"']?[ \t]*$/, "", value_val)
            gsub(/^[ \t]*["'"'"']?|["'"'"']?[ \t]*$/, "", units_val)
            gsub(/^[ \t]*["'"'"']?|["'"'"']?[ \t]*$/, "", variable_code_val)
            
            print year_val "," value_val "," units_val "," variable_code_val
        }
    }
    ' "$raw_filepath" > "$transformed_filepath"
    
    if [ ! -f "$transformed_filepath" ]; then
        print_error "Transformation failed - output file not created"
        exit 1
    fi
    
    if [ ! -s "$transformed_filepath" ]; then
        print_error "Transformation failed - output file is empty"
        exit 1
    fi
    
    print_info "Transformed data preview (first 3 lines):"
        head -n 3 "$transformed_filepath" | while read line; do
            echo "   $line" >&2  
   
    done
    
    print_success "Transformation completed - File saved: $transformed_filepath"
    
   
    if [ -f "${TRANSFORMED_FOLDER}/${TRANSFORMED_FILENAME}" ]; then
        print_success "Confirmed: ${TRANSFORMED_FILENAME} is in the '${TRANSFORMED_FOLDER}' folder"
    fi
    
    echo "$transformed_filepath"  
}



load_data() {
    local transformed_filepath="$1"
    create_folder "$GOLD_FOLDER"
    print_step "LOAD - Loading Data to Gold Directory"
    
    if [ ! -f "$transformed_filepath" ]; then
        print_error "Transformed file not found: $transformed_filepath"
        exit 1
    fi
    
    local gold_filepath="${GOLD_FOLDER}/${TRANSFORMED_FILENAME}"
    
    print_info "Source file: $transformed_filepath"
    print_info "Destination: $gold_filepath"
    

    if cp "$transformed_filepath" "$gold_filepath"; then
        print_success "Successfully copied file to Gold directory"
    else
        print_error "Failed to copy file to Gold directory"
        exit 1
    fi
    

    if [ -f "$gold_filepath" ]; then
        local gold_lines=$(wc -l < "$gold_filepath")
        print_info "Gold file contains $gold_lines lines"
        print_success "Confirmed: File successfully loaded into '${GOLD_FOLDER}' folder"
        
        print_info "Final data preview (first 3 lines):"
            head -n 3 "$gold_filepath" | while read line; do
                echo "   $line" >&2  
        done
    else
        print_error "File verification failed - file not found in Gold folder"
        exit 1
    fi
    
    print_success "Load phase completed - File available: $gold_filepath"
    echo "$gold_filepath"  
}




main() {
    print_step "Starting ETL Pipeline with URL: $CSV_URL"

    raw_filepath=$(extract_data)
    
    if [ -z "$raw_filepath" ]; then
        echo "ERROR: extract_data returned empty string!"
        exit 1
    fi
    
    if [ ! -f "$raw_filepath" ]; then
        echo "ERROR: File '$raw_filepath' does not exist!"
        exit 1
    fi
    

    transformed_filepath=$(transform_data "$raw_filepath")
   
    if [ -z "$transformed_filepath" ]; then
        echo "ERROR: transform_data returned empty string!"
        exit 1
    fi
    
    if [ ! -f "$transformed_filepath" ]; then
        echo "ERROR: Transformed file '$transformed_filepath' does not exist!"
        exit 1
    fi
    
    
    # Debug load_data
    gold_filepath=$(load_data "$transformed_filepath")
    print_success "ETL Pipeline completed successfully!"
}

# execution  
main "$@"
