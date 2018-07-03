# noip.autorenew

Forked from felmoltor/noip.autorenew

Normally when you want to keep a hostname on [noip.com](http://www.noip.com) with a free account they will send you an email reminder every month and you will have to log in and renew it.

This script automatically retrieves the device's public IP address and will log in into your noip.com account to refresh your hostnames.

The script checks a file with the date and IP used during the previous update. If the previous IP is different than the current one, or if the last update was performed more than 15 days ago, the update will run.  This makes it easy to add a cron task to run this every day (or even more frequently if your IP address is particularly volatile) and it will only update if necessary.

### Needed gems
- [mechanize](https://github.com/sparklemotion/mechanize)
- [nokogiri](http://www.nokogiri.org)
- [mail](https://github.com/mikel/mail/)

Follow the instructions at [nokogiri](http://www.nokogiri.org/tutorials/installing_nokogiri.html) to install the gems if you have trouble.

### Usage (with examples)
Note: all of these examples are tested on Debian, and may need to be modified slightly depending on you OS / distribution.
This is also tested on Rasbian, making a Raspberry Pi a low-power DNS renewal solution.

The script can be manually called using the following command (substitute your noip.com username and password where indicated):

    ruby noip.autorenew.rb <noip-username> <noip-password>

In order to log to a file you might do something like this:

    ruby noip.autorenew.rb <noip-username> <noip-password>  >> log.txt

Putting this all together in a crontab task (on Linux), first open crontab for your user:

    crontab -e
    
and then add this line to the bottom of the file:

    0 0 * * * ruby <path-to-script>/noip.autorenew.rb <noip-username> <noip-password>  >> <path-to-script>/log.txt

and save and exit.  This will run the script every night at midnight.  Of course you need to substitute the <path-to-script> with the path to where you stored the script.  The log will be stored in the same location, and can be useful to ensure the script is running.

For more information on crontab, use the command '''man 5 crontab''' from the Linux terminal.

To add an email notification if the update fails, add 3 arguments to the command:

    ruby noip.autorenew.rb <noip-username> <noip-password> <gmail username> <gmail password> <receiver email address>
