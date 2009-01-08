require 'rubygems'
require 'httparty'

class SABnzbd
  
  class Job
    attr_accessor :id, :left, :done, :msgid, :filename
    def initialize(id, left, done, msgid, filename)
      self.id, self.left, self.done, self.msgid, self.filename = id, left, done, msgid, filename
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
  
  def initialize(username, password)
    login(username, password)
  end
  
  def login(username, password)
    self.class.default_params :ma_username => username, :ma_password => password
  end
  
  def status
    results = api_call(:qstatus, :output => "json")
    return Status.new(results)
  end
  
  def shutdown!
    verify api_call(:shutdown)
  end
  
  def resume!
    verify api_call(:resume)
  end
  
  def pause!
    verify api_call(:pause)
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
  
end