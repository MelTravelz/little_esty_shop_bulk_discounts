class Invoice < ApplicationRecord
  validates_presence_of :status,
                        :customer_id

  belongs_to :customer
  has_many :transactions
  has_many :invoice_items
  has_many :items, through: :invoice_items
  has_many :merchants, through: :items
  has_many :bulk_discounts, through: :merchants

  enum status: [:cancelled, 'in progress', :completed]

  def total_revenue
    invoice_items.sum("unit_price * quantity")
  end

  def total_discount_amount
    # invoice_items.joins(item: {merchant: :bulk_discounts}) <- this also works
    query1 = invoice_items.joins(:bulk_discounts)
      .select("invoice_items.*, MAX((invoice_items.quantity * invoice_items.unit_price) * bulk_discounts.percentage_discount) AS discount_amount")
      .where("invoice_items.quantity >= bulk_discounts.quantity_threshold")
      .group(:id)

    query2 = InvoiceItem.from(query1, :query1)
      .select("SUM(query1.discount_amount) AS total_discount_amount")
      .take

    query2.total_discount_amount
    # above is using Subquery, below is using Ruby: 
    # .sum(&:discount_amount)
  end

  def merch_total_revenue(merchant)
    invoice_items.joins(:bulk_discounts)
    .where("bulk_discounts.merchant_id = ?", merchant.id)
    .distinct
    .sum("invoice_items.unit_price * invoice_items.quantity")
  end

  def merch_discount_amount(merchant)
    query1 = invoice_items.joins(:bulk_discounts)
    .select("invoice_items.*, MAX((invoice_items.quantity * invoice_items.unit_price) * bulk_discounts.percentage_discount) AS discount_amount")
    .where("bulk_discounts.merchant_id = ?", merchant.id)
    .where("invoice_items.quantity >= bulk_discounts.quantity_threshold")
    .group(:id)

    query2 = InvoiceItem.from(query1, :query1)
    .select("SUM(query1.discount_amount) AS merch_discount_amount")
    .take

    query2.merch_discount_amount
  end
end
