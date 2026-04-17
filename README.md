# TranslateAPI Shell SDK

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-forcekeys.com-blue.svg)](https://translate.forcekeys.com/docs)
[![Platform](https://img.shields.io/badge/Platform-Bash%2FShell-blue.svg)](https://www.gnu.org/software/bash/)

Official Bash/Shell client for the TranslateAPI translation service. Translate text, documents, and images between 70+ languages directly from your terminal or shell scripts. Perfect for automation, CI/CD pipelines, and system administration tasks.

## Features

- **Text Translation**: Translate text between 70+ languages
- **Document Translation**: Support for PDF, DOCX, TXT files
- **Image OCR**: Extract and translate text from images
- **Language Detection**: Automatically detect language of text
- **Batch Translation**: Translate multiple texts in a single request
- **Account Management**: Check usage, credits, and account info
- **Zero Dependencies**: Only requires `curl` and `jq`
- **Cross-Platform**: Works on Linux, macOS, and Windows (WSL/Git Bash)
- **Easy Integration**: Simple command-line interface
- **JSON Output**: Structured output for scripting

## Installation

### Quick Install

```bash
# Download the script
curl -L https://raw.githubusercontent.com/forcekeys/translate-api-shell/main/translate.sh -o translate.sh
chmod +x translate.sh

# Or clone the repository
git clone https://github.com/forcekeys/translate-api-shell.git
cd translate-api-shell
chmod +x translate.sh
```

### System-wide Installation

```bash
# Install to /usr/local/bin
sudo curl -L https://raw.githubusercontent.com/forcekeys/translate-api-shell/main/translate.sh -o /usr/local/bin/translate
sudo chmod +x /usr/local/bin/translate

# Now you can use it from anywhere
translate --help
```

### Package Manager (Coming Soon)

```bash
# Homebrew (macOS)
brew install translate-api

# apt (Ubuntu/Debian)
sudo apt install translate-api

# yum (RHEL/CentOS)
sudo yum install translate-api
```

## Quick Start

### 1. Get Your API Key

First, sign up at [translate.forcekeys.com](https://translate.forcekeys.com) to get your free API key.

### 2. Set Your API Key

```bash
# Set as environment variable
export TRANSLATE_API_KEY="your_api_key_here"

# Or create a config file
echo 'TRANSLATE_API_KEY="your_api_key_here"' > ~/.translate-api
```

### 3. Basic Usage

```bash
# Translate text
./translate.sh translate "Hello, world!" en fr

# Auto-detect source language
./translate.sh translate "Bonjour le monde" auto en

# Get account information
./translate.sh account

# List supported languages
./translate.sh languages
```

## Comprehensive Examples

### Text Translation

```bash
# Basic translation
./translate.sh translate "Hello, how are you?" en es

# Translation with formality control
./translate.sh translate "Hello, how are you?" en de --formality formal

# Translation with context hint
./translate.sh translate "The bank is closed on Sunday." en fr --context financial

# Save translation to file
./translate.sh translate "Hello, world!" en fr > translation.txt

# Use in a pipeline
echo "Hello, world!" | ./translate.sh translate - en fr
```

### Document Translation

```bash
# Translate a document file
./translate.sh translate-file document.pdf en es translated.txt

# Translate multiple documents
for file in *.pdf; do
  ./translate.sh translate-file "$file" en es "${file%.pdf}_translated.txt"
done

# Translate with progress indicator
./translate.sh translate-file large_document.pdf en de output.txt --progress
```

### Image OCR and Translation

```bash
# Extract text from image and translate
./translate.sh ocr receipt.png en fr

# OCR with image enhancement
./translate.sh ocr blurry_image.png en es --enhance

# Save OCR results to JSON
./translate.sh ocr document.jpg en de --json > results.json
```

### Language Detection

```bash
# Detect language of text
./translate.sh detect "Bonjour le monde"

# Detect with confidence scores
./translate.sh detect "Hola, cómo estás?" --verbose

# Detect language of file content
./translate.sh detect-file text.txt
```

### Batch Translation

```bash
# Translate multiple texts from a file
echo -e "Hello\nGoodbye\nThank you" > texts.txt
./translate.sh batch texts.txt en de translations.txt

# Translate CSV file
./translate.sh batch data.csv en es results.csv --format csv

# Batch translate with parallel processing
./translate.sh batch large_file.txt en fr output.txt --parallel 4
```

### Account Information

```bash
# Get account details
./translate.sh account

# Get usage statistics
./translate.sh account --usage

# Check remaining credits
./translate.sh account --balance

# Export account info as JSON
./translate.sh account --json > account.json
```

### Supported Languages

```bash
# List all supported languages
./translate.sh languages

# List with flags and names
./translate.sh languages --verbose

# Filter languages by region
./translate.sh languages --region europe

# Export languages as CSV
./translate.sh languages --format csv > languages.csv
```

## Advanced Usage

### Configuration File

Create `~/.translate-api`:

```bash
# API Configuration
TRANSLATE_API_KEY="your_api_key_here"
TRANSLATE_API_URL="https://api.translate.forcekeys.com/api/v1"

# Default settings
DEFAULT_SOURCE_LANG="en"
DEFAULT_TARGET_LANG="fr"
DEFAULT_OUTPUT_FORMAT="text"

# Proxy settings (optional)
HTTP_PROXY="http://proxy.example.com:8080"
HTTPS_PROXY="http://proxy.example.com:8080"
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TRANSLATE_API_KEY` | Your API key | Required |
| `TRANSLATE_API_URL` | API base URL | `https://api.translate.forcekeys.com/api/v1` |
| `TRANSLATE_DEFAULT_SOURCE` | Default source language | `auto` |
| `TRANSLATE_DEFAULT_TARGET` | Default target language | `en` |
| `TRANSLATE_OUTPUT_FORMAT` | Output format | `text` |
| `TRANSLATE_TIMEOUT` | Request timeout (seconds) | `30` |
| `HTTP_PROXY` | HTTP proxy URL | None |
| `HTTPS_PROXY` | HTTPS proxy URL | None |

### Command Reference

#### translate
```bash
./translate.sh translate <text> <source> <target> [options]
```

Options:
- `--formality <level>`: "formal" or "informal"
- `--context <hint>`: Context hint (e.g., "financial", "medical")
- `--json`: Output as JSON
- `--quiet`: Suppress non-essential output
- `--progress`: Show progress indicator

#### translate-file
```bash
./translate.sh translate-file <input> <source> <target> <output> [options]
```

Options:
- `--format <format>`: Input format (pdf, docx, txt)
- `--pages <range>`: Page range (e.g., "1-5,10")
- `--preserve-layout`: Preserve document layout
- `--json`: Output as JSON

#### ocr
```bash
./translate.sh ocr <image> <source> <target> [options]
```

Options:
- `--enhance`: Apply image enhancement
- `--lang <language>`: Expected language in image
- `--confidence`: Show confidence score
- `--json`: Output as JSON

#### detect
```bash
./translate.sh detect <text> [options]
```

Options:
- `--verbose`: Show detailed information
- `--alternatives`: Show alternative possibilities
- `--json`: Output as JSON

#### batch
```bash
./translate.sh batch <input> <source> <target> <output> [options]
```

Options:
- `--format <format>`: Input format (txt, csv, json)
- `--delimiter <char>`: CSV delimiter
- `--parallel <n>`: Number of parallel requests
- `--progress`: Show progress bar

#### languages
```bash
./translate.sh languages [options]
```

Options:
- `--verbose`: Show detailed information
- `--region <region>`: Filter by region
- `--format <format>`: Output format (text, json, csv)

#### account
```bash
./translate.sh account [options]
```

Options:
- `--usage`: Show usage statistics
- `--balance`: Show balance information
- `--json`: Output as JSON

### Output Formats

#### Text Output (Default)
```bash
./translate.sh translate "Hello" en fr
# Output: Bonjour
```

#### JSON Output
```bash
./translate.sh translate "Hello" en fr --json
# Output: {"translatedText": "Bonjour", "sourceLang": "en", "targetLang": "fr", "charactersUsed": 5}
```

#### CSV Output
```bash
./translate.sh languages --format csv
# Output: code,name,flag
# en,English,🇺🇸
# fr,French,🇫🇷
```

### Error Handling

```bash
# Check exit codes
if ./translate.sh translate "Hello" en fr > /dev/null 2>&1; then
  echo "Success"
else
  echo "Error: $?"
fi

# Get error details
./translate.sh translate "Hello" en fr 2> error.log

# Retry on failure
for i in {1..3}; do
  if ./translate.sh translate "Hello" en fr; then
    break
  fi
  sleep 1
done
```

## Integration Examples

### Shell Script Integration

```bash
#!/bin/bash
# translate-document.sh

set -e

API_KEY="${TRANSLATE_API_KEY:-$1}"
INPUT_FILE="$2"
SOURCE_LANG="${3:-en}"
TARGET_LANG="${4:-fr}"
OUTPUT_FILE="${5:-${INPUT_FILE%.*}_${TARGET_LANG}.txt}"

if [ -z "$API_KEY" ]; then
  echo "Error: API key required"
  echo "Usage: $0 <api_key> <input_file> [source_lang] [target_lang] [output_file]"
  exit 1
fi

export TRANSLATE_API_KEY="$API_KEY"

echo "Translating $INPUT_FILE from $SOURCE_LANG to $TARGET_LANG..."
./translate.sh translate-file "$INPUT_FILE" "$SOURCE_LANG" "$TARGET_LANG" "$OUTPUT_FILE"

echo "Translation saved to $OUTPUT_FILE"
```

### CI/CD Pipeline Integration

```yaml
# .gitlab-ci.yml
translate-docs:
  stage: deploy
  script:
    - export TRANSLATE_API_KEY="$TRANSLATE_API_KEY"
    - ./translate.sh translate-file README.md en fr README.fr.md
    - ./translate.sh translate-file docs/api.md en es docs/api.es.md
  artifacts:
    paths:
      - README.fr.md
      - docs/api.es.md
```

### System Monitoring

```bash
#!/bin/bash
# monitor-usage.sh

# Check account usage daily
USAGE=$(./translate.sh account --json | jq '.planLimits.todayUsed')
LIMIT=$(./translate.sh account --json | jq '.planLimits.dailyTranslations')
PERCENTAGE=$((USAGE * 100 / LIMIT))

if [ "$PERCENTAGE" -gt 90 ]; then
  echo "Warning: Translation usage at ${PERCENTAGE}%" | mail -s "TranslateAPI Usage Alert" admin@example.com
fi
```

### Webhook Integration

```bash
#!/bin/bash
# translate-webhook.sh

# Read JSON payload from stdin
PAYLOAD=$(cat)
TEXT=$(echo "$PAYLOAD" | jq -r '.text')
TARGET=$(echo "$PAYLOAD" | jq -r '.target // "en"')

# Translate the text
TRANSLATION=$(./translate.sh translate "$TEXT" auto "$TARGET")

# Return JSON response
echo '{"translatedText": "'"$TRANSLATION"'"}'
```

## Error Codes

The script returns the following exit codes:

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | API error |
| 4 | Network error |
| 5 | File error |
| 6 | Configuration error |

## Rate Limits

Rate limits vary by plan:

| Plan | Requests/Minute | Monthly Requests | Max Characters/Request |
|------|----------------|------------------|------------------------|
| Free | 10 | 500/day | 2,000 |
| Starter | 60 | 50,000 | 5,000 |
| Professional | 300 | 1,000,000 | 10,000 |
| Enterprise | Unlimited | Unlimited | Unlimited |

## Troubleshooting

### Common Issues

1. **Permission denied**
   ```bash
   chmod +x translate.sh
   ```

2. **curl not found**
   ```bash
   # Install curl
   sudo apt install curl  # Ubuntu/Debian
   sudo yum install curl  # RHEL/CentOS
   brew install curl      # macOS
   ```

3. **jq not found**
   ```bash
   # Install jq
   sudo apt install jq    # Ubuntu/Debian
   sudo yum install jq    # RHEL/CentOS
   brew install jq        # macOS
   ```

4. **API key not set**
   ```bash
   export TRANSLATE_API_KEY="your_api_key_here"
   ```

### Debug Mode

```bash
# Enable debug output
export TRANSLATE_DEBUG=1
./translate.sh translate "Hello" en fr

# Or use verbose flag
./translate.sh translate "Hello" en fr --verbose
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

- **Documentation**: [translate.forcekeys.com/docs](https://translate.forcekeys.com/docs)
- **Issues**: [GitHub Issues](https://github.com/forcekeys/translate-api-shell/issues)
- **Email**: support@forcekeys.com
- **Discord**: [Join our Discord](https://discord.gg/forcekeys)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [TranslateAPI Python SDK](https://github.com/forcekeys/translate-api-python)
- [TranslateAPI PHP SDK](https://github.com/forcekeys/translate-api-php)
- [TranslateAPI Java SDK](https://github.com/forcekeys/translate-api-java)
- [TranslateAPI JavaScript SDK](https://github.com/forcekeys/translate-api-js)
- [TranslateAPI .NET SDK](https://github.com/forcekeys/translate-api-dotnet)

