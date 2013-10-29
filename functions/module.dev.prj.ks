
#
#	Description:	Handles basic kickstart tasks
#	License: 	GPL v3
#	Date created:	2012.11.11
#	Date changed:	2013.08.28
#	Written by: 	Simon A. Erat, erat . simon æ gmail . com
#
#
#	Variables
#

#
#	Subs
#
	KS_Prj_List() { #
	# Prints a list of content in $ST_USER_PRJ (~/.config/script-tools/projects)
	#
		for e in $(ls $ST_USER_PRJ)
		do test -f $ST_USER_PRJ/$e/kickstart && printf "$e "
		done
	}
	KS_Prj_Select() { #
	# 
	#
		list=$(KS_Prj_List)
		[ "" = "$(echo $list)" ] > /dev/zero && \
			#sE "No kickstart projects found..." "$FAILURE" && \
			return 1
		[ "$(echo $list|awk '{print $1}')" = "$(echo $list)" ] && \
			echo $list && \
			return 0
		select ks in $list
		do	echo $ks
			return 0
		done
		return 1
	}
	KS_Prj_Edit() { # [ LABEL ]
	# Edits an existing kickstart projects
	#
		[ -z $1 ] && \
			lbl=$(KS_Prj_Select) || \
			lbl=$1
		tmp=$ST_USER_PRJ/$lbl/kickstart
		[ -f $tmp ] && \
			source $tmp && \
			sEdit $ST_USER_PRJ/$lbl/ks/$ks_name.ks
	}
	KS_New() { # [ LABEL ]
	# Creates a new kickstart projects
	#
		def_ks_tmp=/mnt
		[ -z $1 ] && lbl=$(PRJ_Select) || lbl="$1"
		[ "$ST_USER_PRJ" = "$(dirname $ST_USER_PRJ/$lbl)" ] && ( PRJ_New $lbl || return 1 )
		#[ ! -d $ST_USER_PRJ/$lbl ] 
		[ -f $ST_USER_PRJ/$lbl/kickstart ] && ReportStatus 1 "Module already added" && return 1
		source $ST_USER_PRJ/$lbl/conf
		ks_name="$lbl"  #$(input "What is the name (project-label)for the kickstart?") || \
		ks_label="$prj_name" # $(input "What is the (spin-)label for $ks_name?")
		ks_tmp=/mnt/$ks_name #$(input "Enter tmp-work path or leave empty for $def_ks_tmp:")
		
		
		select size in "cd" media
		do 	ks_app="live$size-creator"
			break
		done
		
		cat > "$ST_USER_PRJ/$lbl/kickstart" << EOF
# Script-Tools - Kickstart configuration for project $(Capitalize $prj_name)
ks_name=$lbl
ks_label="$prj_name"
ks_tmp=/mnt/\$ks_name
ks_prj_dir="$ST_USER_PRJ/$ks_name/ks"
ks_prj_out="\$outputdir"
ks_app=$ks_app
bootimage="$HOME/Downloads/FXY-netinstall.iso"
EOF
		source $ST_USER_PRJ/$lbl/kickstart
		sT "Create template"
		CheckPath "$(echo $ks_prj_dir/ks)"
		target="$ST_USER_PRJ/$ks_name/ks/$ks_name.ks"
		cp "$stDir/Script-Core/Templates/iso/$ks_app.ks" "$target"
		ReportStatus $? "Created template: $(echo $target)"
		ask "Edit $(basename $target) now?" && \
			sEdit "$target"
	}
	KS_Prj_makefile() { # [ LABEL ]
	# Creates the actual Kickstart file, leaving the sourcefile(s) untouched.
	#
	#
	#	Title
	#
		[ "" = "$1" ] && lbl=$(KS_Prj_Select) || lbl="$1"
		sT "Kickstart generator ($script_version) for project: $lbl"
	#
	#	Variables
	#
		workdir=$ST_USER_PRJ/$lbl/ks
		source $(dirname $workdir)/kickstart
		today="$(date +'%Y%m%d-%H%M')"
		
		tmp=$ST_MENU_DIR/$ks_name-$today.ks	
		thisFile=$tmp
		
		#sE "Saving kickstart:" "$lbl"
		sE "File:"	"$thisFile"
	#
	#	Output
	#
		rmtf $workdir	> /dev/zero
		echo "# Kickstartfile generated by Script-Tools ($stVer)" > $thisFile
		for file in $(ls $workdir --hide=exclude --hide=files);do
			sP "Parsing: $file..." "$PROGRESS"
			[ -f $workdir/$file ] && cat $workdir/$file >> $thisFile
			[ 0 -eq $? ] && retval=0 || retval=1
			ReportStatus "$retval" "Added file: $file" 
		done
		ReportStatus "$retval"  "Parsed files of $ks_label" 
		return $retval
	}
	KS_Prj_Spin() { #  [ LABEL ]
	#
	#
	#
	#	Variables
	#
		ksPath=/usr/share/spin-kickstarts
		today="$(date +'%Y%m%d-%H%M')"
		#for custKS in $(ls $ST_MENU_DIR);do ln -sf $ST_MENU_DIR/$custKS $ksCust;done
		tempdir=""
		CustomList=""
		toInstall=""
		shcmd=""
	#
	#	Required Environment & applications
	#
		for app in livecd-tools spin-kickstarts pykickstart #revisor kvm qemu 
		do	sP "Parsing: $app" "$PROGRESS" 
			test "" = "$(rpm -q $app)" && toInstall="$toInstall $app"
		done
		[ ! "" = "$toInstall" ] && \
			sudo yum install -y $toInstall || \
			sE "Required applications present." "$SUCCESS"
	#
	# If called with [-]-s parameter it opens shell input
	#
		for a in $@;do [ "$a" = "[-]-s" ] && shcmd=" --shell ";done
	#
	#	Select Kickstart file
	#
		[ -z $1 ] && \
			lbl=$(Prj_Select) || \
			lbl=$1
		
		[ "$(echo $ST_USER_PRJ/)" = "$(echo $ST_USER_PRJ/$lbl)" ] && \
			PRJ_New $lbl
		source $ST_USER_PRJ/$lbl/conf || return 1
		source $ST_USER_PRJ/$lbl/kickstart || return 1
		
		[ -z $ks_tmp ] && \
			tempdir=/mnt/sysimage || \
			tempdir=$ks_tmp
		[ -z $outputdir ] && \
			outputdir="$HOME/Projects/output"
	#
	#	Settings for spin
	#	32|64bit, SELinux, Label
	#
		if is64bit
		then	ask "Do you want to create $ks_label as 32bit?" && \
			bit=yes || bit=no
		else	bit=no
		fi
	#
	#	Build Command Line
	#
		if [ ! "" = "$(echo $ks_app|grep media)" ] 
		then	cmd="$ks_app --make-iso --iso=$bootimage --ks=$ks_prj_dir/$ks_name.ks" # $outputdir/$ks_name.iso
		else	cmd="$ks_app $shcmd --config=$ks_prj_dir/$ks_name.ks --fslabel=$ks_label --tmpdir=$tempdir" # 
		fi
		[ "$bit" = "yes" ] && +cmd="setarch i686 "
		
		
		sE
		sE "This command will be executed..."
		sE "$cmd"
		sE
		ask "Edit the file ($(basename $ks_prj_dir/$ks_name.ks))?" && \
			sEdit "$ks_prj_dir/$ks_name.ks"
		sE
	#
	#	Create the Spin
	#
		CheckPath $tempdir
		sudo rm -f $tempdir/*.ks
		sP "Copying $ks_prj_dir/ks/$ks_name.ks to $tempdir" "$PROGRESS"
		sudo cp $ks_prj_dir/$ks_name.ks $tempdir
		ReportStatus $? "Copied $ks_prj_dir/$ks_name.ks to $tempdir"
		sE "Generating required data to build: $ks_label" "$PROGRESS"
		sudo setenforce 0 > /dev/zero
		sudo $cmd && retval=0 || retval=1 #&& return 1
		retvar=$retval
		ReportStatus "$retval" "Built $label as $ks_name.iso"
		return "$retvar"
	}