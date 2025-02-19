class UsersController < ApplicationController
  before_action :authorized, only: [:auto_login, :index, :show, :destroy]

  def index
    @users = User.all
    render json: @users, status: :ok
  end

  def show
    begin
      @user = User.find(params[:id])
      render json: @user, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: {"message": "Usuário não existe"}, status: :not_found
    end
  end

  # REGISTER
  def create
    @user = User.create(user_params)
    if @user.valid?
      token = encode_token({user_id: @user.id})
      render json: { token: token }, status: :created
    elsif @user.errors.to_h.values[0].include? 'Usuário'
      render json: { "message": @user.errors.to_h.values[0] }, status: :conflict
    else
      render json: { "message": @user.errors.to_h.values[0] }, status: :bad_request
    end
  end

  def destroy
    user_id = decoded_token[0]['data']['user_id']
    @user = User.find_by(id: user_id)
    @user.destroy!
    render nothing: true, status: :no_content
  end

  # LOGGING IN
  def login
    begin
      @user = User.find_by(email: params[:email])
    rescue ActiveRecord::RecordNotFound
      render json: {"message": "Usuário não existe"}, status: :not_found
    end

    if @user && @user.password_digest == params[:password]
      token = encode_token({user_id: @user.id})
      render json: {token: token}, status: :ok
    else
      render json: validate_login_params, status: :bad_request
    end
  end

  def auto_login
    render json: @user
  end

  private

  def user_params
    params.require(:user).permit(:displayName, :password_digest, :email, :image)
  end

  def validate_login_params
    if (params.include? 'email') == false
      { message: '"email" is required' }
    elsif (params.include? 'password') == false
      { message: '"password" is required' }
    elsif (params['email'] == '') == true
      { message: '"email" is not allowed to be empty' }
    elsif (params['password'] == '') == true
      { message: '"password" is not allowed to be empty' }
    elsif User.find_by(email: params[:email]).present? == false
      { message: 'Campos inválidos' }
    end
  end

end
