#!/bin/bash
#
# This script works with the NordVPN Linux CLI.  I started
# writing it to save some keystrokes on my Home Theatre PC.
# It keeps evolving and is still a work in progress. Bash
# scripting is new to me and I'm learning as I go.  I added
# a lot of comments to help fellow newbies customize the script.
#
# It looks like this:  https://imgur.com/a/3LMBATC
# /u/pennyhoard20 on reddit
#
# Last tested with NordVPN Version 3.9.5 on Linux Mint 19.3
# (Bash 4.4.20) May 27 2021
#
# =========================================================
# Instructions
# 1) Save as nordlist.sh
#       For convenience I use a directory that is listed in my PATH (echo $PATH)
#       eg. /home/username/bin/nordlist.sh
# 2) Make the script executable with
#       "chmod +x nordlist.sh"
# 3) For the customized menu ASCII and to generate ASCII headings two small programs are required *
#       "figlet" (ASCII generator) and "lolcat" (colorizer).  Highly recommended for this script.
#       eg.  "sudo apt-get install figlet && sudo apt-get install lolcat"
# 4) At the terminal type "nordlist.sh"
#
# =========================================================
# * The script will work without figlet and lolcat after these modifications:
# 1) In "function logo"
#       - change "custom_ascii" to "std_ascii"
# 2) In "function heading"
#       - remove the hash mark (#) before "echo"
#       - put a hash mark (#) before the "figlet" command
#
# =========================================================
# Customization Notes
#   (none of these are required to be changed)
#
#   The Main Menu starts on line 1141.
#    - Recommend configuring the first six main menu items to suit your needs.
#
#   (CTRL-F)
#   Specify your P2P preferred country in "function fp2p"
#   Specify your Obfuscated_Servers preferred country in "function fobservers"
#   Specify your Auto-Connect country and city in "function fautoconnect"
#   Specify your default alternate DNS servers in "function fcustomdns"
#   Add your Whitelist configuration commands to "function fwhitelist"
#   Specify a default server choice in "function ftools"
#   Choose to Rate Server when disconnecting (via main menu) in "function fdisconnect"
#   To connect to cities without prompting change "333" in "function fcountries"
#   Adjust the "COLUMNS" value if the menu looks jumbled or to match your terminal.
#
#   Change the main menu figlet ASCII style in "function custom_ascii"
#   Choose which indicators to display on the main menu in "function logo"
#   Change the figlet ASCII style for headings in "function "heading"
#   If needed change the highlight-text and indicator colors under "COLORS"
#
# =========================================================
#
# VARIABLES
#
# Store info in arrays (BASH v4)
readarray -t nstat < <( nordvpn status | tr -d '\r' )
readarray -t nsets < <( nordvpn settings | tr -d '\r' )
#
function nstatbl () {   # search "status" array by line
    printf '%s\n' "${nstat[@]}" | grep -i $1
}
function nsetsbl () {   # search "settings" array by line
    printf '%s\n' "${nsets[@]}" | grep -i $1
}
# Exit if an update is available.
# (Variables won't be set correctly with an update notice.)
if nstatbl "update"; then
    echo
    echo "** Please update NordVPN."
    echo
    exit
fi
# When disconnected, $connected is the only variable from nstat
connected=$(nstatbl "Status" | awk '{ print $4 }')
srvname=$(nstatbl "server" | cut -f3 -d' ')                 # full hostname
server=$(nstatbl "server" | cut -f3 -d' ' | cut -f1 -d'.')  # shortened hostname
#country and city names may have spaces eg. "United States"
country=$(nstatbl "Country" | cut -f2 -d':' | cut -c 2-)
city=$(nstatbl "City" | cut -f2 -d':' | cut -c 2-)
ipaddr=$(nstatbl "IP" | cut -f 4 -d' ')             # IP address only
ip=$(nstatbl "IP" | cut -f 3-4 -d' ')               # includes "IP: "
technology2=$(nstatbl "technology" | cut -f3 -d' ')     # no value when disconnected
protocol2=$(nstatbl "protocol" | cut -f3 -d' ')         # no value when disconnected
transferd=$(nstatbl "Transfer" | cut -f 2-3 -d' ')  # download stat with units
transferu=$(nstatbl "Transfer" | cut -f 5-6 -d' ')  # upload stat with units
transfer="\u25bc $transferd  \u25b2 $transferu"     # unicode up/down arrows
uptime=$(nstatbl "Uptime" | cut -f 1-5 -d' ')
#
technology=$(nsetsbl "Technology" | awk '{ print $4 }')
protocol=$(nsetsbl "Protocol" | cut -f2 -d' ')      # not listed when using NordLynx
firewall=$(nsetsbl "Firewall" | cut -f2 -d' ')
killswitch=$(nsetsbl "Kill" | cut -f3 -d' ')
cybersec=$(nsetsbl "CyberSec" | cut -f2 -d' ')
obfuscate=$(nsetsbl "Obfuscate" | cut -f2 -d' ')    # not listed when using NordLynx
notify=$(nsetsbl "Notify" | cut -f2 -d' ')
autocon=$(nsetsbl "Auto" | cut -f2 -d' ')
dns_set=$(nsetsbl "DNS" | cut -f2 -d' ')        # disabled or not=disabled
dns_srvrs=$(nsetsbl "DNS")                      # Server IPs, includes "DNS: "
#
# To show the protocol for either Technology whether connected or disconnected.
if [[ "$connected" == "Connected" ]]; then
    p_info=$protocol2
elif [[ "$technology" == "NordLynx" ]]; then
    p_info="UDP"
else
    p_info=$protocol
fi
#
# COLORS (BOLD) - (must use "echo -e")
BBlack='\033[1;30m'
BRed='\033[1;31m'
BGreen='\033[1;32m'
BYellow='\033[1;33m'
BBlue='\033[1;34m'
BPurple='\033[1;35m'
BCyan='\033[1;36m'
BWhite='\033[1;37m'
#
Color_Off='\033[0m'
#                       # Change colors here if needed.
EColor=${BGreen}        # Color for Enabled/On indicator
DColor=${BRed}          # Color for Disabled/Off indicator
WColor=${BRed}          # Color for warnings, errors, disconnects
LColor=${BCyan}         # Color for "changes" lists and key info text
#
# Status Indicators
if [[ "$firewall" == "enabled" ]]; then
    fw=(${EColor}[FW]${Color_Off})
else
    fw=(${DColor}[FW]${Color_Off})
fi
#
if [[ "$killswitch" == "enabled" ]]; then
    ks=(${EColor}[KS]${Color_Off})
else
    ks=(${DColor}[KS]${Color_Off})
fi
#
if [[ "$cybersec" == "enabled" ]]; then
    cs=(${EColor}[CS]${Color_Off})
else
    cs=(${DColor}[CS]${Color_Off})
fi
#
if [[ "$obfuscate" == "enabled" ]]; then
    ob=(${EColor}[OB]${Color_Off})
else
    ob=(${DColor}[OB]${Color_Off})
fi
#
if [[ "$notify" == "enabled" ]]; then
    no=(${EColor}[NO]${Color_Off})
else
    no=(${DColor}[NO]${Color_Off})
fi
#
if [[ "$autocon" == "enabled" ]]; then
    ac=(${EColor}[AC]${Color_Off})
else
    ac=(${DColor}[AC]${Color_Off})
fi
#
if [[ "$dns_set" == "disabled" ]]; then # reversed
    dns=(${DColor}[DNS]${Color_Off})
else
    dns=(${EColor}[DNS]${Color_Off})
fi
#
function std_ascii {
# This ASCII can display above the main menu if you
# prefer to use other ASCII art.
# Place any ASCII art between cat << "EOF" and EOF
# and specify std_ascii in "function logo".
cat << "EOF"
 _   _               ___     ______  _   _
| \ | | ___  _ __ __| \ \   / /  _ \| \ | |
|  \| |/ _ \| '__/ _' |\ \ / /| |_) |  \| |
| |\  | (_) | | | (_| | \ V / |  __/| |\  |
|_| \_|\___/|_|  \__,_|  \_/  |_|   |_| \_|

EOF
}
function custom_ascii {
    # This is the customized ASCII generated by figlet, displayed above the main menu.
    # Specify custom_ascii in "function logo".
    # Any text or variable can be used, single or multiple lines.
    if [[ "$connected" == "Connected" ]]; then
        #figlet NordVPN                         # standard font in mono (like std_ascii)
        #figlet NordVPN | lolcat -p 0.8         # standard font colorized
        #figlet -f slant NordVPN | lolcat       # slant font, colorized
        #figlet $city | lolcat -p 1             # display the city name, more rainbow
        figlet -f slant $city | lolcat -p 2    # city in slant font
        #figlet $country | lolcat -p 1.5        # display the country
        #figlet $transferd | lolcat  -p 1       # display the download statistic
        #
    else
        figlet NordVPN                          # style when disconnected
    fi
}
function logo {
    # Specify  std_ascii or custom_ascii on the line below.
    custom_ascii
    #
    echo $connected: $city $country $server \($technology $p_info\)
    echo -e "$transfer   $ip"
    echo -e $uptime $ks$cs$ob     # all indicators: $fw$ks$cs$ob$no$ac$dns
    echo
}
function heading () {
    # This is the ASCII that displays after a menu selection is made.
    clear
    #echo ""; echo -e ${EColor}"** $1 **"${Color_Off}; echo ""
    figlet -f slant "$1" | lolcat -p 1000   # more solid color
}
function discon {
    heading "$opt"
    echo
    echo "Option $REPLY - Connect to $opt"
    echo
    connected=$(nordvpn status | grep Status | awk '{ print $4 }')
    if [[ "$connected" == "Connected" ]]; then
        echo
        echo -e "${WColor}** Disconnect **${Color_Off}"
        echo
        nordvpn disconnect; wait
        echo
        echo "Connect to $opt"
        echo
    fi
}
function discon2 {
    connected=$(nordvpn status | grep Status | awk '{ print $4 }')
    if [[ "$connected" == "Connected" ]]; then
        echo
        echo -e "${WColor}** Disconnect **${Color_Off}"
        echo
        nordvpn disconnect; wait
        echo
    fi
    echo
}
function status {
    echo
    nordvpn settings
    echo
    nordvpn status
    echo
    date
    echo
}
function warning {
    connected=$(nordvpn status | grep Status | awk '{ print $4 }')
    if [[ "$connected" == "Connected" ]]; then
        echo -e "${WColor}** Changing this setting will disconnect the VPN **${Color_Off}"
        echo
    fi
}
function main_menu {
    # To always show the logo with updated info above the main menu.
    # (should not create more processes)
    echo
    echo
    read -n 1 -s -r -p "Press any key for the menu..."
    exec bash "$0" "$@"
}
function fcountries {
    # submenu for all available countries and cities
    heading "Countries"
    countrylist=($(nordvpn countries | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | tr -d '\r' | sort | tail -n +3))
    # Replaced "Bosnia_And_Herzegovina" with "Sarajevo" to help compact the list.
    countrylist=("${countrylist[@]/Bosnia_And_Herzegovina/Sarajevo}")
    countrylist+=( "Exit" )
    numcountries=${#countrylist[@]}
    if [[ "$obfuscate" == "enabled" ]]; then
        echo -e "$ob Countries with Obfuscation support:"
        echo
    fi
    PS3=$'\n''Choose a Country: '
    select xcountry in "${countrylist[@]}"
    do
        if [[ "$xcountry" == "Exit" ]]; then
            main_menu
        fi
        if (( 1 <= $REPLY )) && (( $REPLY <= $numcountries )); then
            #
            # CITIES
            #
            heading "$xcountry"
            echo
            if [[ "$obfuscate" == "enabled" ]]; then
                echo -e "$ob Cities in $xcountry with Obfuscation support:"
                echo
            fi
            if [[ $xcountry == "Sarajevo" ]]; then  # special case
                xcountry="Bosnia_and_Herzegovina"
            fi
            citylist=($(nordvpn cities $xcountry | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | tr -d '\r' | sort | tail -n +3))
            citylist+=( "Default" )
            citylist+=( "Exit" )
            numcities=${#citylist[@]}
            if [[ $numcities == "333" ]]; then      # change 333 to 3 for immediate connection
                echo "Only one available city in $xcountry."
                echo
                echo -e "Connecting to ${LColor}${citylist[0]}${Color_Off}."
                echo
                discon2
                nordvpn connect $xcountry
                status
                exit
            fi
            PS3=$'\n''Connect to City: '
            select xcity in "${citylist[@]}"
            do
                if [[ "$xcity" == "Exit" ]]; then
                    main_menu
                fi
                if [[ "$xcity" == "Default" ]]; then
                    echo
                    echo "Connecting to the best available city."
                    echo
                    discon2
                    nordvpn connect $xcountry
                    status
                    exit
                fi
                if (( 1 <= $REPLY )) && (( $REPLY <= $numcities )); then
                    heading "$xcity"
                    echo
                    echo "Connecting to $xcity, $xcountry."
                    echo
                    discon2
                    nordvpn connect $xcountry $xcity
                    status
                    exit
                else
                    echo
                    echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                    echo
                    echo "Select any number from 1-$numcities ($numcities to Exit)."
                fi
            done
        else
            echo
            echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
            echo
            echo "Select any number from 1-$numcountries ($numcountries to Exit)."
        fi
    done
}
function fallgroups {
    # submenu for all available groups
    heading "All Groups"
    grouplist=($(nordvpn groups | awk '{for(i=1;i<=NF;i++){printf "%s\n", $i}}' | tr -d '\r' | sort | tail -n +3))
    grouplist+=( "Exit" )
    numgroups=${#grouplist[@]}
    echo "Groups that are available with"
    echo
    echo -e "Technology: ${LColor}$technology${Color_Off}"
    if [[ "$technology" == "OpenVPN" ]]; then
        echo -e "Obfuscate: ${LColor}$obfuscate${Color_Off}"
    fi
    echo
    PS3=$'\n''Connect to Group: '
    select xgroup in "${grouplist[@]}"
    do
        if [[ "$xgroup" == "Exit" ]]; then
            main_menu
        fi
        if (( 1 <= $REPLY )) && (( $REPLY <= $numgroups )); then
            echo
            echo "Connecting to $xgroup."
            echo
            discon2
            nordvpn connect $xgroup
            status
            exit
        else
            echo
            echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
            echo
            echo "Select any number from 1-$numgroups ($numgroups to Exit)."
        fi
    done
}
function fobservers {
    # Specify your preferred Obfuscated_Servers country on the
    # line below (not required) (location must support obfuscation)
    obwhere=""   # eg "United_States"
    #
    # Not available with NordLynx
    heading "Obfuscated"
    echo "Obfuscated servers are specialized VPN servers that"
    echo "hide the fact that you’re using a VPN to reroute your"
    echo "traffic. They allow users to connect to a VPN even in"
    echo "heavily restrictive environments."
    echo
    echo "To connect to the Obfuscated_Servers group the"
    echo "following changes will be made (if necessary):"
    echo -e ${LColor}
    echo "Disconnect the VPN."
    echo "Set Technology to OpenVPN."
    echo "Specify the Protocol."
    echo "Set Obfuscate to enabled."
    echo "Connect to the Obfuscated_Servers group $obwhere"
    echo -e ${Color_Off}
    read -n 1 -r -p "Proceed? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$technology" == "NordLynx" ]]; then
            nordvpn set technology OpenVPN; wait
            obfuscate=$(nordvpn settings | grep Obfuscate | cut -f2 -d' ')
        fi
        ask_protocol
        if [[ "$obfuscate" == "disabled" ]]; then
            nordvpn set obfuscate enabled; wait
        fi
        echo
        echo "Connect to the Obfuscated_Servers group $obwhere"
        echo
        nordvpn connect --group Obfuscated_Servers $obwhere
        status
        exit
    else
        echo
        echo "No changes made."
        main_menu
    fi
}
function fdoublevpn {
    # Not available with NordLynx
    # Not available with obfuscate enabled
    heading "Double-VPN"
    echo "Double VPN is a privacy solution that sends your internet"
    echo "traffic through two servers, encrypting it twice."
    echo
    echo "To connect to the Double_VPN group the"
    echo "following changes will be made (if necessary):"
    echo -e ${LColor}
    echo "Disconnect the VPN."
    echo "Set Technology to OpenVPN."
    echo "Specify the Protocol."
    echo "Set Obfuscate to disabled."
    echo "Connect to the Double_VPN group."
    echo -e ${Color_Off}
    read -n 1 -r -p "Proceed? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$technology" == "NordLynx" ]]; then
            nordvpn set technology OpenVPN; wait
            obfuscate=$(nordvpn settings | grep Obfuscate | cut -f2 -d' ')
        fi
        ask_protocol
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
        fi
        echo
        echo "Connect to the Double_VPN group."
        echo
        nordvpn connect Double_VPN
        status
        exit
    else
        echo
        echo "No changes made."
        main_menu
    fi
}
function fonion {
    # Not available with obfuscate enabled
    heading "Onion+VPN"
    echo "Onion over VPN is a privacy solution that sends your "
    echo "internet traffic through a VPN server and then"
    echo "through the Onion network."
    echo
    echo "To connect to the Onion_Over_VPN group the"
    echo "following changes will be made (if necessary):"
    echo -e ${LColor}
    echo "Disconnect the VPN."
    echo "Set Obfuscate to disabled."
    echo "Connect to the Onion_Over_VPN group."
    echo -e ${Color_Off}
    read -n 1 -r -p "Proceed? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
            ask_protocol
        fi
        echo
        echo "Connect to the Onion_Over_VPN group."
        echo
        nordvpn connect Onion_Over_VPN
        status
        exit
    else
        echo
        echo "No changes made."
        main_menu
    fi
}
function fp2p {
    # Specify your preferred P2P country on the line below (not required)
    p2pwhere=""   # eg "United_States"
    #
    # P2P not available with obfuscate enabled
    heading "Peer to Peer"
    echo "Peer to Peer - sharing information and resources directly"
    echo "without relying on a dedicated central server."
    echo
    echo "To connect to the P2P group the following"
    echo "changes will be made (if necessary):"
    echo -e ${LColor}
    echo "Disconnect the VPN."
    echo "Set Obfuscate to disabled."
    echo "Connect to the P2P group $p2pwhere"
    echo -e ${Color_Off}
    read -n 1 -r -p "Proceed? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$obfuscate" == "enabled" ]]; then
            nordvpn set obfuscate disabled; wait
        fi
        if [[ "$protocol" == "TCP" ]]; then
            ask_protocol
        fi
        echo
        echo "Connect to the P2P group $p2pwhere"
        echo
        nordvpn connect --group P2P $p2pwhere
        status
        exit
    else
        echo
        echo "No changes made."
        main_menu
    fi
}
function ftechnology {
    heading "Technology"
    echo
    warning
    echo "OpenVPN is an open-source VPN protocol and is required to"
    echo " use Obfuscated or Double-VPN servers and to use TCP."
    echo "NordLynx is built around the WireGuard VPN protocol"
    echo " and may be faster with less overhead."
    echo
    echo -e "Currently using ${LColor}$technology${Color_Off}."
    echo "Options are OpenVPN and NordLynx."
    echo
    read -n 1 -r -p "Change the Technology? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$technology" == "OpenVPN" ]]; then
            if [[ "$obfuscate" == "enabled" ]]; then
                nordvpn set obfuscate disabled; wait
                echo
            fi
            if [[ "$protocol" == "TCP" ]]; then
                nordvpn set protocol UDP; wait
                echo
            fi
            nordvpn set technology NordLynx; wait
        else
            nordvpn set technology OpenVPN; wait
            ask_protocol
        fi
    else
        echo
        echo "No changes made."
    fi
    main_menu
}
function fprotocol {
    # NordLynx = UDP only
    heading "Protocol"
    if [[ "$technology" == "NordLynx" ]]; then
        echo
        echo -e "Technology is currently set to ${LColor}NordLynx${Color_Off}."
        echo
        echo "No protocol to specify when using NordLynx,"
        echo "WireGuard supports UDP only."
        echo
        echo "Change Technology to OpenVPN to use TCP or UDP."
        echo
        read -n 1 -r -p "Go to the 'Technology' setting? (y/n) "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ftechnology
        fi
    else
        warning
        echo "UDP is mainly used for online streaming and downloading."
        echo "TCP is more reliable but also slightly slower than UDP and"
        echo " is mainly used for web browsing."
        ask_protocol
    fi
    main_menu
}
function ask_protocol {
    # Ask to choose TCP/UDP if changing to OpenVPN, using Obfuscate,
    # and when connecting to Obfuscated or Double-VPN Servers
    #
    # need to set $protocol if technology just changed from NordLynx
    protocol=$(nordvpn settings | grep Protocol | cut -f2 -d' ')
    echo
    echo -e "The Protocol is set to ${LColor}$protocol${Color_Off}."
    echo "Options are UDP and TCP."
    echo
    read -n 1 -r -p "Change the Protocol? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        if [[ "$protocol" == "UDP" ]]; then
            nordvpn set protocol TCP; wait
        else
            nordvpn set protocol UDP; wait
        fi
        echo
    else
        echo
        echo -e "Continue to use ${LColor}$protocol${Color_Off}."
        echo
    fi
}
function ffirewall {
    heading "Firewall"
    echo "Enable or Disable the NordVPN firewall."
    echo
    echo -e "$fw The Firewall is ${LColor}$firewall${Color_Off}."
    echo
    read -n 1 -r -p "Change the Firewall setting? (y/n) "
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$firewall" == "enabled" ]]; then
            nordvpn set firewall disabled; wait
        else
            nordvpn set firewall enabled; wait
        fi
    else
        echo "No changes made."
    fi
    main_menu
}
function fkillswitch {
    heading "Kill Switch"
    echo "Kill Switch is a feature helping you prevent unprotected"
    echo "access to the internet when your traffic doesn't go"
    echo "through a NordVPN server."
    echo
    echo -e "$ks The Kill Switch is ${LColor}$killswitch${Color_Off}."
    echo
    read -n 1 -r -p "Change the Kill Switch setting? (y/n) "
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$killswitch" == "enabled" ]]; then
            nordvpn set killswitch disabled; wait
        else
            nordvpn set killswitch enabled; wait
        fi
    else
        echo "No changes made."
    fi
    main_menu
}
function fcybersec {
    heading "CyberSec"
    echo
    echo "CyberSec is a feature protecting you from ads,"
    echo "unsafe connections, and malicious sites."
    echo
    echo -e "Enabling CyberSec disables custom DNS $dns"
    echo
    echo -e "$cs CyberSec is ${LColor}$cybersec${Color_Off}."
    echo
    read -n 1 -r -p "Change the CyberSec setting? (y/n) "
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$cybersec" == "enabled" ]]; then
            nordvpn set cybersec disabled; wait
        else
            if [[ "$dns_set" != "disabled" ]]; then
                nordvpn set dns disabled; wait
                echo
            fi
            nordvpn set cybersec enabled; wait
        fi
    else
        echo "No changes made."
    fi
    main_menu
}
function fobfuscate {
    # Obfuscate not available when using NordLynx
    # must disconnect/reconnect to change setting
    heading "Obfuscate"
    if [[ "$technology" == "NordLynx" ]]; then
        echo -e "Technology is currently set to ${LColor}NordLynx${Color_Off}."
        echo
        echo "Obfuscation is not available when using NordLynx."
        echo "Change Technology to OpenVPN to use Obfuscation."
        echo
        read -n 1 -r -p "Go to the 'Technology' setting? (y/n) "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ftechnology
        fi
    else
        warning
        echo "Obfuscated servers can bypass internet restrictions such"
        echo "as network firewalls.  They are recommended for countries"
        echo "with restricted access. "
        echo
        echo "Only certain NordVPN locations support obfuscation."
        echo
        echo "Recommend connecting to the 'Obfuscated' group or through"
        echo "'Countries' when Obfuscate is enabled.  Attempting to"
        echo "connect to unsupported locations will cause an error."
        echo
        echo -e "$ob Obfuscate is ${LColor}$obfuscate${Color_Off}."
        echo
        read -n 1 -r -p "Change the Obfuscate setting? (y/n) "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            discon2
            if [[ "$obfuscate" == "enabled" ]]; then
                nordvpn set obfuscate disabled; wait
            else
                nordvpn set obfuscate enabled; wait
            fi
            ask_protocol
        else
            echo
            echo "No changes made."
        fi
    fi
    main_menu
}
function fnotify {
    heading "Notify"
    echo
    echo "Send OS notifications when the VPN status changes."
    echo
    echo -e "$no Notify is ${LColor}$notify${Color_Off}."
    echo
    read -n 1 -r -p "Change the Notify setting? (y/n) "
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$notify" == "enabled" ]]; then
            nordvpn set notify disabled; wait
        else
            nordvpn set notify enabled; wait
        fi
    else
        echo "No changes made."
    fi
    main_menu
}
function fautoconnect {
    # specify your auto-connect location on the line below (not required)
    acwhere=""  # eg "Canada Vancouver"
    #
    heading "AutoConnect"
    echo "Automatically connect to the VPN on startup."
    echo
    echo -e "$ac Auto-Connect is ${LColor}$autocon${Color_Off}."
    echo
    read -n 1 -r -p "Change the Auto-Connect setting? (y/n) "
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$autocon" == "enabled" ]]; then
            nordvpn set autoconnect disabled; wait
        else
            echo "Enable Auto Connect $acwhere"
            echo
            nordvpn set autoconnect enabled $acwhere; wait
        fi
    else
        echo "No changes made."
    fi
    main_menu
}
function fcustomdns {
    #specify your default alternate DNS servers on the line below
    default_dns="103.86.96.100 103.86.99.100"
    #
    heading "Custom DNS"
    echo "The NordVPN app automatically uses NordVPN DNS servers"
    echo "to prevent DNS leaks. (103.86.96.100 and 103.86.99.100)"
    echo "You can specify your own Custom DNS servers instead."
    echo
    echo -e "Enabling Custom DNS disables CyberSec $cs"
    echo
    if [[ "$dns_set" == "disabled" ]]; then
        echo -e "$dns Custom DNS is ${LColor}disabled${Color_Off}."
    else
        echo -e "$dns Custom DNS is ${LColor}enabled${Color_Off}."
        echo "Custom $dns_srvrs"
    fi
    echo
    read -n 1 -r -p "Change the setting? (y/n) "
    echo
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$dns_set" == "disabled" ]]; then
            echo "Enter the DNS server IPs or hit 'Enter' for default."
            echo "Default: $default_dns"
            echo
            read -r -p "Two Custom DNS servers: " dns2srvrs
            dns2srvrs=${dns2srvrs:-$default_dns}
            echo
            if [[ "$cybersec" == "enabled" ]]; then
                nordvpn set cybersec disabled; wait
                echo
            fi
            nordvpn set dns $dns2srvrs; wait
        else
            nordvpn set dns disabled; wait
        fi
    else
        echo "No changes made."
    fi
    main_menu
}
function fwhitelist {
    heading "Whitelist"
    echo "This is a work in progress."
    echo
    echo "Edit the script to add your whitelist commands to"
    echo " 'function fwhitelist' "
    echo
    echo "This option may be useful to restore a default whitelist"
    echo "configuration after using 'Reset' or making other changes."
    echo
    echo
    read -n 1 -r -p "Apply your default whitelist settings? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Enter one command per line.  Example:
        #
        #nordvpn whitelist remove all    # Clear the Whitelist
        #nordvpn whitelist add subnet 192.168.1.0/24
        #
        echo
    else
        echo
        echo "No changes made."
    fi
    main_menu
}
function faccount {
    # submenu for NordVPN Account options
    heading "Account"
    PS3=$'\n''Choose an Option: '
    submacct=("Login" "Logout" "Account Info" "Register" "Nord Version" "Nord Manual" "Exit")
    numsubmacct=${#submacct[@]}
    select acc in "${submacct[@]}"
    do
        case $acc in
            "Login")
                echo
                nordvpn login
                echo
                ;;
            "Logout")
                echo
                nordvpn logout
                echo
                ;;
            "Account Info")
                echo
                nordvpn account
                echo
                ;;
            "Register")
                echo
                echo "Registers a new user account."
                echo
                echo "Need to disconnect the VPN."
                echo
                echo "* untested"
                echo
                read -n 1 -r -p "Proceed? (y/n) "
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    discon2
                    nordvpn register
                fi
                ;;
            "Nord Version")
                echo
                nordvpn --version
                ;;
            "Nord Manual")
                echo
                man nordvpn
                ;;
            "Exit")
                main_menu
                ;;
            *)
                echo
                echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                echo
                echo "Select any number from 1-$numsubmacct ($numsubmacct to Exit)."
                ;;
        esac
    done
}
function freset {
    heading "Reset Nord"
    echo "Reset the NordVPN app to default settings and logout."
    echo -e ${WColor}
    echo "Send commands:"
    echo "nordvpn whitelist remove all"
    echo "nordvpn set defaults"
    echo "restart nordvpn services"
    echo -e ${Color_Off}
    echo "Requires NordVPN username/password to reconnect."
    echo
    read -n 1 -r -p "Proceed? (y/n) "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        discon2
        nordvpn whitelist remove all; wait
        echo
        nordvpn set defaults; wait
        echo
        read -n 1 -s -r -p "Press any key to restart services..."
        frestart
    fi
    main_menu
}
function frestart {
    # "Restart" will ask for a sudo password to
    # send the commands that restart nordvpnd
    #
    #  troubleshooting
    #  systemctl status nordvpnd.service
    #  systemctl status nordvpn.service
    #  journalctl -u nordvpnd.service
    #  journalctl -xe
    #  sudo service network-manager restart
    #
    heading "Restart"
    echo "Restart nordvpn services."
    echo
    echo "Sending commands:"
    echo "sudo systemctl restart nordvpnd.service"
    echo "sudo systemctl restart nordvpn.service"
    echo
    echo "(CTRL-C to quit) x3"
    echo
    sudo systemctl restart nordvpnd.service
    sudo systemctl restart nordvpn.service
    echo
    echo "Please wait 10s for the service to restart..."
    echo "If Auto-Connect is enabled NordVPN will reconnect."
    echo
    for t in {10..1}; do
        echo -n "$t "; sleep 1
    done
    status
    exit
}
function rate_server {
    echo
    while true
    do
        echo "How would you rate your connection quality?"
        echo -e "${DColor}Terrible${Color_Off} <_1__2__3__4__5_> ${EColor}Excellent${Color_Off}"
        echo
        read -n 1 -r -p "$(echo -e Rating 1-5 [e${LColor}x${Color_Off}it]): " rating
        echo
        if [[ $rating =~ ^[Xx]$ ]]; then
            break
        fi
        if [[ $rating == "" ]]; then
            break
        fi
        if (( 1 <= $rating )) && (( $rating <= 5 )); then
            echo
            nordvpn rate $rating
            break
        else
            echo
            echo -e "${WColor}** Please choose a number from 1 to 5"
            echo -e "('Enter' or 'x' to exit)${Color_Off}"
            echo
        fi
    done
}
function ftools {
    # Specify a VPN hostname/IP to use for testing while the VPN is disconnected.
    # Can still enter any hostname later, this is just a default choice.
    default_host="ca1207.nordvpn.com"   # eg. "ca1207.nordvpn.com"
    #
    # submenu for Tools
    heading "Tools"
    if [[ "$connected" == "Connected" ]]; then
        echo -e "Server: ${LColor}$srvname${Color_Off}"
        echo "$ipaddr ($technology $p_info) $city $country"
        echo -e "$uptime  $transfer"
        echo
        PS3=$'\n''Choose a tool: '
    else
        echo -e "${WColor}** VPN is Disconnected **${Color_Off}"
        echo
        read -r -p "Hostname/IP [Default $default_host]: " srvname
        srvname=${srvname:-$default_host}
        echo
        echo -e "Use server: ${LColor}$srvname${Color_Off}"
        echo "(Does not affect 'Rate VPN Server')"
        echo
        PS3=$'\n''Choose a tool (VPN Off): '
    fi
    nettools=("Rate VPN Server" "www.speedtest.net" "youtube-dl" "ping vpn" "ping google" "my traceroute" "world map" "Exit")
    numnettools=${#nettools[@]}
    select tool in "${nettools[@]}"
    do
        case $tool in
            "Rate VPN Server")
                rate_server
                ;;
            "www.speedtest.net")
                xdg-open http://www.speedtest.net/  # default browser
                #/usr/bin/firefox --new-window http://www.speedtest.net/
                #/usr/bin/firefox --new-window https://speedof.me/
                #/usr/bin/firefox --new-window https://fast.com
                #/usr/bin/firefox --new-window https://www.linode.com/speed-test/
                #/usr/bin/firefox --new-window http://speedtest-blr1.digitalocean.com/
                ;;
            "youtube-dl")
                # "sudo apt-get install youtube-dl"
                # test speed by downloading a youtube video to /dev/null
                # this video is about 60MB, can use any video
                echo
                youtube-dl -f best --no-part --no-cache-dir -o /dev/null --newline https://www.youtube.com/watch?v=bkZac30P5DM
                echo
                ;;
            "ping vpn")
                echo
                echo "ping -c 5 $srvname"
                echo
                ping -c 5 $srvname
                echo
                ;;
            "ping google")
                clear
                echo
                echo "Ping Google DNS 8.8.8.8, 8.8.4.4"
                echo "Ping Cloudflare DNS 1.1.1.1, 1.0.0.1"
                echo "Ping Telstra Australia 139.130.4.5"
                echo
                echo "(CTRL-C to quit)"
                echo
                echo -e "${LColor}===== Google =====${Color_Off}"
                ping -c 5 8.8.8.8
                echo
                ping -c 5 8.8.4.4
                echo
                echo -e "${LColor}===== Cloudflare =====${Color_Off}"
                ping -c 5 1.1.1.1
                echo
                ping -c 5 1.0.0.1
                echo
                echo -e "${LColor}===== Telstra =====${Color_Off}"
                ping -c 5 139.130.4.5
                echo
                ;;
            "my traceroute")
                mtr $srvname
                ;;
            "world map")
                # may be possible to highlight location?
                # github.com/jakewmeyer/Geo/
                echo
                echo -e "${LColor}OpenStreetMap ASCII World Map${Color_Off}"
                echo "- arrow keys to navigate"
                echo "- 'a' and 'z' to zoom"
                echo "- 'q' to quit"
                echo
                read -n 1 -r -p "telnet mapscii.me? (y/n) "
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    telnet mapscii.me
                fi
                echo
                ;;
            "Exit")
                main_menu
                ;;
            *)
                echo
                echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                echo
                echo "Select any number from 1-$numnettools ($numnettools to Exit)."
                ;;
        esac
    done
}
function fdisconnect {
    heading "Disconnect"
    if [[ "$killswitch" == "enabled" ]]; then
        echo -e "${WColor}** Reminder **${Color_Off}"
        echo -e "$ks The Kill Switch is ${LColor}$killswitch${Color_Off}."
        echo
        read -n 1 -r -p "Disable the Kill Switch? (y/n) "
        echo
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nordvpn set killswitch disabled; wait
        else
            echo
            echo -e "$ks Keep the Kill Switch ${LColor}$killswitch${Color_Off}."
            echo
        fi
    fi
    #rate_server     # uncomment to always rate server on disconnect
    discon2
    status
    exit
}
#
# ====== MAIN MENU ======
#
clear
logo
#
# Adjust the COLUMNS value if the menu looks jumbled or to match your terminal.
COLUMNS=79
#
# To modify the list, for example changing Vancouver to Seattle:
# change "Vancouver" in both the first(horizontal) and second(vertical) list to "Seattle"
# and where it says "nordvpn connect Canada Vancouver" change it to
# "nordvpn connect United_States Seattle".  That's it.
#
# The "Restart" entry will ask for a sudo password - see "function frestart".
#
PS3=$'\n''Choose an option: '
#
mainmenu=("Vancouver" "Toronto" "Montreal" "Canada" "USA" "Discord" "Countries" "Groups" "Settings" "Disconnect" "Exit")
#
select opt in "${mainmenu[@]}"
do
    case $opt in
        "Vancouver")
            discon
            nordvpn connect Canada Vancouver
            status
            break
            ;;
        "Toronto")
            discon
            nordvpn connect Canada Toronto
            status
            break
            ;;
        "Montreal")
            discon
            nordvpn connect Canada Montreal
            status
            break
            ;;
        "Canada")
            discon
            nordvpn connect Canada
            status
            break
            ;;
        "USA")
            discon
            nordvpn connect United_States
            status
            break
            ;;
        "Discord")
            # I use this entry to connect to a specific server which can help
            # avoid repeat authentication requests. It then opens a URL.
            # It may be useful for other sites.
            # Example: NordVPN discord  https://discord.gg/83jsvGqpGk
            heading "Discord"
            discon2
            echo
            echo "Connect to us8247 for Discord"
            echo
            nordvpn connect us8247
            status
            xdg-open https://discord.gg/83jsvGqpGk  # default browser
            # /usr/bin/firefox --new-window https://discord.gg/83jsvGqpGk
            break
            ;;
        "Countries")
            fcountries
            ;;
        "Groups")
            # submenu for groups
            heading "Groups"
            echo
            PS3=$'\n''Choose a Group: '
            submgroups=("All_Groups" "Obfuscated" "Double-VPN" "Onion+VPN" "P2P" "Exit")
            numsubmgroups=${#submgroups[@]}
            select smg in "${submgroups[@]}"
            do
                case $smg in
                    "All_Groups")
                        fallgroups
                        ;;
                    "Obfuscated")
                        fobservers
                        ;;
                    "Double-VPN")
                        fdoublevpn
                        ;;
                    "Onion+VPN")
                        fonion
                        ;;
                    "P2P")
                        fp2p
                        ;;
                    "Exit")
                        main_menu
                        ;;
                    *)
                        echo
                        echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                        echo
                        echo "Select any number from 1-$numsubmgroups ($numsubmgroups to Exit)."
                        ;;
                esac
            done
            ;;
        "Settings")
            # submenu for settings
            heading "Settings"
            echo
            echo -e "($technology $p_info) $fw$ks$cs$ob$no$ac$dns"
            echo
            PS3=$'\n''Choose a Setting: '
            submsett=("Technology" "Protocol" "Firewall" "KillSwitch" "CyberSec" "Obfuscate" "Notify" "AutoConnect" "Custom-DNS" "Whitelist" "Account" "Reset" "Restart" "Tools" "Exit")
            numsubmsett=${#submsett[@]}
            select sms in "${submsett[@]}"
            do
                case $sms in
                    "Technology")
                        ftechnology
                        ;;
                    "Protocol")
                        fprotocol
                        ;;
                    "Firewall")
                        ffirewall
                        ;;
                    "KillSwitch")
                        fkillswitch
                        ;;
                    "CyberSec")
                        fcybersec
                        ;;
                    "Obfuscate")
                        fobfuscate
                        ;;
                    "Notify")
                        fnotify
                        ;;
                    "AutoConnect")
                        fautoconnect
                        ;;
                    "Custom-DNS")
                        fcustomdns
                        ;;
                    "Whitelist")
                        fwhitelist
                        ;;
                    "Account")
                        faccount
                        ;;
                    "Reset")
                        freset
                        ;;
                    "Restart")
                        frestart
                        ;;
                    "Tools")
                        ftools
                        ;;
                    "Exit")
                        main_menu
                        ;;
                    *)
                        echo
                        echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
                        echo
                        echo "Select any number from 1-$numsubmsett ($numsubmsett to Exit)."
                        ;;
                esac
            done
            ;;
        "Disconnect")
            fdisconnect
            ;;
        "Exit")
            heading "Goodbye!"
            status
            break
            ;;
        *)
            echo
            echo -e "${WColor}** Invalid option: $REPLY${Color_Off}"
            main_menu
            ;;
    esac
done
