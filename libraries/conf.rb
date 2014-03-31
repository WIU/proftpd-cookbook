
module ProFTPD
  module Conf

    def self.camel2underscore(str)
      str.gsub(/([^A-Z])([A-Z])/,'\1_\2').downcase
    end

    def self.underscore2camel(str)
      str.split('_').map { |e| e.capitalize }.join
    end

    def self.value(v)
      case v
      when Array
        v.map { |x| value(x) }.join(' ')
      when TrueClass
        'on'
      when FalseClass
        'off'
      when nil
        nil
      else
        v.to_s
      end
    end

    def self.set_env(hs)
      unless hs.kind_of?(Hash)
        raise Exceptions::ValidationFailed, "SetEnv attribute must be a kind of Hash! You passed #{hs.inspect}."
      end
      hs.map do |k, v|
        "SetEnv #{k} #{v}"
      end.join("\n")
    end

    def self.configuration_block(block_name, name, conf, prefix='')
      template = <<-EOT
<<%= @block.capitalize %><%= " \#{@name}" unless @name.nil?  %>>
<% @conf.sort.each do |key, value| -%>
<%=  ProFTPD::Conf.attribute(key, value, @prefix).gsub(/^/, '  ') %>
<% end -%>
</<%= @block.capitalize %>>
      EOT

      eruby = Erubis::Eruby.new(template)
      eruby.evaluate(
        :block => block_name,
        :name => name,
        :prefix => prefix,
        :conf => conf,
        :ProFTPD_Conf => ProFTPD::Conf
      )
    end

    def self.configuration_block_list(block_name, conf, prefix='')
      conf.collect do |name, conf|
        configuration_block(block_name, name, conf, prefix)
      end.join("\n")
    end

    def self.global(conf, prefix='')
      configuration_block('Global', nil, conf, prefix)
    end

    def self.directories(conf, prefix='')
      configuration_block_list('Directory', conf, prefix)
    end

    def self.virtual_hosts(conf, prefix='')
      configuration_block_list('VirtualHost', conf, prefix)
    end

    def self.anonymous(conf, prefix='')
      configuration_block_list('Anonymous', conf, prefix)
    end

    def self.limits(conf, prefix='')
      configuration_block_list('Limit', conf, prefix)
    end

    # Fix some camelcase conversions
    def self.attribute_name(name, prefix)
      prefix.to_s + case name
      when /^Sql(.*)$/
        "SQL#{$1}"
      when /^Tls(.*)$/
        "TLS#{$1}"
      when /^Vroot(.*)$/
        "VRoot#{$1}"
      when /^(.*)Dn$/
        "#{$1}DN"
      when /^(.*)Tls$/
        "#{$1}TLS"
      when /^(.*)Ipv6$/
        "#{$1}IPv6"
      when /^(.*)Rfc([0-9]+)$/
        "#{$1}RFC#{$2}"
      else
        name
      end
    end

    def self.attribute(name, value, prefix='')
      name = underscore2camel(name)
      case name
      when 'SetEnv'
        set_env(value)
      when 'Directories'
        directories(value)
      when 'VirtualHosts'
        virtual_hosts(value)
      when 'Anonymous'
        anonymous(value)
      when 'Limits'
        limits(value)
      else
        '%-30s %s' % [ attribute_name(name, prefix), value(value) ]
      end
    end

    def self.attribute_from_hash(hs, name)
      key = camel2underscore(name)
      if hs.has_key?(name)
        attribute(key, hs[name])
      elsif hs.has_key?(key)
        attribute(key, hs[key])
      end
    end

  end
end
