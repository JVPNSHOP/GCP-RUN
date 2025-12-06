#!/bin/bash
set -euo pipefail

# =============================
# Clean UI w/ 256-color accents
# - Banner: no flags
# - Region selection: flags included (only here)
# - No filled yellow backgrounds; colored borders and accents instead
# =============================

# 256-color foreground codes
C_YELLOW=$'\e[38;5;226m'
C_GREEN=$'\e[38;5;46m'
C_CYAN=$'\e[38;5;51m'
C_PURPLE=$'\e[38;5;141m'
C_GRAY=$'\e[38;5;245m'
C_WHITE=$'\e[97m'
BOLD=$'\e[1m'
RESET=$'\e[0m'

# Logging helpers (white body)
log(){ printf "%b[%s]%b %b%s%b\n" "$C_GREEN" "$(date +'%Y-%m-%d %H:%M:%S')" "$RESET" "$C_WHITE" "$1" "$RESET"; }
warn(){ printf "%b[WARN]%b %b%s%b\n" "$C_YELLOW" "$RESET" "$C_WHITE" "$1" "$RESET"; }
error(){ printf "%b[ERR]%b %b%s%b\n" "$C_YELLOW" "$RESET" "$C_WHITE" "$1" "$RESET"; }
info(){ printf "%b[INFO]%b %b%s%b\n" "$C_CYAN" "$RESET" "$C_WHITE" "$1" "$RESET"; }

# -----------------------------
# Nice border header (no filled bg)
# -----------------------------
show_box_header(){
  local title="$1"
  local subtitle="$2"
  local width=66

  printf "%b┌%0.s─" "$C_YELLOW" $(seq 1 $width)
  printf "┐%b\n" "$RESET"

  printf "%b│ %b%s %b" "$C_YELLOW" "$BOLD" "$title" "$RESET"
  local pad=$((width - ${#title} - 1))
  printf "%${pad}s" ""
  printf "%b│%b\n" "$C_YELLOW" "$RESET"

  if [[ -n "$subtitle" ]]; then
    printf "%b│ %b%s %b" "$C_YELLOW" "$C_WHITE" "$subtitle" "$RESET"
    local pad2=$((width - ${#subtitle} - 1))
    printf "%${pad2}s" ""
    printf "%b│%b\n" "$C_YELLOW" "$RESET"
  fi

  printf "%b└%0.s─" "$C_YELLOW" $(seq 1 $width)
  printf "┘%b\n\n" "$RESET"
}

# -----------------------------
# ASCII banner (3-color cycle, no flags here)
# -----------------------------
show_banner(){
  show_box_header "VLESS WS DEPLOYMENT SYSTEM" "VERSION - 2.0  •  Powered by JUE HTET"

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

  local i=0
  for ln in "${lines[@]}"; do
    case $((i % 3)) in
      0) col="$C_GREEN" ;;
      1) col="$C_YELLOW" ;;
      2) col="$C_CYAN" ;;
    esac
    printf "%b│ %b%s%b%*s %b│%b\n" "$C_GRAY" "$col" "$ln" "$RESET" $((48 - ${#ln})) "" "$C_GRAY" "$RESET"
    i=$((i+1))
  done

  printf "%b│%*s │%b\n\n" "$C_GRAY" 56 "" "$RESET"
}

# -----------------------------
# Boxed step
# -----------------------------
show_step(){
  local step="$1"
  local title="$2"
  show_box_header "STEP $step" "$title"
}

# -----------------------------
# Region selection: flags included HERE only
# -----------------------------
select_region(){
  show_step "01" "Region Selection (flags shown here)"

  # region entries: flag|label|code|color
  regions=(
"🇸🇬|Singapore|asia-southeast1|$C_GREEN"
"🇺🇸|United States|us-central1|$C_CYAN"
"🇮🇩|Indonesia|asia-southeast2|$C_YELLOW"
"🇯🇵|Japan|asia-northeast1|$C_PURPLE"
"🇧🇪|Belgium|europe-west1|$C_YELLOW"
"🇮🇳|India|asia-south1|$C_GREEN"
"🇹🇼|Taiwan|asia-east1|$C_CYAN"
  )

  local idx=1
  for entry in "${regions[@]}"; do
    IFS='|' read -r flag name code col <<< "$entry"
    # build content
    local content=" ${flag} ${name} (${code}) "
    # colored top border
    printf "%b┌%0.s─" "$col" $(seq 1 ${#content})
    printf "┐%b" "$RESET"
    printf " "
    # white content
    printf "%b%s%b" "$C_WHITE" "$content" "$RESET"
    printf " "
    # colored bottom border
    printf "%b└%0.s─" "$col" $(seq 1 ${#content})
    printf "┘%b" "$RESET"
    if (( idx % 2 == 0 )); then
      printf "\n\n"
    else
      printf "   "
    fi
    idx=$((idx+1))
  done

  printf "\n"

  echo -e "${C_WHITE}Choose region by number:${RESET}"
  echo -e "${C_WHITE} 1) asia-southeast1   2) us-central1   3) asia-southeast2${RESET}"
  echo -e "${C_WHITE} 4) asia-northeast1   5) europe-west1  6) asia-south1   7) asia-east1${RESET}"
  while true; do
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
      *) echo -e "${C_YELLOW}Enter 1-7${RESET}";;
    esac
  done

  printf "%bSelected region:%b %b%s%b\n\n" "$C_GRAY" "$RESET" "$C_GREEN" "$REGION" "$RESET"
}

# -----------------------------
# CPU & Memory selection
# -----------------------------
select_cpu(){
  show_step "02" "CPU Configuration"
  echo -e "${C_WHITE}1) 1 CPU  2) 2 CPU  3) 4 CPU  4) 8 CPU${RESET}"
  while true; do
    read -p "Select CPU (1-4) [2]: " cpu_choice
    cpu_choice=${cpu_choice:-2}
    case $cpu_choice in
      1) CPU="1"; break ;;
      2) CPU="2"; break ;;
      3) CPU="4"; break ;;
      4) CPU="8"; break ;;
      *) echo -e "${C_YELLOW}Enter 1-4${RESET}";;
    esac
  done
  printf "%bSelected CPU:%b %b%s%b\n\n" "$C_GRAY" "$RESET" "$C_GREEN" "$CPU" "$RESET"
}

select_memory(){
  show_step "03" "Memory Configuration"
  echo -e "${C_WHITE}Options: 1)512Mi 2)1Gi 3)2Gi 4)4Gi 5)8Gi 6)16Gi${RESET}"
  while true; do
    read -p "Select memory (1-6) [3]: " mem_choice
    mem_choice=${mem_choice:-3}
    case $mem_choice in
      1) MEMORY="512Mi"; break ;;
      2) MEMORY="1Gi"; break ;;
      3) MEMORY="2Gi"; break ;;
      4) MEMORY="4Gi"; break ;;
      5) MEMORY="8Gi"; break ;;
      6) MEMORY="16Gi"; break ;;
      *) echo -e "${C_YELLOW}Enter 1-6${RESET}";;
    esac
  done
  printf "%bSelected Memory:%b %b%s%b\n\n" "$C_GRAY" "$RESET" "$C_GREEN" "$MEMORY" "$RESET"
}

# -----------------------------
# Telegram selection & inputs
# -----------------------------
select_telegram_destination(){
  show_step "04" "Telegram Destination"
  echo -e "${C_WHITE}1) Channel only  2) Bot only  3) Both  4) None${RESET}"
  while true; do
    read -p "Select (1-4) [1]: " tchoice
    tchoice=${tchoice:-1}
    case $tchoice in
      1) TELEGRAM_DESTINATION="channel"
         read -p "Telegram Channel ID: " TELEGRAM_CHANNEL_ID
         break;;
      2) TELEGRAM_DESTINATION="bot"
         read -p "Telegram Chat ID: " TELEGRAM_CHAT_ID
         break;;
      3) TELEGRAM_DESTINATION="both"
         read -p "Telegram Channel ID: " TELEGRAM_CHANNEL_ID
         read -p "Telegram Chat ID: " TELEGRAM_CHAT_ID
         break;;
      4) TELEGRAM_DESTINATION="none"; break;;
      *) echo -e "${C_YELLOW}Enter 1-4${RESET}";;
    esac
  done
  printf "%bTelegram destination:%b %b%s%b\n\n" "$C_GRAY" "$RESET" "$C_GREEN" "$TELEGRAM_DESTINATION" "$RESET"
}

# -----------------------------
# Other inputs
# -----------------------------
get_user_input(){
  show_step "05" "Service Configuration"
  read -p "Service name [jue-vless]: " SERVICE_NAME
  SERVICE_NAME=${SERVICE_NAME:-jue-vless}
  read -p "UUID [press enter to use default]: " UUID
  UUID=${UUID:-ba0e3984-ccc9-48a3-8074-b2f507f41ce8}
  if [[ "$TELEGRAM_DESTINATION" != "none" ]]; then
    read -p "Telegram Bot Token: " TELEGRAM_BOT_TOKEN
  fi
  read -p "Host domain [m.googleapis.com]: " HOST_DOMAIN
  HOST_DOMAIN=${HOST_DOMAIN:-m.googleapis.com}
}

# -----------------------------
# Summary & confirm
# -----------------------------
show_config_summary(){
  show_step "06" "Configuration Summary"
  echo -e "${C_WHITE}Project: $(gcloud config get-value project)${RESET}"
  echo -e "${C_WHITE}Region: ${C_GREEN}$REGION${RESET}"
  echo -e "${C_WHITE}Service: ${C_GREEN}$SERVICE_NAME${RESET}"
  echo -e "${C_WHITE}UUID: ${C_GREEN}$UUID${RESET}"
  echo -e "${C_WHITE}CPU: ${C_GREEN}$CPU${RESET}   Memory: ${C_GREEN}$MEMORY${RESET}"
  echo -e "${C_WHITE}Host: ${C_GREEN}$HOST_DOMAIN${RESET}"
  echo
  read -p "Proceed with deployment? (y/n) [y]: " ok
  ok=${ok:-y}
  if [[ ! "$ok" =~ ^[Yy]$ ]]; then echo -e "${C_YELLOW}Cancelled${RESET}"; exit 0; fi
}

# -----------------------------
# Minimal helpers (deployment & telegram)
# -----------------------------
LOG_FILE="/tmp/jue_vless_$(date +%s).log"
touch "$LOG_FILE"

validate_prerequisites(){
  log "Validating prerequisites..."
  if ! command -v gcloud &>/dev/null; then error "gcloud CLI missing"; exit 1; fi
  if ! command -v git &>/dev/null; then error "git missing"; exit 1; fi
  local PROJECT_ID
  PROJECT_ID=$(gcloud config get-value project)
  if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then error "gcloud project not set"; exit 1; fi
}

cleanup(){ [[ -d gcp-v2ray ]] && rm -rf gcp-v2ray; }

send_to_telegram(){
  local chat_id="$1"; local message="$2"
  local payload; payload=$(printf '{"chat_id":"%s","text":"%s","parse_mode":"Markdown"}' "$chat_id" "$message")
  curl -s -X POST -H "Content-Type: application/json" -d "$payload" "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" >/dev/null 2>&1
}

# -----------------------------
# Main flow (keeps original deploy steps)
# -----------------------------
main(){
  show_banner
  select_region
  select_cpu
  select_memory
  select_telegram_destination
  get_user_input
  show_config_summary

  validate_prerequisites
  trap cleanup EXIT

  log "Enabling required APIs..."
  gcloud services enable cloudbuild.googleapis.com run.googleapis.com iam.googleapis.com --quiet

  log "Cloning repository..."
  git clone https://github.com/nyeinkokoaung404/gcp-v2ray.git || { echo -e "${C_YELLOW}git clone failed${RESET}"; exit 1; }
  cd gcp-v2ray || exit 1

  log "Building container image..."
  gcloud builds submit --tag gcr.io/$(gcloud config get-value project)/gcp-v2ray-image --quiet

  log "Deploying to Cloud Run..."
  gcloud run deploy "${SERVICE_NAME}" --image "gcr.io/$(gcloud config get-value project)/gcp-v2ray-image" --platform managed --region "${REGION}" --allow-unauthenticated --cpu "${CPU}" --memory "${MEMORY}" --quiet

  SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" --region "${REGION}" --format 'value(status.url)' --quiet)
  DOMAIN=${SERVICE_URL#https://}

  VLESS_LINK="vless://${UUID}@${HOST_DOMAIN}:443?path=%2Ftg-%40nkka404&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${SERVICE_NAME}"

  MESSAGE="GCP V2Ray Deployment Success
Project: $(gcloud config get-value project)
Service: ${SERVICE_NAME}
Region: ${REGION}
Resources: ${CPU} CPU | ${MEMORY}
Domain: ${DOMAIN}

Link:
${VLESS_LINK}"

  echo "$MESSAGE" > deployment-info.txt
  log "Saved deployment-info.txt"

  if [[ "$TELEGRAM_DESTINATION" == "channel" ]]; then send_to_telegram "$TELEGRAM_CHANNEL_ID" "$MESSAGE"; fi
  if [[ "$TELEGRAM_DESTINATION" == "bot" ]]; then send_to_telegram "$TELEGRAM_CHAT_ID" "$MESSAGE"; fi
  if [[ "$TELEGRAM_DESTINATION" == "both" ]]; then send_to_telegram "$TELEGRAM_CHANNEL_ID" "$MESSAGE"; send_to_telegram "$TELEGRAM_CHAT_ID" "$MESSAGE"; fi

  log "Deployment completed. Service URL: ${SERVICE_URL}"
}

main "$@"
