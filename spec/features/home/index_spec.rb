require 'rails_helper'

RSpec.describe '/', type: :feature do
  before(:each)do
    visit "/"
  end 

  it "should display project title & links to admin pages" do
    expect(page).to have_content("Project: Little Esty Shop BULK DISCOUNTS")
    expect(page).to have_link("Admin Dashboard", href: admin_dashboard_index_path)
    expect(page).to have_link("Admin Merchants Index Page", href: admin_merchants_path)
    expect(page).to have_link("Admin Invoices Index Page", href: admin_invoices_path)
  end

  it "when I click on 'admin dashboard' link, I'm taken to that page & see a header indicating the admin dashboard" do
    click_link("Admin Dashboard")

    expect(current_path).to eq(admin_dashboard_index_path)

    expect(page).to have_content("Admin Dashboard")
  end

end