require 'test_helper'

class PurchasesControllerTest < ActionController::TestCase
  setup do
    @price_setting = dutch_price_setting_mock
    Zaypay::PriceSetting.stubs(:new).returns @price_setting
  end

  def call_report
    get :report, { :status => "prepared", 
                  :payment_id => "419304594", 
                  :message => "This+payment+changed+state", 
                  :price_setting_id => "111111", 
                  :payalogue_id => "111111",
                  :product_id => "1"        }
  end
  context "#report" do
    context "All necessary params present" do
      should  "assign @product and @price_setting" do
        @price_setting.expects(:show_payment).returns({:payment => {:status => 'paid'}})
        call_report
        assert_not_nil assigns(:product)
        assert_not_nil assigns(:price_setting)
      end

      context "AND params of price_setting_id and product_id are correct" do
        context "AND params[:status] is equal to the status on zaypay" do
          should "update status of purchase" do
            @price_setting.expects(:show_payment).returns({:payment => {:status => 'paid'}})
            Purchase.any_instance.expects(:update_attributes).with(:status => 'paid')
            get :report, { :status => "paid", 
                          :payment_id => "419304594", 
                          :message => "This+payment+changed+state", 
                          :price_setting_id => "111111", 
                          :payalogue_id => "111111",
                          :product_id => "1"        }
          end
        end

        context "BUT the params[:status] is NOT equal to the status on zaypay" do
          should "not update status of purchase" do
            @price_setting.expects(:show_payment).returns({:payment => {:status => 'prepared'}})
            Purchase.any_instance.expects(:update_attributes).never
            get :report, { :status => "paid", 
                          :payment_id => "419304594", 
                          :message => "This+payment+changed+state", 
                          :price_setting_id => "111111", 
                          :payalogue_id => "111111",
                          :product_id => "1"        }
          end
        end
      end

      context "BUT the parameters are not correct" do
        should "NOT call show_payment NOR assign certain variables" do
          @price_setting.any_instance.expects(:show_payment).never
          get :report, { :status => "prepared", 
                        :payment_id => "419304594", 
                        :message => "This+payment+changed+state", 
                        :price_setting_id => "999999", 
                        :payalogue_id => "111111",
                        :product_id => "1"        }
          assert_nil assigns(:ps)
          assert_nil assigns(:purchase)
        end
      end
    end
  end

  should "always be succesful and return the right string" do
    get :report, { :x => "y"}
    assert_response :success
    assert_equal "*ok*", @response.body
  end
end
