#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

#if [ -d /etc/X11/xinit/xinitrc.d ]; then
#  for f in /etc/X11/xinit/xinitrc.d/*; do
 #   [ -x "$f" ] && . "$f"
 # done
 # unset f
#fi

#démarrage du Daemon Urxvt
urxvtd -q -o -f

#demarrage de mpd
#mpd

#Demarrage de devmon pour le montage automatique de périphériques
#devmon &

# Start tmux session in the background
#urxvt -e bash -c "tmux attach -d -t mysession" &
# See how to put a loop
#urxvtc -g 81x24+0+0 -e tmux attach-session -t 0
#/usr/bin/xscreensaver -no-splash &

#start chromium
#chromium &
setxkbmap fr
#Map capslock on escape key
setxkbmap -option caps:escape & 

# exec startkde
# exec startxfce4
# ...or the Window Manager of your choice
DEFAULT_SESSION=awesome
case $1 in
    bspwm)  
	sxhkd &
	exec bspwm
	;;
    awesome)   exec awesome;;
    *)       exec $DEFAULT_SESSION;;
 esac

