#!/usr/bin/env bash
#
# HP Mute LED Enabler for Linux (Realtek ALC236 / HP Laptop 15-dw0xxx)
# Author: JustABoot
# License: MIT
#

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}==========================================================${NC}"
echo -e "${BOLD}  HP Laptop Mute LED Fix for Linux (Realtek ALC236)${NC}"
echo -e "${BOLD}  Subsystem ID: 103c:85f5 -> Quirk: 103c:85f0${NC}"
echo -e "${BLUE}${BOLD}==========================================================${NC}"
echo ""

# Ensure superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[Error] This script must be run as root (sudo).${NC}"
  echo "Run: sudo $0"
  exit 1
fi

echo -e "${YELLOW}[1/4] Creating ALSA firmware patch (/lib/firmware/alsa-hp-mute.fw)...${NC}"
mkdir -p /lib/firmware
cat << 'EOF' > /lib/firmware/alsa-hp-mute.fw
[codec]
0x10ec0236 0 0

[model]
103c:85f0

[subsystem_id]
0x103c85f0
EOF
chmod 644 /lib/firmware/alsa-hp-mute.fw
echo -e "${GREEN}  ✓ Firmware patch saved to /lib/firmware/alsa-hp-mute.fw${NC}"

echo -e "${YELLOW}[2/4] Configuring snd-hda-intel kernel module options...${NC}"
mkdir -p /etc/modprobe.d
cat << 'EOF' > /etc/modprobe.d/hp-mute-led.conf
options snd-hda-intel model=103c:85f0 patch=alsa-hp-mute.fw
EOF
chmod 644 /etc/modprobe.d/hp-mute-led.conf
echo -e "${GREEN}  ✓ Configuration saved to /etc/modprobe.d/hp-mute-led.conf${NC}"

echo -e "${YELLOW}[3/4] Updating distribution initramfs...${NC}"
INITRAMFS_UPDATED=0

if command -v dracut >/dev/null 2>&1; then
  echo "  Detected dracut. Regenerating initramfs..."
  dracut -f --include /lib/firmware/alsa-hp-mute.fw /lib/firmware/alsa-hp-mute.fw
  INITRAMFS_UPDATED=1
elif command -v update-initramfs >/dev/null 2>&1; then
  echo "  Detected update-initramfs (Debian/Ubuntu/Mint). Updating..."
  update-initramfs -u
  INITRAMFS_UPDATED=1
elif command -v mkinitcpio >/dev/null 2>&1; then
  echo "  Detected mkinitcpio (Arch Linux). Updating..."
  mkinitcpio -P
  INITRAMFS_UPDATED=1
else
  echo -e "${YELLOW}  ! Could not automatically detect dracut, update-initramfs, or mkinitcpio.${NC}"
  echo "    If your distribution uses another initramfs tool, ensure /lib/firmware/alsa-hp-mute.fw is included."
fi

if [ "$INITRAMFS_UPDATED" -eq 1 ]; then
  echo -e "${GREEN}  ✓ Initramfs updated successfully.${NC}"
fi

echo -e "${YELLOW}[4/4] Attempting to apply live reload without rebooting...${NC}"
APPLIED=0
REAL_USER="${SUDO_USER:-$USER}"

# Detect Realtek ALC236 sysfs device
HDA_DEV=""
for dev in /sys/class/sound/hwC*D*; do
  if [ -f "$dev/vendor_id" ] && grep -qi "0x10ec0236" "$dev/vendor_id" 2>/dev/null; then
    HDA_DEV="$dev"
    break
  fi
done

# Fallback to hwC0D0 if not explicitly matched
if [ -z "$HDA_DEV" ] && [ -d "/sys/class/sound/hwC0D0" ]; then
  HDA_DEV="/sys/class/sound/hwC0D0"
fi

if [ -n "$HDA_DEV" ] && [ -w "$HDA_DEV/modelname" ] && [ -w "$HDA_DEV/reconfig" ]; then
  echo "  Found audio device at $HDA_DEV"
  
  # Temporarily pause PipeWire / PulseAudio to release sound descriptors
  if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    sudo -u "$SUDO_USER" systemctl --user stop wireplumber.service pipewire.service pipewire.socket pulseaudio.service pulseaudio.socket 2>/dev/null || true
  fi

  echo "103c:85f0" > "$HDA_DEV/modelname" 2>/dev/null || true
  echo "0x103c85f0" > "$HDA_DEV/subsystem_id" 2>/dev/null || true

  if echo 1 > "$HDA_DEV/reconfig" 2>/dev/null; then
    APPLIED=1
  fi

  # Restore PipeWire / PulseAudio
  if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    sudo -u "$SUDO_USER" systemctl --user start pipewire.socket pipewire.service wireplumber.service pulseaudio.socket pulseaudio.service 2>/dev/null || true
  fi
fi

echo ""
echo -e "${BLUE}${BOLD}==========================================================${NC}"
if [ "$APPLIED" -eq 1 ]; then
  echo -e "${GREEN}${BOLD}  SUCCESS! The patch has been applied live to your system.${NC}"
  echo "  Try pressing your mute key (Mute / F5) to verify the amber LED turns on."
  echo "  Changes are persistent across reboots."
else
  echo -e "${YELLOW}${BOLD}  Configuration installed permanently.${NC}"
  echo "  For the kernel to load the new firmware and activate the LED,"
  echo "  please reboot your laptop now:"
  echo -e "  ${BOLD}sudo reboot${NC}"
fi
echo -e "${BLUE}${BOLD}==========================================================${NC}"
