 #!/bin/bash
ROOT_DIR=/root/ipset

TMP_DIR=$ROOT_DIR/tmp
IPV6_TMP_DIR=$ROOT_DIR/ipv6_tmp
IPSET_DIR=$ROOT_DIR/ipsetresult
BACKUP_IPSET=/etc/backup_ipset

if [ ! -d "$ROOT_DIR" ]; then
  mkdir -p $ROOT_DIR $TMP_DIR $IPV6_TMP_DIR $IPSET_DIR;
fi

if [ ! -d "$BACKUP_IPSETR" ]; then
  mkdir -p $BACKUP_IPSET;
fi


ALL_ZONES=$ROOT_DIR/all-zones.tar.gz
if [ -f "$ALL_ZONES" ]; then
  rm -f $ALL_ZONES
fi

IPV6_ALL_ZONES=$ROOT_DIR/ipv6-all-zones.tar.gz
if [ -f "$IPV6_ALL_ZONES" ]; then
  rm -f $IPV6_ALL_ZONES
fi

if [ -f "$BACKUP_IPSET/ctryblist.xml" ]; then
  rm -f $BACKUP_IPSET/ctryblist.xml
fi

if [ -f "$BACKUP_IPSET/ctryblist6.xml" ]; then
  rm -f $BACKUP_IPSET/ctryblist6.xml
fi

wget -O $ALL_ZONES --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz
tar -xzf $ALL_ZONES -C $TMP_DIR

wget -O $IPV6_ALL_ZONES --no-check-certificate https://www.ipdeny.com/ipv6/ipaddresses/blocks/ipv6-all-zones.tar.gz
tar -xzf $IPV6_ALL_ZONES -C $IPV6_TMP_DIR


# countries to block
countries="al ar az bh bd by br bg cn co cu hk in ir kp ni ng pk ro ru ua vn "

cat  >>$IPSET_DIR/allowed-header.zone <<'EOF' 
<?xml version="1.0" encoding="utf-8"?> 
<ipset type="hash:net">
  <option name="family" value="inet"/>
  <option name="hashsize" value="4096"/>
  <option name="maxelem" value="500000"/>
EOF

cat  >>$IPSET_DIR/allowed-footer.zone <<'EOF'
</ipset>
EOF


echo -n > $IPSET_DIR/ipv6-allowed-cc.zone
echo -n > $IPSET_DIR/ipv6-allowed.zone
echo -n > $IPSET_DIR/ipv6-allowed-header.zone
echo -n > $IPSET_DIR/ipv6-allowed-footer.zone


cat  >>$IPSET_DIR/ipv6-allowed-header.zone <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ipset type="hash:net">
  <option name="family" value="inet6"/>
  <option name="hashsize" value="4096"/>
  <option name="maxelem" value="500000"/>
EOF

cat  >>$IPSET_DIR/ipv6-allowed-footer.zone <<'EOF'
</ipset>
EOF


for cn in $countries; do
  cat $TMP_DIR/$cn.zone >> $IPSET_DIR/allowed-cc.zone
  cat $IPV6_TMP_DIR/$cn.zone >> $IPSET_DIR/ipv6-allowed-cc.zone
done

cd $IPSET_DIR


sed 's/^/  <entry>/; s/$/<\/entry>/' allowed-cc.zone >> allowed.zone
sed 's/^/  <entry>/; s/$/<\/entry>/' ipv6-allowed-cc.zone >> ipv6-allowed.zone


cat allowed-header.zone allowed.zone allowed-footer.zone  >> $BACKUP_IPSET/ctryblist.xml
cat ipv6-allowed-header.zone ipv6-allowed.zone ipv6-allowed-footer.zone  >> $BACKUP_IPSET/ctryblist6.xml


cd /root
rm -r ipset


if [ -f "$BACKUP_IPSET/drop.xml" ]; then
  rm -f $BACKUP_IPSET/drop.xml
fi



cat  >> $BACKUP_IPSET/drop.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<zone target="DROP">
  <short>Drop</short>
  <description>Unsolicited incoming network packets are dropped.</description>
  <source ipset="ctryblist"/>
  <source ipset="ctryblist6"/>
  <forward/>
</zone>
EOF
