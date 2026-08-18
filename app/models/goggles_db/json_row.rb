# frozen_string_literal: true

module GogglesDb
  # = JsonRow
  #
  # Lightweight, read-only wrapper for JSON-decoded row hashes coming from the
  # aggregated '*_json' columns of the meeting result row views
  # (e.g. laps, relay legs & relay laps).
  #
  # Defines a singleton reader for each key found in the source hash, so that
  # decoded rows can be used like plain models by the view components
  # (e.g. +row.length_in_meters+, +row.minutes+, ...).
  #
  # Includes TimingManageable, so #to_timing (with the optional +from_start+
  # parameter), #positive? & #zero? are all supported whenever the source hash
  # carries the corresponding timing keys.
  #
  # Although mostly read-only, writer singleton methods are also defined so that
  # TimingManageable#from_timing can build derived rows (e.g. the closing lap)
  # without materializing an ActiveRecord instance.
  class JsonRow
    include TimingManageable

    attr_reader :attributes

    # Creates a new JsonRow given a Hash of attributes (string or symbol keys).
    def initialize(attributes)
      @attributes = attributes.transform_keys(&:to_s)
      define_accessors
    end

    # Returns a new Timing instance based on the 'XXX_from_start' keys.
    def timing_from_start
      to_timing(from_start: true)
    end

    def ==(other)
      other.is_a?(self.class) && other.attributes == attributes
    end

    def inspect
      "#<#{self.class.name} #{@attributes.inspect}>"
    end

    def initialize_copy(other)
      super
      @attributes = other.attributes.dup
      define_accessors
    end

    private

    # Defines singleton reader/writer methods for each attribute key.
    def define_accessors
      @attributes.each_key do |key|
        define_singleton_method(key) { @attributes[key] }
        define_singleton_method("#{key}=") { |value| @attributes[key] = value }
      end
    end
  end
end
