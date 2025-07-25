class ImageUploadComponent < ViewComponent::Base
  def initialize(
    field_name:,
    upload_url:,
    current_image: nil,
    form: nil,
    accept: "image/*",
    max_file_size: "5MB",
    help_text: "JPG、PNG、GIF（最大5MB）。",
    spec_class: nil
  )
    @field_name = field_name
    @upload_url = upload_url
    @current_image = current_image
    @form = form
    @accept = accept
    @max_file_size = max_file_size
    @help_text = help_text
    @spec_class = spec_class
  end

  private

  attr_reader :field_name, :upload_url, :current_image, :form,
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
    "w-full aspect-[40/21] object-cover rounded-lg border border-gray-300"
  end

  def clear_button_container_classes
    "mt-2"
  end

  def preview_area_classes
    base_classes = "mt-4"
    base_classes += " hidden" unless current_image.present?
    base_classes
  end

  def dropzone_classes
    base_classes = "border-2 border-dashed border-gray-300 rounded-lg transition-colors w-full aspect-[40/21] flex items-center justify-center"
    base_classes += " hidden" if current_image.present?
    base_classes
  end
end