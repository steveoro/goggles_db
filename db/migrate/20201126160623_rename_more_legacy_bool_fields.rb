# frozen_string_literal: true

class RenameMoreLegacyBoolFields < ActiveRecord::Migration[6.0]
  def change
    rename_table :articles, :posts
    rename_column :posts, :is_sticky, :pinned

    rename_column :badge_payments, :is_manual, :manual
    rename_column :badges, :is_out_of_goggle_cup, :off_gogglecup
    rename_column :badges, :has_to_pay_fees, :fees_due
    rename_column :badges, :has_to_pay_badge, :badge_due
    rename_column :badges, :has_to_pay_relays, :relays_due
    rename_column :category_types, :is_a_relay, :relay
    rename_column :category_types, :is_out_of_race, :out_of_race
    rename_column :category_types, :is_undivided, :undivided
    rename_column :disqualification_code_types, :is_a_relay, :relay
    rename_column :event_types, :is_a_relay, :relay
    rename_column :event_types, :is_mixed_gender, :mixed_gender
    rename_column :goggle_cups, :is_limited_to_season_types_defined, :limited_to_existing_season_types
    rename_column :goggle_cups, :has_to_create_standards, :create_standards
    rename_column :goggle_cups, :has_to_update_standards, :update_standards
    rename_column :goggle_cups, :is_team_limited, :team_constrained
    rename_column :heat_types, :is_default_value, :default
    rename_column :individual_records, :is_team_record, :team_record

    rename_column :seasons, :has_individual_rank, :individual_rank
    rename_column :stroke_types, :is_eventable, :eventable
    rename_column :swimmers, :is_year_guessed, :year_guessed
    rename_column :swimming_pools, :has_multiple_pools, :multiple_pools
    rename_column :swimming_pools, :has_open_area, :garden
    rename_column :swimming_pools, :has_bar, :bar
    rename_column :swimming_pools, :has_restaurant_service, :restaurant
    rename_column :swimming_pools, :has_gym_area, :gym
    rename_column :swimming_pools, :has_children_area, :child_area
    rename_column :swimming_pools, :do_not_update, :read_only
    rename_column :team_affiliations, :must_calculate_goggle_cup, :compute_gogglecup
    rename_column :team_affiliations, :is_autofilled, :autofilled
    rename_column :team_lap_templates, :has_subtotal, :subtotal
    rename_column :team_lap_templates, :has_cycle_count, :cycle_count
    rename_column :team_lap_templates, :has_breath_count, :breath_count
    rename_column :team_lap_templates, :has_non_swam_part, :underwater_part
    rename_column :team_lap_templates, :has_non_swam_kick_count, :underwater_kicks
    rename_column :team_lap_templates, :has_passage_position, :lap_position
    rename_column :user_results, :is_disqualified, :disqualified
  end
end
