require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  # 無効を確かめてから有効を確かめる
  test "password resets" do
    # メールの送信テスト
    get new_password_reset_path
    assert_template 'password_resets/new'
    
    # メールアドレスが無効
    post password_resets_path, params: { password_reset: { email: "" } }
    assert_not flash.empty? # 警告が表示されている？
    assert_template 'password_resets/new'
    
    # メールアドレスが有効
    post password_resets_path,
         params: { password_reset: { email: @user.email } }
    # reset_digestが保存されたか
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    # メールが送られたか
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    
    
    # パスワード再設定フォームのテスト
    user = assigns(:user) # ローカル変数userモデルにアクセス
    # メールアドレスが無効
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    
    # 無効なユーザー
    user.toggle!(:activated)#無効なユーザにする
    # 無効なユーザによる有効なトークンとメールアドレス
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    
    # メールアドレスが有効で、トークンが無効
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    
    # メールアドレスもトークンも有効
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    # メールアドレスが保持されているか
    assert_select "input[name=email][type=hidden][value=?]", user.email
    
    # 無効なパスワードとパスワード確認
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password:              "foobaz",
                            password_confirmation: "barquux" } }
    assert_select 'div#error_explanation'
    
    # パスワードが空
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password:              "",
                            password_confirmation: "" } }
    assert_select 'div#error_explanation'
    
    # 有効なパスワードとパスワード確認
    patch password_reset_path(user.reset_token),
          params: { email: user.email,
                    user: { password:              "foobaz",
                            password_confirmation: "foobaz" } }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end
end
