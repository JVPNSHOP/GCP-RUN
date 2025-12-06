#!/bin/bash
set -euo pipefail

# ============================
# GCP Cloud Run V2Ray Deployment
# Enhanced: Banner, colored region "cards" + flags, colored fonts
# ============================

# ----------------------------
# Basic colors (foreground & background)
# ----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Background colors (256-color approximate)
BG_GREEN=$'\e[48;5;22m'
BG_BLUE=$'\e[48;5;19m'
BG_YELLOW=$'\e[48;5;220m'
BG_GRAY=$'\e[48;5;238m'
BG_CYAN=$'\e[48;5;44m'
BG_MAGENTA=$'\e[48;5;90m'
RESET_BG=$'\e[49m'

# Banner palette (three colors for ASCII art)
B1=$'\e[38;5;46m'    # green-ish
B2=$'\e[38;5;226m'   # yellow
B3=$'\e[38;5;51m'    # cyan

# ----------------------------
# Logging helpers
# ----------------------------
log()  { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error(){ echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# ----------------------------
# Banner: multi-color ASCII + subtle background frame
# ----------------------------
show_banner() {
  clear
  # Top frame
  printf "%b\n" "${BG_GRAY}                                                                              ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${BOLD}${B1} ___           ___     ${B2}    ___         /\\  \\         /\\__\\    ${B3} ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${B1}    ___         /\\  \\         /\\__\\    ${B2}   /\\__\\        \\:\\  \\       /:/ _/_   ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${B2}   /\\__\\        \\:\\  \\       /:/ _/_   ${B3}  /:/__/         \\:\\  \\     /:/ /\\__\\  ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${B3}  /:/__/         \\:\\  \\     /:/ /\\__\\  ${B1} /::\\  \\     ___  \\:\\  \\   /:/ /:/ _/_ ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${B1} /::\\  \\     ___  \\:\\  \\   /:/ /:/ _/_ ${B2} \\/\\:\\  \\   /\\  \\  \\:\\__\\ /:/_/:/ /\\__/ ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${B2} \\/\\:\\  \\   /\\  \\  \\:\\__\\ /:/_/:/ /\\__\\ ${B3}  ~~\\:\\  \\  \\:\\  \\ /:/  / \\:\/:/ /:/  / ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${B3}  ~~\\:\\  \\  \\:\\  \\ /:/  / \\:\/:/ /:/  / ${B1}     \\:\\__\\  \\:\\  /:/  /   \\::/_/:/  /  ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${B1}     \\:\\__\\  \\:\\  /:/  /   \\::/_/:/  / ${B2}     /:/  /   \\:\\/:/  /     \\:\/:/  /   ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${B2}     /:/  /   \\:\\/:/  /     \\:\/:/  /  ${B3}    /:/  /     \\::/  /       \\::/  /    ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}  ${B3}    /:/  /     \\::/  /       \\::/  /   ${B1}   \\/__/       \\/__/         \\/__/     ${RESET_BG}"
  printf "%b\n" "${BG_GRAY}                                                                              ${RESET_BG}"
  printf "%b\n" "  ${YELLOW}🚀 VLESS WS DEPLOYMENT SYSTEM => ${BOLD}VERSION - 2.0${NC}"
  printf "%b\n\n" "  ${CYAN}⚡ Powered by JUE HTET${NC}"
}

# ----------------------------
# Validation helpers
# ----------------------------
validate_uuid() {
  local uuid_pattern='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  if [[ ! $1 =~ $uuid_pattern ]]; then
    error "Invalid UUID format: $1"
    return 1
  fi
  return 0
}

validate_bot_token() {
  local token_pattern='^[0-9]{8,12}:[a-zA-Z0-9_-]{35,}$'
  if [[ ! $1 =~ $token_pattern ]]; then
    error "Invalid Telegram Bot Token format"
    return 1
  fi
  return 0
}

validate_channel_id() {
  if [[ ! $1 =~ ^-?[0-9]+$ ]]; then
    error "Invalid Channel ID format"
    return 1
  fi
  return 0
}

validate_chat_id() {
  if [[ ! $1 =~ ^-?[0-9]+$ ]]; then
    error "Invalid Chat ID format"
    return 1
  fi
  return 0
}

# ----------------------------
# CPU / Memory selection
# ----------------------------
select_cpu() {
  echo
  info "=== CPU Configuration ==="
  echo -e "  1) 1 CPU Core (small)\n  2) 2 CPU Cores (default)\n  3) 4 CPU Cores (recommended)\n  4) 8 CPU Cores (high)"
  while true; do
    read -p "Select CPU cores (1-4) [2]: " cpu_choice
    cpu_choice=${cpu_choice:-2}
    case $cpu_choice in
      1) CPU="1"; break ;;
      2) CPU="2"; break ;;
      3) CPU="4"; break ;;
      4) CPU="8"; break ;;
      *) echo "Invalid selection. Please enter a number between 1-4." ;;
    esac
  done
  info "Selected CPU: $CPU core(s)"
}

select_memory() {
  echo
  info "=== Memory Configuration ==="
  case $CPU in
    1) echo "Recommended memory: 512Mi - 2Gi" ;;
    2) echo "Recommended memory: 1Gi - 4Gi" ;;
    4) echo "Recommended memory: 2Gi - 8Gi" ;;
    8) echo "Recommended memory: 4Gi - 16Gi" ;;
  esac
  echo -e "Memory Options:\n  1) 512Mi\n  2) 1Gi\n  3) 2Gi\n  4) 4Gi\n  5) 8Gi\n  6) 16Gi"
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
      *) echo "Invalid selection. Please enter a number between 1-6." ;;
    esac
  done
  validate_memory_config
  info "Selected Memory: $MEMORY"
}

validate_memory_config() {
  local cpu_num=$CPU
  local memory_num=$(echo $MEMORY | sed 's/[^0-9]*//g')
  local memory_unit=$(echo $MEMORY | sed 's/[0-9]*//g')

  if [[ "$memory_unit" == "Gi" ]]; then
    memory_num=$((memory_num * 1024))
  fi

  local min_memory=0
  local max_memory=0

  case $cpu_num in
    1) min_memory=512;  max_memory=2048 ;;
    2) min_memory=1024; max_memory=4096 ;;
    4) min_memory=2048; max_memory=8192 ;;
    8) min_memory=4096; max_memory=16384 ;;
  esac

  if [[ $memory_num -lt $min_memory ]]; then
    warn "Memory ($MEMORY) might be too low for $CPU CPU(s). Recommended minimum: $((min_memory/1024))Gi"
    read -p "Continue with this configuration? (y/n) [y]: " confirm
    confirm=${confirm:-y}
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
      select_memory
    fi
  elif [[ $memory_num -gt $max_memory ]]; then
    warn "Memory ($MEMORY) might be too high for $CPU CPU(s). Recommended maximum: $((max_memory/1024))Gi"
    read -p "Continue with this configuration? (y/n) [y]: " confirm
    confirm=${confirm:-y}
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
      select_memory
    fi
  fi
}

# ----------------------------
# Region selection with "cards" (flags + colored backgrounds)
# ----------------------------
select_region() {
  echo
  info "=== Region Selection ==="

  # Define regions array: "flag|Display Name|region-code|bg"
  regions=(
    "🇺🇸|us-central1 (Iowa, USA)|us-central1|${BG_BLUE}"
    "🇺🇸|us-west1 (Oregon, USA)|us-west1|${BG_CYAN}"
    "🇺🇸|us-east1 (South Carolina, USA)|us-east1|${BG_GREEN}"
    "🇧🇪|europe-west1 (Belgium)|europe-west1|${BG_MAGENTA}"
    "🇸🇬|asia-southeast1 (Singapore)|asia-southeast1|${BG_YELLOW}"
    "🇯🇵|asia-northeast1 (Tokyo, Japan)|asia-northeast1|${BG_BLUE}"
    "🇹🇼|asia-east1 (Taiwan)|asia-east1|${BG_GRAY}"
  )

  # Print "cards"
  local idx=1
  for entry in "${regions[@]}"; do
    IFS='|' read -r flag name code bg <<< "$entry"
    # Print card with background and padded name
    printf "%b" "${bg}  ${BOLD}${flag} ${name} ${RESET_BG}"
    # Align a couple per line (2 per line)
    if (( idx % 2 == 0 )); then
      printf "\n"
    else
      printf "    "  # spacing between cards
    fi
    idx=$((idx+1))
  done
  printf "\n\n"

  # Prompt
  while true; do
    echo "Choose region by number:"
    echo " 1) us-central1    2) us-west1    3) us-east1"
    echo " 4) europe-west1   5) asia-southeast1   6) asia-northeast1   7) asia-east1"
    read -p "Select region (1-7) [5]: " region_choice
    region_choice=${region_choice:-5}
    case $region_choice in
      1) REGION="us-central1"; break ;;
      2) REGION="us-west1"; break ;;
      3) REGION="us-east1"; break ;;
      4) REGION="europe-west1"; break ;;
      5) REGION="asia-southeast1"; break ;;
      6) REGION="asia-northeast1"; break ;;
      7) REGION="asia-east1"; break ;;
      *) echo "Invalid selection. Please enter a number between 1-7." ;;
    esac
  done
  info "Selected region: $REGION"
}

# ----------------------------
# Telegram destination selection
# ----------------------------
select_telegram_destination() {
  echo
  info "=== Telegram Destination ==="
  echo -e "  1) Send to Channel only\n  2) Send to Bot private message only\n  3) Send to both Channel and Bot\n  4) Don't send to Telegram"
  while true; do
    read -p "Select destination (1-4) [1]: " telegram_choice
    telegram_choice=${telegram_choice:-1}
    case $telegram_choice in
      1)
        TELEGRAM_DESTINATION="channel"
        while true; do
          read -p "Enter Telegram Channel ID: " TELEGRAM_CHANNEL_ID
          if validate_channel_id "$TELEGRAM_CHANNEL_ID"; then break; fi
        done
        break
        ;;
      2)
        TELEGRAM_DESTINATION="bot"
        while true; do
          read -p "Enter your Chat ID (for bot private message): " TELEGRAM_CHAT_ID
          if validate_chat_id "$TELEGRAM_CHAT_ID"; then break; fi
        done
        break
        ;;
      3)
        TELEGRAM_DESTINATION="both"
        while true; do
          read -p "Enter Telegram Channel ID: " TELEGRAM_CHANNEL_ID
          if validate_channel_id "$TELEGRAM_CHANNEL_ID"; then break; fi
        done
        while true; do
          read -p "Enter your Chat ID (for bot private message): " TELEGRAM_CHAT_ID
          if validate_chat_id "$TELEGRAM_CHAT_ID"; then break; fi
        done
        break
        ;;
      4)
        TELEGRAM_DESTINATION="none"
        break
        ;;
      *)
        echo "Invalid selection. Please enter a number between 1-4."
        ;;
    esac
  done
}

# ----------------------------
# Get other user inputs
# ----------------------------
get_user_input() {
  echo
  info "=== Service Configuration ==="

  while true; do
    read -p "Enter service name [jue-vless]: " SERVICE_NAME
    SERVICE_NAME=${SERVICE_NAME:-jue-vless}
    if [[ -n "$SERVICE_NAME" ]]; then break; else error "Service name cannot be empty"; fi
  done

  while true; do
    read -p "Enter UUID [press enter to use default]: " UUID
    UUID=${UUID:-ba0e3984-ccc9-48a3-8074-b2f507f41ce8}
    if validate_uuid "$UUID"; then break; fi
  done

  if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
    while true; do
      read -p "Enter Telegram Bot Token: " TELEGRAM_BOT_TOKEN
      if validate_bot_token "$TELEGRAM_BOT_TOKEN"; then break; fi
    done
  fi

  read -p "Enter host domain [default: m.googleapis.com]: " HOST_DOMAIN
  HOST_DOMAIN=${HOST_DOMAIN:-m.googleapis.com}
}

# ----------------------------
# Summary & confirmation
# ----------------------------
show_config_summary() {
  echo
  info "=== Configuration Summary ==="
  echo "Project ID:    $(gcloud config get-value project)"
  echo "Region:        $REGION"
  echo "Service Name:  $SERVICE_NAME"
  echo "Host Domain:   $HOST_DOMAIN"
  echo "UUID:          $UUID"
  echo "CPU:           $CPU core(s)"
  echo "Memory:        $MEMORY"
  if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
    echo "Bot Token:     ${TELEGRAM_BOT_TOKEN:0:8}..."
    echo "Destination:   $TELEGRAM_DESTINATION"
    if [[ "$TELEGRAM_DESTINATION" == "channel" || "$TELEGRAM_DESTINATION" == "both" ]]; then
      echo "Channel ID:    $TELEGRAM_CHANNEL_ID"
    fi
    if [[ "$TELEGRAM_DESTINATION" == "bot" || "$TELEGRAM_DESTINATION" == "both" ]]; then
      echo "Chat ID:       $TELEGRAM_CHAT_ID"
    fi
  else
    echo "Telegram:      Not configured"
  fi

  while true; do
    read -p "Proceed with deployment? (y/n) [y]: " confirm
    confirm=${confirm:-y}
    case $confirm in
      [Yy]*) break ;;
      [Nn]*) info "Deployment cancelled by user"; exit 0 ;;
      *) echo "Please answer yes (y) or no (n)." ;;
    esac
  done
}

# ----------------------------
# Prereqs, cleanup, telegram send
# ----------------------------
LOG_FILE="/tmp/jue_vless_$(date +%s).log"
touch "$LOG_FILE"

validate_prerequisites() {
  log "Validating prerequisites..."
  if ! command -v gcloud &> /dev/null; then error "gcloud CLI is not installed. Please install Google Cloud SDK."; exit 1; fi
  if ! command -v git &> /dev/null; then error "git is not installed. Please install git."; exit 1; fi
  local PROJECT_ID
  PROJECT_ID=$(gcloud config get-value project)
  if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then error "No project configured. Run: gcloud config set project PROJECT_ID"; exit 1; fi
}

cleanup() {
  log "Cleaning up temporary files..."
  if [[ -d "gcp-v2ray" ]]; then rm -rf gcp-v2ray; fi
}

send_to_telegram() {
  local chat_id="$1"
  local message="$2"
  # Use simple JSON payload; note: the bot token must be valid and bot must be allowed in channel (if channel).
  local response
  response=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$(printf '{"chat_id":"%s","text":"%s","parse_mode":"Markdown","disable_web_page_preview":true}' "$chat_id" "$message")" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage")
  local http_code="${response: -3}"
  local content="${response%???}"
  if [[ "$http_code" == "200" ]]; then
    return 0
  else
    error "Failed to send to Telegram (HTTP $http_code): $content"
    return 1
  fi
}

send_deployment_notification() {
  local message="$1"
  local success_count=0
  case $TELEGRAM_DESTINATION in
    "channel")
      log "Sending to Telegram Channel..."
      if send_to_telegram "$TELEGRAM_CHANNEL_ID" "$message"; then log "✅ Successfully sent to Telegram Channel"; success_count=$((success_count+1)); else error "❌ Failed to send to Telegram Channel"; fi
      ;;
    "bot")
      log "Sending to Bot private message..."
      if send_to_telegram "$TELEGRAM_CHAT_ID" "$message"; then log "✅ Successfully sent to Bot private message"; success_count=$((success_count+1)); else error "❌ Failed to send to Bot private message"; fi
      ;;
    "both")
      log "Sending to both Channel and Bot..."
      if send_to_telegram "$TELEGRAM_CHANNEL_ID" "$message"; then log "✅ Successfully sent to Telegram Channel"; success_count=$((success_count+1)); else error "❌ Failed to send to Telegram Channel"; fi
      if send_to_telegram "$TELEGRAM_CHAT_ID" "$message"; then log "✅ Successfully sent to Bot private message"; success_count=$((success_count+1)); else error "❌ Failed to send to Bot private message"; fi
      ;;
    "none")
      log "Skipping Telegram notification as configured"
      return 0
      ;;
  esac

  if [[ $success_count -gt 0 ]]; then
    log "Telegram notification completed ($success_count successful)"
    return 0
  else
    warn "All Telegram notifications failed, but deployment was successful"
    return 1
  fi
}

# ----------------------------
# Main deployment flow
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
  log "Starting Cloud Run deployment..."
  log "Project: $PROJECT_ID"
  log "Region: $REGION"
  log "Service: $SERVICE_NAME"
  log "CPU: $CPU core(s)"
  log "Memory: $MEMORY"

  validate_prerequisites

  trap cleanup EXIT

  log "Enabling required APIs..."
  gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    iam.googleapis.com \
    --quiet

  cleanup

  log "Cloning repository..."
  if ! git clone https://github.com/nyeinkokoaung404/gcp-v2ray.git; then
    error "Failed to clone repository"
    exit 1
  fi

  cd gcp-v2ray

  log "Building container image..."
  if ! gcloud builds submit --tag gcr.io/${PROJECT_ID}/gcp-v2ray-image --quiet; then
    error "Build failed"
    exit 1
  fi

  log "Deploying to Cloud Run..."
  if ! gcloud run deploy "${SERVICE_NAME}" \
      --image "gcr.io/${PROJECT_ID}/gcp-v2ray-image" \
      --platform managed \
      --region "${REGION}" \
      --allow-unauthenticated \
      --cpu "${CPU}" \
      --memory "${MEMORY}" \
      --quiet; then
    error "Deployment failed"
    exit 1
  fi

  SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
    --region "${REGION}" \
    --format 'value(status.url)' \
    --quiet)

  DOMAIN=$(echo "$SERVICE_URL" | sed 's|https://||')

  VLESS_LINK="vless://${UUID}@${HOST_DOMAIN}:443?path=%2Ftg-%40nkka404&security=tls&alpn=h3%2Ch2%2Chttp%2F1.1&encryption=none&host=${DOMAIN}&fp=randomized&type=ws&sni=${DOMAIN}#${SERVICE_NAME}"

  MESSAGE="*GCP V2Ray Deployment → Successful ✅* ━━━━━━━━━━━━━━━━━━━━
• *Project:* \`${PROJECT_ID}\`
• *Service:* \`${SERVICE_NAME}\`
• *Region:* \`${REGION}\`
• *Resources:* \`${CPU} CPU | ${MEMORY} RAM\`
• *Domain:* \`${DOMAIN}\`

🔗 *V2Ray Configuration Link:*
\`\`\`
${VLESS_LINK}
\`\`\`
━━━━━━━━━━━━━━━━━━━"

  CONSOLE_MESSAGE="GCP V2Ray Deployment → Successful ✅
• Project: ${PROJECT_ID}
• Service: ${SERVICE_NAME}
• Region: ${REGION}
• Resources: ${CPU} CPU | ${MEMORY} RAM
• Domain: ${DOMAIN}

V2Ray Configuration Link:
${VLESS_LINK}

Usage: Copy the above link and import to your V2Ray client."

  echo "$CONSOLE_MESSAGE" > deployment-info.txt
  log "Deployment info saved to deployment-info.txt"

  echo
  info "=== Deployment Information ==="
  echo "$CONSOLE_MESSAGE"
  echo

  if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
    log "Sending deployment info to Telegram..."
    send_deployment_notification "$MESSAGE"
  else
    log "Skipping Telegram notification as per user selection"
  fi

  log "Deployment completed successfully!"
  log "Service URL: $SERVICE_URL"
  log "Configuration saved to: deployment-info.txt"
}

# ----------------------------
# Run
# ----------------------------
main "$@"
