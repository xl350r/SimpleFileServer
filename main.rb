require "sinatra/base"
require 'webrick'
require "webrick/https"
require 'openssl'
require "erb"
require 'fileutils'
CERT_PATH = __dir__ + "/certs/"
class WebServ < Sinatra::Base
	enable :sessions, :logging
	get "/" do
		erb :index
	end
	
	not_found do
		status 404
		"<h1> 404 This page does not exist</h1> <p> redirecting in 5 seconds</p> <meta http-equiv=\"refresh\" content=\"5; url=/listing\" />"
	end
	get "/login" do
		erb :login
	end
	post "/login" do
		if params['user'] != nil and params['password'] != nil 
			puts params
		end
		redirect "/listing"
	end
	get "/admin" do 
		"<h1> UNDER CONSTRUCTION </1>"
	end
	post "/upload" do
		if params[:file] != nil 
			params[:file].each do |file|
				@filename = file["filename"]
					puts "#{@filename} \t #{@filename.class}"
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
		if File.exist?(__dir__ + "/public/#{filename}")
			File.delete(__dir__ + "/public/#{filename}")
		end
		files= Dir.entries(__dir__ + "/public")
		files.delete(".")
		files.delete("..")
		if files.length == 0
			redirect "/upload"
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
