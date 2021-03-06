require "immutable"

module Slang

  struct Identifier
    property parts : IdentifierPart
    property location : FileLocation

    def initialize(@location, value)
      @parts = IdentifierPart.new value
    end

    def to_s(io)
      parts.to_s(io)
    end

    def inspect(io)
      to_s(io)
    end

    def hash
      parts.hash
    end

    def simple : String?
      if @parts.rest.nil?
        @parts.value
      else
        nil
      end
    end

    def simple!
      if @parts.rest.nil?
        @parts.value
      else
        error! "cannot use composite var #{self} in simple context", self
      end
    end

    def lookup!(bindings)
      if s = simple
        bindings.fetch s do
          @parts.lookup bindings["*ns*"].as(Slang::Dynamic).value.as(NS), self
        end
      else
        @parts.lookup bindings["*ns*"].as(Slang::Dynamic).value.as(NS), self
      end
    end

    def lookup?(bindings)
      lookup! bindings
    rescue
      nil
    end
  end

  class IdentifierPart
    property value : String
    property rest : IdentifierPart?

    def initialize(value)
      val, _dot, rest = value.partition('.')
      @value = val
      if rest != ""
        @rest = IdentifierPart.new rest
      end
    end

    def lookup(ns, root)
      val = ns.lookup @value do
        error! "Undeffed identifier #{root}", root
      end

      if (r = @rest) && val.responds_to? :lookup
        return r.lookup(val, root)
      elsif @rest.nil?
        return val
      else
        error! "Non-ns value defined in #{root}", root
      end
    end

    def hash
      value.hash ^ (rest || 0).hash
    end

    def to_s(io)
      io << value
      if r = rest
        io << '.'
        r.to_s io
      end
    end
  end

  struct Atom
    property value : String
    property is_kw : Bool

    delegate :hash, to: @value

    def initialize(@value, @is_kw = false)
    end

    def to_s(io)
      io << ':' << @value
    end

    def inspect(io)
      to_s io
    end

    def with_colon_suffix(io : IO)
      io << @value << ':'
    end

    def kw_arg?; @is_kw end

    def call(args, kw_args)
      first = args.first
      if first.responds_to? :[]
        first[self]
      else
        nil
      end
    end
  end

  class Dynamic
    property value : Object

    def initialize(@value)
    end

    delegate :type, :to_s, :inspect, to: @value
  end

  alias Object = (Int32 | String | Bool | Immutable::Vector(Object) | List |
                  Immutable::Map(Object, Object) | Dynamic | Atom | Identifier | Splice |
                  Function | Protocol | Callable | Instance | Regex | NS | Nil)

  alias Result = Slang::Object

  class Splice
    def initialize(@body : Object)
    end

    def into(outer)
      b = @body
      if b.is_a? Slang::List
        b.each do |elem|
          outer << elem
        end
      elsif b.is_a? Slang::Vector
        b.each do |elem|
          outer << elem
        end
      else
        outer << b
      end
    end
  end

  class Error < Exception
    property trace : Array(Identifier | FileLocation)    

    def initialize(@message : String, cause = nil)
      @trace = [] of Identifier | FileLocation
      if c = cause
        @trace.push c
      end
    end

    def to_s(io)
      backtrace io
    end

    def add_to_trace(location)
      @trace.push location
    end

    def backtrace(io)
      io << @message << " from: "
      first = true
      @trace.each do |location|
        io << '\n' unless first
        first = false
        if location.is_a? Identifier
          location.to_s io
          io << ' '
          location = location.location
        end
        location.to_s io
      end
    end
  end
end
