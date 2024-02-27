#!/bin/bash
WEBHOOK_URL=<SLACK WEBHOOK URL>
IMAGE=<EXTERNALLY HOSTED IMAGE>

JSS=<JSS ADDRESS>
# API Account that has read access to Jamf Pro Server Objects > Computers
API_USER=<API USERNAME>
API_PW=<API PASSWORD>

UDID=$(system_profiler SPHardwareDataType | grep "UUID" | sed s/"Hardware UUID: "/''/g | sed 's/^ *//')
SITE_NAME=$(/usr/bin/curl -H "Accept: application/xml" -H "Content-type: application/xml" -s -u "$API_USER":"$API_PW" "${JSS}/JSSResource/computers/udid/$UDID/subset/General" | xpath /computer/general/site/name | sed -e 's/<name>//;s/<\/name>//')
COMPUTER_NAME=$(scutil --get ComputerName)

SSID=<WIFI SSID>
MODEL=$(system_profiler SPHardwareDataType | grep "Model Name" | sed 's/^[ \t]*//' | sed 's/Model Name: //g')
OS_VERSION=$(/usr/bin/sw_vers -productVersion)

# Danger status set to false
danger=0

TITLE="Mac Setup Completed"
TEXT="*JSS Site:* $SITE_NAME\n*Computer name:* $COMPUTER_NAME\n*Mac model:* $MODEL\n*macOS version:* $OS_VERSION\n"
 
# Primary User Check - looks at computer's assigned 'endUsername' and then confirms that they are an fv enabled user
PRIMARY_USER=$(/usr/bin/curl -H "Accept: application/xml" -H "Content-type: application/xml" -s -u "$API_USER":"$API_PW" "${JSS}/JSSResource/computers/udid/$UDID"/subset/Location | xpath /computer/location/username | sed -e 's/<username>//;s/<\/username>//')

if [[ -z "$PRIMARY_USER" ]]
then
	PRIMARY_USE="Unassigned"
fi

TEXT="$TEXT*Primary User:* $PRIMARY_USER\n"

if [[ "$PRIMARY_USER" != "Unassigned" ]]
then
	primary_user_fv_enabled=$(fdesetup list | grep "$PRIMARY_USER")
	if [[ ! -z "$primary_user_fv_enabled" ]]
   	then
       	TEXT="$TEXT*Primary User FV enabled?:* Yes\n"
   	else
   		TEXT="$TEXT*Primary User FV enabled?:* No\n"
       	danger=1
   	fi
fi
    	
# Confirms that Mac is connecting to the corporate SSID
# This script runs on Macbooks only, hence the assumption that wifi is on en0
# But you could parse through networksetup -listallhardwareports results to be more exact
WIFI=$(networksetup -getairportnetwork en0)
wifi_check=$(echo "$WIFI" | grep "$SSID")
    
if [[ -z "$wifi_check" ]]
then 
	TEXT="$TEXT*WiFi Check*: Mac not connected to $SSID\n"
	danger=1
else
	TEXT="$TEXT*WiFi Check*: Connected to $SSID\n"
fi
  
# If anything was deemed to have failed in the checks above, then the post color will be set to 'danger'/red
# You could also alter the image source at this point too, so that danger == image of a sad laptop, good == image of a happy laptop :)
if [[ $danger -eq 1 ]]
then 
	color="danger"
else
	color="good"
fi

escapedText=$(echo $TEXT | sed 's/"/\"/g' | sed "s/'/\'/g" )
JSON="{\"text\": \"$TITLE\",\"attachments\":[{\"thumb_url\": \"$IMAGE\",\"color\":\"$color\" , \"text\": \"$escapedText\"}]}"
curl -sk -d payload="$JSON" "$WEBHOOK_URL"