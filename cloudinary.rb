require 'net/http'
require 'uri'
require 'json'

class Cloudinary
  def self.list_folder(folder_name)
    cloud_name = ENV['CLOUDINARY_CLOUD_NAME'];
    api_secret = ENV['CLOUDINARY_API_SECRET'];
    api_key = ENV['CLOUDINARY_API_KEY'];
    if cloud_name.nil? || api_secret.nil? || api_key.nil?
      raise <<-HEREDOC
        Error:
        Cloudinary environment not configured. The following variables are required:
          - CLOUDINARY_CLOUD_NAME
          - CLOUDINARY_API_SECRET
          - CLOUDINARY_API_KEY
      HEREDOC
    end
    fetch "https://api.cloudinary.com/api/v1_1/#{cloud_name}/resources/image?prefix=#{folder_name}&type=upload&max_results=100", api_key, api_secret
  end

  private

  def self.fetch(uri_str, api_key, api_secret, limit = 10)
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    uri = URI(uri_str)
    req = Net::HTTP::Get.new(uri)
    req.basic_auth api_key, api_secret
    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') { |http| http.request(req) }
    JSON.parse(response.body)
  end
end