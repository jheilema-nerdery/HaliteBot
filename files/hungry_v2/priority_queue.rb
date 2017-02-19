# a heaped queue, so the smallest thing is always at the top.
# Based on http://www.brianstorti.com/implementing-a-priority-queue-in-ruby/
# 1-indexed for easier math.
class PriorityQueue
  attr_reader :elements

  def initialize(array)
    @elements = [nil] + array.sort
  end

  def <<(element)
    @elements << element
    bubble_up(@elements.size - 1)
  end

  def pop
    exchange(1, @elements.size - 1)
    max = @elements.pop
    bubble_down(1)
    max
  end

  private

  def bubble_up(index)
    parent_index = (index / 2)

    return if index <= 1
    return if (@elements[parent_index] <=> @elements[index]) < 1

    exchange(index, parent_index)
    bubble_up(parent_index)
  end

  def bubble_down(index)
    child_index = (index * 2)

    return if child_index > @elements.size - 1

    not_the_last_element = child_index < @elements.size - 1
    left_element = @elements[child_index]
    right_element = @elements[child_index + 1]
    child_index += 1 if not_the_last_element && (right_element <=> left_element) == -1

    return if (@elements[index] <=> @elements[child_index]) < 1

    exchange(index, child_index)
    bubble_down(child_index)
  end

  def exchange(source, target)
    @elements[source], @elements[target] = @elements[target], @elements[source]
  end
end

