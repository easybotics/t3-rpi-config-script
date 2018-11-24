#!/bin/bash
#
# Copyright 2016,2018 JS Foundation and other contributors, https://js.foundation/
# Copyright 2015,2016 IBM Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
echo -ne "\033[2 q"
if [[ -e /mnt/dietpi_userdata ]]; then
    echo -ne "\n\033[1;32mDiet-Pi\033[0m detected - only going to add the  \033[0;36mnode-red-start, -stop, -log\033[0m  commands.\n"
    echo -ne "Flow files and other things worth backing up can be found in the \033[0;36m/mnt/dietpi_userdata/node-red\033[0m directory.\n\n"
    echo -ne "Use the  \033[0;36mdietpi-software\033[0m  command to un-install and re-install \033[38;5;88mNode-RED\033[0m.\n"
    echo "journalctl -f -n 25 -u node-red -o cat" > /usr/bin/node-red-log
    chmod +x /usr/bin/node-red-log
    echo "dietpi-services node-red stop" > /usr/bin/node-red-stop
    chmod +x /usr/bin/node-red-stop
    echo "dietpi-services node-red start" > /usr/bin/node-red-start
    echo "journalctl -f -n 0 -u node-red -o cat" >> /usr/bin/node-red-start
    chmod +x /usr/bin/node-red-start
else

if [ "$EUID" == "0" ]
  then echo -en "\nRoot user detected. Typically install as a normal user. No need for sudo.\r\n\r\n"
  read -p "Are you really sure you want to install as root ? (y/N) ? " yn
  case $yn in
    [Yy]* )
    ;;
    * )
      exit
    ;;
  esac
fi
if [[ $(cat /etc/*-release | grep VERSION=) != *"wheezy"* ]]; then
if [[ "$(uname)" != "Darwin" ]]; then
wget -q --spider https://www.npmjs.com/package/node-red
if  [ $? -eq 0 ]; then
echo -e '\033]2;'Node-RED update'\007'
echo " "
echo "This script will remove versions of Node.js prior to version 6.x, and Node-RED and"
echo "if necessary replace them with Node.js 8.x LTS (carbon) and the latest Node-RED from Npm."
echo " "
echo "It also moves any Node-RED nodes that are globally installed into your user"
echo "~/.node-red/node_modules directory, and adds them to your package.json, so that"
echo "you can manage them with the palette manager."
echo " "
echo "It also tries to run 'npm rebuild' to refresh any extra nodes you have installed"
echo "that may have a native binary component. While this normally works ok, you need"
echo "to check that it succeeds for your combination of installed nodes."
echo " "
echo "To do all this it runs commands as root - please satisfy yourself that this will"
echo "not damage your Pi, or otherwise compromise your configuration."
echo "If in doubt please backup your SD card first."
echo " "

read -p "Are you really sure you want to do this ? [y/N] ? " yn
case $yn in
    [Yy]* )
        echo ""
        EXTRANODES=""
        EXTRAW="update"
        if [ ! -d "/usr/lib/node_modules/node-red-node-serialport" ] && [ ! -d "$HOME/.node-red/node_modules/node-red-node-serialport" ]; then
            read -r -t 15 -p "Would you like to install the Pi-specific nodes ? [y/N] ? " response
            if [[ "$response" =~ ^([yY])+$ ]]; then
                EXTRANODES="node-red-node-random node-red-contrib-ibm-watson-iot node-red-node-ping node-red-contrib-play-audio node-red-node-smooth node-red-node-serialport"
                EXTRAW="install"
            fi
        fi

        # this script assumes that $HOME is the folder of the user that runs node-red
        # that $USER is the user name and the group name to use when running is the
        # primary group of that user
        # if this is not correct then edit the lines below
        NODERED_HOME=$HOME
        NODERED_USER=$USER
        NODERED_GROUP=`id -gn`
        GLOBAL="true"
        TICK='\033[1;32m\u2714\033[0m'
        CROSS='\033[1;31m\u2718\033[0m'
        cd "$NODERED_HOME" || exit 1
        clear
        echo "Running Node-RED $EXTRAW for user $USER at $HOME"
        time1=$(date)
        echo "" | sudo tee -a /var/log/nodered-install.log >>/dev/null
        echo "***************************************" | sudo tee -a /var/log/nodered-install.log >>/dev/null
        echo "" | sudo tee -a /var/log/nodered-install.log >>/dev/null
        echo "Started : "$time1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
        echo "Running for user $USER at $HOME" | sudo tee -a /var/log/nodered-install.log >>/dev/null
        echo -ne '\r\nThis can take 20-30 minutes on the slower Pi versions - please wait.\r\n\n'
        echo -ne '  Stop Node-RED                       \r\n'
        echo -ne '  Remove old version of Node-RED      \r\n'
        echo -ne '  Remove old version of Node.js       \r\n'
        echo -ne '  Install Node.js                     \r\n'
        echo -ne '  Clean npm cache                     \r\n'
        echo -ne '  Install Node-RED core               \r\n'
        echo -ne '  Move global nodes to local          \r\n'
        echo -ne '  Install extra Pi nodes              \r\n'
        echo -ne '  Npm rebuild existing nodes          \r\n'
        echo -ne '  Add menu shortcut                   \r\n'
        echo -ne '  Update systemd script               \r\n'
        # echo -ne '  Update update script                \r\n'
        echo -ne '                                      \r\n'
        echo -ne '\r\nAny errors will be logged to   /var/log/nodered-install.log\r\n'
        echo -ne '\033[14A'

        # stop any running node-red service
        if sudo service nodered stop 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null ; then CHAR=$TICK; else CHAR=$CROSS; fi
        echo -ne "  Stop Node-RED                       $CHAR\r\n"

        # save any global nodes
        GLOBALNODES=$(find /usr/local/lib/node_modules/node-red-* -maxdepth 0 -type d -printf '%f\n' 2>/dev/null)
        GLOBALNODES="$GLOBALNODES $(find /usr/lib/node_modules/node-red-* -maxdepth 0 -type d -printf '%f\n' 2>/dev/null)"
        echo "Found global nodes: $GLOBALNODES :" | sudo tee -a /var/log/nodered-install.log >>/dev/null

        # remove any old node-red installs or files
        sudo apt-get remove -y nodered 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
        # sudo apt-get remove -y node-red-update 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
        sudo rm -rf /usr/local/lib/node_modules/node-red* /usr/local/lib/node_modules/npm /usr/local/bin/node-red* /usr/local/bin/node /usr/local/bin/npm 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
        sudo rm -rf /usr/lib/node_modules/node-red* /usr/bin/node-red* 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
        echo -ne '  Remove old version of Node-RED      \033[1;32m\u2714\033[0m\r\n'

        nv="v0"
        nv2="v0.0.0"
        if [[ -x "$(command -v node)" ]]; then
            nv=`node -v | cut -d "." -f1`
            nv2=`node -v`
        fi
        # maybe remove Node.js - or upgrade if nodesoure.list exists
        if [[ -e $NODERED_HOME/.nvm ]]; then
            echo -ne '  Using NVM to manage Node.js         +   please run   \033[0;36mnvm use lts/*\033[0m   before running ./node-red\r\n'
            export NVM_DIR=$NODERED_HOME/.nvm
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
            nvm install --lts/* >/dev/null 2>&1
            nvm use lts/* >/dev/null 2>&1
            nvm alias default lts/* >/dev/null 2>&1
            GLOBAL="false"
            ln -f -s $NODERED_HOME/.nvm/versions/node/$(nvm current)/lib/node_modules/node-red/red.js  $NODERED_HOME/node-red
            echo -ne "  Update Node.js LTS                  $CHAR"
        elif [[ $(which n) ]]; then
            echo -ne "  Using N to manage Node.js           +\r\n"
            if sudo n lts 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
            echo -ne "  Update Node.js LTS                  $CHAR"
        elif [ "$nv" = "v0" ] || [ "$nv" = "v1" ] || [ "$nv" = "v3" ] || [ "$nv" = "v4" ] || [ "$nv" = "v5" ] || [ "$nv" = "v6" ] || [ "$nv" = "v7" ] || [ "$nv2" = "v8.11.1" ]; then
            if [ -e /etc/apt/sources.list.d/nodesource.list ]; then
                if [ "$nv" = "v0" ] || [ "$nv" = "v1" ] || [ "$nv" = "v3" ] || [ "$nv" = "v4" ] || [ "$nv" = "v5" ] || [ "$nv" = "v6" ] || [ "$nv" = "v7" ] || [ "$nv2" = "v8.11.1" ]; then
                    sudo apt-get remove -y nodejs nodejs-legacy npm 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                    sudo rm -rf /etc/apt/sources.d/nodesource.list /usr/lib/node_modules/npm*
                    if curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
                else
                    CHAR="-"
                fi
                echo -ne "  Remove old version of Node.js       $CHAR\r\n"
                echo -ne "  Update Node.js LTS                  \r"
                if sudo apt-get install -y nodejs 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
                echo -ne "  Update Node.js LTS                  $CHAR"
            else
                # clean out old nodejs stuff
                npv=$(npm -v 2>/dev/null | head -n 1 | cut -d "." -f1)
                sudo apt-get remove -y nodejs nodejs-legacy npm 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                sudo dpkg -r nodejs 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                sudo dpkg -r node 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                sudo rm -rf /opt/nodejs 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                sudo rm -f /usr/local/bin/node* 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                sudo rm -f /usr/local/bin/npm* /usr/local/bin/npx* /usr/lib/node_modules/npm* 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                if [ "$npv" = "1" ]; then
                    sudo rm -rf /usr/local/lib/node_modules/* /usr/lib/node_modules/* 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                fi
                sudo apt-get autoremove -y 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                echo -ne "  Remove old version of Node.js       \033[1;32m\u2714\033[0m\r\n"
                # grab the correct LTS bundle for the processor
                if cat /proc/cpuinfo | grep model | grep -q ARMv6 ; then
                    echo -ne "  Install Node.js for Armv6           \r"
                    f=$(curl -sL https://nodejs.org/download/release/latest-carbon/ | grep "armv6l.tar.gz" | cut -d '"' -f 2)
                    curl -sL -o node.tgz https://nodejs.org/download/release/latest-carbon/$f 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                    # unpack it into the correct places
                    hd=$(head -c 9 node.tgz)
                    if [ "$hd" == "<!DOCTYPE" ]; then
                        CHAR="$CROSS File $f not downloaded";
                    else
                        if sudo tar -zxf node.tgz --strip-components=1 -C /usr 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
                    fi
                    # remove the tgz file to save space
                    rm node.tgz 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                    echo -ne "  Install Node.js for Armv6           $CHAR"
                elif [[ $(lsb_release -d) == *"18.10"* ]]; then
                    echo -ne "  Apt install Node.js                 \r"
                    if sudo apt-get install -y nodejs npm curl 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
                    echo -ne "  Apt install Node.js                 $CHAR"
                else
                    echo -ne "  Install Node.js LTS                 \r"
                    # use the official script to install for other debian platforms
                    sudo apt-get install -y curl 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                    if sudo apt-get install -y nodejs 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
                    echo -ne "  Install Node.js LTS                 $CHAR"
                fi
                sudo npm i -g npm 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null;
            fi
        else
            CHAR="-"
            echo -ne "  Remove old version of Node.js       $CHAR\n"
            echo -ne "  Leave existing Node.js              $CHAR"
        fi
        hash -r
        rc=""
        if nov=$(node -v 2>/dev/null); then :; else rc="ERR"; fi
        if npv=$(npm -v 2>/dev/null); then :; else rc="ERR"; fi
        if [[ $rc == "" ]]; then
            echo -ne "   Node $nov   Npm $npv\r\n"
        else
            echo -ne "\b$CROSS   Failed to install Node.js - Exit\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n"
            exit 2
        fi

        # clean up the npm cache and node-gyp
        if [[ $GLOBAL == "true" ]]; then
            sudo npm cache clean --force 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
        else
            npm cache clean --force 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
        fi
        if sudo rm -rf "$NODERED_HOME/.node-gyp" "$NODERED_HOME/.npm" /root/.node-gyp /root/.npm; then CHAR=$TICK; else CHAR=$CROSS; fi
        echo -ne "  Clean npm cache                     $CHAR\r\n"

        # and install Node-RED
        if [[ $GLOBAL == "true" ]]; then
            if sudo npm i -g --unsafe-perm --no-progress node-red@latest 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
        else
            if npm i -g --unsafe-perm --no-progress node-red@latest 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
        fi
        nrv=$(npm --no-progress -g ls node-red | grep node-red | cut -d '@' -f 2 | sudo tee -a /var/log/nodered-install.log) >>/dev/null 2>&1
        echo -ne "  Install Node-RED core               $CHAR   $nrv\r\n"

        # install any nodes, that were installed globally, as local instead
        mkdir -p "$NODERED_HOME/.node-red/node_modules"
        sudo chown -R $NODERED_USER:$NODERED_GROUP $NODERED_HOME/.node-red/ 2>&1 >>/dev/null
        pushd "$NODERED_HOME/.node-red" 2>&1 >>/dev/null
            if [ ! -f "package.json" ]; then
                echo '{' > package.json
                echo '  "name": "node-red-project",' >> package.json
                echo '  "description": "A Node-RED Project",' >> package.json
                echo '  "version": "0.0.1",' >> package.json
                echo '  "dependencies": {' >> package.json
                echo '  }' >> package.json
                echo '}' >> package.json
            fi
            CHAR="-"
            if [[ $GLOBALNODES != " " ]]; then
                if npm i --unsafe-perm --save --no-progress $GLOBALNODES 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
            fi
            echo -ne "  Move global nodes to local          $CHAR\r\n"

            CHAR="-"
            if [[ ! -z $EXTRANODES ]]; then
                echo "Installing extra nodes: $EXTRANODES :" | sudo tee -a /var/log/nodered-install.log >>/dev/null
                if npm i --unsafe-perm --save --no-progress $EXTRANODES 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
            fi
            echo -ne "  Install extra Pi nodes              $CHAR\r\n"

            # try to rebuild any already installed nodes
            if npm rebuild  2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
            echo -ne "  Npm rebuild existing nodes          $CHAR\r\n"
        popd 2>&1 >>/dev/null

        # add the shortcut and start/stop/log scripts to the menu
        sudo mkdir -p /usr/bin
        wget -q --spider https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-icon.svg
        if  [ $? -eq 0 ]; then
            sudo curl -sL -o /usr/share/icons/hicolor/scalable/apps/node-red-icon.svg https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-icon.svg 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo curl -sL -o /usr/share/applications/Node-RED.desktop https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/Node-RED.desktop 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo curl -sL -o /usr/bin/node-red-start https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-start 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo curl -sL -o /usr/bin/node-red-stop https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-stop 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo curl -sL -o /usr/bin/node-red-restart https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-restart 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo curl -sL -o /usr/bin/node-red-log https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-log 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo curl -sL -o /etc/logrotate.d/nodered https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/nodered.rotate 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo chmod +x /usr/bin/node-red-start
            sudo chmod +x /usr/bin/node-red-stop
            sudo chmod +x /usr/bin/node-red-log
            echo -ne "  Add menu shortcut                   $TICK\r\n"
        else
            echo -ne "  Add menu shortcut                   $CROSS\r\n"
        fi

        # add systemd script and configure it for $USER
        if sudo curl -sL -o /lib/systemd/system/nodered.service https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/nodered.service 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
        # set the User Group and WorkingDirectory in nodered.service
        sudo sed -i 's#^User=pi#User='$NODERED_USER'#;s#^Group=pi#Group='$NODERED_GROUP'#;s#^WorkingDirectory=/home/pi#WorkingDirectory='$NODERED_HOME'#;' /lib/systemd/system/nodered.service
        sudo systemctl daemon-reload 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
        echo -ne "  Update systemd script               $CHAR\r\n"

        # on LXDE add launcher to top bar, refresh desktop menu
        file=/home/$NODERED_USER/.config/lxpanel/LXDE-pi/panels/panel
        if [ -e $file ]; then
            if ! grep "Node-RED" $file; then
                match="lxterminal.desktop"
                insert="lxterminal.desktop\n    }\n    Button {\n      id=Node-RED.desktop"
                sudo sed -i "s|$match|$insert|" $file 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
                export DISPLAY=:0 && lxpanelctl restart 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            fi
        fi

        # on Pi, add launcher to top bar, add cpu temp example, make sure ping works, refresh desktop menu
        if sudo grep -q BCM2 /proc/cpuinfo; then
            sudo curl -sL -o /usr/lib/node_modules/node-red-contrib-ibm-watson-iot/examples/Pi\ cpu\ temperature.json https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/Pi%20cpu%20temperature.json 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo setcap cap_net_raw+eip $(eval readlink -f `which node`) 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo setcap cap_net_raw=ep /bin/ping 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
            sudo adduser $NODERED_USER gpio 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
        fi

        # Finally update the update script
        if sudo curl -sL -o /tmp/update-nodejs-and-nodered https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/update-pi 2>&1 | sudo tee -a /var/log/nodered-install.log >>/dev/null; then CHAR=$TICK; else CHAR=$CROSS; fi
        sudo chmod +x /tmp/update-nodejs-and-nodered
        # echo -ne "  Update update script                $CHAR\r\n"
        echo -ne "                                           \r\n"

        echo -ne "\r\n\r\n\r\n"
        echo -ne "All done.\r\n"
        if [[ $GLOBAL == "true" ]]; then
            echo -ne "  You can now start Node-RED with the command  \033[0;36mnode-red-start\033[0m\r\n"
            echo -ne "  or using the icon under   Menu / Programming / Node-RED\r\n"
        else
            echo -ne "  You can now start Node-RED with the command  \033[0;36m./node-red\033[0m\r\n"
        fi
        echo -ne "  Then point your browser to \033[0;36mlocalhost:1880\033[0m or \033[0;36mhttp://{your_pi_ip-address}:1880\033[0m\r\n"
        echo -ne "\r\nStarted  $time1  -  Finished  $(date)\r\n\r\n"
        echo "Finished : "$time1 | sudo tee -a /var/log/nodered-install.log >>/dev/null
    ;;
    * )
        echo " "
        exit 1
    ;;
esac
else
echo " "
echo "Sorry - cannot connect to internet - not going to touch anything."
echo "https://www.npmjs.com/package/node-red   is not reachable."
echo "Please ensure you have a working internet connection."
echo "Return code from wget is "$?
echo " "
exit 1
fi
else
echo " "
echo "Sorry - I'm not supposed to be run on a Mac."
echo "Please see the documentation at http://nodered.org/docs/getting-started/upgrading."
echo " "
exit 1
fi
else
echo " "
echo "Sorry - I'm not able to upgrade old Wheezy installations. Please think about updating."
echo "Please see the documentation at http://nodered.org/docs/getting-started/upgrading."
echo " "
exit 1
fi
fi
if [ -e /tmp/update-nodejs-and-nodered ] && [ -s /tmp/update-nodejs-and-nodered ]; then sudo mv /tmp/update-nodejs-and-nodered /usr/bin/update-nodejs-and-nodered; fi
