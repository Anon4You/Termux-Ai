#!/data/data/com.termux/files/usr/bin/bash

# Termux AI Assistant Minimal Installer
# Author: Alienkrishn
# GitHub: GitHub.com/Anon4You

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Check if running in Termux
if [ ! -d "$PREFIX/bin" ]; then
    echo -e "${RED}Error: This script must be run in Termux${NC}"
    exit 1
fi

echo -e "${BLUE}╭──────────────────────────────────────╮${NC}"
echo -e "${BLUE}│${NC}${GREEN}   Termux AI Assistant Minimal Installer  ${BLUE}│${NC}"
echo -e "${BLUE}╰──────────────────────────────────────╯${NC}"

# Update packages
echo -e "${YELLOW}[*] Updating packages...${NC}"
apt update -y && apt upgrade -y

# Install dependencies
echo -e "${YELLOW}[*] Installing dependencies...${NC}"
apt install -y curl jq bc

# Download the script directly
echo -e "${YELLOW}[*] Downloading Termux AI Assistant...${NC}"
curl -s -o $PREFIX/bin/termux-ai \
    https://raw.githubusercontent.com/Anon4You/Termux-Ai/main/termux_ai.sh

# Make script executable
echo -e "${YELLOW}[*] Setting permissions...${NC}"
chmod +x $PREFIX/bin/termux-ai

# Create config directory
echo -e "${YELLOW}[*] Creating config directory...${NC}"
mkdir -p ~/.config/termux_assistant

echo -e "${GREEN}[✓] Installation complete!${NC}"
echo -e "\nRun the AI Assistant with: ${BLUE}termux-ai${NC}"

# First run instructions
echo -e "\n${YELLOW}To configure your API key:${NC}"
echo -e "1. Run ${BLUE}termux-ai${NC}"
echo -e "2. Go to Settings (Option 2)"
echo -e "3. Select 'API Key' (Option 1)"
echo -e "4. Enter your OpenRouter API key\n"

exit 0
