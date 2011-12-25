class Rental < ActiveRecord::Base
  has_many :reviews
end
