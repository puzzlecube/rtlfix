#!/usr/bin/env julia

rtl_verbose = false			# Verbose mode, print and log everything including debug information
rtl_log = stdout			# File / TTY to log to
rtl_log_is_stdout = true	# Denotes whether or not the log is stdout
rtl_print = true			# Should the script be printing to the terminal aswell as the log (no effect if the log is stdout)
rtl_use_color = true		# Use color when printing to stdout (no visible effect if Julia has colors disabled)
rtl_start_part = 1			# Part to start the loop on
# TODO: Max log size so the log doesn't get huge after a while since this program is very chatty.
rtl_truncate_log = false	# Should the log be truncated when it gets to the max size (defined below)
rtl_log_max_size = 131072	# Max size of the log file before it gets truncated

# » Output & Displaying functions

"""
	Printlnc(::Any,::Any...)
		Print text with a single color code prepended to it to make it colored
		First parameter must be an index of Base.text_colors or an error will be raised
		FIXME: Improper resetting of colors at the end of the text.
"""
function printlnc(color,text...)
	if rtl_use_color == true
		println(Base.text_colors[color],text...)
	else
		println(text...,Base.text_colors[:normal]) # The suffix is needed to ensure that the color resets after each new line.
	end
end
"""
	Printlnc(::Array{Any,1},::Any...)
		Print text with multiple color codes prepended to it to make it colored
		First parameter must be an index of Base.text_colors or an error will be raised
		FIXME: Improper resetting of colors at the end of the text.
"""
function printlnc(colors::Array{Any,1},text...)
	if rtl_use_color == true
		prefix = ""
		for color in colors
			prefix *= String(Base.text_colors[color])
		end
		println(prefix,text...,Base.text_colors[:normal]) # The suffix is needed to ensure that the color resets after each new line. This method in particular will cause odd behavior without it.
	else
		println(text...)
	end
end

# Pre-main loop fatal error printer
"""
	init_fatal_error(::Any...)
		Print a fatal error. No writing to a log file is done becausse this is meant to be run before the log has been validated.
"""
function init_fatal_error(txt...)
	if rtl_use_color == true
		printlnc([:bold,:underline,196],"Fatal error: ",tring(txt...)," Exiting.")
	else
		println("FATAL ERROR: ",string(txt...)," Exiting.")
	end
	exit()
end

#= A note for myself on UNIX file permissions
first 3 digits
Octal	permission
1		execute
2		write
4		read

=#
"""
	check_log()
		Check and see if the log file is what it is supposed to be, a readable and writable file.
"""
function check_log()
	if isdir(rtl_log) == true
		init_fatal_error("Log file check: \"$rtl_log\" is a directory instead of a file.")
	elseif isfile(rtl_log) == true
		open(rtl_log,read=true,write=true,append=filesize(rtl_log) > rtl_log_max_size ? false : true,truncate=filesize(rtl_log) > rtl_log_max_size ? tre : false) do logIO
			if iswritable(logIO) == false
				init_fatal_error("Log file check: \"$rtl_log\" is not writable.")
			elseif isreadable(logIO) == false
				init_fatal_error("Log file check: \"$rtl_log\" cannot be read.")
			end
			if filesize(rtl_log) > rtl_log_max_size
				write(logIO,"*****!***** Begin new session *****\n[NOTE]: Log truncated\n",truncate=true)
			else
				write(logIO,"*****!***** Begin new session *****\n")
			end
		end
	else # What we want... maybe?
		printlnc(148,"Log file check: \"$rtl_log\" does not currently exist. Creating it now.")
		try touch(rtl_log)
		catch problem
			init_fatal_error("Log file check: Could not create log file \"$rtl_log\" successfully. The error thrown was $problem")
		finally
			printlnc(35,"Log file check: \"$rtl_log\" created successfully! Repeating log check to make sure the rest of the requirements are met.")
			check_log()
		end
	end
	return true
end
"""
	logln(::Any)
		Append text to the log file and append a newline.
"""
function logln(linetext...)
	open(rtl_log,read=true,write=true,append=true) do io
		print(io,linetext...,"\n")
	end
end

# Verbose mode output functions
"""
	dbg_note(::Any)
		Note printed and logged only in verbose mode.
"""
function dbg_note(txt...)
	if rtl_verbose == false
		return
	end
	if rtl_print == true || rtl_log_is_stdout == true
		if rtl_use_color == true
			printlnc(12,string(txt...))
		else
			println("Debug [NOTE]: ",string(txt...))
		end
	end
	if rtl_log_is_stdout == false
		logln("Debug [NOTE]: ",string(txt...))
	end
end
"""
	dbg_warning(::Any)
		Warning printed and logged only in verbose mode.
"""
function dbg_warning(txt...)
	if rtl_verbose == false
		return
	end
	if rtl_print == true || rtl_log_is_stdout == true
		if rtl_use_color == true
			printlnc(93,string(txt...))
		else
			println("Debug [WARNING]: ",string(txt...))
		end
	end
	if rtl_log_is_stdout == false
		logln("Debug [WARNING]:",string(txt...))
	end
end
"""
	dbg_error(::Any)
		Error printed and logged only in verbose mode.
		NOTE: Does not exit for you.
"""
function dbg_error(txt...)
	if rtl_verbose == false
		return
	end
	if rtl_print == true || rtl_log_is_stdout == true
		if rtl_use_color == true
			printlnc(199,string(txt...))
		else
			println("Debug [Error]: ",string(txt...))
		end
	end
	if rtl_log_is_stdout == false
		logln("Debug [ERROR]: ",string(txt...))
	end
end

# Normal output functions
"""
	show_note(::Any)
		Print and log a note in the note color.
"""
function show_note(txt...)
	if rtl_print == true || rtl_log_is_stdout == true
		if rtl_use_color == true
			printlnc(:yellow,string(txt...))
		else
			println("[NOTE]: ",string(txt...))
		end
	end
	if rtl_log_is_stdout == false
		logln("[NOTE]: ",string(txt...))
	end
end
"""
	show_error(::Any)
		Print and log a warning in the warning color.
"""
function show_warning(txt...)
	if rtl_print == true || rtl_log_is_stdout == true
		if rtl_use_color == true
			printlnc(214,string(txt...))
		else
			println("[WARNING]: ",string(txt...))
		end
	end
	if rtl_log_is_stdout == false
		logln("[WARNING]:",string(txt...))
	end
end
"""
	show_error(::Any)
		Print and log a error in the error color.
"""
function show_error(txt...)
	if rtl_print == true || rtl_log_is_stdout == true
		if rtl_use_color == true
			printlnc(:red,string(txt...))
		else
			println("[ERROR]: ",string(txt...))
		end
	end
	if rtl_log_is_stdout == false
		logln("[ERROR]: ",string(txt...))
	end
end
"""
	fatal_error(::Any...)
		Print and log a fatal error. Then exit the program.
"""
function fatal_error(txt...)
	if rtl_print == true || rtl_log_is_stdout == true
		if rtl_use_color == true
			printlnc([:bold,:underline,196],"Fatal error: ",string(txt...)," Exiting.")
		else
			println("FATAL ERROR: ",string(txt...)," Exiting.")
		end
	end
	if rtl_log_is_stdout == false
		logln("FATAL ERROR: ",string(txt...),"\n*****!***** Exited without having established a connection due to a fatal error.")
	end
	exit()
end

"""
	printlog(::Any)
		Print and log an event in green.
"""
function printlog(txt...)
	if rtl_print == true || rtl_log_is_stdout
		printlnc(46,string(txt...))
	end
	if rtl_log_is_stdout == false
		logln(string(txt...))
	end
end


# Setup functions
"""
	rtl_help(::bool)
		Help text routine.
"""
function rtl_help(exitAfter=true)
	printlnc(11,"Rtlfix: RTL8723be wireless connection fixing script - version 1.0.0 (License: GPLv3 or newer)")
	printlnc(105,"	** For those of us who installed Linux and are too lazy to buy and install a new one that has open source firmware **	")
	printlnc(202," TODO: Buy a different wireless card, write this down someware!")
	print("\n")
	printlnc(14,"Usage: rtlfix [-v|--verbose] [-l|--log logfile] [-q|--quiet] [-w|--nocolor] [-t|--logmax maxsize] [-h|--help]")
	printlnc(15,"*NOTE: you will need to be root or able to use sudo in order for the script to run properly.*")
	print("\n")
	printlnc(11,"Parameters:")
	printlnc([:blink,11],"	short_name	long_name	description")
	printlnc(2,"	-v		--verbose	Print/log extra information including printing for debugging since the behavior of rtl8723be seems to change with every update to pretty much anything the firmware depends on.")
	printlnc(28,"	-l		--log		Log file, defaults to standard output (print to terminal only) if not specified.")
	printlnc(26,"		logfile must be readable and writable or to be created as a readable and writable regular file.")
	printlnc(2,"	-q		--quiet		Turn off printing to stdout if a log file was specified. If no log is specified this flag has no effect.")
	printlnc(28,"	-w		--nocolor	Turn off colors.")
	printlnc(2,"	-s		--part		Start at specified part to hopefully get connected quicker.")
	printlnc(45,"		A note about this flag: It must be a number from 1 to 6. Even numbers are on a NetworkManager restart. Odd numbers are on an antenna switch.")
	printlnc(47,"			Step 1: Select antenna 0 (sketchy automatic selection)")
	printlnc(46,"			Step 3: Select antenna 1")
	printlnc(47,"			Step 5: Select antenna 2")
	printlnc(46,"			Step 2,4, and 6: NetworkManager restarts")
	printlnc(28,"	-t		--logmax	Maximum size of the log file before it gets truncated. (Be careful what your log is!)")
	printlnc(47,"		maxsize should be a positive integer which will be used as the maximum file size. If the size is 0, it defaults to $rtl_log_max_size (rtl_log_max_size on line 9)")
	printlnc(2,"	-h		--help		Show this help dialog and quit.")
	print("\n")
	printlnc([202,:bold,:reverse],"Every kernel upgrade you might have to revisit your logs for this script. More than likely something will change in the firmware's behavior.")
	printlnc(45,"Have fun dealing with your dumb wireless card when it throws a fit and won't connect at all! (Yeah, right, fun! >:C)")
	if exitAfter == true
		exit()
	end
end


"""
	get_partnum()
		Select which part of the rtlfix loop to start at. Here since rtl_start_part must be a string. Thank you parse function!
"""
function get_partnum(partstr)
	partnum = try parse(UInt8,partstr,base=6) # Use base 6 because anything above it will throw an error which is what we want.
	catch
		show_error("Step is not in range 1 through 6. Exiting.")
	end
	return partnum
end

function select_maxsize(size_string)
	size_uint = try parse(UInt,size_string,base=10)
	catch problem
		fatal_error("Command line arguments check: Invalid logfile maximum size. Must be an integer greater than or equal to 0. Error thrown was $problem.")
	end
	return size_uint
end

validArgs = Array{Bool,1}(undef,length(ARGS)) # Store arguments that have been validated, needed for parameters that have parameters.
dbg_note(validArgs)

# Check and validate command line arguments
for (pos,arg) in pairs(ARGS)
	if rtl_verbose == true
		dbg_note(pos," is ",arg)
	end
	if arg == "-v" || arg == "--verbose"
		global rtl_verbose = true
		global validArgs[pos] = true
	elseif arg == "-l" || arg == "--log"
		global rtl_log_is_stdout = false
		global rtl_log = ARGS[pos+1]
		global validArgs[pos] = true
		global validArgs[pos+1] = check_log()
	elseif arg == "-q" || arg == "--quiet"
		global rtl_print = false
		global validArgs[pos] = true
	elseif arg == "-w" || arg == "--nocolor"
		global rtl_use_color = false
		global validArgs[pos] = true
	elseif arg == "-s" || arg == "--part"
		global rtl_start_part = get_partnum(ARGS[pos+1])
		global validArgs[pos] = true
		global validArgs[pos+1] = true
	elseif arg == "-t" || arg == "--logmax"
		global validArgs[pos] = true
		log_max_size = select_maxsize(ARGS[pos+1])
		global validArgs[pos+1] = true
		if log_max_size > 0
			global rtl_log_max_size = log_max_size
		end
	elseif arg == "-h" || arg == "--help"
		rtl_help(true)
	else
		if validArgs[pos] != true
			show_error("Invalid command line parameter \"$arg\" at index $pos")
			rtl_help(false)
		end
	end
end

# rtlfix main routine utility/convenience functions
"""
	ping()
		Ping Google's DNS and return if it worked or not.
"""
function ping()
	try run(`ping -c 1 8.8.8.8`)
	catch
		return false
	end
	return true
end
"""
	rmrtl()
		Remove rtl8723be from the kernel and return if it worked or not.
"""
function rmrtl()
	try run(`sudo modprobe -r rtl8723be`)
	catch
		return false
	end
	return true
end
"""
	addrtl(::Int64)
		Add the rtl8723be module back into the kernel with the specified antenna selected and return if it worked or not.
"""
function addrtl(antenna=0)
	try run(`sudo modprobe rtl8723be ant_sel=$antenna`)
	catch
		return false
	end
	return true
end
"""
	nwm_restartW()
		Restart NetworkManager service and return if it worked or not.
"""
function nwm_restart()
	try run(`sudo service NetworkManager restart`)
	catch
		return false
	end
	return true
end
"""
	iwlist()
		Scan and list networks and return if it worked or not.
"""
function iwlist()
	try run(`/sbin/iwlist scan`)
	catch
		return false
	end
	return true
end
"""
	test_connections(::Int64,::int64)
		The bones of the script. scan for networks and ping Google's DNS if it winds any. Controls what happens next in the loop
"""
function test_connections(part,tries=0)
	printlog("Checking connection...")
	nextpart = part < 6 ? part+1 : 1
	if iwlist() == true
		printlog("iwlist scan found networks!")
		sleep(1)
		dbg_note("attempting to ping 8.8.8.8")
		if ping() == true
			printlog("Connection Successful!")
			exit()
		else
			if tries < 5
				dbg_note("Ping unsuccessful, retrying.")
				test_connections(part,tries+1)
			else
				show_warning("Ping failed to connect to Google's DNS server 5 times. Are you set up to autoconnect to a network that iwlist scan can find?")
				if rtl_print == true
					printlnc(33,"Are you set up to autoconnect? Type y to continue, anything else will exit rtlfix.")
					choice = readuntil(stdin,"\n")
					if choice == "y"
						dbg_note("Restarting rtlfix loop")
						rtlfix(nextpart)
					else
						show_note("User called for exiting rtlfix before connection has certainly been established.")
						exit()
					end
				else
					show_warning("Printing to console is disabled likely due to it being run as an automated task. Moving on with rtlfix loop to try to fix the issue.")
					rtlfix(nextpart)
				end
			end
		end
	else
		show_warning("iwlist failed to detect any networks. Moving on to part ",nextpart)
		rtlfix(nextpart)
	end
end
"""
	rtlfix(::Int64)
		Main loop of the program. Does all the hard work.
"""
function rtlfix(part=1)
	dbg_note("Starting rtlfix loop part ",part)
	if part == 1 # First try, set the antenna to 0 (automatic)
		printlog("Preparing to remove rtl8723be kernel module.")
		rmrtl()
		printlog("Module removed.")
		sleep(1)
		addrtl(2)
		printlog("Added module")
		sleep(1)
		test_connections(part)
	elseif part == 2 # If that didn't work, reset NetworkManager
		nwm_restart()
		test_connections(part)
	elseif part == 3 # This time select antenna 1
		println("Preparing to remove rtl8723be kernel module.")
		rmrtl()
		printlog("Module removed.")
		sleep(1)
		addrtl(1)
		printlog("Added module")
		sleep(1)
		test_connections(part)
	elseif part == 4 # Try to restart NetworkManager again
		nwm_restart()
		test_connections(part)
	elseif part == 5 # Try selecting antenna 2
		println("Preparing to remove rtl8723be kernel module.")
		rmrtl()
		printlog("Module removed.")
		sleep(1)
		addrtl(0)
		printlog("Added module")
		sleep(1)
		test_connections(part)
	elseif part == 6 # Reset NetworkManager again
		nwm_restart()
		test_connections(part)
	else # What the heck went wrong and made this case get ran?
		dbg_error("Rtlfix loop step is greater than 6 somehow. manually resetting to step 1")
		rtlfix()
	end
end
rtlfix(rtl_start_part)
