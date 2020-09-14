# rubocop:disable Style/FrozenStringLiteralComment

require 'singleton'

module GogglesDb
  #
  # = ValidationErrorTools
  #
  #   - author: Steve A.
  #
  #   Container class for any generic tool for validation error message decoration and extraction.
  #   Refactored from old implementation, (p) 2006-2014, FASAR Software, Italy
  #
  # === Typical usage:
  #
  #     ValidationErrorTools.recursive_error_for( any_active_record_instance )
  #
  class ValidationErrorTools
    include Singleton

    # Scans recursively the ActiveRecord row instance specified for validation errors,
    # returning the full error message and *all* the culprits for the validation failure.
    #
    # Whenever any errors are found, the standard error message has the format:
    #
    #   { 'invalid_member_name_1' => ['error_msg_1', 'error_msg_2', ...], ... }
    #
    # This allows us to perform a standard AI depth-first scan of the error keys,
    # until no errors are found or the only members with errors are not of the
    # ActiveRecord::Base kind (a leaf is reached).
    #
    # === Returns:
    # The full error string with the full sub-member hierachy, in case member.invalid?
    # is +true+. An empty string otherwise.
    #
    def self.recursive_error_for(member, error_msg = '')
      return error_msg if member.valid?

      # Loop on all nominated sub-members of the parent class and dive deeper to list its error:
      member.errors.messages.each_key do |sub_member_sym|
        sub_member = member.send(sub_member_sym)
        error_msg << if sub_member.is_a?(ActiveRecord::Base) # Recurse!
                       # Go deep until we found a "leaf" (an atomic or non-active_record member)
                       ValidationErrorTools.recursive_error_for(
                         sub_member,
                         "#{member.class.name} ID:#{member.id} => "
                       )
                     else # Leaf reached!
                       "#{member.class.name} ID:#{member.id}, " \
                       "#{sub_member_sym}: #{member.errors.messages[sub_member_sym].join(', ')}"
                     end
      end
      error_msg
    end
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
