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
    year_range = range_for_year(@year)

    @articles = Article.published
                      .where(created_at: year_range)
                      .order(created_at: :desc)
                      .page(params[:page])

    @monthly_counts = monthly_counts_for(year_range)
    @show_author_info = calculate_show_author_info
  end

  def archive_month
    @year = params[:year].to_i
    @month = params[:month].to_i
    month_range = range_for_month(@year, @month)

    @articles = Article.published
                      .where(created_at: month_range)
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

  def range_for_year(year)
    raise ActiveRecord::RecordNotFound if year < 1

    start_time = Time.zone.local(year, 1, 1).beginning_of_day
    end_time = start_time.end_of_year.end_of_day
    start_time..end_time
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound
  end

  def range_for_month(year, month)
    raise ActiveRecord::RecordNotFound if year < 1 || month < 1 || month > 12

    start_time = Time.zone.local(year, month, 1).beginning_of_day
    end_time = start_time.end_of_month.end_of_day
    start_time..end_time
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound
  end

  def monthly_counts_for(range)
    Article.published
      .where(created_at: range)
      .pluck(:created_at)
      .each_with_object(Hash.new(0)) do |timestamp, counts|
        counts[timestamp.strftime("%m")] += 1
      end
  end
end
