#noip.autorenew

Forked from felmoltor/noip.autorenew

Normally when you want to keep a hostname on [noip.com](http://www.noip.com) with a free account they will send you an email reminder every month and you will have to log in and renew it.

This script automatically retrieves the device's public IP address and will log in into your noip.com account to refresh your hostnames.

The script checks a file with the date and IP used during the previous update. If the previous IP is different than the current one, or if the last update was performed more than 15 days ago, the update will run.  This makes it easy to add a cron task to run this every day (or even more frequently if your IP address is particularly volatile) and it will only update if necessary.

###Needed gems
- [mechanize](https://github.com/sparklemotion/mechanize)
- [nokogiri](http://www.nokogiri.org)
