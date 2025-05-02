#!/bin/bash

# Rileva il gestore pacchetti
detect_platform() {
  if [[ -f /etc/debian_version ]]; then
    PKG_MANAGER="apt"
  elif [[ -f /etc/redhat-release ]]; then
    PKG_MANAGER=$(command -v dnf >/dev/null 2>&1 && echo "dnf" || echo "yum")
  elif [[ -f /etc/alpine-release ]]; then
    PKG_MANAGER="apk"
  else
    PKG_MANAGER="unknown"
  fi
}

# Verifica o installa il pacchetto richiesto
check_dependency() {
  local pkg="$1"
  if ! command -v "$pkg" >/dev/null 2>&1; then
    echo "Il pacchetto '$pkg' non è installato."
    read -rp "Vuoi installarlo automaticamente? [y/N] " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      case "$PKG_MANAGER" in
        apt) sudo apt update && sudo apt install -y "$pkg" ;;
        dnf) sudo dnf install -y "$pkg" ;;
        yum) sudo yum install -y "$pkg" ;;
        apk) apk add "$pkg" ;;  # Niente sudo su Alpine
        *) echo "Impossibile installare '$pkg': gestore pacchetti sconosciuto." && exit 1 ;;
      esac
    else
      echo "Dipendenza '$pkg' mancante. Uscita dallo script." && exit 1
    fi
  fi
}

# Parametri script
LOCAL_FILE="$1"
GITHUB_PATH="$2"
COMMIT_MESSAGE="$3"

if [[ -z "$LOCAL_FILE" || -z "$GITHUB_PATH" || -z "$COMMIT_MESSAGE" ]]; then
  echo "Uso: $0 <file locale> <path GitHub> <messaggio commit>"
  exit 1
fi

# Controlla esistenza file
[[ ! -f "$LOCAL_FILE" ]] && echo "File '$LOCAL_FILE' non trovato." && exit 1

# Repo configurazione
REPO="amastran/ccna"
BRANCH="main"
: "${GITHUB_TOKEN:?Variabile GITHUB_TOKEN mancante. Esco.}"

# Inizializzazione
detect_platform
check_dependency curl
check_dependency jq
check_dependency base64

# Codifica in base64 (compatibile anche con Alpine)
ENCODED_CONTENT=$(base64 "$LOCAL_FILE" | tr -d '\n')

# Recupera SHA se il file già esiste
SHA=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO/contents/$GITHUB_PATH" | jq -r '.sha // empty')

# Prepara JSON per GitHub API
if [[ -n "$SHA" ]]; then
  JSON=$(jq -n \
    --arg msg "$COMMIT_MESSAGE" \
    --arg content "$ENCODED_CONTENT" \
    --arg sha "$SHA" \
    --arg branch "$BRANCH" \
    '{message: $msg, content: $content, sha: $sha, branch: $branch}')
else
  JSON=$(jq -n \
    --arg msg "$COMMIT_MESSAGE" \
    --arg content "$ENCODED_CONTENT" \
    --arg branch "$BRANCH" \
    '{message: $msg, content: $content, branch: $branch}')
fi

# Log informativo
echo "Invio '$LOCAL_FILE' a GitHub come '$GITHUB_PATH' nel repo $REPO [$BRANCH]"

# Invio PUT verso GitHub
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/github_response.json -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON" \
  "https://api.github.com/repos/$REPO/contents/$GITHUB_PATH")

if [[ "$RESPONSE" != 201 && "$RESPONSE" != 200 ]]; then
  echo "Errore nell'invio a GitHub (HTTP $RESPONSE)"
  cat /tmp/github_response.json
  exit 1
else
  echo "File caricato o aggiornato correttamente su GitHub."
fi
