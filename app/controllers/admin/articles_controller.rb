class Admin::ArticlesController < Admin::BaseController
  before_action :set_article, only: [:show, :edit, :update, :destroy]

  def index
    @articles = Article.all.order(created_at: :desc).page(params[:page])
  end

  def drafts
    @articles = Article.drafts.order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)
    @article.author = current_admin.user_id
    
    if params[:commit] == "下書き保存"
      @article.draft = true
    end
    
    if @article.save
      if @article.draft?
        redirect_to admin_articles_path, notice: '下書きを保存しました。'
      else
        redirect_to article_path(@article), notice: '記事を公開しました。'
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:commit] == "下書き保存"
      @article.draft = true
    elsif params[:commit] == "公開"
      @article.draft = false
    end
    
    if @article.update(article_params)
      if @article.draft?
        redirect_to admin_articles_path, notice: '下書きを保存しました。'
      else
        redirect_to article_path(@article), notice: '記事を公開しました。'
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to admin_articles_path, notice: 'Article was successfully deleted.'
  end

  def preview
    render json: { 
      html: helpers.markdown(params[:content] || '') 
    }
  end

  def upload_image
    if params[:image].present?
      # 記事本文用の画像アップロード（2000px制限、WebP形式）
      result = ImageUploadService.upload(params[:image], upload_type: 'content')
      
      if result[:error]
        render json: { error: result[:error] }, status: 422
      else
        render json: result
      end
    else
      render json: { error: '画像ファイルが選択されていません' }, status: 422
    end
  rescue => e
    Rails.logger.error "Image upload controller error: #{e.message}"
    render json: { error: 'アップロードに失敗しました' }, status: 500
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :body, :summary, :thumbnail)
  end
end
