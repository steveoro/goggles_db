# frozen_string_literal: true

module GogglesDb
  #
  # = User model
  #
  #   - version:  7.000
  #   - author:   Steve A.
  #
  class User < ApplicationRecord
    self.table_name = 'users'

    # Include devise modules. Others available are: :omniauthable
    devise :database_authenticatable, :registerable,
           :confirmable, :lockable, :trackable,
           :recoverable, :rememberable, :validatable

    has_one :swimmer

    validates :name, presence: true, uniqueness: { case_sensitive: true, message: :already_exists }

    validates :description,   length: { maximum: 100 } # Same as Swimmer#complete_name
    validates :first_name,    length: { maximum: 50 }
    validates :last_name,     length: { maximum: 50 }
    validates :year_of_birth, length: { maximum: 4 }
  end
end
