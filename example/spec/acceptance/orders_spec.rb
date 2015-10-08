require 'acceptance_helper'

resource "Orders" do
  header "Accept", "application/json"
  header "Content-Type", "application/json"

  let(:order) { Order.create(:name => "Old Name", :paid => true, :email => "email@example.com") }

  get "/orders" do
    parameter :page, "Current page of orders", type: :integer, format: :int32

    let(:page) { 1 }

    before do
      2.times do |i|
        Order.create(:name => "Order #{i}", :email => "email#{i}@example.com", :paid => true)
      end
    end

    example_request "Getting a list of orders" do
      expect(response_body).to eq(Order.all.to_json)
      expect(status).to eq(200)
    end
  end

  head "/orders" do
    example_request "Getting the headers" do
      expect(response_headers["Cache-Control"]).to eq("no-cache")
    end
  end

  post "/orders" do
    parameter :name, "Name of order", :required => true, :scope => :order, type: :string
    parameter :paid, "If the order has been paid for", :required => true, :scope => :order, type: :boolean
    parameter :email, "Email of user that placed the order", :scope => :order, type: :string

    response_field :name, "Name of order", :scope => :order, "Type" => "String"
    response_field :paid, "If the order has been paid for", :scope => :order, "Type" => "Boolean"
    response_field :email, "Email of user that placed the order", :scope => :order, "Type" => "String"

    let(:name) { "Order 1" }
    let(:paid) { true }
    let(:email) { "email@example.com" }

    let(:raw_post) { params.to_json }

    example_request "Creating an order" do
      explanation "First, create an order, then make a later request to get it back"

      order = JSON.parse(response_body)
      expect(order.except("id", "created_at", "updated_at")).to eq({
        "name" => name,
        "paid" => paid,
        "email" => email,
      })
      expect(status).to eq(201)

      client.get(URI.parse(response_headers["location"]).path, {}, headers)
      expect(status).to eq(200)
    end
  end

  get "/orders/:id" do
    let(:id) { order.id }

    parameter :id, 'The id', in: :path, type: :integer, format: :int32

    example_request "Getting a specific order" do
      expect(response_body).to eq(order.to_json)
      expect(status).to eq(200)
    end
  end

  put "/orders/:id" do
    parameter :id, 'The id', in: :path, type: :integer, format: :int32
    parameter :name, "Name of order", :scope => :order, type: :string
    parameter :paid, "If the order has been paid for", :scope => :order, type: :boolean
    parameter :email, "Email of user that placed the order", :scope => :order, type: :string

    let(:id) { order.id }
    let(:name) { "Updated Name" }

    let(:raw_post) { params.to_json }

    example_request "Updating an order" do
      expect(status).to eq(204)
    end
  end

  delete "/orders/:id" do
    let(:id) { order.id }

    parameter :id, 'The id', in: :path, type: :integer, format: :int32
    example_request "Deleting an order" do
      expect(status).to eq(204)
    end
  end
end
