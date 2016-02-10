#!/usr/bin/make -f

#-----------------------------------------------------------------------------

CERTIFICATE_AUTHORITIES = \
	gemstones agate beryl emerald \
	minerals obsidian pyrite

CA_KEYS  = $(foreach CA,$(CERTIFICATE_AUTHORITIES),$(CA)/ca.key.pem)
CA_REQS  = $(foreach CA,$(CERTIFICATE_AUTHORITIES),$(CA)/ca.req.pem)
CA_CERTS = $(foreach CA,$(CERTIFICATE_AUTHORITIES),$(CA)/ca.cert.pem)

CNF = openssl.cnf
CA_KEY_LENGTH = 1024
CA_EXTS = ext_ca
CA_DAYS = 1095
LEAF_EXTS = ext_leaf
LEAF_DAYS = 365

EXTENSIONS = $(LEAF_EXTS)

.SECONDARY: $(CA_KEYS) $(CA_REQS) $(CA_CERTS)

.PHONY: default
default: help

#-----------------------------------------------------------------------------
# CA dependencies and variables {{{

.PHONY: $(CERTIFICATE_AUTHORITIES)
$(CERTIFICATE_AUTHORITIES): %: %/
$(CERTIFICATE_AUTHORITIES): %: %/ca.cert.pem
$(CERTIFICATE_AUTHORITIES): %: %/index.txt %/serial.txt %/signed.d

# NOTE: these two don't use certificate requests, so $(SUBJECT) needs to be
# set for certificate
gemstones/ca.cert.pem: SUBJECT = /O=Gemstones CA/emailAddress=ca@gemstones.net
minerals/ca.cert.pem: SUBJECT = /O=Minerals CA/emailAddress=ca@minerals.org

agate/ca.req.pem: SUBJECT = /O=Agate CA/emailAddress=ca@agate.gemstones.net
agate/ca.cert.pem: PARENT_CA = gemstones
agate/ca.cert.pem: | gemstones

beryl/ca.req.pem: SUBJECT = /O=Beryl CA/emailAddress=ca@beryl.gemstones.net
beryl/ca.cert.pem: PARENT_CA = gemstones
beryl/ca.cert.pem: | gemstones

emerald/ca.req.pem: SUBJECT = /O=Emerald CA/emailAddress=ca@emerald.beryl.gemstones.net
emerald/ca.cert.pem: PARENT_CA = beryl
emerald/ca.cert.pem: | beryl

obsidian/ca.req.pem: SUBJECT = /O=Obsidian CA/emailAddress=ca@obsidian.minerals.org
obsidian/ca.cert.pem: PARENT_CA = minerals
obsidian/ca.cert.pem: | minerals

pyrite/ca.req.pem: SUBJECT = /O=Pyrite CA/emailAddress=ca@pyrite.minerals.org
pyrite/ca.cert.pem: PARENT_CA = minerals
pyrite/ca.cert.pem: | minerals

# }}}
#-----------------------------------------------------------------------------

.PHONY: help
.SILENT: help
help:
	echo "Available targets:"
	echo "  ca"
	echo "  ca-clean"
	echo "  sign CA=ca_name REQ=file.req.pem [CERT=file.cert.pem] [EXTENSIONS=section]"
	echo "  sign-opts [vars as with \`sign'] OPTS='...'"
	echo "Known CAs:"
	printf '  %s\n' $(CERTIFICATE_AUTHORITIES)

.PHONY: ca
ca: $(CERTIFICATE_AUTHORITIES)

.PHONY: ca-clean
ca-clean:
	rm -rf $(foreach CA,$(CERTIFICATE_AUTHORITIES),$(CA)/*)

#-----------------------------------------------------------------------------

.PHONY: sign sign-opts

sign: OPTS = -days $(LEAF_DAYS)
sign: sign-opts

sign-opts: $(CA)
sign-opts:
	CA_HOME=$(if $(CA),$(CA),$(error No CA=... specified)) openssl ca -batch -config $(CNF) -extensions $(EXTENSIONS) -in $(if $(REQ),$(REQ),$(error No REQ=... specified)) -out $(if $(CERT),$(CERT),$(REQ:.req.pem=.cert.pem)) -outdir $(CA)/signed.d -cert $(CA)/ca.cert.pem -keyfile $(CA)/ca.key.pem $(OPTS)

#-----------------------------------------------------------------------------
# building CA {{{

#-----------------------------------------------------------
# common files and directories {{{

%/:
	mkdir $@

%/index.txt:
	touch $@

%/serial.txt:
	echo 01 > $@

%/signed.d:
	mkdir $@

%/ca.key.pem:
	umask 077; openssl genrsa -out $@ $(CA_KEY_LENGTH)

# }}}
#-----------------------------------------------------------
# sub-CAs: certificate requests and certificates {{{

%.req.pem: %.key.pem
	CA_HOME=$(dir $@) openssl req -batch -config $(CNF) -extensions $(CA_EXTS) -new -days $(CA_DAYS) -key $< -subj '$(SUBJECT)' -out $@

%.cert.pem: %.req.pem
	${MAKE} sign-opts CA=$(PARENT_CA) REQ=$< CERT=$@ EXTENSIONS=$(CA_EXTS) OPTS='-days $(CA_DAYS)'

# }}}
#-----------------------------------------------------------
# top-level CAs: certificates {{{

gemstones/ca.req.pem minerals/ca.req.pem:
	echo "This is a root CA, it didn't use a sign request." > $@

gemstones/ca.cert.pem minerals/ca.cert.pem: %.cert.pem: %.key.pem
	CA_HOME=$(dir $@) openssl req -batch -config $(CNF) -extensions $(CA_EXTS) -new -days $(CA_DAYS) -key $< -subj '$(SUBJECT)' -out $@ -x509

# }}}
#-----------------------------------------------------------

# }}}
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# vim:ft=make:foldmethod=marker
