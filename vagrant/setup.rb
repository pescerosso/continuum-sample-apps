#!/opt/chef/bin/ruby
#
# Copyright 2015 Apcera Inc. All rights reserved.
require 'json'
require 'fileutils'
require 'open3'

class Setup
  CONFIG_FILE = "/home/vagrant/continuum-sample-apps/vagrant/continuum-setup.conf"

  attr_accessor :config

  def parse_config
    begin
      @config = JSON.parse(File.read(CONFIG_FILE))
    rescue => err
      puts("Initialize #{CONFIG_FILE} error: #{err}")
      exit(1)
    end
  end

  def save_config
    File.open(CONFIG_FILE, 'w') {|f| f.puts @config.to_json }
  end

  def exec_cmd(cmd)
    stdin, stdout, stderr = Open3.popen3(cmd)
    return stderr.read,stdout.read
  end

  def update_ip
    cmd = 'ifconfig eth1 | grep "inet addr:" | cut -d: -f2| cut -d" " -f1'
    err, out = exec_cmd(cmd)
    on_error(err) if err != ""
    @config["ip"] = out.strip
    save_config
  end

  def setup
    setup_cmd = "/opt/apcera/continuum/bin/continuum-setup "\
                "-config=/home/vagrant/continuum-sample-apps/vagrant/continuum-setup.conf 2>&1 | "\
                "tee /var/log/continuum-install.log"
    err, out = exec_cmd(setup_cmd)
    on_error(err) if err != ""
    puts out
  end

  def update_config
    err, out = exec_cmd('cat /CONTINUUM_DNS_TOKEN') 
    on_error(err) if err != ""
    @config["token"] = out.strip

    cmd = "cat /var/log/continuum-install.log | grep 'apc target' | awk '{print $3}' | cut -d'.' -f 1"
    err, out = exec_cmd(cmd)
    on_error(err) if err != ""
    @config["name"] = out.strip
    save_config
  end

  def on_error(err)
      puts err
      exit(1)
  end

end

setup = Setup.new
setup.parse_config
setup.update_ip
setup.setup
setup.update_config
