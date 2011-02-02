require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'ruku/clients/web'
require 'json'

class TestWebClient < Test::Unit::TestCase
  TEST_HOST_1 = "192.168.1.5"
  TEST_NAME_1 = "Living room"
  TEST_HOST_2 = "192.168.1.17"
  TEST_NAME_2 = "Basement"
  TEST_PORT_2 = 9090

  def test_remote_to_json
    parsed = JSON.parse(test_remotes.first.to_json)
    assert_equal TEST_HOST_1, parsed['host']
    assert_equal TEST_NAME_1, parsed['name']
    assert_equal 8080, parsed['port']

    parsed = JSON.parse(test_remotes.last.to_json)
    assert_equal TEST_HOST_2, parsed['host']
    assert_equal TEST_NAME_2, parsed['name']
    assert_equal TEST_PORT_2, parsed['port']
  end

  def test_remote_manager_remotes_from_json
    json = "{\"remotes\":[" +
      "{\"host\":\"#{TEST_HOST_1}\",\"name\":\"#{TEST_NAME_1}\"}," +
      "{\"host\":\"#{TEST_HOST_2}\",\"name\":\"#{TEST_NAME_2}\", \"port\":#{TEST_PORT_2}}" +
    "],\"active\":1}"
    rm = Remotes.new
    rm.remotes_from_json(json)
    assert_equal 2, rm.boxes.size
    assert_equal TEST_HOST_1, rm.boxes.first.host
    assert_equal TEST_NAME_1, rm.boxes.first.name
    assert_equal 8080, rm.boxes.first.port
    assert_equal TEST_HOST_2, rm.boxes.last.host
    assert_equal TEST_NAME_2, rm.boxes.last.name
    assert_equal TEST_PORT_2, rm.boxes.last.port
    assert_equal TEST_HOST_2, rm.active.host
  end

  protected

  def test_remotes
    [Remote.new(TEST_HOST_1, TEST_NAME_1), Remote.new(TEST_HOST_2, TEST_NAME_2, TEST_PORT_2)]
  end
end
