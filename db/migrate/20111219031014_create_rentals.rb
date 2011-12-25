class CreateRentals < ActiveRecord::Migration
  def self.up
    create_table :rentals do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :rentals
  end
end
