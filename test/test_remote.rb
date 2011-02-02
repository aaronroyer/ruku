require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestRemote < Test::Unit::TestCase
  TEST_HOST = "192.168.1.5"
  TEST_NAME = "Living room"
  TEST_PORT = 5000

  def test_initialize_and_read_host
    assert_equal TEST_HOST, Remote.new(TEST_HOST, TEST_NAME).host
  end

  def test_initialize_and_read_port
    assert_equal TEST_PORT, Remote.new(TEST_HOST, TEST_NAME, TEST_PORT).port
  end

  def test_initialize_and_read_name
    assert_equal TEST_NAME, Remote.new(TEST_HOST, TEST_NAME).name
  end

  def test_default_port
    assert_equal 8080, Remote::DEFAULT_PORT
    assert_equal Remote::DEFAULT_PORT, Remote.new(TEST_HOST, TEST_NAME).port
  end

  def test_send_command
    expect_command('left')
    r = default_remote
    r.send_roku_command :left
  end

  def test_send_command_as_string
    expect_command('left')
    r = default_remote
    r.send_roku_command 'left'
  end

  def test_select_overridden
    expect_command('sel')
    r = default_remote
    r.select
  end

  def test_select_fixed
    expect_command('sel')
    r = default_remote
    r.send_roku_command :select
  end

  # Make sure that most methods on the Remote have been undefined so that
  # almost any command can be sent
  def test_blank_slated
    mock = expect_command('freeze')
    expect_command('send', mock)
    r = default_remote
    r.freeze
    r.send
  end

  def test_commands_are_chainable
    mock = expect_command('down')
    expect_command('right', mock)
    r = default_remote
    assert_same r.down.right, r
  end

  def test_same_host_means_equal
    r1 = Remote.new(TEST_HOST, 'one')
    r2 = Remote.new(TEST_HOST, 'two')
    assert r1 == r2
    new_test_host = "192.168.1.7"
    assert new_test_host != TEST_HOST
    r3 = Remote.new(new_test_host, 'three')
    assert r1 != r3
    assert r3 != r1
  end

  protected

  def default_remote
    Remote.new(TEST_HOST, TEST_NAME)
  end

  def expect_command(cmd, mock_socket=mock())
    mock_socket.expects(:write).with("press #{cmd}\n").once
    mock_socket.expects(:close).once
    TCPSocket.expects(:open).with(TEST_HOST, Remote::DEFAULT_PORT).returns(mock_socket).once
    mock_socket
  end
end