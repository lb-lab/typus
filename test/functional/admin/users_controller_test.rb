require "test_helper"

=begin

  What's being tested here?

    - HasManyThrough

=end

class Admin::UsersControllerTest < ActionController::TestCase

  setup do
    @typus_user = Factory(:typus_user)
    @request.session[:typus_user_id] = @typus_user.id

    @project = Factory(:project)
    @user = @project.user
  end

  should_eventually "be able to destroy items" do
    get :destroy, { :id => @user.id, :method => :delete }

    assert_response :redirect
    assert_equal "User successfully removed.", flash[:notice]
    assert_redirected_to :action => :index
  end

  context "index" do

    setup do
      @user_1 = Factory(:user)
      @project_1 = Factory(:project, :user => @user_1)
      Factory(:project, :user => @user_1)
      @project_2 = Factory(:project)
    end

    should "filter by projects" do
      get :index, { 'projects' => @project_1.id }
      assert_equal [@user_1], assigns(:items)

      get :index, { 'projects' => @project_2.id }
      assert_not_equal [@user_1], assigns(:items)
    end

  end

  context "unrelate collaborators" do

    ##
    # We have a project with many collaborators (which are users)
    #

    setup do
      @project = Factory(:project)
      @user = Factory(:user)
      @project.collaborators << @user

      @request.env['HTTP_REFERER'] = "/admin/projects/edit/#{@project.id}"
    end

    should_eventually "work" do
      assert_difference('@project.collaborators.count', -1) do
        post :unrelate, { :id => @user.id,
                          :resource => 'Project',
                          :resource_id => @project.id,
                          :association_name => "collaborators" }
      end
      assert_response :redirect
      assert_redirected_to @request.env['HTTP_REFERER']
      assert_equal "Project successfully updated.", flash[:notice]
    end

  end

end