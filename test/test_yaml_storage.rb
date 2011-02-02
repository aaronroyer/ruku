require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestYAMLStorage < Test::Unit::TestCase
  TMP_DIR = File.join(File.dirname(__FILE__), 'tmp', '.ruku')

  TEST_NAME_1 = 'Remote 1'
  TEST_NAME_2 = 'Remote 2'
  TEST_HOST_1 = '192.168.1.5'
  TEST_HOST_2 = '192.168.1.6'

  def setup
    cleanup
    @remote1 = Remote.new(TEST_HOST_1, TEST_NAME_1)
    @remote2 = Remote.new(TEST_HOST_2, TEST_NAME_2)
    @test_remotes = [@remote1, @remote2]
    @box_manager = Remotes.new(@test_remotes)
  end

  def teardown; cleanup; end

  def test_initialize_and_read_storage_path
    assert_equal TMP_DIR, YAMLStorage.new(TMP_DIR).storage_path
  end

  def test_store_and_load_box_manager
    YAMLStorage.new(TMP_DIR).store(@box_manager)
    m = YAMLStorage.new(TMP_DIR).load
    assert_equal @box_manager.boxes.size, m.boxes.size
    assert_equal @box_manager.active, m.active

    box1, box2 = m.boxes[0], m.boxes[1]
    assert_equal TEST_NAME_1, box1.name
    assert_equal TEST_HOST_1, box1.host
    assert_equal TEST_NAME_2, box2.name
    assert_equal TEST_HOST_2, box2.host
  end

  def test_store_no_boxes
    YAMLStorage.new(TMP_DIR).store(Remotes.new)
    m = YAMLStorage.new(TMP_DIR).load
    assert_equal 0, m.boxes.size
  end

  def test_load_from_non_existent_file
    m = YAMLStorage.new(TMP_DIR).load
    assert m.boxes.empty?
  end

  protected

  def cleanup
    File.delete(TMP_DIR) if File.exist?(TMP_DIR)
  end
end