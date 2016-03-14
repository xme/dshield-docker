#!/bin/sh
#
# Start the docker instance with the user API key to report to DShield.
# Based on https://github.com/DShield-ISC/dshield/blob/master/bin/install.sh
#
# 2016/03/14 Created
#

echo "Validating provided credentials..."
cd /root/dshield

# Creating a temporary directory
TMPDIR=`mktemp -d -q /tmp/dshieldinstXXXXXXX`
trap "rm -r $TMPDIR" 0 1 2 5 15

# yes. this will make the random number generator less secure. but remember this is for a honeypot
echo HRNGDEVICE=/dev/urandom > /etc/default/rnd-tools

#export NCURSES_NO_UTF8_ACS=1

nonce=`openssl rand -hex 10`
hash=`echo -n $DSHIELD_EMAIL:$DSHIELD_APIKEY | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' '`
user=`echo $DSHIELD_EMAIL | sed 's/@/%40/'`
curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash > $TMPDIR/checkapi
if grep -q '<result>ok</result>' $TMPDIR/checkapi ; then
	uid=`grep  '<id>.*<\/id>' $TMPDIR/checkapi | sed -E 's/.*<id>([0-9]+)<\/id>.*/\1/'`
	echo "API key verification succeeded!"
else
	echo "API key verification failed!"
	exit
fi

# Generating the cowrie config
cp /srv/cowrie/cowrie.cfg.dist /srv/cowrie/cowrie.cfg
cat >> /srv/cowrie/cowrie.cfg <<EOF
[output_dshield]
userid = $DSHIELD_UID
auth_key = $DSHIELD_APIKEY
batch_size = 1
EOF

# Tuning the cowrie config
sed -i.bak 's/svr04/vm002/' /srv/cowrie/cowrie.cfg

# Make output of simple text commands more real
dmesg > /srv/cowrie/txtcmds/bin/dmesg
mount > /srv/cowrie/txtcmds/bin/mount
ulimit > /srv/cowrie/txtcmds/bin/ulimit
lscpu > /srv/cowrie/txtcmds/usr/bin/lscpu
echo '-bash: emacs: command not found' > /srv/cowrie/txtcmds/usr/bin/emacs
echo '-bash: locate: command not found' > /srv/cowrie/txtcmds/usr/bin/locate

# Launch cowrie!
set -e

cd $(dirname $0)

if [ "$1" != "" ]
then
    VENV="$1"

    if [ ! -d "$VENV" ]
    then
        echo "The specified virtualenv \"$VENV\" was not found!"
        exit 1
    fi

    if [ ! -f "$VENV/bin/activate" ]
    then
        echo "The specified virtualenv \"$VENV\" was not found!"
        exit 2
    fi

    echo "Activating virtualenv \"$VENV\""
    . $VENV/bin/activate
fi

echo "Starting cowrie..."
sudo -u cowrie twistd -n -l log/cowrie.log --pidfile cowrie.pid cowrie
