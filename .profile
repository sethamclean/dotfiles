# ~/.profile: executed by Bourne-compatible login shells.
bashrc=~/.bashrc
if [ "$BASH" ]; then
	if [ -x "$(which zsh)" ]; then
		exec zsh
	elif [ -f ${bashrc} ]; then
		. ${bashrc}
	fi
fi

# mesg n 2> /dev/null || true
