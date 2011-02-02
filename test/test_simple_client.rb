require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'ruku/clients/simple'
require 'stringio'

# Tests for Ruku::Clients::Simple; most of these are more integration tests
# since the client is just a UI wrapper around the important stuff
class TestSimpleClient < Test::Unit::TestCase
  TEST_NAME_1 = 'Remote 1'
  TEST_NAME_2 = 'Remote 2'
  TEST_NAME_3 = 'Remote 3'
  TEST_HOST_1 = '192.168.1.5'
  TEST_HOST_2 = '192.168.1.6'
  TEST_HOST_3 = '192.168.1.7'

  def setup
    @output = ''
    @output_stream = StringIO.new(@output, 'w')
  end

  def teardown
    @output_stream.close
  end

  # Tests output of 'list' command line operation, trying to ignore slight
  # changes in UI like the header and making sure things like the names
  # and hosts of the remotes are displayed
  def test_cmd_line_list
    sc, out = get_test_client_and_output
    sc.list

    lines_method = ''.respond_to?(:lines) ? :lines : :to_s
    active1 = out.send(lines_method).find {|l| l.include? TEST_HOST_1}
    inactive2 = out.send(lines_method).find {|l| l.include? TEST_HOST_2}
    inactive3 = out.send(lines_method).find {|l| l.include? TEST_HOST_3}

    assert active1, 'Active box host found in output'
    assert active1.include?(TEST_NAME_1), 'Active box name on same line as host'
    assert active1.include?('active'), 'Active box marked as such in output'

    assert inactive2, 'First inactive box host found in output'
    assert inactive2.include?(TEST_NAME_2), 'First inactive box name on same line as host'
    assert !inactive2.include?('active'), 'First inactive box not marked as active'

    assert inactive3, 'Second inactive box host found in output'
    assert inactive3.include?(TEST_NAME_3), 'Second inactive box name on same line as host'
    assert !inactive3.include?('active'), 'Second inactive box not marked as active'
  end

  def test_add
    sc, out = get_test_client_and_output
    storage_mock = mock()
    sc.remotes = Remotes.new([], storage_mock)
    storage_mock.expects(:store).with(sc.remotes).once

    sc.add(TEST_HOST_1)

    assert sc.remotes.find {|b| b.host == TEST_HOST_1}, 'Box has been added'

    assert out.include?('Added'), 'Output indicates addition'
    assert out.include?(TEST_HOST_1), 'Output includes correct host'
    assert out.include?('My Roku Box'), 'Output shows (default) box name'
  end

  def test_add_with_name
    sc, out = get_test_client_and_output
    storage_mock = mock()
    sc.remotes = Remotes.new([], storage_mock)
    storage_mock.expects(:store).with(sc.remotes).once

    sc.add(TEST_HOST_1, TEST_NAME_1)

    assert sc.remotes.find {|b| b.host == TEST_HOST_1}, 'Box has been added'

    assert out.include?('Added'), 'Output indicates addition'
    assert out.include?(TEST_HOST_1), 'Output includes correct host'
    assert out.include?(TEST_NAME_1), 'Output shows correct box name'
  end

  def test_add_changes_existing_box_name
    sc, out = get_test_client_and_output
    storage_mock = mock()
    sc.remotes = Remotes.new([Remote.new(TEST_HOST_1, TEST_NAME_1)], storage_mock)
    storage_mock.expects(:store).with(sc.remotes).once

    new_name = 'Brand New Name'
    sc.add(TEST_HOST_1, new_name)

    assert sc.remotes.find {|b| b.host == TEST_HOST_1}, 'Box is still there'
    assert_equal new_name, sc.remotes.find {|b| b.host == TEST_HOST_1}.name, 'Name changed correctly'

    assert out.include?('Added'), 'Output indicates addition (even though it is not, really)'
    assert out.include?(TEST_HOST_1), 'Output includes correct host'
    assert out.include?(new_name), 'Output shows changed box name'
  end

  def test_remove_by_host
    sc, out = get_test_client_and_output
    storage_mock = mock()
    sc.remotes.storage = storage_mock
    storage_mock.expects(:store).with(sc.remotes).once

    sc.remove(TEST_HOST_2)

    assert_equal 2, sc.remotes.size, 'There is one less remote'
    assert sc.remotes.find {|b| b.host == TEST_HOST_1}, 'Did not remove the wrong remote'
    assert sc.remotes.find {|b| b.host == TEST_HOST_3}, 'Did not remove the wrong remote'

    assert out.include?('removed'), 'Output indicates removal'
    assert out.include?(TEST_HOST_2), 'Output includes correct host'
  end

  def test_name_with_host
    sc, out = get_test_client_and_output
    storage_mock = mock()
    sc.remotes.storage = storage_mock
    storage_mock.expects(:store).with(sc.remotes).once

    new_name = 'Renamed!'
    sc.name(TEST_HOST_3, new_name)

    assert_equal 3, sc.remotes.size, 'Did not add or remove any remotes'
    assert_equal new_name, sc.remotes.find {|r| r.host == TEST_HOST_3}.name, 'The name is changed'
  end

  def test_activate_with_host
    sc, out = get_test_client_and_output
    storage_mock = mock()
    sc.remotes.storage = storage_mock
    storage_mock.expects(:store).with(sc.remotes).once

    assert_equal TEST_HOST_1, sc.remotes.active.host

    sc.activate(TEST_HOST_3)

    assert_equal TEST_HOST_3, sc.remotes.active.host
    assert out.include?('activated'), 'Activation indicated'
    assert out.include?(TEST_HOST_3), 'Output includes correct host'
  end

  private

  def get_test_remotes
    @remote1 = Remote.new(TEST_HOST_1, TEST_NAME_1)
    @remote2 = Remote.new(TEST_HOST_2, TEST_NAME_2)
    @remote3 = Remote.new(TEST_HOST_3, TEST_NAME_3)
    Remotes.new([@remote1, @remote2, @remote3])
  end

  def get_test_client_and_output
    sc = Clients::Simple.new(get_test_remotes)
    sc.output_stream = @output_stream
    [sc, @output]
  end
end

class Ruku::Clients::Simple
  attr_accessor :output_stream

  def puts(str)
    @output_stream.puts str
  end

  def print(str)
    @output_stream.print str
  end
end
