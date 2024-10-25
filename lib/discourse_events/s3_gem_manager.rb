# frozen_string_literal: true
require "aws-sdk-s3"

module DiscourseEvents
  class S3GemManager
    attr_reader :access_key_id, :secret_access_key, :region, :bucket

    def initialize(opts = {})
      @access_key_id = opts[:access_key_id]
      @secret_access_key = opts[:secret_access_key]
      @region = opts[:region]
      @bucket = opts[:bucket]
    end

    def ready?
      access_key_id && secret_access_key && region && bucket
    end

    def install(gems)
      return unless ready?
      write_gemrc

      gems.each do |gem_slug, version|
        klass = gem_slug.to_s.underscore.classify
        gem_name = gem_slug.to_s.dasherize
        opts = { require_name: gem_slug.to_s.gsub(/\_/, "/"), config: gemrc_path }
        load(plugin_path, gem_name, version, opts)
      end
    ensure
      remove_gemrc
    end

    protected

    # Compare PluginGem.load
    def load(path, name, version, opts = nil)
      opts ||= {}

      gems_path = File.dirname(path) + "/gems/#{RUBY_VERSION}"
      spec_path = gems_path + "/specifications"
      spec_file = spec_path + "/#{name}-#{version}"

      if PluginGem.platform_variants(spec_file).find(&File.method(:exist?)).blank?
        command =
          "gem install #{name} -v #{version} -i #{gems_path} --no-document --ignore-dependencies --no-user-install --config-file #{opts[:config]}"
        puts command
        Bundler.with_unbundled_env { puts `#{command}` }
      end

      spec_file_variant = PluginGem.platform_variants(spec_file).find(&File.method(:exist?))
      if spec_file_variant.present?
        Gem.path << gems_path
        Gem::Specification.load(spec_file_variant).activate
        require opts[:require_name]
      else
        puts "You are specifying the gem #{name} in #{path}, however it does not exist!"
        puts "Looked for: \n- #{PluginGem.platform_variants(spec_file).join("\n- ")}"
        exit(-1)
      end
    end

    def can_access_bucket?
      client.head_bucket(bucket: bucket)
      true
    rescue Aws::S3::Errors::BadRequest, Aws::S3::Errors::Forbidden, Aws::S3::Errors::NotFound => e
      false
    end

    def client
      @client ||=
        begin
          return nil unless region && access_key_id && secret_access_key

          Aws::S3::Client.new(
            region: region,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key,
          )
        end
    end

    def gemrc
      {
        sources: ["s3://#{bucket}/", "https://rubygems.org/"],
        s3_source: {
          "#{bucket}": {
            id: access_key_id,
            secret: secret_access_key,
            region: region,
          },
        },
      }
    end

    def write_gemrc
      File.write(gemrc_path, gemrc.to_yaml)
    end

    def remove_gemrc
      File.delete(gemrc_path) if File.exist?(gemrc_path)
    end

    def gemrc_path
      File.join(Rails.root, "tmp", ".gemrc")
    end

    def plugin_path
      @plugin_path ||= Discourse.plugins_by_name["discourse-events"].path
    end
  end
end
