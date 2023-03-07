require 'rails_helper'

RSpec.describe 'merchant/:merchant_id/invoices/:invoice_id', type: :feature do
  context "as a merchant, when I visit my merchant invoice show page" do
    before :each do
      @merchant1 = Merchant.create!(name: 'Hair Care')
        @item_1 = Item.create!(name: "Shampoo", description: "This washes your hair", unit_price: 10, merchant_id: @merchant1.id, status: 1)
        @item_2 = Item.create!(name: "Conditioner", description: "This makes your hair shiny", unit_price: 5, merchant_id: @merchant1.id)
        @item_3 = Item.create!(name: "Butterfly Clip", description: "This holds up your hair but in a clip", unit_price: 5, merchant_id: @merchant1.id)
        
      @merchant2 = Merchant.create!(name: 'Jewelry')
        @item_4 = Item.create!(name: "Bracelet", description: "Wrist bling", unit_price: 200, merchant_id: @merchant2.id)

      @customer_1 = Customer.create!(first_name: 'Joey', last_name: 'Smith')
      @customer_2 = Customer.create!(first_name: 'Jane', last_name: 'Doe')

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

      visit merchant_invoice_path(@merchant1, @invoice_1)
      # visit "/merchant/#{@merchant1.id}/invoices/#{@invoice_1.id}"
    end

    it "shows merchant information" do
      expect(page).to have_content("Merchant Name: #{@merchant1.name}")
      expect(page).to have_content("Merchant ID: #{@merchant1.id}")
    end
    it "shows the invoice information" do
      expect(page).to have_content(@invoice_1.id)
      expect(page).to have_content(@invoice_1.status)
      expect(page).to have_content(@invoice_1.created_at.strftime("%A, %B %-d, %Y"))
    end

    it "shows the customer information" do
      expect(page).to have_content(@customer_1.first_name)
      expect(page).to have_content(@customer_1.last_name)

      expect(page).to_not have_content(@customer_2.last_name)
    end

    it "shows the item information" do
      expect(page).to have_content(@item_1.name)
      expect(page).to have_content(@ii_1.quantity)
      expect(page).to have_content(@ii_1.unit_price)
    end

      # I updated this test to clearly state what was being returned: 
    it "shows the total revenue for this invoice" do
      expect(page).to have_content("Revenue for Entire Invoice: $225.20")
    end

    it "shows a select field to update the invoice status" do
      within("#the-status-#{@ii_1.id}") do
        page.select("cancelled")
        click_button("Update Invoice")

        expect(page).to have_content("cancelled")
      end

      within("#current-invoice-status") do
        expect(page).to_not have_content("in progress")
      end
    end

    # User Story 6 (#merch_total_revenue(merchant))
    it "shows the total revenue for this invoice (NOT including bulk discounts)" do
      expect(page).to have_content("Total Revenue for Merchant on this Invoice: $172.00")
    end

    # User Story 6 (#merch_discount_amount(merchant))
    it "I see the total DISCOUNTED revenue for my merchant from this invoice" do
      expect(page).to have_content("Total Discounted Revenue: $145.00")
    end

    # User Story 7 (#applied_bulk_discount(merchant))
    it "next to each invoice item, I see a link to the show page for the bulk discount that was applied (if any)" do 
      expect(page).to have_content("See Applied Discount")
      expect(page).to have_content("Merchant ID")
      
      within "#inv_item-#{@ii_1.id}" do
        expect(page).to have_content(@merchant1.id)
        expect(page).to have_link("Basic", href: merchant_bulk_discount_path(@merchant1, @bd_basic))
        # expect(page).to have_link("Basic", href: "/merchant/#{@merchant1.id}/bulk_discounts/#{@bd_basic.id}")
      end

      within "#inv_item-#{@ii_2.id}" do
        expect(page).to have_content(@merchant1.id)
        expect(page).to have_content("No Discount")
      end


      within "#inv_item-#{@ii_3.id}" do
        expect(page).to have_content(@merchant1.id)
        expect(page).to have_link("Super", href: merchant_bulk_discount_path(@merchant1, @bd_super))
        # expect(page).to have_link("Super", href: "/merchant/#{@merchant1.id}/bulk_discounts/#{@bd_super.id}")
      end

      within "#inv_item-#{@ii_4.id}" do
        expect(page).to have_content(@merchant2.id)
        expect(page).to have_content("No Discount")
      end
    end

    # User Story 7 (#applied_bulk_discount(merchant))
    it "I click on that link & am taken to the bulk discount show page" do 
      within "#inv_item-#{@ii_1.id}" do
        click_link("Basic")
      end

      expect(current_path).to eq(merchant_bulk_discount_path(@merchant1, @bd_basic))
      # expect(current_path).to eq("/merchant/#{@merchant1.id}/bulk_discounts/#{@bd_basic.id}")

      expect(page).to have_content("Details for Bulk Discount: #{@bd_basic.title}")
      expect(page).to have_content("Precentage Discount (as a decimal): #{@bd_basic.percentage_discount}")
      expect(page).to have_content("Quantity Threshold (for same item): #{@bd_basic.quantity_threshold}")
    end
  end
end
