class Admin::ArticlesController < Admin::BaseController
  before_action :set_article, only: [ :edit, :update, :destroy ]
  before_action :set_openai_api_key_configured, only: [ :new, :edit ]

  def index
    @articles = Article.all.order(created_at: :desc).page(params[:page])
  end

  def drafts
    @articles = Article.drafts.order(created_at: :desc).page(params[:page])
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)
    @article.author = current_admin.user_id
    publication_flow.apply_state(@article)

    if @article.save
      redirect_with_publication_flow(@article)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    publication_flow.apply_state(@article)

    if @article.update(article_params)
      redirect_with_publication_flow(@article)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @article.destroy
    redirect_to admin_articles_path, notice: "Article was successfully deleted."
  end

  def preview
    render json: {
      html: helpers.markdown(params[:content] || "")
    }
  end

  def upload_image
    if params[:image].present?
      # 記事本文用の画像アップロード（2000px制限、WebP形式）
      result = ImageUploadService.upload(params[:image], upload_type: "content")

      if result[:error]
        render json: { error: result[:error] }, status: 422
      else
        render json: result
      end
    else
      render json: { error: "画像ファイルが選択されていません" }, status: 422
    end
  rescue => e
    Rails.logger.error "Image upload controller error: #{e.message}"
    render json: { error: "アップロードに失敗しました" }, status: 500
  end

  def generate_summary
    title = params[:title]
    body = params[:body]

    service = OpenaiService.new
    result = service.generate_summary(title: title, body: body)

    if result[:success]
      render json: { summary: result[:summary] }
    else
      render json: { error: result[:error] }, status: 422
    end
  rescue => e
    Rails.logger.error "Generate summary controller error: #{e.message}"
    render json: { error: "概要生成に失敗しました" }, status: 500
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def set_openai_api_key_configured
    @openai_api_key_configured = SiteSetting.openai_api_key_configured?
  end

  def article_params
    params.require(:article).permit(:title, :body, :summary, :thumbnail, :published_at)
  end

  def publication_flow
    @publication_flow ||= ArticlePublicationFlow.new(params[:commit])
  end

  def redirect_with_publication_flow(article)
    redirect_to publication_flow.redirect_path(article),
      notice: publication_flow.notice_message(article)
  end
end
