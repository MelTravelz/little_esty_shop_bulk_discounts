require 'rails_helper'

RSpec.describe InvoiceItem, type: :model do
  describe "validations" do
    it { should validate_presence_of :invoice_id }
    it { should validate_presence_of :item_id }
    it { should validate_presence_of :quantity }
    it { should validate_presence_of :unit_price }
    it { should validate_presence_of :status }
  end
  describe "relationships" do
    it { should belong_to :invoice }
    it { should belong_to :item }
    it { should have_many(:bulk_discounts).through(:item) }

    it { should define_enum_for(:status).with_values([:pending, :packaged, :shipped]) }
  end

  describe "class methods" do
    before(:each) do
      @m1 = Merchant.create!(name: 'Merchant 1')
      @c1 = Customer.create!(first_name: 'Bilbo', last_name: 'Baggins')
      @c2 = Customer.create!(first_name: 'Frodo', last_name: 'Baggins')
      @c3 = Customer.create!(first_name: 'Samwise', last_name: 'Gamgee')
      @c4 = Customer.create!(first_name: 'Aragorn', last_name: 'Elessar')
      @c5 = Customer.create!(first_name: 'Arwen', last_name: 'Undomiel')
      @c6 = Customer.create!(first_name: 'Legolas', last_name: 'Greenleaf')
      @item_1 = Item.create!(name: 'Shampoo', description: 'This washes your hair', unit_price: 10, merchant_id: @m1.id)
      @item_2 = Item.create!(name: 'Conditioner', description: 'This makes your hair shiny', unit_price: 8, merchant_id: @m1.id)
      @item_3 = Item.create!(name: 'Brush', description: 'This takes out tangles', unit_price: 5, merchant_id: @m1.id)
      @i1 = Invoice.create!(customer_id: @c1.id, status: 2)
      @i2 = Invoice.create!(customer_id: @c1.id, status: 2)
      @i3 = Invoice.create!(customer_id: @c2.id, status: 2)
      @i4 = Invoice.create!(customer_id: @c3.id, status: 2)
      @i5 = Invoice.create!(customer_id: @c4.id, status: 2)
      @ii_1 = InvoiceItem.create!(invoice_id: @i1.id, item_id: @item_1.id, quantity: 1, unit_price: 10, status: 0)
      @ii_2 = InvoiceItem.create!(invoice_id: @i1.id, item_id: @item_2.id, quantity: 1, unit_price: 8, status: 0)
      @ii_3 = InvoiceItem.create!(invoice_id: @i2.id, item_id: @item_3.id, quantity: 1, unit_price: 5, status: 2)
      @ii_4 = InvoiceItem.create!(invoice_id: @i3.id, item_id: @item_3.id, quantity: 1, unit_price: 5, status: 1)
    end

    it 'incomplete_invoices' do
      expect(InvoiceItem.incomplete_invoices).to eq([@i1, @i3])
    end
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

      @bd_basic = @merchant1.bulk_discounts.create!(title: "Basic", percentage_discount: 0.1, quantity_threshold: 5)
      @bd_super = @merchant1.bulk_discounts.create!(title: "Super", percentage_discount: 0.25, quantity_threshold: 10)
      @bd_seasonal = @merchant1.bulk_discounts.create!(title: "Seasonal", percentage_discount: 0.05, quantity_threshold: 5) 
      
      @bd_mega = @merchant2.bulk_discounts.create!(title: "Mega", percentage_discount: 0.5, quantity_threshold: 20)
    end

    # User Story 7 
    it "#applied_bulk_discount" do 
      expect(@ii_1.applied_bd_title(@merchant1)).to eq(@bd_basic)
      expect(@ii_2.applied_bd_title(@merchant1)).to eq(nil)
      expect(@ii_3.applied_bd_title(@merchant1)).to eq(@bd_super)
      expect(@ii_4.applied_bd_title(@merchant1)).to eq(nil)
    end
  end
end
