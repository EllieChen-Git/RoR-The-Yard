class MilkshakesController < ApplicationController
    before_action :authenticate_user!
    # before_action :set_milkshake, only: [:show, :edit, :update]
    before_action :set_milkshake, only: [:show]
    before_action :set_user_milkshake, only: [:edit, :update]

    def index
        if params[:search] && !params[:search].empty?
            @milkshakes = Milkshake.where(name: params[:search])
        else
            @milkshakes = Milkshake.all
        end
    end

    def show
        session = Stripe::Checkout::Session.create(
            payment_method_types: ["card"],
            customer_email: current_user.email,
            line_items: [
                {
                    name: @milkshake.name,  #coz we set up before action
                    description: @milkshake.description,
                    amount: @milkshake.price,
                    currency: "aud",
                    quantity: 1
                }
            ],
            payment_intent_data: {
                metadata: {
                    user_id: current_user.id,
                    milkshake_id: @milkshake.id  #we can mark it as purchased once it's bought
                }
            },
            success_url: "#{root_url}payment/success?userId=#{current_user.id}&milkshakeId=#{@milkshake.id}", #{root_url}: rails helper method
            cancel_url: "#{root_url}milkshakes/#{@milkshake.id}"
        )

        @session_id = session.id
        @public_key = Rails.application.credentials.dig(:stripe, :public_key)

        #Stripe module, Checkout module, 
    end

    def new
        @milkshake = Milkshake.new
        @ingredients = Ingredient.all
    end

    def create
        @milkshake = current_user.milkshakes.create(milkshake_params)
        
        if @milkshake.errors.any?
            @ingredients = Ingredient.all
            render "new"
        else 
            redirect_to milkshake_path(@milkshake)
        end
    end

    def edit  #the update form
        @ingredients = Ingredient.all
    end

    def update #the action to update
        if @milkshake.update(milkshake_params)
            redirect_to milkshake_path(params[:id])    #if update successfully
        else
            @ingredients = Ingredient.all              #if doesn't udpate: regrab ingredients
            render "edit"
        end
    end

    private #methods can only be used in this controller(not other controllers)

    def milkshake_params
        params.require(:milkshake).permit(:name, :description, :price, :pic, ingredient_ids: [])
    end

    def set_milkshake
        @milkshake = Milkshake.find(params[:id])
    end

    def set_user_milkshake
        @milkshake = current_user.milkshakes.find_by_id(params[:id])  
        #looking for current users' milkshakes only
        # we don't have to set the variable 'current_user' here coz Devise gem has declared it for us

        if @milkshake == nil  #if couldn't find the milkshake
            redirect_to milkshakes_path
        end
    end

end

