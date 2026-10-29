# HP Mute LED Fix for Linux 💡🔇

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://kernel.org)
[![Tested on](https://img.shields.io/badge/Audio%20Codec-Realtek%20ALC236-orange.svg)](#)
[![Distros](https://img.shields.io/badge/Distros-Fedora%20%7C%20Ubuntu%20%7C%20Debian%7C%20Arch-brightgreen.svg)](#)

A permanent and reliable fix to enable the hardware **amber mute indicator LED** on **HP laptops (15-dw0xxx, 15s series, and related models)** equipped with the **Realtek ALC236** audio codec across Linux distributions (Fedora, Ubuntu, Debian, Arch Linux, Linux Mint, etc.).

---

## 🔍 The Problem (Why people give up in forums)

In countless Linux forums (AskUbuntu, Reddit, Arch Forums, HP Community), the typical consensus is:
> *"The mute key LED on HP laptops simply does not work under Linux because it requires proprietary Windows drivers / HP Omen / ACPI software."*

**This is FALSE.**

The hardware LED is **fully supported natively** by the Linux kernel. The issue is a simple missing hardware match in the ALSA Realtek driver quirk table (`sound/pci/hda/patch_realtek.c`):

1. The Linux kernel already includes the quirk:
   ```c
   SND_PCI_QUIRK(0x103c, 0x85f0, "HP Laptop 15-dw0xxx", ALC236_FIXUP_HP_MUTE_LED_COEFBIT2),
   ```
2. However, HP manufactured thousands of laptops in the **HP Laptop 15-dw0xxx** line with **Subsystem ID `103c:85f5`** (instead of `85f0`).
3. Because the exact ID is not matched, the kernel loads a generic sound profile without initializing the specific coefficient bit (`COEFBIT2`) that toggles the mute LED.

---

## ⚡ The Solution

You do **not** need to recompile the kernel. This solution utilizes ALSA's built-in firmware patch mechanism (`snd-hda-intel`) to tell the kernel to apply the `103c:85f0` quirk profile to your sound card.

Once applied:
- The kernel automatically registers `/sys/class/leds/hda::mute`.
- The native kernel trigger `[audio-mute]` is assigned.
- When you mute the audio (via the physical F5 key, PipeWire, PulseAudio, GNOME, or KDE), the **amber LED lights up immediately**.

---

## 🚀 Quick Installation (1 Step)

Clone this repository and run the installer with `sudo`:

```bash
git clone https://github.com/JustABoot/hp-mute-led-linux.git
cd hp-mute-led-linux
chmod +x install.sh
sudo ./install.sh
```

The installer will:
1. Create `/lib/firmware/alsa-hp-mute.fw` with the ALC236 codec mapping.
2. Create `/etc/modprobe.d/hp-mute-led.conf` to load the patch on every boot.
3. Update the `initramfs` (automatically detects **dracut**, **update-initramfs**, or **mkinitcpio**).
4. Apply the patch live by reloading the HDA codec without requiring an immediate reboot.

Press your **Mute (F5)** key to verify the orange LED is working!

---

## 🛠️ Verification

To verify that the kernel successfully detected and bound the LED:

```bash
# Check if the LED device exists:
ls -l /sys/class/leds/hda::mute

# Check the active trigger (should show brackets around [audio-mute]):
cat /sys/class/leds/hda::mute/trigger
```

---

## 📖 Manual Installation (Step by Step)

If you prefer applying the changes manually without running the script:

1. **Create the ALSA firmware patch file:**
   ```bash
   sudo mkdir -p /lib/firmware
   sudo tee /lib/firmware/alsa-hp-mute.fw > /dev/null << 'EOF'
   [codec]
   0x10ec0236 0 0

   [model]
   103c:85f0

   [subsystem_id]
   0x103c85f0
   EOF
   ```

2. **Configure modprobe options:**
   ```bash
   sudo tee /etc/modprobe.d/hp-mute-led.conf > /dev/null << 'EOF'
   options snd-hda-intel model=103c:85f0 patch=alsa-hp-mute.fw
   EOF
   ```

3. **Update your initramfs:**
   - **Fedora / RHEL / CentOS (dracut):**
     ```bash
     sudo dracut -f --include /lib/firmware/alsa-hp-mute.fw /lib/firmware/alsa-hp-mute.fw
     ```
   - **Ubuntu / Debian / Linux Mint (update-initramfs):**
     ```bash
     sudo update-initramfs -u
     ```
   - **Arch Linux / Manjaro (mkinitcpio):**
     ```bash
     sudo mkinitcpio -P
     ```

4. **Reboot your system:**
   ```bash
   sudo reboot
   ```

---

## 🗑️ Uninstallation

If you ever wish to revert all changes:

```bash
sudo ./uninstall.sh
sudo reboot
```

---

## 💻 Tested Compatibility

- **Hardware:**
  - HP Laptop 15-dw0xxx / 15-dw0000 / 15-dw0083wm
  - Realtek ALC236 Codec (`0x10ec0236`)
  - Subsystem ID: `103c:85f5`
- **Operating Systems:**
  - Fedora Linux (Tested on Fedora 40, 41, 42, 43, 44)
  - Ubuntu (20.04 LTS, 22.04 LTS, 24.04 LTS, 26.04 LTS)
  - Debian 11 / 12 / 13
  - Arch Linux / Manjaro
  - Linux Mint / Pop!_OS
  - openSUSE Tumbleweed & Leap

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
