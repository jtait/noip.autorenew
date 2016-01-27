#!/usr/bin/env ruby

# Summary:	This script avoids the need to manually login to http://www.noip.com every month and update your domains to keep them active.
#		It will automaticaly retrieve the machine's current public IP from http://checkip.dyndns.org/
# Original Author: Felipe Molina (@felmoltor)
# Date: July 2013
# License: GPLv3
# Minor changes (translation/language) by Jason Tait, January 2016

require 'date'
require 'mechanize'

def getMyCurrentIP()
	m = Mechanize.new
	m.user_agent_alias = 'Windows IE 8'
	
	ip_page = m.get("http://checkip.dyndns.org/")
	ip = ip_page.root.xpath("//body").text.gsub(/^.*: /,"")
	return ip
end

# ================

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

# ================

puts "======= #{Date.today.to_s} ========"

if ARGV[0].nil? or ARGV[1].nil?
	puts "Error. Please specify the user and password to access your noip.com account"
	puts "e.g. ruby noip.autorenew user password"
	exit(1)
else
	user = ARGV[0]
	password = ARGV[1]
	
	puts "Getting my current public IP..."
	my_public_ip = getMyCurrentIP()
	puts "Done: #{my_public_ip}"
	puts "Sending request to noip.com..."
	updated_hosts = setMyCurrentNoIP(user,password,my_public_ip)	
	if !updated_hosts.nil? and updated_hosts.size > 0
		puts "Done. Keeping alive #{updated_hosts.size} host with IP '#{my_public_ip}':"
		updated_hosts.each do |host|
			puts "- #{host}"
		end
	else
		$stderr.puts "There was an error while updating or there were no hosts to update"
	end
end

puts "==============================="
