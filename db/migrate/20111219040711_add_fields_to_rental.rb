class AddFieldsToRental < ActiveRecord::Migration
  def self.up
    add_column :rentals, :street, :string
    add_column :rentals, :number, :string
    add_column :rentals, :unit, :string
    add_column :rentals, :city, :string
    add_column :rentals, :zipcode, :string
    add_column :rentals, :country, :string
  end

  def self.down
    remove_column :rentals, :street
    remove_column :rentals, :number
    remove_column :rentals, :unit
    remove_column :rentals, :city
    remove_column :rentals, :zipcode
    remove_column :rentals, :country
  end
end
