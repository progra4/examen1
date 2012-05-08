require 'securerandom'
module Models
  class Task

    @@instances = []

    attr_accessor :description, :priority, :assignee
    attr_reader :id

    def initialize(description, assignee, priority)
      @id = SecureRandom.uuid
      @description = description
      @priority = priority
      @assignee = assignee

      @@instances << self
    end

    def as_text
      "#{id}. [#{priority}] #{description} (#{assignee})"
    end

    def self.create(hash_or_array)
      if hash_or_array.is_a?(Hash)
        hsh = hash_or_array
        Task.new(hsh[:description], hsh[:assignee], hsh[:priority])
      elsif hash_or_array.is_a?(Array) && hash_or_array.all?{|e| e.is_a?(Hash)}
        hash_or_array.map{|h|  Task.create(h)  }
      end
    end

    def delete
      @@instances.delete_if{|instance|  instance.id = self.id }
    end

    def update(opts)
      opts.each do |attr, val|
        send("#{attr}=", val)
      end
    end

    def self.all
      @@instances.sort_by(&:priority)
    end

    def self.find(id)
      @@instances.find do |instance|
        instance.id == id
      end
    end

    def self.where(opts)
      @@instances.find_all do |instance|
        opts.collect do |attr, val|
          instance.send(attr) == val
        end.all?
      end.sort_by(&:priority)
    end

    def self.exists?(opts)
      !Task.where(opts).empty?
    end
  end

end
