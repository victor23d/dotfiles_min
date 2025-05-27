#!/bin/bash

# Ensure the script is being run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root."
  exit 1
fi

# Step 1: Enable root login in GDM config
GDM_CONF="/etc/gdm3/custom.conf"
if grep -q "^#*AllowRoot=" "$GDM_CONF"; then
  # Modify existing line
  sed -i 's/^#*AllowRoot=.*/AllowRoot=true/' "$GDM_CONF"
else
  # Add under [security] section or append if not found
  if grep -q "^\[security\]" "$GDM_CONF"; then
    sed -i '/^\[security\]/a AllowRoot=true' "$GDM_CONF"
  else
    echo -e "\n[security]\nAllowRoot=true" >> "$GDM_CONF"
  fi
fi

echo "Updated $GDM_CONF with AllowRoot=true"

# Step 2: Modify PAM config to allow root GUI login
echo "Root login via GDM should now be allowed. Reboot to apply changes."
PAM_FILE="/etc/pam.d/gdm-password"
LINE_TO_COMMENT="pam_succeed_if.so.*user != root.*quiet_success"

if grep -q "$LINE_TO_COMMENT" "$PAM_FILE"; then
  sed -i "/$LINE_TO_COMMENT/ s/^/# /" "$PAM_FILE"
  echo "Commented out root access denial in $PAM_FILE"
else
  echo "No root denial line found matching: $LINE_TO_COMMENT"
fi

echo -e "Done. Reboot your system to apply changes and allow root login in GDM."
