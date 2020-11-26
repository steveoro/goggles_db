# frozen_string_literal: true

class RenameLegacyFieldsForTrainings < ActiveRecord::Migration[6.0]
  def change
    rename_table :news_feeds, :social_news
    rename_column :social_news, :is_read, :old
    rename_column :social_news, :is_friend_activity, :friend_activity
    rename_column :social_news, :is_achievement, :achievement
    rename_column :record_types, :is_for_swimmers, :swimmer
    rename_column :record_types, :is_for_teams, :team
    rename_column :record_types, :is_for_seasons, :season

    rename_column :base_movements, :is_arm_aux_allowed, :aux_arms_ok
    rename_column :base_movements, :is_kick_aux_allowed, :aux_kicks_ok
    rename_column :base_movements, :is_body_aux_allowed, :aux_body_ok
    rename_column :base_movements, :is_breath_aux_allowed, :aux_breath_ok
    rename_column :exercise_rows, :distance, :length_in_meters

    rename_table :arm_aux_types, :aux_arms_types
    rename_table :body_aux_types, :aux_body_types
    rename_table :breath_aux_types, :aux_breath_types
    rename_table :kick_aux_types, :aux_kicks_types

    rename_column :training_rows, :arm_aux_type_id, :aux_arms_type_id
    rename_column :training_rows, :body_aux_type_id, :aux_body_type_id
    rename_column :training_rows, :breath_aux_type_id, :aux_breath_type_id
    rename_column :training_rows, :kick_aux_type_id, :aux_kicks_type_id

    rename_column :user_training_rows, :arm_aux_type_id, :aux_arms_type_id
    rename_column :user_training_rows, :body_aux_type_id, :aux_body_type_id
    rename_column :user_training_rows, :breath_aux_type_id, :aux_breath_type_id
    rename_column :user_training_rows, :kick_aux_type_id, :aux_kicks_type_id
  end
end
