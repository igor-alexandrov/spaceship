class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"

  namespace Rails.env

  begin
    hash = YAML.load(ERB.new(File.read("#{Rails.root}/config/application_local.yml")).result)[Rails.env]
    instance.deep_merge!(hash)
  rescue => e
  end
end
