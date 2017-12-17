require "./func"

module Slang
  module Dispatchable
    
  end

  class Instance
    property type : Type
    property attributes : Slang::Map

    def initialize(@type, @attributes)
    end
    
    def set_attr(k, v)
      new(type, @attributes.set(k, v))
    end

    def to_s(io)
      @type.to_s(io)
      io << ": "
      @attributes.to_s(io)
    end
  end

  class Type < Callable
    property implementations = Hash(Protocol, ProtocolImplementation).new
    property name : String?
    getter attr_names : Array(String)

    def initialize(@attr_names)
    end

    # This is the constructor, called like a function
    def call(values)
      attrs = Hash(String, Object).new
      @attr_names.each_with_index do |attr, idx|
        attrs[attr] = values[idx]
      end
      {Instance.new(self, Slang::Map.new(attrs)), nil}
    end

    def dispatch_method(protocol, func, args)
      implementation = implementations[protocol]
      implementation.call(func, args)
    end

    def to_s(io)
      io << (@name || "unnamed")
    end
  end

  class Protocol
    property name : String? = nil
    property methods : Array(String)

    def initialize(@methods)
    end
  end

  class ProtocolImplementation
    property methods : Hash(String, Callable)

    def initialize(@methods)
    end

    def call(func, args)
      methods[func].call(args)
    end
  end

  module CrystalSendable
    def send(protocol, func, args)
      type.dispatch_method(protocol, func, args)
    end

    def type
      {{ (@type.stringify + "Type").id }}.instance
    end
  end
end
