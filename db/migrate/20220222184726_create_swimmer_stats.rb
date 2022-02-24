class CreateGogglesDb::SwimmerStats < ActiveRecord::Migration[6.0]
  def change
    create_view :swimmer_stats
  end
end
