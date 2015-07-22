
module Fluent
  class FilePositionEntry
    require 'pathname'

    def initialize(file_path)
      @pos_file = file_path
    end

    def update_pos(pos)
      return unless @pos_file

      begin
        f = Pathname.new(@pos_file)
        f.open('wb') do |fp|
          Marshal.dump({
            :date => "#{pos[:date]}",
            :id   => "#{pos[:id]}",
          }, fp)
        end
      rescue => e
        $log.warn "Can't write pos_file #{e}"
      end
    end

    def read_pos
      min_date = "0000-01-01T00:00:00.000Z"

      return unless @pos_file
      f = Pathname.new(@pos_file)
      unless f.exist? then
        return ({:date=> min_date, :id=> ""})
      end
      
      pos = {}
      begin
        f.open('rb') do |_f|
          pos = Marshal.load(_f)
        end
      rescue => e
        return ({:date=> min_date, :id=> ""})
      end
      
      return (pos)
    end
  end
end
