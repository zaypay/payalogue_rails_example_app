class PurchasesController < ApplicationController
  def report
    if all_necessary_params_present? && price_setting_ids_are_equal? && statuses_are_equal?
      @purchase = Purchase.find_or_create_by_zaypay_payment_id_and_product_id(params[:payment_id],params[:product_id] )
      @purchase.update_attributes(:status => params[:status])
    end
    render :layout => false, :text => "*ok*"
  end

  private
  def all_necessary_params_present?
    params[:payment_id].present? && params[:price_setting_id].present? && params[:product_id]
  end

  def statuses_are_equal?
    @price_setting = Zaypay::PriceSetting.new(params[:price_setting_id].to_i)
    @price_setting.show_payment(params[:payment_id])[:payment][:status] == params[:status] if @price_setting
  end

  def price_setting_ids_are_equal?
    @product = Product.find(params[:product_id])
    params[:price_setting_id] == @product.price_setting_id.to_s if @product
  end
end
