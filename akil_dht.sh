
    cd ~/
    curl http://www.airspayce.com/mikem/bcm2835/bcm2835-1.56.tar.gz > bcm2835-1.56.tar.gz
    tar zxvf bcm2835-1.56.tar.gz
    cd bcm2835-1.56
    ./configure
    make
    sudo make check
    sudo make install
    cd ~/
    sudo npm install --unsafe-perm -g node-dht-sensor
    sudo npm install --unsafe-perm -g node-red-contrib-dht-sensor
