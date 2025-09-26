#!/usr/bin/env bash

remote_user="root"                          # change if needed
remote_host="micple.com"                    # your remote server IP or domain
remote_server_pvt_key="/var/store/micple_server_keys"
remote_file="/etc/nginx/conf.d/others/jenkins.somacharnews.com.conf"


# Get current private IP of Mac
ip=$(ifconfig | awk '/inet /{print $2}' \
    | grep -v '^127\.' \
    | grep -v '^169\.254\.' \
    | grep -E '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)' \
    | head -n1)

if [ -z "$ip" ]; then
  echo "No private IP found!"
  exit 1
fi

echo "Using private IP: $ip"

# Replace the IP in 2nd line (keep :8080 intact)
ssh -i "${remote_server_pvt_key}" ${remote_user}@${remote_host} "
  sed -i '2s|server .*:8080;|server ${ip}:8080;|' ${remote_file} &&
  nginx -t &&
  systemctl reload nginx
"