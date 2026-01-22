#!/bin/bash
ROOT_DIR=/root/ipset

TMP_DIR=$ROOT_DIR/tmp
IPV6_TMP_DIR=$ROOT_DIR/ipv6_tmp
IPSET_DIR=$ROOT_DIR/ipsetresult
BACKUP_IPSET=/etc/backup_ipset
FWALLD=/etc/firewalld

if [ ! -d "$FWALLD/ipsets" ]; then
  mkdir -p "$FWALLD/ipsets";
fi

systemctl stop firewalld

DROP_ZONES=$FWALLD/zones/drop.xml
if [ -f "$DROP_ZONES" ]; then
  rm -f $DROP_ZONES
fi

echo "Remove drop.xml"


cp $BACKUP_IPSET/drop.xml $FWALLD/zones/

if [ -f "$FWALLD/ipsets/ctryblist.xml" ]; then
  rm -f $FWALLD/ipsets/ctryblist.xml
fi

if [ -f "$FWALLD/ipsets/ctryblist6.xml" ]; then
  rm -f $FWALLD/ipsets/ctryblist6.xml
fi

cp $BACKUP_IPSET/ctry*.xml $FWALLD/ipsets/

    systemctl start firewalld
    echo ""
    echo "Waiting 60 sec ....."
    echo ""
    sleep 60
    