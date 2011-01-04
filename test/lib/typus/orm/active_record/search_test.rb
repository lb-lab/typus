require "test_helper"

class ActiveRecordTest < ActiveSupport::TestCase

  should_eventually "build_search_conditions"

  context "build_boolean_conditions" do

    should "return true" do
      expected = {'status'=>true}
      output = Page.build_boolean_conditions('status', 'true')
      assert_equal expected, output
    end

    should "return false" do
      expected = {'status'=>false}
      output = Page.build_boolean_conditions('status', 'false')
      assert_equal expected, output
    end

  end

  context "build_datetime_conditions" do

    setup do
      @tomorrow = Time.zone.now.beginning_of_day.tomorrow.to_s(:db)
    end

    should "generate the condition" do
      %w(today last_few_days last_7_days last_30_days).each do |interval|
        output = Article.build_datetime_conditions('created_at', 'today').first
        assert_equal "`articles`.created_at BETWEEN ? AND ?", output
      end
    end

    should "work for today" do
      expected = [0.days.ago.beginning_of_day.to_s(:db), @tomorrow]
      output = Article.build_datetime_conditions('created_at', 'today')[1..-1]
      assert_equal expected, output
    end

    should "work for last_few_days" do
      expected = [3.days.ago.beginning_of_day.to_s(:db), @tomorrow]
      output = Article.build_datetime_conditions('created_at', 'last_few_days')[1..-1]
      assert_equal expected, output
    end

    should "work for last_7_days" do
      expected = [6.days.ago.beginning_of_day.to_s(:db), @tomorrow]
      output = Article.build_datetime_conditions('created_at', 'last_7_days')[1..-1]
      assert_equal expected, output
    end

    should "work for last_30_days" do
      expected = [30.days.ago.beginning_of_day.to_s(:db), @tomorrow]
      output = Article.build_datetime_conditions('created_at', 'last_30_days')[1..-1]
      assert_equal expected, output
    end

  end

  should_eventually "build_date_conditions"

  context "build_string_conditions" do

    should "work" do
      expected = {'test'=>'true'}
      output = Page.build_string_conditions('test', 'true')
      assert_equal expected, output
    end

  end

  context "build_conditions" do

    should "generate conditions for id" do
      Post.stubs(:typus_defaults_for).with(:search).returns(["id"])

      params = { :search => '1' }
      expected = "`posts`.id LIKE '%1%'"

      assert_equal expected, Post.build_conditions(params).first
    end

    should "generate conditions for fields starting with equal" do
      Post.stubs(:typus_defaults_for).with(:search).returns(["=id"])

      params = { :search => '1' }
      expected = "`posts`.id LIKE '1'"

      assert_equal expected, Post.build_conditions(params).first
    end

    should "generate conditions for fields starting with ^" do
      Post.stubs(:typus_defaults_for).with(:search).returns(["^id"])

      params = { :search => '1' }
      expected = "`posts`.id LIKE '1%'"

      assert_equal expected, Post.build_conditions(params).first
    end

    should "return_sql_conditions_on_search_for_typus_user" do
      expected = case ENV["DB"]
                 when /postgresql/
                   ["TEXT(role) LIKE '%francesc%'",
                    "TEXT(last_name) LIKE '%francesc%'",
                    "TEXT(email) LIKE '%francesc%'",
                    "TEXT(first_name) LIKE '%francesc%'"]
                 else
                   ["`typus_users`.first_name LIKE '%francesc%'",
                    "`typus_users`.last_name LIKE '%francesc%'",
                    "`typus_users`.email LIKE '%francesc%'",
                    "`typus_users`.role LIKE '%francesc%'"]
                 end

      [{:search =>"francesc"}, {:search => "Francesc"}].each do |params|
        expected.each do |expect|
          assert_match expect, TypusUser.build_conditions(params).first
        end
        assert_no_match /AND/, TypusUser.build_conditions(params).first
      end
    end

    should_eventually "return_sql_conditions_on_search_and_filter_for_typus_user" do
      case ENV["DB"]
      when /mysql/
        boolean_true = "(`typus_users`.`status` = 1)"
        boolean_false = "(`typus_users`.`status` = 0)"
      else
        boolean_true = "(\"typus_users\".\"status\" = 't')"
        boolean_false = "(\"typus_users\".\"status\" = 'f')"
      end

      expected = ["`typus_users`.first_name LIKE '%francesc%'",
                  "`typus_users`.last_name LIKE '%francesc%'",
                  "`typus_users`.email LIKE '%francesc%'",
                  "`typus_users`.role LIKE '%francesc%'",
                  boolean_true]

      params = { :search => "francesc", :status => "true" }
      output = TypusUser.build_conditions(params).first
      expected.each { |e| assert_match e, output }

      assert_match /AND/, output
      assert_match /OR/, output

      params = { :search => "francesc", :status => "false" }
      output = TypusUser.build_conditions(params).first
      assert_match boolean_false, output
    end

=begin
    # FIXME
    should_eventually "return_sql_conditions_on_filtering_typus_users_by_status" do
      params = { :status => "true" }
      assert_equal { :status => true }, TypusUser.build_conditions(params).first
      params = { :status => "false" }
      assert_equal { :status => false }, TypusUser.build_conditions(params).first
    end
=end

    should "return_sql_conditions_on_filtering_typus_users_by_created_at today" do
      expected = ["`typus_users`.created_at BETWEEN ? AND ?",
                  Time.zone.now.beginning_of_day.to_s(:db),
                  Time.zone.now.beginning_of_day.tomorrow.to_s(:db)]
      params = { :created_at => "today" }

      assert_equal expected, TypusUser.build_conditions(params).first
    end

    should "return_sql_conditions_on_filtering_typus_users_by_created_at last_few_days" do
      expected = ["`typus_users`.created_at BETWEEN ? AND ?",
                  3.days.ago.beginning_of_day.to_s(:db),
                  Time.zone.now.beginning_of_day.tomorrow.to_s(:db)]
      params = { :created_at => "last_few_days" }

      assert_equal expected, TypusUser.build_conditions(params).first
    end

    should "return_sql_conditions_on_filtering_typus_users_by_created_at last_7_days" do
      expected = ["`typus_users`.created_at BETWEEN ? AND ?",
                  6.days.ago.beginning_of_day.to_s(:db),
                  Time.zone.now.beginning_of_day.tomorrow.to_s(:db)]
      params = { :created_at => "last_7_days" }

      assert_equal expected, TypusUser.build_conditions(params).first
    end

    should_eventually "return_sql_conditions_on_filtering_typus_users_by_created_at last_30_days" do
      expected = ["`typus_users`.created_at BETWEEN ? AND ?",
                  Time.zone.now.beginning_of_day.prev_month.to_s(:db),
                  Time.zone.now.beginning_of_day.tomorrow.to_s(:db)]
      params = { :created_at => "last_30_days" }

      assert_equal expected, TypusUser.build_conditions(params).first
    end

    should "return_sql_conditions_on_filtering_posts_by_published_at today" do
      expected = ["`posts`.published_at BETWEEN ? AND ?",
                  Time.zone.now.beginning_of_day.to_s(:db),
                  Time.zone.now.beginning_of_day.tomorrow.to_s(:db)]
      params = { :published_at => "today" }

      assert_equal expected, Post.build_conditions(params).first
    end

    should "return_sql_conditions_on_filtering_posts_by_string" do
      params = { :role => "admin" }
      assert_equal params, TypusUser.build_conditions(params).first
    end

  end

end