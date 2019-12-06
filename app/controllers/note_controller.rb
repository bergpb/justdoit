get '/' do
  if user_signed_in?
    @not_completed_notes = current_user.notes.where(active: true).length
    @completed_notes = current_user.notes.where(active: false).length
    @username = current_user.username if current_user
  end
  slim :"main/index"
end

route :get, :post, '/new' do
  method = request.env["REQUEST_METHOD"]
  if method == "GET"
    if user_signed_in?
      slim :"note/new"
    else
      flash[:warning] = 'Please login.'
      redirect '/login'
    end
  elsif method == "POST"
    @note = Note.new(title: params[:title],
                     description: params[:description],
                     user_id: current_user.id)
    if @note.valid?
      @note.save
      flash[:success] = 'Note saved.'
      redirect '/list'
    else
      @errors = @note.errors
      slim :"note/new"
    end
  end
end

get '/list' do
  if user_signed_in?
    @notes = current_user.notes.order(created_at: :desc)
    @notes.each do |note|
      note.description = note.description.gsub(/\r/, '</br>')
    end
    slim :"note/list"
  else
    flash[:warning] = 'Please login.'
    redirect '/login'
  end
end

get '/show/:id' do
  if user_signed_in?
    @note = current_user.notes.find_by_id(params[:id])
    if @note.nil?
      flash[:warning] = "Note don't exists."
      redirect '/list'
    else
      slim :"note/show"
    end
  else
    flash[:warning] = 'Please login.'
    redirect '/login'
  end
end

route :get, :post, '/edit/:id' do
  method = request.env["REQUEST_METHOD"]
  if method == "GET"
    if user_signed_in?
      @note = current_user.notes.find_by_id(params[:id])
      unless @note.nil?
        slim :"note/edit"
      else
        flash[:warning] = "Note don't exists."
        redirect '/list'
      end
    else
      flash[:warning] = 'Please login.'
      redirect '/login'
    end
  elsif method == "POST"
    @note = current_user.notes.find_by_id(params[:id])
  	@note.update(title: params[:title],
                 description: params[:description],
                 active: params[:active] == "on" ? true : false)
  	if @note.valid?
  	  @note.save
  	  flash[:success] = 'Note updated.'
  	  redirect '/list'
    else
      @errors = @note.errors
  	  slim :"note/edit"
  	end
  end
end

get '/complete/:id' do
  if user_signed_in?
    @note = current_user.notes.find_by_id(params[:id])
  	@note.update(active: false)
  	if @note.save
  	  flash[:success] = 'Note updated.'
  	  redirect '/list'
  	else
  	   flash[:danger] = 'Fail to update note.'
  	   slim :edit
  	end
  else
    flash[:warning] = 'Please login.'
    redirect '/login'
  end
end

get '/delete/:id' do
  if user_signed_in?
    note = current_user.notes.find_by_id(params[:id])
    if !note.nil?
      note.destroy
      if note.destroyed?
        flash[:success] = 'Note removed.'
        redirect '/list'
      else
        flash[:danger] = 'Fail to remove note.'
        redirect '/list'
      end
    else
      flash[:warning] = "Note don't exists."
      redirect '/list'
    end
  else
    flash[:warning] = 'Please login.'
    redirect '/login'
  end
end