#!/bin/bash
set -euo pipefail

# ============================
# Enhanced GCP Cloud Run V2Ray Deployment Script
# - Yellow boxed headers
# - White body text with green/yellow/cyan accents
# - Region "cards" tidy layout
# ============================

# ----------------------------
# Colors (foreground & background)
# ----------------------------
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

# Backgrounds
BG_YELLOW=$'\033[48;5;226m'   # yellow box for headers
BG_GREEN=$'\033[48;5;22m'
BG_BLUE=$'\033[48;5;19m'
BG_CYAN=$'\033[48;5;44m'
BG_MAGENTA=$'\033[48;5;90m'
BG_GRAY=$'\033[48;5;238m'
BG_RESET=$'\033[49m'

# Banner palette (three colors)
B1=$'\033[38;5;46m'    # green
B2=$'\033[38;5;226m'   # yellow
B3=$'\033[38;5;51m'    # cyan

# ----------------------------
# Logging helpers (white body)
# ----------------------------
log()  { echo -e "${FG_GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${RESET} ${FG_WHITE}$1${RESET}"; }
warn() { echo -e "${FG_YELLOW}[WARNING]${RESET} ${FG_WHITE}$1${RESET}"; }
error(){ echo -e "${FG_RED}[ERROR]${RESET} ${FG_WHITE}$1${RESET}"; }
info() { echo -e "${FG_BLUE}[INFO]${RESET} ${FG_WHITE}$1${RESET}"; }

# ----------------------------
# Boxed header (yellow background, white text centered-ish)
# Usage: show_box_header "STEP 01" "Telegram Configuration"
# ----------------------------
show_box_header() {
  local title="$1"
  local subtitle="$2"
  local width=66
  # top border
  printf "%b\n" "${BG_YELLOW}${FG_BLACK} $(printf '%*s' "$width" | tr ' ' ' ') ${BG_RESET}"
  # title line (white bold)
  printf "%b\n" "${BG_YELLOW}${FG_BLACK}  ${BOLD}${FG_WHITE}${title}${RESET}${BG_YELLOW}$(printf '%*s' $((width - ${#title} - 2)) )${BG_RESET}"
  # subtitle
  if [[ -n "$subtitle" ]]; then
    printf "%b\n" "${BG_YELLOW}${FG_BLACK}  ${FG_WHITE}${subtitle}${BG_YELLOW}$(printf '%*s' $((width - ${#subtitle} - 2)) )${BG_RESET}"
  fi
  # bottom border
  printf "%b\n\n" "${BG_YELLOW}${FG_BLACK} $(printf '%*s' "$width" | tr ' ' ' ') ${BG_RESET}"
}

# ----------------------------
# Banner (ASCII with three-color cycling) + yellow header above
# ----------------------------
show_banner() {
  show_box_header "🔰 VLESS WS DEPLOYMENT SYSTEM" "VERSION - 2.0     Powered by JUE HTET"

  # ASCII art lines with three-color cycle, printed in white background frame
  local lines=(
"___           ___     "
"    ___         /\  \         /\__\    "
"   /\__\        \:\  \       /:/ _/_   "
"  /:/__/         \:\  \     /:/ /\__\  "
" /::\  \     ___  \:\  \   /:/ /:/ _/_ "
" \/\:\  \   /\  \  \:\__\ /:/_/:/ /\__\\"
"  ~~\:\  \  \:\  \ /:/  / \:\/:/ /:/  /"
"     \:\__\  \:\  /:/  /   \::/_/:/  / "
"     /:/  /   \:\/:/  /     \:\/:/  /  "
"    /:/  /     \::/  /       \::/  /   "
"    \/__/       \/__/         \/__/    "
  )
  printf "%b\n" "${BG_GRAY}                                                                              ${BG_RESET}"
  local i=0
  for ln in "${lines[@]}"; do
    case $((i % 3)) in
      0) color="$B1" ;;
      1) color="$B2" ;;
      2) color="$B3" ;;
    esac
    printf "%b\n" "${BG_GRAY}  ${color}${BOLD}${ln}${RESET}${BG_GRAY}$(printf '%*s' $((72 - ${#ln})) )${BG_RESET}"
    i=$((i+1))
  done
  printf "%b\n\n" "${BG_GRAY}                                                                              ${BG_RESET}"
  # small footer line
  echo -e "${FG_WHITE}  ${FG_CYAN}Use arrow keys / numbers to navigate prompts. ${RESET}\n"
}

# ----------------------------
# show_step uses yellow boxed header
# ----------------------------
show_step() {
  local step="$1"
  local title="$2"
  show_box_header "STEP ${step}" "${title}"
}

# ----------------------------
# Region "cards" (flag + colored background, white text)
# ----------------------------
select_region() {
  show_step "01" "Region Selection"

  # regions: flag|name|code|bg
  regions=(
"🇸🇬|Singapore (asia-southeast1)|asia-southeast1|${BG_GREEN}"
"🇺🇸|United States (us-central1)|us-central1|${BG_BLUE}"
"🇮🇩|Indonesia (asia-southeast2)|asia-southeast2|${BG_CYAN}"
"🇯🇵|Japan (asia-northeast1)|asia-northeast1|${BG_MAGENTA}"
"🇧🇪|Belgium (europe-west1)|europe-west1|${BG_YELLOW}"
"🇮🇳|India (asia-south1)|asia-south1|${BG_GRAY}"
"🇹🇼|Taiwan (asia-east1)|asia-east1|${BG_GRAY}"
  )

  # print cards two per line
  local idx=1
  for entry in "${regions[@]}"; do
    IFS='|' read -r flag name code bg <<< "$entry"
    # card text white on bg, padded
    local txt=" ${flag} ${name} "
    printf "%b" "${bg}${FG_WHITE}${BOLD}${txt}${BG_RESET}"
    if (( idx % 2 == 0 )); then
      printf "\n"
    else
      printf "    "
    fi
    idx=$((idx+1))
  done
  printf "\n\n"

  # choose
  while true; do
    echo -e "${FG_WHITE}Choose region by number:${RESET}"
    echo -e "${FG_WHITE} 1) asia-southeast1   2) us-central1   3) asia-southeast2${RESET}"
    echo -e "${FG_WHITE} 4) asia-northeast1   5) europe-west1  6) asia-south1   7) asia-east1${RESET}"
    read -p "Select region (1-7) [1]: " region_choice
    region_choice=${region_choice:-1}
    case $region_choice in
      1) REGION="asia-southeast1"; break ;;
      2) REGION="us-central1"; break ;;
      3) REGION="asia-southeast2"; break ;;
      4) REGION="asia-northeast1"; break ;;
      5) REGION="europe-west1"; break ;;
      6) REGION="asia-south1"; break ;;
      7) REGION="asia-east1"; break ;;
      *) echo -e "${FG_YELLOW}Invalid selection. Enter 1-7.${RESET}";;
    esac
  done

  echo -e "${FG_WHITE}Selected region:${FG_GREEN} ${REGION}${RESET}\n"
}

# ----------------------------
# CPU / Memory selection (white body)
# ----------------------------
select_cpu() {
  show_step "02" "CPU Configuration"
  echo -e "${FG_WHITE}1) 1 CPU (small)\n2) 2 CPU (default)\n3) 4 CPU (recommended)\n4) 8 CPU (high)${RESET}"
  while true; do
    read -p "Select CPU (1-4) [2]: " cpu_choice
    cpu_choice=${cpu_choice:-2}
    case $cpu_choice in
      1) CPU="1"; break ;;
      2) CPU="2"; break ;;
      3) CPU="4"; break ;;
      4) CPU="8"; break ;;
      *) echo -e "${FG_YELLOW}Enter 1-4${RESET}";;
    esac
  done
  echo -e "${FG_WHITE}Selected CPU:${FG_GREEN} ${CPU}${RESET}\n"
}

select_memory() {
  show_step "03" "Memory Configuration"
  case $CPU in
    1) echo -e "${FG_WHITE}Recommended: 512Mi - 2Gi${RESET}" ;;
    2) echo -e "${FG_WHITE}Recommended: 1Gi - 4Gi${RESET}" ;;
    4) echo -e "${FG_WHITE}Recommended: 2Gi - 8Gi${RESET}" ;;
    8) echo -e "${FG_WHITE}Recommended: 4Gi - 16Gi${RESET}" ;;
  esac
  echo -e "${FG_WHITE}Options:\n1) 512Mi\n2) 1Gi\n3) 2Gi\n4) 4Gi\n5) 8Gi\n6) 16Gi${RESET}"
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
      *) echo -e "${FG_YELLOW}Enter 1-6${RESET}";;
    esac
  done
  echo -e "${FG_WHITE}Selected Memory:${FG_GREEN} ${MEMORY}${RESET}\n"
}

# ----------------------------
# Telegram selection & inputs
# ----------------------------
select_telegram_destination() {
  show_step "04" "Telegram Destination"
  echo -e "${FG_WHITE}1) Channel only\n2) Bot private message only\n3) Both channel and bot\n4) Don't send${RESET}"
  while true; do
    read -p "Select (1-4) [1]: " tchoice
    tchoice=${tchoice:-1}
    case $tchoice in
      1)
        TELEGRAM_DESTINATION="channel"
        while true; do
          read -p "Enter Telegram Channel ID: " TELEGRAM_CHANNEL_ID
          [[ "$TELEGRAM_CHANNEL_ID" =~ ^-?[0-9]+$ ]] && break
          echo -e "${FG_YELLOW}Invalid channel ID${RESET}"
        done
        break
        ;;
      2)
        TELEGRAM_DESTINATION="bot"
        while true; do
          read -p "Enter your Chat ID (for bot): " TELEGRAM_CHAT_ID
          [[ "$TELEGRAM_CHAT_ID" =~ ^-?[0-9]+$ ]] && break
          echo -e "${FG_YELLOW}Invalid chat ID${RESET}"
        done
        break
        ;;
      3)
        TELEGRAM_DESTINATION="both"
        while true; do
          read -p "Enter Telegram Channel ID: " TELEGRAM_CHANNEL_ID
          [[ "$TELEGRAM_CHANNEL_ID" =~ ^-?[0-9]+$ ]] && break
          echo -e "${FG_YELLOW}Invalid channel ID${RESET}"
        done
        while true; do
          read -p "Enter your Chat ID (for bot): " TELEGRAM_CHAT_ID
          [[ "$TELEGRAM_CHAT_ID" =~ ^-?[0-9]+$ ]] && break
          echo -e "${FG_YELLOW}Invalid chat ID${RESET}"
        done
        break
        ;;
      4)
        TELEGRAM_DESTINATION="none"
        break
        ;;
      *)
        echo -e "${FG_YELLOW}Enter 1-4${RESET}";;
    esac
  done
  echo -e "${FG_WHITE}Telegram destination:${FG_GREEN} ${TELEGRAM_DESTINATION}${RESET}\n"
}

# ----------------------------
# Other inputs
# ----------------------------
get_user_input() {
  show_step "05" "Service Configuration"

  while true; do
    read -p "Service name [jue-vless]: " SERVICE_NAME
    SERVICE_NAME=${SERVICE_NAME:-jue-vless}
    [[ -n "$SERVICE_NAME" ]] && break
  done

  while true; do
    read -p "UUID (press Enter to use default): " UUID
    UUID=${UUID:-ba0e3984-ccc9-48a3-8074-b2f507f41ce8}
    if [[ "$UUID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
      break
    else
      echo -e "${FG_YELLOW}Invalid UUID format${RESET}"
    fi
  done

  if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
    while true; do
      read -p "Telegram Bot Token: " TELEGRAM_BOT_TOKEN
      if [[ "$TELEGRAM_BOT_TOKEN" =~ ^[0-9]{8,12}:[A-Za-z0-9_-]{10,}$ ]]; then break; else echo -e "${FG_YELLOW}Token seems invalid${RESET}"; fi
    done
  fi

  read -p "Host domain [m.googleapis.com]: " HOST_DOMAIN
  HOST_DOMAIN=${HOST_DOMAIN:-m.googleapis.com}
}

# ----------------------------
# Summary & confirm
# ----------------------------
show_config_summary() {
  show_step "06" "Configuration Summary"
  echo -e "${FG_WHITE}Project ID:    $(gcloud config get-value project)${RESET}"
  echo -e "${FG_WHITE}Region:        ${FG_GREEN}$REGION${RESET}"
  echo -e "${FG_WHITE}Service Name:  ${FG_GREEN}$SERVICE_NAME${RESET}"
  echo -e "${FG_WHITE}Host Domain:   ${FG_GREEN}$HOST_DOMAIN${RESET}"
  echo -e "${FG_WHITE}UUID:          ${FG_GREEN}$UUID${RESET}"
  echo -e "${FG_WHITE}CPU:           ${FG_GREEN}$CPU${RESET}"
  echo -e "${FG_WHITE}Memory:        ${FG_GREEN}$MEMORY${RESET}"
  if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
    echo -e "${FG_WHITE}Telegram:      ${FG_GREEN}$TELEGRAM_DESTINATION${RESET}"
    [[ -n "${TELEGRAM_CHANNEL_ID:-}" ]] && echo -e "${FG_WHITE}Channel ID:    ${FG_GREEN}$TELEGRAM_CHANNEL_ID${RESET}"
    [[ -n "${TELEGRAM_CHAT_ID:-}" ]] && echo -e "${FG_WHITE}Chat ID:       ${FG_GREEN}$TELEGRAM_CHAT_ID${RESET}"
  else
    echo -e "${FG_WHITE}Telegram:      ${FG_YELLOW}Not configured${RESET}"
  fi

  while true; do
    read -p "Proceed with deployment? (y/n) [y]: " confirm
    confirm=${confirm:-y}
    case $confirm in
      [Yy]*) break ;;
      [Nn]*) echo -e "${FG_YELLOW}Cancelled by user${RESET}"; exit 0 ;;
      *) echo -e "${FG_YELLOW}Please answer y or n${RESET}";;
    esac
  done
}

# ----------------------------
# Prereqs / helper functions
# ----------------------------
LOG_FILE="/tmp/jue_vless_$(date +%s).log"
touch "$LOG_FILE"

validate_prerequisites() {
  log "Validating prerequisites..."
  if ! command -v gcloud &>/dev/null; then error "gcloud CLI missing"; exit 1; fi
  if ! command -v git &>/dev/null; then error "git missing"; exit 1; fi
  local PROJECT_ID
  PROJECT_ID=$(gcloud config get-value project)
  if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then error "gcloud project not set. Run: gcloud config set project PROJECT_ID"; exit 1; fi
}

cleanup() {
  log "Cleaning up..."
  [[ -d "gcp-v2ray" ]] && rm -rf gcp-v2ray
}

send_to_telegram() {
  local chat_id="$1"
  local message="$2"
  local payload
  payload=$(printf '{"chat_id":"%s","text":"%s","parse_mode":"Markdown","disable_web_page_preview":true}' "$chat_id" "$message")
  local resp
  resp=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$payload" "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage")
  local code="${resp: -3}"
  local body="${resp%???}"
  if [[ "$code" == "200" ]]; then
    return 0
  else
    error "Telegram send failed (HTTP $code)"
    return 1
  fi
}

send_deployment_notification() {
  local message="$1"
  local ok=0
  case $TELEGRAM_DESTINATION in
    channel)
      log "Sending to channel..."
      if send_to_telegram "$TELEGRAM_CHANNEL_ID" "$message"; then ok=1; fi
      ;;
    bot)
      log "Sending to bot..."
      if send_to_telegram "$TELEGRAM_CHAT_ID" "$message"; then ok=1; fi
      ;;
    both)
      log "Sending to channel & bot..."
      send_to_telegram "$TELEGRAM_CHANNEL_ID" "$message" && ok=$((ok+1))
      send_to_telegram "$TELEGRAM_CHAT_ID" "$message" && ok=$((ok+1))
      ;;
    none)
      log "Skipping Telegram"
      return 0
      ;;
  esac

  if [[ $ok -gt 0 ]]; then
    log "Telegram notification sent ($ok)."
    return 0
  else
    warn "Telegram notifications failed."
    return 1
  fi
}

# ----------------------------
# Main
# ----------------------------
main() {
  show_banner

  select_region
  select_cpu
  select_memory
  select_telegram_destination
  get_user_input
  show_config_summary

  PROJECT_ID=$(gcloud config get-value project)
  log "Starting deployment (Project: $PROJECT_ID, Region: $REGION, Service: $SERVICE_NAME)"

  validate_prerequisites
  trap cleanup EXIT

  log "Enabling APIs..."
  gcloud services enable cloudbuild.googleapis.com run.googleapis.com iam.googleapis.com --quiet

  cleanup

  log "Cloning repo..."
  git clone https://github.com/nyeinkokoaung404/gcp-v2ray.git || { error "git clone failed"; exit 1; }
  cd gcp-v2ray || exit 1

  log "Building image..."
  gcloud builds submit --tag gcr.io/${PROJECT_ID}/gcp-v2ray-image --quiet || { error "build failed"; exit 1; }

  log "Deploying to Cloud Run..."
  gcloud run deploy "${SERVICE_NAME}" --image "gcr.io/${PROJECT_ID}/gcp-v2ray-image" --platform managed --region "${REGION}" --allow-unauthenticated --cpu "${CPU}" --memory "${MEMORY}" --quiet || { error "deploy failed"; exit 1; }

  SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" --region "${REGION}" --format 'value(status.url)' --quiet)
  DOMAIN=${SERVICE_URL#https://}

  VLESS_LINK="vless://${UUID}@${HOST_DOMAIN}:443?path=%2Ftg-%40nkka404&security=tls&alpn=h3%2Ch2%2Chttp%2F1.1&encryption=none&host=${DOMAIN}&fp=randomized&type=ws&sni=${DOMAIN}#${SERVICE_NAME}"

  MESSAGE="*GCP V2Ray Deployment → Successful ✅*
• Project: \`${PROJECT_ID}\`
• Service: \`${SERVICE_NAME}\`
• Region: \`${REGION}\`
• Resources: \`${CPU} CPU | ${MEMORY}\`
• Domain: \`${DOMAIN}\`

VLESS link:
\`\`\`
${VLESS_LINK}
\`\`\`"

  echo "$MESSAGE" > deployment-info.txt
  log "Saved deployment-info.txt"

  echo
  info "Deployment complete. Service URL: ${FG_GREEN}${SERVICE_URL}${RESET}"
  echo

  if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
    log "Sending Telegram notification..."
    send_deployment_notification "$MESSAGE"
  fi

  log "Done."
}

# run
main "$@"
