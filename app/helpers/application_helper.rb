module ApplicationHelper
  class HTMLWithSyntaxHighlighting < Redcarpet::Render::HTML
    def block_code(code, language)
      if language.present?
        formatter = Rouge::Formatters::HTML.new(css_class: "highlight")
        lexer = Rouge::Lexer.find(language) || Rouge::Lexers::PlainText
        highlighted = formatter.format(lexer.lex(code))
        "<div class=\"highlight\"><pre><code>#{highlighted}</code></pre></div>"
      else
        "<pre><code>#{ERB::Util.html_escape(code)}</code></pre>"
      end
    end
  end

  def markdown(text)
    return "" if text.blank?

    renderer = HTMLWithSyntaxHighlighting.new(
      filter_html: true,
      no_links: false,
      no_images: false,
      with_toc_data: false,
      hard_wrap: true,
      link_attributes: { target: "_blank" }
    )

    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true
    )

    markdown.render(text).html_safe
  end

  def format_date_with_weekday(date)
    weekdays = %w[日 月 火 水 木 金 土]
    weekday = weekdays[date.wday]
    date.strftime("%Y年%m月%d日（#{weekday}）")
  end

  def show_author_info?
    @_show_author_info ||= Article.published.select(:author).distinct.count >= 2
  end
end
