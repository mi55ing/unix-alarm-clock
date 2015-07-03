#!/bin/bash
###################################################################
# alarmclock.sh 
# A bash script to simulate a 3-stage alarm clock. Hey, why not?!
# I'd appreciate your feedback! e:'mi55ing@protonmail.com'
#  - especially for later versions of OSX and more obscure distros.
# If reporting an error, please state your Linux flavour & version.
###################################################################
# Change Log (NB: also change this in the preamble)
# =================================================
# v1.2:
# Make it louder; hardware speaker sounded awfully quiet with 
# amixer Master Vol @50%
#
# v1.1:
# Optimising for scientific linux with only 'play' which starts 'sox' 
#  - The command to capture PIDs runs before sox has started, so 
#    add a short (0.1s) sleep.
#  - Play quietly ("-q" or "-quiet" = screen output, not sound!) 
#    to avoid unneccessary screen output
#  - Use "kill -PIPE" to avoid Termination message on exit.
# 
# v1.0:
# Initial release. 
#
#
#
# GPLv3 LICENSE:
# ==============
#    alarmclock.sh - A bash script to simulate a 3-stage alarm clock. Hey, why not?!
#
#    Copyright (C) 2015  "mi55 ing"  mi55ing@protonmail.com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Future Imorovements:
# ====================
# 0// Add user-controlled alarm volume (currently 50%-ish by default)
# 1// set up a debug mode for comments (-verbose option)
# 2// determine OS near the start, see https://en.wikipedia.org/wiki/Uname and avoid all the nested IF loops
# 3// Correct for the fact that OSX Yosemite and Mavericks don't have osascript (I think!).
#

#############################################################
#Preamble - GPLv3 License.
#############################################################
echo
echo " /-----------------------------------------------------------------------------\\"
echo " | alarmclock.sh v1.2 Copyright (C) 2015 'mi55 ing'  mi55ing@protonmail.com    |"
echo " | This program comes with ABSOLUTELY NO WARRANTY; for details see license.txt.|"
echo " | This is free software, and you are welcome to redistribute it               |"
echo " | under certain conditions; see license.txt for details.                      |" 
echo " \\-----------------------------------------------------------------------------/"
echo


#############################################################
#Define a usage() function to help users.
#############################################################
function usage(){
    echo
    echo
    echo "Your Friendly bash AlarmClock"
    echo "============================="
    echo "Usage: "
    echo "./alarmclock.sh {-t HH:MM -d DD -h HH -m MM -s SS} [-msg 'yourtext']"
    echo
    echo "Options:"
    echo " -t     Time(HH:MM) in the next 24h to set off the alarm (24h clock)."
    echo " -d     Days in the future to set off the alarm."
    echo " -h     Hours in the future to set off the alarm."
    echo " -m     Minutes in the future to set off the alarm."
    echo " -s     Seconds in the future to set off the alarm."
    echo "[-msg]  Optional message to label the alarm. Use single quotes to surround text."
    echo
    echo "Please give the time (24h clock) for the alarm to go off: [-t HH:MM]"
    echo "Or, please give time to wait, before alarm goes off:" 
    echo "[-d days]  [-h hours]  [-m minutes]  [-s seconds]."
    echo
    echo "Examples:" 
    echo " - For 5 seconds in the future:" 
    echo "   ./alarmclock.sh -s 5"
    echo
    echo " - For 08:00 in the morning:"
    echo "   ./alarmclock.sh -t 08:00"
    echo 
    echo " - For 1h and 30m in the future, and a reminder message:"
    echo "   ./alarmclock.sh -h 1 -m 30 -msg 'TURN OFF THE OVEN!'"
    echo 
    echo "Notes:"
    echo " - [-d, -h, -m, -s, -t]  are OPTIONAL, but AT LEAST ONE must be specified!"
    echo " - You should use single quotes(') to surround your message with -msg 'yourtxt'."
    echo " - If both -t and any of -d,-h,-m,-s are specified, the time to activiate"
    echo "   will be extended by -d days, -h hours, -m minutes and -s seconds"
    echo "   e.g. \"./alarmclock.sh -t 08:00 -m 1\" will activate at 08:01."
    echo " - If using OSX, you can 'Enable Assistive Devices' to allow the screen to focus"
    echo "   on the alarm window when the alarm goes off. "
    echo "    o (OSX Snow Leopard: see System Preferences > Universal Access)"
    echo "    o (OSX Mavericks: System Preferences > Security & Privacy > Privacy > Accessibility" 
    echo "      and check 'Terminal.app'"  
    echo " - If using OSX, you can also enable visual and audible bell in Terminal.app to enable"
    echo "   the screen to flash and beep. (Terminal > Preferences > Advanced)"
    echo
}


#############################################################
# No parameters given, provide USAGE statement
#############################################################
if [[ $# -le 1 ]] 
then
    usage
    exit 1
fi

#############################################################
# Go through parameters..[d,h,m,s,t,msg]
#############################################################
while [[ $# > 1 ]]
do
key="$1"
case $key in
    -d|--days)
    DAYS="$2"
    shift
    ;;
    -h|--hours)
    HOURS="$2"
    shift
    ;;
    -m|--minutes)
    MINUTES="$2"
    shift
    ;;
    -s|--seconds)
    SECS="$2"
    shift
    ;;
    -t|--time)
    TIME="$2"	 
    shift
    ;;
    -msg)
    MESSAGE="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
esac
shift
done

#############################################################
# Filter for invalid options.
#############################################################
if [[ -n $1 ]]; then
    usage
    echo
    echo "alarmclock.sh: Invalid option passed as a command-line argument!"
    exit 2
fi

#############################################################
# Check the user supplied at least one 
# time-dependent parameter [d,h,m,s,t]
#############################################################
if [[ ${DAYS} == "" && ${HOURS} == "" && ${MINUTES} == "" && ${SECS} == "" && ${TIME} == "" ]]
then
    usage
    echo
    echo "alarmclock.sh: Invalid arguments: Please supply at least one of [-d, -h, -m, -s, -t]"
    exit 3
fi

#############################################################
# Ensure a valid media player exists
#############################################################
#echo "alarmclock.sh: Checking a media player exists"
which afplay >/dev/null 2>&1
afplayerresult=$?
which mplayer >/dev/null 2>&1
mplayerresult=$?
which play >/dev/null 2>&1
playerresult=$?
which aplay >/dev/null 2>&1
aplayerresult=$?


if [[ $afplayerresult != 0 && $mplayerresult != 0 && $playerresult != 0 && $aplayerresult != 0 ]]
then
    echo "alarmclock.sh: NO VALID MEDIA PLAYER INSTALLED!"
    echo "alarmclock.sh: Requires mplayer, play, aplay, or afplay."
    echo "alarmclock.sh: afplayer result [0=OK, >0=FAIL]: " $afplayerresult
    echo "alarmclock.sh: mplayer result  [0=OK, >0=FAIL]: " $mplayerresult
    echo "alarmclock.sh: player result   [0=OK, >0=FAIL]: " $playerresult
    echo "alarmclock.sh: aplayer result  [0=OK, >0=FAIL]: " $aplayerresult
    echo "EXITING"
    exit 4
fi

#############################################################
# NOW REGISTER THE  {d,h,m,s,t} parameters
#############################################################
if [[ ${DAYS} == "" ]]
    then 
    DAYS=0
fi
if [[ ${HOURS} == "" ]]
    then 
    HOURS=0
fi
if [[ ${MINUTES} == "" ]]
    then 
    MINUTES=0
fi
if [[ ${SECS} == "" ]]
    then 
    SECS=0
fi
#echo DAYS       = "${DAYS}"
#echo HOURS      = "${HOURS}"
#echo MINUTES    = "${MINUTES}"
#echo SECS       = "${SECS}"


######################################################################
# Set the Window Title to something useful so we can identify it later
######################################################################
# We do this so that OSX can identify the window, raise it and focus.
# choose a random number to name the window - 
# it would be used ONLY to bing the window in to focus; 
# In case there is a clash (>1 alarm set and unlucky random number gets repeated), it will NOT stop the alarm going off!
# Only the window will not be brought into focus if there is a clash.
myrand=$(( ( RANDOM % 1000000 )  + 1 ))
echo -n -e "\033]0;myalarmclock-$myrand\007"


#############################################################
# NOW CONVERT D->S, H->S and M->S
#############################################################
dayseconds=$((DAYS*86400))
#echo "dayseconds: "$dayseconds
hourseconds=$((HOURS*3600))
#echo "hourseconds: "$hourseconds
minuteseconds=$((MINUTES*60))
#echo "minuteseconds: "$minuteseconds
totalseconds=$((dayseconds+hourseconds+minuteseconds+SECS))
#echo "totalseconds: "$totalseconds
#now we have established the interval in seconds until the alarm is to be executed

#############################################################
# Add to $totalseconds if there is a time entered
#############################################################
if [[ ${TIME} != "" ]]
then    
    CURRENTTIME=$( date +%H:%M )
    #echo "CURRENTTIME IS " $CURRENTTIME
    #echo "ALARM REQUESTED FOR " $TIME
    DIFFMINS=$(  echo "($TIME) - ($CURRENTTIME)"   | sed 's%:%*60+%g' | bc -l )
    #echo "TIME MINUS CURRENTTIME IN MINS IS " $DIFFMINS
    if [[ $DIFFMINS -le 0 ]]
    then
	#echo "GONE NEGATIVE OR ZERO! " 
	#echo "ADDING 24h (1440m)"
	DIFFMINS=$((DIFFMINS+1440))
	#echo "NEW TIME MINUS CURRENTTIME IN MINS IS " $DIFFMINS
	currentseconds=$( date +%S )
	#echo "currentseconds" $currentseconds
	currentseconds=`echo $currentseconds|sed 's/^0*//'`
	#echo "new currentseconds" $currentseconds
	#echo "DIFFMINS*60" $((DIFFMINS*60))
	#echo "DIFFMINS*60-currentseconds" $((DIFFMINS*60-currentseconds))
	diffseconds=$((DIFFMINS*60-currentseconds))
	totalseconds=$((totalseconds+diffseconds))
	#echo "totalseconds to " $TIME " from " $CURRENTTIME " is " $diffseconds 
    else
	#echo "NEW TIME MINUS CURRENTTIME IN MINS IS " $DIFFMINS
	currentseconds=$( date +%S )
	#echo "currentseconds" $currentseconds
	currentseconds=`echo $currentseconds|sed 's/^0*//'`
	#echo "new currentseconds" $currentseconds
	#echo "DIFFMINS*60" $((DIFFMINS*60))
	#echo "DIFFMINS*60-currentseconds" $((DIFFMINS*60-currentseconds))
	diffseconds=$((DIFFMINS*60-currentseconds))
	totalseconds=$((totalseconds+diffseconds))
	#echo "totalseconds to " $TIME " from " $CURRENTTIME " is " $diffseconds 
    fi
fi


#############################################################
# Due to nonstandard DATE commands 
# between bash shell in OSX and other Linux flavours
# we must try two methods...
#############################################################
# Standard linux bash command, 
# (use "2>&1" so that if it fails, it does so quietly)
alarmdate=`date --date="${totalseconds} seconds" 2>&1 `
alarmresult=$?
# Trap any error (i.e. if $alarmresult != 0)
# echo "Standard Linux alarm setting attempt status $alarmresult, value set was: $alarmdate"
if [[ $alarmresult != 0 ]]
then
    # Maybe apple OSX
    # (again, use "2>&1" so that if it fails, it does so quietly)
    #echo "alarmclock.sh: Could not set date using standard linux format, trying osx/apple version of date command"
    alarmdate=`date -v+${totalseconds}S  2>&1`
    alarmresult=$?
    # trap any error (i.e. if $alarmresult != 0)
    # echo "OSX alarm setting attempt status $alarmresult , value set was: $alarmdate"
    if [[ $alarmresult != 0 ]]
    then
	echo "alarmclock.sh: FAILED TO SET DATE! EXITING..."
	exit 5
    #else
	#echo "alarmclock.sh: Successfully set date using apple/osx version of date command"	
    fi
fi



#############################################################
# User Comfort message and SLEEP command
#############################################################
echo
echo
echo "Alarm Set For: " $MESSAGE
echo "=============="
echo $alarmdate
echo
sleep $totalseconds





#############################################################
# FUNCTION TO  START THE ALARMS
#############################################################
function alarmstart(){

################################################
# After sleeping, set volume wherever possible
################################################
#set the volume to a reasonable level as many ways as possible..
#bash varies between os and other more standard distros, so we will try two ways to begin with
#NB use the ">/dev/null 2>&1"  so that it fails quietly; we trap the errors anyway
#---------------------------------
#standard bash "amixer" command
amixer set Master 100% >/dev/null  2>&1
volumeresult=$?
# trap any error
#echo "Standard Linux amixer setting attempt status $volumeresult"
if [[ $volumeresult != 0 ]]
then
    #echo "alarmclock.sh: There was an error setting volume using standard amixer command"
    osascript -e "set Volume 5" >/dev/null 2>&1
    volumeresult=$?
    # trap any error
    #echo "OSX osascript volume setting attempt status $volumeresult"
    if [[ $volumeresult != 0 ]]
    then
	echo "--------------------------------------------------------------------"
	echo "alarmclock.sh: NO VOLUME SET!"
	echo "alarmclock.sh: Continuing, but it may not make any sound!"
	echo "alarmclock.sh: We do have a fallback 'tput bel' command inside"
        echo "               the script 'flashscreen.sh', which may or may not"
        echo "               make some noise."
	echo "--------------------------------------------------------------------"
    #else
	#echo "alarmclock.sh: Successfully set volume using apple osascript"
	#echo
	#echo
    fi
fi

################################################
# bring window to front, zoom it, 
# flash screen, set focus
################################################
#What we do here depends on OS.
#OSX Snow Leopard (Kernel 10.X) at least, offers the ability bring the 
#window to the front AND focus the cursor in the window
#(hence, we can just ask the user to push 'ENTER' to stop the alarm).
#
#Linux in general cannot do this without wmctrl or xdotool installed.
#I will not assume they are installed.
#What we can do instead, is zoom the window and listen for mouse clicks.
#
#General ANSI escape code to bring the window to the front
printf '\033[5t'
#General ANSI escape code to zoom the window
printf '\033[9;1t'
#General ANSI escape code to listen for mouse click 
#(does not appear to work in OSX, but does not affect other functionality 
# using osascript to raise/focus window in OSX, so I leave it here..)
printf '\033[?1000h' 
# 
#Specifically for Snow Leopard (Kernel 10.X)
#bring the terminal in to focus
#MUST HAVE ASSISTIVE DEVICES ENABLED in SYSTEM PREFERENCES -> UNIVERSAL ACCESS-> "enable access for assistive devices"
#AND TO DO THIS BY COMMAND LNE REQUIRES SUDO... :(
#made more robust by creating a random number for name e.g. myalarmclock-12345 
OperatingSystem=`uname -s`
KernelVersionMajor=`uname -r | awk -F '.' '{print $1 "."}'` 
if [[ $OperatingSystem == "Darwin" && $KernelVersionMajor == "10." ]]
then
    text=myalarmclock-$myrand
    osascript -e 'do shell script "open -a  Terminal"'  
    sleep 0.1
    osascript -e 'tell application "Terminal" to set index of window 1 whose name contains "'"$text"'" to 1'
    sleep 0.1
    osascript -e 'tell application "System Events" to tell process "Terminal" to perform action "AXRaise" of window 1' > /dev/null
fi




################################################
#the actual alarm STAGE 1
################################################
# By this stage, we know that ONE valid player is present
if [[ $afplayerresult == 0 ]]
then
    afplay birdsong.wav -v 1 & >/dev/null 2>&1
else
    if [[ $mplayerresult == 0 ]]
    then
	mplayer -quiet birdsong.wav & >/dev/null 2>&1
    else
	if [[ $playerresult == 0 ]]
	then
            play -q birdsong.wav & >/dev/null 2>&1 
	else
     	    if [[ $aplayerresult == 0 ]]
	    then
		aplay -q birdsong.wav & >/dev/null 2>&1 
	    fi
	fi
    fi
fi
    
################################################
# NOW GET THE PROCESS ID TO KILL IF ENTER IS HIT
################################################
# First, sleep a short time to let aplay/play stary any needed processes..
sleep 0.1
playerprocessid=`ps ax | grep birdson\[\g\] | grep -v grep | awk '{print $1}'`
#echo $playerprocessid

################################################
# Flash the Terminal & get that process too
################################################
./flashscreen.sh & 
flashprocessid=`ps ax | grep flashscree\[\n\] | grep -v grep | awk '{print $1}'`
#echo $flashprocessid

################################################
# Offer to abort at Stage 1
################################################
echo -n -e "\033[30;46;5m.                                           \033[0m"
echo
echo -n -e "\033[30;46;5m.                                           \033[0m"
echo
if [[ $OperatingSystem == "Darwin" ]]
then 
    echo -n -e "\033[30;46;5mHit ENTER to abort sequence! >              \033[0m"
else 
    echo -n -e "\033[30;46;5mClick Mouse/Track Pad to abort sequence! >  \033[0m"
fi    
if read -n 6 -t 15 response; then
    echo
    echo "Great, you made it in time!"
    kill -PIPE $playerprocessid >/dev/null 2>&1
    #use the -PIPE option to suppress output
    kill -PIPE $flashprocessid  >/dev/null 2>&1  
    #leave the function alarmstart()
    return
else
    echo
    echo -n -e "\033[30;46;5m.                                           \033[0m"
    echo
    echo -n -e "\033[30;46;5m.                                           \033[0m"
    echo
    echo "\/ \/ \/ \/    I  REPEAT!  \/ \/ \/ \/  "
fi


    
################################################
#the actual alarm STAGE 2
################################################
# By this stage, we know that ONE valid player is present
if [[ $afplayerresult == 0 ]]
then
    afplay GrandfatherClock.wav -v 1 & >/dev/null 2>&1
else
    if [[ $mplayerresult == 0 ]]
    then
	mplayer -quiet GrandfatherClock.wav & >/dev/null 2>&1
    else
	if [[ $playerresult == 0 ]]
	then
            play -q GrandfatherClock.wav & >/dev/null 2>&1 
	else
     	    if [[ $aplayerresult == 0 ]]
	    then
		aplay -q GrandfatherClock.wav & >/dev/null 2>&1 
	    fi
	fi
    fi
fi


################################################
# NOW GET THE PROCESS ID TO KILL IF ENTER IS HIT
################################################
# First, sleep a short time to let aplay/play stary any needed processes..
sleep 0.1
playerprocess2id=`ps ax | grep GrandfatherCloc\[\k\] | grep -v grep | awk '{print $1}'` 
#echo $playerprocess2id

################################################
# Offer to abort at Stage 2
################################################
echo -n -e "\033[30;43;5m.                                           \033[0m"
echo
echo -n -e "\033[30;43;5m.                                           \033[0m"
echo
if [[ $OperatingSystem == "Darwin" ]]
then 
    echo -n -e "\033[30;43;5mHit ENTER to abort sequence! >              \033[0m"
else 
    echo -n -e "\033[30;43;5mClick Mouse/Track Pad to abort sequence! >  \033[0m"
fi    
if read -n 6 -t 35 response; then
    echo 
    echo "Great, you made it in time!"
    kill -PIPE $playerprocess2id >/dev/null 2>&1
    #use the -PIPE option to suppress output
    kill -PIPE $flashprocessid >/dev/null 2>&1
    #leave the function alarmstart()
    return
else
    echo
    echo -n -e "\033[30;43;5m.                                           \033[0m"
    echo
    echo "\/ \/ \/ \/    I  REPEAT!  \/ \/ \/ \/  "
fi




################################################
#the actual alarm STAGE 3
################################################
# By this stage, we know that ONE valid player is present
# afplay command, if afplay is present
if [[ $afplayerresult == 0 ]]
then
    afplay CarterAirRaidSiren.wav -v 1 & >/dev/null 2>&1
else
    if [[ $mplayerresult == 0 ]]
    then
	mplayer -quiet CarterAirRaidSiren.wav & >/dev/null 2>&1
    else
	if [[ $playerresult == 0 ]]
	then
            play -q CarterAirRaidSiren.wav & >/dev/null 2>&1 
	else
     	    if [[ $aplayerresult == 0 ]]
	    then
		aplay -q CarterAirRaidSiren.wav & >/dev/null 2>&1 
	    fi
	fi
    fi
fi


################################################
# NOW GET THE PROCESS ID TO KILL IF ENTER IS HIT
################################################
# First, sleep a short time to let aplay/play stary any needed processes..
sleep 0.1
playerprocess3id=`ps ax | grep CarterAirRaidSire\[\n\] | grep -v grep | awk '{print $1}'`
#echo $playerprocess3id

################################################
# Offer to abort at Stage 3
################################################
echo -n -e "\033[37;41;5m.                                           \033[0m"
echo
if [[ $OperatingSystem == "Darwin" ]]
then 
    echo -n -e "\033[37;41;5mHit ENTER to abort sequence! >              \033[0m"
else 
    echo -n -e "\033[37;41;5mClick Mouse/Track Pad to abort sequence! >  \033[0m"
fi    
if read -n 6 -t 68 response; then
    echo 
    echo "Great, you made it in time!"
    kill -PIPE $playerprocess3id >/dev/null 2>&1
    #use the -PIPE option to suppress output
    kill -PIPE $flashprocessid >/dev/null 2>&1
    #leave the function alarmstart()
    return
else
    echo "Sorry, you are too slow!" 
    echo "GAME OVER, MAN!"
    #Finally kill the beeping/flashing screen so as not to irritate others *too* much!
    kill -PIPE $flashprocessid >/dev/null 2>&1
fi

################################################
# End of function to start the alarms
################################################
}



#############################################################
# Set off the alarms
#ALARM!!!
#############################################################
alarmstart
#End - turn off the mouse listening
printf '\033[?1000l'
printf '\n'
printf '\n'
#leave nicely
exit 0