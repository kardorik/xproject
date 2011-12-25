class AddUserToReview < ActiveRecord::Migration
  def self.up
    add_column :reviews, :user_id, :integer
    add_column :reviews, :rental_id, :integer
  end

  def self.down
    remove_column :reviews, :user_id
    remove_column :reviews, :rental_id
  end
end
