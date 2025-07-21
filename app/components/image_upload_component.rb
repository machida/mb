class ImageUploadComponent < ViewComponent::Base
  def initialize(
    field_name:,
    label:,
    upload_url:,
    current_image: nil,
    form: nil,
    accept: "image/*",
    max_file_size: "5MB",
    help_text: "JPG, PNG, GIF (最大5MB)",
    spec_class: nil
  )
    @field_name = field_name
    @label = label
    @upload_url = upload_url
    @current_image = current_image
    @form = form
    @accept = accept
    @max_file_size = max_file_size
    @help_text = help_text
    @spec_class = spec_class
  end

  private

  attr_reader :field_name, :label, :upload_url, :current_image, :form,
              :accept, :max_file_size, :help_text, :spec_class

  def controller_data
    {
      controller: "thumbnail-upload",
      "thumbnail-upload-upload-url-value": upload_url
    }
  end

  def input_classes
    "hidden #{'spec--' + spec_class + '-input' if spec_class}"
  end

  def preview_image_src
    current_image.present? ? current_image : nil
  end

  def preview_classes
    base_classes = "max-w-xs h-auto rounded-lg border border-gray-300"
    base_classes += " hidden" unless current_image.present?
    base_classes
  end

  def clear_button_container_classes
    base_classes = "mt-2"
    base_classes += " hidden" unless current_image.present?
    base_classes
  end
end