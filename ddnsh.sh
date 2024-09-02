#!/usr/bin/env sh

# User args
DOMAIN="$1"
IPV="$2"

# Set initial vars
CHANGED=true
if [ ! "$DDNSH_CF_PROXY" = false ]; then
	DDNSH_CF_PROXY=true
fi

case "$IPV" in
A)
	LOCAL_IPS=$(curl -s https://ipv4.icanhazip.com/)
	FOREIGN_IPS=$(host -t A "$DOMAIN" | awk '/has address/ { print $4 }')
	;;
AAAA)
	LOCAL_IPS=$(curl -s https://ipv6.icanhazip.com/)
	FOREIGN_IPS=$(host -t AAAA "$DOMAIN" | awk '/has IPv6 address/ { print $5 }')
	;;
*)
	LOCAL_IPS=$({
		curl -s https://ipv4.icanhazip.com/
		curl -s https://ipv6.icanhazip.com/
	})
	FOREIGN_IPS=$({
		host -t A "$DOMAIN" | awk '/has address/ { print $4 }'
		host -t AAAA "$DOMAIN" | awk '/has IPv6 address/ { print $5 }'
	})
	;;
esac

# Start logic
for FOREIGN_IP in $FOREIGN_IPS; do
	for LOCAL_IP in $LOCAL_IPS; do
		if [ "$FOREIGN_IP" = "$LOCAL_IP" ]; then
			CHANGED=false
			break
		fi
	done
done

if [ $CHANGED = true ]; then
	TYPE="A"
	for LOCAL_IP in $LOCAL_IPS; do
			RECORDS=$(host -t txt ddnsh."$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')" | sed -n 's/.*"\([^"]*\)".*/\1/p')
			curl --request POST --url https://api.cloudflare.com/client/v4/zones/$DDNSH_CF_ZONEID/dns_records/ \
				--header "Content-Type: application/json" \
				--header "Authorization: Bearer $DDNSH_CF_APIKEY" \
				--data "{
        \"content\": \"$LOCAL_IP\",
        \"name\": \"$DOMAIN\",
        \"proxied\" $DDNSH_CF_PROXY):,
        \"type\": \"$TYPE\",
        \"comment\": \"Record created by DDNSH!\",
        \"tags\": [],
        \"ttl\": 300
      }"
			TYPE="AAAA"
		fi
	done
fi
