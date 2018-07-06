#!/usr/bin/env ruby

# Summary:	This script avoids the need to manually login to http://www.noip.com every month and update your domains to keep them active.
#		It will automaticaly retrieve the machine's current public IP from http://checkip.dyndns.org/
# Original Author: Felipe Molina (@felmoltor)
# Date: July 2013
# License: GPLv3
# Changes by Jason Tait
#   - translation/language - January 2016
#   - added a check that will make update only run if last update was done at least 15 days ago - February 2, 2016
#   - added a check of the previous IP address used, will update if different, ignoring 15 day rule - February 19, 2016
#   - fixed error in IP comparison - script will now update if IP address has changed.  Also improved information given on the reason the update request is made - May 11, 2016
#   - added email notification if an error occurs - July 2, 2018

require 'date'
require 'mechanize'
require 'mail'

def sendGmail(username, password, email_to, message)
	options = {
		:address              => "smtp.gmail.com",
		:port                 => 587,
		:domain               => 'localhost',
		:user_name            => username,
		:password             => password,
		:authentication       => 'plain',
		:enable_starttls_auto => true
	}
	Mail.defaults do
		delivery_method :smtp, options
	end
	Mail.deliver do
		to email_to
		from username + '@gmail.com'
		subject 'noip.autorenew notification'
		body message
	end
end

def getMyCurrentIP()
	m = Mechanize.new
	m.user_agent_alias = 'Windows IE 8'

	ip_page = m.get("http://checkip.dyndns.org/")
	ip = ip_page.root.xpath("//body").text.gsub(/^.*: /,"")
	return ip
end

def setMyCurrentNoIP(user,password,my_public_ip)

	updated_hosts = []

	m = Mechanize.new
	m.user_agent_alias = 'Windows IE 8'

	loginpage = m.get("https://www.noip.com/login/")

	members_page = loginpage.form_with(:id => 'clogs') do |form|
		form.username = user
		form.password = password
	end.submit

	# Once successfuly logged in, access to DNS manage page
	dns_page = m.get("https://www.noip.com/members/dns/")
	dns_page.links_with(:text => "Modify").each do |link|
		# Update all the domains with my current IP
		update_host_page = m.click(link)
		hostname = update_host_page.forms[0].field_with(:name => "host[host]").value
		domain = update_host_page.forms[0].field_with(:name => "host[domain]").value
		updated_hosts << "#{hostname}.#{domain}"
		update_host_page.forms[0].field_with(:name => "host[ip]").value = my_public_ip
		update_host_page.forms[0].submit
	end

	return updated_hosts
end

def shouldUpdate?(check_file, public_ip)

	update = 0

	if !File.exist?(check_file)
		# file did not exist, so update
		f = File.new(check_file, "w+")
		update = 1

	else
		f = File.open(check_file, "r+")
		file_contents = f.readlines()
		date = Date.parse(file_contents[0])

		# check if update is necessary
		if (Date.today - 15) > date
			update = 2
		elsif (public_ip.to_s + "\n") != (file_contents[1].to_s)
			update = 3
		end

	end

	f.close()
	return update

end

# ================

def recordUpdateDate(filename, public_ip)
	f = File.open(filename, "w")
	f.write("#{Date.today.to_s}" + "\n")
	f.write(public_ip.to_s + "\n")
	f.close()
end

# ================

puts "======= #{Date.today.to_s} ========"

update_filename = File.expand_path(File.dirname(__FILE__)) + "/noip.autorenew.dat"

if ARGV[2].nil? or ARGV[3].nil? or ARGV[4].nil?
	puts "will not send gmail notifications"
	notifications = false
else
	notifications = true
end

if ARGV[0].nil? or ARGV[1].nil?
	puts "Error. Please specify the user and password to access your noip.com account"
	exit(1)
else
	user = ARGV[0]
	password = ARGV[1]
	gmail_username = ARGV[2]
	gmail_password = ARGV[3]
	gmail_to = ARGV[4]

	puts "Getting my current public IP..."
	my_public_ip = getMyCurrentIP()
	puts "Done: #{my_public_ip}"

	update = shouldUpdate?(update_filename, my_public_ip)
	if update == 0
		puts "Update was performed within the last 15 days and IP has not changed, exiting"

	elsif update > 0
		if update == 1
			puts "dat file doesn't exist"
		elsif update == 2
			puts "Update performed more than 15 days ago"
		elsif update == 3
			puts "IP has changed since last update"
			sendGmail(gmail_username, gmail_password, gmail_to, "updated IP address for #{user} to #{my_public_ip}")
		end

		puts "Sending request to noip.com..."
		updated_hosts = setMyCurrentNoIP(user,password,my_public_ip)
		if !updated_hosts.nil? and updated_hosts.size > 0
			puts "Done. Keeping alive #{updated_hosts.size} host with IP '#{my_public_ip}':"
			updated_hosts.each do |host|
				puts "- #{host}"
			end
			recordUpdateDate(update_filename, my_public_ip)
		else
			error_message = "There was an error while updating or there were no hosts to update"
			puts error_message
			if notifications		
				sendGmail(gmail_username, gmail_password, gmail_to, error_message)
			end
		end

	end

end

puts "==============================="
