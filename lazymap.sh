#!/usr/bin/env bash
# LazyMap
# Daniel Compton
# www.commonexploits.com
# contact@commexploits.com
# Twitter = @commonexploits

# Important info - read first!

# Nmap Lazy Script - For Internal Inf Testing.

VERSION="2.7"

#####################################################################################################################

# User config options

# Turn on/off Nmap scan options - Default setting is Full TCP and Quick UDP

FULLTCP="on" # to disable/enable Full TCP Scan set to "off" / "on"
SCRIPT="off" # to disable/enable safe script Scan set to "off" / "on"
QUICKUDP="on" # to disable/enable quick UDP scan set to "off" / "on"
COMMONTCP="off" # to disable/enable common TCP scan set to "off" / "on"

######################################################################################################################
# Script Starts
echo -e "\e[00;32m#############################################################\e[00m"
echo ""
echo "***   Lazymap - Internal Auto Nmap Script Version $VERSION  ***"
echo ""
echo -e "\e[00;32m#############################################################\e[00m"
echo ""
echo -e "\e[01;32m[-]\e[00m All output including hosts up, down, unique ports and an audit of each scan start stop times can be found in the output directory."
echo ""
echo -e "\e[01;32m[-]\e[00m Press Enter to continue"
echo ""
# Check if root
if [[ $EUID -ne 0 ]]; then
        echo ""
        echo -e "\e[01;31m[!]\e[00m This program must be run as root. Run again with 'sudo'"
        echo ""
        exit 1
fi

echo ""
echo -e "\e[01;32m[-]\e[00m The following Interfaces are available"
echo ""
	ip link show | grep 'UP\|DOWN' | cut -d ":" -f 2 |grep -v -i lo | sed -e 's/^[ \t]*//'
echo ""
echo -e "\e[1;31m--------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter the interface to scan from as the source"
echo -e "\e[1;31m--------------------------------------------------\e[00m"
read INT

ifconfig | grep -i -w $INT >/dev/null

if [ $? = 1 ]
	then
		echo ""
		echo -e "\e[1;31m Sorry the interface you entered does not exist or is not up! - check and try again."
		echo ""
		exit 1
else
echo ""
fi
LOCAL=$(ifconfig $INT |grep "inet " |cut -d "" -f 3 | awk '{print $2}')
MASK=$(ifconfig |grep $LOCAL | awk '{print $4}')
CIDR=$(ip addr show $INT |grep inet |grep -v inet6 |cut -d "/" -f 2 | awk '{print $1}')
echo ""
echo ""
echo -e "\e[01;32m[-]\e[00m Your source IP address is set as follows \e[1;32m"$LOCAL"\e[00m with the mask of \e[1;32m"$MASK"(/"$CIDR")\e[00m"
echo ""
ifconfig $INT |grep "inet addr:" |grep "192.168.186.*" >/dev/null 2>&1
if [ $? = 0 ]
	then
		echo -e "\e[1;31m It seems you are running in VMWARE with a NAT network connection."
		echo ""
		echo -e "\e[1;31m If you intend to scan from a static IP you should set the NIC to BRIDGED mode, script will continue but CTRL C to quit and change if required."
		echo ""
		sleep 5
	else
echo ""
fi
echo -e "\e[1;31m------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Would you like to change your source IP address or gateway..? - Enter yes or no and press ENTER"
echo -e "\e[1;31m------------------------------------------------------------------------------------------------------\e[00m"
read IPANSWER
if [ $IPANSWER = yes ]
	then
		echo ""
		echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
		echo -e "\e[01;31m[?]\e[00m Enter the IP address/subnet for the source interface you want to set. i.e 192.168.1.1/24 and press ENTER"
		echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
		read SETIPINT
		ifconfig $INT $SETIPINT up
		SETLOCAL=`ifconfig $INT |grep "inet " |cut -d "" -f 3 | awk '{print $2}'`
		SETMASK=`ifconfig |grep $SETLOCAL | awk '{print $4}'`
		SETCIDR=`ip addr show $INT |grep inet |grep -v inet6 |cut -d "/" -f 2 | awk '{print $1}'`
		echo ""
		echo -e "Your source IP address is set as follows \e[1;33m"$SETLOCAL"\e[00m with the mask of \e[1;33m"$SETMASK"(/"$SETCIDR")\e[00m"
		echo ""
		echo -e "\e[1;31m-------------------------------------------------------------------------------------------\e[00m"
		echo -e "\e[01;31m[?]\e[00m Would you like to change your default gateway..? - Enter yes or no and press ENTER"
		echo -e "\e[1;31m-------------------------------------------------------------------------------------------\e[00m"
		read GATEWAYANSWER
			if [ $GATEWAYANSWER = yes ]
		then
		echo ""
		echo -e "\e[1;31m----------------------------------------------------------\e[00m"
		echo -e "\e[01;31m[?]\e[00m Enter the default gateway you want set and press ENTER"
		echo -e "\e[1;31m----------------------------------------------------------\e[00m"
		read SETGATEWAY
		route add default gw $SETGATEWAY
		echo ""
		echo ""
		echo -e "\e[01;32m[+]\e[00m The default gateway has been added below"
		echo ""
		ROUTEGW=`route |grep -i default`
		echo -e "\e[1;33m$ROUTEGW\e[00m"
		echo ""
	else
echo ""
	fi
fi
echo ""
echo -e "\e[1;31m------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter the reference or client name for the scan"
echo -e "\e[1;31m------------------------------------------------------\e[00m"
read REF
echo ""
echo -e "\e[1;31m-----------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter the IP address/Range or the exact path to an input file (can tab complete)"
echo -e "\e[1;31m-----------------------------------------------------------------------------------------------\e[00m"
read -e RANGE
mkdir "$REF" >/dev/null 2>&1
cd "$REF"
echo "$REF" > REF
echo "$INT" > INT
echo ""
echo -e "\e[1;31m-------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Do you want to exclude any additional IPs from the scan i.e other testers or VMs?"
echo -e "\e[1;31m-------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[-]\e[00m Note - I will auto exclude your source IP address of \e[1;32m"$LOCAL"\e[00m from the scan"
echo ""
echo -e "\e[1;31m----------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter yes or no and press ENTER"
echo -e "\e[1;31m----------------------------------------------\e[00m"
echo ""
read EXCLUDEANS

if [ $EXCLUDEANS = yes ]
		then
			echo ""
			echo -e "\e[1;31m-------------------------------------------------------------------------------------------------------------------------------------\e[00m"
			echo -e "\e[01;31m[?]\e[00m Enter the IP addresses to exclude i.e 192.168.1.1, 192.168.1.1-10 - or the exact path to an input file (can tab complete)"
			echo -e "\e[1;31m-------------------------------------------------------------------------------------------------------------------------------------\e[00m"
			read -e EXCLUDEDIPS
			#check if manual input or a file
			echo $EXCLUDEDIPS |egrep '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}.' >/dev/null 2>&1

			if [ $? = 0 ]
				then
					echo ""
					echo -e "\e[01;32m[-]\e[00m I will exclude the following additional IP addresses from the scan"
					echo ""
					echo $EXCLUDEDIPS |tee excludeiplist
					echo "$LOCAL" >> excludeiplist
					echo ""
				else
					echo ""
					echo -e "\e[01;32m[-]\e[00m You entered a file as the exclusion input, I will just check I can read it ok"
					echo ""
					cat $EXCLUDEDIPS >/dev/null 2>&1
						if [ $? = 1 ]
								then
									echo ""
									echo -e "\e[01;31m[!]\e[00m Sorry I can't read that file, check the path and try again!"
									echo ""
									exit 1
								else
									echo ""
									echo -e "\e[01;32m[+]\e[00m I can read the exclusion file ok, I will exclude the following additional IP addresses from the scan"
									echo ""
									cat $EXCLUDEDIPS |tee excludeiplist
									echo ""
									echo "$LOCAL" >> excludeiplist
						fi
			fi
			EXIP=$(cat excludeiplist)
			EXCLUDE="--excludefile excludeiplist"
			echo "$EXCLUDE" > excludetmp
			echo "$LOCAL" >> excludetmp
			echo -e "\e[01;33m[-]\e[00m The following IP addresses were asked to be excluded from the scan = "$EXIP"" > "$REF"_nmap_hosts_excluded.txt
		else
			EXCLUDE="--exclude "$LOCAL""
			echo "$LOCAL" > excludeiplist
		fi

echo $RANGE |egrep '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}.' >/dev/null 2>&1
if [ $? = 0 ]
	then
		echo ""
		echo -e "\e[01;32m[-]\e[00m You entered a manual IP or range, scan will now start"
		echo ""
		echo -e "\e[01;32m[-]\e[00m $REF - Finding Live hosts via $INT, please wait"
		echo ""
		nmap -e $INT -sn $EXCLUDE -n --stats-every 4 -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -oA "$REF"_nmap_PingScan $RANGE 

		cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep "Up" |awk '{print $2}' > "$REF"_hosts_Up.txt
		cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep  "Down" |awk '{print $2}' > "$REF"_hosts_Down.txt

	else
		echo ""
		echo -e "\e[01;32m[-]\e[00m You entered a file as the input, I will just check I can read it ok"
		cat $RANGE >/dev/null 2>&1
			if [ $? = 1 ]
			then
				echo ""
				echo -e "\e[01;31m[!]\e[00m Sorry I can't read that file, check the path and try again!"
				echo ""
			exit 1
		else
			echo ""
			echo -e "\e[01;32m[+]\e[00m I can read the input file ok, Scan will now start"
			echo ""
			echo -e "\e[01;32m[-]\e[00m $REF - Finding Live hosts via $INT, please wait...\e[00m"
			echo ""
			nmap -e $INT -sn $EXCLUDE -n --stats-every 4 -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -oA "$REF"_nmap_PingScan -iL $RANGE 

		cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep "Up" |awk '{print $2}' > "$REF"_hosts_Up.txt
		cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep  "Down" |awk '{print $2}' > "$REF"_hosts_Down.txt

		fi
fi
echo ""
HOSTSCOUNT=$(cat "$REF"_hosts_Up.txt |wc -l)
HOSTSUPCHK=$(cat "$REF"_hosts_Up.txt)
if [ -z "$HOSTSUPCHK" ]
	then
		echo ""
		echo -e "\e[01;31m[!]\e[00m It seems there are no live hosts present in the range specified..I will run an arp-scan to double check"
		echo ""
		sleep 4
		arp-scan --interface $INT --file "$REF"_hosts_Down.txt > "$REF"_arp_scan.txt 2>&1
		arp-scan --interface $INT --file "$REF"_hosts_Down.txt |grep -i "0 responded" >/dev/null 2>&1
			if [ $? = 0 ]
				then
					echo -e "\e[01;32m[!]\e[00m No live hosts were found using arp-scan - check IP range/source address and try again. It may be there are no live hosts."
					echo ""
					rm "INT" 2>/dev/null
					rm "REF" 2>/dev/null
					rm "excludetmp" 2>/dev/null
					touch "$REF"_no_live_hosts.txt
					exit 1
			else
					arp-scan --interface $INT --file "$REF"_hosts_Down.txt > "$REF"_arp_scan.txt 2>&1
					ARPUP=$(cat "$REF"_arp_scan.txt)
					echo ""
					echo -e "\e[01;33m[-]\e[00m Nmap didn't find any live hosts, but arp-scan found the following hosts within the range...script will exit. Try adding these to the host list to scan."
					echo ""
					rm "INT" 2>/dev/null
					rm "REF" 2>/dev/null
					rm "excludetmp" 2>/dev/null
					echo -e "\e[00;32m$ARPUP\e[00m"
					echo ""
					exit 1
	fi
fi
echo -e "\e[1;32m-----------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[+]\e[00m The following $HOSTSCOUNT hosts were found up for $REF"
echo -e "\e[1;32m-----------------------------------------------------------------\e[00m"
HOSTSUP=$(cat "$REF"_hosts_Up.txt)
echo -e "\e[00;32m$HOSTSUP\e[00m"

if [ $COMMONTCP = "on" ]
then
# Scanning Common TCP Ports
nmap -e $INT -sS $EXCLUDE -Pn -T4 -sV --version-intensity 1 -vvv -oA "$REF"_nmap_CommonPorts -iL "$REF"_hosts_Up.txt -n --min-rate 500
else
echo ""
echo -e "\e[01;33m[-]\e[00m Skipping Common TCP scan as turned off in options"
fi

if [ $QUICKUDP = "on" ]
then
#Scanning Quick UDP (1,000) Ports
nmap -e $INT -sU $EXCLUDE -Pn -T4 -vvv -oA "$REF"_nmap_QuickUDP -iL "$REF"_hosts_Up.txt -n --min-rate 500
else
echo ""
echo -e "\e[01;33m[-]\e[00m Skipping Quick UDP Scan as turned off in options"
fi

if [ $FULLTCP = "on" ]
then
# Scanning Full TCP Ports 
nmap -e $INT -sS $EXCLUDE -Pn -T4 -p- -sV --version-intensity 1 -vvv -oA "$REF"_nmap_FullPorts -iL "$REF"_hosts_Up.txt -n --min-rate 500
else
echo ""
echo -e "\e[01;33m[-]\e[00m Skipping Full TCP as turned off in options"
fi

if [ $SCRIPT = "on" ]
then
    #Script Scan
    UNIQUE=$(cat *.xml |grep -i 'open"' |grep -i "portid=" |cut -d '"' -f 4,5,6| grep -o '[0-9]*' |sort --unique | sort -k1n |paste -s -d, 2>&1)
    if [ -z "$UNIQUE" ]
    then
        echo -e "\e[01;31m[!]\e[00m No open ports were found on any scans"
    else
        $nmap -e $INT -Pn $EXCLUDE -p $UNIQUE -A -vvv -oA "$REF"_nmap_ScriptScan -iL "$REF"_hosts_Up.txt -n --min-rate 250
        echo ""
    fi
else
        echo ""
        echo -e "\e[01;33m[-]\e[00m Skipping Script Scan as turned off in options"
fi

#clear temp files
sleep 5
rm "INT" 2>/dev/null
rm "REF" 2>/dev/null

echo ""
echo -e "\e[01;32m[-]\e[00m Once all scans are complete, press ENTER on this window to list all unique ports found and continue - $REF"
echo ""
echo -e "\e[1;32m----------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[+]\e[00m The following scan start/finish times were recorded for $REF"
echo -e "\e[1;32m----------------------------------------------------------------------------------\e[00m"
echo ""
PINGTIMESTART=`cat "$REF"_nmap_PingScan.nmap 2>/dev/null |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
PINGTIMESTOP=`cat "$REF"_nmap_PingScan.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
COMMONTCPTIMESTART=`cat "$REF"_nmap_CommonPorts.nmap 2>/dev/null  |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
COMMONTCPTIMESTOP=`cat "$REF"_nmap_CommonPorts.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
FULLTCPTIMESTART=`cat "$REF"_nmap_FullPorts.nmap 2>/dev/null |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
FULLTCPTIMESTOP=`cat "$REF"_nmap_FullPorts.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
QUICKUDPTIMESTART=`cat "$REF"_nmap_QuickUDP.nmap 2>/dev/null |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
QUICKUDPTIMESTOP=`cat "$REF"_nmap_QuickUDP.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
SCRIPTTIMESTART=`cat "$REF"_nmap_ScriptScan.nmap 2>/dev/null |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
SCRIPTTIMESTOP=`cat "$REF"_nmap_ScriptScan.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`

if [ -z "$PINGTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Ping sweep started $PINGTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Ping sweep started $PINGTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Ping sweep started $PINGTIMESTART\e[00m - \e[00;32mfinished successfully $PINGTIMESTOP"
		echo "Ping sweep started $PINGTIMESTART - finished successfully $PINGTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$COMMONTCPTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Common TCP scan started $COMMONTCPTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Common TCP scan started $COMMONTCPTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Common TCP scan started $COMMONTCPTIMESTART\e[00m - \e[00;32mfinished successfully $COMMONTCPTIMESTOP"
		echo "Common TCP scan started $COMMONTCPTIMESTART - finished successfully $COMMONTCPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$FULLTCPTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Full TCP scan started $FULLTCPTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Full TCP scan started $FULLTCPTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Full TCP scan started $FULLTCPTIMESTART\e[00m - \e[00;32mfinished successfully $FULLTCPTIMESTOP"
		echo "Full TCP scan started $FULLTCPTIMESTART - finished successfully $FULLTCPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$QUICKUDPTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Quick UDP scan started $QUICKUDPTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Quick UDP scan started $QUICKUDPTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Quick UDP scan started $QUICKUDPTIMESTART\e[00m - \e[00;32mfinished successfully $QUICKUDPTIMESTOP"
		echo "Quick UDP scan started $QUICKUDPTIMESTART - finished successfully $QUICKUDPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$SCRIPTTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Script scan started $SCRIPTTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Script scan started $SCRIPTTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Script scan started $SCRIPTTIMESTART\e[00m - \e[00;32mfinished successfully $SCRIPTTIMESTOP"
		echo "Script scan started $SCRIPTTIMESTART - finished successfully $SCRIPTTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
echo ""
echo -e "\e[1;32m------------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[+]\e[00m Unique TCP and UDP Port Summary - $REF"
echo -e "\e[1;32m------------------------------------------------------------------\e[00m"
UNIQUE=$(cat *.xml |grep -i 'open"' |grep -i "portid=" |cut -d '"' -f 4,5,6| grep -o '[0-9]*' |sort --unique | sort -k1n |paste -s -d, 2>&1)
echo $UNIQUE >"$REF"_nmap_unique_ports.txt
if [ -z "$UNIQUE" ]
then
	echo -e "\e[01;31m[!]\e[00m No open ports were found on any scans"
else
echo -e "\e[00;32m$UNIQUE\e[00m"
echo ""
fi
echo ""
echo -e "\e[1;32m-----------------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[+]\e[00m The following $HOSTSCOUNT hosts were up and scanned for $REF"
echo -e "\e[1;32m-----------------------------------------------------------------------\e[00m"
HOSTSUP=$(cat "$REF"_hosts_Up.txt)
echo -e "\e[00;32m$HOSTSUP\e[00m"
echo ""
echo ""
#Check for excluded IPs
ls "$REF"_nmap_hosts_excluded.txt >/dev/null 2>&1
if [ $? = 0 ]
	then
		echo -e "\e[1;32m--------------------------------------------------------------------------------\e[00m"
		echo -e "\e[01;32m[+]\e[00m The following hosts were requested to be excluded from scans for $REF"
		echo -e "\e[1;32m---------------------------------------------------------------------------------\e[00m"
		EXFIN=$(cat excludeiplist)
		echo -e "\e[00;32m$EXFIN\e[00m"
		echo ""
	else
	echo ""
fi
echo -e "\e[01;33m[-]\e[00m Output files have all been saved to the \e[00;32m"$REF"\e[00m directory"
echo ""

rm "excludeiplist" 2>/dev/null
rm  "excludetmp" 2>/dev/null
exit 0

