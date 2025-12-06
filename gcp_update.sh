#!/usr/bin/env bash
set -euo pipefail

# ===== Ensure interactive reads even when run via curl/process substitution =====
if [[ ! -t 0 ]] && [[ -e /dev/tty ]]; then
  exec </dev/tty
fi

# ===== Logging & error handler =====
LOG_FILE="/tmp/jue_vless_$(date +%s).log"
touch "$LOG_FILE"

on_err() {
  local rc=$?
  echo "" | tee -a "$LOG_FILE"
  echo "❌ ERROR: Command failed (exit $rc) at line $LINENO: ${BASH_COMMAND}" | tee -a "$LOG_FILE" >&2
  echo "—— LOG (last 80 lines) ——" >&2
  tail -n 80 "$LOG_FILE" >&2 || true
  echo "📄 Log File: $LOG_FILE" >&2
  exit $rc
}
trap on_err ERR

# =================== JUE Custom UI (colors preserved) ===================
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RESET=$'\e[0m'; BOLD=$'\e[1m'
  C_JUE_RED=$'\e[38;5;196m'      # Bright Red
  C_JUE_BLUE=$'\e[38;5;39m'      # Bright Blue
  C_JUE_GREEN=$'\e[38;5;46m'     # Bright Green
  C_JUE_YELLOW=$'\e[38;5;226m'   # Bright Yellow
  C_JUE_PURPLE=$'\e[38;5;93m'    # Purple
  C_JUE_GRAY=$'\e[38;5;245m'     # Gray
  C_JUE_CYAN=$'\e[38;5;51m'      # Cyan
  # Three-color banner palette
  B1=$'\e[38;5;46m'   # green
  B2=$'\e[38;5;226m'  # yellow
  B3=$'\e[38;5;51m'   # cyan
else
  RESET= BOLD= C_JUE_RED= C_JUE_BLUE= C_JUE_GREEN= C_JUE_YELLOW= C_JUE_PURPLE= C_JUE_GRAY= C_JUE_CYAN= B1= B2= B3=
fi

# =================== JUE Banner ===================
show_JUE_banner() {
  clear
  printf "\n\n"
  printf "${C_JUE_RED}${BOLD}"
  printf "╔══════════════════════════════════════════════════════════════════╗\n"
  printf "║                                                                 ${C_JUE_RED}\n"
  local lines=(
"___           ___     "
"    ___         /\\  \\         /\\__\\    "
"   /\\__\\        \\:\\  \\       /:/ _/_   "
"  /:/__/         \\:\\  \\     /:/ /\\__\\  "
" /::\\  \\     ___  \\:\\  \\   /:/ /:/ _/_ "
" \\/\\:\\  \\   /\\  \\  \\:\\__\\ /:/_/:/ /\\__\\"
"  ~~\\:\\  \\  \\:\\  \\ /:/  / \\:\\/:/ /:/  /"
"     \\:\\__\\  \\:\\  /:/  /   \\::/_/:/  / "
"     /:/  /   \\:\\/:/  /     \\:\\/:/  /  "
"    /:/  /     \\::/  /       \\::/  /   "
"    \\/__/       \\/__/         \\/__/    "
  )
  local i=0
  for ln in "${lines[@]}"; do
    case $((i % 3)) in
      0) color="$B1" ;;
      1) color="$B2" ;;
      2) color="$B3" ;;
    esac
    printf "║    ${color}%s${C_JUE_RED}\n" "$ln"
    i=$((i+1))
  done

  printf "%b" "${C_JUE_RED}"
  printf "║                                                                                               ${C_JUE_RED}\n"
  printf "║         ${C_JUE_YELLOW}🚀 VLESS WS DEPLOYMENT SYSTEM => VERSION - 2.0                         ${C_JUE_RED}\n"
  printf "║         ${C_JUE_GREEN}⚡ Powered by JUE HTET                                             ${C_JUE_RED}\n"
  printf "║                                                                                               ${C_JUE_RED}\n"
  printf "╚══════════════════════════════════════════════════════════════════╝${RESET}\n"
  printf "\n\n"
}

# =================== Custom UI Functions ===================
show_step() { local step_num="$1" ; local step_title="$2"
  printf "\n${C_JUE_PURPLE}${BOLD}┌─── STEP %s ──────────────────────────────────────────┐${RESET}\n" "$step_num"
  printf "${C_JUE_PURPLE}${BOLD}│${RESET} ${C_JUE_CYAN}%s${RESET}\n" "$step_title"
  printf "${C_JUE_PURPLE}${BOLD}└──────────────────────────────────────────────────────┘${RESET}\n"
}
show_success() { printf "${C_JUE_GREEN}${BOLD}✓${RESET} ${C_JUE_GREEN}%s${RESET}\n" "$1"; }
show_info()    { printf "${C_JUE_BLUE}${BOLD}ℹ${RESET} ${C_JUE_BLUE}%s${RESET}\n" "$1"; }
show_warning() { printf "${C_JUE_YELLOW}${BOLD}⚠${RESET} ${C_JUE_YELLOW}%s${RESET}\n" "$1"; }
show_error()   { printf "${C_JUE_RED}${BOLD}✗${RESET} ${C_JUE_RED}%s${RESET}\n" "$1"; }
show_divider() { printf "${C_JUE_GRAY}%s${RESET}\n" "──────────────────────────────────────────────────────────"; }
show_kv()      { printf "   ${C_JUE_GRAY}%s${RESET}  ${C_JUE_CYAN}%s${RESET}\n" "$1" "$2"; }

# =================== Progress Spinner ===================
run_with_progress() {
  local label="$1"; shift
  ( "$@" ) >>"$LOG_FILE" 2>&1 &
  local pid=$!
  local pct=5
  if [[ -t 1 ]]; then
    printf "\e[?25l"
    while kill -0 "$pid" 2>/dev/null; do
      local step=$(( (RANDOM % 9) + 2 ))
      pct=$(( pct + step ))
      (( pct > 95 )) && pct=95
      printf "\r${C_JUE_PURPLE}⟳${RESET} ${C_JUE_CYAN}%s...${RESET} [${C_JUE_YELLOW}%s%%${RESET}]" "$label" "$pct"
      sleep "$(awk -v r=$RANDOM 'BEGIN{s=0.08+(r%7)/100; printf "%.2f", s }')"
    done
    wait "$pid"; local rc=$?
    printf "\r"
    if (( rc==0 )); then
      printf "${C_JUE_GREEN}✓${RESET} ${C_JUE_GREEN}%s...${RESET} [${C_JUE_GREEN}100%%${RESET}]\n" "$label"
    else
      printf "${C_JUE_RED}✗${RESET} ${C_JUE_RED}%s failed (see %s)${RESET}\n" "$label" "$LOG_FILE"
      return $rc
    fi
    printf "\e[?25h"
  else
    wait "$pid"
  fi
}

# ===== Show banner =====
show_JUE_banner

# =================== Step 01: Telegram Config ===================
show_step "01" "Telegram Configuration Setup"

TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-}"
TELEGRAM_CHAT_IDS="${TELEGRAM_CHAT_IDS:-${TELEGRAM_CHAT_ID:-}}"

# load from .env if present
if [[ ( -z "${TELEGRAM_TOKEN}" || -z "${TELEGRAM_CHAT_IDS}" ) && -f .env ]]; then
  set -a; source ./.env; set +a
  show_info "Loaded configuration from .env file"
fi

printf "\n${C_JUE_YELLOW}┌──────────────────────────────────────────────────────┐${RESET}\n"
printf "${C_JUE_YELLOW}│${RESET} ${C_JUE_CYAN}🔑 Telegram Bot Configuration${RESET}                      ${C_JUE_YELLOW}│${RESET}\n"
printf "${C_JUE_YELLOW}└──────────────────────────────────────────────────────┘${RESET}\n\n"

read -rp "${C_JUE_GREEN}🤖 Enter Telegram Bot Token:${RESET} " _tk || true
[[ -n "${_tk:-}" ]] && TELEGRAM_TOKEN="$_tk"
if [[ -z "${TELEGRAM_TOKEN:-}" ]]; then
  show_warning "Telegram token is empty. Deployment will continue without notifications."
else
  show_success "Telegram token configured"
fi

read -rp "${C_JUE_GREEN}👤 Enter Owner/Channel Chat ID(s) (comma separated):${RESET} " _ids || true
[[ -n "${_ids:-}" ]] && TELEGRAM_CHAT_IDS="${_ids// /}"

DEFAULT_LABEL="Join CHANNEL JUE"
DEFAULT_URL="https://t.me/Pussy1900"
BTN_LABELS=(); BTN_URLS=()

printf "\n${C_JUE_YELLOW}┌──────────────────────────────────────────────────────┐${RESET}\n"
printf "${C_JUE_YELLOW}│${RESET} ${C_JUE_CYAN}🔘 Inline Button Configuration (Optional)${RESET}            ${C_JUE_YELLOW}│${RESET}\n"
printf "${C_JUE_YELLOW}└──────────────────────────────────────────────────────┘${RESET}\n\n"

read -rp "${C_JUE_GREEN}➕ Add URL button(s)? [y/N]:${RESET} " _addbtn || true
if [[ "${_addbtn:-}" =~ ^([yY]|yes)$ ]]; then
  i=0
  while true; do
    printf "\n${C_JUE_GRAY}── Button $((i+1)) ──${RESET}\n"
    read -rp "${C_JUE_GREEN}🔖 Label [default: ${DEFAULT_LABEL}]:${RESET} " _lbl || true
    if [[ -z "${_lbl:-}" ]]; then
      BTN_LABELS+=("${DEFAULT_LABEL}")
      BTN_URLS+=("${DEFAULT_URL}")
      show_success "Added: ${DEFAULT_LABEL} → ${DEFAULT_URL}"
    else
      read -rp "${C_JUE_GREEN}🔗 URL (http/https):${RESET} " _url || true
      if [[ -n "${_url:-}" && "${_url}" =~ ^https?:// ]]; then
        BTN_LABELS+=("${_lbl}")
        BTN_URLS+=("${_url}")
        show_success "Added: ${_lbl} → ${_url}"
      else
        show_warning "Skipped (invalid or empty URL)"
      fi
    fi
    i=$(( i + 1 ))
    (( i >= 3 )) && break
    read -rp "${C_JUE_GREEN}➕ Add another button? [y/N]:${RESET} " _more || true
    [[ "${_more:-}" =~ ^([yY]|yes)$ ]] || break
  done
fi

# Normalize CHAT_ID array
CHAT_ID_ARR=()
IFS=',' read -r -a CHAT_ID_ARR <<< "${TELEGRAM_CHAT_IDS:-}" || true

# utility to escape JSON for reply_markup
json_escape(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# =================== Improved tg_send function (supports text + optional file) ===================
tg_send(){
  local text="$1"
  local filepath="${2:-}"   # optional: path to a file to send as document
  if [[ -z "${TELEGRAM_TOKEN:-}" || ${#CHAT_ID_ARR[@]} -eq 0 ]]; then
    echo "[tg_send] Telegram not configured or no chat IDs; skipping."
    return 0
  fi

  # Construct inline keyboard JSON if any buttons were set
  local RM=""
  if (( ${#BTN_LABELS[@]} > 0 )); then
    local L1 U1 L2 U2 L3 U3
    [[ -n "${BTN_LABELS[0]:-}" ]] && L1="$(json_escape "${BTN_LABELS[0]}")" && U1="$(json_escape "${BTN_URLS[0]}")"
    [[ -n "${BTN_LABELS[1]:-}" ]] && L2="$(json_escape "${BTN_LABELS[1]}")" && U2="$(json_escape "${BTN_URLS[1]}")"
    [[ -n "${BTN_LABELS[2]:-}" ]] && L3="$(json_escape "${BTN_LABELS[2]}")" && U3="$(json_escape "${BTN_URLS[2]}")"
    if (( ${#BTN_LABELS[@]} == 1 )); then
      RM="{\"inline_keyboard\":[[{\"text\":\"${L1}\",\"url\":\"${U1}\"}] ]}"
    elif (( ${#BTN_LABELS[@]} == 2 )); then
      RM="{\"inline_keyboard\":[[{\"text\":\"${L1}\",\"url\":\"${U1}\"}], [{\"text\":\"${L2}\",\"url\":\"${U2}\"}] ]}"
    else
      RM="{\"inline_keyboard\":[[{\"text\":\"${L1}\",\"url\":\"${U1}\"}], [{\"text\":\"${L2}\",\"url\":\"${U2}\"},{\"text\":\"${L3}\",\"url\":\"${U3}\"}] ]}"
    fi
  fi

  for _cid in "${CHAT_ID_ARR[@]}"; do
    # trim whitespace
    _cid="$(echo -n "${_cid}" | tr -d '[:space:]')"
    if [[ -n "$filepath" && -f "$filepath" ]]; then
      # send document (file)
      resp=$(curl -s -w "\n%{http_code}" -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendDocument" \
        -F chat_id="${_cid}" \
        -F document=@"${filepath}" \
        -F caption="${text}" \
        ${RM:+-F "reply_markup=${RM}"})
    else
      # send text message
      resp=$(curl -s -w "\n%{http_code}" -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "chat_id=${_cid}" \
        --data-urlencode "text=${text}" \
        --data-urlencode "parse_mode=HTML" \
        ${RM:+--data-urlencode "reply_markup=${RM}"})
    fi

    http_code=$(echo "$resp" | tail -n1)
    body=$(echo "$resp" | sed '$d')

    if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
      show_success "Telegram notification sent → ${_cid}"
    else
      show_error "Failed to send to ${_cid} (HTTP ${http_code})"
      echo "Telegram response body: $body" >> "$LOG_FILE"
      # keep going for other chat ids
    fi
  done
}

# =================== Step 02: GCP Project ===================
show_step "02" "GCP Project Configuration"

PROJECT="$(gcloud config get-value project 2>/dev/null || true)"
if [[ -z "$PROJECT" ]]; then
  show_error "No active GCP project found."
  show_info "Please run: ${C_JUE_CYAN}gcloud config set project <YOUR_PROJECT_ID>${RESET}"
  exit 1
fi
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')" || true
show_success "Project loaded successfully"
show_kv "Project ID:" "$PROJECT"
show_kv "Project Number:" "$PROJECT_NUMBER"

# =================== Step 03: Protocol ===================
show_step "03" "Protocol Selection"

PROTO="vless-ws"
IMAGE="docker.io/nkka404/vless-ws:latest"

show_success "Protocol: ${C_JUE_CYAN}VLESS WebSocket${RESET}"
show_info "Docker Image: ${C_JUE_GRAY}$IMAGE${RESET}"
echo "[Docker Image] ${IMAGE}" >>"$LOG_FILE"

# =================== Step 04: Region ===================
show_step "04" "Region Selection"

echo "  1) ${C_JUE_BLUE}🇸🇬 Singapore${RESET} (asia-southeast1) - ${C_JUE_GREEN}Recommended${RESET}"
echo "  2) ${C_JUE_BLUE}🇺🇸 United States${RESET} (us-central1)"
echo "  3) ${C_JUE_BLUE}🇮🇩 Indonesia${RESET} (asia-southeast2)"
echo "  4) ${C_JUE_BLUE}🇯🇵 Japan${RESET} (asia-northeast1)"
echo "  5) ${C_JUE_BLUE}🇪🇺 Belgium${RESET} (europe-west1)"
echo "  6) ${C_JUE_BLUE}🇮🇳 India${RESET} (asia-south1)"
printf "\n"
read -rp "${C_JUE_GREEN}Choose region [1-6, default 1]:${RESET} " _r || true
case "${_r:-1}" in
  2) REGION="us-central1" ;;
  3) REGION="asia-southeast2" ;;
  4) REGION="asia-northeast1" ;;
  5) REGION="europe-west1" ;;
  6) REGION="asia-south1" ;;
  *) REGION="asia-southeast1" ;;
esac
show_success "Selected Region: ${C_JUE_CYAN}$REGION${RESET}"

# =================== Step 05: Resources ===================
show_step "05" "Resource Configuration"

read -rp "${C_JUE_GREEN}CPU Cores [1/2/4/6, default 2]:${RESET} " _cpu || true
CPU="${_cpu:-2}"

printf "\n${C_JUE_GRAY}Available Memory Options:${RESET}\n"
echo "  ${C_JUE_GRAY}•${RESET} 512Mi  ${C_JUE_GRAY}•${RESET} 1Gi    ${C_JUE_GRAY}•${RESET} 2Gi (Recommended)"
echo "  ${C_JUE_GRAY}•${RESET} 4Gi    ${C_JUE_GRAY}•${RESET} 8Gi    ${C_JUE_GRAY}•${RESET} 16Gi"
printf "\n"
read -rp "${C_JUE_GREEN}Memory [default 2Gi]:${RESET} " _mem || true
MEMORY="${_mem:-2Gi}"
show_success "Resource Configuration"
show_kv "CPU Cores:" "$CPU"
show_kv "Memory:" "$MEMORY"

# =================== Step 06: Service ===================
show_step "06" "Service Configuration"

SERVICE="${SERVICE:-jue-vless}"
TIMEOUT="${TIMEOUT:-3600}"
PORT="${PORT:-8080}"
read -rp "${C_JUE_GREEN}Service Name [default: ${SERVICE}]:${RESET} " _svc || true
SERVICE="${_svc:-$SERVICE}"
show_success "Service Configuration"
show_kv "Service Name:" "$SERVICE"
show_kv "Port:" "$PORT"
show_kv "Timeout:" "${TIMEOUT}s"

# =================== Step 07: Timezone / Schedule ===================
show_step "07" "Deployment Schedule"

export TZ="Asia/Yangon"
START_EPOCH="$(date +%s)"
END_EPOCH="$(( START_EPOCH + 5*3600 ))"
fmt_dt(){ date -d @"$1" "+%d.%m.%Y %I:%M %p"; }
START_LOCAL="$(fmt_dt "$START_EPOCH")"
END_LOCAL="$(fmt_dt "$END_EPOCH")"

show_kv "Start Time:" "$START_LOCAL"
show_kv "End Time:" "$END_LOCAL"
show_kv "Timezone:" "Asia/Yangon"
show_info "Deployment will complete within 5 minutes"

# =================== Step 08: Enable APIs ===================
show_step "08" "GCP API Enablement"

run_with_progress "Enabling Cloud Run & Cloud Build APIs" \
  gcloud services enable run.googleapis.com cloudbuild.googleapis.com --quiet
show_success "All required APIs enabled"

# =================== Step 09: Deploy to Cloud Run ===================
show_step "09" "Cloud Run Deployment"

show_info "Deployment Configuration Summary:"
show_kv "Protocol:" "VLESS WS"
show_kv "Region:" "$REGION"
show_kv "Service:" "$SERVICE"
show_kv "Resources:" "${CPU} vCPU / ${MEMORY}"
show_kv "Image:" "${C_JUE_GRAY}${IMAGE}${RESET}"
printf "\n"

run_with_progress "Deploying ${SERVICE} to Cloud Run" \
  gcloud run deploy "$SERVICE" \
    --image="$IMAGE" \
    --platform=managed \
    --region="$REGION" \
    --memory="$MEMORY" \
    --cpu="$CPU" \
    --concurrency=1000 \
    --timeout="$TIMEOUT" \
    --allow-unauthenticated \
    --port="$PORT" \
    --min-instances=1 \
    --quiet

# =================== Step 10: Result ===================
show_step "10" "Deployment Result"

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')" || true
CANONICAL_HOST="${SERVICE}-${PROJECT_NUMBER}.${REGION}.run.app"
URL_CANONICAL="https://${CANONICAL_HOST}"

show_success "VLESS WS Service is now running!"
show_divider
printf "\n${C_JUE_GREEN}${BOLD}📡 SERVICE ENDPOINT:${RESET}\n"
printf "   ${C_JUE_CYAN}${BOLD}%s${RESET}\n\n" "${URL_CANONICAL}"

# =================== VLESS Configuration ===================
VLESS_UUID="${VLESS_UUID:-ba0e3984-ccc9-48a3-8074-b2f507f41ce8}"
URI="vless://${VLESS_UUID}@vpn.googleapis.com:443?path=%2F%40juevpn&security=tls&encryption=none&host=${CANONICAL_HOST}&type=ws&sni=vpn.googleapis.com#CHANNEL-JUE-VLESS-WS"

printf "${C_JUE_GREEN}${BOLD}🔑 VLESS CONFIGURATION:${RESET}\n"
printf "   ${C_JUE_CYAN}%s${RESET}\n\n" "${URI}"

printf "${C_JUE_GREEN}${BOLD}📋 CONFIGURATION DETAILS:${RESET}\n"
show_kv "UUID:" "$VLESS_UUID"
show_kv "Host:" "vpn.googleapis.com"
show_kv "Port:" "443"
show_kv "Path:" "/@juevpn"
show_kv "Security:" "TLS"
show_kv "Transport:" "WebSocket"
show_kv "SNI:" "vpn.googleapis.com"
show_divider

# =================== QR Code Display (placeholder) ===================
printf "\n${C_JUE_GREEN}${BOLD}📱 QR CODE (Scan with V2Ray client):${RESET}\n"
show_info "Generating QR code for quick configuration..."
echo "[QR Code URL: $URI]" >> "$LOG_FILE"

# Save deployment info to file (so we can optionally send as document)
DEPLOY_INFO_FILE="/tmp/deployment-info-$(date +%s).txt"
cat > "${DEPLOY_INFO_FILE}" <<EOF
VLESS WS Deployment Success
Region: ${REGION}
Protocol: VLESS WebSocket
Endpoint: ${URL_CANONICAL}
Resources: ${CPU} vCPU / ${MEMORY}
VLESS URI:
${URI}
Deployed: ${START_LOCAL}
Expires: ${END_LOCAL}
EOF
echo "Saved deployment info to ${DEPLOY_INFO_FILE}" >> "$LOG_FILE"

# =================== Step 11: Telegram Notification ===================
show_step "11" "Telegram Notification"

MSG=$(cat <<EOF
✅ <b>VLESS WS Deployment Success</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━
🌍 <b>Region:</b> ${REGION}
📡 <b>Protocol:</b> VLESS WebSocket
🔗 <b>Endpoint:</b> <a href="${URL_CANONICAL}">${URL_CANONICAL}</a>
⚙️ <b>Resources:</b> ${CPU} vCPU / ${MEMORY}

🔑 <b>VLESS Configuration:</b>
<pre>${URI}</pre>

🕒 <b>Deployed:</b> ${START_LOCAL}
⏳ <b>Expires:</b> ${END_LOCAL}

━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>Powered by CHANNEL JUE</b>
EOF
)

# send text message
tg_send "${MSG}"

# optionally send deployment info file as document (uncomment if you want file send)
# tg_send "Attached: deployment details" "${DEPLOY_INFO_FILE}"

show_success "Telegram notification attempted (see logs for details)"

# =================== Final Output ===================
printf "\n${C_JUE_YELLOW}┌──────────────────────────────────────────────────────┐${RESET}\n"
printf "${C_JUE_YELLOW}│${RESET} ${C_JUE_CYAN}✨ DEPLOYMENT COMPLETE${RESET}                                ${C_JUE_YELLOW}│${RESET}\n"
printf "${C_JUE_YELLOW}└──────────────────────────────────────────────────────┘${RESET}\n\n"

show_success "VLESS WS service deployed successfully!"
show_info "Service URL: ${C_JUE_CYAN}${URL_CANONICAL}${RESET}"
show_info "Configuration saved to log file"
show_kv "Log File:" "$LOG_FILE"
show_kv "Service Name:" "$SERVICE"
show_kv "Region:" "$REGION"

printf "\n${C_JUE_PURPLE}${BOLD}💡 IMPORTANT NOTES:${RESET}\n"
echo "  ${C_JUE_GRAY}•${RESET} Service is configured with ${C_JUE_GREEN}warm instances${RESET} (min-instances=1)"
echo "  ${C_JUE_GRAY}•${RESET} ${C_JUE_GREEN}No cold start${RESET} delays for initial connections"
echo "  ${C_JUE_GRAY}•${RESET} Configured for ${C_JUE_GREEN}high concurrency${RESET} (1000 concurrent requests)"
echo "  ${C_JUE_GRAY}•${RESET} ${C_JUE_GREEN}Publicly accessible${RESET} via the endpoint"
echo "  ${C_JUE_GRAY}•${RESET} Auto-scales based on traffic demand"
printf "\n"

show_divider
printf "\n${C_JUE_RED}${BOLD}J U E${RESET} ${C_JUE_GRAY}|${RESET} ${C_JUE_CYAN}VLESS WebSocket Deployment System${RESET} ${C_JUE_GRAY}|${RESET} ${C_JUE_GREEN}v2.0${RESET}\n"
printf "${C_JUE_GRAY}──────────────────────────────────────────────────────────${RESET}\n\n"
