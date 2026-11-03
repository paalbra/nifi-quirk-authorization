# About

[Apache Nifi](https://nifi.apache.org/) is a system that lets you process and distribute data.

I am no expert when it comes to Nifi, but in my opinion it has a large amount of quirks and gotchas. Some are related to users, authentication and authorization.

This repo tries to illustrate one quirk related to authorization.

# The quirk

Nifi can be [configured to use an identity provider like LDAP](https://nifi.apache.org/nifi-docs/administration-guide.html#ldap_login_identity_provider) and to [get users and groups](https://nifi.apache.org/nifi-docs/administration-guide.html#ldapusergroupprovider).

The access/policies/authorizations are often configured through the UI, but they reside in a "Authorizations File", authorizations.xml.

One weird part about authorizations.xml is that it isn't some kind of database that gives users access directly. Users are referred to by an "identifier" property. When using LDAP this "identifier" is really a hash of the user identity provided by LDAP (witch commonly would say uid or dn). The hashes are based on UUIDv3/MD5 algorithm.

Adding this extra layer of hashing in the authorization part creates the possiblility for multiple users to get the same policy/autorization (hash collision).

This repo constructs an environment where this happens. Two usernames alternate between having the same autorization, by making this hash collision problem apparent. The consequences are weird/unexpected and I do not have the complete picture myself...

# Run containers

```
docker-compose up
```

More details about the four containers below.

## certs-init

Helper container that initializes some certificates for the LDAP and Nifi servers. Could probably be removed for this example to work, but it adds some extra possibilities in Nifi.

## openldap

[A testing container for OpenLDAP](https://hub.docker.com/r/rroemhild/test-openldap). Used for convenience/to have some basic structure populated in a LDAP.

## nifi

A variant of [the official Apache Nifi container](https://hub.docker.com/r/apache/nifi). The official image has no convenient way to configure user/group syncronization from LDAP.
  
## helper

A helper container that makes sure the two hash collisions/users alternate between each other.

# Observe

Three main users are to be used in this example, `TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak`, `TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak` and `fry`. Their passwords are the same as their usernames.

The "helper" container will output each time the hash collision makes the two special users swap. Something like the following:
```
==================================================
Current users in Nifi: "TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak","fry","amy","hermes","bender","leela","professor","zoidberg"
Current TEXT users in LDAP: TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
!!! Swapping from TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
adding new entry "cn=TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak,ou=people,dc=planetexpress,dc=com"

Current TEXT user: TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
==================================================
Current users in Nifi: "TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak","fry","amy","hermes","bender","leela","professor","zoidberg"
Current TEXT users in LDAP: TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
Current TEXT user: TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
==================================================
Current users in Nifi: "TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak","fry","amy","hermes","bender","leela","professor","zoidberg"
Current TEXT users in LDAP: TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
!!! Current TEXT user changed
!!! from: TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
!!! to  : TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
```

The "openldap" test container has a user, "fry", that is configured to be the initial admin in Nifi. This user could be used to observe the UI as the colliding users swap.

Trying to authorize with the two special users lead to weird behavior (depending on which is "the most active", I guess). The API and UI behaves different.

# MD5 collision

The example collision itself is not found by me, but a part of [Project HashClash](https://github.com/cr-marcstevens/hashclash).

```
TEXT1: TEXTCOLLBYfGiJUETHQ4hAcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
TEXT2: TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak
DIFF:                       ^
MD5 FOR BOTH: faad49866e9498fc1719f5289e7a0269
HASH IN NIFI: faad49866e9438fc9719f5289e7a0269
DIFF:                     ^   ^
```

Nifi doesn't create a "pure MD5" sum, but creates an UUID3 with some sort of empty namespace. I have not looked into how Nifi does this, but it could be recreated with Python like so:
```
python -c 'import uuid; print(str(uuid.uuid3(type("", (), dict(bytes=b""))(), "TEXTCOLLBYfGiJUETHQ4hEcKSMd5zYpgqf1YRDhkmxHkhPWptrkoyz28wnI9V0aHeAuaKnak")))' # faad4986-6e94-38fc-9719-f5289e7a0269
```

# Last words

In my opinion Nifi has many quirks that makes it really hard to "do right". This example might be the worst one I know of, since it makes authorization non-deterministic.

I am no expert in Nifi, LDAP or the MD5 algorithm. To my knowledge:
* The LDAP RFC does not require any order of search results. For some LDAP implementation the behavior triggered by the "helper" container could be "builtin". The behavior seen here is that OpenLDAP apparently orders search results after the time the object was added(?).
* I am unaware of any pratical way to use this collision. It must be fairly easy to create a _username_ (very restrictive input/alphabeth) that has a MD5 hash collision with "insert-your-powerful-admin-username-here".

The potential attack vector is dependent on setup, but a fairly obvious way would be:
1. You're in control of a login provider that Nifi uses ([it's possible to setup multiple authorization sources in Nifi](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#multi-tenant-authorization)).
2. You're aware of some sensitive/high privelege username/policy in the specific Nifi.
3. You could within reasonable time find a MD5 collision and create such user in a configured login provider.

This quirk should be fairly obvious if you have experience with Nifi, but I am not aware of/haven't seen any mentions of this elsewere...?

# Timeline

* 2026-11-03 - Created public Github repo, since this is by design and has questionable impact/severity.
* 2026-11-03 - Sent an inquiry to [Apache Nifi Security](https://nifi.apache.org/documentation/security/) regarding the mater.
