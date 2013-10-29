#!/bin/sh
# Inspired by the MS-DOS command 'net':	1996.xx.yy
#-------------------------------------------------
# Original concept of Script-Tools:	2011.05.01
# First rework of Script-Tools: 	2011.08.16
# Second rework of Script-Tools: 	2011.11.11
# Third rework of Script-Tools: 	2012.05.10
# Fourth rework of Script-Tools: 	2013.10.01
#-------------------------------------------------
#
#	sea's Script Tools: The 4th Generation
#	File Description:	
#	File Version:       0.7
#	Author:             Simon A. Erat (sea) <erat.simon AT gmail.com>
#	Created (y.m.d):    2012.04.10
#	Changed:            2013.09.29
#	License:            GPL v3
#	Modified By:        
#	Resource:           
#	Special Thanks:     
# ------------------------------------------------------------------------------
#
#	Variables
#	This is the default path, if it does not exist,
#	script-tools will create a symlink from its current location
#
	stDir=/usr/share/script-tools
	sst=st
	stVer=0.9.0
#
#	Subs
#
	sGetRunDir() { # ARGS
	# This will return the path where script tools is executed from.
	# Will probably fail as soon $stDir/$sst is symlinked to /usr/bin
		olddir=$(pwd)
		isSH=false
		comparewith="sh $(which sh)"

		for s in $comparewith; do
		    if [[ ! "$isSH" = "true" ]];then
		      [[ "$0" = "$s" ]] && isSH=true
		    fi
		done

		if [[ true = $isSH ]] 
		then	cd $(dirname $1)
			echo $(pwd)
		else	cd $(dirname $0)
			echo $(pwd)
		fi
		cd $olddir
		return 0
	}
#
#	Path check
#	This prepares the environment even if it was retrieved
#	by GIT or by Tarball
#
	if [[ ! -d "$stDir" ]]
	then	echo "$stDir does not exist, creating symlink"
		sudo ln -sf $(sGetRunDir $0 $@) "$stDir"
	fi
	if [[ ! -f "/usr/bin/$sst" ]]
	then	echo "/usr/bin/$sst does not exist, creating symlink"
		sudo ln -sf "$stDir/$sst" "/usr/bin/$sst"
	fi
#
#	Loading the framework
#	/usr/share/script-tools/st.cfg 'exists' now, so load it
#
	source "$stDir/$sst.cfg"
	#source /usr/share/script-tools/st.cfg
#
#	Display
#
	args=$@		# For default.$foldername files that are sourced with function sMenu
			# because of arguments and are therefore refering to another $@
	#sH "$@"
	if [[ ! -z $1 ]]
	then	parseargs $@
	else	sH "$@"
		sMenu "$ST_MENU_DIR"
	fi
echo
sea_select a b c
press