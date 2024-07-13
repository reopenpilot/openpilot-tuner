# openpilot-tuner

Automatically modify code at startup to fine-tune openpilot, sunnypilot, or frogpilot.



## Steps
Skip steps 1 & 2 if not using Telegram notifications.
1. Get a Telegram bot token & chat_id:
   [Telegram Bot Token & Chat ID Guide](https://gist.github.com/nafiesl/4ad622f344cd1dc3bb1ecbe468ff9f8a)

2. Replace `___TOKEN___` and `___CHAT_ID___` in the commands below with your token & chat_id. Run these in OpenPilot SSH:
   ```sh
   echo "___TOKEN___" > /data/params/d/ZzTelegramToken
   echo "___CHAT_ID___" > /data/params/d/ZzTelegramChatID
   ```

3. Run this command in OpenPilot SSH:
   ```sh
   curl -fsSL https://gist.githubusercontent.com/reopenpilot/openpilot-tuner/raw/openpilot-tuner.sh | sudo tee /data/continue.sh > /dev/null
   ```
