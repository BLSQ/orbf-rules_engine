
module Assertions
  def self.valid_arg_keys!(args, known_keys)
    unknown_keys = args.keys - known_keys
    raise "unknown args #{unknown_keys} only supports #{known_keys}" if unknown_keys.any?
  end
end
