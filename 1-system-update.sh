#!/bin/bash
set -e

echo "Step 1: Update and reboot"
sudo apt update && sudo apt upgrade -y

echo "Reboot the system before continuing. Press ENTER after reboot to continue..."
read -p "Press ENTER to continue after reboot..."



# After reboot, user should run:
# rocminfo
# clinfo
