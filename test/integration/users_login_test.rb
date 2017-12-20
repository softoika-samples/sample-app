require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end
  
  # 間違った情報でログインを試みたときに、フラッシュがページ遷移で消えないバグのテスト
  test "login with invalid information" do
    # ログイン用のパスを開く
    get login_path
    # 新しいセッションのフォームが正しく表示されたことを確認する
    assert_template 'sessions/new'
    # わざと無効なparamsハッシュを使ってセッション用パスにpostする
    post login_path, params: {session: {email: "", password: ""}}
    # 新しいセッションのフォームが再度表示され、
    assert_template 'sessions/new'
    # フラッシュメッセージが追加されることを確認する
    assert_not flash.empty?
    # 別のページに一旦移動する
    get root_path
    # 移動先のページでフラッシュメッセージが表示されていないことを確認する
    assert flash.empty?
  end
  
  test "login with valid information followed by logout" do
    # ログイン用のパスを開く
    get login_path
    # セッション用パスに有効な情報をpostする
    post login_path, params: {session: {email: @user.email, password: "password"}}
    assert is_logged_in? # ログイン状態か
    # リダイレクト先がログインユーザのものか確認
    assert_redirected_to @user
    # 実際にページを移動する
    follow_redirect!
    # ログイン用リンクが表示されなくなったことを確認する
    assert_select "a[href=?]", login_path, count: 0
    # ログアウト用リンクが表示されていることを確認する
    assert_select "a[href=?]", logout_path
    # プロフィール用リンクが表示されていることを確認する
    assert_select "a[href=?]", user_path(@user)
    
    delete logout_path # deleteリクエストでログアウト
    assert_not is_logged_in? # ログイン状態でないか
    assert_redirected_to root_url # ログアウト後ルートにリダイレクトしているか
    # 2番目のウィンドウでログアウトをクリックするユーザーをシミュレートする
    delete logout_path
    
    follow_redirect!
    assert_select "a[href=?]", login_path # ログインリンクが表示されているか
    assert_select "a[href=?]", logout_path,      count: 0 # ログアウトリンクが消えているか
    assert_select "a[href=?]", user_path(@user), count: 0 # プロフィールリンクが消えているか
  end
  
  test "login with remembering" do
    log_in_as(@user, remember_me: '1')
    assert_not_empty cookies['remember_token']
  end

  test "login without remembering" do
    # クッキーを保存してログイン
    log_in_as(@user, remember_me: '1')
    delete logout_path
    # クッキーを削除してログイン
    log_in_as(@user, remember_me: '0')
    assert_empty cookies['remember_token']
  end
end
