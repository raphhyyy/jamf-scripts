#!/bin/bash

jssUser=""
jssPassword=""
jssURL=""
#You can also uncomment this line if you want the script to read which jamf server the computer it is running on connects to.
jssURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed s'/.$//')

if [ -z $jssURL ]; then
    echo "Please enter the JSS URL:"
    read -r jssURL
fi 
if [ -z $jssUser ]; then
    echo "Please enter your JSS username:"
    read -r jssUser
fi 
if [ -z $jssPassword ]; then 
    echo "Please enter JSS password for account: $jssUser:"
    read -r -s jssPassword
fi

echo "Logging in to $jssURL as $jssUser"
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
    echo "The currently logged in user is $loggedInUser. Creating CSV file on the desktop..."
    time=$(date +"%m.%d.%Y_%H.%M.%S")
    reportType=PolicySettings
    touch /Users/"$loggedInUser"/Desktop/"${reportType}_${time}".csv

# adds header fields to the CSV
echo "Category","Policy ID","Policy Name","Enabled","Trigger Type","Trigger Enrollment Complete","Custom Trigger","Frequency","Scoped to All Computers","Scoped Computer Groups","Scoped User Groups","Scoped Exclusions","Self Service","Packages","Scripts" >> /Users/"$loggedInUser"/Desktop/"${reportType}_${time}".csv

# Grab All Policies
ALL_JSS_POLICIES=$(curl -k -s \
    "Accept: text/xml" --user "${jssUser}:${jssPassword}" \
    ${jssURL}/JSSResource/policies/createdBy/jss -X GET \
    | xmllint --format - | awk -F'>|<' '/<id>/{print $3}')

    while true; do
        read line1 || break
        ALL_POLICY_IDS+=("$line1")
    done < <(printf '%s\n' "$ALL_JSS_POLICIES")

# Loop through all the policies and grab the specified fields
i=0
for id in "${ALL_POLICY_IDS[@]}"; do
    echo "Checking policy number $id"
    
    policyInfo=$( curl -k -s \
    "Accept: text/xml" --user "${jssUser}:${jssPassword}" \
    ${jssURL}/JSSResource/policies/id/$id -X GET )
    
    policyName=$( echo $policyInfo | xpath -e //policy/general/name | sed 's/<[^>]*>//g' )
    policyEnabled=$( echo $policyInfo | xpath -e //policy/general/enabled | sed 's/<[^>]*>//g' )
    triggerType=$( echo $policyInfo | xpath -e //policy/general/trigger | sed 's/<[^>]*>//g' )
    
    triggerEnrollment=$( echo $policyInfo | xpath -e //policy/general/trigger_enrollment_complete | sed 's/<[^>]*>//g' )
    if [[ -z "$triggerEnrollment" ]]; then triggerEnrollment="N/A"; fi
    
    triggerCustom=$( echo $policyInfo | xpath -e //policy/general/trigger_other | sed 's/<[^>]*>//g' )
    if [[ -z "$triggerCustom" ]]; then triggerCustom="N/A"; fi
    
    policyFrequency=$( echo $policyInfo | xpath -e //policy/general/frequency | sed 's/<[^>]*>//g' )
    if [[ -z "$policyFrequency" ]]; then policyFrequency="N/A"; fi
    
    policyCategory=$( echo $policyInfo | xpath -e //policy/general/category/name | sed 's/<[^>]*>//g' )
    if [[ -z "$policyCategory" ]]; then policyCategory="N/A"; fi
    
    scopeAll=$( echo $policyInfo | xpath -e //policy/scope/all_computers | sed 's/<[^>]*>//g' )
    if [[ -z "$scopeAll" ]]; then scopeAll="N/A"; fi
    
    scopeGroup=$( echo $policyInfo | xpath -e //policy/scope/computer_groups/computer_group/name | sed 's/<[^>]*>//g' )
    scopeGroup=$( echo $scopeGroup | xargs )
    if [[ -z "$scopeGroup" ]]; then scopeGroup="N/A"; fi
    
    scopeLimit=$( echo $policyInfo | xpath -e //policy/scope/limitations/user_groups/user_group/name | sed 's/<[^>]*>//g' )
    scopeLimit=$( echo $scopeLimit | xargs )
    if [[ -z "$scopeLimit" ]]; then scopeLimit="N/A"; fi
    
    scopeExclusions=$( echo $policyInfo | xpath -e //policy/scope/exclusions/computer_groups/computer_group/name | sed 's/<[^>]*>//g' )
    scopeExclusions=$( echo $scopeExclusions | xargs )
    if [[ -z "$scopeExclusions" ]]; then scopeExclusions="N/A"; fi
    
    policySelfService=$( echo $policyInfo | xpath -e //policy/self_service/use_for_self_service | sed 's/<[^>]*>//g' )
    if [[ -z "$policySelfService" ]]; then policySelfService="N/A"; fi
    
    policyPackages=$( echo $policyInfo | xpath -e //policy/package_configuration/packages/package/name | sed 's/<[^>]*>//g' )
    policyPackages=$( echo $policyPackages | xargs )
    if [[ -z "$policyPackages" ]]; then policyPackages="N/A"; fi
    
    policyScripts=$( echo $policyInfo | xpath -e //policy/scripts/script/name | sed 's/<[^>]*>//g' )
    policyScripts=$( echo $policyScripts | xargs )
    if [[ -z "$policyScripts" ]]; then policyScripts="N/A"; fi
    
    # Update the CSV with the Policy Data
    echo "$policyCategory","$id","$policyName","$policyEnabled","$triggerType","$triggerEnrollment","$triggerCustom","$policyFrequency","$scopeAll","$scopeGroup","$scopeLimit","$scopeExclusions","$policySelfService","$policyPackages","$policyScripts" >> /Users/"$loggedInUser"/Desktop/"${reportType}_${time}".csv
    let i=$((i+1))
done

echo "Complete."

exit 0