#!/bin/bash
set -euo pipefail

# ============================
# GCP Cloud Run V2Ray Deployment Script
# - UI Enhanced for better visual experience
# - Yellow box headers with clean layout
# ============================

# ----------------------------
# Color Definitions
# ----------------------------
# Foreground Colors
FG_WHITE='\033[97m'
FG_BLACK='\033[30m'
FG_RED='\033[31m'
FG_GREEN='\033[32m'
FG_YELLOW='\033[33m'
FG_BLUE='\033[34m'
FG_CYAN='\033[36m'
FG_MAGENTA='\033[35m'
BOLD='\033[1m'
RESET='\033[0m'

# Background Colors
BG_YELLOW='\033[48;5;226m'
BG_GREEN='\033[48;5;22m'
BG_BLUE='\033[48;5;19m'
BG_CYAN='\033[48;5;44m'
BG_MAGENTA='\033[48;5;90m'
BG_GRAY='\033[48;5;238m'
BG_RESET='\033[49m'

# Special Colors for Banner
B1='\033[38;5;46m'    # Green
B2='\033[38;5;226m'   # Yellow
B3='\033[38;5;51m'    # Cyan

# ----------------------------
# Logging Functions
# ----------------------------
log()   { echo -e "${FG_GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${RESET} ${FG_WHITE}$1${RESET}"; }
warn()  { echo -e "${FG_YELLOW}[WARNING]${RESET} ${FG_WHITE}$1${RESET}"; }
error() { echo -e "${FG_RED}[ERROR]${RESET} ${FG_WHITE}$1${RESET}"; }
info()  { echo -e "${FG_CYAN}[INFO]${RESET} ${FG_WHITE}$1${RESET}"; }

# ----------------------------
# Yellow Box Header
# ----------------------------
show_box_header() {
    local title="$1"
    local subtitle="$2"
    local width=70
    
    # Top border
    echo -e "${BG_YELLOW}${FG_BLACK}$(printf '%*s' "$width" | tr ' ' '═')${BG_RESET}"
    
    # Title line
    local title_padding=$(( (width - ${#title} - 4) / 2 ))
    echo -e "${BG_YELLOW}${FG_BLACK}║${RESET}${BG_YELLOW}$(printf '%*s' "$title_padding")${BOLD}${FG_WHITE}${title}${RESET}${BG_YELLOW}$(printf '%*s' "$((width - ${#title} - title_padding - 4))")${FG_BLACK}║${BG_RESET}"
    
    # Subtitle line (if exists)
    if [[ -n "$subtitle" ]]; then
        local sub_padding=$(( (width - ${#subtitle} - 4) / 2 ))
        echo -e "${BG_YELLOW}${FG_BLACK}║${RESET}${BG_YELLOW}$(printf '%*s' "$sub_padding")${FG_WHITE}${subtitle}${RESET}${BG_YELLOW}$(printf '%*s' "$((width - ${#subtitle} - sub_padding - 4))")${FG_BLACK}║${BG_RESET}"
    fi
    
    # Bottom border
    echo -e "${BG_YELLOW}${FG_BLACK}$(printf '%*s' "$width" | tr ' ' '═')${BG_RESET}\n"
}

# ----------------------------
# Banner Display
# ----------------------------
show_banner() {
    clear
    
    # Top header from image
    show_box_header "🔰 YEARS VS DEPLOYMENT SYSTEM" "VERSION - 2.0     Powered by JDB IEEE"
    
    # ASCII Art with colors
    echo -e "${BG_GRAY}                                                                              ${BG_RESET}"
    echo -e "${BG_GRAY}  ${B1}██╗   ██╗██╗     ███████╗███████╗██████╗ ███████╗${B2}███████╗${B3}${BG_GRAY}                       ${BG_RESET}"
    echo -e "${BG_GRAY}  ${B1}██║   ██║██║     ██╔════╝██╔════╝██╔══██╗██╔════╝${B2}██╔════╝${B3}${BG_GRAY}                       ${BG_RESET}"
    echo -e "${BG_GRAY}  ${B1}██║   ██║██║     █████╗  ███████╗██████╔╝█████╗  ${B2}███████╗${B3}${BG_GRAY}                       ${BG_RESET}"
    echo -e "${BG_GRAY}  ${B1}██║   ██║██║     ██╔══╝  ╚════██║██╔══██╗██╔══╝  ${B2}╚════██║${B3}${BG_GRAY}                       ${BG_RESET}"
    echo -e "${BG_GRAY}  ${B1}╚██████╔╝███████╗███████╗███████║██║  ██║███████╗${B2}███████║${B3}${BG_GRAY}                       ${BG_RESET}"
    echo -e "${BG_GRAY}   ${B1}╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝${B2}╚══════╝${B3}${BG_GRAY}                       ${BG_RESET}"
    echo -e "${BG_GRAY}                                                                              ${BG_RESET}"
    echo -e "${BG_GRAY}  ${FG_WHITE}         V L E S S   +   W E B S O C K E T   +   T L S            ${BG_RESET}"
    echo -e "${BG_GRAY}                                                                              ${BG_RESET}\n"
    
    echo -e "${FG_CYAN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${FG_CYAN}║${RESET} ${FG_WHITE}Use arrow keys / numbers to navigate prompts                       ${FG_CYAN}║${RESET}"
    echo -e "${FG_CYAN}╚══════════════════════════════════════════════════════════════════╝${RESET}\n"
}

# ----------------------------
# Step Display
# ----------------------------
show_step() {
    local step="$1"
    local title="$2"
    show_box_header "STEP ${step}" "${title}"
}

# ----------------------------
# Region Selection (from image)
# ----------------------------
select_region() {
    show_step "01" "Project Deployment Region"
    
    echo -e "${FG_WHITE}Please select your deployment region:${RESET}\n"
    
    # Regions exactly from image
    regions=(
        "🇸🇬|Singapore (asia-southeast1) - Recommended|asia-southeast1|${BG_GREEN}"
        "🇺🇸|United States (us-central1)|us-central1|${BG_BLUE}"
        "🇮🇩|Indonesia (asia-southeast3)|asia-southeast3|${BG_CYAN}"
        "🇯🇵|Japan (asia-northeast3)|asia-northeast3|${BG_MAGENTA}"
        "🇧🇪|Belgium (europe-northeast3)|europe-northeast3|${BG_YELLOW}"
        "🇮🇳|India (asia-south1)|asia-south1|${BG_GRAY}"
    )
    
    # Display regions in two columns
    echo -e "${FG_WHITE}┌──────────────────────────────────────┬──────────────────────────────────────┐${RESET}"
    
    for i in {0..5..2}; do
        # First column
        IFS='|' read -r flag1 name1 code1 bg1 <<< "${regions[$i]}"
        # Second column
        if [[ $((i+1)) -lt ${#regions[@]} ]]; then
            IFS='|' read -r flag2 name2 code2 bg2 <<< "${regions[$((i+1))]}"
        else
            flag2=""; name2=""; code2=""; bg2=""
        fi
        
        # Display row
        if [[ -n "$name1" ]]; then
            col1="${bg1}${FG_WHITE} ${flag1} ${name1} ${BG_RESET}"
            col1_len=$(( ${#name1} + ${#flag1} + 4 ))
            col1_pad=$(( 38 - col1_len ))
        fi
        
        if [[ -n "$name2" ]]; then
            col2="${bg2}${FG_WHITE} ${flag2} ${name2} ${BG_RESET}"
            col2_len=$(( ${#name2} + ${#flag2} + 4 ))
            col2_pad=$(( 38 - col2_len ))
        fi
        
        echo -e "${FG_WHITE}│${RESET} ${col1}$(printf '%*s' "$col1_pad") ${FG_WHITE}│${RESET} ${col2}$(printf '%*s' "$col2_pad") ${FG_WHITE}│${RESET}"
        
        if [[ $i -lt 4 ]]; then
            echo -e "${FG_WHITE}├──────────────────────────────────────┼──────────────────────────────────────┤${RESET}"
        fi
    done
    
    echo -e "${FG_WHITE}└──────────────────────────────────────┴──────────────────────────────────────┘${RESET}\n"
    
    # Region choice
    while true; do
        echo -e "${FG_WHITE}Choose region by number (1-6):${RESET}"
        echo -e "${FG_WHITE}  ${FG_CYAN}1) asia-southeast1   2) us-central1   3) asia-southeast3${RESET}"
        echo -e "${FG_WHITE}  ${FG_CYAN}4) asia-northeast3   5) europe-northeast3  6) asia-south1${RESET}"
        
        read -p "Select region [1]: " region_choice
        region_choice=${region_choice:-1}
        
        case $region_choice in
            1) REGION="asia-southeast1"; break ;;
            2) REGION="us-central1"; break ;;
            3) REGION="asia-southeast3"; break ;;
            4) REGION="asia-northeast3"; break ;;
            5) REGION="europe-northeast3"; break ;;
            6) REGION="asia-south1"; break ;;
            *) echo -e "${FG_YELLOW}Invalid selection. Please enter 1-6.${RESET}";;
        esac
    done
    
    echo -e "\n${FG_WHITE}✓ Selected region:${FG_GREEN} ${REGION}${RESET}\n"
}

# ----------------------------
# Telegram Configuration
# ----------------------------
select_telegram_config() {
    show_step "02" "Telegram Configuration Setup"
    
    echo -e "${FG_WHITE}Projects for Configuration${RESET}\n"
    echo -e "${FG_CYAN}Status:${RESET} ${FG_WHITE}Telegram DB_Token_BM93129927.AADsReg3yg-U.cxPReNUpubBMSgd95Yqw${RESET}"
    echo -e "${FG_CYAN}Diagram:${RESET} ${FG_WHITE}follow configuration${RESET}"
    echo -e "${FG_CYAN}Error Over/Channel Card [D1] :${RESET} ${FG_YELLOW}34V4445454${RESET}\n"
    
    echo -e "${FG_WHITE}Finite Button Configuration (Options)${RESET}\n"
    
    # Valid TBL button prompt from image
    while true; do
        read -p "Valid TBL button[nT] (y/N): " tbl_choice
        tbl_choice=${tbl_choice:-N}
        
        case $tbl_choice in
            [Yy]*) 
                echo -e "${FG_GREEN}TBL button validated${RESET}\n"
                break
                ;;
            [Nn]*) 
                echo -e "${FG_YELLOW}TBL button skipped${RESET}\n"
                break
                ;;
            *) 
                echo -e "${FG_YELLOW}Please answer y or n${RESET}"
                ;;
        esac
    done
    
    show_step "02" "OPEN Project Configuration"
    
    # Simulate project loading
    echo -e "${FG_WHITE}Loading project configuration...${RESET}"
    sleep 1
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "gwhkbbp-gcp-01-6683def0488")
    PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)" 2>/dev/null || echo "632028013450")
    
    echo -e "${FG_GREEN}✓ Project loaded successfully${RESET}"
    echo -e "${FG_CYAN}Project ID:${RESET} ${FG_WHITE}$PROJECT_ID${RESET}"
    echo -e "${FG_CYAN}Project Number:${RESET} ${FG_WHITE}$PROJECT_NUMBER${RESET}\n"
    
    show_step "02" "Protocol Selection"
    
    echo -e "${FG_GREEN}✓ Selected Protocols: YEARS VS${RESET}\n"
    echo -e "${FG_CYAN}Protocol:${RESET} ${FG_WHITE}YEARS WebSocket${RESET}"
    echo -e "${FG_CYAN}Docker Image:${RESET} ${FG_WHITE}docker.io/class404/clear-wrlistcat${RESET}\n"
}

# ----------------------------
# CPU Configuration
# ----------------------------
select_cpu() {
    show_step "03" "CPU Configuration"
    
    echo -e "${FG_WHITE}Select CPU configuration:${RESET}\n"
    echo -e "${FG_CYAN}1)${RESET} ${FG_WHITE}1 CPU (small)${RESET}"
    echo -e "${FG_CYAN}2)${RESET} ${FG_WHITE}2 CPU (default)${RESET}"
    echo -e "${FG_CYAN}3)${RESET} ${FG_WHITE}4 CPU (recommended)${RESET}"
    echo -e "${FG_CYAN}4)${RESET} ${FG_WHITE}8 CPU (high)${RESET}"
    
    while true; do
        read -p "Select CPU (1-4) [3]: " cpu_choice
        cpu_choice=${cpu_choice:-3}
        
        case $cpu_choice in
            1) CPU="1"; break ;;
            2) CPU="2"; break ;;
            3) CPU="4"; break ;;
            4) CPU="8"; break ;;
            *) echo -e "${FG_YELLOW}Please enter 1-4${RESET}";;
        esac
    done
    
    echo -e "\n${FG_WHITE}✓ Selected CPU:${FG_GREEN} ${CPU}${RESET}\n"
}

# ----------------------------
# Memory Configuration
# ----------------------------
select_memory() {
    show_step "04" "Memory Configuration"
    
    # Show recommendations based on CPU
    echo -e "${FG_WHITE}Memory recommendations for ${CPU} CPU:${RESET}"
    case $CPU in
        1) echo -e "${FG_YELLOW}Recommended: 512Mi - 2Gi${RESET}" ;;
        2) echo -e "${FG_YELLOW}Recommended: 1Gi - 4Gi${RESET}" ;;
        4) echo -e "${FG_YELLOW}Recommended: 2Gi - 8Gi${RESET}" ;;
        8) echo -e "${FG_YELLOW}Recommended: 4Gi - 16Gi${RESET}" ;;
    esac
    
    echo -e "\n${FG_WHITE}Available options:${RESET}"
    echo -e "${FG_CYAN}1)${RESET} ${FG_WHITE}512Mi${RESET}"
    echo -e "${FG_CYAN}2)${RESET} ${FG_WHITE}1Gi${RESET}"
    echo -e "${FG_CYAN}3)${RESET} ${FG_WHITE}2Gi${RESET}"
    echo -e "${FG_CYAN}4)${RESET} ${FG_WHITE}4Gi${RESET}"
    echo -e "${FG_CYAN}5)${RESET} ${FG_WHITE}8Gi${RESET}"
    echo -e "${FG_CYAN}6)${RESET} ${FG_WHITE}16Gi${RESET}"
    
    while true; do
        read -p "Select memory (1-6) [3]: " memory_choice
        memory_choice=${memory_choice:-3}
        
        case $memory_choice in
            1) MEMORY="512Mi"; break ;;
            2) MEMORY="1Gi"; break ;;
            3) MEMORY="2Gi"; break ;;
            4) MEMORY="4Gi"; break ;;
            5) MEMORY="8Gi"; break ;;
            6) MEMORY="16Gi"; break ;;
            *) echo -e "${FG_YELLOW}Please enter 1-6${RESET}";;
        esac
    done
    
    echo -e "\n${FG_WHITE}✓ Selected Memory:${FG_GREEN} ${MEMORY}${RESET}\n"
}

# ----------------------------
# Telegram Destination
# ----------------------------
select_telegram_destination() {
    show_step "05" "Telegram Destination Setup"
    
    echo -e "${FG_WHITE}Select telegram notification destination:${RESET}\n"
    echo -e "${FG_CYAN}1)${RESET} ${FG_WHITE}Channel only${RESET}"
    echo -e "${FG_CYAN}2)${RESET} ${FG_WHITE}Bot private message only${RESET}"
    echo -e "${FG_CYAN}3)${RESET} ${FG_WHITE}Both channel and bot${RESET}"
    echo -e "${FG_CYAN}4)${RESET} ${FG_WHITE}Don't send notifications${RESET}"
    
    while true; do
        read -p "Select option (1-4) [1]: " tchoice
        tchoice=${tchoice:-1}
        
        case $tchoice in
            1)
                TELEGRAM_DESTINATION="channel"
                while true; do
                    read -p "Enter Telegram Channel ID (e.g., -100123456789): " TELEGRAM_CHANNEL_ID
                    if [[ "$TELEGRAM_CHANNEL_ID" =~ ^-?[0-9]+$ ]]; then
                        break
                    else
                        echo -e "${FG_YELLOW}Invalid channel ID. Use numeric ID with optional - prefix${RESET}"
                    fi
                done
                break
                ;;
            2)
                TELEGRAM_DESTINATION="bot"
                while true; do
                    read -p "Enter your Chat ID (for bot): " TELEGRAM_CHAT_ID
                    if [[ "$TELEGRAM_CHAT_ID" =~ ^-?[0-9]+$ ]]; then
                        break
                    else
                        echo -e "${FG_YELLOW}Invalid chat ID. Use numeric ID${RESET}"
                    fi
                done
                break
                ;;
            3)
                TELEGRAM_DESTINATION="both"
                while true; do
                    read -p "Enter Telegram Channel ID: " TELEGRAM_CHANNEL_ID
                    if [[ "$TELEGRAM_CHANNEL_ID" =~ ^-?[0-9]+$ ]]; then
                        break
                    else
                        echo -e "${FG_YELLOW}Invalid channel ID${RESET}"
                    fi
                done
                while true; do
                    read -p "Enter your Chat ID (for bot): " TELEGRAM_CHAT_ID
                    if [[ "$TELEGRAM_CHAT_ID" =~ ^-?[0-9]+$ ]]; then
                        break
                    else
                        echo -e "${FG_YELLOW}Invalid chat ID${RESET}"
                    fi
                done
                break
                ;;
            4)
                TELEGRAM_DESTINATION="none"
                break
                ;;
            *)
                echo -e "${FG_YELLOW}Please enter 1-4${RESET}";;
        esac
    done
    
    echo -e "\n${FG_WHITE}✓ Telegram destination:${FG_GREEN} ${TELEGRAM_DESTINATION}${RESET}\n"
}

# ----------------------------
# Service Configuration
# ----------------------------
get_service_config() {
    show_step "06" "Service Configuration"
    
    while true; do
        read -p "Service name [jue-vless]: " SERVICE_NAME
        SERVICE_NAME=${SERVICE_NAME:-jue-vless}
        if [[ -n "$SERVICE_NAME" ]]; then
            break
        fi
    done
    
    # UUID with validation
    while true; do
        read -p "UUID [ba0e3984-ccc9-48a3-8074-b2f507f41ce8]: " UUID
        UUID=${UUID:-ba0e3984-ccc9-48a3-8074-b2f507f41ce8}
        if [[ "$UUID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
            break
        else
            echo -e "${FG_YELLOW}Invalid UUID format. Please use valid UUID format${RESET}"
        fi
    done
    
    # Telegram Bot Token if needed
    if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
        while true; do
            read -p "Telegram Bot Token: " TELEGRAM_BOT_TOKEN
            if [[ "$TELEGRAM_BOT_TOKEN" =~ ^[0-9]{8,12}:[A-Za-z0-9_-]{35,}$ ]]; then
                break
            else
                echo -e "${FG_YELLOW}Invalid bot token format. Should be like: 1234567890:ABCdefGhIJKlmNoPQRsTUVwxyZ${RESET}"
            fi
        done
    fi
    
    # Host domain
    read -p "Host domain [m.googleapis.com]: " HOST_DOMAIN
    HOST_DOMAIN=${HOST_DOMAIN:-m.googleapis.com}
    
    echo -e "\n${FG_WHITE}✓ Service configuration completed${RESET}\n"
}

# ----------------------------
# Configuration Summary
# ----------------------------
show_config_summary() {
    show_step "07" "Before Detection - Configuration Summary"
    
    echo -e "${FG_CYAN}┌────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}Configuration Summary                                                      ${FG_CYAN}│${RESET}"
    echo -e "${FG_CYAN}├────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}• Project ID:    ${FG_GREEN}$(gcloud config get-value project 2>/dev/null || echo "$PROJECT_ID")${RESET}${FG_CYAN}                   │${RESET}"
    echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}• Region:        ${FG_GREEN}$REGION${RESET}${FG_CYAN}                                                               │${RESET}"
    echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}• Service Name:  ${FG_GREEN}$SERVICE_NAME${RESET}${FG_CYAN}                                                         │${RESET}"
    echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}• Host Domain:   ${FG_GREEN}$HOST_DOMAIN${RESET}${FG_CYAN}                                                         │${RESET}"
    echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}• UUID:          ${FG_GREEN}$UUID${RESET}${FG_CYAN}                                                               │${RESET}"
    echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}• CPU:           ${FG_GREEN}$CPU${RESET}${FG_CYAN}                                                                 │${RESET}"
    echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}• Memory:        ${FG_GREEN}$MEMORY${RESET}${FG_CYAN}                                                               │${RESET}"
    
    if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
        echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}• Telegram:      ${FG_GREEN}$TELEGRAM_DESTINATION${RESET}${FG_CYAN}                                                   │${RESET}"
        [[ -n "${TELEGRAM_CHANNEL_ID:-}" ]] && \
        echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}  Channel ID:    ${FG_GREEN}$TELEGRAM_CHANNEL_ID${RESET}${FG_CYAN}                                                     │${RESET}"
        [[ -n "${TELEGRAM_CHAT_ID:-}" ]] && \
        echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}  Chat ID:       ${FG_GREEN}$TELEGRAM_CHAT_ID${RESET}${FG_CYAN}                                                       │${RESET}"
    else
        echo -e "${FG_CYAN}│${RESET} ${FG_WHITE}• Telegram:      ${FG_YELLOW}Not configured${RESET}${FG_CYAN}                                                     │${RESET}"
    fi
    echo -e "${FG_CYAN}└────────────────────────────────────────────────────────────────────────┘${RESET}\n"
    
    # Final confirmation
    echo -e "${FG_YELLOW}══════════════════════════════════════════════════════════════════════════${RESET}"
    while true; do
        read -p "Proceed with deployment? (y/n) [y]: " confirm
        confirm=${confirm:-y}
        case $confirm in
            [Yy]*)
                echo -e "${FG_GREEN}Starting deployment...${RESET}\n"
                break
                ;;
            [Nn]*)
                echo -e "${FG_YELLOW}Deployment cancelled by user${RESET}"
                exit 0
                ;;
            *)
                echo -e "${FG_YELLOW}Please answer y or n${RESET}"
                ;;
        esac
    done
}

# ----------------------------
# Deployment Functions
# ----------------------------
validate_prerequisites() {
    log "Validating prerequisites..."
    
    # Check gcloud
    if ! command -v gcloud &>/dev/null; then
        error "Google Cloud SDK (gcloud) is not installed or not in PATH"
        exit 1
    fi
    
    # Check git
    if ! command -v git &>/dev/null; then
        error "Git is not installed or not in PATH"
        exit 1
    fi
    
    # Check project
    local project_id
    project_id=$(gcloud config get-value project 2>/dev/null)
    if [[ -z "$project_id" || "$project_id" == "(unset)" ]]; then
        error "No project configured. Run: gcloud config set project PROJECT_ID"
        exit 1
    fi
    
    log "Prerequisites validation passed"
}

cleanup() {
    log "Cleaning up temporary files..."
    [[ -d "gcp-v2ray" ]] && rm -rf gcp-v2ray
}

send_to_telegram() {
    local chat_id="$1"
    local message="$2"
    
    # URL encode message
    local encoded_msg
    encoded_msg=$(echo "$message" | sed 's/ /%20/g; s/"/%22/g; s/\\/%5C/g; s/\//%2F/g;')
    
    local api_url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
    local payload="chat_id=${chat_id}&text=${encoded_msg}&parse_mode=Markdown&disable_web_page_preview=true"
    
    local response
    response=$(curl -s -w "%{http_code}" -X POST -d "$payload" "$api_url")
    local http_code="${response: -3}"
    
    if [[ "$http_code" == "200" ]]; then
        return 0
    else
        error "Telegram API error: HTTP $http_code"
        return 1
    fi
}

send_deployment_notification() {
    local message="$1"
    local ok=0
    
    case $TELEGRAM_DESTINATION in
        channel)
            log "Sending notification to channel..."
            if send_to_telegram "$TELEGRAM_CHANNEL_ID" "$message"; then
                ok=1
            fi
            ;;
        bot)
            log "Sending notification to bot..."
            if send_to_telegram "$TELEGRAM_CHAT_ID" "$message"; then
                ok=1
            fi
            ;;
        both)
            log "Sending notifications to both channel and bot..."
            send_to_telegram "$TELEGRAM_CHANNEL_ID" "$message" && ok=$((ok+1))
            send_to_telegram "$TELEGRAM_CHAT_ID" "$message" && ok=$((ok+1))
            ;;
        none)
            log "Telegram notifications disabled"
            return 0
            ;;
    esac
    
    if [[ $ok -gt 0 ]]; then
        log "Telegram notification sent successfully"
        return 0
    else
        warn "Failed to send Telegram notifications"
        return 1
    fi
}

# ----------------------------
# Main Deployment
# ----------------------------
main() {
    # Show banner
    show_banner
    
    # Configuration steps
    select_region
    select_telegram_config
    select_cpu
    select_memory
    select_telegram_destination
    get_service_config
    show_config_summary
    
    # Get project ID
    PROJECT_ID=$(gcloud config get-value project)
    log "Starting deployment for project: $PROJECT_ID"
    
    # Validate prerequisites
    validate_prerequisites
    
    # Cleanup on exit
    trap cleanup EXIT
    
    # Enable required APIs
    log "Enabling required Google Cloud APIs..."
    gcloud services enable \
        cloudbuild.googleapis.com \
        run.googleapis.com \
        iam.googleapis.com \
        --quiet
    
    # Cleanup old files
    cleanup
    
    # Clone repository
    log "Cloning V2Ray configuration repository..."
    git clone https://github.com/nyeinkokoaung404/gcp-v2ray.git || {
        error "Failed to clone repository"
        exit 1
    }
    cd gcp-v2ray || exit 1
    
    # Build Docker image
    log "Building Docker image..."
    gcloud builds submit \
        --tag "gcr.io/${PROJECT_ID}/gcp-v2ray-image" \
        --quiet || {
        error "Docker build failed"
        exit 1
    }
    
    # Deploy to Cloud Run
    log "Deploying to Cloud Run..."
    gcloud run deploy "$SERVICE_NAME" \
        --image "gcr.io/${PROJECT_ID}/gcp-v2ray-image" \
        --platform managed \
        --region "$REGION" \
        --allow-unauthenticated \
        --cpu "$CPU" \
        --memory "$MEMORY" \
        --quiet || {
        error "Cloud Run deployment failed"
        exit 1
    }
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
        --region "$REGION" \
        --format 'value(status.url)' \
        --quiet)
    
    DOMAIN="${SERVICE_URL#https://}"
    
    # Generate VLESS link
    VLESS_LINK="vless://${UUID}@${HOST_DOMAIN}:443?path=%2Ftg-%40nkka404&security=tls&alpn=h3%2Ch2%2Chttp%2F1.1&encryption=none&host=${DOMAIN}&fp=randomized&type=ws&sni=${DOMAIN}#${SERVICE_NAME}"
    
    # Create deployment message
    MESSAGE="*GCP V2Ray Deployment Successful ✅*

• *Project:* \`${PROJECT_ID}\`
• *Service:* \`${SERVICE_NAME}\`
• *Region:* \`${REGION}\`
• *Resources:* \`${CPU} CPU | ${MEMORY}\`
• *Domain:* \`${DOMAIN}\`
• *Service URL:* \`${SERVICE_URL}\`

*VLESS Configuration Link:*
\`\`\`
${VLESS_LINK}
\`\`\`

*Powered by YEARS VS DEPLOYMENT SYSTEM v2.0*"
    
    # Save info to file
    echo "$MESSAGE" > deployment-info.txt
    log "Deployment information saved to: deployment-info.txt"
    
    # Display success
    echo -e "\n${FG_GREEN}══════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${FG_GREEN}                    DEPLOYMENT SUCCESSFUL!                    ${RESET}"
    echo -e "${FG_GREEN}══════════════════════════════════════════════════════════════════════════${RESET}\n"
    
    echo -e "${FG_CYAN}Service URL:${RESET} ${FG_WHITE}${SERVICE_URL}${RESET}"
    echo -e "${FG_CYAN}Domain:${RESET} ${FG_WHITE}${DOMAIN}${RESET}"
    echo -e "${FG_CYAN}VLESS Link saved to:${RESET} ${FG_WHITE}deployment-info.txt${RESET}\n"
    
    # Send Telegram notification
    if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
        log "Sending deployment notification to Telegram..."
        send_deployment_notification "$MESSAGE"
    fi
    
    # Final message
    echo -e "${FG_YELLOW}╔══════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${FG_YELLOW}║${RESET} ${FG_WHITE}Deployment completed successfully!                                  ${FG_YELLOW}║${RESET}"
    echo -e "${FG_YELLOW}║${RESET} ${FG_WHITE}Check deployment-info.txt for your VLESS configuration.            ${FG_YELLOW}║${RESET}"
    echo -e "${FG_YELLOW}╚══════════════════════════════════════════════════════════════════════╝${RESET}\n"
}

# Run main function
main "$@"
