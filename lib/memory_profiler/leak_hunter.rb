require 'objspace'

module MemoryProfiler
  class LeakHunter
    attr_reader :collection, :memsize_delta#, :times
    BEFORE = 'before'.freeze
    AFTER  = 'after'.freeze

    def initialize
      init_memsize = ObjectSpace.memsize_of_all
      memsize_2 = ObjectSpace.memsize_of_all 
      @memsize_delta = memsize_2 - init_memsize
      @before_all = init_memsize
      @collection = []
    end

    def check(uid:, meta: nil, &block)
      collection.push(name: uid, prefix: BEFORE, value: memsize, meta: meta, time: Time.current.to_i)
      result = block.call
      collection.push(name: uid, prefix: AFTER, value: memsize, meta: meta, time: Time.current.to_i)
      result
    end

    def end_up
      @after_all = memsize
    end

    def hunt_down_leak!
      res = ""
      res << "Total BEFORE: #{@before_all}\n"
      calc_delta!
      collection.each do |item|
        res << "  Key: #{item[:name]}\n"
        res << "    Prefix: #{item[:prefix]}\n"
        res << "    Mem Size: #{item[:value]}\n"
        res << "    Mem Delta: #{item[:mem_delta]}\n"
        res << "    Time Delta: #{item[:time_delta]}\n"
      end
      # collection.each do |key, value|
      #   if value.is_a?(Hash)
      #     res << "  Key: #{key}\n"
      #     res << "    Before: #{value[:before]}\n"
      #     res << "    After: #{value[:after]}\n"
      #   end
      # end
      res << "Total AFTER: #{@after_all}\n"
      res
    end

    def calc_delta!
      collection.map!.with_index do |item, idx|
        item[:mem_delta] = idx == 0 ? item[:value] - @before_all : item[:value] - collection[idx - 1][:value]
        item[:time_delta] = idx == 0 ? 0 : item[:time] - collection[idx - 1][:time]
        item
      end.sort_by! {|item| item[:mem_delta]}
    end

    def memsize
      ObjectSpace.memsize_of_all - memsize_delta#(memsize_delta * times)
    end
  end
end
