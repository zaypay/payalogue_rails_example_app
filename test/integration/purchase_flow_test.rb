require 'test_helper'

class PurchaseFlowTest < ActionDispatch::IntegrationTest
  context "A customer navigates to a product, makes a payment" do
    setup do
      @product = products(:one)
      @price_setting = dutch_price_setting_mock
      Zaypay::PriceSetting.stubs(:new).returns @price_setting
    end
    should "create a purchase and update its status" do
      # navigate to home page
      get root_path
      assert_response :success
      assert_select "#products_index_button"
      # navigate to products index
      get products_path
      assert_response :success
      assert_select "tr#product_#{@product.id}"
      # navigate to product page, should have a button
      get product_path(@product)
      assert_response :success
      assert_match "<a href=\"https://secure.zaypay.com/pay/#{@product.payalogue_id}?", @response.body

      # End-user submits language, country and payment_method in the payalogue, hence creating a payment on the Zaypay-platform
      # As a result, zaypay sends a get request with params to the report-url
      # This should create a Purchase object with the correct data
      assert_difference "Purchase.count" do
        @price_setting.expects(:show_payment).returns({:payment => {:status => 'prepared'}})
        get report_path, {:price_setting_id => @product.price_setting_id,
                          :status => 'prepared',
                          :product_id => @product.id,
                          :payment_id => '123456',
                          :message => 'This+payment+changed+state',
                          :payalogue_id => @product.payalogue_id}
        assert_response :success
        assert_equal 123456,      Purchase.last.zaypay_payment_id
        assert_equal @product.id, Purchase.last.product_id
        assert_equal 'prepared',  Purchase.last.status
      end

      # End-user is in the process of making the payment, hence zaypay sends us a report with status in_progress
      assert_no_difference "Purchase.count" do
        @price_setting.expects(:show_payment).returns({:payment => {:status => 'in_progress'}})
        get report_path, {:price_setting_id => @product.price_setting_id,
                          :status => 'in_progress',
                          :product_id => @product.id,
                          :payment_id => '123456',
                          :message => 'This+payment+changed+state',
                          :payalogue_id => @product.payalogue_id} 
        assert_response :success
        assert_equal 123456,      Purchase.last.zaypay_payment_id
        assert_equal @product.id, Purchase.last.product_id
        assert_equal 'in_progress',  Purchase.last.status
      end

      # End-user has made the payment, hence zaypay sends us a report with status is paid
      assert_no_difference "Purchase.count" do
        @price_setting.expects(:show_payment).returns({:payment => {:status => 'paid'}})
        get report_path, {:price_setting_id => @product.price_setting_id,
                          :status => 'paid',
                          :product_id => @product.id,
                          :payment_id => '123456',
                          :message => 'This+payment+changed+state',
                          :payalogue_id => @product.payalogue_id} 
        assert_response :success
        assert_equal 123456,      Purchase.last.zaypay_payment_id
        assert_equal @product.id, Purchase.last.product_id
        assert_equal 'paid',  Purchase.last.status
      end
    end
  end

  # Since anyone can send a get-request to our report-url,
  # we have to perform a check to verify that the status of payment we receive in params corresponds to the status of the payment on the Zaypay platform
  # In case that is not the case, we should not update our purchase record
  context "A malicious request comes in that tries to alter the payment status" do
    setup do
       @purchase = purchases(:two)
       @product = products(:two)
       @price_setting = dutch_price_setting_mock
       Zaypay::PriceSetting.stubs(:new).returns @price_setting
     end

    should "not update the status of our purchase record" do
      Purchase.stubs(:find_or_create_by_zaypay_payment_id_and_product_id).returns @purchase
      # the status of the payment on zaypay is 'prepared'
      @price_setting.expects(:show_payment).returns({:payment => {:status => 'prepared'}})
      assert_no_difference "Purchase.count" do
        # a request that tries to set the status to 'paid'
        get report_path, {:price_setting_id => @product.price_setting_id,
                          :status => 'paid',
                          :product_id => @product.id,
                          :payment_id => '123456',
                          :message => 'This+payment+changed+state',
                          :payalogue_id => @product.payalogue_id} 
        assert_response :success
        assert_equal 2,          @purchase.zaypay_payment_id
        assert_equal 2,          @purchase.product_id
        assert_equal 'prepared', @purchase.status
      end
    end
  end
end
