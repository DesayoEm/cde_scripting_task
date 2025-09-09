if [ -f ".env" ]; then
    source .env
    echo "Loaded configuration from .env file"
else
    echo "ERROR: .env file not found!"
    exit 1
fi

test_connection() {
    echo "Testing database connection..."
    
    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c '\q' 2>/dev/null; then
        echo "Cannot connect to PostgreSQL server. Please check your connection settings."
        echo "Connection details:"
        echo "  Host: $DB_HOST" 
        echo "  Port: $DB_PORT" 
        echo "  User: $DB_USER"
        echo "  Database: postgres (for connection test)"
        exit 1
    fi
    
    echo "Database connection successful"
}

create_database() {
    echo "Checking if database '$DB_NAME' exists..."
    
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        echo "Database '$DB_NAME' already exists"
    else
        echo "Creating database '$DB_NAME'..."
        createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"
        echo "Database '$DB_NAME' created successfully"
    fi
}

# remove file ext and make SQL-safe
sanitize_table_name() {
    local filename="$1"
    basename "$filename" .csv | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_\|_$//g'
}



get_csv_headers() {
    local csv_file="$1"
    head -n 1 "$csv_file" | sed 's/,/\n/g' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/[^a-zA-Z0-9]/_/g' | tr '[:upper:]' '[:lower:]'
}


create_table_from_csv() {
    local csv_file="$1"
    local table_name="$2"
    
    echo "Creating table '$table_name' from CSV structure..."
    
    local headers
    headers=$(get_csv_headers "$csv_file")
    
    local column_defs=""
    while IFS= read -r header; do
        if [ -n "$header" ]; then
            column_defs="$column_defs\"$header\" TEXT,"
        fi
    done <<< "$headers"
    
    column_defs=${column_defs%,}
    
    local create_sql="CREATE TABLE IF NOT EXISTS \"$table_name\" ($column_defs);"
    
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$create_sql" > /dev/null; then
        echo "Table '$table_name' created successfully"
    else
        echo "Failed to create table '$table_name'"
        return 1
    fi
}


import_csv() {
    local csv_file="$1"
    local table_name
    table_name=$(sanitize_table_name "$csv_file")
    
    echo "Processing file: $csv_file"
    echo "Target table: $table_name"
    
    if [ ! -r "$csv_file" ]; then
        echo "Cannot read file: $csv_file"
        return 1
    fi
    
    if [ ! -s "$csv_file" ]; then
        warning "File is empty: $csv_file"
        return 1
    fi

    if [ "$CREATE_TABLES" = "true" ]; then
        create_table_from_csv "$csv_file" "$table_name" || return 1
    fi
   
    
    local abs_csv_path
    abs_csv_path=$(realpath "$csv_file")
    
    echo "Importing data from $csv_file to table $table_name..."
    
    local copy_sql="\\COPY \"$table_name\" FROM '$abs_csv_path' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '\"', ESCAPE '\"');"
    
    if echo "$copy_sql" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > /dev/null; then
    
        local row_count
        row_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM \"$table_name\";" | xargs)
        echo "Successfully imported $csv_file ($row_count rows)"
    else
        echo "Failed to import $csv_file"
        return 1
    fi
}

process_csv_files() {
    local csv_count=0
    local success_count=0
    local error_count=0
    
    echo "Processing CSV files in folder: $CSV_FOLDER"
    
    if [ ! -d "$CSV_FOLDER" ]; then
        echo "Folder does not exist: $CSV_FOLDER"
        exit 1
    fi
    
    while IFS= read -r -d '' csv_file; do
        csv_count=$((csv_count + 1))
        echo
        if import_csv "$csv_file"; then
            success_count=$((success_count + 1))
        else
            error_count=$((error_count + 1))
        fi
    done < <(find "$CSV_FOLDER" -name "*.csv" -type f -print0)
    
 
    echo "Total CSV files found: $csv_count"
    echo "Successfully imported: $success_count"
    echo "Failed imports: $error_count"
    
    if [ $csv_count -eq 0 ]; then
        warning "No CSV files found in $CSV_FOLDER"
        exit 1
    elif [ $error_count -gt 0 ]; then
        warning "Some imports failed. Please check the errors above."
        exit 1
    else
        echo "All CSV files imported successfully!"
    fi
}



main() { 
    echo "Starting CSV to PostgreSQL import process"
    echo "Database: $DB_NAME"
    echo "CSV Folder: $CSV_FOLDER"

    test_connection
    create_database
    process_csv_files
    
    echo "Import process completed"
}

# execution  
main "$@"
