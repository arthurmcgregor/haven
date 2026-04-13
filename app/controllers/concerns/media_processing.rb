module MediaProcessing
  extend ActiveSupport::Concern

  VIDEO_EXTENSIONS = %w[mp4 mov hevc].freeze
  AUDIO_EXTENSIONS = %w[mp3].freeze
  LARGE_IMAGE_WIDTH = 1600

  private

  # Builds an Image from an uploaded file and returns:
  # [image, html_snippet, url_to_embed, media_type]
  def attach_media(uploaded_file)
    image = Image.new
    image.blob.attach(uploaded_file)
    image.save!

    ext = path_for(image.blob).split(".").last.downcase
    if AUDIO_EXTENSIONS.include?(ext)
      [image, audio_html(image), image_path(image), "audio"]
    elsif VIDEO_EXTENSIONS.include?(ext)
      [image, video_html(image), image_path(image), "video"]
    else
      url = image_display_url(image)
      [image, image_html(image, url), url, "image"]
    end
  end

  # Public (well, concern-private) entry used by PostsController and
  # importers — picks the right URL and wraps large images in a link.
  def process_new_image(image)
    image_html(image, image_display_url(image))
  end

  def process_new_video(image)
    video_html(image)
  end

  def process_new_audio(image)
    audio_html(image)
  end

  def image_display_url(image)
    meta = ActiveStorage::Analyzer::ImageAnalyzer::ImageMagick.new(image.blob).metadata
    if meta[:width] && meta[:width] > LARGE_IMAGE_WIDTH
      image_resized_path(image)
    else
      image_path(image)
    end
  end

  def image_html(image, display_url)
    if display_url == image_resized_path(image)
      "\n\n<a href=\"#{image_path(image)}\">\n  <img src=\"#{display_url}\"></img>\n</a>"
    else
      "\n\n<img src=\"#{display_url}\"></img>"
    end
  end

  def video_html(image)
    "\n\n<video controls><source src=\"#{image_path(image)}\" type=\"video/mp4\"></video>"
  end

  def audio_html(image)
    "\n\n<audio controls><source src=\"#{image_path(image)}\" type=\"audio/mpeg\"></audio>"
  end

  def image_path(image)
    "/images/raw/#{image.id}/#{image.blob.filename}"
  end

  def image_resized_path(image)
    "/images/resized/#{image.id}/#{image.blob.filename}"
  end

  # Strips the scheme+host from url_for(obj), leaving "/path/to/obj"
  def path_for(obj)
    url = url_for(obj)
    "/#{url.split("/", 4)[3]}"
  end
end
