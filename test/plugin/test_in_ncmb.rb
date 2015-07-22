require_relative '../helper.rb'
require 'fluent/plugin/in_ncmb'

class NcmbInputTest < Test::Unit::TestCase

  POS_FILE_PATH = "./test/test_pos_file"
  CONFIG_NCMB = %[
    id ncmb
    tag hoge.a
    application_key hoge
    client_key hoge
    class_name test
    pos_file_path #{POS_FILE_PATH} 

    interval 1
  ]

  def setup
    Fluent::Test.setup

    if File.exist?(POS_FILE_PATH) then
      File.unlink POS_FILE_PATH
    end
  end

  def teardown
    if File.exist?(POS_FILE_PATH) then
      File.unlink POS_FILE_PATH
    end
  end

  def create_driver_ncmb(conf = CONFIG_NCMB)
    Fluent::Test::InputTestDriver.new(Fluent::NcmbInput).configure(conf)
  end
  def create_driver_ncmb_stub(conf = CONFIG_NCMB, stub_data = [])
    any_instance_of(NCMB::Client) do |klass|
      stub(klass).get {{:results=>stub_data}}
    end
    Fluent::Test::InputTestDriver.new(Fluent::NcmbInput).configure(conf)
  end

  def test_configure_ncmb
    d = create_driver_ncmb()
    assert_equal 'hoge.a',      d.instance.tag
    assert_equal 'hoge',        d.instance.application_key
    assert_equal 'hoge',        d.instance.client_key
    assert_equal 'test',        d.instance.class_name
    assert_equal POS_FILE_PATH, d.instance.pos_file_path
    assert_equal 1,             d.instance.interval
  end

  def test_configure_error
    not_tag_config = %[
      id ncmb
      application_key hoge
      client_key hoge
      class_name test
      pos_file_path #{POS_FILE_PATH}

      interval 1
    ]
    assert_raise Fluent::ConfigError do
      d = create_driver_ncmb(not_tag_config) 
    end
  end

  def test_emit_ncmb
    stub_data = [{:objectId=>"a", :createDate=>"2015-01-01T00:00:00.000Z", :num=>4},
                 {:objectId=>"b", :createDate=>"2015-01-01T00:00:01:000Z", :num=>5}]
    d = create_driver_ncmb_stub(CONFIG_NCMB, stub_data)

    d.run()
    
    actual_data = d.emits
    assert_true(actual_data[0][2] == stub_data)
  end

  def test_mistake_key
    d = create_driver_ncmb(CONFIG_NCMB)

    d.run()

    actual_data = d.emits
    assert_true(actual_data.empty?)
  end

  def test_field_param
    config = %[
      id ncmb
      tag hoge
      application_key hoge
      client_key hoge
      class_name test
      pos_file_path #{POS_FILE_PATH}

      interval 1
      field num
    ]
    stub_data = [{:objectId=>"a", :createDate=>"2015-01-01T00:00:00.000Z", :num=>4},
                 {:objectId=>"b", :createDate=>"2015-01-01T00:00:01:000Z", :num=>5}]
    success_data = [{:num=>4}, {:num=>5}]

    d = create_driver_ncmb_stub(config, stub_data)

    d.run()

    actual_data = d.emits
    assert_true(actual_data[0][2] == success_data)
  end

  def test_pos
    config = %[
      id ncmb
      tag hoge
      application_key hoge
      client_key hoge
      class_name test
      pos_file_path #{POS_FILE_PATH}

      interval 1
    ]

    stub_data = [{:objectId=>"a", :createDate=>"2015-01-02T00:00:00.000Z", :num=>1},
                 {:objectId=>"b", :createDate=>"2015-01-02T00:00:03.000Z", :num=>2},
                 {:objectId=>"c", :createDate=>"2015-01-02T00:00:03.000Z", :num=>3},
                 {:objectId=>"d", :createDate=>"2015-01-02T00:00:04.001Z", :num=>4},
                 {:objectId=>"e", :createDate=>"2015-01-02T00:00:04.001Z", :num=>5}]
    
    d = create_driver_ncmb_stub(config, stub_data)
    d.run()

    actual_data = d.emits
    pos_entry = d.instance.pos_entry
    last_pos  = d.instance.last_pos
    pos_entry.update_pos(last_pos)
    
    stub_data = [{:objectId=>"d", :createDate=>"2015-01-02T00:00:04.001Z", :num=>4},
                 {:objectId=>"e", :createDate=>"2015-01-02T00:00:04.001Z", :num=>5},
                 {:objectId=>"f", :createDate=>"2015-01-02T00:00:05.001Z", :num=>5},
                 {:objectId=>"g", :createDate=>"2015-01-02T00:00:05.001Z", :num=>5}]
    expected_data = stub_data.slice(2..3)

    d = create_driver_ncmb_stub(config, stub_data) 
    d.run()

    actual_data = d.emits
    assert_true(actual_data[0][2] == expected_data)
  end
end
