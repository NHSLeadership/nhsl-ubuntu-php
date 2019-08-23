#!/bin/bash
printf "\033[1;34m    _   ____  _______   _        _
   / | / / / / / ___/  | |      / \
  /  |/ / /_/ /\__ \   | |     / _ \
 / /|  / __  /___/ /   | |___ / ___ \
/_/ |_/_/ /_//____/    |_____/_/   \_\ \033[0m\n\n"

printf "Entered container environment...\n\n"

# Container info:
printf "%-30s %-30s\n" "Site:" "$SITE_NAME"
printf "%-30s %-30s\n" "Branch:" "$SITE_BRANCH"
printf "%-30s %-30s\n" "Environment:" "$ENVIRONMENT"
printf "%-30s %-30s\n" "Role: " "$CONTAINERROLE"

if [ "$CONTAINERROLE" == "web" ]; then
  // call web script
elif ["$CONTAINERROLE" == "worker" ]; then
  // call worker script
else
  // call web script
fi