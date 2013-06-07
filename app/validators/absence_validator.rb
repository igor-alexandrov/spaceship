class AbsenceValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    if value.present?
      object.errors.add attribute, :present, options
    end
  end
end
