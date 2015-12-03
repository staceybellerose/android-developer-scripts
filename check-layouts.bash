#!/bin/bash

# check-layouts: Determine if any layout files are unused in an Android project
# Copyright 2011 Stacey Adams stacey.belle.rose@gmail.com

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This program was inspired by the bash script written by Cristian on
# http://stackoverflow.com/questions/3760033/find-out-if-resource-is-used

usage()
{
cat << EOF
usage: $0 options [PROJECT]

This script checks each layout in PROJECT/res/layout (and related
folders) and searches all xml and java source files to determine if the
layout is used in the project.

OPTIONS:
	-h		Show this message
	-p PROJECT	main project folder, defaults to $PROJECT
	-c		Display color coding (red=unused; green=used)
	-v		Verbose mode: also show used drawables
EOF
}

# default: assume current directory
PROJECT=.

# other options
SHOW_USED=0
SHOW_UNUSED=1
COLOR=0

# parse the command line parameters
while getopts :hp:cdv OPTION
do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	p)
		PROJECT=$OPTARG
		;;
	c)
		COLOR=1
		;;
	v)
		SHOW_USED=1
		SHOW_UNUSED=1
		;;
	\?)
		usage
		exit 1
		;;
	esac
done
shift $((OPTIND-1))

# project directory given as optional arg
if [[ $# -gt 0 ]]
then
	PROJECT=$1
fi

# sanity checks to determine if $PROJECT is really an Android project
if [ ! -e $PROJECT/AndroidManifest.xml ]
then
	echo ERROR: $PROJECT is not a valid Android project
	echo
	usage
	exit 2
fi
if [ ! -d $PROJECT/res ]
then
	echo ERROR: $PROJECT is not a valid Android project
	echo
	usage
	exit 2
fi
if [ ! -d $PROJECT/src ]
then
	echo ERROR: $PROJECT is not a valid Android project
	echo
	usage
	exit 2
fi

# create lists of file names to check
XML_FILES=$(find $PROJECT/res -name "*.xml" -print 2> /dev/null)
JAVA_FILES=$(find $PROJECT/src -name "*.java" -print 2> /dev/null)
LAYOUTS=$(ls $PROJECT/res/layout* -1 | sed 's/\..\+//g' | sort | uniq)

# check each $LAYOUT
for file in $LAYOUTS
do
	found=0
	# first check the XML files
	if grep -q @layout/$file $XML_FILES
	then
		found=1
	fi
	if [ $found -eq 0 ]
	then
		# not found yet; check the Java files
		if grep -q R.layout.$file $JAVA_FILES
		then
			found=1
		fi
	fi
	if [ $found -eq 0 ]
	then
		if [ $SHOW_UNUSED -eq 1 ]
		then
			if [ $COLOR -eq 1 ]
			then
				echo -e "\e[0;31m$file\e[0m not used"
			else
				echo "$file not used"
			fi
		fi
	else
		if [ $SHOW_USED -eq 1 ]
		then
			if [ $COLOR -eq 1 ]
			then
				echo -e "\e[0;32m$file\e[0m used"
			else
				echo "$file used"
			fi
		fi
	fi
done
