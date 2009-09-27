require 'rubygems'
require 'net/http/post/multipart'
require 'hpricot'

# A library for dealing with files on http://stashbox.org 
module Stashbox
  # Represents a file on the stashbox servers. Creating a new Stashbox::Item object will start
  # a file upload to the stashbox server. Stashbox::Search queries will also return Stashbox::Item objects
  # and - with the required priviledges - you may edit a stashbox item via this class nomatter where it
  # comes from.
  class Item
    attr_reader :id, :filename, :url, :know_code
    
    def initialize(file, is_public = true)
      url = URI.parse('http://stashbox.org/upload.php')
      info = nil
      
      if File.exists?(file)
        if File.size(file) > 67108864 # 64MB
          raise StandardError "That file is too large, sorry!"
        end
        File.open(file) do |fp|
          req = Net::HTTP::Post::Multipart.new url.path,:wants_rss => 1, :upload_type => 'local_file', :is_public => ((is_public) ? 1: 0),:file => UploadIO.new(fp, "text/plain", file)
          res = Net::HTTP.start(url.host, url.port) do |http|
            http.request(req)
          end

          info = Hpricot(res.body)
        end
      else
        req = Net::HTTP::Post::Multipart.new url.path,:wants_rss => 1, :upload_type => ((file =~ /^http:\/\//) ? 'remote_file' : 'text'), :is_public => ((is_public) ? 1: 0),:file => file
        res = Net::HTTP.start(url.host, url.port) do |http|
          http.request(req)
        end
        info = Hpricot(res.body)
      end
      
      @id = $1.to_i if (info/:upload/:url)[0].inner_text =~ /stashbox\.org\/(\d+)\//
      @filename = (info/:upload/:filename)[0].inner_text
      @url = (info/:upload/:url)[0].inner_text
      @know_code = (info/:upload/:know_code)[0].inner_text
      @know_code = nil if @know_code == ""
      @extended = false
    end
    
    
    def extended?
      @extended
    end
    
    def extend
      # Get extended information
    end
  end
  
  # Deals with searching stashbox.org for files.
  class Search
    def initialize(q)
      info = Hpricot(Net::HTTP.get 'stashbox.org', "/browse.php?wants_rss=1&q=#{URI.encode(q)}")
      results = []
      (info/:channel/:item).each do |item|
        
      end
      return results
    end
  end
end

p Stashbox::Search.new("Test")