require 'httpclient'
require 'json'
require 'ruby-debug'

require 'fb_utils'

class UsersController < ApplicationController
  layout 'simple'

  def intro
    #render :layout => 'simple_large'
  end

  def app_authenticate
    code = params[:code]
    get_token(code)
    redirect_to :action => 'loggedin'
  end

  def loggedin
    @current_user_info = get_current_user_info
    user = User.find_by_fbid(@current_user_info.fbid)
    if user.nil?
      user = User.new
      user.name = @current_user_info.name
      user.fbid = @current_user_info.fbid
      user.save
    end

    # look for known friends
    @active_friends = Array.new
    friend_infos = get_current_user_friend_infos
    friend_infos.each { |friend_info|
      active_friend = User.find_by_fbid(friend_info.fbid)
      if not active_friend.nil?
        if friend_info.picture.nil?
          friend_info.picture = get_profile_picture(friend_info.fbid)
        end
        @active_friends << friend_info
      end
    }
  end

end

