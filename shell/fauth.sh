#!/bin/sh
#
#: fauth.sh -- IIT Kanpur firewall authenticator
#:
#: This script allows you to headlessly log in to the IIT Kanpur firewall
#: on both Fortigate and IronPort gateways.  Fortigate is assumed by
#: default and should work without any issues.
#:
#: The IronPort gateway requires authenticating twice -- for HTTP(S)
#: requests and for non-HTTP requests (IMAP, FTP, P2P protocols, etc.).
#: Authentication for HTTP requests is done through basic authentication.
#: Since basic authentication does not support logging out [1], one has
#: to wait until the session expires (a session lasts for about 2 hours).
#: Authentication for non-HTTP requests is handled separately through a
#: web form [2] as described on the CC website [3].
#:
#: Usage: fauth [-Iv] [-u <user>] [-p <passwd>] [-t <url>] [-w <time>]
#:
#:   -I           Choose the IronPort gateway
#:   -v           Verbose output for debugging
#:   -u <user>    Username for authentication
#:   -p <passwd>  Password for authentication
#:   -t <url>     Test connection using this URL
#:   -w <time>    Waiting time (time-out) for a cURL operation
#:
#: Rather than passing the username and password as command line
#: arguments, it's better to edit the script and set the "fauth_user"
#: and "fauth_passwd" variables manually [4].
#:
#: [1]: One possible way is to force a 401 response from the server by
#:      sending a wrong user/password combination -- but it doesn't seem
#:      to work in this case.  See: http://stackoverflow.com/a/233551
#: [2]: https://authenticate.iitk.ac.in/netaccess/loginuser.html
#: [3]: http://www.iitk.ac.in/cc/ironport_noproxy.htm
#: [4]: Otherwise it's quite easy to steal the password from
#:      /proc/<process-id>/cmdline
#:
#: Requires: cURL >= 7.18.0
#:
#: History: The first version of this script was hacked together in 2012 as an
#: alternative to Siddharth Aggarwal's firewall-auth Python script.  I kept on
#: tweaking things as IITK's firewall evolved.  I used it between 2012 and 2015
#: (right before I left).  (Also worked in June 2017 when I visited IITK.)
#

ip_connstatus="https://authenticate.iitk.ac.in/netaccess/connstatus.html"
ip_loginuser="https://authenticate.iitk.ac.in/netaccess/loginuser.html"

unset http_proxy
unset HTTPS_PROXY
unset ALL_PROXY

die() {
  echo >&2 "$1"
  exit 1
}

usage() {
  grep '^#:' <"$0" | cut -c 4-
}

time_log() {
  echo >&2 "[$(date +'%Y-%m-%d %I:%M:%S %p')] ${1}"
}

ironport=false
test_url="91.198.174.192"
time_out="10"
curl_opts="-skm ${time_out}"

while getopts ":hvIu:p:t:w:" opt; do
  case "$opt" in
    h)  usage; exit                                        ;;
    I)  ironport=true                                      ;;
    v)  curl_opts="${curl_opts} --trace-ascii /dev/stderr" ;;
    u)  fauth_user="$OPTARG"                               ;;
    p)  fauth_passwd="$OPTARG"                             ;;
    t)  test_url="$OPTARG"                                 ;;
    w)  time_out="$OPTARG"                                 ;;
    :)  die "fauth: -${OPTARG} requires an argument"       ;;
    \?) die "fauth: -${OPTARG} is not a valid option"      ;;
  esac
done

[ -n "$fauth_user" ]   || die "fauth: missing username"
[ -n "$fauth_passwd" ] || die "fauth: missing password"

logout_fort() {
  if curl $curl_opts -o /dev/null "$log_out_url"; then
    time_log "Successfully logged out of Fortigate."
    return 0
  else
    time_log "Error: Unable to log out of Fortigate."
    return 1
  fi
}

logout_ip_nohttp() {
  resp=$(curl $curl_opts "$ip_connstatus" -d sid="0" -d logout="Log+Out+Now")

  if $(echo "$resp" | grep -q "You are not logged in."); then
    time_log "Successfully cleared IronPort non-HTTP authentication."
    return 0
  else
    time_log "Error: Unable to clear IronPort non-HTTP authentication."
    return 1
  fi
}

# Log out on interruption.
trap '
  echo >&2
  if [ "$ironport" = "true" ]; then
    logout_ip_nohttp
  else
    logout_fort
  fi
  exit "$?"
' INT TERM

#
# HTTP response codes:
#
#   000 -- network not reachable
#   303, 307 -- redirection (authentication required)
#   200 -- connected (already authenticated)
#

login_fort() {
  while true; do
    code=$(curl $curl_opts -w "%{http_code}" -o /dev/null "$test_url")

    case "$code" in
      000)
        time_log "Network unreachable.  Will try again in 5 secs."
        sleep 5
        ;;
      303)
        auth_url=$(curl $curl_opts -w "%{redirect_url}" -o /dev/null "$test_url")

        magic_string=$(curl $curl_opts "$auth_url" |
                       sed -ne 's/.*value="\([0-9a-f^"]\+\)".*/\1/p')

        resp=$(curl $curl_opts "$auth_url"                     \
                    -d username="$fauth_user"                  \
                    --data-urlencode password="$fauth_passwd"  \
                    -d magic="$magic_string"                   \
                    -d 4Tredir="/")

        keep_alive_url=$(echo "$resp" |
                         sed -ne 's/.*location.href="\([^"]\+\)";.*/\1/p')

        log_out_url=$(echo "$resp" |
                      sed -ne 's/.*<p><a href="\([^"]\+\)">logout.*/\1/p')

        if [ -n "$keep_alive_url" ] && [ -n "$log_out_url" ]; then
          time_log "Fortigate authentication successful."
          time_log "Keep alive URL: ${keep_alive_url}"
          time_log "Log out URL: ${log_out_url}"
        else
          time_log "Error: Fortigate authentication unsuccessful."
          time_log "Error: Please check username/password."
          exit 1
        fi
        ;;
      200)
        if [ -n "$keep_alive_url" ] && [ -n "$log_out_url" ]; then
          curl $curl_opts -o /dev/null "$keep_alive_url"
          time_log "Keep alive request sent!"
          sleep 200
        else
          time_log "Already logged in.  Trying again in 5 secs."
          sleep 5
        fi
        ;;
      *)
        time_log "Error: Unknown HTTP response: ${code}"
        time_log "Error: Run in verbose mode to diagnose."
        exit 1
        ;;
    esac
  done
}

login_ip_http() {
  while true; do
    code=$(curl $curl_opts -w "%{http_code}" -o /dev/null "$test_url")

    case "$code" in
      000)
        time_log "Network unreachable.  Will try again in 5 secs."
        sleep 5
        ;;
      307)
        auth_url=$(curl $curl_opts -w "%{redirect_url}" -o /dev/null "$test_url")

        redirect_url=$(curl $curl_opts "$auth_url"             \
                            -u "${fauth_user}:${fauth_passwd}" \
                            -w "%{redirect_url}"               \
                            -o /dev/null)

        if [ -n "$redirect_url" ]; then
          time_log "IronPort HTTP authentication successful."
        else
          time_log "Error: IronPort HTTP authentication unsuccessful."
          time_log "Error: Please check username/password."
          exit 1
        fi
        ;;
      200)
        time_log "Authenticated for HTTP requests.  Checking in 20 secs."
        sleep 20
        ;;
      *)
        time_log "Error: Unknown HTTP response: ${code}"
        time_log "Error: Run in verbose mode to diagnose."
        exit 1
        ;;
    esac
  done
}

login_ip_nohttp() {
  # Probe connstatus.html; I honestly don't know why this is required
  # but without this it doesn't seem to work.
  curl $curl_opts "$ip_connstatus" \
       -d sid="0"                  \
       -d login="Log+In+Now"       \
       -o /dev/null

  resp=$(curl $curl_opts "$ip_loginuser"                \
              -d username="$fauth_user"                 \
              --data-urlencode password="$fauth_passwd" \
              -d sid="0")

  username=$(echo "$resp" | sed -ne 's/.*<br>Username: \([^>]*\)<br>.*/\1/p')
  user_ip=$(echo "$resp" | sed -ne 's/.*<br>User IP: \([^>]*\)<br>.*/\1/p')

  if [ -n "$username" ] && [ -n "$user_ip" ]; then
    time_log "IronPort non-HTTP authentication successful."
    time_log "Username: ${username}"
    time_log "IP adress: ${user_ip}"
  else
    time_log "Error: IronPort non-HTTP authentication unsuccessful."
    time_log "Error: Please check username/password."
    exit 1
  fi
}

if [ "$ironport" = "true" ]; then
  login_ip_nohttp
  login_ip_http
else
  login_fort
fi
