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

      name = container['Name'].split('/').last
      image = container_ids_to_image[container['Id']]
      env = Hash[container['Config']['Env'].collect do |it|
                   parts = it.split '=', 2
                   [parts.first, parts.last]
                 end]

      new(:name => name,
          :ensure => :present,
          :image => image,
          :env => env)
    end
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
    options = create_options @resource
    docker('run', '-d', '--name', @resource[:name], options, @resource[:image])
  end

  def create_options(resource)
    opts = []

    resource[:env].collect { |k, v| opts << "-e" << "#{k}=#{v}" } unless resource[:env].nil? or resource[:env].empty?

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

  def flush
    if @property_changed
      Puppet.debug("flush: renewing container #{@resource[:name]}")
      destroy
      create
    end

    @property_hash = resource.to_hash
  end
end
