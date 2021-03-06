require File.expand_path('../../../test_helper', __FILE__)

class User
  class RecordNotFound < StandardError; end
  def self.session_key
    :user_id
  end
end

class ControllerTest < Test::Unit::TestCase
  include SimplestAuth::Controller

  context "the Controller module" do
    should "know if a user is authorized" do
      stubs(:logged_in?).returns(true)
      assert authorized?
    end

    should "redirect to a new session if access is denied" do
      stubs(:store_location)
      expects(:redirect_to).with("")
      stubs(:new_session_url).returns("")
      stubs(:flash).returns({})
      access_denied
    end

    should "set the error flash if access is denied" do
      stubs(:store_location)
      stubs(:redirect_to).with("")
      stubs(:new_session_url).returns("")
      stubs(:login_message).returns("blah")
      flash_stub = {}
      stubs(:flash).returns(flash_stub)
      access_denied
      assert_equal "blah", flash_stub[:error]
    end

    should "store the location of the desired page before redirecting" do
      expects(:store_location)
      stubs(:redirect_to)
      stubs(:new_session_url)
      stubs(:flash).returns({})
      access_denied
    end

    should "store the location of the current request to session" do
      expects(:session).returns({})
      stubs(:request).returns(stub(:request_uri => ''))
      store_location
    end

    should "redirect back to the stored uri" do
      stubs(:session).returns({:return_to => 'somewhere'})
      expects(:redirect_to).with('somewhere')
      redirect_back_or_default('')
    end

    should "redirect to a default location if the session url is nil" do
      stubs(:session).returns({:return_to => nil})
      expects(:redirect_to).with('default')
      redirect_back_or_default('default')
    end

    should "clear the session stored url after redirect" do
      session = {:return_to => 'somewhere'}
      stubs(:session).returns(session)
      stubs(:redirect_to)
      redirect_back_or_default('')
      assert_nil session[:return_to]
    end

    should "know if login is required from authorized method" do
      stubs(:authorized?).returns(true)
      assert login_required
    end

    should "consider access denied if login is required and not authorized" do
      stubs(:authorized?).returns(false)
      expects(:access_denied)
      login_required
    end

    should "know if a user is logged in" do
      stubs(:current_user_id).returns(1)
      assert logged_in?
    end

    should "know if a user is not logged in" do
      stubs(:current_user_id).returns(nil)
      assert_equal false, logged_in?
    end

    should "#get the current user" do
      user_stub = stub
      user_stub.stubs(:get).with(1).returns("user")

      stubs(:current_user_id).returns(1)
      stubs(:user_class).returns(user_stub)

      assert_equal "user", current_user
    end

    should "#find the current user when #get fails" do
      user = mock do |m|
        m.expects(:where).with(:id => '1').returns(m)
        m.expects(:first).returns("user")
      end
      stubs(:current_user_id).returns('1')
      stubs(:user_class).returns(user)

      assert_equal "user", current_user
    end

    should "clear session and return nil for the current user if it doesn't exist" do
      user = mock do |m|
        m.expects(:where).with(:id => '1').returns(m)
        m.expects(:first).returns(nil)
      end
      stubs(:current_user_id).with().returns('1')
      stubs(:user_class).returns(user)
      stubs(:clear_session)

      assert_nil current_user
    end

    should "be able to clear its session variables" do
      expects(:session).with().returns(mock() {|m| m.expects(:[]=).with(:user_id, nil) })
      clear_session
    end

    should "allow assigning to the current user" do
      stubs(:session).returns({})
      user = mock(:id => 1)
      self.current_user = user
    end

    should "save the current user to avoid lookup" do
      stubs(:session).returns({})
      user = stub(:id => 1)
      self.current_user = user
      assert_equal user, current_user
    end

    should "know the current user id from session" do
      stubs(:session).returns({:user_id => 1})
      assert_equal 1, current_user_id
    end

    should "have a default login error message" do
      assert_equal "Login or Registration Required", login_message
    end

    should "return the current_user, repeatedly" do
      user = mock do |m|
        m.expects(:where).with(:id => 1).returns(m)
        m.expects(:first).returns("user")
      end
      stubs(:user_class).returns(user)
      stubs(:current_user_id).returns(1)

      assert_equal "user", current_user
    end

    should "adapt the session key for the user class" do
      stubs(:user_class).returns(mock(:session_key => :user_id))
      assert_equal :user_id, session_key
    end
  end

end