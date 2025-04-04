#!/bin/bash

# Visit this URL for usage instructions
# https://github.com/reopenpilot/openpilot-tuner/

# Set shutdown voltage
VBATT_SHUTDOWN_THRESHOLD=11.2

MAX_TIME_OFFROAD_S=$(cat /data/params/ZzShutdownTime 2>/dev/null || echo "100*365*24*3600")

# ONLY FOR FrogPilot (HOURS)
DEVICE_SHUTDOWN_TIME=99999

TOKEN=$(cat /data/params/ZzTelegramToken 2>/dev/null || echo "")
CHAT_ID=$(cat /data/params/ZzTelegramChatID 2>/dev/null || echo "")
TELEGRAM_URL="https://api.telegram.org/bot$TOKEN/sendMessage"

send_telegram() {
    local message="$1"
    local start_time=$(date +%s)
    if [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ]; then
        echo "TOKEN or CHAT_ID is an empty string, skiping this function."
        return
    fi
    (
        while true; do
            if curl -s -X POST "$TELEGRAM_URL" -d chat_id="$CHAT_ID" -d parse_mode="MarkdownV2" -d text="$message" > /dev/null; then
                break
            fi
            local now=$(date +%s)
            if [ $((now - start_time)) -ge 3600 ]; then
                echo "Failed to send message after 1 hour. Abandoning attempts."
                break
            fi
            sleep 30
        done
    ) &
}

cd /data/openpilot
cd /data/safe_staging/finalized

filename_athenad=system/athena/athenad.py
filename_powermonitoring=system/hardware/power_monitoring.py

errors=""

{
    git checkout -- $filename_athenad 2>&1
    git checkout -- $filename_powermonitoring 2>&1
    find .git -exec touch -t 200001010000 {} \; 2>&1

    sed -i "s/if len(file.fn) == 0/if 'dcamera' in file.fn or len(file.fn) == 0/" $filename_athenad 2>&1
    sed -i "s/VBATT_PAUSE_CHARGING = 11.8/VBATT_PAUSE_CHARGING = $VBATT_SHUTDOWN_THRESHOLD/" $filename_powermonitoring 2>&1

    sed -i "s/MAX_TIME_OFFROAD_S = .*/MAX_TIME_OFFROAD_S = $MAX_TIME_OFFROAD_S/" $filename_powermonitoring 2>&1

    sed -i 's/should_shutdown |= (self.car_battery_capacity_uWh <= 0)/#should_shutdown |= (self.car_battery_capacity_uWh <= 0)/' $filename_powermonitoring 2>&1

    sed -i 's/frogpilot_toggles.low_voltage_shutdown/0/' $filename_powermonitoring 2>&1
    sed -i "s/frogpilot_toggles.device_shutdown_time/$DEVICE_SHUTDOWN_TIME/" $filename_powermonitoring 2>&1

} 2>&1 | {
    while IFS= read -r line; do
        errors+="$line\n"
    done
}

changes=$(git diff --no-prefix --minimal --unified=0 | sed 's/`/\\`/g')
changes=${changes:0:2000}
errors=${errors:0:2000}

send_telegram "\`\`\`
#ERROR:
$errors
\`\`\`"

send_telegram "\`\`\`
#CHANGES:
$changes
\`\`\`"

cd /data/openpilot
exec ./launch_openpilot.sh
