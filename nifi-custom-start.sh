#!/bin/bash
set -e

echo "Add more config to make LDAP user/group sync work"

sed -i -e '/To enable the ldap-user-group-provider remove 2 lines. This is . of 2./d' /opt/nifi/nifi-current/conf/authorizers.xml

sed -i -e 's|<property name="Authentication Strategy">START_TLS</property>|<property name="Authentication Strategy">SIMPLE</property>|' /opt/nifi/nifi-current/conf/authorizers.xml
sed -i -e 's|<property name="Manager DN"></property>|<property name="Manager DN">cn=admin,dc=planetexpress,dc=com</property>|' /opt/nifi/nifi-current/conf/authorizers.xml
sed -i -e 's|<property name="Manager Password"></property>|<property name="Manager Password">GoodNewsEveryone</property>|' /opt/nifi/nifi-current/conf/authorizers.xml
sed -i -e 's|<property name="Url"></property>|<property name="Url">ldap://openldap:10389</property>|' /opt/nifi/nifi-current/conf/authorizers.xml
sed -i -e 's|<property name="Sync Interval">30 mins</property>|<property name="Sync Interval">30 secs</property>|' /opt/nifi/nifi-current/conf/authorizers.xml
sed -i -e 's|<property name="User Search Base"></property>|<property name="User Search Base">ou=people,dc=planetexpress,dc=com</property>|' /opt/nifi/nifi-current/conf/authorizers.xml
sed -i -e 's|<property name="User Object Class">person</property>|<property name="User Object Class">inetOrgPerson</property>|' /opt/nifi/nifi-current/conf/authorizers.xml
sed -i -e 's|<property name="User Identity Attribute"></property>|<property name="User Identity Attribute">uid</property>|' /opt/nifi/nifi-current/conf/authorizers.xml

sed -i -e 's|<property name="Group Search Base"></property>|<property name="Group Search Base">ou=people,dc=planetexpress,dc=com</property>|' /opt/nifi/nifi-current/conf/authorizers.xml
sed -i -e 's|<property name="User Identity Attribute"></property>|<property name="Group Identity Attribute">uid</property>|' /opt/nifi/nifi-current/conf/authorizers.xml

sed -i -e 's|<property name="Group Name Attribute"></property>|<property name="Group Name Attribute">cn</property>|' /opt/nifi/nifi-current/conf/authorizers.xml
sed -i -e 's|<property name="Group Member Attribute"></property>|<property name="Group Member Attribute">member</property>|' /opt/nifi/nifi-current/conf/authorizers.xml

sed -i -e 's|<property name="User Group Provider">file-user-group-provider</property>|<property name="User Group Provider">ldap-user-group-provider</property>|' /opt/nifi/nifi-current/conf/authorizers.xml

# Original entrypoint
exec /opt/nifi/scripts/start.sh "$@"
