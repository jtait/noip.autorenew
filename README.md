noip.autorenew
==============

Forked from felmoltor/noip.autorenew

Usually, when you want to keep alive a hostname of noip.com with a Free Account, they will send you an email reminder every month
to keep this hostname in their servers. Thus, you will have to manually login in your noip.com account to avoid deletion of your hostnames.

This script will automatically retrieve the device public IP address and will login into your noip.com account to refresh your hostnames.

The the script checks for a file with the date and IP used during the previous update. If the previous IP is different than the current one, or if the last update was performed more than 15 days ago, the update will run.  Otherwise the script will exit. This makes it easy to add a cron task to run this every day (or even more frequently if your IP address is particularly volatile) and it will only update if necessary.

Needed gems
-----------

- [mechanize](https://github.com/sparklemotion/mechanize)
- [nokogiri](http://www.nokogiri.org)
