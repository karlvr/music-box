#!/bin/bash -eu

apt-get install -y build-essential autoconf automake libtool libdaemon-dev libasound2-dev libpopt-dev libconfig-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev
apt-get install -y wget

WORKDIR=/root/shairport-sync

mkdir -p "$WORKDIR"
pushd "$WORKDIR"

wget https://github.com/mikebrady/shairport-sync/archive/master.tar.gz
tar zxf master.tar.gz
pushd shairport-sync-master

autoreconf -i -f
# Fix rpl_malloc issue
# http://rickfoosusa.blogspot.co.nz/2011/11/howto-fix-undefined-reference-to.html
sed -e 's/^AC_FUNC_MALLOC/#AC_FUNC_MALLOC/' --in-place configure.ac
sed -e 's/^AC_FUNC_REALLOC/#AC_FUNC_REALLOC/' --in-place configure.ac
./configure --with-alsa --with-avahi --with-ssl=openssl --with-metadata --with-soxr --with-systemd
make

getent group shairport-sync &>/dev/null || sudo groupadd -r shairport-sync >/dev/null
getent passwd shairport-sync &> /dev/null || sudo useradd -r -M -g shairport-sync -s /usr/bin/nologin -G audio shairport-sync >/dev/null

make install

if [ -x /usr/bin/mpc ]; then
sed -e '/run_this_before_play_begins/i run_this_before_play_begins = "/usr/bin/mpc stop";' --in-place /etc/shairport-sync.conf
sed -e '/wait_for_completion/i wait_for_completion = "yes";' --in-place /etc/shairport-sync.conf
fi
sed -e '/interpolation = "/i interpolation = "soxr";' --in-place /etc/shairport-sync.conf

systemctl enable shairport-sync

popd
popd

rm -rf "$WORKDIR"
