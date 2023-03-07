class BulkDiscountsController < ApplicationController
  before_action :nager_info, only: [:index]
  before_action :find_merchant, only: [:index, :new, :create]
  before_action :find_merchant_and_bulk_discount, only: [:show, :edit, :update, :destroy]

  def nager_info
    @nager_holidays = NagerFacade.next_3_holidays.info
    # This could also work but maybe NOT with an OpenStruct object:
    # @nager_holidays = NagerFacade.next_3_holidays.first(3)
  end

  def index
    @bulk_discounts = @merchant.bulk_discounts
  end

  def show
  end

  def new
  end

  def create
    new_params = bulk_discount_params
    new_params[:percentage_discount] = (new_params[:percentage_discount].to_f/100)
    new_bd = @merchant.bulk_discounts.new(new_params)
   
    if new_bd.save
      flash.notice = "Your new bulk discount was successfully created!"
      redirect_to merchant_bulk_discounts_path(@merchant)
    else
      flash.notice = new_bd.errors.full_messages.join(", ")
      redirect_to new_merchant_bulk_discount_path(@merchant)
      # render :new <- won't carry the merchant_id
    end
  end

  def edit
    @discount_number = ((@bulk_discount.percentage_discount)*100).to_i
  end

  def update
    new_params = bulk_discount_params
    new_params[:percentage_discount] = (new_params[:percentage_discount].to_f/100)
 
    @bulk_discount.update!(new_params)
    flash.notice = "Your bulk discount was successfully edited!"
    redirect_to merchant_bulk_discount_path(@merchant, @bulk_discount)
    #   # Not sure if this is necessary since all fields are required & it'll never allow errors??
    #   # Could add if conditional if it was needed
    #   flash.notice = new_bd.errors.full_messages.join(", ")
    #   redirect_to edit_merchant_bulk_discount_path(@merchant, @bulk_discount)
  end

  def destroy
    @bulk_discount.destroy
    redirect_to merchant_bulk_discounts_path(@merchant)
  end

  private
  def find_merchant
    @merchant = Merchant.find(params[:merchant_id])
  end

  def find_merchant_and_bulk_discount
    @merchant = Merchant.find(params[:merchant_id])
    @bulk_discount = @merchant.bulk_discounts.find(params[:id])
  end

  def bulk_discount_params
    params.permit(:title, :percentage_discount, :quantity_threshold)
  end
end