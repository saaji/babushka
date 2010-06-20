module Babushka
  class MetaDepWrapper
    INVALID_NAMES = %w[base]

    def self.for supplied_name, source, opts, &block
      name = supplied_name.to_s.downcase
      if name.to_s.blank?
        raise ArgumentError, "You can't define a meta dep with a blank name."
      elsif name.in? INVALID_NAMES
        raise ArgumentError, "You can't use '#{name}' for a meta dep name, because it's reserved."
      elsif name[/^[a-z]/].nil?
        raise ArgumentError, "You can't use '#{name}' for a meta dep name - it must start with a letter."
      elsif name[Dep::VALID_NAME].nil?
        raise ArgumentError, "You can't use '#{name}' for a meta dep name - it can only contain [a-z0-9_]."
      elsif Babushka.const_defined?("#{name.to_s.camelize}DepDefiner") || Babushka.const_defined?("#{name.to_s.camelize}DepRunner")
        raise ArgumentError, "A meta dep called '#{name}' has already been defined."
      else
        new name, source, opts, &block
      end
    end

    attr_reader :name, :opts, :definer_class, :runner_class

    def initialize name, source, opts, &block
      @name = name.to_sym
      @opts = opts
      @block = block
      @definer_class = build_definer block
      @runner_class = build_runner
      source.templates.register self
    end

    def build_definer block
      Class.new(MetaDepDefiner, &block)
    end

    def build_runner
      Class.new(MetaDepRunner)
    end

    def define_dep name, opts, &block
      DepDefiner.current_load_source.deps.add name, opts, block, definer_class, runner_class
    end
  end
end
