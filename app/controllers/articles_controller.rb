class ArticlesController < ApplicationController
  before_action :set_article, only: [ :show ]

  def index
    @articles = Article.published.order(created_at: :desc).page(params[:page])
    @show_author_info = calculate_show_author_info
  end

  def show
    # 下書き記事は管理者以外アクセス不可
    if @article.draft? && !current_user_signed_in?
      redirect_to root_path, alert: "この記事は非公開です。"
      nil
    end
  end

  def archive_year
    @year = params[:year].to_i
    @articles = Article.published.where("strftime('%Y', created_at) = ?", @year.to_s)
                      .order(created_at: :desc)
                      .page(params[:page])

    # 月別の記事数を取得
    @monthly_counts = Article.published.where("strftime('%Y', created_at) = ?", @year.to_s)
                            .group("strftime('%m', created_at)")
                            .count
    @show_author_info = calculate_show_author_info
  end

  def archive_month
    @year = params[:year].to_i
    @month = params[:month].to_i
    @articles = Article.published.where("strftime('%Y', created_at) = ? AND strftime('%m', created_at) = ?",
                             @year.to_s, sprintf("%02d", @month))
                      .order(created_at: :desc)
                      .page(params[:page])
    @show_author_info = calculate_show_author_info
  end

  def feed
    @articles = Article.published.order(created_at: :desc).limit(20)

    respond_to do |format|
      format.rss { render layout: false }
    end
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def calculate_show_author_info
    @_show_author_info ||= SiteSetting.author_display_enabled && Article.published.select(:author).distinct.count >= 2
  end
end
