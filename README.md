# DDNSH

A minimal POSIX shell script to update your DNS entries in the case that your dynamic IP updates.
Ideally run as a cron job.

This script should work on Linux, *BSD and any other POSIX system.
Currently, It only supports updating records from Cloudflare. 
Other DNS providers can be supported in future if an issue gets risen for them, and they have a REST API.

## Dependencies

The only dependency you need is curl.
Curl is often preinstalled on most Linux systems, however it is not on *BSD systems.
Consult your package manager on how to install curl if it is not installed already.

## Installation

```sh
curl -s -o ./ddnsh.sh [INSERT THE RAW URL HERE];
chmod +x ./ddnsh.sh
```

## Usage

`./ddns.sh [Your domain] [Bool: Overwrite DNS records tagged with 'DDNSH'?] [OPTIONAL: Edit A records or AAAA records or both; inputs A/AAAA/(leave blank for both)]`

An example:
`./ddns.sh example.com true`

### With overwrite enabled

Enabling overwrite will require some more manual setup unless you allow [the script to naively overwrite every A and AAAA record](#naive-auto-setup).

To enable overwrite, create a txt record at `ddnsh.your.domain` and input each IP (accepts IPv4 and IPv6) address you want updated, one per line.
You will have to update this file with more IP's as you add servers that use DDNSH on other dynamic IP networks.

An example:
```txt
127.0.0.1
::1
```

#### Naive auto setup

If you set the `DDNSH_NAIVE_SETUP` to true the script will create a txt record under `ddnsh.your.domain`,
naively the script will take all the ip's from the specified records (The optional: A/AAAA/both) and insert them into the txt file.

```sh
export DDNSH_NAIVE_SETUP=true
```

### With Cloudflare

Firstly, you will have to find your domains [zone id](https://developers.cloudflare.com/fundamentals/setup/find-account-and-zone-ids/).
Secondly you're going to need an [API token](https://dash.cloudflare.com/profile/api-tokens).
Lastly, you can specify if you want records to proxy through Cloudflare. By default, it will however you disable this through `DDNSH_CF_PROXY=false`.

I recommend you use the Zone DNS template for the token.
The token will need to have Zone DNS editing access.
The rest it up to you, however I would recommend making a token for each specific domain and setting the TTL to be **at most** 6 months.

Once you have both of these, you'll have to pass them in with the DDNSH_CF env vars.
```sh
# Run first to disable shell history. Not doing so will leak your api secrets in plaintext to $HISTFILE.
HISTFILE_COPY="$HISTFILE" HISTFILE="/dev/null"

# Run this line as many times as you need for each domain.
DDNSH_CF_ZONEID="yourzoneid" DDNSH_CF_APIKEY="yourcloudflareapikey" DDNSH_CF_PROXY=false ./ddnsh.sh args-here

# Run when your finished to turn back on shell history.
HISTFILE="$HISTFILE_COPY" unset HISTFILE_COPY
```

## Quick start

I recommend using this quick setup script if you want something opinionated that "just works"™.
This will install the script at `~/local/bin/` and create a crontab for this user running this script every 5 minutes.
Ideally this should be run on the same user that your web facing server is run on.

```sh
mkdir ~/.local; \
mkdir ~/.local/bin/; \
curl -s -o ~/.local/bin/ddnsh.sh [INSERT THE RAW URL HERE]; \
chmod +x ~/.local/bin/ddnsh.sh; \
(crontab -l; echo "DDNSH_CF_ZONEID='yourzoneid'
DDNSH_CF_APIKEY='yourcloudflareapikey'
*/5 * * * * /home/$USER/.local/bin/ddnsh.sh your-site.here true > /dev/null") | crontab -
```

**NOTE**: This quick start script will **ONLY** work if your cron allows setting env vars inside itself. 
Crons that are known **TO** work are:
- Vixie-cron
- GNU mcron

Crons that are known **NOT TO** work are:
- Cronie

Vixie-cron is the most widely used which makes it good enough for me to put in the quick start,
**HOWEVER** if you are no running one of the compatible crons then you'll have to follow the standard install guide.
