require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  context "#index" do
    should "should be successful and render index" do
      get :index
      assert_response :success
      assert_template "index"
    end
    should "should assign @products" do
      get :index
      assert_not_nil assigns(:products)
    end
  end

  context "#show" do
    should "show should be a success" do
      get :show, :id => 1
      assert_response :success
      assert_template "show"
    end

    should "should assign a @product" do
      get :show, :id => 1
      assert_not_nil assigns(:product)
    end
  end
  
end
