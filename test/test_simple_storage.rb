require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestSimpleStorage < Test::Unit::TestCase
  TMP_DIR = File.join(File.dirname(__FILE__), 'tmp')
  BOXES_FILE = File.join(TMP_DIR, 'boxes.txt')

  TEST_NAME_1 = 'Living Room'
  TEST_NAME_2 = 'Upstairs'
  TEST_NAME_3 = nil
  TEST_HOST_1 = '192.168.1.5'
  TEST_HOST_2 = 'NP-20F8A0003472'
  TEST_HOST_3 = '192.168.1.7'

  def setup
    cleanup
    @remote1 = Remote.new(TEST_HOST_1, TEST_NAME_1)
    @remote2 = Remote.new(TEST_HOST_2, TEST_NAME_2)
    @remote3 = Remote.new(TEST_HOST_3, TEST_NAME_3)
    @test_remotes = [@remote1, @remote2, @remote3]
    @remotes = Remotes.new(@test_remotes)
  end

  def teardown; cleanup; end

  def test_initialize_and_read_storage_path
    assert_equal BOXES_FILE, SimpleStorage.new(BOXES_FILE).storage_path
  end

  def test_store_and_load_box_manager
    SimpleStorage.new(BOXES_FILE).store(@remotes)
    boxes = SimpleStorage.new(BOXES_FILE).load
    assert_equal @remotes.boxes.size, boxes.boxes.size
    assert_equal @remotes.active, boxes.active

    box1, box2, box3 = boxes.boxes[0], boxes.boxes[1], boxes.boxes[2]
    assert_equal TEST_NAME_1, box1.name
    assert_equal TEST_HOST_1, box1.host
    assert_equal TEST_NAME_2, box2.name
    assert_equal TEST_HOST_2, box2.host
    assert_equal TEST_NAME_3, box3.name
    assert_equal TEST_HOST_3, box3.host
  end

  def test_store_no_boxes
    SimpleStorage.new(BOXES_FILE).store(Remotes.new)
    boxes = SimpleStorage.new(BOXES_FILE).load
    assert boxes.boxes.empty?
  end

  def test_load_from_non_existent_file
    boxes = SimpleStorage.new(BOXES_FILE).load
    assert boxes.boxes.empty?
  end

  def test_box_config_format_is_correct
    SimpleStorage.new(BOXES_FILE).store(@remotes)
    lines = IO.read(BOXES_FILE).split("\n")
    assert_equal 3, lines.size

    assert_equal '192.168.1.5:Living Room', lines[0]
    assert_equal 'NP-20F8A0003472:Upstairs', lines[1]
    assert_equal '192.168.1.7', lines[2]
  end

  protected

  def cleanup
    File.delete(BOXES_FILE) if File.exist?(BOXES_FILE)
  end
end