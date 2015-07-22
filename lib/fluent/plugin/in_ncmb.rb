module Fluent
  class NcmbInput < Fluent::Input
    Fluent::Plugin.register_input('ncmb', self);

    require 'date'
    require 'ncmb'
    require './lib/fluent/plugin/file_pos_entry'
    include NCMB

    config_param :tag,             :string,  :default => nil
    config_param :application_key, :string,  :default => nil
    config_param :client_key,      :string,  :default => nil
    config_param :class_name,      :string,  :default => nil
    config_param :api_version,     :string,  :default => '2013-09-01'
    config_param :pos_file_path,   :string,  :default => './pos_file'

    config_param :interval,        :integer, :default => 10
    config_param :field,           :string,  :default => nil
    config_param :start_date,      :string,  :default => nil
    config_param :limit,           :integer, :default => 1000

    SORT_FIELD = "createDate,objectId"
    attr_reader :pos_entry
    attr_reader :last_pos

    def configure(conf)
      super

      raise Fluent::ConfigError.new("ConfigError: Please input tag") if @tag.nil?
      raise Fluent::ConfigError.new("ConfigError: Please input application_key") if @application_key.nil?
      raise Fluent::ConfigError.new("ConfigError: Please input client_key") if @client_key.nil?
      raise Fluent::ConfigError.new("ConfigError: Please input class_name") if @class_name.nil?
      raise Fluent::ConfigError.new("ConfigError: Please input pos_file_path") if @pos_file_path.nil?

      @ncmb_client = NCMB.initialize application_key: @application_key, client_key: @client_key
      @pos_entry = FilePositionEntry.new(@pos_file_path)
      @last_pos = @pos_entry.read_pos()

      @path = "/#{@api_version}/classes/#{@class_name}"

      unless @start_date.nil? then
        @start_date = DateTime.parse(@start_date)
      else
        @start_date = DateTime.now
      end
    end

    def start()
      super;
      
      @ncmb_thread = Thread.new(&method(:run))
    end

    def shutdown()
      @pos_entry.update_pos(@last_pos)
      @ncmb_thread.terminate()
    end

    def run()
      loop {
        loop {
          records = load_records();
          if records.length == 0 then
            break;
          end

          time = Time.now.to_i;
          @router.emit(@tag, time, records)
        } 

        sleep(@interval * 60);
      }
    end

    def load_records()
      queries = {}
      queries[:limit] = @limit + 1
      queries[:order] = SORT_FIELD
      queries[:where] = create_where_query(@start_date)

      items = @ncmb_client.get @path, queries
      items = remove_emitted_record(items)

      if items.length > 0 then
        @last_pos[:date] = items[-1][:createDate]
        @last_pos[:id]   = items[-1][:objectId]
      end

      records = []
      if @field.nil? then
        records = items 
      else  
        items.each do |item|
          records << {@field.intern => item[@field.intern]}
        end
      end

      return (records)
    end

    def remove_emitted_record(items)
      result_items = []
      items[:results].each do |item|
        if item[:createDate] > @last_pos[:date] then
          result_items << item
        elsif item[:createDate] == @last_pos[:date] then
          if item[:objectId] > @last_pos[:id] then
            result_items << item
          end
        end
      end

      return result_items
    end

    def create_where_query(conf_start_date)
      start_date = DateTime.parse(@last_pos[:date])
      if conf_start_date > start_date then
        start_date = conf_start_date
      end
  
      query = ""
      start_date_str = start_date.strftime("%FT%T.%LZ")
      query = "{\"createDate\": {\"$gte\": {\"__type\":\"Date\", \"iso\":\"#{start_date_str}\"}}}"

      return (query)
    end
  end
end
