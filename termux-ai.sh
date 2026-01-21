#!/data/data/com.termux/files/usr/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

CONFIG_DIR="$HOME/.config/termux-ai"
CONFIG_FILE="$CONFIG_DIR/config"
HISTORY_FILE="$CONFIG_DIR/history"
SESSION_FILE="$CONFIG_DIR/session_$(date +%Y%m%d_%H%M%S).txt"
API_KEYS_FILE="$CONFIG_DIR/api_keys"

init_config() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << EOF
DEFAULT_PROVIDER="sky"
IMAGE_PROVIDER="arta"
SAVE_HISTORY=true
SHOW_BANNER=true
EOF
    fi
    
    if [ ! -f "$HISTORY_FILE" ]; then
        touch "$HISTORY_FILE"
    fi
    
    if [ ! -f "$API_KEYS_FILE" ]; then
        touch "$API_KEYS_FILE"
    fi
    
    touch "$SESSION_FILE"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        DEFAULT_PROVIDER="sky"
        IMAGE_PROVIDER="arta"
        SAVE_HISTORY=true
        SHOW_BANNER=true
    fi
}

get_api_key() {
    local provider=$1
    if [ -f "$API_KEYS_FILE" ]; then
        grep "^${provider}=" "$API_KEYS_FILE" | cut -d'=' -f2-
    fi
}

save_api_key() {
    local provider=$1
    local key=$2
    
    if [ -f "$API_KEYS_FILE" ]; then
        if grep -q "^${provider}=" "$API_KEYS_FILE"; then
            sed -i "/^${provider}=/d" "$API_KEYS_FILE"
        fi
        echo "${provider}=${key}" >> "$API_KEYS_FILE"
    else
        echo "${provider}=${key}" > "$API_KEYS_FILE"
    fi
}

remove_api_key() {
    local provider=$1
    if [ -f "$API_KEYS_FILE" ]; then
        if grep -q "^${provider}=" "$API_KEYS_FILE"; then
            sed -i "/^${provider}=/d" "$API_KEYS_FILE"
            return 0
        else
            return 1
        fi
    fi
    return 1
}

list_api_keys() {
    if [ -f "$API_KEYS_FILE" ] && [ -s "$API_KEYS_FILE" ]; then
        echo -e "${CYAN}Stored API Keys:${NC}"
        while IFS='=' read -r provider key; do
            if [[ -n "$provider" && -n "$key" ]]; then
                local masked_key="${key:0:8}****${key: -4}"
                echo -e "  ${GREEN}$provider:${NC} $masked_key"
            fi
        done < "$API_KEYS_FILE"
    else
        echo -e "${YELLOW}No API keys stored${NC}"
    fi
}

save_to_history() {
    if [ "$SAVE_HISTORY" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$HISTORY_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $2" >> "$HISTORY_FILE"
        echo "---" >> "$HISTORY_FILE"
    fi
}

save_to_session() {
    echo "$1" >> "$SESSION_FILE"
}

show_banner() {
    if [ "$SHOW_BANNER" = "true" ]; then
        clear
        gum style \
            --foreground 212 --border double --border-foreground 212 \
            --padding "1 2" --margin "1 2" \
            "TERMUX-AI v3.0" \
            "Interactive AI Assistant"
        echo -e "\t\tBy Alienkrishn [Anon4You]"
    fi
}

build_tgpt_command() {
    local provider=$1
    local prompt=$2
    local extra_flags=$3
    
    local api_key=$(get_api_key "$provider")
    local command="tgpt"
    
    if [ -n "$api_key" ]; then
        case "$provider" in
            "openai")
                command="$command --provider openai --key \"$api_key\""
                ;;
            "deepseek")
                command="$command --provider deepseek --key \"$api_key\""
                ;;
            "groq")
                command="$command --provider groq --key \"$api_key\""
                ;;
            "gemini")
                command="$command --provider gemini --key \"$api_key\""
                ;;
            *)
                command="$command --provider $provider"
                ;;
        esac
    else
        command="$command --provider $provider"
    fi
    
    if [ -n "$extra_flags" ]; then
        command="$command $extra_flags"
    fi
    
    command="$command \"$prompt\""
    echo "$command"
}

show_main_menu() {
    while true; do
        show_banner
        
        echo -e "${CYAN}Main Menu${NC}\n"
        
        CHOICE=$(gum choose \
            --height=12 \
            --cursor="> " \
            --selected.foreground="87" \
            "Chat Mode" \
            "Shell Command Mode" \
            "Code Generation" \
            "Image Generation" \
            "Settings" \
            "API Keys Management" \
            "History" \
            "Session Log" \
            "Help" \
            "Credits" \
            "Exit")
        
        case "$CHOICE" in
            "Chat Mode")
                chat_mode
                ;;
            "Shell Command Mode")
                shell_mode
                ;;
            "Code Generation")
                code_mode
                ;;
            "Image Generation")
                image_mode
                ;;
            "Settings")
                settings_menu
                ;;
            "API Keys Management")
                api_keys_menu
                ;;
            "History")
                view_history
                ;;
            "Session Log")
                view_session_log
                ;;
            "Help")
                show_help
                ;;
            "Credits")
                show_credits
                ;;
            "Exit")
                echo -e "\n${GREEN}Goodbye!${NC}\n"
                exit 0
                ;;
        esac
    done
}

chat_mode() {
    show_banner
    echo -e "${CYAN}Chat Mode${NC}"
    echo -e "${YELLOW}Type 'exit' or 'quit' to return to menu${NC}"
    echo -e "${YELLOW}Type 'clear' to clear screen${NC}\n"
    
    while true; do
        QUESTION=$(gum input \
            --placeholder "Ask me anything..." \
            --prompt "> " \
            --width 80 \
            --header "Chat Mode | Provider: $DEFAULT_PROVIDER")
        
        if [[ "$QUESTION" == "exit" ]] || [[ "$QUESTION" == "quit" ]]; then
            return
        fi
        
        if [[ "$QUESTION" == "clear" ]]; then
            clear
            show_banner
            echo -e "${CYAN}Chat Mode${NC}\n"
            continue
        fi
        
        if [ -z "$QUESTION" ]; then
            continue
        fi
        
        save_to_session "User: $QUESTION"
        
        TGPT_CMD=$(build_tgpt_command "$DEFAULT_PROVIDER" "$QUESTION")
        eval "$TGPT_CMD"
        
        RESPONSE=$(eval "$TGPT_CMD --quiet")
        save_to_history "$QUESTION" "$RESPONSE"
        save_to_session "AI: $RESPONSE"
        
        echo
    done
}

shell_mode() {
    show_banner
    echo -e "${CYAN}Shell Command Mode${NC}"
    echo -e "${YELLOW}Type 'exit' or 'quit' to return to menu${NC}\n"
    
    while true; do
        QUESTION=$(gum input \
            --placeholder "What shell command do you need?" \
            --prompt "> " \
            --width 80 \
            --header "Shell Mode | Provider: $DEFAULT_PROVIDER")
        
        if [[ "$QUESTION" == "exit" ]] || [[ "$QUESTION" == "quit" ]]; then
            return
        fi
        
        if [ -z "$QUESTION" ]; then
            continue
        fi
        
        save_to_session "Shell Request: $QUESTION"
        
        TGPT_CMD=$(build_tgpt_command "$DEFAULT_PROVIDER" "$QUESTION" "-s")
        eval "$TGPT_CMD"
        
        echo
    done
}

code_mode() {
    show_banner
    echo -e "${CYAN}Code Generation Mode${NC}"
    echo -e "${YELLOW}Type 'exit' or 'quit' to return to menu${NC}\n"
    
    while true; do
        QUESTION=$(gum input \
            --placeholder "Describe the code you want..." \
            --prompt "> " \
            --width 80 \
            --header "Code Mode | Provider: $DEFAULT_PROVIDER")
        
        if [[ "$QUESTION" == "exit" ]] || [[ "$QUESTION" == "quit" ]]; then
            return
        fi
        
        if [ -z "$QUESTION" ]; then
            continue
        fi
        
        save_to_session "Code Request: $QUESTION"
        
        TGPT_CMD=$(build_tgpt_command "$DEFAULT_PROVIDER" "$QUESTION" "-c")
        eval "$TGPT_CMD"
        
        echo
    done
}

image_mode() {
    show_banner
    echo -e "${CYAN}Image Generation Mode${NC}"
    echo -e "${YELLOW}Type 'exit' or 'quit' to return to menu${NC}\n"
    
    while true; do
        PROMPT=$(gum input \
            --placeholder "Describe the image you want to generate..." \
            --prompt "> " \
            --width 80 \
            --header "Image Mode | Provider: arta")
        
        if [[ "$PROMPT" == "exit" ]] || [[ "$PROMPT" == "quit" ]]; then
            return
        fi
        
        if [ -z "$PROMPT" ]; then
            continue
        fi
        
        save_to_session "Image Request: $PROMPT"
        
        echo -e "\n${CYAN}Image Options:${NC}"
        
        MODEL=$(gum choose \
            --height=20 \
            --cursor="> " \
            --selected.foreground="87" \
            "Medieval" \
            "Vincent Van Gogh" \
            "F Dev" \
            "Low Poly" \
            "Dreamshaper-xl" \
            "Anima-pencil-xl" \
            "Biomech" \
            "Trash Polka" \
            "No Style" \
            "Cheyenne-xl" \
            "Chicano" \
            "Embroidery tattoo" \
            "Red and Black" \
            "Fantasy Art" \
            "Watercolor" \
            "Dotwork" \
            "Old school colored" \
            "Realistic tattoo" \
            "Japanese_2" \
            "Realistic-stock-xl" \
            "F Pro" \
            "RevAnimated" \
            "Katayama-mix-xl" \
            "SDXL L" \
            "Cor-epica-xl" \
            "Anime tattoo" \
            "New School" \
            "Death metal" \
            "Old School" \
            "Juggernaut-xl" \
            "Photographic" \
            "SDXL 1.0" \
            "Graffiti" \
            "Mini tattoo" \
            "Surrealism" \
            "Neo-traditional" \
            "On limbs black" \
            "Yamers-realistic-xl" \
            "Pony-xl" \
            "Playground-xl" \
            "Anything-xl" \
            "Flame design" \
            "Kawaii" \
            "Cinematic Art" \
            "Professional" \
            "Flux" \
            "Black Ink" \
            "Epicrealism-xl" \
            "High GPT4o")
        
        RATIO=$(gum choose \
            --height=10 \
            --cursor="> " \
            --selected.foreground="87" \
            "1:1" \
            "2:3" \
            "3:2" \
            "3:4" \
            "4:3" \
            "9:16" \
            "16:9" \
            "9:21" \
            "21:9")
        
        COUNT=$(gum input \
            --placeholder "Number of images (default: 1)" \
            --value "1" \
            --prompt "> ")
        
        NEGATIVE_PROMPT=$(gum input \
            --placeholder "Negative prompt (optional)" \
            --prompt "> ")
        
        echo -e "\n${YELLOW}Generating $COUNT image(s) with model: $MODEL, ratio: $RATIO${NC}"
        
        if [ -n "$NEGATIVE_PROMPT" ]; then
            tgpt --provider arta --img --img_count "$COUNT" --img_ratio "$RATIO" --img_negative "$NEGATIVE_PROMPT" "$PROMPT"
            save_to_session "Image generated: $PROMPT (Model: $MODEL, Ratio: $RATIO, Count: $COUNT, Negative: $NEGATIVE_PROMPT)"
        else
            tgpt --provider arta --img --img_count "$COUNT" --img_ratio "$RATIO" "$PROMPT"
            save_to_session "Image generated: $PROMPT (Model: $MODEL, Ratio: $RATIO, Count: $COUNT)"
        fi
        
        echo
    done
}

api_keys_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}API Keys Management${NC}\n"
        
        list_api_keys
        echo
        
        ACTION=$(gum choose \
            --height=7 \
            --cursor="> " \
            --selected.foreground="87" \
            "Add/Update API Key" \
            "Remove API Key" \
            "View API Keys" \
            "Test API Key" \
            "Back to Main Menu")
        
        case "$ACTION" in
            "Add/Update API Key")
                add_api_key
                ;;
            "Remove API Key")
                remove_api_key_menu
                ;;
            "View API Keys")
                show_banner
                echo -e "${CYAN}API Keys${NC}\n"
                list_api_keys
                echo
                gum input --placeholder "Press Enter to continue..." --prompt "> "
                ;;
            "Test API Key")
                test_api_key
                ;;
            "Back to Main Menu")
                return
                ;;
        esac
    done
}

add_api_key() {
    show_banner
    echo -e "${CYAN}Add/Update API Key${NC}\n"
    
    echo -e "${YELLOW}Select provider to add/update API key:${NC}"
    PROVIDER=$(gum choose \
        --height=8 \
        --cursor="> " \
        "openai" \
        "deepseek" \
        "gemini" \
        "groq" \
        "Back")
    
    if [[ "$PROVIDER" == "Back" ]]; then
        return
    fi
    
    echo -e "\n${YELLOW}Getting API key for $PROVIDER:${NC}"
    echo -e "${BLUE}Where to get API key:${NC}"
    
    case "$PROVIDER" in
        "openai")
            echo "Visit: https://platform.openai.com/api-keys"
            ;;
        "deepseek")
            echo "Visit: https://platform.deepseek.com/api-keys"
            ;;
        "gemini")
            echo "Visit: https://aistudio.google.com/apikey"
            ;;
        "groq")
            echo "Visit: https://console.groq.com/keys"
            ;;
    esac
    
    echo
    API_KEY=$(gum input \
        --placeholder "Paste your $PROVIDER API key here" \
        --prompt "> " \
        --password)
    
    if [ -z "$API_KEY" ]; then
        echo -e "${RED}No API key provided.${NC}"
        return
    fi
    
    save_api_key "$PROVIDER" "$API_KEY"
    echo -e "\n${GREEN}API key for $PROVIDER saved successfully!${NC}"
    gum spin --spinner dot --title "Saving..." -- sleep 1
}

remove_api_key_menu() {
    show_banner
    echo -e "${CYAN}Remove API Key${NC}\n"
    
    if [ ! -f "$API_KEYS_FILE" ] || [ ! -s "$API_KEYS_FILE" ]; then
        echo -e "${YELLOW}No API keys to remove.${NC}"
        gum spin --spinner dot --title "Loading..." -- sleep 1
        return
    fi
    
    echo -e "${YELLOW}Select API key to remove:${NC}"
    
    providers=()
    while IFS='=' read -r provider key; do
        if [[ -n "$provider" && -n "$key" ]]; then
            providers+=("$provider")
        fi
    done < "$API_KEYS_FILE"
    
    providers+=("Back")
    
    SELECTED=$(printf '%s\n' "${providers[@]}" | gum choose \
        --height=10 \
        --cursor="> " \
        --selected.foreground="87")
    
    if [[ "$SELECTED" == "Back" ]]; then
        return
    fi
    
    if gum confirm "Are you sure you want to remove API key for $SELECTED?"; then
        if remove_api_key "$SELECTED"; then
            echo -e "${GREEN}API key for $SELECTED removed.${NC}"
        else
            echo -e "${RED}Failed to remove API key for $SELECTED.${NC}"
        fi
    else
        echo -e "${YELLOW}Cancelled.${NC}"
    fi
    
    gum spin --spinner dot --title "Processing..." -- sleep 1
}

test_api_key() {
    show_banner
    echo -e "${CYAN}Test API Key${NC}\n"
    
    if [ ! -f "$API_KEYS_FILE" ] || [ ! -s "$API_KEYS_FILE" ]; then
        echo -e "${YELLOW}No API keys to test.${NC}"
        gum spin --spinner dot --title "Loading..." -- sleep 1
        return
    fi
    
    echo -e "${YELLOW}Select API key to test:${NC}"
    
    providers=()
    while IFS='=' read -r provider key; do
        if [[ -n "$provider" && -n "$key" ]]; then
            providers+=("$provider")
        fi
    done < "$API_KEYS_FILE"
    
    providers+=("Back")
    
    SELECTED=$(printf '%s\n' "${providers[@]}" | gum choose \
        --height=10 \
        --cursor="> " \
        --selected.foreground="87")
    
    if [[ "$SELECTED" == "Back" ]]; then
        return
    fi
    
    echo -e "\n${YELLOW}Testing $SELECTED API key...${NC}"
    
    local api_key=$(get_api_key "$SELECTED")
    if [ -z "$api_key" ]; then
        echo -e "${RED}No API key found for $SELECTED${NC}"
        return
    fi
    
    echo -e "${BLUE}Sending test query...${NC}"
    
    case "$SELECTED" in
        "openai")
            TGPT_CMD="tgpt --provider openai --key \"$api_key\" --quiet \"Hello, please respond with just 'API working' to confirm.\""
            ;;
        "deepseek")
            TGPT_CMD="tgpt --provider deepseek --key \"$api_key\" --quiet \"Hello, please respond with just 'API working' to confirm.\""
            ;;
        "gemini")
            TGPT_CMD="tgpt --provider gemini --key \"$api_key\" --quiet \"Hello, please respond with just 'API working' to confirm.\""
            ;;
        "groq")
            TGPT_CMD="tgpt --provider groq --key \"$api_key\" --quiet \"Hello, please respond with just 'API working' to confirm.\""
            ;;
        *)
            echo -e "${YELLOW}Testing not supported for $SELECTED${NC}"
            return
            ;;
    esac
    
    RESPONSE=$(eval "$TGPT_CMD" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
        echo -e "${GREEN}API key for $SELECTED is working!${NC}"
        echo -e "${BLUE}Response:${NC} $RESPONSE"
    else
        echo -e "${RED}API key for $SELECTED is NOT working${NC}"
        echo -e "${YELLOW}Please check your API key and try again.${NC}"
    fi
    
    echo
    gum input --placeholder "Press Enter to continue..." --prompt "> "
}

settings_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}Settings${NC}\n"
        
        SETTING=$(gum choose \
            --height=9 \
            --cursor="> " \
            --selected.foreground="87" \
            "Change AI Provider" \
            "Change Image Provider" \
            "Toggle History Saving" \
            "Toggle Banner" \
            "View Config File" \
            "Clear History" \
            "Back to Main Menu")
        
        case "$SETTING" in
            "Change AI Provider")
                change_provider
                ;;
            "Change Image Provider")
                change_image_provider
                ;;
            "Toggle History Saving")
                toggle_history
                ;;
            "Toggle Banner")
                toggle_banner
                ;;
            "View Config File")
                view_config
                ;;
            "Clear History")
                clear_history
                ;;
            "Back to Main Menu")
                return
                ;;
        esac
    done
}

change_provider() {
    show_banner
    echo -e "${CYAN}Select AI Provider${NC}\n"
    
    PROVIDER=$(gum choose \
        --height=12 \
        --selected.foreground="87" \
        "sky (Default)" \
        "phind" \
        "deepseek" \
        "gemini" \
        "groq" \
        "openai" \
        "ollama" \
        "kimi" \
        "isou" \
        "pollinations")
    
    PROVIDER_NAME=$(echo "$PROVIDER" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
    
    sed -i "s/^DEFAULT_PROVIDER=.*/DEFAULT_PROVIDER=\"$PROVIDER_NAME\"/" "$CONFIG_FILE"
    DEFAULT_PROVIDER="$PROVIDER_NAME"
    
    echo -e "\n${GREEN}Provider changed to: $PROVIDER_NAME${NC}"
    gum spin --spinner dot --title "Saving..." -- sleep 1
}

change_image_provider() {
    show_banner
    echo -e "${CYAN}Select Image Generation Provider${NC}\n"
    
    PROVIDER=$(gum choose \
        --height=4 \
        --selected.foreground="87" \
        "arta (Default)" \
        "pollinations" \
        "Back")
    
    if [[ "$PROVIDER" == "Back" ]]; then
        return
    fi
    
    PROVIDER_NAME=$(echo "$PROVIDER" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
    
    sed -i "s/^IMAGE_PROVIDER=.*/IMAGE_PROVIDER=\"$PROVIDER_NAME\"/" "$CONFIG_FILE"
    IMAGE_PROVIDER="$PROVIDER_NAME"
    
    echo -e "\n${GREEN}Image provider changed to: $PROVIDER_NAME${NC}"
    gum spin --spinner dot --title "Saving..." -- sleep 1
}

toggle_history() {
    if [ "$SAVE_HISTORY" = "true" ]; then
        SAVE_HISTORY="false"
        echo -e "${YELLOW}History saving disabled${NC}"
    else
        SAVE_HISTORY="true"
        echo -e "${GREEN}History saving enabled${NC}"
    fi
    
    sed -i "s/^SAVE_HISTORY=.*/SAVE_HISTORY=$SAVE_HISTORY/" "$CONFIG_FILE"
    gum spin --spinner dot --title "Saving..." -- sleep 1
}

toggle_banner() {
    if [ "$SHOW_BANNER" = "true" ]; then
        SHOW_BANNER="false"
        echo -e "${YELLOW}Banner disabled${NC}"
    else
        SHOW_BANNER="true"
        echo -e "${GREEN}Banner enabled${NC}"
    fi
    
    sed -i "s/^SHOW_BANNER=.*/SHOW_BANNER=$SHOW_BANNER/" "$CONFIG_FILE"
    gum spin --spinner dot --title "Saving..." -- sleep 1
}

view_config() {
    show_banner
    echo -e "${CYAN}Configuration File${NC}\n"
    
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        echo -e "${RED}Config file not found!${NC}"
    fi
    
    echo
    gum input --placeholder "Press Enter to continue..." --prompt "> "
}

clear_history() {
    if gum confirm "Are you sure you want to clear all history?"; then
        > "$HISTORY_FILE"
        echo -e "${GREEN}History cleared!${NC}"
        gum spin --spinner dot --title "Clearing..." -- sleep 1
    else
        echo -e "${YELLOW}Cancelled.${NC}"
    fi
}

view_history() {
    show_banner
    echo -e "${CYAN}Conversation History${NC}\n"
    
    if [ -s "$HISTORY_FILE" ]; then
        tail -50 "$HISTORY_FILE"
    else
        echo -e "${YELLOW}No history yet.${NC}"
    fi
    
    echo
    gum input --placeholder "Press Enter to continue..." --prompt "> "
}

view_session_log() {
    show_banner
    echo -e "${CYAN}Current Session Log${NC}\n"
    
    if [ -s "$SESSION_FILE" ]; then
        cat "$SESSION_FILE"
    else
        echo -e "${YELLOW}Session log is empty.${NC}"
    fi
    
    echo
    ACTIONS=$(gum choose \
        --height=3 \
        --cursor="> " \
        "Save to file" \
        "Clear session" \
        "Back")
    
    case "$ACTIONS" in
        "Save to file")
            SAVE_NAME=$(gum input \
                --placeholder "Enter filename to save session" \
                --value "session_backup_$(date +%Y%m%d_%H%M%S).txt")
            
            if [ -n "$SAVE_NAME" ]; then
                cp "$SESSION_FILE" "$SAVE_NAME"
                echo -e "${GREEN}Session saved to: $SAVE_NAME${NC}"
            fi
            ;;
        "Clear session")
            if gum confirm "Clear current session log?"; then
                > "$SESSION_FILE"
                echo -e "${GREEN}Session log cleared!${NC}"
            fi
            ;;
    esac
}

show_help() {
    show_banner
    echo -e "${CYAN}Termux-Ai Help${NC}\n"
    
    echo -e "${BOLD}Available Modes:${NC}"
    echo "Chat Mode: Regular conversation with AI"
    echo "Shell Mode: Generate and execute shell commands (like tgpt -s)"
    echo "Code Mode: Generate code snippets (like tgpt -c)"
    echo "Image Mode: Generate images from text (using arta provider)"
    echo ""
    echo -e "${BOLD}Commands in Chat Mode:${NC}"
    echo "exit/quit: Return to main menu"
    echo "clear: Clear the screen"
    echo ""
    echo -e "${BOLD}Providers:${NC}"
    echo "sky (default) - Free, uses gpt-4.1-mini model"
    echo "phind - Great for developers"
    echo "deepseek - Requires API key (add in API Keys menu)"
    echo "gemini - Requires API key (add in API Keys menu)"
    echo "openai - Requires API key (add in API Keys menu)"
    echo "groq - Requires API key (add in API Keys menu)"
    echo "ollama - Local models"
    echo "pollinations - Free image generation"
    echo ""
    echo -e "${BOLD}Image Generation:${NC}"
    echo "Uses arta provider by default"
    echo "Supports 50+ models including: Flux, Photographic, SDXL 1.0, Anime tattoo, etc."
    echo "Supports 9 aspect ratios"
    echo "Can generate multiple images at once"
    echo "Supports negative prompts"
    echo ""
    echo -e "${BOLD}API Keys Management:${NC}"
    echo "Go to 'API Keys Management' menu to add API keys"
    echo "Supported: openai, deepseek, gemini, groq"
    echo ""
    echo -e "${BOLD}Tips:${NC}"
    echo "Use arrow keys to navigate menus"
    echo "Press Ctrl+C to exit anytime"
    echo "History is saved in ~/.termux-ai/"
    echo "Change providers in Settings"
    
    echo
    gum input --placeholder "Press Enter to continue..." --prompt "> "
}

show_credits() {
    show_banner
    echo -e "${CYAN}Credits${NC}\n"
    
    echo -e "${BOLD}Termux-AI${NC}"
    echo "Interactive AI Assistant for Termux"
    echo ""
    echo -e "${BOLD}Powered by:${NC}"
    echo "• tgpt - AI command line tool"
    echo "  GitHub: https://github.com/aandrew-me/tgpt"
    echo "  License: GPL-3.0"
    echo ""
    echo "• gum - A tool for glamorous shell scripts"
    echo "  GitHub: https://github.com/charmbracelet/gum"
    echo "  License: MIT"
    echo ""
    echo -e "${BOLD}AI Providers:${NC}"
    echo "• sky, phind, deepseek, gemini, groq, openai"
    echo "• ollama, kimi, isou, pollinations, arta"
    echo ""
    echo -e "${BOLD}Note:${NC}"
    echo "This tool is a wrapper interface for tgpt."
    echo "Please respect the licenses of the underlying tools."
    echo "Support the original projects if you find them useful!"
    echo ""
    gum input --placeholder "Press Enter to continue..." --prompt "> "
}

quick_mode() {
    if [ $# -eq 0 ]; then
        show_main_menu
    else
        QUERY="$*"
        echo -e "${CYAN}Termux-Ai Quick Response${NC}\n"
        echo -e "${YELLOW}Query:${NC} $QUERY\n"
        
        TGPT_CMD=$(build_tgpt_command "$DEFAULT_PROVIDER" "$QUERY")
        eval "$TGPT_CMD"
    fi
}

main() {
    init_config
    load_config
    
    if [ $# -gt 0 ]; then
        quick_mode "$@"
    else
        show_main_menu
    fi
}

main "$@"
