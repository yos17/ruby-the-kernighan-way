require "minitest/autorun"
require "wordtools"

class TestWordtools < Minitest::Test
  def test_tally_counts_lowercase_words
    result = Wordtools.tally("Hello hello WORLD")
    assert_equal({ "hello" => 2, "world" => 1 }, result)
  end

  def test_top_returns_n_most_frequent_alphabetically_for_ties
    result = Wordtools.top("the the and a", 2)
    assert_equal [["the", 2], ["a", 1]], result
  end

  def test_top_default_n_is_10
    text = %w[alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar].join(" ")
    assert_equal 10, Wordtools.top(text).length
  end
end
