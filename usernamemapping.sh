#!/bin/bash

USER_ID="$(echo 'show State:/Users/ConsoleUser' | scutil | awk '($1 == "UID") { print $NF; exit }')"

if [[ $USER_ID == 0 ]]; then

    /bin/echo "No user logged in"
    exit 0

else

    USER_NAME="$(dscl /Search -search /Users UniqueID "${USER_ID}" 2> /dev/null | awk '{ print $1; exit }')"
    HOME_FOLDER="$(/usr/libexec/PlistBuddy -c 'Print :dsAttrTypeStandard\:NFSHomeDirectory:0' /dev/stdin <<< "$(dscl -plist . -read "/Users/${USER_NAME}" NFSHomeDirectory 2> /dev/null)" 2> /dev/null)"

    JAMF_CONNECT_USER=$(/usr/bin/defaults read "${HOME_FOLDER}/Library/Preferences/com.jamf.connect.state.plist" UserShortName)

	/bin/echo "Assigning computer to $JAMF_CONNECT_USER"
    /usr/local/bin/jamf recon -endUsername "${JAMF_CONNECT_USER}"

fi