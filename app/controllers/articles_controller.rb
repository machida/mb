class ArticlesController < ApplicationController
  before_action :set_article, only: [:show]

  def index
    @articles = Article.published.order(created_at: :desc).page(params[:page])
  end

  def show
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
  end

  def archive_month
    @year = params[:year].to_i
    @month = params[:month].to_i
    @articles = Article.published.where("strftime('%Y', created_at) = ? AND strftime('%m', created_at) = ?", 
                             @year.to_s, sprintf("%02d", @month))
                      .order(created_at: :desc)
                      .page(params[:page])
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
end
