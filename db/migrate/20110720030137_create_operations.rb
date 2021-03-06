class CreateOperations < ActiveRecord::Migration
  def self.up
    create_table :operations do |t|
      t.integer :operation_template_id
      t.integer :operator_id
      t.integer :app_id
      t.string :name
      t.string :state

      t.timestamps
    end
  end

  def self.down
    drop_table :operations
  end
end
