require "./objects"

alias Bindings = Immutable::Map(String, Slang::Object)

class NSes
  property current : NS
  property nses = Hash(String, NS).new

  def initialize
    @current = NS.new "Global"
    @nses[@current.name] = @current
  end

  def change_ns(new_name)
    prev = @current
    @current = nses[new_name]? || NS.new new_name
    @nses[new_name] = @current
  end

  def alias_to(old, new_name)
    ns = @nses[old]
    @nses[new_name] = ns
  end

  def to_s(io)
    io << "ns: "
    io << current.name
    io << '\n'
    nses.each do |name, ns|
      ns.describe(io)
    end
  end

  def get_ns(name : String) : NS?
    @nses[name]?
  end

  delegate :[]=, :[], to: @current
end

class NS
  property defs = Hash(String, Slang::Object).new
  property aliased = Array(NS).new
  property name : String

  def initialize(@name)
  end

  def alias(ns : NS)
    aliased.push ns
  end

  def lookup(name : String, &block)
    @defs.fetch name do
      yield
    end
  end

  def [](iden)
    @defs[iden]
  end

  def []=(name : Slang::Identifier, value)
    @defs[name.simple!] = value
  end

  def []=(name, value)
    @defs[name] = value
  end

  def to_s(io)
    inspect io
  end

  def inspect(io)
    io << @name << '<'
    first = true
    @defs.each_key do |name|
      io << ' ' unless first
      first = false
      io << name
    end
    io << '>'
  end

  def describe(io)
    io << @name
    io << '\n'
    @defs.each do |n, d|
      io << n
      io << ": "
      d.to_s io
      io << '\n'
    end
  end
end
