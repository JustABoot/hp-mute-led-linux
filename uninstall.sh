#!/usr/bin/env bash
#
# HP Mute LED Uninstaller for Linux
# Author: JustABoot
# License: MIT
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}==========================================================${NC}"
echo -e "${BOLD}  HP Mute LED Fix Uninstaller${NC}"
echo -e "${BLUE}${BOLD}==========================================================${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[Error] This script must be run as root (sudo).${NC}"
  echo "Run: sudo $0"
  exit 1
fi

echo -e "${YELLOW}[1/3] Removing modprobe configuration file...${NC}"
if [ -f /etc/modprobe.d/hp-mute-led.conf ]; then
  rm -f /etc/modprobe.d/hp-mute-led.conf
  echo -e "${GREEN}  ✓ /etc/modprobe.d/hp-mute-led.conf removed.${NC}"
else
  echo "  - /etc/modprobe.d/hp-mute-led.conf not found."
fi

echo -e "${YELLOW}[2/3] Removing ALSA firmware patch file...${NC}"
if [ -f /lib/firmware/alsa-hp-mute.fw ]; then
  rm -f /lib/firmware/alsa-hp-mute.fw
  echo -e "${GREEN}  ✓ /lib/firmware/alsa-hp-mute.fw removed.${NC}"
else
  echo "  - /lib/firmware/alsa-hp-mute.fw not found."
fi

echo -e "${YELLOW}[3/3] Regenerating initramfs to restore default state...${NC}"
if command -v dracut >/dev/null 2>&1; then
  dracut -f
elif command -v update-initramfs >/dev/null 2>&1; then
  update-initramfs -u
elif command -v mkinitcpio >/dev/null 2>&1; then
  mkinitcpio -P
fi
echo -e "${GREEN}  ✓ Initramfs regenerated.${NC}"

echo ""
echo -e "${GREEN}${BOLD}Uninstallation complete. Please reboot your system to restore the default kernel state.${NC}"
