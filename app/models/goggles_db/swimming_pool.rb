# frozen_string_literal: true

module GogglesDb
  #
  # = SwimmingPool model
  #
  #   - version:  7-0.5.10
  #   - author:   Steve A.
  #
  class SwimmingPool < ApplicationRecord
    self.table_name = 'swimming_pools'

    belongs_to :city
    belongs_to :pool_type

    belongs_to :shower_type, optional: true
    belongs_to :hair_dryer_type, optional: true
    belongs_to :locker_cabinet_type, optional: true

    validates_associated :city
    validates_associated :pool_type

    default_scope { includes(:city, :pool_type) }

    validates :name,          presence: { length: { within: 1..100, allow_nil: false } }
    validates :nick_name,     presence: { length: { within: 1..100, allow_nil: false } }
    validates :address,       length: { maximum: 100 }
    validates :phone_number,  length: { maximum:  40 }
    validates :fax_number,    length: { maximum:  40 }
    validates :e_mail,        length: { maximum: 100 }
    validates :contact_name,  length: { maximum: 100 }

    validates :lanes_number,  presence: { length: { within: 1..2, allow_nil: false } },
                              numericality: true

    validates :multiple_pools, inclusion: { in: [true, false] }
    validates :garden,         inclusion: { in: [true, false] }
    validates :bar,            inclusion: { in: [true, false] }
    validates :restaurant,     inclusion: { in: [true, false] }
    validates :gym,            inclusion: { in: [true, false] }
    validates :child_area,     inclusion: { in: [true, false] }
    validates :read_only,      inclusion: { in: [true, false] }

    delegate :name, to: :city, prefix: true, allow_nil: false

    # acts_as_taggable_on :tags_by_users
    # acts_as_taggable_on :tags_by_teams

    #-- ------------------------------------------------------------------------
    #   Sorting scopes:
    #-- ------------------------------------------------------------------------
    #++

    scope :by_name, ->(dir = :asc) { order(name: dir) }
    scope :by_city, ->(dir = :asc) { includes(:city).joins(:city).order('cities.name': dir) }

    # Sort by PoolType(type code, pool name)
    # == Params
    # - dir: :asc|:desc
    def self.by_pool_type(dir = :asc)
      includes(:pool_type).joins(:pool_type).order('pool_types.code': dir, 'swimming_pools.name': dir)
    end

    #-- ------------------------------------------------------------------------
    #   Filtering scopes:
    #-- ------------------------------------------------------------------------
    #++

    # Fulltext search by name or nick_name with additional domain inclusion by using standard "LIKE"s
    scope :for_name, lambda { |name|
      like_query = "%#{name}%"
      where(
        '(MATCH(swimming_pools.name, swimming_pools.nick_name) AGAINST(?)) OR ' \
        '(swimming_pools.name LIKE ?) OR (swimming_pools.nick_name LIKE ?) OR (swimming_pools.address LIKE ?)',
        name, like_query, like_query, like_query
      )
    }
    #-- ------------------------------------------------------------------------
    #++

    # Override: returns the list of single association names (as symbols)
    # included by <tt>#to_hash</tt> (and, consequently, by <tt>#to_json</tt>).
    #
    def single_associations
      %i[city pool_type shower_type hair_dryer_type locker_cabinet_type]
    end

    # Override: include some of the decorated fields in the output.
    #
    def minimal_attributes(locale = I18n.locale)
      super(locale).merge(
        'display_label' => decorate.display_label(locale),
        'short_label' => decorate.short_label(locale),
        'city' => city.decorate.short_label,
        'city_name' => city.name,
        'pool_code' => pool_type.code
      )
    end
  end
end
