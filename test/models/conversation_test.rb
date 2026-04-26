require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:in_pipeline_es)
    @student      = users(:student_es)
    @admin        = users(:admin)
  end

  test "student returns the user who owns the homologation request" do
    assert_equal @student, @conversation.student
  end

  test "unread_for? is false when there are no messages" do
    empty = conversations(:at_redsara_es)

    refute empty.unread_for?(@student)
    refute empty.unread_for?(@admin)
  end

  test "unread_for? is true when student has never read and messages exist" do
    assert @conversation.unread_for?(@student)
  end

  test "unread_for? is true when admin has never read and messages exist" do
    assert @conversation.unread_for?(@admin)
  end

  test "unread_for? is false when student last read after every message" do
    travel_to(1.minute.ago) { @conversation.mark_read_for!(@student) }

    refute @conversation.unread_for?(@student)
  end

  test "unread_for? is true when a message arrived after student last read" do
    travel_to(1.year.ago) { @conversation.mark_read_for!(@student) }

    assert @conversation.unread_for?(@student)
  end

  test "unread_for? checks admin_last_read_at for super_admins" do
    travel_to(1.year.ago)   { @conversation.mark_read_for!(@student) }
    travel_to(1.minute.ago) { @conversation.mark_read_for!(@admin) }

    refute @conversation.unread_for?(@admin)
    assert @conversation.unread_for?(@student)
  end

  test "mark_read_for! sets admin_last_read_at for super_admins" do
    freeze_time do
      @conversation.mark_read_for!(@admin)

      assert_equal Time.current, @conversation.reload.admin_last_read_at
      assert_nil   @conversation.student_last_read_at
    end
  end

  test "mark_read_for! sets student_last_read_at for students" do
    freeze_time do
      @conversation.mark_read_for!(@student)

      assert_equal Time.current, @conversation.reload.student_last_read_at
      assert_nil   @conversation.admin_last_read_at
    end
  end

  test "destroying a conversation destroys its messages" do
    assert_difference("Message.count", -1) { @conversation.destroy }
  end
end
