require_relative '../helper.rb'
require 'fluent/plugin/out_ncmb'

class NcmbOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    type            ncmb
    application_key APPLICATION_KEY
    client_key      CLIENT_KEY
    api_version     API_VERSION
    class_name      CLASS_NAME
    buffer_path     ./tmp/ncmb
    failed_log_path ./tmp/ncmb
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::NcmbOutput).configure(conf)
  end

  @case = {
    test1: 0,
    test2: 1,
    test3: 49,
    test4: 50,
    test5: 51,
    test6: 100,
    test7: 101,
    test8: 1000
  }

  data(@case)
  def test_write(data)
    d = create_driver
    count = 0
    stub(d.instance.ncmb).post {|_, query| count += query[:requests].size; [{'a' => 1}, {'b' => 2}]}

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    records = (1..data).map{|i| [{'a' => i}, time] }
    records.each do |record|
      d.emit(*record)
    end

    d.run
    assert_equal(data, count)
  end

  data(@case)
  def test_write_with_api_request_failure(data)
    d = create_driver
    stub(d.instance.ncmb).post {{code: 'E400000'}}

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    records = (1..data).map{|i| [{'a' => i}, time] }
    records.each do |record|
      d.emit(*record)
    end

    d.run
  end

  data(@case)
  def test_write_with_http_error(data)
    d = create_driver
    stub(d.instance.ncmb).post { raise 'TestException' }

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    records = (1..data).map{|i| [{'a' => i}, time] }
    records.each do |record|
      d.emit(*record)
    end

    d.run
  end
end
