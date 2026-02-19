#!/usr/bin/env bash
# check_ssl_expiry.sh
# Check SSL certificate expiration for domains listed in a file.
# Supports optional client certificate/key (for mTLS).

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <domains_file>"
    echo "Each line format:"
    echo "  domain"
    echo "  domain,client_cert.pem,client_key.pem"
    exit 1
fi

DOMAINS_FILE="$1"

if [[ ! -f "$DOMAINS_FILE" ]]; then
    echo "Error: file '$DOMAINS_FILE' not found."
    exit 1
fi

exit_code=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # skip empty lines or comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    IFS=',' read -r domain client_cert client_key <<<"$line"
    echo -n "🔍 Checking $domain ... "

    # Split domain and port (default to 443)
    if [[ "$domain" =~ ^(.+):([0-9]+)$ ]]; then
        host="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
        connect_str="$domain"
    else
        host="$domain"
        port="443"
        connect_str="$domain:443"
    fi

    # Build openssl command options
    cert_args=""
    if [[ -n "${client_cert:-}" && -n "${client_key:-}" ]]; then
        # Expand tilde in paths
        client_cert="${client_cert/#\~/$HOME}"
        client_key="${client_key/#\~/$HOME}"
        cert_args="-cert $client_cert -key $client_key"
    fi

    # Fetch certificate and extract expiry date
    expiry_date=$(
        timeout 8 bash -c "openssl s_client -showcerts -servername '$host' -connect '$connect_str' $cert_args </dev/null 2>&1" | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2
    ) || true

    if [[ -z "$expiry_date" ]]; then
        echo "❌ Failed to fetch certificate."
        continue
    fi

    expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || date -jf "%b %d %T %Y %Z" "$expiry_date" +%s)
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

    printf "%s (%d days left)\n" "$expiry_date" "$days_left"

    if (( days_left <= 0 )); then
        echo "⚠️  Certificate for $domain has expired!"
        exit_code=1
    elif (( days_left <= 30 )); then
        echo "⚠️  Certificate for $domain expires soon (in $days_left days)!"
        [[ $exit_code -eq 0 ]] && exit_code=2
    fi
done < "$DOMAINS_FILE"

exit $exit_code
