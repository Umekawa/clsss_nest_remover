# frozen_string_literal: true

require 'minitest/autorun'
require_relative './main'

class Test < Minitest::Test
  def test_class_names_with_empty_array
    parent_names = []
    actual = class_names(parent_names)
    expected = ''
    assert_equal expected, actual
  end

  def test_class_names_with_single_list_of_string
    parent_names = [%w[a b c]]
    actual = class_names(parent_names)
    expected = "a,\nb,\nc"
    assert_equal expected, actual
  end

  def test_class_names_with_several_list_of_string
    parent_names = [
      %w[a b c],
      %w[d e f],
      %w[g h i]
    ]
    actual = class_names(parent_names)
    expected = parent_names.yield_self { |h, *t| h.product(*t) }.map(&:join).join(",\n")
    assert_equal expected, actual
  end

  def test_remove_extend_class_with_empty_array
    s = ''
    expected = s + "\n"
    actual = remove_extend_class(s.chars)
    assert_equal expected, actual
  end

  def test_remove_extend_class_with_comment_line
    s = <<~EOL.chop
      aaa // something
      bbb
    EOL
    expected = <<~EOL
       
      bbb
    EOL
    actual = remove_extend_class(s)
    assert_equal expected, actual
  end

  def test_remove_extend_class_with_comment_block
    s = <<~EOL.chop
      aaa /* something
      something2 */ bbb
    EOL
    expected = <<~EOL
      */ bbb
    EOL
    actual = remove_extend_class(s)
    assert_equal expected, actual
  end

  def test_remove_extend_class_with_block
    s = <<~EOL
      a{ body of a &b{ body of b }&c{ body of c } body of a2 }
    EOL
    expected = <<~EOL
      ab{ body of a { body of b }

      ac{ body of c }

      a body of a2 }
    EOL
    actual = remove_extend_class(s)
    assert_equal expected, actual
  end
end
