# frozen_string_literal: true
class ChangeFilterModelIdToBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :discourse_events_filters, :model_id, :bigint
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
