#!/data/data/com.termux/files/usr/bin/bash

# Termux AI Assistant
# Author: Alienkrishn
# GitHub: GitHub.com/Anon4You
# Version: 2.0

# ANSI Color Codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Configuration
CONFIG_DIR="$HOME/.config/termux_assistant"
HISTORY_FILE="$CONFIG_DIR/history"
CONFIG_FILE="$CONFIG_DIR/config"
API_KEY_FILE="$CONFIG_DIR/api_key"
VERSION="2.0"

# Available Free Models
declare -A FREE_MODELS=(
    ["deepseek-r1"]="deepseek/deepseek-r1:free"
    ["qwen2.5-vl-32b"]="qwen/qwen2.5-vl-32b-instruct:free"
    ["gemma-3-27b"]="google/gemma-3-27b-it:free"
    ["mistral-small"]="mistralai/mistral-small-3.1-24b-instruct:free"
    ["Gemini-pro2.5"]="google/gemini-2.5-pro-exp-03-25:free"
    ["meta-llama"]="meta-llama/llama-3.1-8b-instruct:free"
    ["Qwerky 72b"]="featherless/qwerky-72b:free"
    ["Allen-Ai"]="allenai/molmo-7b-d:free"
    ["Nous: DeepHermes"]="nousresearch/deephermes-3-llama-3-8b-preview:free"
    ["Rogue Rose"]="sophosympatheia/rogue-rose-103b-v0.2:free"
)

# Default settings
MODEL=${FREE_MODELS["deepseek-r1"]}
ENABLE_HISTORY=true
SHOW_TOKEN_USAGE=true
MAX_TOKENS=800
TEMPERATURE=0.7

# Initialize configuration directory
init_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR" || {
            echo -e "${RED}Failed to create config directory${NC}"
            exit 1
        }
        chmod 700 "$CONFIG_DIR"
    fi
}

# Secure API key handling
load_api_key() {
    if [ -f "$API_KEY_FILE" ]; then
        API_KEY=$(cat "$API_KEY_FILE" | tr -d '\n')
    else
        API_KEY=""
    fi
}

save_api_key() {
    echo -n "$API_KEY" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"
}

# Load or create config
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" || {
            echo -e "${YELLOW}Config file corrupted, creating new one${NC}"
            save_config
        }
    else
        save_config
    fi
    load_api_key
}

save_config() {
    cat > "$CONFIG_FILE" <<EOF
MODEL="$MODEL"
ENABLE_HISTORY=$ENABLE_HISTORY
SHOW_TOKEN_USAGE=$SHOW_TOKEN_USAGE
MAX_TOKENS=$MAX_TOKENS
TEMPERATURE=$TEMPERATURE
EOF
    chmod 600 "$CONFIG_FILE"
}

# Helper function to clean JSON input
clean_json() {
    tr -d '\r\n' | sed 's/\\/\\\\/g;s/"/\\"/g'
}

# Validate temperature input
validate_temperature() {
    local temp=$1
    if ! [[ "$temp" =~ ^[0-9]+(\.[0-9]+)?$ ]] || \
       (( $(echo "$temp < 0.1 || $temp > 2.0" | bc -l) )); then
        return 1
    fi
    return 0
}

# Validate max tokens input
validate_max_tokens() {
    local tokens=$1
    if ! [[ "$tokens" =~ ^[0-9]+$ ]] || \
       [ "$tokens" -lt 50 ] || [ "$tokens" -gt 2000 ]; then
        return 1
    fi
    return 0
}

# Colorized print functions (unchanged from original)
print_header() {
    clear
    echo -e "${BLUE}╭──────────────────────────────────────╮${NC}"
    echo -e "${BLUE}│${NC}${WHITE}      Termux AI Assistant ${GRAY}v$VERSION${NC}        ${BLUE}│${NC}"
    echo -e "${BLUE}╰──────────────────────────────────────╯${NC}"
    echo -e "${GRAY}Author: Alienkrishn   GitHub: GitHub.com/Anon4You${NC}\n"
}

print_menu() {
    echo -e "${YELLOW}1.${NC} Start Chat Session"
    echo -e "${YELLOW}2.${NC} Settings Configuration"
    echo -e "${YELLOW}3.${NC} View Conversation History"
    echo -e "${YELLOW}4.${NC} Exit"
    echo ""
}

print_settings_header() {
    echo -e "${MAGENTA}╭──────────────────────────────────────╮${NC}"
    echo -e "${MAGENTA}│${NC}${WHITE}        AI Assistant Settings${NC}         ${MAGENTA}│${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────╯${NC}"
}

print_settings_menu() {
    echo -e "${CYAN}1.${NC} API Key: ${GREEN}${API_KEY:0:4}****${API_KEY: -4}${NC}"
    
    local current_model_name=""
    for name in "${!FREE_MODELS[@]}"; do
        if [[ "${FREE_MODELS[$name]}" == "$MODEL" ]]; then
            current_model_name=$name
            break
        fi
    done
    echo -e "${CYAN}2.${NC} Model: ${GREEN}$current_model_name${NC} ${GRAY}(${MODEL})${NC}"
    
    echo -e "${CYAN}3.${NC} Max Tokens: ${GREEN}$MAX_TOKENS${NC}"
    echo -e "${CYAN}4.${NC} Temperature: ${GREEN}$TEMPERATURE${NC}"
    echo -e "${CYAN}5.${NC} History: ${GREEN}$ENABLE_HISTORY${NC}"
    echo -e "${CYAN}6.${NC} Show Token Usage: ${GREEN}$SHOW_TOKEN_USAGE${NC}"
    echo -e "${CYAN}7.${NC} Clear History"
    echo -e "${CYAN}8.${NC} Back to Main Menu"
    echo ""
}

# Initialize
init() {
    init_config_dir
    load_config
    touch "$HISTORY_FILE"
    chmod 600 "$HISTORY_FILE"
    
    # Check dependencies
    local dependencies=("jq" "curl" "bc")
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${YELLOW}Installing $dep...${NC}"
            pkg install -y "$dep" && echo -e "${GREEN}✓ $dep installed successfully${NC}" || {
                echo -e "${RED}Failed to install $dep${NC}"
                exit 1
            }
        fi
    done
    
    # Check API key
    if [ -z "$API_KEY" ]; then
        echo -e "${RED}Warning: No API key configured!${NC}"
        echo -e "Please set your OpenRouter API key in the settings menu."
        sleep 2
    fi
}

# Model selection menu (unchanged UI)
model_selection_menu() {
    echo -e "${MAGENTA}╭──────────────────────────────────────╮${NC}"
    echo -e "${MAGENTA}│${NC}${WHITE}        Available Free Models${NC}         ${MAGENTA}│${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────╯${NC}"
    
    local i=1
    local model_options=()
    for name in "${!FREE_MODELS[@]}"; do
        echo -e "${CYAN}$i.${NC} ${GREEN}$name${NC} ${GRAY}(${FREE_MODELS[$name]})${NC}"
        model_options+=("${FREE_MODELS[$name]}")
        ((i++))
    done
    
    echo ""
    read -p "Select model (1-${#FREE_MODELS[@]}): " choice
    
    if [[ "$choice" -ge 1 && "$choice" -le ${#FREE_MODELS[@]} ]]; then
        MODEL="${model_options[$((choice-1))]}"
        save_config
        echo -e "${GREEN}Model changed successfully!${NC}"
    else
        echo -e "${RED}Invalid selection. Keeping current model.${NC}"
    fi
    sleep 1
}

# Enhanced chat function with timeout and better error handling
chat() {
    local prompt="$1"
    local context=()
    
    if [ "$ENABLE_HISTORY" = true ]; then
        # Add last 3 messages from history as context
        while IFS= read -r line; do
            context+=("$line")
        done < <(tail -n 3 "$HISTORY_FILE")
    fi
    
    # Build messages array with proper JSON escaping
    local messages='[]'
    for msg in "${context[@]}"; do
        msg=$(echo "$msg" | clean_json)
        messages=$(jq --arg role "assistant" --arg content "$msg" '. += [{"role": $role, "content": $content}]' <<< "$messages")
    done
    
    prompt=$(echo "$prompt" | clean_json)
    messages=$(jq --arg role "user" --arg content "$prompt" '. += [{"role": $role, "content": $content}]' <<< "$messages")
    
    # Show thinking indicator
    echo -ne "${GRAY}🤖 Thinking...${NC}\r"
    
    # Make API request with timeout and proper JSON handling
    local response
    response=$(timeout 30 curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -H "HTTP-Referer: https://termux.com" \
        -H "X-Title: Termux AI Assistant" \
        -d "$(jq -n --arg model "$MODEL" --argjson messages "$messages" \
        --argjson max_tokens $MAX_TOKENS --argjson temperature $TEMPERATURE \
        '{
            "model": $model,
            "messages": $messages,
            "max_tokens": $max_tokens,
            "temperature": $temperature
        }')" 2>/dev/null)
    
    # Clear thinking indicator
    echo -ne "                            \r"
    
    # Check for curl errors
    local curl_exit=$?
    if [ $curl_exit -eq 124 ]; then
        echo -e "${RED}Error: Request timed out after 30 seconds${NC}"
        return 1
    elif [ $curl_exit -ne 0 ]; then
        echo -e "${RED}Error: Failed to connect to API (curl error $curl_exit)${NC}"
        return 1
    fi
    
    # Check for API errors with proper JSON parsing
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local error_msg=$(echo "$response" | jq -r '.error.message')
        echo -e "${RED}Error: ${error_msg}${NC}"
        return 1
    fi
    
    # Process response with proper JSON handling
    local answer=$(echo "$response" | jq -r '.choices[0].message.content')
    local tokens=$(echo "$response" | jq -r '.usage.total_tokens')
    
    # Save to history
    if [ "$ENABLE_HISTORY" = true ]; then
        echo "$answer" >> "$HISTORY_FILE"
    fi
    
    # Display response with formatting (unchanged UI)
    echo -e "\n${BLUE}╭──────────────────────────────────────╮${NC}"
    
    local model_name=""
    for name in "${!FREE_MODELS[@]}"; do
        if [[ "${FREE_MODELS[$name]}" == "$MODEL" ]]; then
            model_name=$name
            break
        fi
    done
    
    echo -e "${BLUE}│${NC} ${CYAN}AI Assistant${NC} ${GRAY}($model_name)${NC}"
    echo -e "${BLUE}╰──────────────────────────────────────╯${NC}"
    echo -e "${WHITE}$answer${NC}"
    echo -e "${BLUE}╭──────────────────────────────────────╮${NC}"
    
    if [ "$SHOW_TOKEN_USAGE" = true ]; then
        echo -e "${BLUE}│${NC} ${GRAY}Tokens used: ${GREEN}$tokens${NC} ${GRAY}(Max: $MAX_TOKENS)${NC}"
    fi
    
    echo -e "${BLUE}╰──────────────────────────────────────╯${NC}"
}

# View conversation history with pagination
view_history() {
    if [ ! -s "$HISTORY_FILE" ]; then
        echo -e "${YELLOW}No conversation history found.${NC}"
        return
    fi
    
    echo -e "${MAGENTA}╭─────��────────────────────────────────╮${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Conversation History${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────╯${NC}"
    
    # Use less if available for pagination
    if command -v less &>/dev/null; then
        nl -ba "$HISTORY_FILE" | less -R
    else
        nl -ba "$HISTORY_FILE" | while read -r line; do
            echo -e "${GRAY}${line}${NC}"
        done
        echo ""
        read -p "Press enter to continue..."
    fi
}

# Settings menu with enhanced input validation
settings_menu() {
    while true; do
        print_header
        print_settings_header
        print_settings_menu
        read -p "Select option: " choice
        
        case $choice in
            1) 
                read -p "Enter new API Key: " API_KEY
                save_api_key
                echo -e "${GREEN}API Key updated successfully!${NC}"
                sleep 1
                ;;
            2) 
                model_selection_menu
                ;;
            3) 
                while true; do
                    read -p "Enter max tokens (50-2000): " MAX_TOKENS
                    if validate_max_tokens "$MAX_TOKENS"; then
                        save_config
                        echo -e "${GREEN}Max tokens updated to $MAX_TOKENS${NC}"
                        break
                    else
                        echo -e "${RED}Invalid value (50-2000). Please try again.${NC}"
                    fi
                done
                sleep 1
                ;;
            4) 
                while true; do
                    read -p "Enter temperature (0.1-2.0): " TEMPERATURE
                    if validate_temperature "$TEMPERATURE"; then
                        save_config
                        echo -e "${GREEN}Temperature updated to $TEMPERATURE${NC}"
                        break
                    else
                        echo -e "${RED}Invalid value (0.1-2.0). Please try again.${NC}"
                    fi
                done
                sleep 1
                ;;
            5) 
                ENABLE_HISTORY=$([ "$ENABLE_HISTORY" = true ] && echo false || echo true)
                save_config
                echo -e "${GREEN}History ${ENABLE_HISTORY}${NC}"
                sleep 1
                ;;
            6) 
                SHOW_TOKEN_USAGE=$([ "$SHOW_TOKEN_USAGE" = true ] && echo false || echo true)
                save_config
                echo -e "${GREEN}Token usage display ${SHOW_TOKEN_USAGE}${NC}"
                sleep 1
                ;;
            7) 
                > "$HISTORY_FILE"
                echo -e "${GREEN}History cleared!${NC}"
                sleep 1
                ;;
            8) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Main menu (unchanged UI)
main_menu() {
    init
    
    while true; do
        print_header
        print_menu
        read -p "Select option: " choice
        
        case $choice in
            1) 
                echo -e "\n${GREEN}Starting chat session...${NC}"
                echo -e "${GRAY}Type 'exit' or 'quit' to end session${NC}\n"
                
                local model_name=""
                for name in "${!FREE_MODELS[@]}"; do
                    if [[ "${FREE_MODELS[$name]}" == "$MODEL" ]]; then
                        model_name=$name
                        break
                    fi
                done
                echo -e "${CYAN}Current model: ${GREEN}$model_name${NC}\n"
                
                while true; do
                    echo -ne "${YELLOW}You: ${NC}"
                    read -r prompt
                    
                    if [[ "$prompt" =~ ^(exit|quit)$ ]]; then
                        break
                    fi
                    
                    if [ -z "$prompt" ]; then
                        continue
                    fi
                    
                    chat "$prompt"
                done
                ;;
            2) settings_menu ;;
            3) view_history ;;
            4) 
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Start the assistant
main_menu
