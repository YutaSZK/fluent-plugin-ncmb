module Fluent
  class NcmbOutput < Fluent::BufferedOutput
    # First, register the plugin. NAME is the name of this plugin
    # and identifies the plugin in the configuration file.
    Fluent::Plugin.register_output('ncmb', self)

    # required
    config_param :application_key,  :string,  :default => nil
    config_param :client_key,       :string,  :default => nil
    config_param :class_name,       :string,  :default => nil

    config_param :api_version,      :string,  :default => '2013-09-01'
    config_param :failed_log_path,  :string,  :default => '/var/log/fluent/ncmb'
    config_param :buffer_type,      :string,  :default => 'file'
    config_param :retry_limit,      :integer, :default => 3

    attr_reader :ncmb

    # This method is called before starting.
    def configure(conf)
      super

      raise Fluent::ConfigError.new("ConfigError: Please input application_key") if @application_key.nil?
      raise Fluent::ConfigError.new("ConfigError: Please input client_key") if @client_key.nil?
      raise Fluent::ConfigError.new("ConfigError: Please input class_name") if @class_name.nil?

      if @buffer_type == 'file'
        if Dir.exist?(@config['buffer_path'])
          unless File.writable?(@config['buffer_path'])
            raise Fluent::ConfigError.new("ConfigError: Permission denied => buffer_path: #{@buffer_path}")
          end
        else
          begin
            FileUtils.mkdir_p(@config['buffer_path'])
          rescue
            raise Fluent::ConfigError.new("ConfigError: Permission denied => buffer_path: #{@buffer_path}")
          end
        end
      end

      if Dir.exist?(@failed_log_path)
        unless File.writable?(@failed_log_path)
          raise Fluent::ConfigError.new("ConfigError: Permission denied => failed_log_path: #{@failed_log_path}")
        end
      else
        begin
          FileUtils.mkdir_p(@failed_log_path)
        rescue
          raise Fluent::ConfigError.new("ConfigError: Permission denied => failed_log_path: #{@failed_log_path}")
        end
      end

      require 'ncmb'
      @ncmb = NCMB.initialize(application_key: @application_key, client_key: @client_key)
    end

    # This method is called when starting.
    def start
      super

      @path = "/#{@api_version}/classes/#{@class_name}"
      @mutex = Mutex.new
    end

    # This method is called when shutting down.
    def shutdown
      super
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      records = []

      @mutex.lock
      begin
        chunk.msgpack_each do |tag, time, record|
          records << [tag, time, record]
        end
      ensure
        @mutex.unlock
      end

      # batchAPIの件数上限が50のため、50件毎に実行する
      records.each_slice(50) do |slice|
        bulk_insert(slice)
      end
    end

    def bulk_insert(records)
      requests = records.map {|tag, time, record|
        {path: @path, method: :POST, body: {tag: tag, time: time, record: record}}
      }
      cnt = 0
      while cnt < @retry_limit
        begin
          res = @ncmb.post("/#{@api_version}/batch", requests: requests)
        rescue
          # リクエストが失敗した場合
          next cnt += 1
        end

        # レスポンスがエラーだった場合
        if res.is_a?(Hash) && res.has_key?(:code)
          next cnt += 1
        else
          return
        end
      end

      # retry上限を超えても送信できなかった場合、送信失敗logに書き込む
      write_failed_log(records)
      return
    end

    def write_failed_log(records)
      msgpack = records.map{|record| format(*record)}.to_msgpack
      File.open("#{@failed_log_path}/failed.log", 'a+') do |file|
        file.sync = true
        file.write(msgpack)
      end
    end
  end
end
