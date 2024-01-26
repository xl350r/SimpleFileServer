require "sinatra/base"
require 'webrick'
require "webrick/https"
require 'openssl'
require "erb"
require 'fileutils'
CERT_PATH = __dir__ + "/certs/"
class Auth 
	attr_accessor :credentials
	def initialize(credentials)
		self.credentials = credentials
	end
end

class WebServ < Sinatra::Base
	enable :sessions, :logging
	set :public_folder, __dir__ + '/pub/'
	$authenticated_sessions = []
	use Rack::Session::Pool, :expire_after => 2592000
	before do   # Before every request, make sure they get assigned an ID.
    session[:id] ||= SecureRandom.uuid
	end
	helpers do
			def authenticated?
				$authenticated_sessions.include? session[:id]
			end
	  	def authorize
	  		if @auth == nil
	  			redirect "/login"
	  		end
    		if @auth.credentials == ['admin', 'c7ad44cbad762a5da0a452f9e854fdc1e0e7a52a38015f23f3eab1d80b931dd472634dfac71cd34ebc35d16ab7fb8a90c81f975113d6c7538dc69dd8de9077ec'] 
   		 		$authenticated_sessions.push(session[:id])
   		 	else
   		 		redirect "/login"
   		 	end
  		end
	end
	get "/" do
		erb :index
	end

	not_found do
		status 404
		"""
<html>
	<head>
		<link rel=\"stylesheet\" href=\"/stylesheets/98.css\" type=\"text/css\">
		<link rel=\"stylesheet\" href=\"/stylesheets/vs.css\" type=\"text/css\">
		<link rel=\"stylesheet\" href=\"/stylesheets/docs.css\" type=\"text/css\">
	</head>
	<h1> 404 This page does not exist</h1> <p> redirecting in 5 seconds</p> <meta http-equiv=\"refresh\" content=\"5; url=/listing\" />
</html>
"""
	end

	get "/illegal_file" do
"""
<html>
	<head>
		<link rel=\"stylesheet\" href=\"/stylesheets/98.css\" type=\"text/css\">
		<link rel=\"stylesheet\" href=\"/stylesheets/vs.css\" type=\"text/css\">
		<link rel=\"stylesheet\" href=\"/stylesheets/docs.css\" type=\"text/css\">
	</head>
	<h1> ERROR</h1> <p> File contains illegal characters </p>  <meta http-equiv=\"refresh\" content=\"5; url=/listing\" />
</html>
"""
			redirect "/listing"
	end

	post "/upload" do
		if not authenticated?
			redirect "/login"
		end
		if params[:file] != nil 
			params[:file].each do |file|
				@filename = file["filename"]
				if @filename.include?("#") 
					redirect "/illegal_file"
				end
				tempfile = file[:tempfile]
				if not File.exist?(__dir__ + "/public/#{@filename}")
					File.open(__dir__ + "/public/#{@filename}", "wb") do |f|
						f.write(tempfile.read)
					end
				end
			end
		end
		redirect "/listing"
	end

	get "/listing" do
		@files= Dir.entries(__dir__ + "/public/")
		@files.delete(".")
		@files.delete("..")
		erb :listing
		#action = params[:remove]
	end

	get '/download/:filename' do |filename|
		send_file __dir__ + "/public/#{filename}", :filename => filename, :type => "Application/octet-stream"
		redirect "/listing"
	end

	get '/remove/:filename' do |filename|
		if not authenticated?
			redirect "login"
		end
		if File.exist?(__dir__ + "/public/#{filename}")
			File.delete(__dir__ + "/public/#{filename}")
		end
		files= Dir.entries(__dir__ + "/public")
		files.delete(".")
		files.delete("..")
		if files.length == 0	
			redirect "/listing"
		else
			redirect "/listing"
		end
	end
	get '/public/:filename' do |filename|
		if File.exist?(__dir__ + "/public/#{filename}")
			send_file __dir__ + "/public/#{filename}"
		else
			"<h1>File not found return <a href='/'> home </a></h1>"
		end
	end
	get "/Authenticated" do
		"<h1> Authenticated! <h1> <br>You will be redirected soon...</br> <meta http-equiv=\"refresh\" content=\"5; url=/listing\" />"
	end

	get "/logout" do
			if authenticated?
				$authenticated_sessions.delete session[:id]
			end
			redirect "/listing"
	end
	get "/login" do 
		erb :login
	end
	post "/login" do
		if params['user'] != nil and params['password'] != nil 
			if authenticated? 
				redirect "/Authenticated"
			else
				@auth = Auth.new [params['user'], params['password']]
				authorize
				if authenticated?
					redirect "/Authenticated"
				else
					redirect "/login"
				end
			end
		end
		redirect "/listing"
	end
end

webrick_options = {
  :Port               => 4567,
  :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
  :DocumentRoot       => nil,
  :SSLEnable          => true,
  :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
  :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open(File.join(CERT_PATH, "server.crt")).read),
  :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open(File.join(CERT_PATH, "server.key")).read),
  :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ],
  :app                => WebServ
}
if not File.exist?(__dir__ + "/public/")
	FileUtils.mkdir_p(__dir__ + "/public/")
end
#Dir.chdir(__dir__)
Rack::Server.start webrick_options
