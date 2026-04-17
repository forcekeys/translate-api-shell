#!/bin/bash

# TranslateAPI Shell SDK
# https://github.com/forcekeys/translate-api-shell

set -e

API_KEY="${TRANSLATE_API_KEY:-}"
API_URL="${TRANSLATE_API_URL:-https://api.translate.forcekeys.com/api/v1}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error() { echo -e "${RED}Error: $1${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}$1${NC}"; }
info() { echo -e "${YELLOW}$1${NC}"; }

check_key() {
    if [[ -z "$API_KEY" ]]; then
        error "API key not set. Use: export TRANSLATE_API_KEY=your_api_key"
    fi
}

call_api() {
    local endpoint="$1"
    local method="${2:-POST}"
    local data="$3"
    
    if [[ "$method" == "GET" ]]; then
        curl -s -X GET "${API_URL}/${endpoint}" \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json"
    else
        curl -s -X "$method" "${API_URL}/${endpoint}" \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    fi
}

cmd_translate() {
    check_key
    local text="$1"
    local source="${2:-auto}"
    local target="${3:-en}"
    
    [[ -z "$text" ]] && error "Usage: translate <text> <source_lang> <target_lang>"
    
    local response=$(call_api "translate" "POST" "{\"text\":\"$text\",\"source_lang\":\"$source\",\"target_lang\":\"$target\"}")
    echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('translated_text',''))"
}

cmd_translate_file() {
    check_key
    local input="$1"
    local source="$2"
    local target="$3"
    local output="$4"
    
    [[ ! -f "$input" ]] && error "Input file not found: $input"
    
    # Upload and translate
    local response=$(call_api "translate-file" "POST" "{\"filename\":\"$input\"}")
    echo "$response"
}

cmd_detect() {
    check_key
    local text="$1"
    [[ -z "$text" ]] && error "Usage: detect <text>"
    
    call_api "detect" "POST" "{\"text\":\"$text\"}"
}

cmd_languages() {
    call_api "languages" "GET"
}

cmd_account() {
    check_key
    call_api "account" "GET"
}

# Main command router
case "${1:-}" in
    translate)
        shift
        cmd_translate "$@"
        ;;
    translate-file)
        shift
        cmd_translate_file "$@"
        ;;
    detect)
        shift
        cmd_detect "$@"
        ;;
    languages)
        cmd_languages
        ;;
    account)
        cmd_account
        ;;
    -h|--help|help)
        echo "TranslateAPI Shell SDK"
        echo ""
        echo "Usage: translate <command> [options]"
        echo ""
        echo "Commands:"
        echo "  translate <text> <source> <target>  Translate text"
        echo "  translate-file <file> <source> <target> <output>  Translate file"
        echo "  detect <text>                      Detect language"
        echo "  languages                          List supported languages"
        echo "  account                            Get account info"
        ;;
    *)
        error "Unknown command: ${1:-}"
        ;;
esac