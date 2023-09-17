require "sinatra"
require "sinatra/reloader"

get("/") do
  "
  <h1>Welcome to your Sinatra App!</h1>
  <p>Define some routes in app.rb</p>
  "
end

get("/umbrella") do

  erb(:umbrella)

end

post("/process_umbrella") do
  require "http"
  require "json"

  # Call GMAPS API
  @user_location = params.fetch("user_location")
  
  @gmaps_api_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{CGI.escape(@user_location)}&key=AIzaSyDKz4Y3bvrTsWpPRNn9ab55OkmcwZxLOHI"

  @raw_response_gmaps = HTTP.get(@gmaps_api_url)

  @parsed_response_gmaps = JSON.parse(@raw_response_gmaps)

  @lat_long = @parsed_response_gmaps.fetch("results").at(0).fetch("geometry").fetch("location")

  # Extract Lat and Lng from GMAPS
  @lat = @lat_long.fetch("lat")
  @lng = @lat_long.fetch("lng")

  # Call PirateWeather API
  @weather_api_url = "https://api.pirateweather.net/forecast/3RrQrvLmiUayQ84JSxL8D2aXw99yRKlx1N4qFDUE/#{@lat},#{@lng}"

  @raw_response_weather = HTTP.get(@weather_api_url)

  @parsed_response_weather = JSON.parse(@raw_response_weather)

  @forecast = @parsed_response_weather.fetch("currently")

  #Extract Weather Info from PirateWeather

  @temp = @forecast.fetch("temperature")
  @skies = @forecast.fetch("summary")
  @chanceOfRain = @forecast.fetch("precipProbability")
  


  if @chanceOfRain <= 0.1
    @text = "You won't need an umbrella"
  else
    @text = "You should bring an umbrella"
  end


  erb(:process_umbrella)
end

get("/message") do


  erb(:message)

end


post("/process_single_message") do
  require "http"
  require "json"

  @the_message = params.fetch("the_message")
 ## @gpt_response = 

  @request_headers_hash = {
  "Authorization" => "Bearer #{ENV.fetch("GPT_KEY")}",
  "content-type" => "application/json"
}

@request_body_hash = {
  "model" => "gpt-3.5-turbo",
  "messages" => [
    {
      "role" => "system",
      "content" => "You are a helpful assistant."
    },
    {
      "role" => "user",
      "content" => @the_message
    }
  ]
}

@request_body_json = JSON.generate(@request_body_hash)

@raw_response = HTTP.headers(@request_headers_hash).post(
  "https://api.openai.com/v1/chat/completions",
  :body => @request_body_json
).to_s

@parsed_response = JSON.parse(@raw_response)

@text_response = @parsed_response.fetch("choices").at(0).fetch("message").fetch("content")

pp @text_response

  erb(:process_single_message)
  
end

get("/chat") do
  if !cookies["chat_history"]
    cookies.store("chat_history", JSON.generate([]))
  else
    @chat_history = JSON.parse(cookies.fetch("chat_history"))
  end
  erb(:chat)
end

post("/chat") do
  require "http"
  require "json"
  require "sinatra/cookies"

  @user_message = params.fetch("user_message")

  @chat_history = JSON.parse(cookies.fetch("chat_history"))



  @request_headers_hash = {
  "Authorization" => "Bearer #{ENV.fetch("GPT_KEY")}",
  "content-type" => "application/json"
}

@request_body_hash = {
  "model" => "gpt-3.5-turbo",
  "messages" => [
    {
      "role" => "system",
      "content" => "You are a helpful assistant."
    },
    {
      "role" => "user",
      "content" => @user_message
    }
  ]
}

@request_body_json = JSON.generate(@request_body_hash)

@raw_response = HTTP.headers(@request_headers_hash).post(
  "https://api.openai.com/v1/chat/completions",
  :body => @request_body_json
).to_s

@parsed_response = JSON.parse(@raw_response)

@text_response = @parsed_response.fetch("choices").at(0).fetch("message").fetch("content")

@chat_history.push({"role":"user", "content":@user_message})
@chat_history.push({"role":"assistant", "content":@text_response})

cookies.store("chat_history", JSON.generate(@chat_history))










































# @parsed_cookies = JSON.parse(cookies.fetch("chat_history"))











  

  redirect(:chat)
end

post("/clear_chat") do

  cookies["chat_history"] = JSON.generate([])
  redirect(:chat)
end
