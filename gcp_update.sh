#!/bin/bash
set -euo pipefail

# -----------------------
# Color definitions
# -----------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Small helpers for colored logging
log()    { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; }
info()   { echo -e "${BLUE}[INFO]${NC} $1"; }

# -----------------------
# Fancy boxed section printer (with border & padding)
# -----------------------
print_section() {
  # $1 = section title
  local title="$1"
  local term_width=72
  local padding=2
  # Trim and ensure title isn't longer than available width
  local clean_title="${title}"
  local avail=$((term_width - (padding * 2) - 2)) # 2 for side borders
  if (( ${#clean_title} > avail )); then
    clean_title="${clean_title:0:avail-3}..."
  fi
  # Build line content centered
  local space_each=$(( (avail - ${#clean_title}) / 2 ))
  local left_pad=$(printf '%*s' $space_each '')
  local right_pad_len=$(( avail - ${#clean_title} - space_each ))
  local right_pad=$(printf '%*s' $right_pad_len '')
  # Top border
  echo -e "${CYAN}╔$(printf '═%.0s' $(seq 1 $term_width))╗${NC}"
  # Empty padding line (top)
  for i in $(seq 1 $padding); do
    echo -e "${CYAN}║${NC}$(printf ' %.0s' $(seq 1 $term_width))${CYAN}║${NC}"
  done
  # Title line
  echo -e "${CYAN}║${NC} ${WHITE}${BOLD}${left_pad}${clean_title}${right_pad}${NC} ${CYAN}║${NC}"
  # Empty padding line (bottom)
  for i in $(seq 1 $padding); do
    echo -e "${CYAN}║${NC}$(printf ' %.0s' $(seq 1 $term_width))${CYAN}║${NC}"
  done
  # Bottom border
  echo -e "${CYAN}╚$(printf '═%.0s' $(seq 1 $term_width))╝${NC}"
  echo
}

# -----------------------
# Colored ASCII Banner
# -----------------------
print_banner() {
  # Banner uses mix of GREEN (left), BLUE (right) and WHITE for highlight
  echo -e "${GREEN} ___           ___     ${NC}${BLUE}        ____  _                       ${NC}"
  echo -e "${GREEN}    ___         /\\  \\         /\\__\\    ${NC}${BLUE}       / __ \\(_)___  ____ _____ ___ ${NC}"
  echo -e "${GREEN}   /\\__\\        \\:\\  \\       /:/ _/_   ${NC}${WHITE}      / / / / / __ \\/ __ \`/ __ \`/ _ \\${NC}"
  echo -e "${GREEN}  /:/__/         \\:\\  \\     /:/ /\\__\\  ${NC}${WHITE}     / /_/ / / / / / /_/ / /_/ /  __/${NC}"
  echo -e "${GREEN} /::\\  \\     ___  \\:\\  \\   /:/ /:/ _/_ ${NC}${BLUE}     \\____/_/_/ /_/\\__,_/\\__, /\\___/ ${NC}"
  echo -e "${GREEN} \\/\\:\\  \\   /\\  \\  \\:\\__\\ /:/_/:/ /\\__\\ ${NC}${BLUE}                       /____/      ${NC}"
  echo -e "${YELLOW}  ~~\\:\\  \\  \\:\\  \\ /:/  / \\:\/:/ /:/  / ${NC}"
  echo -e "${YELLOW}     \\:\\__\\  \\:\\  /:/  /   \\::/_/:/  /  ${NC}"
  echo -e "${YELLOW}     /:/  /   \\:\\/:/  /     \\:\\/:/  /   ${NC}"
  echo -e "${YELLOW}    /:/  /     \\::/  /       \\::/  /    ${NC}"
  echo -e "${YELLOW}    \\/__/       \\/__/         \\/__/     ${NC}"
  echo
  # Script by line
  echo -e "${MAGENTA}${BOLD}Script By : JueHtet${NC}"
  echo
}

# -----------------------
# Validation helpers (kept from original, slightly cleaned)
# -----------------------
validate_uuid() {
  local uuid_pattern='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  if [[ ! $1 =~ $uuid_pattern ]]; then error "Invalid UUID format: $1"; return 1; fi
  return 0
}

validate_bot_token() {
  local token_pattern='^[0-9]{8,10}:[a-zA-Z0-9_-]{35}$'
  if [[ ! $1 =~ $token_pattern ]]; then error "Invalid Telegram Bot Token format"; return 1; fi
  return 0
}

validate_channel_id() {
  if [[ ! $1 =~ ^-?[0-9]+$ ]]; then error "Invalid Channel ID format"; return 1; fi
  return 0
}

validate_chat_id() {
  if [[ ! $1 =~ ^-?[0-9]+$ ]]; then error "Invalid Chat ID format"; return 1; fi
  return 0
}

# -----------------------
# CPU selection
# -----------------------
select_cpu() {
  print_section "CPU Configuration"
  echo -e "${WHITE}1.${NC} 1 CPU Core (Default)"
  echo -e "${WHITE}2.${NC} 2 CPU Cores"
  echo -e "${WHITE}3.${NC} 4 CPU Cores"
  echo -e "${WHITE}4.${NC} 8 CPU Cores"
  while true; do
    read -p "$(echo -e ${CYAN}Select CPU cores (1-4):${NC} )" cpu_choice
    case $cpu_choice in
      1) CPU="1"; break ;;
      2) CPU="2"; break ;;
      3) CPU="4"; break ;;
      4) CPU="8"; break ;;
      *) echo -e "${YELLOW}Invalid selection. Please enter a number between 1-4.${NC}" ;;
    esac
  done
  info "Selected CPU: $CPU core(s)"
}

# -----------------------
# Memory selection & validation
# -----------------------
select_memory() {
  print_section "Memory Configuration"
  case $CPU in
    1) echo -e "${WHITE}Recommended memory:${NC} 512Mi - 2Gi" ;;
    2) echo -e "${WHITE}Recommended memory:${NC} 1Gi - 4Gi" ;;
    4) echo -e "${WHITE}Recommended memory:${NC} 2Gi - 8Gi" ;;
    8) echo -e "${WHITE}Recommended memory:${NC} 4Gi - 16Gi" ;;
  esac
  echo
  echo -e "${WHITE}Memory Options:${NC}"
  echo -e "${WHITE}1.${NC} 512Mi"
  echo -e "${WHITE}2.${NC} 1Gi"
  echo -e "${WHITE}3.${NC} 2Gi"
  echo -e "${WHITE}4.${NC} 4Gi"
  echo -e "${WHITE}5.${NC} 8Gi"
  echo -e "${WHITE}6.${NC} 16Gi"
  while true; do
    read -p "$(echo -e ${CYAN}Select memory (1-6):${NC} )" memory_choice
    case $memory_choice in
      1) MEMORY="512Mi"; break ;;
      2) MEMORY="1Gi"; break ;;
      3) MEMORY="2Gi"; break ;;
      4) MEMORY="4Gi"; break ;;
      5) MEMORY="8Gi"; break ;;
      6) MEMORY="16Gi"; break ;;
      *) echo -e "${YELLOW}Invalid selection. Please enter a number between 1-6.${NC}" ;;
    esac
  done
  validate_memory_config
  info "Selected Memory: $MEMORY"
}

validate_memory_config() {
  local cpu_num=$CPU
  local memory_num=$(echo $MEMORY | sed 's/[^0-9]*//g')
  local memory_unit=$(echo $MEMORY | sed 's/[0-9]*//g')
  if [[ "$memory_unit" == "Gi" ]]; then memory_num=$((memory_num * 1024)); fi

  local min_memory=0
  local max_memory=0
  case $cpu_num in
    1) min_memory=512; max_memory=2048 ;;
    2) min_memory=1024; max_memory=4096 ;;
    4) min_memory=2048; max_memory=8192 ;;
    8) min_memory=4096; max_memory=16384 ;;
  esac

  if [[ $memory_num -lt $min_memory ]]; then
    warn "Memory configuration ($MEMORY) might be too low for $CPU CPU core(s)."
    warn "Recommended minimum: $((min_memory / 1024))Gi"
    read -p "Do you want to continue with this configuration? (y/n): " confirm
    if [[ ! $confirm =~ [Yy] ]]; then select_memory; fi
  elif [[ $memory_num -gt $max_memory ]]; then
    warn "Memory configuration ($MEMORY) might be too high for $CPU CPU core(s)."
    warn "Recommended maximum: $((max_memory / 1024))Gi"
    read -p "Do you want to continue with this configuration? (y/n): " confirm
    if [[ ! $confirm =~ [Yy] ]]; then select_memory; fi
  fi
}

# -----------------------
# Region selection (with flags)
# -----------------------
select_region() {
  print_section "Region Selection"
  echo -e "${WHITE}1.${NC} us-central1 (Iowa, USA) ${GREEN}🇺🇸${NC}"
  echo -e "${WHITE}2.${NC} us-west1 (Oregon, USA) ${GREEN}🇺🇸${NC}"
  echo -e "${WHITE}3.${NC} us-east1 (South Carolina, USA) ${GREEN}🇺🇸${NC}"
  echo -e "${WHITE}4.${NC} europe-west1 (Belgium) ${BLUE}🇧🇪${NC}"
  echo -e "${WHITE}5.${NC} asia-southeast1 (Singapore) ${CYAN}🇸🇬${NC}"
  echo -e "${WHITE}6.${NC} asia-northeast1 (Tokyo, Japan) ${CYAN}🇯🇵${NC}"
  echo -e "${WHITE}7.${NC} asia-east1 (Taiwan) ${CYAN}🇹🇼${NC}"
  while true; do
    read -p "$(echo -e ${CYAN}Select region (1-7):${NC} )" region_choice
    case $region_choice in
      1) REGION="us-central1"; break ;;
      2) REGION="us-west1"; break ;;
      3) REGION="us-east1"; break ;;
      4) REGION="europe-west1"; break ;;
      5) REGION="asia-southeast1"; break ;;
      6) REGION="asia-northeast1"; break ;;
      7) REGION="asia-east1"; break ;;
      *) echo -e "${YELLOW}Invalid selection. Please enter a number between 1-7.${NC}" ;;
    esac
  done
  info "Selected region: $REGION"
}

# -----------------------
# Telegram destination selection
# -----------------------
select_telegram_destination() {
  print_section "Telegram Destination"
  echo -e "${WHITE}1.${NC} Send to Channel only"
  echo -e "${WHITE}2.${NC} Send to Bot private message only"
  echo -e "${WHITE}3.${NC} Send to both Channel and Bot"
  echo -e "${WHITE}4.${NC} Don't send to Telegram"
  while true; do
    read -p "$(echo -e ${CYAN}Select destination (1-4):${NC} )" telegram_choice
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
        echo -e "${YELLOW}Invalid selection. Please enter a number between 1-4.${NC}"
        ;;
    esac
  done
}

# -----------------------
# User input: service name, UUID, bot token, host domain
# -----------------------
get_user_input() {
  print_section "Service Configuration"
  # Service Name
  while true; do
    read -p "Enter service name: " SERVICE_NAME
    if [[ -n "$SERVICE_NAME" ]]; then break; else error "Service name cannot be empty"; fi
  done

  # UUID (default provided if blank)
  while true; do
    read -p "Enter UUID [default: ba0e3984-ccc9-48a3-8074-b2f507f41ce8]: " UUID
    UUID=${UUID:-"ba0e3984-ccc9-48a3-8074-b2f507f41ce8"}
    if validate_uuid "$UUID"; then break; fi
  done

  # Telegram Bot Token (if needed)
  if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
    while true; do
      read -p "Enter Telegram Bot Token: " TELEGRAM_BOT_TOKEN
      if validate_bot_token "$TELEGRAM_BOT_TOKEN"; then break; fi
    done
  fi

  # Host Domain (optional)
  read -p "Enter host domain [default: m.googleapis.com]: " HOST_DOMAIN
  HOST_DOMAIN=${HOST_DOMAIN:-"m.googleapis.com"}
}

# -----------------------
# Show summary
# -----------------------
show_config_summary() {
  print_section "Configuration Summary"
  local PROJECT_ID
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "(no project)")
  echo -e "${WHITE}Project ID:${NC} ${PROJECT_ID}"
  echo -e "${WHITE}Region:${NC} ${REGION}"
  echo -e "${WHITE}Service Name:${NC} ${SERVICE_NAME}"
  echo -e "${WHITE}Host Domain:${NC} ${HOST_DOMAIN}"
  echo -e "${WHITE}UUID:${NC} ${UUID}"
  echo -e "${WHITE}CPU:${NC} ${CPU} core(s)"
  echo -e "${WHITE}Memory:${NC} ${MEMORY}"
  if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
    echo -e "${WHITE}Bot Token:${NC} ${TELEGRAM_BOT_TOKEN:0:8}..."
    echo -e "${WHITE}Destination:${NC} ${TELEGRAM_DESTINATION}"
    if [[ "$TELEGRAM_DESTINATION" == "channel" || "$TELEGRAM_DESTINATION" == "both" ]]; then
      echo -e "${WHITE}Channel ID:${NC} ${TELEGRAM_CHANNEL_ID}"
    fi
    if [[ "$TELEGRAM_DESTINATION" == "bot" || "$TELEGRAM_DESTINATION" == "both" ]]; then
      echo -e "${WHITE}Chat ID:${NC} ${TELEGRAM_CHAT_ID}"
    fi
  else
    echo -e "${WHITE}Telegram:${NC} Not configured"
  fi
  while true; do
    read -p "$(echo -e ${CYAN}Proceed with deployment? (y/n):${NC} )" confirm
    case $confirm in
      [Yy]* ) break;;
      [Nn]* ) info "Deployment cancelled by user"; exit 0 ;;
      * ) echo "Please answer yes (y) or no (n).";;
    esac
  done
}

# -----------------------
# Prerequisite validation (kept original)
# -----------------------
validate_prerequisites() {
  log "Validating prerequisites..."
  if ! command -v gcloud &> /dev/null; then
    error "gcloud CLI is not installed. Please install Google Cloud SDK."
    exit 1
  fi
  if ! command -v git &> /dev/null; then
    error "git is not installed. Please install git."
    exit 1
  fi
  local PROJECT_ID
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
  if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
    error "No project configured. Run: gcloud config set project PROJECT_ID"
    exit 1
  fi
}

cleanup() {
  log "Cleaning up temporary files..."
  if [[ -d "gcp-v2ray" ]]; then rm -rf gcp-v2ray; fi
}

# -----------------------
# Telegram send helpers (kept original)
# -----------------------
send_to_telegram() {
  local chat_id="$1"
  local message="$2"
  local response
  response=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "{ \"chat_id\": \"${chat_id}\", \"text\": \"$message\", \"parse_mode\": \"MARKDOWN\", \"disable_web_page_preview\": true }" \
    https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage)
  local http_code="${response: -3}"
  local content="${response%???}"
  if [[ "$http_code" == "200" ]]; then return 0; else error "Failed to send to Telegram (HTTP $http_code): $content"; return 1; fi
}

send_deployment_notification() {
  local message="$1"
  local success_count=0
  case $TELEGRAM_DESTINATION in
    "channel")
      log "Sending to Telegram Channel..."
      if send_to_telegram "$TELEGRAM_CHANNEL_ID" "$message"; then
        log "✅ Successfully sent to Telegram Channel"
        success_count=$((success_count + 1))
      else
        error "❌ Failed to send to Telegram Channel"
      fi
      ;;
    "bot")
      log "Sending to Bot private message..."
      if send_to_telegram "$TELEGRAM_CHAT_ID" "$message"; then
        log "✅ Successfully sent to Bot private message"
        success_count=$((success_count + 1))
      else
        error "❌ Failed to send to Bot private message"
      fi
      ;;
    "both")
      log "Sending to both Channel and Bot..."
      if send_to_telegram "$TELEGRAM_CHANNEL_ID" "$message"; then
        log "✅ Successfully sent to Telegram Channel"
        success_count=$((success_count + 1))
      else
        error "❌ Failed to send to Telegram Channel"
      fi
      if send_to_telegram "$TELEGRAM_CHAT_ID" "$message"; then
        log "✅ Successfully sent to Bot private message"
        success_count=$((success_count + 1))
      else
        error "❌ Failed to send to Bot private message"
      fi
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

# -----------------------
# Main deployment flow (kept original logic, with banner + boxed sections)
# -----------------------
main() {
  info "=== GCP Cloud Run V2Ray Deployment ==="
  print_banner

  # Interact with user
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

  # Ensure cleanup on exit
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
  if ! gcloud run deploy ${SERVICE_NAME} \
    --image gcr.io/${PROJECT_ID}/gcp-v2ray-image \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    --cpu ${CPU} \
    --memory ${MEMORY} \
    --quiet; then
    error "Deployment failed"
    exit 1
  fi

  # Get the service URL
  SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --region ${REGION} \
    --format 'value(status.url)' \
    --quiet)
  DOMAIN=$(echo $SERVICE_URL | sed 's|https://||')

  # Create Vless share link
  VLESS_LINK="vless://${UUID}@${HOST_DOMAIN}:443?path=%2Ftg-%40nkka404&security=tls&alpn=h3%2Ch2%2Chttp%2F1.1&encryption=none&host=${DOMAIN}&fp=randomized&type=ws&sni=${DOMAIN}#${SERVICE_NAME}"

  # Create telegram message
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
━━━━━━━━━━━━━━━━━━━━"

  CONSOLE_MESSAGE="GCP V2Ray Deployment → Successful ✅
━━━━━━━━━━━━━━━━━━━━
• Project: ${PROJECT_ID}
• Service: ${SERVICE_NAME}
• Region: ${REGION}
• Resources: ${CPU} CPU | ${MEMORY} RAM
• Domain: ${DOMAIN}
🔗 V2Ray Configuration Link:
${VLESS_LINK}
━━━━━━━━━━━━━━━━━━━━
Usage: Copy the above link and import to your V2Ray client."

  # Save to file
  echo "$CONSOLE_MESSAGE" > deployment-info.txt
  log "Deployment info saved to deployment-info.txt"

  # Display locally
  print_section "Deployment Information"
  echo "$CONSOLE_MESSAGE"
  echo

  # Send to Telegram if configured
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

# -----------------------
# Run main
# -----------------------
main "$@"
