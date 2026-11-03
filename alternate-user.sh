#!/bin/sh

function nifi_curl {
    curl -s --cacert /certs/nifi/server.crt -H "Authorization: Bearer $1" -H 'Content-Type: application/json' "$@"
}

function get_current_user {
    nifi_curl $1 'https://nifi:8443/nifi-api/flow/current-user' | jq .identity
}

function get_users {
    nifi_curl $1 'https://nifi:8443/nifi-api/tenants/users' | jq -r '.users | map(.component.identity) | @csv'
}

function get_text_users {
    nifi_curl $1 'https://nifi:8443/nifi-api/tenants/users' | jq -r '.users[].component.identity | select(test("TEXT"))'
}

function get_token {
    curl -s --cacert /certs/nifi/server.crt --fail --data "username=$1&password=$1" 'https://nifi:8443/nifi-api/access/token'
}

TEXT_A=TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
TEXT_E=TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak

apk update && apk add curl jq openldap openldap-clients

cat << EOF > /$TEXT_A.ldif
dn: cn=$TEXT_A,ou=people,dc=planetexpress,dc=com
cn: $TEXT_A
sn: Example
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
uid: $TEXT_A
userPassword: $(slappasswd -h '{SSHA}' -s $TEXT_A)
EOF

cat << EOF > /$TEXT_E.ldif
dn: cn=$TEXT_E,ou=people,dc=planetexpress,dc=com
cn: $TEXT_E
sn: Example
objectClass: inetOrgPerson
uid: $TEXT_E
userPassword: $(slappasswd -h '{SSHA}' -s $TEXT_E)
EOF

ldapadd -D "cn=admin,dc=planetexpress,dc=com" -w GoodNewsEveryone -H ldap://openldap:10389 -f /$TEXT_A.ldif
ldapadd -D "cn=admin,dc=planetexpress,dc=com" -w GoodNewsEveryone -H ldap://openldap:10389 -f /$TEXT_E.ldif

until get_token fry &>/dev/null; do
  echo "Helper waiting for Nifi API ..."
  sleep 10
done

API_TOKEN=$(get_token fry)
TEXT_USER=$(get_text_users $API_TOKEN)

SWAP_IN_PROGRESS=no

while true; do
  echo -e "Helper loop starting $(date -Iseconds)\n=================================================="
  echo -n "Current users in Nifi: "
  get_users $API_TOKEN
  echo -n "Current TEXT users in LDAP: "
  echo $(ldapsearch -D "cn=admin,dc=planetexpress,dc=com" -w GoodNewsEveryone -H ldap://openldap:10389 -LLL -b "dc=planetexpress,dc=com" uid=TEXT* uid | grep "^uid: " | cut -c6- | tr '\n' ' ')

  CURRENT_TEXT_USER=$(get_text_users $API_TOKEN)

  if [ ! -z "$CURRENT_TEXT_USER" ] && [ "$SWAP_IN_PROGRESS" = "no" ]; then
    # Try to swap the users in LDAP by re-adding the current user. Nifi will only see the other user, that was added first.
    # Nifi will see this when is does it next sync according to "Sync Interval" in authorizers.xml
    echo "!!! Swapping from $CURRENT_TEXT_USER"
    ldapdelete -D "cn=admin,dc=planetexpress,dc=com" -w GoodNewsEveryone -H ldap://openldap:10389 "cn=$CURRENT_TEXT_USER,ou=people,dc=planetexpress,dc=com"
    ldapadd -D "cn=admin,dc=planetexpress,dc=com" -w GoodNewsEveryone -H ldap://openldap:10389 -f /$CURRENT_TEXT_USER.ldif

    SWAP_IN_PROGRESS=yes
  fi

  if [ "$TEXT_USER" != "$CURRENT_TEXT_USER" ]; then
    echo -e "!!! Current TEXT user changed\n!!! from: $TEXT_USER\n!!! to  : $CURRENT_TEXT_USER"
    TEXT_USER="$CURRENT_TEXT_USER"

    SWAP_IN_PROGRESS=no
  else
    echo "Current TEXT user: $CURRENT_TEXT_USER"
  fi

  sleep 5
done
