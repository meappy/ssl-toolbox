#!/bin/bash

# 2018-03-01
# v1
# Gerald S.

CN="${1}"

# Let's try to build the  [ dn ] info
openssl s_client -servername "${CN}" -connect "${CN}":443  2>&1 < /dev/null | \
    openssl x509 -noout -text | grep Subject: | perl -pe 's/^.*(C=.*)/$1/g' | \
    perl -pe 's/^ +Subject: //g' | \
    perl -pe 's/(.=|..=)/\n$1/g' | perl -pe 's/^ //g' | \
    perl -pe 's/, ?$//g' | \
    perl -pe 's/^\n//g' > /tmp/$$_1
    
# [ alt_names ] info
openssl s_client -servername "${CN}" -connect "${CN}":443  2>&1 < /dev/null | \
    openssl x509 -noout -text | grep DNS: | \
    perl -pe 's/^ +DNS://g' | perl -pe 's/, DNS:/\n/g' > /tmp/$$_2

DN="$(cat /tmp/$$_1)"
FN="$(echo ${CN} | perl -pe 's/\./_/g')"
ARRAY=($(cat /tmp/$$_2))

#ALT_NAMES= "$(for ((i = 0; i < ${#ARRAY[@]}; ++i)); do NUM=$(( $i + 1 )); echo DNS.$NUM = ${ARRAY[$i]}; done)"

echo
echo
echo "*********************************************************************************"
echo "**** IMPORTANT NOTE: This is experimental, and quickly queries a domain      ****"
echo "****                 for .csr generation                                     ****"
echo "*********************************************************************************"
echo
echo "*********************************************************************************"
echo "**** Now verify, then copy and paste the following to generate .csr and .key ****"
echo "*********************************************************************************"
echo

echo -n "
openssl req -new -sha256 -nodes -out ${FN}.csr -newkey rsa:2048 -keyout ${FN}.key -config <(
cat <<-EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
${DN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
"
for ((i = 0; i < ${#ARRAY[@]}; ++i)); 
    do NUM=$(( $i + 1 ))
    echo "DNS.$NUM = ${ARRAY[$i]}"
done
echo "
EOF
)"
