class RentalsController < ApplicationController
  layout 'simple'

  def new
  end

  def create
    @rental = Rental.create(params[:rental])
  end

  def search_form
  end

  def search
    param_zipcode = params[:rental][:zipcode]
    @rentals = Rental.find_all_by_zipcode(param_zipcode)
    render :action => :show_list
  end

  def show_list
  end

  def show_single
    param_id = params[:id]
    session[:rental_id] = param_id
    @rental = Rental.find_by_id(param_id)
  end

end
