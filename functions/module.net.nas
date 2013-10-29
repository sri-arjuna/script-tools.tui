
#
#	sea's dev nas is aimed to assist home users
#	to easy access their local NAS.
#
#	This script is written with best intention to help, 
#	but there is NO warranty, garanty and I deny ANY responsiblity
#	that may or may not affect your system.
#
#	Lisence:        GPL v3
#	Author:         Simon A. Erat (sea)
#	Release Date:   2012.06.12
#	Changed Date:	2013.07.25
#	script_version=0.9
#
#
#	Vars
#
#	Default Directory & File
#
	export SMB_LOG_DIR=/var/log/samba
	export SMB_CONF=/etc/samba/smb.conf
#
#	Change your personal default values here if you like
#	Or provide a config file in $ST_USER_NAS/$lbl
#
	if [ -z $NAS_DEFAULT_IP ]
	then	NAS_DEFAULT_IP=192.168.1.10
		NAS_DEFAULT_NAME=MYNAS
		NAS_DEFAULT_SHARE=Public
		NAS_DEFAULT_DOMAIN=WORKGROUP
		NAS_DEFAULT_MOUNTPOINT=/mnt
		[ ! -z $USER ] && [ ! root = "$USER" ] &&  NAS_DEFAULT_USR=$USER
	fi
#
# 	lbl_nas is only for the config file
# 	while nas_str_* will be for the real smb.conf (much, much later, if ever) 
#
	LBL_NAS_Q="Type the "
	LBL_NAS_IP="nas_ip"
	LBL_NAS_SHARE="nas_share"
	LBL_NAS_NAME="nas_dev_name"
	LBL_NAS_USR="username"
	LBL_NAS_DOM="domain"
	LBL_NAS_PW="password"
#
#	Subs
	NAS_Select() { # 
	# Select among files located in \$ST_USER_NAS
	# which is $HOME/bin/$USER-libs/nas by default
	#
	#	Get a list of available projects
	#
		NAS_DEVICES=""
		[ ! -d $ST_USER_NAS ] && mkdir -p $ST_USER_NAS
		cd $ST_USER_NAS
		tmp=$(ls)
		#echo $tmp
		for t in $tmp
		do	NAS_DEVICES="$NAS_DEVICES $t"
		done
		#echo $NAS_DEVICES
	#
	#	Check if only one location is available
	#
		checkVal="$(echo $NAS_DEVICES|awk '{print $1}')"
		#echo "$checkVal ; $NAS_DEVICES"
		if [ "$(echo $NAS_DEVICES)" = "$checkVal" ]
		then	echo $NAS_DEVICES 
			return 0
		fi
		if [ "" = "$(echo $NAS_DEVICES)" ] 
		then	echo "No NAS configuration found!"
			ask "Create one now?" && \
				NAS_New || return 1
		fi
		select thisPrj in $NAS_DEVICES
			do	echo $thisPrj
				return 0
		done
	}
	
	NAS_Edit() { # [ LABEL ]
	# If no label is provided it asks the user to choose one
	# Afterwards its asking to open cred or conf file
		[ -z $1 ] && tmp=$(NAS_Select)| tmp=$1
		ask "Edit config file (y) or credentials (n)?" && \
		sEdit $ST_USER_NAS/$tmp/conf || \
		sEdit $ST_USER_NAS/$tmp/cred
	}
	NAS_Edit_Conf() { # [ LABEL ]
	#
	#
		[ -z $1 ] && lbl=$(NAS_Select)| lbl=$1
		sEdit $ST_USER_NAS/$lbl/conf
		#press
		source $ST_USER_NAS/$lbl/conf
		sP "Updating SAMBA credentials in $ST_USER_NAS/$lbl/cred" "$PROGRESS"
		NAS_Write_Cred "$ST_USER_NAS/$lbl/cred" "$username" "$nas_ip" "$password"
		ReportStatus $? "Updated SAMBA credentials in $ST_USER_NAS/$lbl/cred"
	}
	NAS_Copy_Conf() { #
	# Select an existing nas configuration/label
	# and save as a new one
		sE "Please select the existing LABEL"
		name_old=$(NAS_Select)
		sE "Selected label:" "$name_old"
		name_new=$(input "Please type the new LABEL:")
		cd $ST_USER_NAS
		cp -r "$name_old" "$name_new"
		ReportStatus $? "Copied $name_old to $name_new"
	}
	NAS_New() { # [ LABEL ]
	#
	#
		[ "" = "$1" ] && \
			sE "Please enter a label for this NAS:" && \
			sE "This is required for this script to work, and ease its usage." && \
			label=$(input "Type the projects label: ") || label="$1"
		sE "Selected Project:" "$label"
	#
	#	Ask for the data, providing default values
	#
		read -p "$LBL_NAS_Q $LBL_NAS_IP? ($NAS_DEFAULT_IP): "      nas_ip
		read -p "$LBL_NAS_Q $LBL_NAS_SHARE? ($NAS_DEFAULT_SHARE): " nas_share
		read -p "$LBL_NAS_Q $LBL_NAS_NAME? ($NAS_DEFAULT_NAME): "  nas_name
		read -p "$LBL_NAS_Q $LBL_NAS_DOM? ($NAS_DEFAULT_DOMAIN): " nas_dom
		read -p "$LBL_NAS_Q $LBL_NAS_USR? ($NAS_DEFAULT_USR): "    nas_usr
		read -p "$LBL_NAS_Q mount point? ($NAS_DEFAULT_MOUNTPOINT): " MOUNTPOINT
	#
	#	Check for empty variables, and fill with default values
	#
		test "" = "$nas_ip"     && nas_ip=$NAS_DEFAULT_IP
		test "" = "$nas_share"     && nas_share=$NAS_DEFAULT_SHARE
		test "" = "$nas_usr"    && nas_usr="$NAS_DEFAULT_USR"
		test "" = "$nas_name"   && nas_name="$NAS_DEFAULT_NAME"
		test "" = "$nas_dom"    && nas_dom="$NAS_DEFAULT_DOMAIN"
		test "" = "$MOUNTPOINT"		&& MOUNTPOINT="$NAS_DEFAULT_MOUNTPOINT"
	#
	#	
	#
		echo "Asking for your password which you had set on the NAS"
		echo "Leave empty and press enter to change the password later manualy."
		read -p "Your password: " tmp_pw
		test "" = "$tmp_pw" && tmp_pw="PASSWORD"
	#
	#	Now write the config file and the credentials
	#
		test ! -d $ST_USER_NAS && mkdir -p $ST_USER_NAS
		for each in cred nas hosts
		do  case $each in
			"cred")     NAS_Write_Cred "$nas_usr" "$nas_dom" "$tmp_pw" 
			;;
			"nas")      # OUTPUTFILE IP NAME USER DOMAIN PASSWORD MOUNTPOINT
					touch "$ST_USER_NAS/$label/conf"
						NAS_Write_Conf "$ST_USER_NAS/$label/conf" "$nas_ip" "$nas_name" "$nas_usr" "$nas_dom" "$tmp_pw" "$MOUNTPOINT"  
										;;  
			"!hosts")	sudo cat >> /etc/hosts << EOF
$nas_ip 		$nas_name
EOF
			;;
			esac
		done
		#[ "" = "$(grep $nas_name /etc/hosts)" ] && \
		isRoot && \
			ask "Add $nas_name to /etc/hosts?" && \
			echo "$nas_ip	$nas_name" >> /etc/hosts
	}
	NAS_List_Shares() { # LABEL
	# Lists an array of entries found on NAS
	# 
		test "" = "$(echo $1)" && sE "Usage: NAS_List_Shares IP|NAME" && return 1
		CheckSMBC
		if [ -f "$ST_USER_NAS/$1/conf" ]
		then	source $ST_USER_NAS/$1/conf
		else	nas_dev_name="$1"
		fi
		tmp_str=$($SMBC -L "$nas_dev_name" -N	grep Disk|awk '{print $1}')
		echo "${tmp_str}"
    	}
	NAS_Connect() { # LABEL
	# Retrieve a list of folders on the NAS and connect to one of them
	# Return 0 for connected, 1 otherwise
		test "" = "$1" && sE "Usage: NAS_Connect LABEL" && return 1
		test -d "$ST_USER_NAS/$1/conf" && lbl="$1"
		
		CheckSMBC
		
		select share in ${shares} back
		do  test $share = back && break
		    $SMBC //$nas_dev_name/$share -A $ST_USER_NAS/$lbl/cred && \
		    	return 0| return 1
		done
	}
	NAS_Mount() { # LABEL 
	# Mount the folders on the NAS to local environment
	#
        	[ -z $1 ] && echo "Usage: NAS_Mount LABEL" && exit 1
        	lbl=$1
        	conf="$ST_USER_NAS/$lbl/conf"
        	sP "Reading $lbl configuration..." "$PROGRESS"
        	source "$conf"
        	ReportStatus $? "$(Capitalize $lbl) config read."
        	
        	if [ "" = "$(mount|grep $nas_ip/$share)" ] ; then
			CheckPath "$(echo $MOUNTPOINT)"
			sP "Mounting $lbl to $MOUNTPOINT" "$PROGRESS"
			# nodiratime causes errors?
			sudo mount -t cifs -o _netdev,rw,credential="$conf" "//$nas_ip/$share" "$MOUNTPOINT"
			retval=$?
        	else	retval=3
        	fi
        	ReportStatus $retval "Mounted $lbl to $MOUNTPOINT"
        	exit $retval
        }
        NAS_Umount() { # LABEL 
	# Mount the folders on the NAS to local environment
	#
               	[ -z $1 ] && echo "Usage: NAS_Umount LABEL" && exit 1
        	lbl=$1
        	conf="$ST_USER_NAS/$lbl/conf"
        	sP "Reading $lbl configuration..." "$PROGRESS"
        	source "$conf"
        	ReportStatus $? "$(Capitalize $lbl) config read."
        	if [ ! "" = "$(mount|grep $nas_ip/$share)" ] ; then
			sP "Unmounting $lbl from $MOUNTPOINT" "$PROGRESS"
			sudo umount $MOUNTPOINT
			retval=$?
		else	retval=3
		fi
		ReportStatus $retval "Unmounted $lbl"
		exit $retval
        }
        NAS_Mountall() { # LABEL 
	# Mount the folders on the NAS to local environment
	#
        #
        #	Check & load arguments
        #
        [ -z $1 ] && echo "Usage: NAS_Mountall LABEL" && exit 1
        lbl="$1"
        if [ ! source $ST_USER_NAS/$lbl/conf ]
	then	sE "Could not load: $ST_USER_NAS/$lbl/conf"
		return 1
	fi
        shares=$(NAS_List_Shares $lbl)
        #echo "$shares"
        #
		#	Preparing smb.conf and path
		#
		reLine=$(grep workgroup /etc/samba/smb.conf|grep -v "\#")
		sudo sed -i s/"$reLine"/"workgroup = $domain"/g /etc/samba/smb.conf
		#
		#	Actualy mount the shares
		#
		for each in $(echo $shares)
		do	test ! -d "$MOUNTPOINT/$each" && sudo mkdir -p "$MOUNTPOINT/$each" # CheckPath "$MOUNTPOINT/$each"
			text="Mounting: //$nas_dev_name/$each to $MOUNTPOINT/$each"
			cmds="mount -t cifs //$nas_dev_name/$each $MOUNTPOINT/$each -o rw,soft,credentials=$ST_USER_NAS/$lbl/conf"
			cmdfile="/tmp/mount-nas.sh"
			
			sP "$text" "$PROGRESS"
	        sudo $cmds && \
	       		sE "$text"  "$SUCCESS"| \
	       		#ask "Save command for later usage?" && \
	       		#text="Save as file: $cmdfile" && \
	       		#echo "$cmds" >> $cmdfile && \
	       		#sE "$text" "$SUCCESS"| \
	       		sE "$text" "$FAILURE"
	        #return 1
		done
	}
	NAS_FSTAB() { # NAS-NAME|IP
	# Shows the commandline for /etc/fstab, and asks to add it to it
	#
		#//192.168.10.110/Shares /mnt/nas cifs username=usr,password=pw,uid=1000,gid=1000 0 0
		select share in $shares;do break; done

		echo $share
		read buffer

		cmdline="//$nas_dev_name/$share $MOUNTPOINT/$share cifs _netdev,rw,credentials=$ST_USER_NAS/$lbl/cred 0 0 " 
		sE "The command line for the /etc/fstab looks like:" "$cmdline"
		if ask "Add it to /etc/fstab?"
		then	su -c "echo $cmdline >> /etc/fstab"
				cat /etc/fstab
		fi
	}
	NAS_Write_Cred(){ # OUTPUTFILE USER DOMAIN PASSWORD
	# Write the Samba Credentials file
	#
		[ -z $4 ] && \
			echo "Usuage: NAS_Write_Cred OUTPUTFILE USER DOMAIN PASSWORD" && \
			return 1
		nameDir="$(dirname $1)"
		[ ! "$nameDir" = "$1" ] && mkdir -p "$nameDir"
		touch "$1"
		printf "username = $2\n"   > "$1"
		printf "  domain = $3\n"  >> "$1"
		printf "password = $4\n"  >> "$1"
	}
	NAS_Write_Conf() { # OUTPUTFILE IP NAME USER DOMAIN SHARENAME PASSWORD MOUNTPOINT 
	# Write the dummy file so you dont have to provide the same information to the script
	#
		[ -z $8 ] && \
			echo "Usuage: NAS_Write_Conf OUTPUTFILE IP NAME USER DOMAIN SHARENAME PASSWORD MOUNTPOINT " && \
			return 1
		mkdir -p "$(dirname $1)"
		touch "$1"
		echo "$LBL_NAS_IP=$2"    > "$1"
		echo "$LBL_NAS_NAME=$3" >> "$1"
		echo "$LBL_NAS_USR=$4"  >> "$1"
		echo "$LBL_NAS_DOM=$5"  >> "$1" 
		echo "$LBL_NAS_SHARE=$6"   >> "$1" 
		echo "$LBL_NAS_PW=$7"   >> "$1" 
		echo "MOUNTPOINT=$8"    >> "$1"
	}
	NAS_Debug() { #
	# Runs diffrent task like ping, the NAS' ip or name
	# shows firewall settings, and checks selinux settings.
		sE "Please select location:"
		select nas in $(ls $ST_USER_NAS);do break;done

		sE "Testing $nas_ip"
		CheckIP $nas_ip
		CheckIP $nas_device_name
		#press

		sE "Comparing smb.conf and nas.conf"
		sE "    smb.conf"						"nas.conf    "
		#wg=$(grep workgroup $SMB_CONFegrep -v "\#")
		#sE "$wg"	"$STR_SMB_DOM = $nas_domain "
		#press

		sE
		sE "Testing Firewall"
		sudo iptables -L -n
		#press

		fus="samba_share_fusefs"
		fusefs=$(getsebool $fus|awk '{print $3}')
		sE
		sE "Testing: $fus"
		sE "The SELinux $fus setting is currently" "$fusefs"
		if ask "Do you want to toggle it?" 
		then    fus_toggle="yes"
		else    fus_toggle="no"
		fi
		test "$fus_toggle" = "yes" && test "on" = "$fusefs" && sudo setsebool $fus 0| sudo setsebool $fus 1
		#press

		sE
		sE "Testing: $SAMBA_CONF using testparm"
		ask "Edit $SAMBA_CONF before testing" && vi "$SAMBA_CONF"
		testparm
		#press

		sE
		sE "List services for Samba server"  "(NOT required for NAS)"
		for service in smbd nmbd
		do ps -e	grep $service| sE "Service:$service" "not found"
		done
		systemd-analyze blame|grep smb
		#press

		echo
		echo "View logfiles in $SAMBA_LOGDIR"
		if [ "0" = "$UID" ]
		then    logs=$(ls "$SAMBA_LOGDIR" -r)
		    if [ ! "" = "$logs" ]
		    then    for log in $logs back
			    do      test "$log" = "back" && break
				    test ask "View log: $log" && vi "$log"
			    done
		    fi
		else    echo "You need to be root to view the logs."
		fi
		#press
	}
