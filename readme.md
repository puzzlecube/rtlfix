Rtlfix - A way to tell your Rtl8723be wireless card that it has two choices, My way or my way.

Rtlfix is a very configurable super automatic way to force your Rtl8723be wireless card to do what it is supposed to for WIFI connection to happen.
The script will execute a loop of operations which are as follows:
	removing the rtl8723be kernel module.
	Re-add it with a different antenna selected.
	Try to make sure there is an internet connection.
	If it successfully pings 8.8.8.8 (Google's DNS server) the script will finish.
	If it fails 5 times it will (by default) prompt you asking if you should be auto-connecting to a network.
	If you type y when it prompts you if you want to continue or if you disable printing to stdout (useful for automatic running) it will retry removing rtl8723be from the kernel and adding it back with a different antenna selected.
The script is set up so that it can be used as an automated task where you never have to think about what it is doing AGAIN! Rather or not 100& autonomy works right now remains to be seen.
NOTE: Results WILL vary and you will probably notice your results changing every kernel update or just randomly for no apparent reason at all.
Colors are disablable but I figured why not make the most frustrating part of our Linux setup just a tad brighter with some colors! But if your terminal emulator or TTY gets mad about it they can be disabled either by julia or by this script.

Requirements to use it (hopefully) successfully are:
	Julia (>=1.0.3) (Earlier versions of julia may or may not (likely not) work but have not been tested)
	A Linux install with NetworkManager managing the network (New enough to support the rtl8723be firmware)
	rtl8723be firmware and kernel module(s) (duh)
	The ability to use sudo
	A network set up for automatic connection

For the most colorful help text in all of your bash_history you can type ./rtlfix -h or ./rtlfix --help from this directory.
This script was written because I got tired of having to manually run 2 different shell scripts to force-reset the wireless card and reset NetworkManager

TODO list:
	Buy a new wireless card and replace this one so I don't have to deal with this any more.
	Maybe add other rtl cards since it seems the entire Realtek line of cards have issues on several if not all distros
	Add the ability to supply additional flags to the modprobe command that adds the kernel module back again
	FInd better ways to determine if the card is running than requiring you to have a network that NetworkManager is set up to autoconnect to.
	Could probably be faster.

Known bugs:
	One check whines about the startign step for some reason.
	At the continue prompt the color carries over if there is an error.

Other notes: This entire script was written also as a test of my julia skills with NO access to the internet until the first successful run so things may be a little bit odd since methods() and the REPL were my only documentation.

In theory this could be compiled into a standalone binary and not require julia if myself or someone else released binaries but for now it works great as a script.
