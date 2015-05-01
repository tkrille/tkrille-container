# Copyright 2015 Thomas Krille
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing
# permissions and limitations under the License.

Puppet::Type.type(:container).provide(:docker) do
  desc 'Docker support for running containers'

  FQIN_PATTERN = /\A([\w\-\.]+?(:[\d]+?)?\/)?([\w\-\.\+]+\/)?([\w\-\.]+)(:[\w\-\.]+)?\z/

  confine :kernel => :linux
  commands :docker => 'docker'

  def initialize(value ={})
    super(value)
    @property_changed = false
  end

  def self.instances
    container_lines = docker('ps', '--all', '--no-trunc').split(/\n/)
    container_lines.shift
    container_lines.map! { |it| it.split }

    container_ids = container_lines.map { |it| it[0] }
    container_ids_to_image = Hash[container_lines.map { |it| [it[0], it[1]] }]

    return [] if container_ids.empty?

    JSON.parse(docker('inspect', container_ids)).map do |container|
      new(:name => container['Name'].split('/').last,
          :ensure => :present,
          :image => container_ids_to_image[container['Id']],
          :env => get_env(container),
          :links => get_links(container),
          :volumes => get_volumes(container),
          :hostname => get_hostname(container),
          :ports => get_ports(container))
    end
  end

  def self.get_env(container)
    Hash[container['Config']['Env'].collect do |it|
           parts = it.split '=', 2
           [parts.first, parts.last]
         end]
  end

  def self.get_links(container)
    if container['HostConfig']['Links'].nil?
      {}
    else
      Hash[container['HostConfig']['Links'].collect do |it|
             parts = it.split ':', 2
             [parts.first.split('/').last, parts.last.split('/').last]
           end]
    end
  end

  def self.get_volumes(container)
    volumes_host = []
    volumes_host = container['HostConfig']['Binds'] unless container['HostConfig']['Binds'].nil?

    volumes_anon = []
    volumes_anon = container['Config']['Volumes'].map { |it| it[0] } unless container['Config']['Volumes'].nil?

    volumes_host.concat volumes_anon
  end

  def self.get_hostname(container)
    hostname = container['Config']['Hostname']
    hostname += ".#{container['Config']['Domainname']}" unless container['Config']['Domainname'].empty?
    hostname
  end

  def self.get_ports(container)
    ports = []

    container['HostConfig']['PortBindings'].each do |k, bindings|
      container_port = k.split(/\//, 2)[0]

      bindings.each do |binding|
        port = container_port
        port = "#{binding['HostPort']}:#{port}" unless binding['HostPort'].empty?
        port = ":#{port}" if binding['HostPort'].empty? and not binding['HostIp'].empty?
        port = "#{binding['HostIp']}:#{port}" unless binding['HostIp'].empty?
        ports << port
      end
    end

    ports
  end

  def self.prefetch(resources)
    containers = instances
    resources.keys.each do |name|
      provider = containers.find { |it| it.name == name }
      if provider
        resources[name].provider = provider
      end
    end
  end

  mk_resource_methods

  def create
    docker 'run', '-d', '--name', @resource[:name], create_options(@resource), @resource[:image]
  end

  def create_options(resource)
    opts = []

    resource[:env].collect { |k, v| opts << '-e' << "#{k}=#{v}" } unless resource[:env].nil? or resource[:env].empty?
    resource[:links].collect { |k, v| opts << '--link' << "#{k}:#{v}" } unless resource[:links].nil? or resource[:links].empty?
    resource[:volumes].collect { |v| opts << '-v' << "#{v}" } unless resource[:volumes].nil? or resource[:volumes].empty?
    opts << '-h' << resource[:hostname] unless resource[:hostname].nil? or resource[:hostname].empty?
    resource[:ports].collect { |v| opts << '-p' << "#{v}" } unless resource[:ports].nil? or resource[:ports].empty?

    opts
  end

  def destroy
    docker('stop', @resource[:name])
    docker('rm', '-f', @resource[:name])
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def validate
    # TODO: check invariants
  end

  def image=(fqin)
    @property_changed = true
  end

  def image_validate(fqin)
    fail("invalid value '#{fqin}' for 'image'") if (fqin =~ FQIN_PATTERN).nil?
  end

  def image_munge(fqin)
    fqin.scan FQIN_PATTERN do |match|
      if match[4].nil?
        return "#{fqin}:latest"
      end
    end

    fqin
  end

  def env=(env_hash)
    @property_changed = true
  end

  def links=(links_hash)
    @property_changed = true
  end

  def volumes=(volumes_array)
    @property_changed = true
  end

  def hostname=(hostname)
    @property_changed = true
  end

  def ports=(ports_array)
    @property_changed = true
  end

  def flush
    if @property_changed
      Puppet.debug("flush: renewing container #{@resource[:name]}")
      destroy
      create
    end

    @property_hash = resource.to_hash
  end
end
