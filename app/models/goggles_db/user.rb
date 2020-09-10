# frozen_string_literal: true

#
# = User model
#
#   - version:  7.000
#   - author:   Steve A.
#
module GogglesDb
  class User < ApplicationRecord
    self.table_name = 'users'

    # Include devise modules. Others available are: :omniauthable
    devise :database_authenticatable, :registerable,
           :confirmable, :lockable, :trackable,
           :recoverable, :rememberable, :validatable

    validates :name, presence: true
    validates :name, uniqueness: { case_sensitive: true, message: :already_exists }

    validates     :description,   length: { maximum: 100 } # Same as Swimmer#complete_name
    validates     :first_name,    length: { maximum: 50 }
    validates     :last_name,     length: { maximum: 50 }
    validates     :year_of_birth, length: { maximum: 4 }
  end
end
