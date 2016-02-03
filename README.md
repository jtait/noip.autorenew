noip.autorenew
==============

Forked from felmoltor/noip.autorenew

Usually, when you want to keep alive a hostname of noip.com with a Free Account, they will send you an email every month
to keep this hostname in their servers. Thus, you will have to manually login in your noip.com account to avoid deletion of your hostnames.

This script will automatically retrieve the device public IP address and will login into your noip.com account to 
refresh your hostnames.

Needed gems
-----------

- [mechanize](https://github.com/sparklemotion/mechanize)
- [nokogiri](http://www.nokogiri.org)
