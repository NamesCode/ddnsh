#!/usr/bin/env sh

# User args
DOMAIN="$1"
IPV="$2"

# Set initial vars
if [ ! "$DDNSH_CF_PROXY" = false ]; then
	DDNSH_CF_PROXY=true
fi

HOST=$(uname -n)

case "$IPV" in
A)
	LOCAL_IPS=$(curl -s https://ipv4.icanhazip.com/)
	;;
AAAA)
	LOCAL_IPS=$(curl -s https://ipv6.icanhazip.com/)
	;;
*)
	LOCAL_IPS=$({
		curl -s https://ipv4.icanhazip.com/
		curl -s https://ipv6.icanhazip.com/
	})
	;;
esac

# Start logic
RECORDS=$(
	curl -s --request GET \
		--url "https://api.cloudflare.com/client/v4/zones/beaa649556618108a535c4e9b32473c5/dns_records?comment.contains=DDNSH-$HOST" \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer $DDNSH_CF_APIKEY" | jq -c '.result.[]'
)

for RECORD in $RECORDS; do
	TYPE="A"
	for LOCAL_IP in $LOCAL_IPS; do
		if [ ! $(echo $RECORD | jq -r '.content') = $LOCAL_IP ] && [ $(echo $RECORD | jq -r '.type') = $TYPE ]; then
			RESULT=$(curl -s --request PATCH \
				--url https://api.cloudflare.com/client/v4/zones/$DDNSH_CF_ZONEID/dns_records/$(echo $RECORD | jq -r '.id') \
				--header "Content-Type: application/json" \
				--header "Authorization: Bearer $DDNSH_CF_APIKEY" \
				--data "{
            \"comment\": \"DDNSH-$HOST\",
            \"name\": \"$DOMAIN\",
            \"content\": \"$LOCAL_IP\",
            \"ttl\": 300,
            \"type\": \"$TYPE\",
            \"tags\": []
          }")
			if [ "$(echo $RESULT | jq -r '.success')" = true ]; then
				echo "Successfully updated! :3 | Updated $DOMAIN: $(echo $RECORD | jq -r '.content') -> $LOCAL_IP"
			else
				echo "Failed to update. Error: $(echo $RESULT | jq '.errors')"
			fi
		fi
		TYPE="AAAA"
	done
done
