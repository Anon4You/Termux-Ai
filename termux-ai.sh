#!/data/data/com.termux/files/usr/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

VERSION="4.0"

CONFIG_DIR="$HOME/.config/termux-ai"
CONFIG_FILE="$CONFIG_DIR/config"
MODEL_FILE="$CONFIG_DIR/models"
HISTORY_FILE="$CONFIG_DIR/history"
SESSION_FILE="$CONFIG_DIR/session_$(date +%Y%m%d_%H%M%S).txt"
API_KEYS_FILE="$CONFIG_DIR/api_keys"

CHAT_PROVIDER_OPTIONS=(
    "powerbrain (Free Default)"
    "opencode (Free)"
    "fx (Free)"
    "aitopia (Free)"
    "isou (Free Web Search)"
    "pollinations (Free)"
    "deepseek-web (Free Web Token)"
    "aihorde (Free)"
    "koboldai (Novel AI)"
    "ollama (Local)"
    "omniroute (Local Proxy)"
    "anyapi (Free Tokens)"
    "atlascloud (API Key)"
    "deepseek (API Key)"
    "gemini (API Key)"
    "groq (API Key)"
    "litellm (API Key)"
    "minimax (API Key)"
    "ollamacloud (API Key)"
    "openai (API Key)"
    "openrouter (API Key)"
    "custom (OpenAI Compatible)"
)

IMAGE_PROVIDER_OPTIONS=(
    "pollinations (Free Default)"
    "magicstudio (Free Fast)"
    "anyapi (API Key)"
)

API_KEY_PROVIDERS=(anyapi atlascloud deepseek deepseek-web gemini groq litellm minimax ollamacloud openai openrouter)

key_url() {
    case "$1" in
        anyapi)       echo "https://docs.anyapi.ai/" ;;
        atlascloud)   echo "https://www.atlascloud.ai/" ;;
        deepseek)     echo "https://platform.deepseek.com/api_keys" ;;
        deepseek-web) echo "Browser userToken from chat.deepseek.com (Dev Tools > Local Storage)" ;;
        gemini)       echo "https://aistudio.google.com/apikey" ;;
        groq)         echo "https://console.groq.com/keys" ;;
        litellm)      echo "https://docs.litellm.ai" ;;
        minimax)      echo "https://platform.minimaxi.com" ;;
        ollamacloud)  echo "https://ollama.cloud" ;;
        openai)       echo "https://platform.openai.com/api-keys" ;;
        openrouter)   echo "https://openrouter.ai/keys" ;;
        *)            echo "Check the provider docs" ;;
    esac
}

provider_name_from_label() {
    echo "$1" | awk '{print $1}' | tr '[:upper:]' '[:lower:]'
}

init_config() {
    mkdir -p "$CONFIG_DIR"

    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << EOF
DEFAULT_PROVIDER="powerbrain"
IMAGE_PROVIDER="pollinations"
CUSTOM_API_URL=""
CUSTOM_MODEL=""
CUSTOM_API_KEY=""
SAVE_HISTORY=true
SHOW_BANNER=true
EOF
    fi

    migrate_config

    [ -f "$MODEL_FILE" ] || touch "$MODEL_FILE"
    [ -f "$HISTORY_FILE" ] || touch "$HISTORY_FILE"
    [ -f "$API_KEYS_FILE" ] || touch "$API_KEYS_FILE"
    touch "$SESSION_FILE"
}

migrate_config() {
    local f="$CONFIG_FILE"

    grep -q '^DEFAULT_PROVIDER=' "$f" || echo 'DEFAULT_PROVIDER="powerbrain"' >> "$f"
    grep -q '^IMAGE_PROVIDER=' "$f" || echo 'IMAGE_PROVIDER="pollinations"' >> "$f"
    grep -q '^CUSTOM_API_URL=' "$f" || echo 'CUSTOM_API_URL=""' >> "$f"
    grep -q '^CUSTOM_MODEL=' "$f" || echo 'CUSTOM_MODEL=""' >> "$f"
    grep -q '^CUSTOM_API_KEY=' "$f" || echo 'CUSTOM_API_KEY=""' >> "$f"
    grep -q '^SAVE_HISTORY=' "$f" || echo 'SAVE_HISTORY=true' >> "$f"
    grep -q '^SHOW_BANNER=' "$f" || echo 'SHOW_BANNER=true' >> "$f"

    sed -i 's/^DEFAULT_PROVIDER="sky"/DEFAULT_PROVIDER="powerbrain"/' "$f"
    sed -i 's/^DEFAULT_PROVIDER="phind"/DEFAULT_PROVIDER="powerbrain"/' "$f"
    sed -i 's/^DEFAULT_PROVIDER="kimi"/DEFAULT_PROVIDER="powerbrain"/' "$f"
    sed -i 's/^IMAGE_PROVIDER="arta"/IMAGE_PROVIDER="pollinations"/' "$f"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        DEFAULT_PROVIDER="powerbrain"
        IMAGE_PROVIDER="pollinations"
        CUSTOM_API_URL=""
        CUSTOM_MODEL=""
        CUSTOM_API_KEY=""
        SAVE_HISTORY=true
        SHOW_BANNER=true
    fi
}

set_config() {
    local key=$1
    local value=$2

    if grep -q "^${key}=" "$CONFIG_FILE"; then
        sed -i "/^${key}=/d" "$CONFIG_FILE"
    fi
    echo "${key}=\"${value}\"" >> "$CONFIG_FILE"
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

get_provider_model() {
    local provider=$1
    if [ -f "$MODEL_FILE" ]; then
        grep "^${provider}=" "$MODEL_FILE" | cut -d'=' -f2-
    fi
}

save_provider_model() {
    local provider=$1
    local model=$2

    if grep -q "^${provider}=" "$MODEL_FILE"; then
        sed -i "/^${provider}=/d" "$MODEL_FILE"
    fi
    echo "${provider}=${model}" >> "$MODEL_FILE"
}

remove_provider_model() {
    local provider=$1
    if grep -q "^${provider}=" "$MODEL_FILE"; then
        sed -i "/^${provider}=/d" "$MODEL_FILE"
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
            "TERMUX-AI v$VERSION" \
            "Interactive AI Assistant"
        echo -e "\t\tBy Alienkrishn [Anon4You]"
    fi
}

build_tgpt_command() {
    local provider=$1
    local prompt=$2
    local extra_flags=$3

    local api_key=""
    local model=""
    local cmd="tgpt"

    if [ "$provider" = "custom" ]; then
        provider="openai"
        [ -n "$CUSTOM_API_URL" ] && extra_flags="$extra_flags --url \"$CUSTOM_API_URL\""
        api_key="$CUSTOM_API_KEY"
        model="$CUSTOM_MODEL"
    else
        api_key=$(get_api_key "$provider")
        model=$(get_provider_model "$provider")
    fi

    cmd="$cmd --provider $provider"

    if [ -n "$api_key" ]; then
        cmd="$cmd --key \"$api_key\""
    fi

    if [ -n "$model" ]; then
        cmd="$cmd --model \"$model\""
    fi

    if [ -n "$extra_flags" ]; then
        cmd="$cmd $extra_flags"
    fi

    cmd="$cmd \"$prompt\""
    echo "$cmd"
}

show_main_menu() {
    while true; do
        show_banner

        echo -e "${CYAN}Main Menu${NC}\n"

        CHOICE=$(gum choose \
            --height=15 \
            --cursor="> " \
            --selected.foreground="87" \
            "Chat Mode" \
            "Shell Command Mode" \
            "Code Generation" \
            "Web Search Mode" \
            "Tool Calling Mode" \
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
            "Web Search Mode")
                find_mode
                ;;
            "Tool Calling Mode")
                tools_mode
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
    echo -e "${YELLOW}Provider: $DEFAULT_PROVIDER | Type 'exit' to return, 'clear' to clean screen${NC}\n"

    while true; do
        QUESTION=$(gum input \
            --placeholder "Ask me anything..." \
            --prompt "> " \
            --width 80 \
            --header "Chat Mode | Provider: $DEFAULT_PROVIDER")

        [[ "$QUESTION" == "exit" || "$QUESTION" == "quit" ]] && return

        if [[ "$QUESTION" == "clear" ]]; then
            clear
            show_banner
            echo -e "${CYAN}Chat Mode${NC}\n"
            continue
        fi

        [ -z "$QUESTION" ] && continue

        save_to_session "User: $QUESTION"

        TGPT_CMD=$(build_tgpt_command "$DEFAULT_PROVIDER" "$QUESTION")
        RESPONSE=$(eval "$TGPT_CMD" 2>/dev/null)
        echo "$RESPONSE"

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

        [[ "$QUESTION" == "exit" || "$QUESTION" == "quit" ]] && return
        [ -z "$QUESTION" ] && continue

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

        [[ "$QUESTION" == "exit" || "$QUESTION" == "quit" ]] && return
        [ -z "$QUESTION" ] && continue

        save_to_session "Code Request: $QUESTION"

        TGPT_CMD=$(build_tgpt_command "$DEFAULT_PROVIDER" "$QUESTION" "-c")
        eval "$TGPT_CMD"

        echo
    done
}

find_mode() {
    show_banner
    echo -e "${CYAN}Web Search Mode${NC}"
    echo -e "${YELLOW}Type 'exit' or 'quit' to return to menu${NC}\n"

    while true; do
        QUESTION=$(gum input \
            --placeholder "What do you want to search for?" \
            --prompt "> " \
            --width 80 \
            --header "Web Search | Provider: $DEFAULT_PROVIDER")

        [[ "$QUESTION" == "exit" || "$QUESTION" == "quit" ]] && return
        [ -z "$QUESTION" ] && continue

        save_to_session "Search Request: $QUESTION"

        TGPT_CMD=$(build_tgpt_command "$DEFAULT_PROVIDER" "$QUESTION" "-f")
        eval "$TGPT_CMD"

        echo
    done
}

tools_mode() {
    show_banner
    echo -e "${CYAN}Tool Calling Mode${NC}"
    echo -e "${YELLOW}Let the model use built-in tools (web search, files, shell...). Type 'exit' to return${NC}\n"

    while true; do
        QUESTION=$(gum input \
            --placeholder "Ask something, the model can use tools..." \
            --prompt "> " \
            --width 80 \
            --header "Tools | Provider: $DEFAULT_PROVIDER")

        [[ "$QUESTION" == "exit" || "$QUESTION" == "quit" ]] && return
        [ -z "$QUESTION" ] && continue

        echo -e "\n${CYAN}Enable tools:${NC}"
        TOOLS_CHOICE=$(gum choose \
            --height=4 \
            --cursor="> " \
            "All built-in tools" \
            "Select tools manually" \
            "No tools")

        if [[ "$TOOLS_CHOICE" == "No tools" ]]; then
            continue
        fi

        BUILD_IN_TOOLS=(web_search_exa web_search_firecrawl read_directory read_file execute_command web_fetch write_file edit_file grep glob)

        TOOLS_FLAG=""
        if [[ "$TOOLS_CHOICE" == "Select tools manually" ]]; then
            SELECTED=$(printf '%s\n' "${BUILD_IN_TOOLS[@]}" | gum choose \
                --height=10 \
                --no-limit \
                --cursor="> ")
            if [ -n "$SELECTED" ]; then
                TOOLS_FLAG=$(printf '%s' "$SELECTED" | tr '\n' ',')
                TOOLS_FLAG="${TOOLS_FLAG%,}"
            else
                TOOLS_FLAG="all"
            fi
        else
            TOOLS_FLAG="all"
        fi

        save_to_session "Tools Request: $QUESTION (tools: $TOOLS_FLAG)"

        TGPT_CMD=$(build_tgpt_command "$DEFAULT_PROVIDER" "$QUESTION" "-t \"$TOOLS_FLAG\"")
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
            --header "Image Mode | Provider: $IMAGE_PROVIDER")

        [[ "$PROMPT" == "exit" || "$PROMPT" == "quit" ]] && return
        [ -z "$PROMPT" ] && continue

        save_to_session "Image Request: $PROMPT"

        echo -e "\n${CYAN}Select Image Provider:${NC}"
        IMG_PROVIDER=$(gum choose \
            --height=5 \
            --cursor="> " \
            --selected.foreground="87" \
            "${IMAGE_PROVIDER_OPTIONS[@]}" \
            "Back")

        [[ "$IMG_PROVIDER" == "Back" ]] && continue
        IMG_NAME=$(provider_name_from_label "$IMG_PROVIDER")

        MODEL=""
        WIDTH=""
        HEIGHT=""
        OUT=""
        KEY=""

        if [ "$IMG_NAME" = "pollinations" ]; then
            echo -e "\n${CYAN}Pollinations options:${NC}"
            MODEL=$(gum choose \
                --height=4 \
                --cursor="> " \
                "flux" \
                "turbo" \
                "default")
            [ "$MODEL" = "default" ] && MODEL=""
            WIDTH=$(gum input --placeholder "Width in px (empty = default, e.g. 1024)" --prompt "> ")
            HEIGHT=$(gum input --placeholder "Height in px (empty = default, e.g. 1024)" --prompt "> ")
            OUT=$(gum input --placeholder "Output file (empty = auto)" --prompt "> " --value "image_$(date +%Y%m%d_%H%M%S).png")
        fi

        if [ "$IMG_NAME" = "anyapi" ]; then
            KEY=$(get_api_key anyapi)
            if [ -z "$KEY" ]; then
                echo -e "${RED}No anyapi key found. Add one in 'API Keys Management'.${NC}"
                continue
            fi
        fi

        CMD="tgpt --provider $IMG_NAME --img"
        [ -n "$KEY" ] && CMD="$CMD --key \"$KEY\""
        [ -n "$MODEL" ] && CMD="$CMD --model \"$MODEL\""
        [ -n "$WIDTH" ] && CMD="$CMD --width \"$WIDTH\""
        [ -n "$HEIGHT" ] && CMD="$CMD --height \"$HEIGHT\""
        [ -n "$OUT" ] && CMD="$CMD --out \"$OUT\""
        CMD="$CMD \"$PROMPT\""

        echo -e "\n${YELLOW}Generating via $IMG_NAME: $PROMPT${NC}"
        eval "$CMD"

        save_to_session "Image generated via $IMG_NAME: $PROMPT (Model: $MODEL, ${WIDTH}x${HEIGHT}, Out: $OUT)"

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
        --height=13 \
        --cursor="> " \
        "${API_KEY_PROVIDERS[@]}" \
        "Back")

    if [[ "$PROVIDER" == "Back" ]]; then
        return
    fi

    echo -e "\n${YELLOW}Getting API key for $PROVIDER:${NC}"
    echo -e "${BLUE}Where to get API key:${NC}"
    echo "$(key_url "$PROVIDER")"

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

    TGPT_CMD=$(build_tgpt_command "$SELECTED" "Hello, please respond with just 'API working' to confirm." "--quiet")
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
            --height=11 \
            --cursor="> " \
            --selected.foreground="87" \
            "Change AI Provider" \
            "Change Image Provider" \
            "Change Default Model" \
            "Custom OpenAI-Compatible Endpoint" \
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
            "Change Default Model")
                change_model
                ;;
            "Custom OpenAI-Compatible Endpoint")
                custom_config
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
        --height=16 \
        --selected.foreground="87" \
        "${CHAT_PROVIDER_OPTIONS[@]}")

    PROVIDER_NAME=$(provider_name_from_label "$PROVIDER")

    set_config "DEFAULT_PROVIDER" "$PROVIDER_NAME"
    DEFAULT_PROVIDER="$PROVIDER_NAME"

    echo -e "\n${GREEN}Provider changed to: $PROVIDER_NAME${NC}"
    gum spin --spinner dot --title "Saving..." -- sleep 1
}

change_image_provider() {
    show_banner
    echo -e "${CYAN}Select Image Generation Provider${NC}\n"

    PROVIDER=$(gum choose \
        --height=5 \
        --selected.foreground="87" \
        "${IMAGE_PROVIDER_OPTIONS[@]}" \
        "Back")

    if [[ "$PROVIDER" == "Back" ]]; then
        return
    fi

    PROVIDER_NAME=$(provider_name_from_label "$PROVIDER")

    set_config "IMAGE_PROVIDER" "$PROVIDER_NAME"
    IMAGE_PROVIDER="$PROVIDER_NAME"

    echo -e "\n${GREEN}Image provider changed to: $PROVIDER_NAME${NC}"
    gum spin --spinner dot --title "Saving..." -- sleep 1
}

change_model() {
    show_banner
    echo -e "${CYAN}Default Model${NC}\n"

    CURRENT=$(get_provider_model "$DEFAULT_PROVIDER")
    if [ -z "$CURRENT" ]; then
        CURRENT="default (provider model)"
    fi

    echo -e "Setting a model for: ${BOLD}$DEFAULT_PROVIDER${NC}"
    echo -e "Current model: ${GREEN}$CURRENT${NC}\n"

    ACTION=$(gum choose \
        --height=4 \
        --cursor="> " \
        --selected.foreground="87" \
        "Set Model" \
        "Clear Model" \
        "Back")

    case "$ACTION" in
        "Set Model")
            MODEL=$(gum input \
                --placeholder "Model name (e.g. gpt-5, gpt-4o-mini)" \
                --prompt "> " \
                --value "$CURRENT")

            if [ -n "$MODEL" ] && [[ "$MODEL" != default* ]]; then
                save_provider_model "$DEFAULT_PROVIDER" "$MODEL"
                echo -e "\n${GREEN}Model saved for $DEFAULT_PROVIDER: $MODEL${NC}"
            else
                echo -e "\n${YELLOW}No custom model set.${NC}"
            fi
            ;;
        "Clear Model")
            remove_provider_model "$DEFAULT_PROVIDER"
            echo -e "\n${YELLOW}Model cleared (default will be used)${NC}"
            ;;
    esac

    gum spin --spinner dot --title "Saving..." -- sleep 1
}

custom_config() {
    show_banner
    echo -e "${CYAN}Custom OpenAI-Compatible Endpoint${NC}\n"

    echo -e "${BLUE}Point the tool to any OpenAI-compatible API${NC}"
    echo -e "(OpenAI, vLLM, Ollama server, LiteLLM, LocalAI, any custom gateway)\n"
    echo -e "${YELLOW}tgpt needs the FULL API URL ending in /chat/completions${NC}"
    echo -e "Example: ${GREEN}https://api.example.com/v1/chat/completions${NC}\n"

    URL=$(gum input \
        --placeholder "Full API URL (e.g. https://api.example.com/v1/chat/completions)" \
        --prompt "URL> " \
        --value "$CUSTOM_API_URL")
    CUSTOM_API_URL="$URL"
    set_config "CUSTOM_API_URL" "$URL"

    MODEL=$(gum input \
        --placeholder "Model name (optional)" \
        --prompt "MODEL> " \
        --value "$CUSTOM_MODEL")
    CUSTOM_MODEL="$MODEL"
    set_config "CUSTOM_MODEL" "$MODEL"

    KEY=$(gum input \
        --placeholder "API key (optional)" \
        --prompt "KEY> " \
        --password \
        --value "$CUSTOM_API_KEY")
    CUSTOM_API_KEY="$KEY"
    set_config "CUSTOM_API_KEY" "$KEY"

    echo -e "\n${GREEN}Custom endpoint configured!${NC}"
    echo "Select 'custom (OpenAI Compatible)' as your provider in Settings to use it."
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

    set_config "SAVE_HISTORY" "$SAVE_HISTORY"
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

    set_config "SHOW_BANNER" "$SHOW_BANNER"
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
    echo "Shell Mode: Generate shell commands (like tgpt -s)"
    echo "Code Mode: Generate code snippets (like tgpt -c)"
    echo "Web Search Mode: Find info with web search (like tgpt -f)"
    echo "Tool Calling Mode: Let the model use built-in tools (like tgpt -t)"
    echo "Image Mode: Generate images from text"
    echo ""
    echo -e "${BOLD}Commands in Chat Mode:${NC}"
    echo "exit/quit: Return to main menu"
    echo "clear: Clear the screen"
    echo ""
    echo -e "${BOLD}Free Providers (no key needed):${NC}"
    echo "powerbrain (default) - Free, uses gpt-5 model"
    echo "opencode - Free, deepseek-v4-flash-free model"
    echo "fx - Free, zai/glm-5.2 model"
    echo "aitopia - Free, gpt-4o-mini model"
    echo "isou - Free with web search"
    echo "pollinations - Free text + image"
    echo "deepseek-web - Free, needs userToken + node.js"
    echo "aihorde - Free, community powered"
    echo "ollama - Local models"
    echo "omniroute - Local OpenAI-compatible proxy"
    echo ""
    echo -e "${BOLD}API Key Providers:${NC}"
    echo "anyapi, atlascloud, deepseek, gemini, groq, litellm"
    echo "minimax, ollamacloud, openai, openrouter"
    echo ""
    echo -e "${BOLD}Custom OpenAI-Compatible:${NC}"
    echo "Point any OpenAI-compatible API (vLLM, LiteLLM, LocalAI, custom gateways)"
    echo "Configure it in Settings > Custom OpenAI-Compatible Endpoint"
    echo ""
    echo -e "${BOLD}Image Generation:${NC}"
    echo "pollinations (default) - free, flux/turbo models, custom size & output"
    echo "magicstudio - free and fast"
    echo "anyapi - requires API key, many models"
    echo ""
    echo -e "${BOLD}API Keys Management:${NC}"
    echo "Go to 'API Keys Management' menu to add/remove/test API keys"
    echo "Keys are stored locally in ~/.config/termux-ai/api_keys"
    echo ""
    echo -e "${BOLD}Tips:${NC}"
    echo "Use arrow keys to navigate menus"
    echo "Press Ctrl+C to exit anytime"
    echo "Change providers and models in Settings"
    echo "History is saved in ~/.config/termux-ai/"
    echo "Data dir: ~/.config/tgpt/ for tgpt config.conf"

    echo
    gum input --placeholder "Press Enter to continue..." --prompt "> "
}

show_credits() {
    show_banner
    echo -e "${CYAN}Credits${NC}\n"

    echo -e "${BOLD}Termux-AI v$VERSION${NC}"
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
    echo "• Free: powerbrain, opencode, fx, aitopia, isou, pollinations,"
    echo "  deepseek-web, aihorde, koboldai, ollama, omniroute"
    echo "• API: anyapi, atlascloud, deepseek, gemini, groq, litellm,"
    echo "  minimax, ollamacloud, openai, openrouter"
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