#!/usr/bin/env ruby

# Summary: This script avoids the need to manually login to http://www.noip.com
# every month and update your domains to keep them active. It will automatically
# retrieve the machine's current public IP from http://checkip.dyndns.org/
# Original Author: Felipe Molina (@felmoltor)
# Date: July 2013
# License: GPLv3
# Changes by Jason Tait
#   - translation/language - January 2016
#   - added a check that will make update only run if last update was done at
#     least 15 days ago - February 2, 2016
#   - added a check of the previous IP address used, will update if different,
#     ignoring 15 day rule - February 19, 2016
#   - fixed error in IP comparison - script will now update if IP address has
#     changed.  Also improved information given on the reason the update request
#     is made - May 11, 2016
#   - added email notification if an error occurs - July 2, 2018
#   - added force option, a lot of cleanup - October 11, 2018
#   - removed gmail option, it doesn't play well with gmail security - October 20, 2018

require 'date'
require 'mechanize'
require 'optparse'

def my_current_ip?
  m = Mechanize.new
  m.user_agent_alias = 'Windows IE 8'

  ip_page = m.get('http://checkip.dyndns.org/')
  ip_page.root.xpath('//body').text.gsub(/^.*: /, '')
end

def set_my_current_noip(user, password, my_public_ip)

  updated_hosts = []

  m = Mechanize.new
  m.user_agent_alias = 'Windows IE 8'

  loginpage = m.get("https://www.noip.com/login/")

  loginpage.form_with(:id => 'clogs') do |form|
    form.username = user
    form.password = password
  end.submit

  # Once successfully logged in, access the DNS manage page
  dns_page = m.get("https://www.noip.com/members/dns/")
  dns_page.links_with(:text => "Modify").each do |link|
    # Update all the domains with my current IP
    update_host_page = m.click(link)
    hostname = update_host_page.forms[0].field_with(:name => 'host[host]').value
    domain = update_host_page.forms[0].field_with(:name => 'host[domain]').value
    updated_hosts << "#{hostname}.#{domain}"
    update_host_page.forms[0].field_with(:name => 'host[ip]').value = my_public_ip
    update_host_page.forms[0].submit
  end

  updated_hosts
end

def should_update?(check_file, public_ip)
  update = 0

  if !File.exist?(check_file)
    # file did not exist, so update
    f = File.new(check_file, "w+")
    update = 1

  else
    f = File.open(check_file, "r+")
    file_contents = f.readlines
    date = Date.parse(file_contents[0])

    # check if update is necessary
    if (Date.today - 15) > date
      update = 2
    elsif (public_ip.to_s + "\n") != (file_contents[1].to_s)
      update = 3
    end

  end

  f.close
  update

end

def record_update_date(filename, public_ip)
  f = File.open(filename, 'w')
  f.write(Date.today.to_s + "\n")
  f.write(public_ip.to_s + "\n")
  f.close
end

OptionParser.new do |o|
  o.on('-f') { |b| $force = b }
  o.parse!
end

puts "========= #{Date.today} =========="

update_filename = File.expand_path(__dir__) + '/noip.autorenew.dat'

if ARGV[0].nil? or ARGV[1].nil?
  puts 'Error. Please specify the user and password to access your noip.com account'
  exit(1)
else
  user = ARGV[0]
  password = ARGV[1]

  puts 'Getting my current public IP...'
  my_public_ip = my_current_ip?
  puts "Done: #{my_public_ip}"

  if $force
    update = 4
  else
    update = should_update?(update_filename, my_public_ip)
  end

  if update.zero?
    puts 'Update was performed within the last 15 days and IP has not changed, exiting'
  elsif update > 0
    case update
    when 1
      puts 'dat file doesn\'t exist'
    when 2
      puts 'Update performed more than 15 days ago'
    when 3
      puts 'IP has changed since last update'
    when 4
      puts 'forcing update'
    end

    puts 'Sending request to noip.com...'
    updated_hosts = set_my_current_noip(user, password, my_public_ip)
    if !updated_hosts.nil? && !updated_hosts.empty?
      puts "Done. Keeping alive #{updated_hosts.size} host with IP '#{my_public_ip}':"
      updated_hosts.each do |host|
        puts "- #{host}"
      end
      record_update_date(update_filename, my_public_ip)
    else
      error_message = 'There was an error while updating or there were no hosts to update'
      puts error_message
    end

  end

end
