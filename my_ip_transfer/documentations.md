### Documentation: Creating a Startup Service on macOS

#### First log in as root user
```bash
sudo su root
```

### Create Your Script
```bash
sudo nano /usr/local/bin/my_ip_transfer.sh
```
then pest the shell scirpt:
```bash
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

```

Make the script file executable:
```bash
sudo chmod +x /usr/local/bin/my_ip_transfer.sh
```
### Create a Launch Daemon plist

Create the service definition file:

```bash
sudo nano /Library/LaunchDaemons/com.my_ip_transfer.plist
```

Paste the following:

```bash
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.my_ip_transfer</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/my_ip_transfer.sh</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/my_ip_transfer.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/my_ip_transfer.err</string>
</dict>
</plist>

```

### Set Permissions
LaunchDaemons must be owned by root:wheel and have 644 permissions.

```bash
sudo chown root:wheel /Library/LaunchDaemons/com.my_ip_transfer.plist
sudo chmod 644 /Library/LaunchDaemons/com.my_ip_transfer.plist

```

### Load and Start the Service

Load the service into launchd:
```bash
sudo launchctl load /Library/LaunchDaemons/com.my_ip_transfer.plist
```
Start it immediately:
```bash
sudo launchctl start com.my_ip_transfer
```

### Verify the Service

Check if it’s loaded:
```bash
sudo launchctl list | grep com.my_ip_transfer
```

Expected output example:
```bash
12345   0   com.my_ip_transfer
```
(12345 = PID if running)

Check logs:
```bash
cat /tmp/my_ip_transfer.log
cat /tmp/my_ip_transfer.out
cat /tmp/my_ip_transfer.err
```

### Manage the Service
- **Unload (disable):**
```bash
sudo launchctl unload /Library/LaunchDaemons/com.my_ip_transfer.plist
```
- **Restart:*
```bash
sudo launchctl stop com.my_ip_transfer
sudo launchctl start com.my_ip_transfer
```
- **Check details:**
```bash
sudo launchctl print system/com.my_ip_transfer
```

### Summary
- Script is at: `/usr/local/bin/my_ip_transfer.sh`
- Service definition: `/Library/LaunchDaemons/com.my_ip_transfer.plist`
- Service name (label): `com.my_ip_transfer`
- Logs: `/tmp/my_ip_transfer.log`, `/tmp/my_ip_transfer.out`, `/tmp/my_ip_transfer.err`

This ensures your script will **auto-start at boot** and stay alive (like `systemd’s Restart=always`).