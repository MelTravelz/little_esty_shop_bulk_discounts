require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe "validations" do
    it { should validate_presence_of :status }
    it { should validate_presence_of :customer_id }
  end

  describe "relationships" do
    it { should belong_to :customer }
    it { should have_many :transactions}
    it { should have_many :invoice_items}
    it { should have_many(:items).through(:invoice_items) }
    it { should have_many(:merchants).through(:items) }
    it { should have_many(:bulk_discounts).through(:merchants) }

    it { should define_enum_for(:status).with_values([:cancelled, "in progress", :completed]) }
  end

  describe "instance methods" do
    before(:each) do 
      @merchant1 = Merchant.create!(name: 'Hair Care')
      @item_1 = Item.create!(name: "Shampoo", description: "This washes your hair", unit_price: 10, merchant_id: @merchant1.id, status: 1)
      @item_2 = Item.create!(name: "Conditioner", description: "This makes your hair shiny", unit_price: 5, merchant_id: @merchant1.id)
      @item_3 = Item.create!(name: "Butterfly Clip", description: "This holds up your hair but in a clip", unit_price: 5, merchant_id: @merchant1.id)
      
      @merchant2 = Merchant.create!(name: 'Jewelry')
      @item_4 = Item.create!(name: "Bracelet", description: "Wrist bling", unit_price: 200, merchant_id: @merchant2.id)

      @customer_1 = Customer.create!(first_name: 'Joey', last_name: 'Smith')
      @invoice_1 = Invoice.create!(customer_id: @customer_1.id, status: 2, created_at: "2012-03-27 14:54:09")
        #ii_1 (merchant1) & qualifies for 2 discounts, but will choose largest: "Basic"
      @ii_1 = InvoiceItem.create!(invoice_id: @invoice_1.id, item_id: @item_1.id, quantity: 9, unit_price: 10, status: 1)
        #ii_2 (merchant1) & qualifies for NO discount:
      @ii_2 = InvoiceItem.create!(invoice_id: @invoice_1.id, item_id: @item_2.id, quantity: 1, unit_price: 10, status: 1)
        #ii_3 (merchant1) & qualifies for all 3 discounts, but will choose largest: "Super"
      @ii_3 = InvoiceItem.create!(invoice_id: @invoice_1.id, item_id: @item_3.id, quantity: 12, unit_price: 6, status: 1)
        #ii_4 (merchant2) & will not influence `merch_discount_amount` for merchant1 & qualifies for 1 discount: "Mega"
      @ii_4 = InvoiceItem.create!(invoice_id: @invoice_1.id, item_id: @item_4.id, quantity: 40, unit_price: 1.33, status: 1)

        # This entire invoice will have NO discounts applied -> edge case: dealing with nil values
      @invoice_55 = Invoice.create!(customer_id: @customer_1.id, status: 2, created_at: "2012-03-27 14:54:08")
      @ii_55 = InvoiceItem.create!(invoice_id: @invoice_55.id, item_id: @item_2.id, quantity: 1, unit_price: 10, status: 1)

      @bd_basic = @merchant1.bulk_discounts.create!(title: "Basic", percentage_discount: 0.1, quantity_threshold: 5)
      @bd_super = @merchant1.bulk_discounts.create!(title: "Super", percentage_discount: 0.25, quantity_threshold: 10)
      @bd_seasonal = @merchant1.bulk_discounts.create!(title: "Seasonal", percentage_discount: 0.05, quantity_threshold: 5) 
      @bd_mega = @merchant2.bulk_discounts.create!(title: "Mega", percentage_discount: 0.5, quantity_threshold: 20)
    end

    # User Story 8 
    it "#total_revenue (of entire invoice)" do
      expect(@invoice_1.total_revenue).to eq(225.2)
      expect(@invoice_55.total_revenue).to eq(10)
    end

    # User Story 8 (so see total discounted revenue for entire invoice, visit admin/invoices_controller.rb & admin/invoices/show.html.erb)
    it "#total_discount_amount (of entire invoice)" do 
      expect(@invoice_1.total_discount_amount).to eq(53.6)
      expect(@invoice_55.total_discount_amount).to eq(0)
    end

    # User Story 6
    it "#merch_total_revenue (for only 1 merchant on the invoice)" do
      expect(@invoice_1.merch_total_revenue(@merchant1)).to eq(172.0)
      expect(@invoice_55.merch_total_revenue(@merchant1)).to eq(10.0)
    end

    # User Story 6 (so see total discounted revenue for a merchant, visit invoices_controller.rb & invoices/show.html.erb)
    it "#merch_discount_amount (for only 1 merchant on the invoice)" do
      expect(@invoice_1.merch_discount_amount(@merchant1)).to eq(27)
      expect(@invoice_55.merch_discount_amount(@merchant1)).to eq(0)
    end
  end
end
