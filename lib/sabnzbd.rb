require 'rubygems'
require 'httparty'

class SABnzbd
  
  class Job
    attr_accessor :id, :left, :total, :msgid, :filename
    def initialize(id, left, total, msgid, filename)
      self.id, self.left, self.total, self.msgid, self.filename = id, left, total, msgid, filename
    end
  end
  
  class Status
    attr_accessor :paused, :queue_size, :jobs, :size_downloaded, :size_left, :time_left,
                  :complete_disk_free, :download_disk_free, :speed, :raw
    
    def alive?
      !alive
    end
    
    def paused?
      paused
    end
    
    def initialize(hash)
      self.raw             = hash
      self.paused          = hash["paused"]
      self.jobs            = self.class.jobs_from(hash)
      self.queue_size      = hash["noofslots"]
      self.size_downloaded = hash["mb"]
      self.size_left       = hash["mbleft"]
      self.time_left       = parse_time(hash)
      self.speed           = hash["kbpersec"]
      # Disk Spaces
      self.complete_disk_free = hash["diskspace1"]
      self.download_disk_free = hash["diskspace2"]
    end
    
    def self.jobs_from(hash)
      jobs = []
      hash["jobs"].each do |j|
        jobs << Job.new(j["id"], j["mbleft"], j["mb"], j["msgid"], j["filename"])
      end
      return jobs
    end
    
    private
    
    def parse_time(hash)
      t = hash["timeleft"]
      parts = t.split(":").map { |p| p.to_i }
      return parts[2] + parts[1] * 60 + parts[0] * 3600
    end
    
  end
  
  include HTTParty
  base_uri 'localhost:8080'
  
  def initialize(username = '', password = '')
    login(username, password)
  end
  
  def login(username, password)
    opts = {}
    opts[:ma_username] = username unless username.blank?
    opts[:ma_password] = password unless password.blank?
    self.class.default_params(opts)
  end
  
  def status
    results = api_call(:qstatus, :output => "json")
    return Status.new(results)
  end
  
  def shutdown!
    verify api_call(:shutdown)
  end
  
  def autoshutdown=(value)
    options = {:name => (value ? "1" : "0")}
    verify api_call(:autoshutdown, options)
  end
  
  def resume!
    verify api_call(:resume)
  end
  
  def pause!
    verify api_call(:pause)
  end
  
  def add_url(url, category = nil, job_options = nil, script = nil)
    options          = {}
    options[:name]   = url
    options[:cat]    = category if !category.blank?
    options[:pp]     = job_options if !job_options.blank?
    options[:script] = script if !script.blank?
    verify api_call(:addurl, options)
  end
  
  def add_newzbin(id, category = nil, job_options = nil, script = nil)
    options          = {}
    options[:name]   = id
    options[:cat]    = category if !category.blank?
    options[:pp]     = job_options if !job_options.blank?
    options[:script] = script if !script.blank?
    verify api_call(:addid, options)
  end
  
  def api_call(mode, opts = {})
    opts.merge!(:mode => mode.to_s)
    return self.class.get("/sabnzbd/api", :query => opts)
  end
  
  def verify(text)
    text.strip == "ok"
  end
  
  def jobs
    Status.jobs_from(status)
  end
  
  class << self
    
    @@settings_path = File.expand_path("~/.sabnzbd/sabnzbd.ini")
    
    def settings_path
      @@settings_path
    end
    
    def settings_path=(value)
      @@settings_path = value
    end
    
    def settings
      self.parse_ini(File.read(self.settings_path))
    end
    
    def local
      s = self.settings
      self.new(s["misc"]["username"], s["misc"]["password"])
    end
    
    protected
    
    def parse_ini(text)
      options = {}
      keys = []
      text.each_line do |line|
        if line =~ /^(\[+([^\[\]]+)\]+)$/
          normal, name = $1, $2
          start = line.match(/^\[+/)[0]
          depth = start.length
          if depth == 1
            keys = []
          elsif depth <= keys.size
            width = (depth - 2)
            width = 0 if width < 0
            keys = keys[0..width]
          end
          keys << name
          set_value options, keys, {}
        elsif line =~ /^(.*)=(.*)$/
          key, value = $1.strip, $2.strip
          set_value options, (keys + [key]), value
        end
      end
      return options
    end
    
    def set_value(options, keys, value)
      r = options
      keys[0..-2].each do |k|
        r = (r[k] ||= {})
      end
      r[keys.last] = value
      return options
    end
    
  end
  
end