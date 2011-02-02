require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestRemotes < Test::Unit::TestCase
  TEST_NAME_1 = 'Remote 1'
  TEST_NAME_2 = 'Remote 2'
  TEST_NAME_3 = 'Remote 3'
  TEST_HOST_1 = '192.168.1.5'
  TEST_HOST_2 = '192.168.1.6'
  TEST_HOST_3 = '192.168.1.7'

  def setup
    @test_storage_path = File.join(File.dirname(__FILE__), 'tmp', '.ruku')
    cleanup
    @remote1 = Remote.new(TEST_HOST_1, TEST_NAME_1)
    @remote2 = Remote.new(TEST_HOST_2, TEST_NAME_2)
    @remote3 = Remote.new(TEST_HOST_3, TEST_NAME_3)
  end

  def teardown
    cleanup
  end

  def test_initialize_adds_boxes
    assert Remotes.new.empty?

    m = Remotes.new([@remote1])
    assert_equal 1, m.boxes.size
    assert m.boxes.include?(@remote1)

    m = Remotes.new([@remote1, @remote2])
    assert_equal 2, m.boxes.size
    assert m.boxes.include?(@remote1)
    assert m.boxes.include?(@remote2)
  end

  def test_active_box_defaults_to_first
    assert_equal @remote1, Remotes.new([@remote1]).active
    assert_equal @remote1, Remotes.new([@remote1, @remote2]).active
  end

  def test_active_box_is_nil_if_no_boxes
    assert_nil Remotes.new.active
  end

  def test_set_active
    m = Remotes.new([@remote1, @remote2])
    assert_equal @remote1, m.active
    m.set_active(@remote2)
    assert_equal @remote2, m.active
  end

  def test_add
    m = Remotes.new([@remote1, @remote2])
    assert_equal 2, m.boxes.size
    m.add(@remote3)
    assert_equal 3, m.boxes.size
    m.boxes.include?(@remote3)
  end

  def test_add_does_not_add_duplicates
    m = Remotes.new([@remote1, @remote2])
    assert_equal 2, m.boxes.size
    m.add(@remote2)
    assert_equal 2, m.boxes.size
  end

  def test_remove
    m = Remotes.new([@remote1, @remote2])
    assert_equal 2, m.boxes.size

    m.remove(@remote2)
    assert_equal 1, m.boxes.size
    assert !m.boxes.include?(@remote2)

    m.remove(@remote1)
    assert m.boxes.empty?
    assert !m.boxes.include?(@remote2)
  end

  def test_remove_adjusts_active
    m = Remotes.new([@remote1, @remote2])
    m.set_active(@remote2)
    assert_equal @remote2, m.active
    m.remove(@remote2)
    assert_equal @remote1, m.active

    m = Remotes.new([@remote1, @remote2])
    assert_equal @remote1, m.active
    m.remove(@remote1)
    assert_equal @remote2, m.active
  end

  def test_remove_non_existent
    m = Remotes.new([@remote1, @remote2])
    assert_equal 2, m.boxes.size

    m.remove(@remote3)
    assert_equal 2, m.boxes.size
  end

  def test_store_and_load
    storage = YAMLStorage.new(@test_storage_path)
    Remotes.new([@remote1, @remote2], storage).store
    m = Remotes.new
    m.storage = storage
    m.load

    assert_equal 2, m.boxes.size
    assert_equal @remote1, m.boxes[0]
    assert_equal @remote2, m.boxes[1]
    assert_equal @remote1, m.active
  end

  def test_each
    m = Remotes.new([@remote1, @remote2])
    hosts = []
    m.each {|b| hosts << b.host}
    assert_equal 2, hosts.size
    assert hosts.include?(TEST_HOST_1)
    assert hosts.include?(TEST_HOST_2)
  end

  def test_subscript_reader
    m = Remotes.new([@remote1, @remote2])
    assert_equal TEST_HOST_1, m[0].host
    assert_equal TEST_HOST_2, m[1].host
  end

  def test_subscript_writer
    m = Remotes.new
    m[0] = @remote1
    assert_equal TEST_HOST_1, m[0].host
    m[0] = @remote2
    assert_equal TEST_HOST_2, m[0].host
    m[1] = @remote3
    assert_equal TEST_HOST_3, m[1].host
  end

  protected

  def cleanup
    File.delete(@test_storage_path) if File.exist?(@test_storage_path)
  end
end
