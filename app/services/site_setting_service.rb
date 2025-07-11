class SiteSettingService
  class << self
    def defaults
      @defaults ||= Rails.application.config.site_settings_defaults
    end

    def get(key)
      SiteSetting.get(key.to_s) || defaults[key.to_sym]
    end

    def set(key, value)
      SiteSetting.set(key.to_s, value.to_s)
    end

    def all_settings
      defaults.keys.each_with_object({}) do |key, hash|
        hash[key] = get(key)
      end
    end

    def update_settings(params)
      params.each do |key, value|
        set(key, value) if defaults.key?(key.to_sym)
      end
    end

    def reset_to_defaults!
      defaults.each do |key, value|
        set(key, value)
      end
    end
  end
end