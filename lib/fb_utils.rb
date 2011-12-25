require 'httpclient'
require 'json'
require 'ruby-debug'

# corner
$app_url = 'http://76.217.211.93:3000/users/app_authenticate'
$app_id = '139096349472608'
$app_secret = '54c970891b31b869aa7e81520b712bb0'

# production
#$app_url = 'http://.../users/app_authenticate'
#$app_id = '...'
#$app_secret = '...'

class UserInfo
  attr_accessor :fbid, :name, :picture

  def initialize(fbid, name, picture)
    @fbid = fbid
    @name = name
    @picture = picture
  end
end

def get_token(code)
  app_auth_url = "https://graph.facebook.com/oauth/access_token?client_id=#{$app_id}&redirect_uri=#{$app_url}&client_secret=#{$app_secret}&code=#{code}"

  client = HTTPClient.new
  resp = client.get(app_auth_url)
  token = resp.content
  token.gsub!(/^access_token=/, "")
  token.gsub!(/&expires=.*/, "")
  session[:token] = token
  return token
end

# url is without access_token, for example:
#   "https://graph.facebook.com/me?access_token=#{token}"
# should be passed as:
#   "https://graph.facebook.com/me?access_token=TOKEN"
def query_graph(graph_url)
  token = session[:token]
  if token.nil?
    token = get_token()
  end
  client = HTTPClient.new
  fresh_token = false
  while 1
    graph_url.gsub!(/TOKEN/, token)
    graph_url = URI.escape(graph_url)
    graph_url = URI.encode(graph_url)
    resp = client.get(graph_url)
    #puts "response: #{resp.content}"

    parsed_resp = JSON.parse(resp.content)
    if not parsed_resp.include?("error")
      return parsed_resp
    else
      if fresh_token
        puts "fresh token does not work"
        return nil
      else
        puts "stale token get new one"
        token = get_token
        fresh_token = true
      end
    end
  end
end

def get_current_user_info
  graph_url = "https://graph.facebook.com/me?access_token=TOKEN"
  parsed_resp = query_graph(graph_url)
  name = parsed_resp["name"]
  fbid = parsed_resp["id"]
  picture = get_profile_picture(fbid)
  current_user_info = UserInfo.new(fbid, name, picture)
  session[:fbid] = fbid
  return current_user_info
end

def get_current_user_friend_infos
  graph_url = "https://graph.facebook.com/me/friends?access_token=TOKEN"
  parsed_resp = query_graph(graph_url)
  parsed_resp_data = parsed_resp["data"]
  friend_infos = Array.new
  parsed_resp_data.each { |info|
    fbid = info['id']
    name = info['name']
    friend_infos << UserInfo.new(fbid, name, nil)
  }
  return friend_infos
end

def get_user_name(fbid)
  graph_url = "https://graph.facebook.com/#{fbid}?access_token=TOKEN"
  parsed_resp = query_graph(graph_url)
  name = parsed_resp["name"]
  return name
end

# need to use old rest api, method not available in graph api yet
def get_mutual_friend_fbids(target_fbid)
  graph_url = "https://api.facebook.com/method/friends.getMutualFriends?target_uid=#{target_fbid}&access_token=TOKEN&format=JSON"
  parsed_resp = query_graph(graph_url)
  friends = parsed_resp
  return friends
end


# not allowed, can not query friends of other users
def get_other_friends(fbid)
  graph_url = "https://graph.facebook.com/#{fbid}/friends?access_token=TOKEN"
  parsed_resp = query_graph(graph_url)
  friends = parsed_resp["data"]
  return friends
end

class Contact
  attr_accessor :target_info, :mutual_infos

  def initialize(target_info, mutual_infos)
    @target_info = target_info
    @mutual_infos = mutual_infos
  end
end


def find_overlapping_users(sittertime)
  relaxed_start = sittertime.start.gsub(/[0-9][0-9]$/, "00")
  relaxed_end = sittertime.end.gsub(/[0-9][0-9]$/, "23")
  overlaps = Sittertime.find(:all, :conditions => "start >= #{relaxed_start} AND end <= #{relaxed_end}") 
  overlapping_users = Array.new
  overlaps.each { |overlap|
    if(overlap.user.fbid != session[:fbid])
      overlapping_users << overlap.user
    end
  }
  return overlapping_users
end

def find_contacts(sittertime)
  contacts = Array.new

  overlapping_users = find_overlapping_users(sittertime)
  if not overlapping_users.empty?
    friends = get_current_user_friend_infos
    overlapping_users.each { |overlapping_user|
      # try friends first, before mutual
      friends.each { |friend|
        if friend.fbid == overlapping_user.fbid
          picture = get_profile_picture(overlapping_user.fbid)
          overlapping_user_info = UserInfo.new(overlapping_user.fbid, overlapping_user.name, picture)
          contact = Contact.new(overlapping_user_info, [])
          contacts << contact
          next
        end
      }

      # not a direct friend, need to try mutual
      mutual_friend_fbids = get_mutual_friend_fbids(overlapping_user.fbid)
      if mutual_friend_fbids.empty?
        next
      else
        mutual_friend_infos = Array.new
        count_mutuals = 1
        count_mutuals_max = 3
        mutual_friend_fbids.each { |mutual_friend_fbid|
          mutual_friend_name = get_user_name(mutual_friend_fbid)
          picture = get_profile_picture(mutual_friend_fbid)
          mutual_friend_info = UserInfo.new(mutual_friend_fbid, mutual_friend_name, picture)
          mutual_friend_infos << mutual_friend_info
          if count_mutuals == count_mutuals_max
            break
          else
            count_mutuals += 1
          end
        }

        picture = get_profile_picture(overlapping_user.fbid)
        overlapping_user_info = UserInfo.new(overlapping_user.fbid, overlapping_user.name, picture)
        contact = Contact.new(overlapping_user_info, mutual_friend_infos)
        contacts << contact
      end
    }
  end

  return contacts
end

class ChainNode
  attr_accessor :fbid, :parent_fbid

  def initialize(fbid, parent)
    @fbid = fbid
    @parent = parent
  end
end

def find_mutual_friends(user)
  my_friends = get_friends()
  other_friends = get_other_friends(user.fbid)
  mutuals = Array.new
  other_friends.each { |other_friend|
    if my_friends.include? other_friend
      mutuals << other_friend
    end
  }
  return mutuals
end

def find_chains(users)
  friends = get_friends(session[:token])
  you_node = ChainNode.new(session[:fbid], nil)
  chain_nodes = Array.new
  friends.each { |friend|
    chain_node = ChainNode.new(friend['id'], you_node)
    chain_nodes << chain_node
  }
  other_chain_nodes = Array.new
  chain_nodes.each { |chain_node|
    other_friends = get_other_friends(chain_node.fbid)
    other_friends.each { |other_friend|
      other_chain_node = ChainNode.new(other_friend['id'], chain_node)
      other_chain_nodes << other_chain_node
    }
  }
end

def convert_time(date_string, time_string, ampm_string)
  month_to_number = {
    'JAN' => '01',
    'FEB' => '02',
    'MAR' => '03',
    'APR' => '04',
    'MAY' => '05',
    'JUN' => '06',
    'JUL' => '07',
    'AUG' => '08',
    'SEP' => '09',
    'OCT' => '10',
    'NOV' => '11',
    'DEC' => '12'
  }
  day_string, month_string, year_string = date_string.split("-")
  month_number = month_to_number[month_string]
  if ampm_string == "pm"
    time_number = time_string.to_i
    time_number += 12
    time_string = time_number.to_s
  end
  if time_string.size == 1
    time_string = "0" + time_string
  end
  converted = year_string + month_number + day_string + time_string
  return converted
end

def get_profile_picture(fbid)
  picture_url = "https://graph.facebook.com/#{fbid}/picture"

  client = HTTPClient.new
  resp = client.get(picture_url)
  location = resp.header["Location"][0]
  return location
end



