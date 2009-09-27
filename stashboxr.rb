require 'rubygems'
require 'net/http/post/multipart'
require 'xml'
require 'time'


# A library for dealing with files on http://stashbox.org 
module Stashbox
  # Represents a file on the stashbox servers. Creating a new Stashbox::Item object will start
  # a file upload to the stashbox server. Stashbox::Search queries will also return Stashbox::Item objects
  # and - with the required priviledges - you may edit a stashbox item via this class nomatter where it
  # comes from.
  class Item
    ATTRS = %w{id filename url know_code uploaded_on}
    ATTRS.each {|att| attr_reader att}
    
    def initialize(file, options)
      if file.nil?
        # To create an instance from an id
        raise "Please pass a filename, url or text (nil given)" if not options.has_key? :id
        options.delete_if{|key,v| not ATTRS.include? key.to_s}.each_pair do |key,value|
          eval("@#{key} = value")
        end
        @extended = false
      else
        # To upload a file
        url = URI.parse('http://stashbox.org/upload.php')
        info = nil
      
        if File.exists?(file)
          if File.size(file) > 67108864 # 64MB
            raise StandardError "That file is too large, sorry!"
          end
          File.open(file) do |fp|
            req = Net::HTTP::Post::Multipart.new url.path,:wants_rss => 1, :upload_type => 'local_file', :is_public => ((options[:is_public] || true) ? 1: 0),:file => UploadIO.new(fp, "text/plain", file)
            res = Net::HTTP.start(url.host, url.port) do |http|
              http.request(req)
            end
            info = XML::Parser.string(res.body).parse
          end
        else
          req = Net::HTTP::Post::Multipart.new url.path,:wants_rss => 1, :upload_type => ((file =~ /^http:\/\// and textfilename.nil?) ? 'remote_file' : 'text'), :is_public => ((options[:is_public] || true) ? 1: 0),:file => file,:filename => options[:filename] || "textupload.txt"
          res = Net::HTTP.start(url.host, url.port) do |http|
            http.request(req)
          end
          info = XML::Parser.string(res.body).parse
        end
      
        @id = $1.to_i if info.find('//upload/url')[0].content =~ /stashbox\.org\/(\d+)\//
        @url = info.find('//upload/url')[0].content
        @filename = info.find('//upload/filename')[0].content
        @knowcode = (info.find('//upload/know_code')[0].content == "") ? nil : info.find('//upload/know_code')[0].content
      end
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
    def self.do(q)
      doc = XML::Parser.string(Net::HTTP.get('stashbox.org', "/browse.php?wants_rss=1&q=#{URI.encode(q)}")).parse
      results = []
      doc.find('//item').each do |item|
        results << Item.new(nil,{
          :id => item.find('link')[0].content[/stashbox\.org\/(\d+)\//,1].to_i,
          :url => item.find('link')[0].content,
          :filename => item.find('link')[0].content[/stashbox\.org\/\d+\/(.+)$/,1],
          :uploaded_on => Time.parse(item.find('pubDate')[0].content)
        })
      end
      return results
    end
  end
end