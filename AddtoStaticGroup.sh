#!/bin/bash

# server connection information
URL="https://jamf.2u.com/"
userName="jamfapi"
password="jamfapi1234"

httpErrorCodes="200 Request successful
201 Request to create or update object successful
400 Bad request
401 Authentication failed
403 Invalid permissions
404 Object/resource not found
409 Conflict
500 Internal server error"

# get list of static groups
computerGroupXML=$( /usr/bin/curl "$URL/JSSResource/computergroups" \
--user "$userName":"$password" \
--header "Accept: text/xml" \
--request GET \
--silent )

# parse XML for static groups
staticGroupList=$( /usr/bin/xpath "//is_smart[text()='false']/preceding-sibling::name/text()" 2>&1 <<< "$computerGroupXML" | /usr/bin/sed 's/-- NODE --//g' | /usr/bin/tail -n +3 | /usr/bin/sort )

# display dialog to choose a group and endcode for HTTP submission
theCommand="choose from list every paragraph of \"$staticGroupList\" with title \"Add to Static Group\" with prompt \"Choose a static group...\" multiple selections allowed false empty selection allowed false"

staticGroupName=$( /usr/bin/osascript -e "$theCommand" | /usr/bin/sed -e 's/ /%20/g' )

# display dialog to prompt for serial number
theCommand="display dialog \"Enter a computer serial number...\" default answer \"\" with title \"Add to Static Group\" buttons {\"Cancel\", \"OK\"} default button {\"OK\"}"

results=$( /usr/bin/osascript -e "$theCommand" )
serialNumber=$( echo "$results" | /usr/bin/awk -F "text returned:" '{print $2}' )

# add new serial number to list
xmlData="<computer_group><computer_additions><computer><serial_number>$serialNumber</serial_number></computer></computer_additions></computer_group>"

# add serial number to static group
uploadData=$( /usr/bin/curl "$URL/JSSResource/computergroups/name/$staticGroupName" \
--write-out "%{http_code}" \
--user "$userName":"$password" \
--header "Content-Type: text/xml" \
--data "$xmlData" \
--request PUT \
--silent )

# evaluate HTTP status code
resultStatus=${uploadData: -3}
code=$( /usr/bin/grep "$resultStatus" <<< "$httpErrorCodes" )
echo "$code"

# display status dialog
theCommand="display dialog \"Status: $code\" with title \"Add to Static Group\" buttons {\"OK\"} default button {\"OK\"}"
/usr/bin/osascript -e "$theCommand"

exit 0