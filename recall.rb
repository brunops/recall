require 'data_mapper'
require 'sinatra'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'

enable :sessions

SITE_TITLE = "Recall"
SITE_DESCRIPTION = "'cause you're too busy to remember"

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

class Note
  include DataMapper::Resource
  property :id, Serial
  property :content, Text, :required => true
  property :completed, Boolean, :required => true, :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

get '/' do
  @notes = Note.all :order => :id.desc
  @title = 'All Notes'
  if @notes.empty?
    flash[:error] = 'No notes found. Add your first below.'
  end
  erb :home
end

post '/' do
  n = Note.new
  n.content = params[:content]
  n.created_at = Time.now
  n.updated_at = Time.now
  if n.save
    redirect '/', :notice => 'Note created sucessfully.'
  else
    redirect '/', :error => 'Failed to save note.'
  end
end

get '/rss.xml' do
  @notes = Note.all :order => :id.desc
  builder :rss
end

get '/:id' do
  @note = Note.get params[:id]
  if @note
    @title = "Edit note ##{@note.id}"
    erb :edit
  else
    redirect '/', :error => "Can't find that note."
  end
end

put '/:id' do
  n = Note.get params[:id]
  unless n
    redirect '/', :error => "Can't find that note."
  end
  n.content = params[:content]
  n.completed = params[:completed] ? 1 : 0
  n.updated_at = Time.now
  if n.save
    redirect '/', :notice => "Note updated successfully."
  else
    redirect '/', :error => "Error updating note."
  end
  redirect '/'
end

get '/:id/delete' do
  @note = Note.get params[:id]
  @title = "Confirm deletion of note ##{params[:id]}"
  if @note
    erb :delete
  else
    redirect '/', :error => "Can't find that note."
  end
end


delete '/:id' do
  n = Note.get params[:id]
  if n.destroy
    redirect '/', :notice => 'Note deleted successfully.'
  else
    redirect '/', :error => 'Error deleting note.'
  end
end

get '/:id/complete' do
  n = Note.get params[:id]
  unless n
    redirect '/', :error => "Can't find that note."
  end
  n.completed = n.completed ? 0 : 1 # flip it
  n.updated_at = Time.now
  if n.save
    redirect '/', :notice => "Note marked as completed."
  else
    redirect '/', :error => "Error marking note as completed."
  end
  redirect '/'
end







