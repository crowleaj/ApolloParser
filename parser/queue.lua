  
--Found at https://www.lua.org/pil/11.4.html

   Queue = {}
    function Queue.new ()
      return {first = 0, last = -1}
    end

    function Queue.enqueue(list, value)
      local first = list.first - 1
      list.first = first
      list[first] = value
    end

    function Queue.empty(list)
      return list.first > list.last
    end
    function Queue.dequeue(list)
      local last = list.last
      if list.first > last then error("list is empty") end
      local value = list[last]
      list[last] = nil         -- to allow garbage collection
      list.last = last - 1
      return value
    end