== Small, dumb CA generator and certificate signer ==

This is a makefile that generates a tree (a forest) of certificate
authorities. It can also sign leaf certificates.

All this CA uses is `make' (obviously), OpenSSL command line tool, and several
typical unix commands, like `mkdir' and `touch'. I used GNU make; I can't
guarantee that other `make' implementations will work.

Note that all generated keys are only 1024 bits long, which is way too small
for normal CA operation. The length was chosen purely for key generation
speed, as this generator was intended for being a help in checking behaviour
of software that relies on X.509 infrastructure.

Generated CA certificates are valid for 1095 = 3 * 365 days.


=== Usage ===

To generate default CA structure just run `make ca'. It will generate all the
RSA keys, CA certificates, and text files required by `openssl ca' to operate.

To produce a certificate, first generate a private key, e.g. with this
command:

  $ (umask 077; openssl genrsa -out server.key.pem 1024)

Now generate a certificate signing request:

  $ openssl req -new \
      -key server.key.pem \
      -out server.req.pem \
      -subj '/CN=your-server.example.net'

And this is the file you can sign:

  $ make sign CA=emerald REQ=server.req.pem

The certificate is written to server.cert.pem and will be valid for 365 days.
This is how you can check certificate details:

  $ openssl x509 -noout -in server.cert.pem -text


==== Default CA structure ====

Some CAs in this structure are top-level, some others are sub-CAs.

The structure who signs what and which namespaces are intended for whom are as
follows:


  gemstones (gemstones.net)
      |
      +-- agate (agate.gemstones.net)
      |
      +-- beryl (beryl.gemstones.net)
            |
            +-- emerald (emerald.beryl.gemstones.net)

  minerals (minerals.org)
      |
      +-- obsidian (obsidian.minerals.org)
      |
      +-- pyrite (pyrite.minerals.org)


Namespaces above are merely a suggestion. They may be useful default, but they
are by no means definitive or enforced in any way.

==== OpenSSL configuration ====

Configuration file for OpenSSL (openssl.cnf) was trimmed heavily, with almost
all of the options being strictly required. Every parameter was moved out to
command line, if it was possible. Because of this, `openssl' invocations used
in makefile may be a little scary, but there's no magic. Analyzing them is
a quite good way to learn how CA really operates.


=== License ===

This software is distributed under GPLv3 license. See LICENSE file for
details.
