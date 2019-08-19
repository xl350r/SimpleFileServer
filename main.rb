require "sinatra/base"
require 'webrick'
require "webrick/https"
require 'openssl'
require "erb"
CERT_PATH = "./certs/"
class WebServ < Sinatra::Base
	enable :sessions, :logging
	get "/" do
		erb :index
	end

	get "/upload" do
		erb :file
	end

	post "/upload" do
		@filename = params[:file][:filename]
		file = params[:file][:tempfile]
		if not File.exist?("./public/#{@filename}")
			File.open("./public/#{@filename}", "wb") do |f|
				f.write(file.read)
			end
		end
		redirect "/listing"
	end

	get "/listing" do
		@files= Dir.entries("./public/")
		@files.delete(".")
		@files.delete("..")
		erb :listing
		#action = params[:remove]
	end

	get '/download/:filename' do |filename|
		send_file "./public/#{filename}", :filename => filename, :type => "Application/octet-stream"
		redirect "/listing"
	end

	get '/remove/:filename' do |filename|
		if File.exist?("./public/#{filename}")
			File.delete("./public/#{filename}")
		end
		files= Dir.entries("./public")
		files.delete(".")
		files.delete("..")
		if files.length == 0
			redirect "/upload"
		else
			redirect "/listing"
		end
	end
	get '/public/:filename' do |filename|
		if File.exist?("./public/#{filename}")
			send_file "./public/#{filename}"
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
Rack::Server.start webrick_options
