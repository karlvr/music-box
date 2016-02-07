#!/bin/bash -eu

#######################
# Mopidy

apt-get install -y python-setuptools wget

easy_install pip # We use easy_install rather than apt to get the latest pip and to avoid http://stackoverflow.com/questions/27341064/how-do-i-fix-importerror-cannot-import-name-incompleteread

wget -q -O - https://apt.mopidy.com/mopidy.gpg | apt-key add -
wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/jessie.list

apt-get update && apt-get install -y mopidy

# Mopidy extensions
apt-get install -y mopidy-scrobbler mopidy-alsamixer
apt-get install -y mpc

# Mopify
apt-get install -y mopidy-spotify
pip install Mopidy-Mopify

# Nginx
# So we can reverse proxy the HTTP on port 6680
apt-get install -y nginx

cat > /etc/nginx/sites-available/default <<"EOF"
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /var/www/html;

	# Add index.php to the list if you are using PHP
	index index.html index.htm index.nginx-debian.html;

	server_name _;

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		# try_files $uri $uri/ =404;
		proxy_pass http://127.0.0.1:6680;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
	}
}
EOF

invoke-rc.d nginx restart

# Mopidy configuration
cat >> /etc/mopidy/mopidy.conf <<EOF

# http://mopidy.readthedocs.org/en/latest/ext/mpd/
[mpd]
enabled = false
hostname = ::
port = 6600
password =
max_connections = 20
connection_timeout = 60
zeroconf = Mopidy MPD server on $hostname
command_blacklist = listall,listallinfo

# https://docs.mopidy.com/en/latest/ext/http/
[http]
enabled = true
hostname = ::
port = 6680
zeroconf = Mopidy HTTP server on \$hostname

[scrobbler]
enabled = false
username = 
password = 

# https://github.com/mopidy/mopidy-spotify
[spotify]
enabled = false
username = 
password = 
# The bitrate, the quality of the music played by Spotify, can be set to 96, 160 (default) or 320
bitrate = 320

[audio]
mixer = software
#mixer = alsamixer
mixer_volume = 100
output = alsasink

# https://github.com/mopidy/mopidy-alsamixer
[alsamixer]
card = 0
control = PCM
#control = Digital
EOF

update-rc.d mopidy remove && update-rc.d mopidy defaults

if [ -x /bin/systemctl ]; then
	systemctl enable mopidy
else
	invoke-rc.d mopidy start
fi

# Extra utilities
apt-get install -y alsa-utils
