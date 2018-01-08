require 'test_helper'

class UsersProfileTest < ActionDispatch::IntegrationTest
  include ApplicationHelper

  def setup
    @user = users(:michael)
  end

  test "profile display" do
    # ユーザページにアクセス
    get user_path(@user)
    # アクセスできた？
    assert_template 'users/show'
    # タイトルは正しいか
    assert_select 'title', full_title(@user.name)
    # ユーザ名は表示されているか
    assert_select 'h1', text: @user.name
    # 画像は表示されているか
    assert_select 'h1>img.gravatar'
    # マイクロポストの数は適切か
    assert_match @user.microposts.count.to_s, response.body
    # ページネーションされているか
    assert_select 'div.pagination'
    # それぞれのマイクロポストにテキスト内容がそんざいするか
    @user.microposts.paginate(page: 1).each do |micropost|
      assert_match micropost.content, response.body
    end
  end
end
