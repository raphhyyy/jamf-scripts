#!/bin/sh
## postinstall

#by Raphael Hernandez

#Designed to be used as a post install script in a PKG that contains both the ARM and Intel Rapid7 install scripts. Uses logic to determine the running computers architecture and runs the correct script 

#Path to rapid7 install scripts
rapid7InstallScriptPath="/private/tmp/rapid7agent"

#determine mac architecture 
arch="$(uname -m)"

if [ "$arch" = "x86_64" ]; then
	echo "Running on native Intel"
	rapid7InstallScript="$rapid7InstallScriptPath/agent_installer-x86_64.sh"
elif [ "$arch" = "arm64" ]; then
	echo "Running on ARM"
	rapid7InstallScript="$rapid7InstallScriptPath/agent_installer-arm64.sh"
else
	echo "Running on ${arch}, exiting"
	exit 1
fi

echo $rapid7InstallScript

#Installing Rapid7 using architecture specific script
sudo sh $rapid7InstallScript uninstall --token eu:30a60af6-4870-4170-9a7f-95ae871682df


#cleanup
rm -rf $rapid7InstallScriptPath


exit 0		## Success
exit 1		## Failure


exit 0		## Success
exit 1		## Failure
