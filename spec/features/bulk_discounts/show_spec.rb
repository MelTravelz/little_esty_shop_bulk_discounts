require 'rails_helper'

RSpec.describe 'merchant/:merchant_id/bulk_discounts/:bulk_discount_id', type: :feature do
  context "as a merchant, when I visit the bulk discounts show page" do
    before :each do 
      @merchant1 = Merchant.create!(name: 'The Frisbee Store')
      @merchant2 = Merchant.create!(name: 'Jewelry')

      @bd_basic = @merchant1.bulk_discounts.create!(title: "Basic", percentage_discount: 0.1, quantity_threshold: 2)
      @bd_mega = @merchant2.bulk_discounts.create!(title: "Mega", percentage_discount: 0.5, quantity_threshold: 20)

      visit merchant_bulk_discount_path(@merchant1, @bd_basic)
      # visit "/merchant/#{@merchant1.id}/bulk_discounts/#{@bd_basic.id}"
    end
  
    # User Story 4
    it "I see the bulk discount's quantity threshold and percentage discount" do 
      expect(page).to have_content("Details for Bulk Discount: #{@bd_basic.title}")
      expect(page).to have_content("Precentage Discount (as a decimal): #{@bd_basic.percentage_discount}")
      expect(page).to have_content("Quantity Threshold (for same item): #{@bd_basic.quantity_threshold}")

      expect(page).to_not have_content("#{@bd_mega.title}")
    end

    # EXTRA
    it "I see a link to return to the merchants bulk discount index page" do
      expect(page).to have_link("See All Discounts for Merchant")

      click_link("See All Discounts for Merchant", href: merchant_bulk_discounts_path(@merchant1))

      expect(current_path).to eq(merchant_bulk_discounts_path(@merchant1))
      expect(page).to have_content("All Available Bulk Discounts")
    end

    # User Story 5
    it "I see a link to edit the bulk discount" do
      expect(page).to have_link("Edit this Bulk Discount", href: edit_merchant_bulk_discount_path(@merchant1, @bd_basic))
      # expect(page).to have_link("Edit this Bulk Discount", href: "/merchant/#{@merchant1.id}/bulk_discounts/#{@bd_basic.id}/edit")
    end

    # User Story 5
    it "when I click on this link & am taken to that bulk discount's edit page" do
      click_link("Edit this Bulk Discount")
      expect(current_path).to eq(edit_merchant_bulk_discount_path(@merchant1, @bd_basic))
    end
  end
end