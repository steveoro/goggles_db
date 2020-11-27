# frozen_string_literal: true

module GogglesDb
  #
  # = User model
  #
  #   - version:  7.035
  #   - author:   Steve A.
  #
  class User < ApplicationRecord
    self.table_name = 'users'

    # Include devise modules. Others available are: :omniauthable
    devise :database_authenticatable, :registerable,
           :confirmable, :lockable, :trackable,
           :recoverable, :rememberable, :validatable

    belongs_to :swimmer_level_type, optional: true
    belongs_to :coach_level_type, optional: true

    has_one :swimmer
    # FIXME: [Steve, 20141204] We should really rename this table using a passive name, something like "managed_affiliations"
    has_many :team_managers

    validates :name, presence: true, uniqueness: { case_sensitive: true, message: :already_exists }

    validates :description,   length: { maximum: 100 } # Same as Swimmer#complete_name
    validates :first_name,    length: { maximum: 50 }
    validates :last_name,     length: { maximum: 50 }
    validates :year_of_birth, length: { maximum: 4 }
  end
end
