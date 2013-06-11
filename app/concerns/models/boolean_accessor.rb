module Models::BooleanAccessor
  extend ActiveSupport::Concern
    
  module ClassMethods
    def boolean_accessor(*attributes)
      attributes.each do |attribute|
        define_method "#{attribute}!" do
          instance_variable_set("@#{attribute}", true)
        end
        
        define_method "#{attribute}?" do
          !!instance_variable_get("@#{attribute}")
        end
      end
    end
  end
end