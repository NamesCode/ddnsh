#!/usr/bin/env sh

# Set initial vars
HOST=$(uname -n)
LOCAL_IPS=$({
	curl -s https://ipv4.icanhazip.com/
	curl -s https://ipv6.icanhazip.com/
})

# Start logic
RECORDS=$(
	curl -s --request GET \
		--url "https://api.cloudflare.com/client/v4/zones/$DDNSH_CF_ZONEID/dns_records?comment.contains=DDNSH-$HOST" \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer $DDNSH_CF_APIKEY"
)

if [ $(echo "$RECORDS" | jq -r '.success') = true ]; then
	RECORDS=$(echo "$RECORDS" | jq -c '.result.[]')
else
	echo "Issue with authentication, check your keys?"
	exit 0
fi

for RECORD in $RECORDS; do
	TYPE="A"
	for LOCAL_IP in $LOCAL_IPS; do
		if [ ! $(echo $RECORD | jq -r '.content') = $LOCAL_IP ] && [ $(echo $RECORD | jq -r '.type') = $TYPE ]; then
			DOMAIN=$(echo $RECORD | jq -r '.name')
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
				echo "Failed to update $DOMAIN. Error: $(echo $RESULT | jq '.errors')"
			fi
		fi
		TYPE="AAAA"
	done
done
