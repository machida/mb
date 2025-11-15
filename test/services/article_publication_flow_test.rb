require "test_helper"

class ArticlePublicationFlowTest < ActiveSupport::TestCase
  def setup
    Article.destroy_all
    Admin.destroy_all

    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )

    @article = Article.create!(
      title: "Sample",
      body: "Body",
      summary: "Summary",
      author: @admin.user_id
    )
  end

  test "applies draft state and destinations when committing as draft" do
    flow = ArticlePublicationFlow.new("下書き保存")
    flow.apply_state(@article)

    assert @article.draft?
    assert_equal "/admin/articles", flow.redirect_path(@article)
    assert_equal "下書きを保存しました。", flow.notice_message(@article)
  end

  test "applies publish state and destinations when committing as publish" do
    flow = ArticlePublicationFlow.new("公開")
    flow.apply_state(@article)

    refute @article.draft?
    assert_equal "/article/#{@article.id}", flow.redirect_path(@article)
    assert_equal "記事を公開しました。", flow.notice_message(@article)
  end

  test "keeps article state when action is unknown" do
    @article.update!(draft: true)
    flow = ArticlePublicationFlow.new(nil)

    flow.apply_state(@article)

    assert @article.draft?
    assert_equal "/admin/articles", flow.redirect_path(@article)
  end
end
