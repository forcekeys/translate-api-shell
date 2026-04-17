#!/bin/bash

# TranslateAPI Shell SDK
# Official shell client for the TranslateAPI translation service.
# https://github.com/forcekeys/translate-api-shell
#
# Usage:
#   source translate.sh
#   translate_api_key="your_api_key"
#   translate_text "Hello, world!" "en" "fr"
#
# Or as standalone script:
#   ./translate.sh translate "Hello, world!" "en" "fr"

set -e

# Default configuration
TRANSLATE_API_BASE_URL="https://api.translate.forcekeys.com/api/v1"
TRANSLATE_API_TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error handling
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

info() {
    echo -e "${BLUE}Info: $1${NC}"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

# Check if curl is available
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed"
    fi
    
    if ! command -v jq &> /dev/null; then
        warn "jq is recommended for JSON parsing. Install with: brew install jq (macOS) or apt-get install jq (Linux)"
        # We'll use grep/sed as fallback
    fi
}

# Make API request
make_request() {
    local endpoint="$1"
    local method="$2"
    local data="$3"
    local file_path="$4"
    
    local url="${TRANSLATE_API_BASE_URL}/${endpoint}"
    local curl_cmd="curl -s --max-time ${TRANSLATE_API_TIMEOUT}"
    
    # Add headers
    if [ -n "$translate_api_key" ]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $translate_api_key'"
    else
        error "API key not set. Set translate_api_key variable or use --api-key option"
    fi
    
    curl_cmd="$curl_cmd -H 'User-Agent: TranslateAPI-Shell/1.0.0'"
    
    # Handle different request types
    if [ "$method" = "POST" ]; then
        if [ -n "$file_path" ]; then
            # File upload (multipart/form-data)
            curl_cmd="$curl_cmd -F 'file=@$file_path'"
            if [ -n "$data" ]; then
                # Parse additional form data
                IFS='&' read -ra PARAMS <<< "$data"
                for param in "${PARAMS[@]}"; do
                    curl_cmd="$curl_cmd -F '$param'"
                done
            fi
        elif [ -n "$data" ]; then
            # JSON data
            curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
        fi
        curl_cmd="$curl_cmd -X POST"
    elif [ "$method" = "GET" ]; then
        curl_cmd="$curl_cmd -X GET"
    fi
    
    curl_cmd="$curl_cmd '$url'"
    
    # Execute curl command
    local response
    response=$(eval "$curl_cmd" 2>/dev/null || echo "{\"status\":\"error\",\"message\":\"Network error\"}")
    
    # Check for errors
    if echo "$response" | grep -q '"status":"error"'; then
        local error_msg
        if command -v jq &> /dev/null; then
            error_msg=$(echo "$response" | jq -r '.message // "Unknown error"')
        else
            error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        fi
        error "$error_msg"
    fi
    
    echo "$response"
}

# Parse JSON response (jq or fallback)
parse_json() {
    local json="$1"
    local key="$2"
    
    if command -v jq &> /dev/null; then
        echo "$json" | jq -r "$key"
    else
        # Simple grep/sed fallback for common patterns
        case "$key" in
            ".translated_text")
                echo "$json" | grep -o '"translated_text":"[^"]*"' | cut -d'"' -f4
                ;;
            ".text")
                echo "$json" | grep -o '"text":"[^"]*"' | cut -d'"' -f4
                ;;
            ".language")
                echo "$json" | grep -o '"language":"[^"]*"' | cut -d'"' -f4
                ;;
            ".confidence")
                echo "$json" | grep -o '"confidence":[0-9.]*' | cut -d':' -f2
                ;;
            ".characters_used")
                echo "$json" | grep -o '"characters_used":[0-9]*' | cut -d':' -f2
                ;;
            ".processing_time_ms")
                echo "$json" | grep -o '"processing_time_ms":[0-9]*' | cut -d':' -f2
                ;;
            *)
                echo "$json"
                ;;
        esac
    fi
}

# Translate text
translate_text() {
    local text="$1"
    local target_lang="$2"
    local source_lang="${3:-}"
    local formality="${4:-}"
    
    local data="{\"text\":\"$text\",\"target_lang\":\"$target_lang\"}"
    
    if [ -n "$source_lang" ]; then
        data=$(echo "$data" | sed 's/}$/, "source_lang":"'"$source_lang"'"}/')
    fi
    
    if [ -n "$formality" ]; then
        data=$(echo "$data" | sed 's/}$/, "formality":"'"$formality"'"}/')
    fi
    
    local response
    response=$(make_request "translate" "POST" "$data")
    
    local translated_text
    translated_text=$(parse_json "$response" ".translated_text")
    
    echo "$translated_text"
    
    # Print additional info if verbose
    if [ "${TRANSLATE_VERBOSE:-0}" -eq 1 ]; then
        local source_lang_result
        local characters_used
        local processing_time
        
        source_lang_result=$(parse_json "$response" ".source_lang")
        characters_used=$(parse_json "$response" ".characters_used")
        processing_time=$(parse_json "$response" ".processing_time_ms")
        
        echo "Source language: $source_lang_result"
        echo "Characters used: $characters_used"
        echo "Processing time: ${processing_time}ms"
    fi
}

# Translate document
translate_document() {
    local file_path="$1"
    local target_lang="$2"
    local source_lang="${3:-}"
    
    if [ ! -f "$file_path" ]; then
        error "File not found: $file_path"
    fi
    
    local data="target_lang=$target_lang"
    if [ -n "$source_lang" ]; then
        data="$data&source_lang=$source_lang"
    fi
    
    local response
    response=$(make_request "translate/document" "POST" "$data" "$file_path")
    
    local translated_text
    translated_text=$(parse_json "$response" ".translated_text")
    
    echo "$translated_text"
    
    # Print additional info if verbose
    if [ "${TRANSLATE_VERBOSE:-0}" -eq 1 ]; then
        local pages
        local characters_used
        local processing_time
        
        pages=$(parse_json "$response" ".pages")
        characters_used=$(parse_json "$response" ".characters_used")
        processing_time=$(parse_json "$response" ".processing_time_ms")
        
        echo "Pages: $pages"
        echo "Characters used: $characters_used"
        echo "Processing time: ${processing_time}ms"
    fi
}

# Extract text from image (OCR)
ocr_image() {
    local file_path="$1"
    local lang="${2:-}"
    local enhance="${3:-false}"
    
    if [ ! -f "$file_path" ]; then
        error "File not found: $file_path"
    fi
    
    local data=""
    if [ -n "$lang" ]; then
        data="lang=$lang"
    fi
    
    if [ "$enhance" = "true" ]; then
        if [ -n "$data" ]; then
            data="$data&enhance=true"
        else
            data="enhance=true"
        fi
    fi
    
    local response
    response=$(make_request "ocr" "POST" "$data" "$file_path")
    
    local text
    text=$(parse_json "$response" ".text")
    
    echo "$text"
    
    # Print additional info if verbose
    if [ "${TRANSLATE_VERBOSE:-0}" -eq 1 ]; then
        local confidence
        local language_detected
        local processing_time
        
        confidence=$(parse_json "$response" ".confidence")
        language_detected=$(parse_json "$response" ".language_detected")
        processing_time=$(parse_json "$response" ".processing_time_ms")
        
        echo "Confidence: ${confidence}%"
        echo "Language detected: $language_detected"
        echo "Processing time: ${processing_time}ms"
    fi
}

# Detect language
detect_language() {
    local text="$1"
    
    local data="{\"text\":\"$text\"}"
    local response
    response=$(make_request "detect" "POST" "$data")
    
    local language
    local confidence
    
    language=$(parse_json "$response" ".language")
    confidence=$(parse_json "$response" ".confidence")
    
    echo "$language (${confidence}%)"
    
    # Print alternatives if verbose
    if [ "${TRANSLATE_VERBOSE:-0}" -eq 1 ] && command -v jq &> /dev/null; then
        local alternatives
        alternatives=$(echo "$response" | jq -r '.alternatives[] | "  \(.language): \(.confidence)%"')
        if [ -n "$alternatives" ]; then
            echo "Alternatives:"
            echo "$alternatives"
        fi
    fi
}

# Get supported languages
get_supported_languages() {
    local response
    response=$(make_request "languages" "GET")
    
    if command -v jq &> /dev/null; then
        echo "$response" | jq -r '.languages[] | "\(.code): \(.name) \(.flag // "")"'
    else
        # Simple output without jq
        echo "$response" | grep -o '"code":"[^"]*","name":"[^"]*"' | \
            sed 's/"code":"\([^"]*\)","name":"\([^"]*\)"/\1: \2/g'
    fi
}

# Batch translate
batch_translate() {
    local texts_file="$1"
    local target_lang="$2"
    local source_lang="${3:-}"
    
    if [ ! -f "$texts_file" ]; then
        error "File not found: $texts_file"
    fi
    
    # Read texts from file (one per line)
    local texts=()
    while IFS= read -r line || [ -n "$line" ]; do
        texts+=("$line")
    done < "$texts_file"
    
    # Build JSON array
    local texts_json="["
    for text in "${texts[@]}"; do
        texts_json="$texts_json\"$text\","
    done
    texts_json="${texts_json%,}]"
    
    local data="{\"texts\":$texts_json,\"target_lang\":\"$target_lang\"}"
    
    if [ -n "$source_lang" ]; then
        data=$(echo "$data" | sed 's/}$/, "source_lang":"'"$source_lang"'"}/')
    fi
    
    local response
    response=$(make_request "translate/batch" "POST" "$data")
    
    if command -v jq &> /dev/null; then
        echo "$response" | jq -r '.translations[] | "\(.original) => \(.translated)"'
    else
        # Simple output
        echo "$response" | grep -o '"original":"[^"]*","translated":"[^"]*"' | \
            sed 's/"original":"\([^"]*\)","translated":"\([^"]*\)"/\1 => \2/g'
    fi
}

# Get account info
get_account_info() {
    local response
    response=$(make_request "account" "GET")
    
    if command -v jq &> /dev/null; then
        echo "$response" | jq -r '.account | "Email: \(.email)\nName: \(.name // "N/A")\nPlan: \(.plan)\nStatus: \(.status)\nDaily translations: \(.plan_limits.today_used)/\(.plan_limits.daily_translations)\nBalance: $\(.balance.available)\nTotal spent: $\(.balance.total_spent)"'
    else
        # Simple output
        echo "Account information requires jq for proper parsing."
        echo "Install jq or use --verbose flag to see raw JSON."
        if [ "${TRANSLATE_VERBOSE:-0}" -eq 1 ]; then
            echo "$response"
        fi
    fi
}

# Main function for standalone script
main() {
    check_dependencies
    
    local command="$1"
    shift
    
    case "$command" in
        "translate")
            translate_text "$@"
            ;;
        "translate-document")
            translate_document "$@"
            ;;
        "ocr")
            ocr_image "$@"
            ;;
        "detect")
            detect_language "$@"
            ;;
        "languages")
            get_supported_languages "$@"
            ;;
        "batch")
            batch_translate "$@"
            ;;
        "account")
            get_account_info "$@"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            error "Unknown command: $command. Use 'help' for usage information."
            ;;
    esac
}

# Show help
show_help() {
    cat << EOF
TranslateAPI Shell SDK

Usage:
  ./translate.sh <command> [options]

Commands:
  translate <text> <target_lang> [source_lang] [formality]
    Translate text

  translate-document <file_path> <target_lang> [source_lang]
    Translate document (PDF, DOCX, TXT)

  ocr <image_path> [lang] [enhance]
    Extract text from image

  detect <text>
    Detect language of text

  languages
    Get supported languages

  batch <texts_file> <target_lang> [source_lang]
    Batch translate texts from file

  account
    Get account information

Environment variables:
  translate_api_key      Your API key (required)
  TRANSLATE_API_BASE_URL API base URL (default: https://api.translate.forcekeys.com/api/v1)
  TRANSLATE_VERBOSE      Set to 1 for verbose output

Examples:
  translate_api_key="your_key" ./translate.sh translate "Hello" "en" "fr"
  ./translate.sh --api-key "your_key" translate "Hello" "en" "fr"
  ./translate.sh translate-document document.pdf "en" "es"
  ./translate.sh ocr image.png "en" true

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --api-key)
                translate_api_key="$2"
                shift 2
                ;;
            --base-url)
                TRANSLATE_API_BASE_URL="$2"
                shift 2
                ;;
            --verbose)
                TRANSLATE_VERBOSE=1
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    main "$@"
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_args "$@"
fi