require_relative '../priority_queue'

describe PriorityQueue do
  it 'starts with a list' do
    things = [4, 8, 6, 2]
    sorted_things = [nil, 2, 4, 6, 8]
    queue = PriorityQueue.new(things)
    expect(queue.instance_variable_get(:@elements)).to eql sorted_things
  end

  it 'adds things to the list' do
    things = [4, 8]
    queue = PriorityQueue.new(things)
    queue << 6
    queue << 2
    queue << 6
    expect(queue.instance_variable_get(:@elements).length).to eql 6
    expect(queue.instance_variable_get(:@elements)[1]).to eql 2
  end

  it 'pops things off the list after pushing them' do
    things = [8, 4]
    queue = PriorityQueue.new(things)
    queue << 6
    queue << 2
    queue << 6
    expect(queue.pop).to eql 2
    expect(queue.pop).to eql 4
    expect(queue.pop).to eql 6
    expect(queue.pop).to eql 6
    expect(queue.pop).to eql 8
    queue << 6
    queue << 2
    queue << 4
    expect(queue.pop).to eql 2
    expect(queue.pop).to eql 4
    expect(queue.pop).to eql 6
  end

  it 'sorts complicated things like arrays' do
    smallest = [0, -0.2, 5]
    small = [0, 0, 2]
    medium = [0, 1, -2]
    big = [1, -2, 5]
    things = [medium, big, smallest, small]
    queue = PriorityQueue.new(things)

    expect(queue.instance_variable_get(:@elements).length).to eql 5
    expect(queue.pop).to eql smallest
    expect(queue.pop).to eql small
    expect(queue.pop).to eql medium
    queue << small
    queue << smallest
    expect(queue.pop).to eql smallest
    expect(queue.pop).to eql small
    expect(queue.pop).to eql big
  end

end
