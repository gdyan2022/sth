echo -e "========== Telegram ==========\nSG (91.108.56.130): $(ping 91.108.56.130 -c 10 -i 0.3 | grep -oP 'mdev\s\=\s\K\d+\.\d+')\nNL (149.154.167.51): $(ping 149.154.167.51 -c 10 -i 0.3 | grep -oP 'mdev\s\=\s\K\d+\.\d+')\nUS (149.154.175.53): $(ping 149.154.175.53 -c 10 -i 0.3 | grep -oP 'mdev\s\=\s\K\d+\.\d+')\n========== Twitter ==========\nvideo.twimg.com: $(ping video.twimg.com -c 10 -i 0.3 | grep -oP 'mdev\s\=\s\K\d+\.\d+')"
