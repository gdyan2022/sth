#!/bin/bash

security delete-generic-password -s "Claude Code-credentials" 2>/dev/null || true
rm -rf "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.anthropic."* 2>/dev/null || true
python3 -c 'import json,os,secrets; p=os.path.expanduser("~/.claude.json"); data=json.load(open(p)) if os.path.exists(p) else {}; [data.pop(k, None) for k in ["oauthAccount", "account", "user", "primaryOrgId", "lastCost", "lastTokenUsage"]]; data.update({"machineID": secrets.token_hex(32), "userID": secrets.token_hex(32)}); json.dump(data, open(p, "w"), indent=2)'
