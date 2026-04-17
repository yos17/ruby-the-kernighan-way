# Exercise 6 — first taste of Minitest
#
# Test TaskStore. Use a Tempfile so we don't write to disk.
#
# Skeleton:
#   require "minitest/autorun"
#   require "tempfile"
#   require_relative "../examples/tasks"
#
#   class TaskStoreTest < Minitest::Test
#     def setup
#       @file = Tempfile.new("tasks")
#       @store = TaskStore.new(@file.path)
#     end
#
#     def teardown
#       @file.close
#       @file.unlink
#     end
#
#     def test_add_assigns_incrementing_ids
#       a = @store.add("first")
#       b = @store.add("second")
#       assert_equal 1, a.id
#       assert_equal 2, b.id
#     end
#
#     # TODO: test_mark_done_sets_done_to_true
#     # TODO: test_find_raises_NotFound_for_missing_id
#   end
#
# Run: ruby exercises/6_task_store_test.rb
