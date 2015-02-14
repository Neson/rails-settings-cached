module RailsSettings
  class CachedSettings < Settings
    @@cache_expire_rate = 100
    after_commit :rewrite_cache, on: [:create, :update]
    def rewrite_cache
      Rails.cache.write("settings:#{self.var}:#{Time.now.to_i/@@cache_expire_rate}", self.value)
    end

    after_commit :expire_cache, on: [:destroy]
    def expire_cache
      Rails.cache.delete_matched("settings:#{self.var}:*")
    end

    def self.cache_expire_rate(rate)
      @@cache_expire_rate = rate
      expire_cache
    end

    def self.expire_cache
      Rails.cache.delete_matched("settings:*")
    end

    def self.reload
      expire_cache
    end

    def self.[](var_name)
      cache_key = "settings:#{var_name}:#{Time.now.to_i/@@cache_expire_rate}"
      obj = Rails.cache.read(cache_key)
      if obj == nil
        obj = super(var_name)
        Rails.cache.write(cache_key, obj)
      end

      return @@defaults[var_name.to_s] if obj == nil
      obj
    end

    def self.save_default(key,value)
      return false if self.send(key) != nil
      self.send("#{key}=",value)
    end
  end
end
