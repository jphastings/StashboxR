require 'rubygems'
require 'mechanize'

# Allows percentages to be inspected and stringified in human
# form "33.3%", but kept in a float format for mathmatics
class Percentage < DelegateClass(Float)
  def to_s(decimalplaces = 0)
    (((self * 10**(decimalplaces+2)).round)/10**decimalplaces).to_s+"%"
  end
  alias :inspect :to_s
end

# A library for dealing with files on http://stashbox.org 
class Stashboxr
  # Settings for the browser emulation
  Agent = Mechanize.new { |agent| agent.user_agent = 'Stashboxr' }
  
  # Log into stashbox
  def self.login(username,password)
    res = Agent.post('http://stashbox.org/',{
      :dologin => 1,
      :user => username,
      :password => password
    })
    
    raise RuntimeError, "Log in failed" if res.code != "200"
    @@username = username
  end
  
  # Log out of stashbox
  def self.logout
    Agent.get('http://stashbox.org/logout.php')
    @@username = nil
    true
  end
  
  # Is someone logged in?
  def self.loggedin?
    !@@username.nil?
  end
  
  # Username of current logged in user (nil if not logged in)
  def self.username
    @@username
  end
  
  # Search stashbox.org - the site has this advice for formatting searches:
  #
  # You can use any number of terms in your search, all of which will be required in the results. You can also use the following search types (using "type:*the_type*" format): archives, audio, code, documents, images, movies
  #
  # Search types can be combined with normal search keywords to refine your results.
  # 
  # In addition, remember you can search for both full and partial mimetypes, ie _application/pdf_.
  def self.search(q)
    res = Nokogiri::XML(Agent.get("http://stashbox.org/browse.php?wants_rss=1&q=#{URI.encode(q)}").body)
    
    res.search('//item').collect do |item|
      File.new(item.search('link').inner_text)
    end
  end
  
  class File
    attr_reader :filename, :url, :unsaved
    attr_reader :know_code, :uploaded_on, :size, :views, :rating
    attr_accessor :title, :description
    attr_accessor :autosave
    
    SIZES = {
      '' => 9.765625e-4,
      'K' => 1,
      'M' => 1024
    }
    
    # Upload a file to stashbox and return a Stashbox::File object referencing it (which can be used to edit the metadata)
    def self.upload(local_file,is_public = true)
      # Does file exist?
      raise RuntimeError, "This file does not exist - I can't upload it!" if !::File.exists? local_file
      # Upload the file
      res = Agent.post('http://stashbox.org/upload.php',{
        :upload_type => "local_file",
        :wants_rss => 1,
        :file => open(local_file),
        :is_public => is_public
      })
      body = Nokogiri::XML(res.body)
      
      case res.code.to_i
      when 200
        new(body.search('//url').inner_text)
      else
        reason = body.search('//error').inner_text rescue nil
        raise RuntimeError, "The upload wasn't allowed"<<((reason.nil?) ? "" : " because '#{reason}'")
      end
    end
    
    def initialize(url)
      if (url =~ /(?:http:\/\/)?(?:stashbox\.org)?(?:\/v)?\/?([0-9]+\/(.+))$/)
        @stashboxid = $1
        @filename = $2
      else
        raise RuntimeError, "That isn't a valid stashbox URL"
      end
      
      @autosave = true
      @saved = true
    end
    
    # Has metadata been loaded
    def has_metadata?;   @metadata;                              end
    # If you make alterations to the file's metadata with autosave turned off, this will become true until to #save it.
    def autosave=(pref); @autosave = (pref != false);            end
    # Returns true if there are unsaved changes to the metadata for the file
    def unsaved?;        !@saved;                                end
    def url;             "http://stashbox.org/#{@stashboxid}";   end
    def tags;            refresh if not @metadata; @tags;        end
    def title;           refresh if not @metadata; @title;       end
    def description;     refresh if not @metadata; @description; end
    def uploaded_on;     refresh if not @metadata; @uploaded_on; end
    def size;            refresh if not @metadata; @size;        end
    def views;           refresh if not @metadata; @views;       end
    def rating;          refresh if not @metadata; @rating;      end
    def sfw?;            refresh if not @metadata; @sfw;         end
    def public?;         refresh if not @metadata; @public;      end
    
    # Add tags to the file on stashbox
    def add_tag(new_tags)
      # TODO: Parse input tags?
      @tags = (tags + parse_tags(new_tags)).uniq
      @saved = false
      save if @autosave
    end
    alias :add_tags :add_tag
    
    # Remove tags from the file on stashbox
    def remove_tag(new_tags)
      @tags = (tags - parse_tags(new_tags)).uniq
      @saved = false
      save if @autosave
    end
    alias :remove_tags :remove_tag
    
    # Reset the tags for this file to the ones in the given array
    def set_tags(new_tags)
      @tags = parse_tags(new_tags)
      @saved = false
      save if @autosave
    end
    
    def title=(title)
      @title = title
      @saved = false
      save if @autosave
    end
    
    def description=(description)
      @description = description
      @saved = false
      save if @autosave
    end
    
    def sfw=(sfw)
      @sfw = (sfw == true)
      @saved = false
      save if @autosave
    end
    
    def public=(ispublic)
      @public = (ispublic == true)
      @saved = false
      save if @autosave
    end
    
    # Save the metadata to Stashboxr. Called automatically with any changes by default.
    def save
      res = Agent.post("http://stashbox.org/manage_file/"<<@stashboxid,{
        :tags => @tags * " ",
        :meta_title => @title,
        :meta_description => @details,
        :is_nsfw => !@sfw,
        :is_public => @public
      })
      
      raise RuntimeError, "You don't have permission to edit this file" if res.body =~ /don't have permission/
      
      return res.code == "200"
    end
    
    # Delete this file (permanently!) from stashbox.org
    def delete
      res = Agent.post("http://stashbox.org/delete_upload/"<<@stashboxid)
      
      raise RuntimeError, "You don't have permission to delete this file" if res.body =~ /don't have permission/
      
      return res.code == "200"
    end
    
    def inspect
      keys = [@public ? "public" : "private"]
      keys.push("nsfw") if !@sfw and @metadata
      "<Stash: #{@filename} (#{keys * ", "})>"
    end
    
    # Grab metadata from stashbox.org
    def refresh
      # Get extended information
      doc = Agent.get "http://stashbox.org/v/"<<@stashboxid
      
      doc.search("//div[@class='subsection']").each do |sub|
        value = sub.search("div[@class='value']").inner_text.strip
        case sub.search("div[@class='label']").inner_text
        when "Size"
          @size = value[/^(\d+\.\d+)\ ([K|M]?)B$/,1].to_f * SIZES[$2]
        when "Uploaded On"
          @uploaded_on = Time.parse(value)
        when "Views"
          @size = value[/^(\d+)\ \(/,1].to_i
        when "Rating"
          @rating = Percentage.new(value[/(\d+\.\d+)\/5\ $/,1].to_f/5.0)
        when "Tags"
          @tags = sub.search("div[@class='value']/a").collect do |tag|
            tag.inner_text
          end
        when "Title"
          if sub.search("div[@class='value']/i").inner_text == ""
            @title = value
          else
            @title = nil
          end
        when "KnowCode"
          @know_code = value
        when "Description"
          if sub.search("div[@class='value']/i").inner_text == ""
            @description = value
          else
            @description = nil
          end
        when "Is this file work safe?"
          @sfw = (value == "Yes")
        end
      end
      @metadata = true
      return
    end
    
    private
    def parse_tags(new_tags)
      [new_tags].flatten.collect do |tag|
        tag.downcase.gsub(/[^a-z0-9_-]/,"")
        tag = nil if tag.empty?
      end.compact.uniq
    end
  end
end