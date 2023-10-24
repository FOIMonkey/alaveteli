require 'attachment_to_html/view'

require 'attachment_to_html/adapter'

Dir[File.dirname(__FILE__) + '/attachment_to_html/adapters/*.rb'].each do |file|
  require file
end

module AttachmentToHTML
  extend self

  def to_html(attachment, opts = {})
    adapter = adapter_for(attachment).new(attachment, opts)

    unless adapter.success?
      adapter = fallback_adapter_for(attachment).new(attachment, opts)
    end

    view = View.new(adapter)
    if adapter.is_a?(Adapters::GoogleDocsViewer)
      view.wrapper = 'wrapper_google_embed'
    end

    view.render do
      opts.fetch(:content_for, []).each do |k,v|
        inject_content(k) { v }
      end
    end
  end

  def extractable?(attachment)
    adapter_for(attachment) != Adapters::CouldNotConvert
  end

  private

  def adapter_for(attachment)
    case attachment.content_type
    when 'text/plain' then Adapters::Text
    when 'application/pdf' then Adapters::PDF
    when 'application/rtf' then Adapters::RTF
    else
      fallback_adapter_for(attachment)
    end
  end

  def fallback_adapter_for(attachment)
    if Adapters::GoogleDocsViewer.viewable?(attachment.content_type)
      Adapters::GoogleDocsViewer
    else
      Adapters::CouldNotConvert
    end
  end
end
