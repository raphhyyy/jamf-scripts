#!/bin/bash

# Created by Raphael Hernandez on 1/17/2022


# Identify the username of the logged-in user

currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Create file named "standard" and place in /private/tmp/

touch /private/tmp/standard 

# Populate "standard" file with desired permissions

echo "$currentUser ALL= (ALL) ALL
$currentUser    ALL = (ALL) ALL " >> /private/tmp/standard

# Move "standard" file to /etc/sudoers.d

mv /private/tmp/standard /etc/sudoers.d

# Change permissions for "standard" file

chmod 644 /etc/sudoers.d/standard

exit 0;     ## Sucess
exit 1;     ## Failure