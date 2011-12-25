class ReviewsController < ApplicationController
  layout 'simple'

  def new
  end

  def create
    rental_id = session[:rental_id]
    params[:review][:rental_id] = rental_id
    @review = Review.create(params[:review])
  end
end
