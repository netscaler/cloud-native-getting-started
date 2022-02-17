#! /usr/bin/bash

SETUP=$2
VIP=$1
CERT=$3
KEY=$4

if [[ $1 == "" ||  $2 == "" ]]; then
        echo "USAGE: bash generate_ingress_conf.sh VIP SETUP-NAME [cert.pem] [key.pem]"
        exit 1
fi	

if [[ $3 != "" &&  $4 == "" ]]; then
        echo "USAGE: bash generate_ingress_conf.sh VIP SETUP-NAME [cert.pem] [key.pem]"
        exit 1
fi

SLAVES=`kubectl get nodes -o wide | grep -v "master\|INTERNAL-IP" | awk -F" " '{print $6}'`
if [[ $SLAVES == "" ]]; then
        echo "Command needs to be run on kubernetes master node"
        exit 1
fi

echo "en ns feature lb ssl" > $SETUP-batch.txt
echo "en ns mode usip" >> $SETUP-batch.txt
echo "" >> $SETUP-batch.txt
echo "add ns httpProfile adm_websocket_profile -webSocket ENABLED"  >> $SETUP-batch.txt

count=1
for slave in $SLAVES; do
	echo "add server $SETUP-adm_server-$count $slave" >> $SETUP-batch.txt
	(( count++ ))
done
(( count-- ))

echo "" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_server http -usip no -useproxyport no" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_syslog udp -usip yes" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_snmp udp -usip yes" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_appflow udp -usip yes" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_logstream_a tcp -usip no -useproxyport no" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_logstream_b tcp -usip no -useproxyport no" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_license tcp -usip no -useproxyport no" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_license_aux tcp -usip no -useproxyport no" >> $SETUP-batch.txt
#echo "add servicegroup sg-$SETUP-adm_aaad tcp -usip no -useproxyport no" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_cmp http -maxClient 0 -maxReq 1 -cip DISABLED -usip NO -useproxyport YES -sp OFF -cltTimeout 31536000 -svrTimeout 31536000 -CKA NO -TCPB NO -CMP NO" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_adp http -maxClient 0 -maxReq 1 -cip DISABLED -usip NO -useproxyport YES -sp OFF -cltTimeout 31536000 -svrTimeout 31536000 -CKA NO -TCPB NO -CMP NO" >> $SETUP-batch.txt
echo "add servicegroup sg-$SETUP-adm_restcollector tcp -usip no -useproxyport no" >> $SETUP-batch.txt
echo "" >> $SETUP-batch.txt
echo "add lb vserver lb-$SETUP-adm_server HTTP $VIP 80" >> $SETUP-batch.txt
echo "add lb vserver ssl-$SETUP-adm_server SSL $VIP 443" >> $SETUP-batch.txt
echo "add lb vserver lb-$SETUP-adm_syslog UDP $VIP 514" >> $SETUP-batch.txt
echo "add lb vserver lb-$SETUP-adm_snmp UDP $VIP 162" >> $SETUP-batch.txt
echo "add lb vserver lb-$SETUP-adm_appflow UDP $VIP 4739" >> $SETUP-batch.txt
echo "add lb vserver lb-$SETUP-adm_logstream_a TCP $VIP 5557" >> $SETUP-batch.txt
echo "add lb vserver lb-$SETUP-adm_logstream_b TCP $VIP 5558" >> $SETUP-batch.txt
echo "add lb vserver lb-$SETUP-adm_license TCP $VIP 27000" >> $SETUP-batch.txt
echo "add lb vserver lb-$SETUP-adm_license_aux TCP $VIP 7279" >> $SETUP-batch.txt
#echo "add lb vserver lb-$SETUP-adm_aaad TCP $VIP 8888" >> $SETUP-batch.txt
echo "add lb vserver ssl-$SETUP-adm_cmp SSL $VIP 7443 -cltTimeout 31536000 -httpProfileName adm_websocket_profile" >> $SETUP-batch.txt
echo "add lb vserver ssl-$SETUP-adm_adp SSL $VIP 8443 -cltTimeout 31536000 -httpProfileName adm_websocket_profile" >> $SETUP-batch.txt
echo "add lb vserver lb-$SETUP-adm_restcollector TCP $VIP 5563" >> $SETUP-batch.txt
echo "" >> $SETUP-batch.txt
#echo "=============================================" >> $SETUP-batch.txt
echo "" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_server $SETUP-adm_server-[1-$count] 30008" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_syslog $SETUP-adm_server-[1-$count] 31002" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_snmp $SETUP-adm_server-[1-$count] 31001" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_appflow $SETUP-adm_server-[1-$count] 31003" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_logstream_a $SETUP-adm_server-[1-$count] 31557" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_logstream_b $SETUP-adm_server-[1-$count] 31558" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_license $SETUP-adm_server-[1-$count] 30554" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_license_aux $SETUP-adm_server-[1-$count] 32474" >> $SETUP-batch.txt
#echo "bind servicegroup sg-$SETUP-adm_aaad $SETUP-adm_server-[1-$count] 30555" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_cmp $SETUP-adm_server-[1-$count] 30007" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_adp $SETUP-adm_server-[1-$count] 32007" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_restcollector $SETUP-adm_server-[1-$count] 31563" >> $SETUP-batch.txt
echo "" >> $SETUP-batch.txt
#echo "=============================================" >> $SETUP-batch.txt
echo "" >> $SETUP-batch.txt
echo "bind lb vserver lb-$SETUP-adm_server sg-$SETUP-adm_server" >> $SETUP-batch.txt
echo "bind lb vserver ssl-$SETUP-adm_server sg-$SETUP-adm_server" >> $SETUP-batch.txt
echo "bind lb vserver lb-$SETUP-adm_syslog sg-$SETUP-adm_syslog" >> $SETUP-batch.txt
echo "bind lb vserver lb-$SETUP-adm_snmp sg-$SETUP-adm_snmp" >> $SETUP-batch.txt
echo "bind lb vserver lb-$SETUP-adm_appflow sg-$SETUP-adm_appflow" >> $SETUP-batch.txt
echo "bind lb vserver lb-$SETUP-adm_logstream_a sg-$SETUP-adm_logstream_a" >> $SETUP-batch.txt
echo "bind lb vserver lb-$SETUP-adm_logstream_b sg-$SETUP-adm_logstream_b" >> $SETUP-batch.txt
echo "bind lb vserver lb-$SETUP-adm_license sg-$SETUP-adm_license" >> $SETUP-batch.txt
echo "bind lb vserver lb-$SETUP-adm_license_aux sg-$SETUP-adm_license_aux" >> $SETUP-batch.txt
#echo "bind lb vserver lb-$SETUP-adm_aaad sg-$SETUP-adm_aaad" >> $SETUP-batch.txt
echo "bind lb vserver ssl-$SETUP-adm_cmp sg-$SETUP-adm_cmp" >> $SETUP-batch.txt
echo "bind lb vserver ssl-$SETUP-adm_adp sg-$SETUP-adm_adp" >> $SETUP-batch.txt
echo "bind lb vserver lb-$SETUP-adm_restcollector sg-$SETUP-adm_restcollector" >> $SETUP-batch.txt
echo "" >> $SETUP-batch.txt
echo "add monitor custom-udp tcp -destPort 31557" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_snmp -monitorName custom-udp" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_syslog -monitorName custom-udp" >> $SETUP-batch.txt
echo "bind servicegroup sg-$SETUP-adm_appflow -monitorName custom-udp" >> $SETUP-batch.txt
echo "" >> $SETUP-batch.txt
echo "add ssl certKey citrixadm -cert $CERT -key $KEY" >> $SETUP-batch.txt
#echo "add ssl certKey DigiCertCA -cert DigiCertCA.crt" >> $SETUP-batch.txt
#echo "link ssl certKey citrixadm DigiCertCA" >> $SETUP-batch.txt
echo "bind ssl vserver ssl-$SETUP-adm_server -certkeyName citrixadm" >> $SETUP-batch.txt
echo "bind ssl vserver ssl-$SETUP-adm_cmp -certkeyName citrixadm" >> $SETUP-batch.txt
echo "bind ssl vserver ssl-$SETUP-adm_adp -certkeyName citrixadm" >> $SETUP-batch.txt

echo "\"$SETUP-batch.txt\" config file has been generated."
echo ""
echo "Follow these steps:"
echo "================== "
echo "1. Manually copy $SETUP-batch.txt to the ingress device under /nsconfig/"
echo "2. Optionally, if Cert and Key files have been generated and provided as inputs, manually copy them to the ingress device uner /nsconfig/ssl/"
echo "3. Run the batch command to apply the config: \"batch -f /nsconfig/$SETUP-batch.txt\""
echo ""
exit 0
