#!/bin/sh
# Color Balance for Onion (Miyoo Mini Plus) v1.0.1
# https://github.com/TR2NLG/onion-color-balance
# Adjusts the warmth and the red, green and blue gains of the display with a
# live preview. Saved values are applied through Onion's own blue light filter,
# so Onion keeps applying them at boot and when the filter is switched on or off.

cd "$(dirname "$0")"
sysdir="${CB_SYSDIR:-/mnt/SDCARD/.tmp_update}"
DISP="${CB_DISP:-/proc/mi_modules/mi_disp/mi_disp0}"
PROMPT="${CB_PROMPT:-$sysdir/bin/prompt}"
INFOPANEL="${CB_INFOPANEL:-$sysdir/bin/infoPanel}"
TESTDIR="$(pwd)/testimages"
SHOTS="${CB_SHOTS:-/mnt/SDCARD/Screenshots}"
BLF="$sysdir/script/blue_light.sh"
CFG="$sysdir/config/display"
VALUES="$CFG/colorBalance"          # "R G B", read by the hook in blue_light.sh
STATE="$CFG/colorBalanceState"      # "warmth red_offset green_offset blue_offset boost"
TITLE="Color Balance"
export LD_LIBRARY_PATH="/lib:/config/lib:/mnt/SDCARD/miyoo/lib:$sysdir/lib:$sysdir/lib/parasyte"

ask() { # $1 message, $2 selected index, then the options; sets ANSWER
	msg="$1"; sel="$2"; shift 2
	LD_PRELOAD=/mnt/SDCARD/miyoo/lib/libpadsp.so "$PROMPT" -t "$TITLE" -m "$msg" -s "$sel" "$@"
	ANSWER=$?
}

num() { case "${1#-}" in ''|*[!0-9]*) echo "$2" ;; *) echo "$1" ;; esac; }
clamp() { v=$1; [ "$v" -lt "$2" ] && v=$2; [ "$v" -gt "$3" ] && v=$3; echo "$v"; }

# Hook in Onion's blue light script: our values replace the fixed filter levels.
ensure_hook() {
	[ -f "$BLF" ] || return 1
	grep -q "COLOR_BALANCE_HOOK" "$BLF" && return 0
	# the script has no hook (first start, or Onion replaced it in an update):
	# keep exactly this version as backup, so a restore never brings back an older script
	cp "$BLF" "$BLF.orig"
	awk '
		{ print }
		/^setRGBValues\(\) \{/ && !done {
			print "    # COLOR_BALANCE_HOOK: values saved by the Color Balance app replace the filter levels"
			print "    if [ -s \"$sysdir/config/display/colorBalance\" ]; then"
			print "        read endR endG endB < \"$sysdir/config/display/colorBalance\" && return 0"
			print "    fi"
			done = 1
		}' "$BLF" > "$BLF.tmp" && mv "$BLF.tmp" "$BLF" && chmod +x "$BLF"
	grep -q "COLOR_BALANCE_HOOK" "$BLF"
}

show_images() { # $1 folder; A or right = next image, B or left = back, MENU = return
	found=0
	for f in "$1"/*.png "$1"/*.jpg "$1"/*.jpeg "$1"/*.bmp; do
		[ -f "$f" ] && { found=1; break; }
	done
	if [ "$found" = 0 ]; then
		if [ "$1" = "$SHOTS" ]; then
			ask 'No screenshots yet.\nIn a game, hold MENU\nand press POWER.\nThen come back here.' 0 "OK"
		else
			ask 'No test images found\nin the app folder.' 0 "OK"
		fi
		return
	fi
	LD_PRELOAD=/mnt/SDCARD/miyoo/lib/libpadsp.so "$INFOPANEL" -d "$1" > /dev/null 2>&1
}

# Remove the four hook lines from the current script (no restore of an old backup).
remove_hook() {
	grep -q "COLOR_BALANCE_HOOK" "$BLF" || return 0
	awk '/COLOR_BALANCE_HOOK/ { skip = 4 } skip > 0 { skip--; next } { print }' "$BLF" > "$BLF.tmp" || return 1
	# if the result matches the backup (same Onion version), use the backup for a byte exact original
	if [ -f "$BLF.orig" ] && awk '1' "$BLF.orig" | cmp -s - "$BLF.tmp"; then
		cp "$BLF.orig" "$BLF.tmp"
	fi
	mv "$BLF.tmp" "$BLF" && chmod +x "$BLF"
	! grep -q "COLOR_BALANCE_HOOK" "$BLF"
}

remove_from_onion() {
	ask 'Remove Color Balance\nfrom Onion?\nColors are reset and the\nblue light filter turns off.' 1 "Yes, remove" "No"
	[ "$ANSWER" = 0 ] || return 1
	rm -f "$VALUES" "$STATE"
	if remove_hook; then
		sync
		run_blf disable
		R=128; G=128; B=128; apply_live
		ask 'Removed.\nDelete the folder\nApp/ColorBalance\nto finish.' 0 "OK"
	else
		ask 'The lines in blue_light.sh\ncould not be removed.\nSee the README to do it\nby hand.' 0 "OK"
	fi
	return 0
}

run_blf() { # run Onion's script, retry once if it is busy
	"$BLF" "$1" > /dev/null 2>&1 || { sleep 1; "$BLF" "$1" > /dev/null 2>&1; }
}

load_state() {
	set -- $(cat "$STATE" 2>/dev/null) 0 0 0 0 0
	W=$(num "$1" 0); dR=$(num "$2" 0); dG=$(num "$3" 0); dB=$(num "$4" 0); BOOST=$(num "$5" 0)
}

compute() {
	W=$(clamp "$W" 0 100)
	dR=$(clamp "$dR" -96 64); dG=$(clamp "$dG" -96 64); dB=$(clamp "$dB" -96 64)
	R=$((128 + dR))
	G=$((128 - W * 28 / 100 + dG))
	B=$((128 - W * 56 / 100 + dB))
	MAXV=128; [ "$BOOST" = 1 ] && MAXV=192
	R=$(clamp "$R" 32 "$MAXV"); G=$(clamp "$G" 32 "$MAXV"); B=$(clamp "$B" 32 "$MAXV")
	# keep the offsets in line with what is shown, so a capped channel never builds up hidden steps
	dR=$((R - 128)); dG=$((G - (128 - W * 28 / 100))); dB=$((B - (128 - W * 56 / 100)))
}

apply_live() {
	[ -e "$DISP" ] || { "$sysdir/bin/disp_init" & sleep 2.5; }
	echo "colortemp 0 0 0 0 $B $G $R" > "$DISP"
}

save_and_apply() {
	mkdir -p "$CFG"
	echo "$W $dR $dG $dB $BOOST" > "$STATE"
	if [ "$R" = 128 ] && [ "$G" = 128 ] && [ "$B" = 128 ]; then
		rm -f "$VALUES"
		sync
		run_blf disable
	else
		echo "$R $G $B" > "$VALUES"
		sync
		run_blf enable
	fi
	if [ -f "$sysdir/config/.blf" ] && [ -f "$VALUES" ]; then
		ask 'Blue light schedule is on:\ncolors only apply in its\ntime window. Switch it off\nin Tweaks to use them all day.' 0 "OK"
	fi
}

restore_saved() {
	if [ -f /tmp/.blfOn ] || [ -f "$sysdir/config/.blfOn" ]; then
		run_blf enable
	else
		R=128; G=128; B=128; apply_live
	fi
}

rgb_menu() {
	s=0
	while true; do
		compute; apply_live
		if [ "$BOOST" = 1 ]; then b="Above neutral: allowed"; else b="Above neutral: off (max 128)"; fi
		ask "Red $R   Green $G   Blue $B" "$s" \
			"Red +1" "Red -1" "Green +1" "Green -1" "Blue +1" "Blue -1" "Test images" "My screenshots" "$b" "Back"
		r=$ANSWER
		case "$r" in
			0) dR=$((dR + 1)) ;; 1) dR=$((dR - 1)) ;;
			2) dG=$((dG + 1)) ;; 3) dG=$((dG - 1)) ;;
			4) dB=$((dB + 1)) ;; 5) dB=$((dB - 1)) ;;
			6) show_images "$TESTDIR" ;;
			7) show_images "$SHOTS" ;;
			8) if [ "$BOOST" = 1 ]; then BOOST=0; else BOOST=1; fi ;;
			*) return ;;
		esac
		s=$r
	done
}

# main
if ! ensure_hook; then
	ask "Onion's blue light script\\nwas not found or could\\nnot be prepared.\\nNothing was changed." 0 "OK"
	exit 1
fi
load_state
sel=0
while true; do
	compute; apply_live
	ask "Warmth $W %   R $R  G $G  B $B" "$sel" \
		"Warmer +5" "Warmer +1" "Cooler -1" "Cooler -5" "Red, green, blue ..." "Test images" "My screenshots" "Reset to neutral" "Save and exit" "Exit without saving" "Remove from Onion"
	r=$ANSWER
	case "$r" in
		0) W=$((W + 5)) ;; 1) W=$((W + 1)) ;; 2) W=$((W - 1)) ;; 3) W=$((W - 5)) ;;
		4) rgb_menu ;;
		5) show_images "$TESTDIR" ;;
		6) show_images "$SHOTS" ;;
		7) W=0; dR=0; dG=0; dB=0 ;;
		8) compute; save_and_apply; exit 0 ;;
		10) remove_from_onion && exit 0 ;;
		*) restore_saved; exit 0 ;;
	esac
	[ "$r" -le 7 ] && sel=$r
done
