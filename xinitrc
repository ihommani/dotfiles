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
userresources=$HOME/.Xresources
if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

# Démarrage de xscreenSaver
/usr/bin/xscreensaver -no-splash &

#démarrage du Daemon Urxvt
urxvtd -q -o -f

# Disable beep sound
xset -b

#demarrage de mpd
#mpd

#Demarrage de devmon pour le montage automatique de périphériques
#devmon &

# Start tmux session in the background
urxvt -e bash -c "tmux -q has-session && exec tmux attach-session -d || exec tmux new-session -n$USER -s$USER@$HOSTNAME" &

#start chromium
#chromium &
setxkbmap fr
#Map capslock on escape key
setxkbmap -option caps:escape & 

#Export some envvar for idea
export IDEA_JDK=~/bin/jdk1.7.0_71

# Disable touchpad while typing
syndaemon -d -t -K -i 2

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

