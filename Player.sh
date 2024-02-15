#!/bin/bash
# A simple playerctl wrapper
# Author: KKV9

# Set your menu command here
MENU="rofi"
# Set album art status
ALBUM_ART=true
# Set album art path
ALBUM_ART_PATH=~/.cache/album-art.jpg
# Set menu prompt
PROMPT="PlayerControl"

# Exit if no media is playing
check=$(playerctl metadata)
if [ -z $check ]; then
	exit 0
fi

refresh() {
	# Remove old album art
	rm -f $ALBUM_ART_PATH
	if [ "$ALBUM_ART" == true ] && [ "$MENU" == "rofi" ]; then
		# Sleep to allow album art to load
		sleep 0.2
		# Get album art, trim & resize it
		curl $(playerctl metadata --format "{{mpris:artUrl}}") >$ALBUM_ART_PATH && magick mogrify -define trim:percent-background=0% -trim +repage -resize 500x300! $ALBUM_ART_PATH
	fi
}

toggle_loop() {
	# Toggle loop status
	if [[ $(playerctl loop) == "Playlist" ]]; then
		playerctl loop Track
	elif [[ $(playerctl loop) == "Track" ]]; then
		playerctl loop None
	else
		playerctl loop Playlist
	fi
}

# Set menu arguments
case $MENU in
"rofi")
	menu_args=(-dmenu -l 7 -p "$PROMPT")
	refresh
	;;
"fuzzel" | "wofi")
	menu_args=(-d -l 7 -p "$PROMPT")
	;;
"tofi")
	menu_args=(--prompt-text "$PROMPT")
	;;
"dmenu")
	menu_args=(-p "$PROMPT")
	;;
*)
	menu_args=()
	;;
esac

# Loop if option is selected
while true; do

	# Get currently playing
	current=$(playerctl metadata --format "{{artist}} - {{title}}")

	# Set menu options
	opts=("▶️ $current" "⏭️ next track" "⏮️ previous track" "❌ loop" "❌ shuffle" "➡️ shift source forward" "⬅️ shift source backword")

	# Show play-pause status
	if [[ $(playerctl status) != "Playing" ]]; then
		opts[0]="⏸️ $current"
	fi

	# Show loop status
	if [[ $(playerctl loop) == "Playlist" ]]; then
		opts[3]="🔁 loop"
	elif [[ $(playerctl loop) == "Track" ]]; then
		opts[3]="🔂 loop"
	fi

	# Show shuffle status
	if [[ $(playerctl shuffle) == "On" ]]; then
		opts[4]="🔀 shuffle"
	fi

	# Menu prompt
	selection=$(printf '%s\n' "${opts[@]}" | $MENU ${menu_args[@]})
	noRefresh=false

	# Handle selection
	case $selection in
	"${opts[0]}")
		playerctl play-pause
		noRefresh=true
		;;
	"${opts[1]}")
		playerctl next
		;;
	"${opts[2]}")
		playerctl previous
		;;
	"${opts[3]}")
		toggle_loop
		noRefresh=true
		;;
	"${opts[4]}")
		playerctl shuffle toggle
		noRefresh=true
		;;
	"${opts[5]}")
		playerctld shift
		;;
	"${opts[6]}")
		playerctld unshift
		;;
	*)
		break
		;;
	esac

	# Refresh album art if new song is playing
	if [ "$noRefresh" == false ]; then
		refresh
	fi

done
