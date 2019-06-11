#!/usr/bin/env julia

# Installer for rtlfix.jl as a script into $PATH

# Default vars
default_installpath = "/usr/local/bin"
installpath = default_installpath # Here because default_installpath gets used in the help text
strip_jl_extension = true # TODO: Make it check if it is installed as a standalone binary which will have a stripped file extension.
verbose = false
mode = :install
outfile = "rtlfix"
run_from = Base.pwd()


"""
	Printlnc(::Any,::Any...)
		Print text with olor codes prepended to it to make it colored
		First parameter must be an index of Base.text_colors or an error will be raised
"""
function printlnc(colors,text...)
	prefix=Base.text_colors[:normal]
	if colors isa Array{Any,1}
		for color in colors
			prefix *= Base.text_colors[color]
		end
	else
		prefix *= Base.text_colors[colors]
	end
	println(prefix,text...,Base.text_colors[:normal])
end

function vprintlnc(colors,text...)
	if verbose == true
		printlnc(colors,text...)
	end
end

"""
	show_problem(::Symbol,::Any)
		Function to show a problem/error occured.
"""
function show_problem(problem::Symbol,case::Any)
	problems = Dict{Symbol,String}(
		:update_failed		=>	"Couldn't update the script because of $case being thrown.",
		:install_failed		=>	"Couldn't install the script because of $case being thrown.",
		:failed				=>	"Failed to $case.",
		:no_script			=>	"Can't find $case in $run_from.",
		:installpath_no_rw	=>	"Failed to $case in $installpath. You Don't have read and write access to the install path.\nAre you running as root?",
		:bad_param			=>	"Invalid parameter: \"$case\" specified.",
		:bad_installpath	=>	"$installpath is $case.",
	)
	for (cproblem,text) in pairs(problems)
		if problem == cproblem
			printlnc([:bold,:underline,196],text)
			return (problem,text)
		end
	end
	printlnc(196,"Invalid problem.")
	return (problem,"?")
end
"""
	helptext(::NamedTuple(::Symbol,::Any),::Bool)
		Help text with parameters to determine if it was shown because of some parameter being invalid. and what exactly was invalid.
"""
function helptext(invalid=(problem=:none,case=""),exit_after=true)
	if invalid.problem != :none
		show_problem(invalid.problem,invalid.case)
	end
	printlnc([:bold,47],"Rtlfix script installer")
	print("\n")
	printlnc(44,"This script will install or uninstall rtlfix from your \$PATH.")
	printlnc(44,"By default the script will install in $default_installpath")
	print("\n")
	printlnc(86,"Usage:")
	printlnc(46,"	./script-install.jl [-v|--verbose] [-p|--prefix installpath] [-j|--jl] [install|uninstall]")
	printlnc(45,"Parameters:")
	printlnc(47,"	-h|--help		Show this help text.")
	printlnc(48,"	-j|--jl			Keep the .jl extension on the installed script.")
	printlnc(50,"	-p|--prefix:	Set the path where the script will be installed to. Defaults to $default_installpath if unspecified.")
	printlnc(48,"	-v|--verbose:	Print everything that happens.")
	printlnc(50,"	install:		Install the script to either the installpath provided after the -p|--prefix argument or $default_installpath.")
	printlnc(48,"	uninstall:		Remove the script from the installpath.")
	print("\n")
	printlnc(45,"NOTE: You will probably want to run this as root.")
	if exit_after == true
		cd(run_from)
		exit()
	end
end

"""
	check_installpath()
		Checks if we can read and write to this directory.
"""
function check_installpath()
	permission_testfile=".~_rtlfix_installer_permission_testfile"
	# Checking what this place is.
	if isfile(installpath) == true
		helptext((problem=:bad_installpath,case="is a file instead of a directory"))
	end
	if isdir(installpath) == false
		helptext((problem=:bad_installpath,case="not a directory"))
	end
	# Checking if we can read, and write to this directory.
	try cd(installpath)
	catch problem
		helptext((problem=:bad_installpath,case="unable to be entered because of $problem"))
	end
	cd(installpath)
	try touch(permission_testfile)
	catch problem
		helptext((problem=:installpath_no_rw,case="create a test file (threw $problem)"))
	end
	try open(permission_testfile,read=true,write=true,append=true) do testopen end
	catch problem
		helptext((problem=:installpath_no_rw,case="open test file (threw $problem)"))
	end
	open(permission_testfile,read=true,write=true,append=true) do testIORW
		if isreadable(testIORW) == false
			helptext(problem=:installpath_no_rw,case="read test file")
		end
		if iswritable(testIORW) == false
			helptext((problem=:installpath_no_rw,case="read test file"))
		end
		try write(testIORW,"Testing permissions.")
		catch problem
			helptext((problem=:installpath_no_rw,case="write text to the testfile (threw $problem)"))
		end
	end
	try rm(permission_testfile)
	catch problem
		helptext((problem=:installpath_no_rw,case="delete test file (threw $problem)"))
	end
	if verbose == true
		printlnc(45,"Installation path is readable & writable!")
	end
	return true
end

validArgs = Array{Bool,1}(undef,length(ARGS)) # Store arguments that have been validated, needed for parameters that have parameters.

# Check and validate command line arguments
for (pos,arg) in pairs(ARGS)
	if arg == "-v" || arg == "--verbose"
		global verbose = true
		global validArgs[pos] = true
	elseif arg == "-j" || arg == "--jl"
		global strip_jl_extension = false
		global outfile *= ".jl"
		global validArgs[pos] = true
	elseif arg == "-p" || arg == "--prefix"
		global installpath = ARGS[pos+1]
		global validArgs[pos] = true
		global validArgs[pos+1] = check_installpath()
	elseif arg == "-h" || arg == "--help"
		helptext()
	elseif arg == "install"
		global mode = :install
		global validArgs[pos] = true
	elseif arg == "uninstall"
		global mode = :uninstall
		global validArgs[pos] = true
	else
		if validArgs[pos] != true
			helptext((problem=:bad_param,case="$(ARGS[pos]) at $pos"),false)
		end
	end
end
vprintlnc(83,"Verbose mode enabled.")
print("\n")
if mode == :install
	printlnc(82,"Installing rtlfix as script. Options set to:")
elseif mode == :uninstall
	printlnc(82,"Uninstalling rtlfix script. Options set to:")
end
if strip_jl_extension == true
	printlnc(83,"Strip .jl extension")
else
	printlnc(83,"Leave .jl extension")
end
printlnc(82,"Install into $installpath.")
printlnc(83,"$mode mode.")

if mode == :install
	vprintlnc([:bold,40],"Beginning installation:")
	vprintlnc(10,"Trying to open the script.")
	try
		open("$run_from/rtlfix.jl") do io
		end
	catch problem
		printlnc(208,"Script found: No")
		printlnc(208,"Script updated: No")
		printlnc(208,"Script installed: No")
		print("\n\n\n----------------\n\n\n")
		helptext((problem=:no_script,case="rtlfix.jl (threw $problem)"))
	end
	printlnc(82,"Script found: Yes")
	vprintlnc(10,"Trying to copy the script to $installpath")
	try cp("$run_from/rtlfix.jl","$installpath/rtlfix")
	catch problem
		if problem isa ArgumentError
			vprintlnc(10,"An ArgumentError was thrown, we must be updating an existing script.")
			printlnc(76,"Updating script: Yes")
			try cp("$run_from/rtlfix.jl","$installpath/$outfile",force=true)
			catch problem2
				printlnc(208,"Script updated: No")
				printlnc(208,"Script installed: No")
				print("\n\n\n----------------\n\n\n")
				helptext((problem=:update_failed,case="$problem2"))
			finally
				printlnc(83,"Script updated: Yes")
			end
		else
			printlnc(208,"Script installed: No")
			print("\n\n\n----------------\n\n\n")
			helptext((problem=:install_failed,case="$problem"))
		end
	finally
		printlnc(82,"Script installed: Yes")
	end
	printlnc([:bold,83],"Installed rtlfix script in $installpath successfully! Have fun!")
	vprintlnc([:bold,40],"Installation complete!")
elseif mode == :uninstall
	vprintlnc([:bold,40],"Beginning uninstallation:")
	vprintlnc(10,"Entering installation directory.")
	try cd(installpath)
	catch problem
		printlnc(208,"Entered installation directory: No")
		printlnc(208,"Found script: No")
		printlnc(208,"Script removed: No")
		print("\n\n\n----------------\n\n\n")
		helptext((problem=:failed,case="change directory because of $problem being thrown"))
	end
	printlnc(82,"Entered installation directory: Yes")
	vprintlnc(10,"Checking for the script.")
	if isfile("$installpath/$outfile") == false
		printlnc(208,"Founc script: No")
		printlnc(208,"Script removed: No")
		print("\n\n\n----------------\n\n\n")
		helptext((problem=:failed,case="find $outfile"))
	end
	printlnc(83,"Founc script: Yes")
	try rm("$installpath/$outfile")
	catch problem
		printlnc(208,"Script removed: No")
		print("\n\n\n----------------\n\n\n")
		helptext((problem=:failed,case="delete $outfile because of $problem being thrown."))
	end
	printlnc(82,"Script removed: Yes")
	printlnc([:bold,83],"Successfully uninstalled $outfile from installpath. Have fun!")
	vprintlnc([:bold,40],"Uninstallation complete!")
end
