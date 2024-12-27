#!/bin/bash

# Function to display help
show_help() {
  echo "Usage: $0 [create|remove]"
  echo "  create - Create a combined sink from selected sinks."
  echo "  remove - Remove the combined sink named 'multi-sink'."
}

# Function to create the combined sink
create_sink() {
  echo "Available sinks:"
  
  # List sinks and capture them into an array
  sinks=($(pactl list short sinks | awk '{print $2}'))

  for i in "${!sinks[@]}"; do
    echo "$((i + 1)). ${sinks[i]}"
  done

  # Prompt the user to select multiple sinks
  echo "Select sinks by their numbers separated by spaces (e.g., 1 2 3):"
  read -p "Your selection: " selection

  # Validate and convert user input into sink names
  selected_sinks=()
  for index in $selection; do
    if ! [[ $index =~ ^[0-9]+$ ]] || [ $index -le 0 ] || [ $index -gt ${#sinks[@]} ]; then
      echo "Invalid selection: $index. Please enter valid numbers."
      exit 1
    fi
    selected_sinks+=("${sinks[index-1]}")
  done

  # Check if at least two sinks are selected
  if [ ${#selected_sinks[@]} -lt 2 ]; then
    echo "You must select at least two sinks."
    exit 1
  fi

  # Create the combined sink
  slave_sinks=$(IFS=,; echo "${selected_sinks[*]}")
  echo "Creating combined sink 'multi-sink' with sinks: $slave_sinks..."
  pactl load-module module-combine-sink sink_name=multi-sink slaves="$slave_sinks"
  pactl set-default-sink multi-sink
  echo "Combined sink 'multi-sink' created and set as default."
}

# Function to remove the combined sink
remove_sink() {
  # Find the module ID of the 'multi-sink'
  module_id=$(pactl list modules short | grep "module-combine-sink" | awk '{print $1}')

  if [ -z "$module_id" ]; then
    echo "No 'multi-sink' found to remove."
  else
    # Unload the module
    echo "Removing combined sink 'multi-sink'..."
    pactl unload-module "$module_id"
    echo "Combined sink 'multi-sink' removed."
  fi
}

# Main script logic
if [ "$#" -ne 1 ]; then
  show_help
  exit 1
fi

case "$1" in
  create)
    create_sink
    ;;
  remove)
    remove_sink
    ;;
  *)
    show_help
    exit 1
    ;;
esac

