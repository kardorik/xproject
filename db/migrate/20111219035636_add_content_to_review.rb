class AddContentToReview < ActiveRecord::Migration
  def self.up
    add_column :reviews, :content, :string
  end

  def self.down
    remove_column :reviews, :content
  end
end
